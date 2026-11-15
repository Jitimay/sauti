import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/bank_notification.dart';
import '../../domain/entities/bank_transaction.dart';
import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/data_freshness.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/bank_repository.dart';
import '../datasources/bank_snapshot_store.dart';
import 'simulated_bank_repository.dart';

/// Decorator adding offline read-through caching.
///
/// * Successful reads refresh the snapshot.
/// * On [NetworkFailure], reads fall back to the snapshot and are explicitly
///   marked [DataSource.cached] with the snapshot time.
/// * Writes (transfers, mark-read) are **never** cached or queued.
final class CachingBankRepository implements BankRepository {
  CachingBankRepository(this._remote, this._store);

  /// Upper bound on transactions kept in the encrypted offline snapshot.
  static const maxCachedTransactions = 200;

  final BankRepository _remote;
  final BankSnapshotStore _store;

  /// Test/demo introspection: debits actually applied by the simulated bank.
  int get debugRemoteAppliedTransfers => switch (_remote) {
    final SimulatedBankRepository sim => sim.appliedTransfers,
    _ => -1,
  };

  Future<Result<Fresh<T>>> _fallback<T>(
    Failure f,
    T? Function(BankSnapshot s) pick,
    DateTime Function(BankSnapshot s) savedAt,
  ) async {
    if (f is! NetworkFailure) return Err(f);
    final snap = await _store.read();
    final data = snap == null ? null : pick(snap);
    if (snap == null || data == null) return Err(f);
    return Ok(Fresh(data, source: DataSource.cached, asOf: savedAt(snap)));
  }

  @override
  Future<Result<Fresh<List<Account>>>> getAccounts() async {
    final r = await _remote.getAccounts();
    switch (r) {
      case Ok(:final value):
        await _store.save(accounts: value.data, at: value.asOf);
        return r;
      case Err(:final failure):
        return _fallback(failure, (s) => s.accounts, (s) => s.accountsAt);
    }
  }

  @override
  Future<Result<Fresh<List<BankTransaction>>>> getTransactions(TransactionQuery query) async {
    final r = await _remote.getTransactions(query);
    switch (r) {
      case Ok(:final value):
        // Only an unfiltered "newest N" page is a faithful slice of history.
        // Merge it into the snapshot instead of replacing it, so a short page
        // (the dashboard shows 4) never shrinks what is available offline.
        if (query == TransactionQuery(limit: query.limit)) {
          final cached = (await _store.read())?.transactions ?? const <BankTransaction>[];
          final fresh = {for (final t in value.data) t.id};
          final merged = [...value.data, ...cached.where((t) => !fresh.contains(t.id))]
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          await _store.save(transactions: merged.take(maxCachedTransactions).toList(), at: value.asOf);
        }
        return r;
      case Err(:final failure):
        // Deterministic local filtering on whatever is cached.
        return _fallback(
          failure,
          (s) => s.transactions?.where(query.matches).take(query.limit).toList(),
          (s) => s.transactionsAt,
        );
    }
  }

  @override
  Future<Result<BankTransaction>> getTransaction(String id) async {
    final r = await _remote.getTransaction(id);
    if (r case Err(failure: NetworkFailure())) {
      final cached = (await _store.read())?.transactions?.where((t) => t.id == id).firstOrNull;
      if (cached != null) return Ok(cached);
    }
    return r;
  }

  @override
  Future<Result<List<Beneficiary>>> getBeneficiaries() async {
    final r = await _remote.getBeneficiaries();
    switch (r) {
      case Ok(:final value):
        await _store.save(beneficiaries: value, at: DateTime.now());
        return r;
      case Err(:final failure):
        if (failure is! NetworkFailure) return r;
        final cached = (await _store.read())?.beneficiaries;
        return cached == null ? r : Ok(cached);
    }
  }

  @override
  Future<Result<Fresh<List<BankNotification>>>> getNotifications() async {
    final r = await _remote.getNotifications();
    switch (r) {
      case Ok(:final value):
        await _store.save(notifications: value.data, at: value.asOf);
        return r;
      case Err(:final failure):
        return _fallback(failure, (s) => s.notifications, (s) => s.notificationsAt);
    }
  }

  @override
  Future<Result<void>> markNotificationRead(String id) => _remote.markNotificationRead(id);

  @override
  Future<Result<int>> outgoingTransferredToday() => _remote.outgoingTransferredToday();

  @override
  Future<Result<TransferReceipt>> submitTransfer(TransferRequest request) => _remote.submitTransfer(request);
}
