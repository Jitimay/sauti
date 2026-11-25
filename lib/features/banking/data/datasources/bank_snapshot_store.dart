import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/bank_notification.dart';
import '../../domain/entities/bank_transaction.dart';
import '../../domain/entities/beneficiary.dart';
import '../models/bank_mappers.dart';

/// Last known-good banking snapshot for offline display.
final class BankSnapshot {
  const BankSnapshot({
    this.accounts,
    this.transactions,
    this.notifications,
    this.beneficiaries,
    required this.savedAt,
    this._accountsAt,
    this._transactionsAt,
    this._notificationsAt,
  });

  final List<Account>? accounts;
  final List<BankTransaction>? transactions;
  final List<BankNotification>? notifications;
  final List<Beneficiary>? beneficiaries;

  /// Time of the most recent save of any section.
  final DateTime savedAt;

  final DateTime? _accountsAt;
  final DateTime? _transactionsAt;
  final DateTime? _notificationsAt;

  // Each section keeps the time it was actually fetched, so refreshing one
  // section never makes another look newer than it is.
  DateTime get accountsAt => _accountsAt ?? savedAt;
  DateTime get transactionsAt => _transactionsAt ?? savedAt;
  DateTime get notificationsAt => _notificationsAt ?? savedAt;

  /// Merges a partial save into this snapshot (or a new one).
  static BankSnapshot merge(
    BankSnapshot? current, {
    List<Account>? accounts,
    List<BankTransaction>? transactions,
    List<BankNotification>? notifications,
    List<Beneficiary>? beneficiaries,
    required DateTime at,
  }) => BankSnapshot(
    accounts: accounts ?? current?.accounts,
    transactions: transactions ?? current?.transactions,
    notifications: notifications ?? current?.notifications,
    beneficiaries: beneficiaries ?? current?.beneficiaries,
    savedAt: at,
    accountsAt: accounts != null ? at : current?.accountsAt,
    transactionsAt: transactions != null ? at : current?.transactionsAt,
    notificationsAt: notifications != null ? at : current?.notificationsAt,
  );
}

abstract interface class BankSnapshotStore {
  Future<BankSnapshot?> read();
  Future<void> save({
    List<Account>? accounts,
    List<BankTransaction>? transactions,
    List<BankNotification>? notifications,
    List<Beneficiary>? beneficiaries,
    required DateTime at,
  });
  Future<void> clear();
}

/// Encrypted at rest via platform keystore/keychain.
final class SecureBankSnapshotStore implements BankSnapshotStore {
  SecureBankSnapshotStore(this._storage, {String? namespace})
    : _key = 'bank_snapshot_v1_${namespace ?? 'default'}';

  final FlutterSecureStorage _storage;
  final String _key;

  /// Saves are read-modify-write. Screens refresh several sections at once
  /// (the dashboard loads accounts, transactions and notifications in
  /// parallel), so writes are serialized: otherwise the last write would
  /// silently drop the sections saved by the others.
  Future<void> _tail = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() body) {
    final next = _tail.then((_) => body());
    _tail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  @override
  Future<BankSnapshot?> read() => _serialized(_readSnapshot);

  Future<BankSnapshot?> _readSnapshot() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final j = (jsonDecode(raw) as Map).cast<String, Object?>();
      List<T>? list<T>(String k, T Function(Map<String, Object?>) f) =>
          (j[k] as List?)
              ?.map((e) => f((e as Map).cast<String, Object?>()))
              .toList();
      DateTime? time(String k) =>
          j[k] == null ? null : DateTime.parse(j[k]! as String);
      return BankSnapshot(
        accounts: list('accounts', BankMappers.accountFrom),
        transactions: list('transactions', BankMappers.transactionFrom),
        notifications: list('notifications', BankMappers.notificationFrom),
        beneficiaries: list('beneficiaries', BankMappers.beneficiaryFrom),
        savedAt: DateTime.parse(j['savedAt'] as String),
        accountsAt: time('accountsAt'),
        transactionsAt: time('transactionsAt'),
        notificationsAt: time('notificationsAt'),
      );
    } catch (_) {
      // Corrupt cache is discarded, never trusted.
      await _storage.delete(key: _key);
      return null;
    }
  }

  @override
  Future<void> save({
    List<Account>? accounts,
    List<BankTransaction>? transactions,
    List<BankNotification>? notifications,
    List<Beneficiary>? beneficiaries,
    required DateTime at,
  }) => _serialized(() async {
    final s = BankSnapshot.merge(
      await _readSnapshot(),
      accounts: accounts,
      transactions: transactions,
      notifications: notifications,
      beneficiaries: beneficiaries,
      at: at,
    );
    final data = {
      'accounts': s.accounts?.map(BankMappers.account).toList(),
      'transactions': s.transactions?.map(BankMappers.transaction).toList(),
      'notifications': s.notifications?.map(BankMappers.notification).toList(),
      'beneficiaries': s.beneficiaries?.map(BankMappers.beneficiary).toList(),
      'savedAt': s.savedAt.toIso8601String(),
      'accountsAt': s.accountsAt.toIso8601String(),
      'transactionsAt': s.transactionsAt.toIso8601String(),
      'notificationsAt': s.notificationsAt.toIso8601String(),
    };
    await _storage.write(key: _key, value: jsonEncode(data));
  });

  @override
  Future<void> clear() => _serialized(() => _storage.delete(key: _key));
}

final class InMemoryBankSnapshotStore implements BankSnapshotStore {
  BankSnapshot? _snap;

  @override
  Future<BankSnapshot?> read() async => _snap;

  @override
  Future<void> save({
    List<Account>? accounts,
    List<BankTransaction>? transactions,
    List<BankNotification>? notifications,
    List<Beneficiary>? beneficiaries,
    required DateTime at,
  }) async {
    _snap = BankSnapshot.merge(
      _snap,
      accounts: accounts,
      transactions: transactions,
      notifications: notifications,
      beneficiaries: beneficiaries,
      at: at,
    );
  }

  @override
  Future<void> clear() async => _snap = null;
}
