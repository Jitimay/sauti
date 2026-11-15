import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/money/money.dart';
import '../../../../core/network/network_status.dart';
import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/transfer.dart';
import '../../../banking/domain/repositories/bank_repository.dart';
import '../../../banking/domain/services/beneficiary_resolver.dart';
import '../../../banking/domain/services/transfer_preparer.dart';

/// Outcome of preparing a transfer: either a draft, or a reason it couldn't
/// be prepared (including ambiguous recipients that need user choice).
sealed class PrepareTransferOutcome {
  const PrepareTransferOutcome();
}

final class TransferPrepared extends PrepareTransferOutcome {
  const TransferPrepared(this.draft);
  final TransferDraft draft;
}

final class TransferNeedsRecipientChoice extends PrepareTransferOutcome {
  const TransferNeedsRecipientChoice(this.resolution);
  final BeneficiaryAmbiguous resolution;
}

/// Steps 1–5 of the transfer workflow: resolve recipient among *saved*
/// beneficiaries, check live balance and limits, produce a draft.
/// Never executes the transfer and never runs offline.
final class PrepareTransfer {
  const PrepareTransfer(this._bank, this._preparer, this._network);

  final BankRepository _bank;
  final TransferPreparer _preparer;
  final NetworkStatus _network;

  Future<Result<PrepareTransferOutcome>> call({
    String? beneficiaryId,
    String? beneficiaryName,
    required Money amount,
    String? fromAccountId,
    String? note,
  }) async {
    if (!await _network.isOnline()) {
      return const Err(ServiceUnavailableFailure(FailureCode.offlineNotAllowed));
    }
    final amountFailure = _preparer.validateAmount(amount);
    if (amountFailure != null) return Err(amountFailure);

    final bens = await _bank.getBeneficiaries();
    if (bens case Err(:final failure)) return Err(failure);
    final saved = bens.valueOrNull!;

    final BeneficiaryResolution resolution;
    if (beneficiaryId != null) {
      final b = saved.where((b) => b.id == beneficiaryId).firstOrNull;
      resolution = b == null ? BeneficiaryUnknown(beneficiaryId) : BeneficiaryResolved(b);
    } else {
      resolution = _preparer.resolver.resolve(beneficiaryName ?? '', saved);
    }

    switch (resolution) {
      case BeneficiaryUnknown():
        return const Err(ValidationFailure(FailureCode.beneficiaryNotFound));
      case BeneficiaryAmbiguous():
        return Ok(TransferNeedsRecipientChoice(resolution));
      case BeneficiaryResolved(:final beneficiary):
        final accounts = await _bank.getAccounts();
        if (accounts case Err(:final failure)) return Err(failure);
        final fresh = accounts.valueOrNull!;
        if (fresh.isCached) {
          // Never authorise money movement against cached balances.
          return const Err(ServiceUnavailableFailure(FailureCode.offlineNotAllowed));
        }
        final Account? from = fromAccountId == null
            ? fresh.data.firstOrNull
            : fresh.data.where((a) => a.id == fromAccountId).firstOrNull;
        if (from == null) return const Err(NotFoundFailure('source account'));

        final today = await _bank.outgoingTransferredToday();
        if (today case Err(:final failure)) return Err(failure);

        return _preparer
            .prepare(
              from: from,
              beneficiary: beneficiary,
              amount: amount,
              transferredTodayMinor: today.valueOrNull!,
              note: note,
            )
            .map<PrepareTransferOutcome>(TransferPrepared.new);
    }
  }
}
