import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sauti/app/app.dart';
import 'package:sauti/app/di/injection.dart';
import 'package:sauti/core/config/app_config.dart';
import 'package:sauti/core/error/failure.dart';
import 'package:sauti/core/error/result.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/core/utils/clock.dart';
import 'package:sauti/features/ai_agent/data/repositories/secure_conversation_repository.dart';
import 'package:sauti/features/banking/data/datasources/bank_snapshot_store.dart';
import 'package:sauti/features/banking/data/repositories/caching_bank_repository.dart';
import 'package:sauti/features/banking/domain/repositories/bank_repository.dart';
import 'package:sauti/features/transfers/domain/entities/transfer_authorization.dart';
import 'package:sauti/features/transfers/domain/repositories/transfer_authenticator.dart';
import 'package:sauti/features/voice/domain/speech_recognizer.dart';
import 'package:sauti/features/voice/domain/speech_synthesizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

final class FakeRecognizer implements SpeechRecognizer {
  FakeRecognizer({this.supported = const {AppLanguage.english, AppLanguage.french}, this.permission = true});
  Set<AppLanguage> supported;
  bool permission;

  /// Next utterance to "hear".
  String nextUtterance = '';
  int sessions = 0;

  @override
  Future<bool> initialize() async => permission;

  @override
  Future<RecognitionLocale> resolveLocale(AppLanguage language) async => RecognitionLocale(
        requested: language,
        localeId: supported.contains(language) ? language.speechLocaleCandidates.first : null,
        isExactMatch: true,
      );

  @override
  Stream<RecognitionEvent> listen({required String localeId, Duration maxDuration = const Duration(seconds: 15), Duration silenceTimeout = const Duration(seconds: 3)}) async* {
    sessions++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (nextUtterance.length > 4) yield RecognitionPartial(nextUtterance.substring(0, 4));
    yield nextUtterance.isEmpty ? const RecognitionError(RecognitionErrorKind.noMatch) : RecognitionFinal(nextUtterance);
  }

  @override
  Future<void> stop() async {}
  @override
  Future<void> cancel() async {}
}

final class FakeSynthesizer implements SpeechSynthesizer {
  final spoken = <String>[];
  Set<AppLanguage> supported = {AppLanguage.english, AppLanguage.french};
  @override
  Future<bool> supports(AppLanguage language) async => supported.contains(language);
  @override
  Future<void> speak(String text, {required AppLanguage language, required double rate}) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

final class FakeAuthenticator implements TransferAuthenticator {
  bool deviceAvailable = true;
  bool approve = true;
  int prompts = 0;
  @override
  Future<AuthenticatorAvailability> availability() async => AuthenticatorAvailability(deviceAuthAvailable: deviceAvailable);
  @override
  Future<Result<AuthMethod>> authenticateWithDevice({required String reason}) async {
    prompts++;
    return approve ? const Ok(AuthMethod.deviceBiometricOrPasscode) : const Err(AuthFailure(FailureCode.authInvalidCredentials));
  }

  @override
  Future<Result<AuthMethod>> authenticateWithPassword(String password) async =>
      password == 'Sauti2026' ? const Ok(AuthMethod.accountPassword) : const Err(AuthFailure(FailureCode.authInvalidCredentials));
}

/// Test harness running the real composition root in DEMO mode with fakes
/// only at the platform boundary.
final class TestHarness {
  final network = FakeNetwork();
  final clock = FixedClock(testNow);
  final recognizer = FakeRecognizer();
  final synthesizer = FakeSynthesizer();
  final authenticator = FakeAuthenticator();
  final snapshots = InMemoryBankSnapshotStore();
  final conversations = InMemoryConversationRepository();

  Future<void> setUp({
    bool signedIn = true,
    AppLanguage? language = AppLanguage.english,
    bool onboarded = true,
    bool voiceFeedback = false,
  }) async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({
      if (language != null) 'settings.language': language.code,
      'settings.onboardingComplete': onboarded,
      'settings.voiceFeedback': voiceFeedback,
      'settings.reduceMotion': true,
      if (signedIn) 'demo_session_active': true,
    });
    await configureDependencies(
      config: const AppConfig(environment: AppEnvironment.demo, aiModel: 'test'),
      firebaseReady: false,
      overrides: DependencyOverrides(
        prefs: await SharedPreferences.getInstance(),
        network: network,
        clock: clock,
        snapshots: snapshots,
        conversations: conversations,
        recognizer: recognizer,
        synthesizer: synthesizer,
        authenticator: authenticator,
        bankLatency: Duration.zero,
      ),
    );
  }

  int get appliedTransfers {
    final repo = sl<BankRepository>() as CachingBankRepository;
    return repo.debugRemoteAppliedTransfers;
  }

  Future<void> pumpApp(WidgetTester tester, {Size size = const Size(412, 915)}) async {
    tester.view.physicalSize = size * 2.625;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SautiApp());
    await settle(tester);
  }
}

/// pumpAndSettle with a cap (the voice orb may animate).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (!tester.binding.hasScheduledFrame) break;
  }
}

Future<void> runAsync(WidgetTester t, Future<void> Function() f) async {
  await t.runAsync(f);
  await settle(t);
}
