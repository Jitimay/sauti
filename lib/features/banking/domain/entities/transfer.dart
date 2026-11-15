import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'beneficiary.dart';

/// Request sent to the bank. The [idempotencyKey] guarantees at-most-once
/// execution even if the request is retried.
final class TransferRequest extends Equatable {
  const TransferRequest({
    required this.idempotencyKey,
    required this.fromAccountId,
    required this.beneficiaryId,
    required this.amount,
    this.note,
  });

  final String idempotencyKey;
  final String fromAccountId;
  final String beneficiaryId;
  final Money amount;
  final String? note;

  @override
  List<Object?> get props => [idempotencyKey, fromAccountId, beneficiaryId, amount, note];
}

/// A validated, not-yet-executed transfer. Creating a draft never moves money.
final class TransferDraft extends Equatable {
  const TransferDraft({
    required this.id,
    required this.idempotencyKey,
    required this.fromAccountId,
    required this.fromAccountMasked,
    required this.beneficiary,
    required this.amount,
    required this.fee,
    required this.balanceBefore,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String idempotencyKey;
  final String fromAccountId;
  final String fromAccountMasked;
  final Beneficiary beneficiary;
  final Money amount;
  final Money fee;
  final Money balanceBefore;
  final DateTime createdAt;
  final String? note;

  Money get total => amount + fee;
  Money get balanceAfter => balanceBefore - total;

  TransferRequest toRequest() => TransferRequest(
        idempotencyKey: idempotencyKey,
        fromAccountId: fromAccountId,
        beneficiaryId: beneficiary.id,
        amount: amount,
        note: note,
      );

  @override
  List<Object?> get props =>
      [id, idempotencyKey, fromAccountId, fromAccountMasked, beneficiary, amount, fee, balanceBefore, createdAt, note];
}

/// Returned by the bank only after the debit has actually been recorded.
final class TransferReceipt extends Equatable {
  const TransferReceipt({
    required this.reference,
    required this.idempotencyKey,
    required this.beneficiaryName,
    required this.beneficiaryMasked,
    required this.amount,
    required this.fee,
    required this.newBalance,
    required this.executedAt,
    required this.transactionId,
  });

  final String reference;
  final String idempotencyKey;
  final String beneficiaryName;
  final String beneficiaryMasked;
  final Money amount;
  final Money fee;
  final Money newBalance;
  final DateTime executedAt;
  final String transactionId;

  @override
  List<Object?> get props =>
      [reference, idempotencyKey, beneficiaryName, beneficiaryMasked, amount, fee, newBalance, executedAt, transactionId];
}
