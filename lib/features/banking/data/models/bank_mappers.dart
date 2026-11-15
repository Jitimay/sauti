import '../../../../core/money/money.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/bank_notification.dart';
import '../../domain/entities/bank_transaction.dart';
import '../../domain/entities/beneficiary.dart';

/// JSON mappers shared by the snapshot cache and Firestore data source.
/// Unknown enum values degrade to safe defaults instead of crashing.
abstract final class BankMappers {
  static Map<String, Object?> money(Money m) => {'minor': m.minorUnits, 'currency': m.currency.code};

  static Money moneyFrom(Object? json) {
    final m = (json as Map).cast<String, Object?>();
    return Money((m['minor'] as num).toInt(), Currency.fromCode(m['currency'] as String));
  }

  static T _enum<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  static DateTime _date(Object? v) => switch (v) {
        String s => DateTime.parse(s),
        int ms => DateTime.fromMillisecondsSinceEpoch(ms),
        _ => throw FormatException('Bad date: $v'),
      };

  static Map<String, Object?> account(Account a) => {
        'id': a.id,
        'name': a.name,
        'maskedNumber': a.maskedNumber,
        'type': a.type.name,
        'balance': money(a.balance),
        'availableBalance': money(a.availableBalance),
        'institution': a.institution,
      };

  static Account accountFrom(Map<String, Object?> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        maskedNumber: j['maskedNumber'] as String,
        type: _enum(AccountType.values, j['type'], AccountType.current),
        balance: moneyFrom(j['balance']),
        availableBalance: moneyFrom(j['availableBalance'] ?? j['balance']),
        institution: (j['institution'] as String?) ?? '',
      );

  static Map<String, Object?> transaction(BankTransaction t) => {
        'id': t.id,
        'accountId': t.accountId,
        'direction': t.direction.name,
        'amount': money(t.amount),
        'counterparty': t.counterparty,
        'category': t.category.name,
        'description': t.description,
        'timestamp': t.timestamp.toIso8601String(),
        'status': t.status.name,
        if (t.fee != null) 'fee': money(t.fee!),
        if (t.reference != null) 'reference': t.reference,
      };

  static BankTransaction transactionFrom(Map<String, Object?> j) {
    final amount = moneyFrom(j['amount']);
    if (amount.isNegative) throw const FormatException('transaction amount must be unsigned');
    return BankTransaction(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        direction: _enum(TransactionDirection.values, j['direction'], TransactionDirection.outgoing),
        amount: amount,
        counterparty: j['counterparty'] as String,
        category: _enum(TransactionCategory.values, j['category'], TransactionCategory.other),
        description: (j['description'] as String?) ?? '',
        timestamp: _date(j['timestamp']),
        status: _enum(TransactionStatus.values, j['status'], TransactionStatus.completed),
        fee: j['fee'] == null ? null : moneyFrom(j['fee']),
        reference: j['reference'] as String?,
      );
  }

  static Map<String, Object?> beneficiary(Beneficiary b) => {
        'id': b.id,
        'name': b.name,
        'maskedAccount': b.maskedAccount,
        'institution': b.institution,
        'aliases': b.aliases,
      };

  static Beneficiary beneficiaryFrom(Map<String, Object?> j) => Beneficiary(
        id: j['id'] as String,
        name: j['name'] as String,
        maskedAccount: j['maskedAccount'] as String,
        institution: (j['institution'] as String?) ?? '',
        aliases: ((j['aliases'] as List?) ?? const []).cast<String>(),
      );

  static Map<String, Object?> notification(BankNotification n) => {
        'id': n.id,
        'kind': n.kind.name,
        'timestamp': n.timestamp.toIso8601String(),
        if (n.amount != null) 'amount': money(n.amount!),
        if (n.counterparty != null) 'counterparty': n.counterparty,
        if (n.detail != null) 'detail': n.detail,
        'read': n.read,
        if (n.transactionId != null) 'transactionId': n.transactionId,
      };

  static BankNotification notificationFrom(Map<String, Object?> j) => BankNotification(
        id: j['id'] as String,
        kind: _enum(NotificationKind.values, j['kind'], NotificationKind.reminder),
        timestamp: _date(j['timestamp']),
        amount: j['amount'] == null ? null : moneyFrom(j['amount']),
        counterparty: j['counterparty'] as String?,
        detail: j['detail'] as String?,
        read: (j['read'] as bool?) ?? false,
        transactionId: j['transactionId'] as String?,
      );
}
