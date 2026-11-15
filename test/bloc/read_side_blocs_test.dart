import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/error/failure.dart';
import 'package:sauti/core/money/money.dart';
import 'package:sauti/core/utils/view_status.dart';
import 'package:sauti/features/banking/domain/entities/bank_transaction.dart';
import 'package:sauti/features/banking/domain/usecases/banking_usecases.dart';
import 'package:sauti/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:sauti/features/financial_insights/presentation/bloc/insights_bloc.dart';
import 'package:sauti/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:sauti/features/settings/data/prefs_settings_repository.dart';
import 'package:sauti/features/settings/domain/settings.dart';
import 'package:sauti/features/settings/presentation/bloc/accessibility_bloc.dart';
import 'package:sauti/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

void main() {
  late TestStack s;
  setUp(() => s = TestStack());

  group('DashboardBloc', () {
    DashboardBloc build() => DashboardBloc(GetAccounts(s.bank), GetRecentTransactions(s.bank), GetNotifications(s.bank));

    blocTest<DashboardBloc, DashboardState>(
      'loading → success with balance, recent and unread count',
      build: build,
      act: (b) => b.add(const DashboardLoadRequested()),
      expect: () => [
        isA<DashboardState>().having((x) => x.status, 'status', ViewStatus.loading),
        isA<DashboardState>()
            .having((x) => x.status, 'status', ViewStatus.success)
            .having((x) => x.primary?.availableBalance, 'balance', const Money.bif(250000))
            .having((x) => x.unreadNotifications, 'unread', 2)
            .having((x) => x.recent?.data.length, 'recent', 4),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'offline without cache → failure',
      build: build,
      setUp: () => s.network.set(false),
      act: (b) => b.add(const DashboardLoadRequested()),
      verify: (b) {
        expect(b.state.status, ViewStatus.failure);
        expect(b.state.failure, isA<NetworkFailure>());
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'offline with cache → success marked cached',
      build: build,
      act: (b) async {
        b.add(const DashboardLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        s.network.set(false);
        b.add(const DashboardLoadRequested(silent: true));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        expect(b.state.status, ViewStatus.success);
        expect(b.state.accounts!.isCached, isTrue);
      },
    );
  });

  group('TransactionBloc', () {
    blocTest<TransactionBloc, TransactionState>(
      'filters by direction and text; empty state when nothing matches',
      build: () => TransactionBloc(SearchTransactions(s.bank)),
      act: (b) async {
        b.add(const TransactionFilterChanged(direction: TransactionDirection.incoming));
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(b.state.transactions!.data.every((t) => t.isIncoming), isTrue);
        b.add(const TransactionFilterChanged(text: 'zzzz-nobody'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) => expect(b.state.status, ViewStatus.empty),
    );
  });

  group('InsightsBloc', () {
    blocTest<InsightsBloc, InsightsState>(
      'this month and last month summaries',
      build: () => InsightsBloc(CalculateMonthlySpending(s.bank, s.clock), s.clock),
      act: (b) async {
        b.add(const InsightsRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(b.state.summary!.data.totalSpent, const Money.bif(60000));
        b.add(const InsightsRequested(monthOffset: 1));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) => expect(b.state.summary!.data.totalSpent, const Money.bif(88500)),
    );
  });

  group('NotificationsBloc', () {
    blocTest<NotificationsBloc, NotificationsState>(
      'marks a notification read',
      build: () => NotificationsBloc(GetNotifications(s.bank), MarkNotificationRead(s.bank)),
      act: (b) async {
        b.add(const NotificationsLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        b.add(const NotificationMarkedRead('n1'));
      },
      wait: const Duration(milliseconds: 20),
      verify: (b) => expect(b.state.items!.data.firstWhere((n) => n.id == 'n1').read, isTrue),
    );
  });

  group('AccessibilityBloc', () {
    late PrefsSettingsRepository repo;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = PrefsSettingsRepository(await SharedPreferences.getInstance());
    });

    blocTest<AccessibilityBloc, AccessibilitySettings>(
      'changes are applied, clamped and persisted',
      build: () => AccessibilityBloc(repo),
      act: (b) => b
        ..add(const FontSizeChanged(5))
        ..add(const HighContrastChanged(true))
        ..add(const InteractionModeChanged(InteractionMode.simplified))
        ..add(const VoiceFeedbackChanged(false))
        ..add(const SpeechRateChanged(0.1)),
      wait: const Duration(milliseconds: 20),
      verify: (b) {
        final saved = repo.loadAccessibility();
        expect(saved.textScale, 2.0);
        expect(saved.highContrast, isTrue);
        expect(saved.interactionMode, InteractionMode.simplified);
        expect(saved.voiceFeedback, isFalse);
        expect(saved.speechRate, 0.25);
        expect(b.state, saved);
      },
    );
  });
}
