import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import '../entities/bank_transaction.dart';

final class CategoryTotal extends Equatable {
  const CategoryTotal(this.category, this.total, this.count);
  final TransactionCategory category;
  final Money total;
  final int count;
  @override
  List<Object?> get props => [category, total, count];
}

final class SpendingSummary extends Equatable {
  const SpendingSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.totalSpent,
    required this.totalReceived,
    required this.byCategory,
    required this.previousPeriodSpent,
    required this.transactionCount,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final Money totalSpent;
  final Money totalReceived;

  /// Sorted descending by amount.
  final List<CategoryTotal> byCategory;
  final Money previousPeriodSpent;
  final int transactionCount;

  Money get net => totalReceived - totalSpent;

  /// Change vs previous period in whole percent, or null if no baseline.
  int? get changePercent {
    if (previousPeriodSpent.isZero) return null;
    final diff = totalSpent.minorUnits - previousPeriodSpent.minorUnits;
    return (diff * 100 / previousPeriodSpent.minorUnits).round();
  }

  CategoryTotal? get topCategory => byCategory.isEmpty ? null : byCategory.first;

  @override
  List<Object?> get props =>
      [periodStart, periodEnd, totalSpent, totalReceived, byCategory, previousPeriodSpent, transactionCount];
}

/// Deterministic spending calculations. The AI may *explain* these numbers;
/// it is never the source of them.
final class SpendingAnalyzer {
  const SpendingAnalyzer();

  SpendingSummary monthly(
    List<BankTransaction> all, {
    required DateTime month,
    Currency currency = Currency.bif,
    TransactionCategory? onlyCategory,
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final prevStart = DateTime(month.year, month.month - 1);
    return summarize(all,
        start: start, end: end, prevStart: prevStart, currency: currency, onlyCategory: onlyCategory);
  }

  SpendingSummary summarize(
    List<BankTransaction> all, {
    required DateTime start,
    required DateTime end,
    required DateTime prevStart,
    Currency currency = Currency.bif,
    TransactionCategory? onlyCategory,
  }) {
    bool inRange(BankTransaction t, DateTime s, DateTime e) =>
        !t.timestamp.isBefore(s) && t.timestamp.isBefore(e);
    bool counts(BankTransaction t) =>
        t.status == TransactionStatus.completed &&
        t.amount.currency == currency &&
        (onlyCategory == null || t.category == onlyCategory);

    final current = all.where((t) => counts(t) && inRange(t, start, end)).toList();
    final previous = all.where((t) => counts(t) && inRange(t, prevStart, start) && !t.isIncoming);

    final out = current.where((t) => !t.isIncoming);
    final inc = current.where((t) => t.isIncoming);

    final map = <TransactionCategory, (int, int)>{};
    for (final t in out) {
      final (sum, n) = map[t.category] ?? (0, 0);
      map[t.category] = (sum + t.amount.minorUnits, n + 1);
    }
    final cats = map.entries.map((e) => CategoryTotal(e.key, Money(e.value.$1, currency), e.value.$2)).toList()
      ..sort((a, b) => b.total.minorUnits.compareTo(a.total.minorUnits));

    return SpendingSummary(
      periodStart: start,
      periodEnd: end,
      totalSpent: Money.sum(out.map((t) => t.amount), currency),
      totalReceived: Money.sum(inc.map((t) => t.amount), currency),
      byCategory: cats,
      previousPeriodSpent: Money.sum(previous.map((t) => t.amount), currency),
      transactionCount: current.length,
    );
  }
}
