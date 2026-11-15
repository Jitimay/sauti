import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../entities/bank_transaction.dart';

/// Structured, verifiable facts about a transaction. Natural-language
/// explanations (template- or LLM-based) are generated *from* these facts.
final class TransactionExplanation extends Equatable {
  const TransactionExplanation({
    required this.transaction,
    required this.isRecurring,
    required this.similarCount,
    required this.categoryShareOfMonthPercent,
    this.fee,
  });

  final BankTransaction transaction;

  /// Same counterparty seen in ≥ 2 previous months.
  final bool isRecurring;

  /// Other transactions with the same counterparty in the dataset.
  final int similarCount;

  /// This transaction as % of the month's spending in its category (outgoing only).
  final int? categoryShareOfMonthPercent;
  final Money? fee;

  @override
  List<Object?> get props => [transaction, isRecurring, similarCount, categoryShareOfMonthPercent, fee];
}

final class TransactionExplainer {
  const TransactionExplainer();

  TransactionExplanation explain(BankTransaction tx, List<BankTransaction> history) {
    final same = history.where((t) => t.id != tx.id && t.counterparty == tx.counterparty).toList();
    final months = same.map((t) => t.timestamp.year * 12 + t.timestamp.month).toSet()
      ..remove(tx.timestamp.year * 12 + tx.timestamp.month);

    int? share;
    if (!tx.isIncoming) {
      final monthTotal = history
          .where((t) =>
              !t.isIncoming &&
              t.category == tx.category &&
              t.timestamp.year == tx.timestamp.year &&
              t.timestamp.month == tx.timestamp.month)
          .fold<int>(0, (a, t) => a + t.amount.minorUnits);
      if (monthTotal > 0) share = (tx.amount.minorUnits * 100 / monthTotal).round();
    }

    return TransactionExplanation(
      transaction: tx,
      isRecurring: months.length >= 2,
      similarCount: same.length,
      categoryShareOfMonthPercent: share,
      fee: tx.fee,
    );
  }
}
