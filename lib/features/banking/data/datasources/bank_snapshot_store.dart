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
  });

  final List<Account>? accounts;
  final List<BankTransaction>? transactions;
  final List<BankNotification>? notifications;
  final List<Beneficiary>? beneficiaries;
  final DateTime savedAt;
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
  SecureBankSnapshotStore(this._storage, {String? namespace}) : _key = 'bank_snapshot_v1_${namespace ?? 'default'}';

  final FlutterSecureStorage _storage;
  final String _key;

  @override
  Future<BankSnapshot?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final j = (jsonDecode(raw) as Map).cast<String, Object?>();
      List<T>? list<T>(String k, T Function(Map<String, Object?>) f) =>
          (j[k] as List?)?.map((e) => f((e as Map).cast<String, Object?>())).toList();
      return BankSnapshot(
        accounts: list('accounts', BankMappers.accountFrom),
        transactions: list('transactions', BankMappers.transactionFrom),
        notifications: list('notifications', BankMappers.notificationFrom),
        beneficiaries: list('beneficiaries', BankMappers.beneficiaryFrom),
        savedAt: DateTime.parse(j['savedAt'] as String),
      );
    } catch (_) {
      // Corrupt cache is discarded, never trusted.
      await clear();
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
  }) async {
    final current = await read();
    final data = {
      'accounts': (accounts ?? current?.accounts)?.map(BankMappers.account).toList(),
      'transactions': (transactions ?? current?.transactions)?.map(BankMappers.transaction).toList(),
      'notifications': (notifications ?? current?.notifications)?.map(BankMappers.notification).toList(),
      'beneficiaries': (beneficiaries ?? current?.beneficiaries)?.map(BankMappers.beneficiary).toList(),
      'savedAt': at.toIso8601String(),
    };
    await _storage.write(key: _key, value: jsonEncode(data));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
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
    _snap = BankSnapshot(
      accounts: accounts ?? _snap?.accounts,
      transactions: transactions ?? _snap?.transactions,
      notifications: notifications ?? _snap?.notifications,
      beneficiaries: beneficiaries ?? _snap?.beneficiaries,
      savedAt: at,
    );
  }

  @override
  Future<void> clear() async => _snap = null;
}
