import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/clock.dart';
import '../../../banking/domain/entities/beneficiary.dart';
import '../../../banking/domain/entities/transfer.dart';
import '../../../banking/domain/entities/transfer_policy.dart';
import '../../../banking/domain/usecases/banking_usecases.dart';
import '../../domain/entities/transfer_authorization.dart';
import '../../domain/entities/transfer_stage.dart';
import '../../domain/repositories/transfer_authenticator.dart';
import '../../domain/usecases/prepare_transfer.dart';
import '../../domain/usecases/submit_transfer.dart';

// ---- Events ----
sealed class TransferEvent extends Equatable {
  const TransferEvent();
  @override
  List<Object?> get props => [];
}

final class TransferStarted extends TransferEvent {
  const TransferStarted();
}

/// Manual form: build a draft for a saved beneficiary.
final class TransferDraftRequested extends TransferEvent {
  const TransferDraftRequested({required this.beneficiaryId, required this.amount, this.note});
  final String beneficiaryId;
  final Money amount;
  final String? note;
  @override
  List<Object?> get props => [beneficiaryId, amount, note];
}

/// A draft prepared by the agent (validated by PrepareTransfer).
final class TransferDraftCreated extends TransferEvent {
  const TransferDraftCreated(this.draft);
  final TransferDraft draft;
  @override
  List<Object?> get props => [draft];
}

final class TransferAuthenticationRequested extends TransferEvent {
  const TransferAuthenticationRequested(this.reason);
  final String reason;
  @override
  List<Object?> get props => [reason];
}

final class TransferPasswordSubmitted extends TransferEvent {
  const TransferPasswordSubmitted(this.password);
  final String password;
  @override
  List<Object?> get props => const []; // never expose
}

/// The explicit final confirmation (user pressed "Send").
final class TransferSubmitted extends TransferEvent {
  const TransferSubmitted();
}

final class TransferCancelled extends TransferEvent {
  const TransferCancelled();
}

// ---- State ----
final class TransferState extends Equatable {
  const TransferState({
    this.stage = TransferStage.idle,
    this.beneficiaries = const [],
    this.draft,
    this.authorization,
    this.receipt,
    this.failure,
    this.deviceAuthAvailable = true,
    this.outcomeUnknown = false,
  });

  final TransferStage stage;
  final List<Beneficiary> beneficiaries;
  final TransferDraft? draft;
  final TransferAuthorization? authorization;

  /// Only set after the bank confirmed execution.
  final TransferReceipt? receipt;
  final Failure? failure;
  final bool deviceAuthAvailable;

  /// True when the submission result could not be confirmed (e.g. timeout).
  final bool outcomeUnknown;

  TransferState copyWith({
    TransferStage? stage,
    List<Beneficiary>? beneficiaries,
    TransferDraft? Function()? draft,
    TransferAuthorization? Function()? authorization,
    TransferReceipt? Function()? receipt,
    Failure? Function()? failure,
    bool? deviceAuthAvailable,
    bool? outcomeUnknown,
  }) =>
      TransferState(
        stage: stage ?? this.stage,
        beneficiaries: beneficiaries ?? this.beneficiaries,
        draft: draft != null ? draft() : this.draft,
        authorization: authorization != null ? authorization() : this.authorization,
        receipt: receipt != null ? receipt() : this.receipt,
        failure: failure != null ? failure() : this.failure,
        deviceAuthAvailable: deviceAuthAvailable ?? this.deviceAuthAvailable,
        outcomeUnknown: outcomeUnknown ?? this.outcomeUnknown,
      );

  @override
  List<Object?> get props =>
      [stage, beneficiaries, draft, authorization, receipt, failure, deviceAuthAvailable, outcomeUnknown];
}

// ---- Bloc ----
/// Drives the transfer state machine. Every transition is validated by
/// [TransferStateMachine]; submission requires a fresh user authorization
/// and is protected against duplicates (droppable + idempotency key).
final class TransferBloc extends Bloc<TransferEvent, TransferState> {
  TransferBloc({
    required this._prepare,
    required this._submit,
    required this._beneficiaries,
    required this._authenticator,
    required this._clock,
    this._policy = TransferPolicy.bifDefault,
  }) : super(const TransferState()) {
    on<TransferStarted>(_onStarted, transformer: restartable());
    on<TransferDraftRequested>(_onDraftRequested, transformer: droppable());
    on<TransferDraftCreated>(_onDraftCreated, transformer: droppable());
    on<TransferAuthenticationRequested>(_onAuthDevice, transformer: droppable());
    on<TransferPasswordSubmitted>(_onAuthPassword, transformer: droppable());
    on<TransferSubmitted>(_onSubmit, transformer: droppable());
    on<TransferCancelled>(_onCancel);
  }

  final PrepareTransfer _prepare;
  final SubmitTransfer _submit;
  final ListBeneficiaries _beneficiaries;
  final TransferAuthenticator _authenticator;
  final Clock _clock;
  final TransferPolicy _policy;
  static const _machine = TransferStateMachine();

  bool _can(TransferStage to) => _machine.canTransition(state.stage, to);

  Future<void> _onStarted(TransferStarted e, Emitter<TransferState> emit) async {
    if (state.stage == TransferStage.submitting) return; // never reset an in-flight submission
    emit(const TransferState());
    final avail = await _authenticator.availability();
    final r = await _beneficiaries();
    emit(state.copyWith(
      beneficiaries: r.valueOrNull ?? const [],
      failure: () => r.failureOrNull,
      deviceAuthAvailable: avail.deviceAuthAvailable,
    ));
  }

  Future<void> _onDraftRequested(TransferDraftRequested e, Emitter<TransferState> emit) async {
    if (!_can(TransferStage.drafting)) return;
    emit(state.copyWith(stage: TransferStage.drafting, failure: () => null, receipt: () => null));
    final r = await _prepare(beneficiaryId: e.beneficiaryId, amount: e.amount, note: e.note);
    switch (r) {
      case Ok(value: TransferPrepared(:final draft)):
        emit(state.copyWith(stage: TransferStage.awaitingAuthentication, draft: () => draft));
      case Ok(value: TransferNeedsRecipientChoice()):
        emit(state.copyWith(stage: TransferStage.failed, failure: () => const ValidationFailure(FailureCode.beneficiaryAmbiguous)));
      case Err(:final failure):
        emit(state.copyWith(stage: TransferStage.failed, failure: () => failure));
    }
  }

  Future<void> _onDraftCreated(TransferDraftCreated e, Emitter<TransferState> emit) async {
    // A submission in flight must finish (and show its receipt or failure)
    // before another draft can take over the flow.
    if (state.stage == TransferStage.submitting) return;
    final avail = await _authenticator.availability();
    if (state.stage == TransferStage.submitting) return;
    emit(TransferState(
      stage: TransferStage.awaitingAuthentication,
      draft: e.draft,
      beneficiaries: state.beneficiaries,
      deviceAuthAvailable: avail.deviceAuthAvailable,
    ));
  }

  Future<void> _onAuthDevice(TransferAuthenticationRequested e, Emitter<TransferState> emit) =>
      _authenticate(emit, () => _authenticator.authenticateWithDevice(reason: e.reason));

  Future<void> _onAuthPassword(TransferPasswordSubmitted e, Emitter<TransferState> emit) =>
      _authenticate(emit, () => _authenticator.authenticateWithPassword(e.password));

  Future<void> _authenticate(Emitter<TransferState> emit, Future<Result<AuthMethod>> Function() run) async {
    final draft = state.draft;
    if (draft == null || !_can(TransferStage.authenticating)) return;
    emit(state.copyWith(stage: TransferStage.authenticating, failure: () => null));
    final r = await run();
    if (state.stage != TransferStage.authenticating) return; // cancelled meanwhile
    switch (r) {
      case Ok(:final value):
        emit(state.copyWith(
          stage: TransferStage.awaitingConfirmation,
          authorization: () => TransferAuthorization(
            draftIdempotencyKey: draft.idempotencyKey,
            method: value,
            grantedAt: _clock.now(),
            validFor: _policy.authorizationValidity,
          ),
        ));
      case Err(:final failure):
        emit(state.copyWith(stage: TransferStage.awaitingAuthentication, failure: () => failure));
    }
  }

  Future<void> _onSubmit(TransferSubmitted e, Emitter<TransferState> emit) async {
    final draft = state.draft;
    final auth = state.authorization;
    if (draft == null || state.stage != TransferStage.awaitingConfirmation) return;
    if (auth == null || !auth.isValidAt(_clock.now(), draft.idempotencyKey)) {
      emit(state.copyWith(
        stage: TransferStage.awaitingAuthentication,
        authorization: () => null,
        failure: () => const AuthFailure(FailureCode.authExpired),
      ));
      return;
    }
    emit(state.copyWith(stage: TransferStage.submitting, failure: () => null));
    final r = await _submit(draft, auth);
    switch (r) {
      case Ok(:final value):
        emit(state.copyWith(stage: TransferStage.completed, receipt: () => value, authorization: () => null));
      case Err(:final failure):
        emit(state.copyWith(
          stage: TransferStage.failed,
          failure: () => failure,
          authorization: () => null,
          outcomeUnknown: failure is UnexpectedFailure,
        ));
    }
  }

  void _onCancel(TransferCancelled e, Emitter<TransferState> emit) {
    if (!_can(TransferStage.cancelled)) return; // e.g. cannot cancel while submitting
    emit(state.copyWith(stage: TransferStage.cancelled, authorization: () => null, failure: () => null));
  }
}
