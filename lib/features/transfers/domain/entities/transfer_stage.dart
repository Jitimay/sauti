/// Explicit state machine for a money transfer.
///
/// ```
/// idle → drafting → awaitingAuthentication → authenticating
///      → awaitingConfirmation → submitting → completed
/// any non-terminal stage → cancelled; drafting/authenticating/submitting → failed
/// failed(auth) → awaitingAuthentication (retry)
/// ```
enum TransferStage {
  idle,
  drafting,
  awaitingAuthentication,
  authenticating,
  awaitingConfirmation,
  submitting,
  completed,
  failed,
  cancelled;

  bool get isTerminal => this == completed || this == cancelled;
}

final class TransferStateMachine {
  const TransferStateMachine();

  static const Map<TransferStage, Set<TransferStage>> _allowed = {
    TransferStage.idle: {TransferStage.drafting, TransferStage.awaitingAuthentication},
    TransferStage.drafting: {TransferStage.awaitingAuthentication, TransferStage.failed, TransferStage.cancelled},
    TransferStage.awaitingAuthentication: {TransferStage.authenticating, TransferStage.cancelled},
    TransferStage.authenticating: {
      TransferStage.awaitingConfirmation,
      TransferStage.awaitingAuthentication,
      TransferStage.failed,
      TransferStage.cancelled,
    },
    TransferStage.awaitingConfirmation: {
      TransferStage.submitting,
      TransferStage.awaitingAuthentication, // authorization expired
      TransferStage.cancelled,
    },
    TransferStage.submitting: {TransferStage.completed, TransferStage.failed},
    TransferStage.failed: {TransferStage.awaitingAuthentication, TransferStage.drafting, TransferStage.cancelled},
    TransferStage.completed: {},
    TransferStage.cancelled: {TransferStage.drafting, TransferStage.awaitingAuthentication},
  };

  bool canTransition(TransferStage from, TransferStage to) => _allowed[from]!.contains(to);

  TransferStage transition(TransferStage from, TransferStage to) {
    if (!canTransition(from, to)) {
      throw StateError('Illegal transfer transition: ${from.name} → ${to.name}');
    }
    return to;
  }
}
