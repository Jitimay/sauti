import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/view_status.dart';
import '../../../banking/domain/entities/bank_transaction.dart';
import '../../../banking/domain/entities/data_freshness.dart';
import '../../../banking/domain/entities/transaction_query.dart';
import '../../../banking/domain/services/transaction_explainer.dart';
import '../../../banking/domain/usecases/banking_usecases.dart';

sealed class TransactionEvent extends Equatable {
  const TransactionEvent();
  @override
  List<Object?> get props => [];
}

final class TransactionsLoadRequested extends TransactionEvent {
  const TransactionsLoadRequested();
}

final class TransactionFilterChanged extends TransactionEvent {
  const TransactionFilterChanged({this.direction, this.text});
  final TransactionDirection? direction;
  final String? text;
  @override
  List<Object?> get props => [direction, text];
}

final class TransactionState extends Equatable {
  const TransactionState({
    this.status = ViewStatus.initial,
    this.transactions,
    this.direction,
    this.text = '',
    this.failure,
  });

  final ViewStatus status;
  final Fresh<List<BankTransaction>>? transactions;
  final TransactionDirection? direction;
  final String text;
  final Failure? failure;

  TransactionState copyWith({
    ViewStatus? status,
    Fresh<List<BankTransaction>>? transactions,
    TransactionDirection? Function()? direction,
    String? text,
    Failure? Function()? failure,
  }) =>
      TransactionState(
        status: status ?? this.status,
        transactions: transactions ?? this.transactions,
        direction: direction != null ? direction() : this.direction,
        text: text ?? this.text,
        failure: failure != null ? failure() : this.failure,
      );

  @override
  List<Object?> get props => [status, transactions, direction, text, failure];
}

final class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc(this._search) : super(const TransactionState()) {
    on<TransactionsLoadRequested>((e, emit) => _load(emit), transformer: restartable());
    // Typing triggers rapid filter events; restartable cancels stale searches.
    on<TransactionFilterChanged>((e, emit) async {
      emit(state.copyWith(direction: () => e.direction, text: e.text ?? state.text));
      await _load(emit);
    }, transformer: restartable());
  }

  final SearchTransactions _search;

  Future<void> _load(Emitter<TransactionState> emit) async {
    emit(state.copyWith(status: ViewStatus.loading, failure: () => null));
    final r = await _search(TransactionQuery(
      direction: state.direction,
      text: state.text.trim().isEmpty ? null : state.text.trim(),
      limit: 50,
    ));
    switch (r) {
      case Ok(:final value):
        emit(state.copyWith(status: value.data.isEmpty ? ViewStatus.empty : ViewStatus.success, transactions: value));
      case Err(:final failure):
        emit(state.copyWith(status: ViewStatus.failure, failure: () => failure));
    }
  }
}

// ---- Details ----
final class TransactionDetailsState extends Equatable {
  const TransactionDetailsState({this.status = ViewStatus.initial, this.explanation, this.failure});
  final ViewStatus status;
  final TransactionExplanation? explanation;
  final Failure? failure;
  @override
  List<Object?> get props => [status, explanation, failure];
}

final class TransactionDetailsCubit extends Cubit<TransactionDetailsState> {
  TransactionDetailsCubit(this._explain) : super(const TransactionDetailsState());
  final ExplainTransaction _explain;

  Future<void> load(String id) async {
    emit(const TransactionDetailsState(status: ViewStatus.loading));
    final r = await _explain(id: id);
    emit(switch (r) {
      Ok(:final value) => TransactionDetailsState(status: ViewStatus.success, explanation: value),
      Err(:final failure) => TransactionDetailsState(status: ViewStatus.failure, failure: failure),
    });
  }
}
