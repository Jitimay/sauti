import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/app_config.dart';
import '../core/l10n/app_language.dart';
import '../core/l10n/fallback_localizations.dart';
import '../core/network/connectivity_cubit.dart';
import '../core/widgets/status_banners.dart';
import '../features/ai_agent/presentation/bloc/agent_bloc.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../features/settings/domain/settings.dart';
import '../features/settings/presentation/bloc/accessibility_bloc.dart';
import '../features/settings/presentation/bloc/preferences_cubit.dart';
import '../features/voice/presentation/bloc/voice_bloc.dart';
import '../l10n/app_localizations.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class SautiApp extends StatefulWidget {
  const SautiApp({super.key});

  @override
  State<SautiApp> createState() => _SautiAppState();
}

class _SautiAppState extends State<SautiApp> {
  late final AuthBloc _auth = AuthBloc(sl());
  late final PreferencesCubit _prefs = PreferencesCubit(sl());
  late final GoRouter _router = buildRouter(auth: _auth, prefs: _prefs);

  @override
  void dispose() {
    _router.dispose();
    _auth.close();
    _prefs.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _auth),
        BlocProvider.value(value: _prefs),
        BlocProvider(create: (_) => AccessibilityBloc(sl())..add(const AccessibilitySettingsLoaded())),
        BlocProvider(create: (_) => ConnectivityCubit(sl())),
        BlocProvider(create: (_) => DashboardBloc(sl(), sl(), sl())),
        BlocProvider(
          create: (_) => AgentBloc(
            orchestrator: sl(),
            history: sl(),
            clock: sl(),
            newId: sl(instanceName: 'newId'),
            drafts: sl(),
          ),
        ),
        BlocProvider(create: (_) => VoiceBloc(sl(), sl())),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (a, b) => a.status == AuthenticationStatus.authenticated && b.status == AuthenticationStatus.unauthenticated,
        listener: (context, _) async {
          await clearSessionData();
          if (context.mounted) context.read<AgentBloc>().add(const AgentConversationCleared());
        },
        child: _ThemedApp(router: _router),
      ),
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp({required this.router});
  final GoRouter router;

  static final _delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
    ...FallbackLocalizationsDelegate.forDelegates(GlobalMaterialLocalizations.delegates),
  ];

  @override
  Widget build(BuildContext context) {
    final a11y = context.watch<AccessibilityBloc>().state;
    final language = context.select<PreferencesCubit, AppLanguage>((c) => c.state.language);
    final isDemo = sl<AppConfig>().isDemo;

    return MaterialApp.router(
      title: 'Sauti',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: a11y.highContrast ? AppTheme.highContrast() : AppTheme.standard(),
      locale: Locale(language.code),
      supportedLocales: [for (final l in AppLanguage.values) Locale(l.code)],
      localizationsDelegates: _delegates,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Respect the OS text scale and multiply by the in-app preference.
        final scaled = mq.copyWith(
          textScaler: TextScaler.linear((mq.textScaler.scale(16) / 16) * a11y.textScale),
          disableAnimations: mq.disableAnimations || a11y.reduceMotion,
        );
        return MediaQuery(
          data: scaled,
          child: Column(children: [
            if (isDemo) const DemoBanner(),
            Expanded(
              // Own semantics container: route-level BlockSemantics must not
              // hide the DEMO banner from screen readers.
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                // The banner consumes the status-bar inset; pages below must not re-add it.
                child: MediaQuery(data: isDemo ? scaled.removePadding(removeTop: true) : scaled, child: child!),
              ),
            ),
          ]),
        );
      },
    );
  }
}

/// Convenience for widgets reading the interaction mode.
extension InteractionModeX on BuildContext {
  bool get simplifiedMode => watch<AccessibilityBloc>().state.interactionMode == InteractionMode.simplified;
}
