import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/network_status.dart';
import '../../../../core/utils/clock.dart';
import '../../../banking/domain/entities/transfer.dart';
import '../../../banking/domain/repositories/bank_repository.dart';
import '../entities/transfer_authorization.dart';

/// Step 9–10: submits a draft *only* with a valid, unexpired user
/// authorization bound to that draft, and returns the bank-verified receipt.
final class SubmitTransfer {
  const SubmitTransfer(this._bank, this._clock, this._network);

  final BankRepository _bank;
  final Clock _clock;
  final NetworkStatus _network;

  Future<Result<TransferReceipt>> call(TransferDraft draft, TransferAuthorization? authorization) async {
    if (authorization == null || !authorization.isValidAt(_clock.now(), draft.idempotencyKey)) {
      return const Err(AuthFailure(FailureCode.authExpired));
    }
    if (!await _network.isOnline()) {
      // Transfers are never queued for later execution.
      return const Err(ServiceUnavailableFailure(FailureCode.offlineNotAllowed));
    }
    final result = await _bank.submitTransfer(draft.toRequest());
    return switch (result) {
      Ok(:final value) when value.idempotencyKey != draft.idempotencyKey || value.amount != draft.amount =>
        const Err(ServerFailure('receipt does not match request')),
      _ => result,
    };
  }
}
