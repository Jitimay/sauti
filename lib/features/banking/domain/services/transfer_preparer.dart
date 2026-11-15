import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/clock.dart';
import '../entities/account.dart';
import '../entities/beneficiary.dart';
import '../entities/transfer.dart';
import '../entities/transfer_policy.dart';
import 'beneficiary_resolver.dart';

typedef IdGenerator = String Function();

/// Validates a transfer intent against business rules and produces a draft.
/// Pure logic — repository I/O happens in the use case.
final class TransferPreparer {
  const TransferPreparer({
    required this.policy,
    required this.clock,
    required this.newId,
    this.resolver = const BeneficiaryResolver(),
  });

  final TransferPolicy policy;
  final Clock clock;
  final IdGenerator newId;
  final BeneficiaryResolver resolver;

  /// Validates amount bounds independent of balance.
  Failure? validateAmount(Money amount) {
    if (amount.currency != policy.minimum.currency) {
      return const ValidationFailure(FailureCode.invalidAmount, 'currency');
    }
    if (!amount.isPositive || amount < policy.minimum) {
      return const ValidationFailure(FailureCode.invalidAmount, 'below minimum');
    }
    if (amount > policy.perTransferLimit) {
      return const ValidationFailure(FailureCode.limitExceeded, 'per-transfer limit');
    }
    return null;
  }

  Result<TransferDraft> prepare({
    required Account from,
    required Beneficiary beneficiary,
    required Money amount,
    required int transferredTodayMinor,
    String? note,
  }) {
    final amountFailure = validateAmount(amount);
    if (amountFailure != null) return Err(amountFailure);

    final total = amount + policy.flatFee;
    if (transferredTodayMinor + amount.minorUnits > policy.dailyLimit.minorUnits) {
      return const Err(ValidationFailure(FailureCode.limitExceeded, 'daily limit'));
    }
    if (total > from.availableBalance) {
      return const Err(TransferFailure(FailureCode.insufficientFunds));
    }
    final sanitizedNote = note?.trim();
    return Ok(TransferDraft(
      id: newId(),
      idempotencyKey: newId(),
      fromAccountId: from.id,
      fromAccountMasked: from.maskedNumber,
      beneficiary: beneficiary,
      amount: amount,
      fee: policy.flatFee,
      balanceBefore: from.availableBalance,
      createdAt: clock.now(),
      note: (sanitizedNote == null || sanitizedNote.isEmpty)
          ? null
          : sanitizedNote.substring(0, sanitizedNote.length.clamp(0, 140)),
    ));
  }
}
