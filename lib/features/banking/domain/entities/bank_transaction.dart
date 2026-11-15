import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

enum TransactionDirection { incoming, outgoing }

enum TransactionCategory {
  income,
  transfer,
  transport,
  groceries,
  utilities,
  airtime,
  health,
  education,
  fees,
  other,
}

enum TransactionStatus { completed, pending, failed }

final class BankTransaction extends Equatable {
  const BankTransaction({
    required this.id,
    required this.accountId,
    required this.direction,
    required this.amount,
    required this.counterparty,
    required this.category,
    required this.description,
    required this.timestamp,
    this.status = TransactionStatus.completed,
    this.fee,
    this.reference,
  });

  final String id;
  final String accountId;
  final TransactionDirection direction;

  /// Always non-negative (enforced by mappers/bank). Sign is given by [direction].
  final Money amount;
  final String counterparty;
  final TransactionCategory category;

  /// Free text from the bank/merchant. Treated as *untrusted data* when given
  /// to an AI model (it can contain prompt-injection attempts).
  final String description;
  final DateTime timestamp;
  final TransactionStatus status;
  final Money? fee;
  final String? reference;

  bool get isIncoming => direction == TransactionDirection.incoming;

  /// Signed amount: positive for credits, negative for debits.
  Money get signedAmount => isIncoming ? amount : -amount;

  @override
  List<Object?> get props =>
      [id, accountId, direction, amount, counterparty, category, description, timestamp, status, fee, reference];
}
