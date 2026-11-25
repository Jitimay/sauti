import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/clock.dart';
import '../entities/account.dart';
import '../entities/bank_notification.dart';
import '../entities/bank_transaction.dart';
import '../entities/beneficiary.dart';
import '../entities/data_freshness.dart';
import '../entities/transaction_query.dart';
import '../repositories/bank_repository.dart';
import '../services/spending_analyzer.dart';
import '../services/transaction_explainer.dart';

/// Thin read-side use cases. Each is independently injectable and testable.
final class GetAccounts {
  const GetAccounts(this._bank);
  final BankRepository _bank;
  Future<Result<Fresh<List<Account>>>> call() => _bank.getAccounts();
}

final class GetRecentTransactions {
  const GetRecentTransactions(this._bank);
  final BankRepository _bank;
  Future<Result<Fresh<List<BankTransaction>>>> call({int limit = 10}) =>
      _bank.getTransactions(TransactionQuery(limit: limit.clamp(1, 50)));
}

final class SearchTransactions {
  const SearchTransactions(this._bank);
  final BankRepository _bank;
  Future<Result<Fresh<List<BankTransaction>>>> call(TransactionQuery query) =>
      _bank.getTransactions(query);
}

final class GetTransactionDetails {
  const GetTransactionDetails(this._bank);
  final BankRepository _bank;
  Future<Result<BankTransaction>> call(String id) => _bank.getTransaction(id);
}

final class ListBeneficiaries {
  const ListBeneficiaries(this._bank);
  final BankRepository _bank;
  Future<Result<List<Beneficiary>>> call() => _bank.getBeneficiaries();
}

final class GetNotifications {
  const GetNotifications(this._bank);
  final BankRepository _bank;
  Future<Result<Fresh<List<BankNotification>>>> call() =>
      _bank.getNotifications();
}

final class MarkNotificationRead {
  const MarkNotificationRead(this._bank);
  final BankRepository _bank;
  Future<Result<void>> call(String id) => _bank.markNotificationRead(id);
}

final class CalculateMonthlySpending {
  const CalculateMonthlySpending(
    this._bank,
    this._clock, [
    this._analyzer = const SpendingAnalyzer(),
  ]);
  final BankRepository _bank;
  final Clock _clock;
  final SpendingAnalyzer _analyzer;

  Future<Result<Fresh<SpendingSummary>>> call({
    DateTime? month,
    TransactionCategory? category,
  }) async {
    final m = month ?? _clock.now();
    final from = DateTime(m.year, m.month - 1);
    final to = DateTime(m.year, m.month + 1);
    final res = await _bank.getTransactions(
      TransactionQuery(from: from, to: to, limit: 1000),
    );
    return res.map(
      (fresh) => fresh.map(
        (txs) => _analyzer.monthly(
          txs,
          month: m,
          currency: Currency.bif,
          onlyCategory: category,
        ),
      ),
    );
  }
}

final class ExplainTransaction {
  const ExplainTransaction(
    this._bank, [
    this._explainer = const TransactionExplainer(),
  ]);
  final BankRepository _bank;
  final TransactionExplainer _explainer;

  /// Explains [id], or the most recent transaction when [id] is null.
  Future<Result<TransactionExplanation>> call({String? id}) async {
    final all = await _bank.getTransactions(
      const TransactionQuery(limit: 1000),
    );
    return all.then((fresh) async {
      final list = fresh.data;
      if (list.isEmpty) return const Err(NotFoundFailure('no transactions'));
      final tx = id == null
          ? list.first
          : list.where((t) => t.id == id).firstOrNull;
      if (tx == null) {
        final single = await _bank.getTransaction(id!);
        return single.map((t) => _explainer.explain(t, list));
      }
      return Ok(_explainer.explain(tx, list));
    });
  }
}
