import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/clock.dart';
import '../../../../core/utils/view_status.dart';
import '../../../banking/domain/entities/data_freshness.dart';
import '../../../banking/domain/services/spending_analyzer.dart';
import '../../../banking/domain/usecases/banking_usecases.dart';

sealed class InsightsEvent extends Equatable {
  const InsightsEvent();
  @override
  List<Object?> get props => [];
}

final class InsightsRequested extends InsightsEvent {
  const InsightsRequested({this.monthOffset = 0});
  final int monthOffset;
  @override
  List<Object?> get props => [monthOffset];
}

final class InsightsState extends Equatable {
  const InsightsState({this.status = ViewStatus.initial, this.monthOffset = 0, this.summary, this.failure});
  final ViewStatus status;
  final int monthOffset;
  final Fresh<SpendingSummary>? summary;
  final Failure? failure;
  @override
  List<Object?> get props => [status, monthOffset, summary, failure];
}

final class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  InsightsBloc(this._calc, this._clock) : super(const InsightsState()) {
    on<InsightsRequested>((e, emit) async {
      emit(InsightsState(status: ViewStatus.loading, monthOffset: e.monthOffset, summary: state.summary));
      final now = _clock.now();
      final r = await _calc(month: DateTime(now.year, now.month - e.monthOffset));
      emit(switch (r) {
        Ok(:final value) => InsightsState(
            status: value.data.totalSpent.isZero && value.data.totalReceived.isZero ? ViewStatus.empty : ViewStatus.success,
            monthOffset: e.monthOffset,
            summary: value,
          ),
        Err(:final failure) => InsightsState(status: ViewStatus.failure, monthOffset: e.monthOffset, failure: failure),
      });
    }, transformer: restartable());
  }

  final CalculateMonthlySpending _calc;
  final Clock _clock;
}
