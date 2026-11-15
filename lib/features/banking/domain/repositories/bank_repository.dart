import '../../../../core/error/result.dart';
import '../entities/account.dart';
import '../entities/bank_notification.dart';
import '../entities/bank_transaction.dart';
import '../entities/beneficiary.dart';
import '../entities/data_freshness.dart';
import '../entities/transaction_query.dart';
import '../entities/transfer.dart';

/// Contract for any banking backend (simulated demo bank, Firebase-backed
/// sandbox, or a future licensed banking API).
///
/// Implementations must:
/// * only return data belonging to the authenticated user;
/// * enforce transfer limits and balance checks server-side;
/// * honour [TransferRequest.idempotencyKey] (at-most-once execution);
/// * return a [TransferReceipt] only after the debit is durably recorded.
abstract interface class BankRepository {
  Future<Result<Fresh<List<Account>>>> getAccounts();

  Future<Result<Fresh<List<BankTransaction>>>> getTransactions(TransactionQuery query);

  Future<Result<BankTransaction>> getTransaction(String id);

  Future<Result<List<Beneficiary>>> getBeneficiaries();

  Future<Result<Fresh<List<BankNotification>>>> getNotifications();

  Future<Result<void>> markNotificationRead(String id);

  /// Sum of outgoing transfers today, used for daily-limit checks.
  Future<Result<int>> outgoingTransferredToday();

  Future<Result<TransferReceipt>> submitTransfer(TransferRequest request);
}
