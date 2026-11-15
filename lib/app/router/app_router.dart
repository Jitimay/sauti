import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/ai_agent/presentation/pages/assistant_page.dart';
import '../../features/ai_agent/presentation/pages/conversation_history_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/authentication/presentation/bloc/auth_bloc.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/onboarding_page.dart';
import '../../features/authentication/presentation/pages/language_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/reset_password_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/welcome_page.dart';
import '../../features/banking/domain/entities/transfer.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/financial_insights/presentation/pages/insights_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/settings/presentation/bloc/preferences_cubit.dart';
import '../../features/settings/presentation/pages/accessibility_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transactions/presentation/pages/transaction_details_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
import '../../features/transfers/presentation/bloc/transfer_bloc.dart';
import '../../features/transfers/presentation/pages/transfer_confirm_page.dart';
import '../../features/transfers/presentation/pages/transfer_prepare_page.dart';
import '../../features/transfers/presentation/pages/transfer_receipt_page.dart';
import '../di/injection.dart';
import 'home_shell.dart';
import 'routes.dart';
import 'stream_listenable.dart';

GoRouter buildRouter({required AuthBloc auth, required PreferencesCubit prefs}) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: Routes.splash,
    refreshListenable: StreamListenable([auth.stream, prefs.stream]),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final status = auth.state.status;
      final p = prefs.state;
      final isPublic = Routes.publicRoutes.contains(loc);

      if (status == AuthenticationStatus.unknown) return loc == Routes.splash ? null : Routes.splash;
      if (!p.languageChosen) return loc == Routes.language ? null : Routes.language;
      if (!p.onboardingComplete) return loc == Routes.onboarding ? null : Routes.onboarding;
      if (status == AuthenticationStatus.unauthenticated) {
        return isPublic && loc != Routes.splash && loc != Routes.language && loc != Routes.onboarding
            ? null
            : Routes.welcome;
      }
      // Authenticated
      if (isPublic) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.language, builder: (_, _) => const LanguagePage()),
      GoRoute(path: Routes.onboarding, builder: (_, _) => const OnboardingPage()),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomePage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterPage()),
      GoRoute(path: Routes.resetPassword, builder: (_, _) => const ResetPasswordPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const DashboardPage())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.assistant,
              builder: (_, _) => const AssistantPage(),
              routes: [
                GoRoute(
                  path: 'history',
                  parentNavigatorKey: rootKey,
                  builder: (_, _) => const ConversationHistoryPage(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.activity,
              builder: (_, _) => const TransactionsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootKey,
                  builder: (_, s) => TransactionDetailsPage(id: s.pathParameters['id']!),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.settings,
              builder: (_, _) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: 'accessibility',
                  parentNavigatorKey: rootKey,
                  builder: (_, _) => const AccessibilitySettingsPage(),
                ),
              ],
            ),
          ]),
        ],
      ),
      GoRoute(path: Routes.accounts, builder: (_, _) => const AccountsPage()),
      GoRoute(path: Routes.insights, builder: (_, _) => const InsightsPage()),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsPage()),
      // One TransferBloc spans prepare → confirm → receipt.
      ShellRoute(
        builder: (context, state, child) => BlocProvider(
          create: (_) => TransferBloc(
            prepare: sl(),
            submit: sl(),
            beneficiaries: sl(),
            authenticator: sl(),
            clock: sl(),
            policy: sl(),
          )..add(const TransferStarted()),
          child: child,
        ),
        routes: [
          GoRoute(path: Routes.transfer, builder: (_, s) => TransferPreparePage(prefillBeneficiaryId: s.uri.queryParameters['to'])),
          GoRoute(path: Routes.transferConfirm, builder: (_, s) => TransferConfirmPage(draft: s.extra as TransferDraft?)),
          GoRoute(path: Routes.transferReceipt, builder: (_, _) => const TransferReceiptPage()),
        ],
      ),
    ],
  );
}
