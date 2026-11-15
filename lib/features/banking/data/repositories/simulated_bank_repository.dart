import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/network_status.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/bank_notification.dart';
import '../../domain/entities/bank_transaction.dart';
import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/data_freshness.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/entities/transfer_policy.dart';
import '../../domain/repositories/bank_repository.dart';
import '../demo/demo_seed.dart';

/// In-memory **simulated** bank used only in DEMO mode.
///
/// It behaves like a server: it re-validates every transfer independently of
/// the client (limits, balance, beneficiary ownership), enforces idempotency,
/// and only returns a receipt after mutating its ledger. It fails with
/// [NetworkFailure] when the device is offline.
final class SimulatedBankRepository implements BankRepository {
  SimulatedBankRepository({
    required Clock clock,
    required this._network,
    this._policy = TransferPolicy.bifDefault,
    this._latency = const Duration(milliseconds: 450),
    DemoSeed? seed,
  }) : _clock = clock {
    final s = seed ?? DemoSeed(clock.now());
    _accounts = {for (final a in s.accounts()) a.id: a};
    _transactions = s.transactions();
    _beneficiaries = s.beneficiaries();
    _notifications = s.notifications();
  }

  final Clock _clock;
  final NetworkStatus _network;
  final TransferPolicy _policy;
  final Duration _latency;

  late Map<String, Account> _accounts;
  late List<BankTransaction> _transactions;
  late List<Beneficiary> _beneficiaries;
  late List<BankNotification> _notifications;
  final Map<String, TransferReceipt> _idempotency = {};
  final Map<String, Future<Result<TransferReceipt>>> _inFlight = {};
  int _seq = 1000;

  /// Visible for tests: number of debits actually applied.
  int appliedTransfers = 0;

  Future<Failure?> _roundTrip() async {
    if (_latency > Duration.zero) await Future<void>.delayed(_latency);
    if (!await _network.isOnline()) return const NetworkFailure('simulated bank unreachable');
    return null;
  }

  @override
  Future<Result<Fresh<List<Account>>>> getAccounts() async {
    final f = await _roundTrip();
    if (f != null) return Err(f);
    return Ok(Fresh.live(_accounts.values.toList(growable: false), _clock.now()));
  }

  @override
  Future<Result<Fresh<List<BankTransaction>>>> getTransactions(TransactionQuery query) async {
    final f = await _roundTrip();
    if (f != null) return Err(f);
    final list = _transactions.where(query.matches).take(query.limit).toList(growable: false);
    return Ok(Fresh.live(list, _clock.now()));
  }

  @override
  Future<Result<BankTransaction>> getTransaction(String id) async {
    final f = await _roundTrip();
    if (f != null) return Err(f);
    final t = _transactions.where((t) => t.id == id).firstOrNull;
    return t == null ? const Err(NotFoundFailure('transaction')) : Ok(t);
  }

  @override
  Future<Result<List<Beneficiary>>> getBeneficiaries() async {
    final f = await _roundTrip();
    if (f != null) return Err(f);
    return Ok(List.unmodifiable(_beneficiaries));
  }

  @override
  Future<Result<Fresh<List<BankNotification>>>> getNotifications() async {
    final f = await _roundTrip();
    if (f != null) return Err(f);
    final list = [..._notifications]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Ok(Fresh.live(list, _clock.now()));
  }

  @override
  Future<Result<void>> markNotificationRead(String id) async {
    final f = await _roundTrip();
    if (f != null) return Err(f);
    _notifications = [for (final n in _notifications) n.id == id ? n.markRead() : n];
    return const Ok(null);
  }

  @override
  Future<Result<int>> outgoingTransferredToday() async {
    final f = await _roundTrip();
    if (f != null) return Err(f);
    return Ok(_todayOutgoingTransfers());
  }

  int _todayOutgoingTransfers() {
    final now = _clock.now();
    final start = DateTime(now.year, now.month, now.day);
    return _transactions
        .where((t) => !t.isIncoming && t.category == TransactionCategory.transfer && !t.timestamp.isBefore(start))
        .fold(0, (a, t) => a + t.amount.minorUnits);
  }

  @override
  Future<Result<TransferReceipt>> submitTransfer(TransferRequest request) {
    // Idempotency: concurrent duplicates share one execution.
    final existing = _inFlight[request.idempotencyKey];
    if (existing != null) return existing;
    final future = _execute(request);
    _inFlight[request.idempotencyKey] = future;
    return future.whenComplete(() => _inFlight.remove(request.idempotencyKey));
  }

  Future<Result<TransferReceipt>> _execute(TransferRequest r) async {
    final f = await _roundTrip();
    if (f != null) return Err(f);

    final prior = _idempotency[r.idempotencyKey];
    if (prior != null) {
      final sameRequest = prior.amount == r.amount;
      return sameRequest ? Ok(prior) : const Err(TransferFailure(FailureCode.duplicateRequest, 'key reuse'));
    }

    // --- Server-side validation (never trust the client) ---
    final from = _accounts[r.fromAccountId];
    if (from == null) return const Err(PermissionFailure(FailureCode.unauthorized, 'account not owned'));
    final ben = _beneficiaries.where((b) => b.id == r.beneficiaryId).firstOrNull;
    if (ben == null) return const Err(ValidationFailure(FailureCode.beneficiaryNotFound));
    if (r.amount.currency != from.balance.currency || !r.amount.isPositive || r.amount < _policy.minimum) {
      return const Err(ValidationFailure(FailureCode.invalidAmount));
    }
    if (r.amount > _policy.perTransferLimit ||
        _todayOutgoingTransfers() + r.amount.minorUnits > _policy.dailyLimit.minorUnits) {
      return const Err(ValidationFailure(FailureCode.limitExceeded));
    }
    final total = r.amount + _policy.flatFee;
    if (total > from.availableBalance) return const Err(TransferFailure(FailureCode.insufficientFunds));

    // --- Apply ---
    final now = _clock.now();
    final updated = from.copyWith(balance: from.balance - total, availableBalance: from.availableBalance - total);
    _accounts[from.id] = updated;
    final txId = 'tx${_seq++}';
    final ref = 'SAUTI-DEMO-${now.millisecondsSinceEpoch.toRadixString(36).toUpperCase()}';
    _transactions = [
      BankTransaction(
        id: txId,
        accountId: from.id,
        direction: TransactionDirection.outgoing,
        amount: r.amount,
        counterparty: ben.name,
        category: TransactionCategory.transfer,
        description: r.note == null ? 'Transfer sent' : 'Transfer sent — ${r.note}',
        timestamp: now,
        fee: _policy.flatFee.isZero ? null : _policy.flatFee,
        reference: ref,
      ),
      ..._transactions,
    ];
    _notifications = [
      BankNotification(
        id: 'n-$txId',
        kind: NotificationKind.transferSent,
        timestamp: now,
        amount: r.amount,
        counterparty: ben.name,
        transactionId: txId,
      ),
      ..._notifications,
    ];
    appliedTransfers++;
    final receipt = TransferReceipt(
      reference: ref,
      idempotencyKey: r.idempotencyKey,
      beneficiaryName: ben.name,
      beneficiaryMasked: ben.maskedAccount,
      amount: r.amount,
      fee: _policy.flatFee.isZero ? Money.zero(r.amount.currency) : _policy.flatFee,
      newBalance: updated.availableBalance,
      executedAt: now,
      transactionId: txId,
    );
    _idempotency[r.idempotencyKey] = receipt;
    return Ok(receipt);
  }
}
