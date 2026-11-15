import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/bank_notification.dart';
import '../../domain/entities/bank_transaction.dart';
import '../../domain/entities/beneficiary.dart';
import '../../domain/entities/data_freshness.dart';
import '../../domain/entities/transaction_query.dart';
import '../../domain/entities/transfer.dart';
import '../../domain/repositories/bank_repository.dart';
import '../models/bank_mappers.dart';

/// LIVE-mode sandbox bank backed by Firestore (reads, restricted by security
/// rules to the signed-in user) and a Cloud Function (`submitTransfer`) that
/// performs all money movement server-side with idempotency.
///
/// Requires a configured Firebase project; see docs/FIREBASE_SETUP.md.
final class FirebaseBankRepository implements BankRepository {
  FirebaseBankRepository({
    required FirebaseFirestore firestore,
    required this._functions,
    required String? Function() currentUserId,
  })  : _db = firestore,
        _uid = currentUserId;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final String? Function() _uid;

  Future<Result<T>> _guard<T>(Future<T> Function(DocumentReference<Map<String, dynamic>> user) body) async {
    final uid = _uid();
    if (uid == null) return const Err(AuthFailure(FailureCode.unauthorized, 'no user'));
    try {
      return Ok(await body(_db.collection('users').doc(uid)));
    } on FirebaseException catch (e) {
      return Err(_map(e.code, e.message));
    } on FormatException catch (e) {
      return Err(ServerFailure('malformed document: ${e.message}'));
    } catch (e) {
      return Err(UnexpectedFailure(e.runtimeType.toString()));
    }
  }

  static Failure _map(String code, String? msg) => switch (code) {
        'unavailable' || 'deadline-exceeded' => NetworkFailure(msg),
        'permission-denied' || 'unauthenticated' => AuthFailure(FailureCode.unauthorized, msg),
        'not-found' => NotFoundFailure(msg),
        'invalid-argument' => ValidationFailure(FailureCode.validation, msg),
        'failed-precondition' => switch (msg) {
            'insufficient_funds' => const TransferFailure(FailureCode.insufficientFunds),
            'limit_exceeded' => const ValidationFailure(FailureCode.limitExceeded),
            'unknown_beneficiary' => const ValidationFailure(FailureCode.beneficiaryNotFound),
            'invalid_amount' => const ValidationFailure(FailureCode.invalidAmount),
            'idempotency_conflict' => const TransferFailure(FailureCode.duplicateRequest),
            _ => TransferFailure(FailureCode.transferRejected, msg),
          },
        _ => ServerFailure('$code: $msg'),
      };

  static Map<String, Object?> _withId(DocumentSnapshot<Map<String, dynamic>> d) {
    final data = Map<String, Object?>.from(d.data() ?? const {});
    data['id'] = d.id;
    // Firestore Timestamps → ISO strings for the shared mappers.
    data.updateAll((k, v) => v is Timestamp ? v.toDate().toIso8601String() : v);
    return data;
  }

  Fresh<T> _fresh<T>(T data, SnapshotMetadata meta) => Fresh(
        data,
        source: meta.isFromCache ? DataSource.cached : DataSource.live,
        asOf: DateTime.now(),
      );

  @override
  Future<Result<Fresh<List<Account>>>> getAccounts() => _guard((u) async {
        var s = await u.collection('accounts').get();
        if (s.docs.isEmpty && !s.metadata.isFromCache) {
          // First sign-in in the sandbox: the server provisions fictitious
          // data (idempotent). Clients cannot write accounts themselves.
          await _functions.httpsCallable('provisionSandboxAccount').call<Map<String, dynamic>>();
          s = await u.collection('accounts').get();
        }
        return _fresh(s.docs.map((d) => BankMappers.accountFrom(_withId(d))).toList(), s.metadata);
      });

  @override
  Future<Result<Fresh<List<BankTransaction>>>> getTransactions(TransactionQuery q) => _guard((u) async {
        Query<Map<String, dynamic>> ref = u.collection('transactions').orderBy('timestamp', descending: true);
        if (q.from != null) ref = ref.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(q.from!));
        if (q.to != null) ref = ref.where('timestamp', isLessThan: Timestamp.fromDate(q.to!));
        // Text/category/amount filters are applied client-side on the user's
        // own (rule-restricted) data to avoid many composite indexes.
        final s = await ref.limit(q.text == null && q.category == null ? q.limit : 500).get();
        final list = s.docs.map((d) => BankMappers.transactionFrom(_withId(d))).where(q.matches).take(q.limit);
        return _fresh(list.toList(), s.metadata);
      });

  @override
  Future<Result<BankTransaction>> getTransaction(String id) => _guard((u) async {
        final d = await u.collection('transactions').doc(id).get();
        if (!d.exists) throw FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
        return BankMappers.transactionFrom(_withId(d));
      });

  @override
  Future<Result<List<Beneficiary>>> getBeneficiaries() => _guard((u) async {
        final s = await u.collection('beneficiaries').get();
        return s.docs.map((d) => BankMappers.beneficiaryFrom(_withId(d))).toList();
      });

  @override
  Future<Result<Fresh<List<BankNotification>>>> getNotifications() => _guard((u) async {
        final s = await u.collection('notifications').orderBy('timestamp', descending: true).limit(50).get();
        return _fresh(s.docs.map((d) => BankMappers.notificationFrom(_withId(d))).toList(), s.metadata);
      });

  @override
  Future<Result<void>> markNotificationRead(String id) =>
      _guard((u) => u.collection('notifications').doc(id).update({'read': true}));

  @override
  Future<Result<int>> outgoingTransferredToday() => _guard((u) async {
        final now = DateTime.now();
        final s = await u
            .collection('transactions')
            .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
            .get();
        return s.docs
            .map((d) => BankMappers.transactionFrom(_withId(d)))
            .where((t) => !t.isIncoming && t.category == TransactionCategory.transfer)
            .fold<int>(0, (a, t) => a + t.amount.minorUnits);
      });

  @override
  Future<Result<TransferReceipt>> submitTransfer(TransferRequest r) async {
    try {
      final res = await _functions.httpsCallable('submitTransfer').call<Map<String, dynamic>>({
        'idempotencyKey': r.idempotencyKey,
        'fromAccountId': r.fromAccountId,
        'beneficiaryId': r.beneficiaryId,
        'amountMinor': r.amount.minorUnits,
        'currency': r.amount.currency.code,
        if (r.note != null) 'note': r.note,
      });
      final d = res.data;
      final currency = Currency.fromCode(d['currency'] as String);
      return Ok(TransferReceipt(
        reference: d['reference'] as String,
        idempotencyKey: d['idempotencyKey'] as String,
        beneficiaryName: d['beneficiaryName'] as String,
        beneficiaryMasked: d['beneficiaryMasked'] as String,
        amount: Money((d['amountMinor'] as num).toInt(), currency),
        fee: Money((d['feeMinor'] as num).toInt(), currency),
        newBalance: Money((d['newBalanceMinor'] as num).toInt(), currency),
        executedAt: DateTime.parse(d['executedAt'] as String),
        transactionId: d['transactionId'] as String,
      ));
    } on FirebaseFunctionsException catch (e) {
      return Err(_map(e.code, e.message));
    } catch (e) {
      // Unknown outcome: do NOT report success. The idempotency key makes a
      // user-initiated retry safe.
      return Err(UnexpectedFailure('transfer outcome unknown: ${e.runtimeType}'));
    }
  }
}
