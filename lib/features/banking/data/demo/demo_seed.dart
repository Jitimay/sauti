import '../../../../core/money/money.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/bank_notification.dart';
import '../../domain/entities/bank_transaction.dart';
import '../../domain/entities/beneficiary.dart';

/// SIMULATED data for DEMO mode only. All names, numbers and balances are
/// fictitious. Dates are relative to [now] so "this month" always has data.
final class DemoSeed {
  DemoSeed(this.now);

  final DateTime now;

  static const mainAccountId = 'demo-acc-main';
  static const savingsAccountId = 'demo-acc-savings';

  DateTime _ago({int days = 0, int hours = 0}) => now.subtract(Duration(days: days, hours: hours));

  /// Clamp a "days ago" offset into the current month so the headline demo
  /// numbers always land in "this month", even on the 1st.
  DateTime _thisMonth(int daysAgo, int hour) {
    final d = now.day - 1 < daysAgo ? 0 : daysAgo;
    final t = DateTime(now.year, now.month, now.day - d, hour);
    return t.isAfter(now) ? now.subtract(const Duration(minutes: 5)) : t;
  }

  List<Account> accounts() => const [
        Account(
          id: mainAccountId,
          name: 'Compte courant',
          maskedNumber: '•••• 4821',
          type: AccountType.current,
          balance: Money.bif(250000),
          availableBalance: Money.bif(250000),
        ),
        Account(
          id: savingsAccountId,
          name: 'Épargne',
          maskedNumber: '•••• 7310',
          type: AccountType.savings,
          balance: Money.bif(1200000),
          availableBalance: Money.bif(1200000),
        ),
      ];

  List<Beneficiary> beneficiaries() => const [
        Beneficiary(
          id: 'demo-ben-jean',
          name: 'Jean Ndayishimiye',
          maskedAccount: '•••• 1104',
          institution: 'Sauti Demo Bank',
          aliases: ['Jean'],
        ),
        Beneficiary(
          id: 'demo-ben-aline',
          name: 'Aline Irakoze',
          maskedAccount: '•••• 5532',
          institution: 'Sauti Demo Bank',
          aliases: ['Aline'],
        ),
        Beneficiary(
          id: 'demo-ben-mama',
          name: 'Spès Niyonzima',
          maskedAccount: '•••• 0917',
          institution: 'Demo Microfinance',
          aliases: ['Maman', 'Mama', 'Mum'],
        ),
        Beneficiary(
          id: 'demo-ben-eric',
          name: 'Éric Hakizimana',
          maskedAccount: '•••• 2288',
          institution: 'Sauti Demo Bank',
          aliases: ['Eric'],
        ),
      ];

  List<BankTransaction> transactions() {
    BankTransaction tx(String id, TransactionDirection dir, int amount, String cp, TransactionCategory cat,
            String desc, DateTime at, {int? fee}) =>
        BankTransaction(
          id: id,
          accountId: mainAccountId,
          direction: dir,
          amount: Money.bif(amount),
          counterparty: cp,
          category: cat,
          description: desc,
          timestamp: at,
          fee: fee == null ? null : Money.bif(fee),
          reference: 'DEMO-${id.toUpperCase()}',
        );
    const i = TransactionDirection.incoming;
    const o = TransactionDirection.outgoing;
    final list = <BankTransaction>[
      // This month — headline demo transactions.
      tx('t101', i, 50000, 'Jean Ndayishimiye', TransactionCategory.income, 'Transfer received', _thisMonth(0, 9)),
      tx('t102', o, 15000, 'Bujumbura Moto Taxi', TransactionCategory.transport, 'Transport — weekly pass', _thisMonth(1, 18)),
      tx('t103', o, 30000, 'Marché Central', TransactionCategory.groceries, 'Groceries', _thisMonth(2, 11)),
      tx('t104', o, 10000, 'REGIDESO', TransactionCategory.utilities, 'Water & electricity bill', _thisMonth(3, 8), fee: 200),
      tx('t105', o, 5000, 'Lumitel', TransactionCategory.airtime, 'Airtime top-up', _thisMonth(4, 20)),
      tx('t106', i, 30000, 'Aline Irakoze', TransactionCategory.income, 'Transfer received', _thisMonth(5, 14)),
      // Previous months — for trends and recurring detection.
      tx('t090', o, 12000, 'Bujumbura Moto Taxi', TransactionCategory.transport, 'Transport — weekly pass', _ago(days: 33)),
      tx('t091', o, 42000, 'Marché Central', TransactionCategory.groceries, 'Groceries', _ago(days: 36)),
      tx('t092', o, 9500, 'REGIDESO', TransactionCategory.utilities, 'Water & electricity bill', _ago(days: 34), fee: 200),
      tx('t093', i, 180000, 'Demo Employer SARL', TransactionCategory.income, 'Salary', _ago(days: 40)),
      tx('t094', o, 25000, 'Spès Niyonzima', TransactionCategory.transfer, 'Transfer sent', _ago(days: 45)),
      tx('t080', o, 9800, 'REGIDESO', TransactionCategory.utilities, 'Water & electricity bill', _ago(days: 64), fee: 200),
      tx('t081', o, 14000, 'Bujumbura Moto Taxi', TransactionCategory.transport, 'Transport — weekly pass', _ago(days: 62)),
      tx('t082', o, 20000, 'Clinique Prince Louis', TransactionCategory.health, 'Consultation', _ago(days: 70)),
    ];
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<BankNotification> notifications() => [
        BankNotification(
          id: 'n1',
          kind: NotificationKind.paymentReceived,
          timestamp: _thisMonth(0, 9),
          amount: const Money.bif(50000),
          counterparty: 'Jean Ndayishimiye',
          transactionId: 't101',
        ),
        BankNotification(
          id: 'n2',
          kind: NotificationKind.reminder,
          timestamp: _ago(hours: 30),
          detail: 'utility_bill_due',
        ),
        BankNotification(
          id: 'n3',
          kind: NotificationKind.security,
          timestamp: _ago(days: 2),
          detail: 'new_device_login',
          read: true,
        ),
        BankNotification(
          id: 'n4',
          kind: NotificationKind.paymentReceived,
          timestamp: _thisMonth(5, 14),
          amount: const Money.bif(30000),
          counterparty: 'Aline Irakoze',
          transactionId: 't106',
          read: true,
        ),
      ];
}
