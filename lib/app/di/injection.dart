import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/network/connectivity_network_status.dart';
import '../../core/network/demo_network_switch.dart';
import '../../core/network/network_status.dart';
import '../../core/utils/clock.dart';
import '../../features/ai_agent/data/cloud/gemini_ai_provider.dart';
import '../../features/ai_agent/data/local/local_intent_provider.dart';
import '../../features/ai_agent/data/on_device/hybrid_ai_provider.dart';
import '../../features/ai_agent/data/on_device/hybrid_intent_provider.dart';
import '../../features/ai_agent/data/repositories/secure_conversation_repository.dart';
import '../../features/ai_agent/domain/providers/ai_provider.dart';
import '../../features/ai_agent/domain/repositories/conversation_repository.dart';
import '../../features/ai_agent/domain/services/agent_orchestrator.dart';
import '../../features/ai_agent/domain/tools/agent_tool.dart';
import '../../features/ai_agent/domain/tools/banking_tools.dart';
import '../../features/ai_agent/domain/tools/tool_registry.dart';
import '../../features/authentication/data/repositories/demo_auth_repository.dart';
import '../../features/authentication/data/repositories/firebase_auth_repository.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/banking/data/datasources/bank_snapshot_store.dart';
import '../../features/banking/data/repositories/caching_bank_repository.dart';
import '../../features/banking/data/repositories/firebase_bank_repository.dart';
import '../../features/banking/data/repositories/simulated_bank_repository.dart';
import '../../features/banking/domain/entities/transfer_policy.dart';
import '../../features/banking/domain/repositories/bank_repository.dart';
import '../../features/banking/domain/services/transfer_preparer.dart';
import '../../features/banking/domain/usecases/banking_usecases.dart';
import '../../features/settings/data/prefs_settings_repository.dart';
import '../../features/settings/domain/settings.dart';
import '../../features/transfers/data/device_transfer_authenticator.dart';
import '../../features/transfers/domain/repositories/transfer_authenticator.dart';
import '../../features/transfers/domain/usecases/prepare_transfer.dart';
import '../../features/transfers/domain/usecases/submit_transfer.dart';
import '../../features/voice/data/platform_speech_recognizer.dart';
import '../../features/voice/data/platform_speech_synthesizer.dart';
import '../../features/voice/domain/speech_recognizer.dart';
import '../../features/voice/domain/speech_synthesizer.dart';

final sl = GetIt.instance;

/// Substitutes for platform-bound infrastructure (used by tests). Business
/// wiring stays identical, so tests exercise the real composition.
final class DependencyOverrides {
  const DependencyOverrides({
    this.prefs,
    this.network,
    this.clock,
    this.snapshots,
    this.conversations,
    this.recognizer,
    this.synthesizer,
    this.authenticator,
    this.bankLatency,
    this.hybridAi,
    this.hybridToolLoop,
  });

  final SharedPreferences? prefs;
  final NetworkStatus? network;
  final Clock? clock;
  final BankSnapshotStore? snapshots;
  final ConversationRepository? conversations;
  final SpeechRecognizer? recognizer;
  final SpeechSynthesizer? synthesizer;
  final TransferAuthenticator? authenticator;
  final Duration? bankLatency;

  /// Hybrid inference bridge. Defaults to the platform client.
  final HybridAiClient? hybridAi;

  /// Whether [hybridAi] drives a native tool loop (Apple). Defaults to iOS.
  final bool? hybridToolLoop;
}

/// Composition root. The demo/live boundary is decided here and nowhere else.
Future<void> configureDependencies({
  required AppConfig config,
  required bool firebaseReady,
  DependencyOverrides overrides = const DependencyOverrides(),
}) async {
  final o = overrides;
  const uuid = Uuid();
  String newId() => uuid.v4();

  sl
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<AppLogger>(const PrintLogger())
    ..registerSingleton<Clock>(o.clock ?? const SystemClock())
    ..registerSingleton<SharedPreferences>(o.prefs ?? await SharedPreferences.getInstance())
    ..registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage())
    ..registerSingleton<DemoNetworkSwitch>(DemoNetworkSwitch())
    ..registerSingleton<NetworkStatus>(o.network ?? ConnectivityNetworkStatus(Connectivity(), sl()))
    ..registerSingleton<SettingsRepository>(PrefsSettingsRepository(sl()));

  // ---- Auth + Bank: DEMO vs LIVE boundary ----
  final live = !config.isDemo;
  if (live && !firebaseReady) {
    throw StateError('SAUTI_ENV=live requires Firebase configuration. See docs/FIREBASE_SETUP.md.');
  }
  sl.registerSingleton<AuthRepository>(
      live ? FirebaseAuthRepository(FirebaseAuth.instance) : DemoAuthRepository(sl()));

  if (live) {
    // Firestore's disk cache is unencrypted and survives sign-out. Offline
    // reads come from the encrypted BankSnapshotStore instead.
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  }
  final BankRepository remote = live
      ? FirebaseBankRepository(
          firestore: FirebaseFirestore.instance,
          functions: FirebaseFunctions.instanceFor(region: config.functionsRegion),
          currentUserId: () => sl<AuthRepository>().currentUser?.id,
        )
      : SimulatedBankRepository(clock: sl(), network: sl(), latency: o.bankLatency ?? const Duration(milliseconds: 450));
  sl
    ..registerSingleton<BankSnapshotStore>(o.snapshots ?? SecureBankSnapshotStore(sl(), namespace: config.environment.name))
    ..registerSingleton<BankRepository>(CachingBankRepository(remote, sl()))
    ..registerSingleton<TransferPolicy>(TransferPolicy.bifDefault);

  // ---- Use cases ----
  sl
    ..registerLazySingleton(() => GetAccounts(sl()))
    ..registerLazySingleton(() => GetRecentTransactions(sl()))
    ..registerLazySingleton(() => SearchTransactions(sl()))
    ..registerLazySingleton(() => GetTransactionDetails(sl()))
    ..registerLazySingleton(() => ListBeneficiaries(sl()))
    ..registerLazySingleton(() => GetNotifications(sl()))
    ..registerLazySingleton(() => MarkNotificationRead(sl()))
    ..registerLazySingleton(() => CalculateMonthlySpending(sl(), sl()))
    ..registerLazySingleton(() => ExplainTransaction(sl()))
    ..registerLazySingleton(() => TransferPreparer(policy: sl(), clock: sl(), newId: newId))
    ..registerLazySingleton(() => PrepareTransfer(sl(), sl(), sl()))
    ..registerLazySingleton(() => SubmitTransfer(sl(), sl(), sl()))
    ..registerLazySingleton<TransferAuthenticator>(() => o.authenticator ?? DeviceTransferAuthenticator(LocalAuthentication(), sl()));

  // ---- AI agent ----
  final clock = sl<Clock>();
  // Hybrid inference bridge (Firebase AI Logic): Apple Foundation Models on
  // iOS (works without Firebase; Gemini fallback needs it), Gemini Nano on
  // Android and in Chrome (needs Firebase).
  final isApple = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  final hybridClient = o.hybridAi ?? (isApple || firebaseReady ? createHybridAiClient() : null);
  if (hybridClient != null) sl.registerSingleton<HybridAiClient>(hybridClient);
  final nativeToolLoop = o.hybridToolLoop ?? isApple;
  sl
    ..registerSingleton<SessionDraftStore>(SessionDraftStore())
    ..registerLazySingleton(() => ToolRegistry([
          GetAccountBalanceTool(sl()),
          GetRecentTransactionsTool(sl()),
          SearchTransactionsTool(sl(), clock),
          GetTransactionDetailsTool(sl()),
          ExplainTransactionTool(sl()),
          CalculateMonthlySpendingTool(sl(), clock),
          ListBeneficiariesTool(sl()),
          PrepareTransferTool(sl()),
          const ConfirmTransferTool(),
          GetNotificationsTool(sl(), clock),
        ], logger: sl()))
    ..registerLazySingleton<ConversationRepository>(() => o.conversations ?? SecureConversationRepository(sl()))
    ..registerLazySingleton(() {
      Future<bool> cloudAllowed() async =>
          firebaseReady &&
          sl<SettingsRepository>().loadPreferences().cloudAiEnabled &&
          await sl<NetworkStatus>().isOnline();
      final providers = <AiProvider>[
        // On-device tier. iOS: Apple's session drives the tool loop, with
        // Gemini (Firebase AI Logic) as its cloud fallback. Android/Chrome:
        // Gemini Nano labels the intent, Sauti's tools and templates answer.
        if (hybridClient != null && nativeToolLoop)
          HybridAiProvider(client: hybridClient, cloudAllowed: cloudAllowed, now: clock.now, cloudModel: config.aiModel),
        if (hybridClient != null && !nativeToolLoop)
          HybridIntentProvider(
            client: hybridClient,
            cloudAllowed: cloudAllowed,
            now: clock.now,
            cloudModel: config.aiModel,
          ),
        if (firebaseReady)
          GeminiAiProvider.firebase(
            model: config.aiModel,
            now: clock.now,
            isEnabled: cloudAllowed,
          ),
        LocalIntentProvider(now: clock.now),
      ];
      return AgentOrchestrator(
        providers: providers,
        registry: sl(),
        clock: clock,
        newId: newId,
        drafts: sl(),
        logger: sl(),
      );
    });

  // ---- Voice ----
  sl
    ..registerLazySingleton<SpeechRecognizer>(() => o.recognizer ?? PlatformSpeechRecognizer())
    ..registerLazySingleton<SpeechSynthesizer>(() => o.synthesizer ?? PlatformSpeechSynthesizer())
    ..registerSingleton<String Function()>(newId, instanceName: 'newId');
}

/// Clears per-user local data on sign-out (cache, conversation, drafts).
Future<void> clearSessionData() async {
  await sl<BankSnapshotStore>().clear();
  await sl<ConversationRepository>().clear();
  sl<SessionDraftStore>().clear();
}
