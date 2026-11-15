import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'bank_transaction.dart';

/// Typed, validated filter for transaction search.
final class TransactionQuery extends Equatable {
  const TransactionQuery({
    this.text,
    this.direction,
    this.category,
    this.from,
    this.to,
    this.amount,
    this.limit = 20,
  });

  final String? text;
  final TransactionDirection? direction;
  final TransactionCategory? category;
  final DateTime? from;
  final DateTime? to;
  final Money? amount;
  final int limit;

  bool matches(BankTransaction t) {
    if (direction != null && t.direction != direction) return false;
    if (category != null && t.category != category) return false;
    if (from != null && t.timestamp.isBefore(from!)) return false;
    if (to != null && !t.timestamp.isBefore(to!)) return false;
    if (amount != null && t.amount != amount) return false;
    if (text != null && text!.trim().isNotEmpty) {
      final q = _fold(text!);
      if (!_fold(t.counterparty).contains(q) && !_fold(t.description).contains(q)) return false;
    }
    return true;
  }

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  @override
  List<Object?> get props => [text, direction, category, from, to, amount, limit];
}
