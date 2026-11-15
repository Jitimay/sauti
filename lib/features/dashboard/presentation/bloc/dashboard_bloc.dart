import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/view_status.dart';
import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/bank_transaction.dart';
import '../../../banking/domain/entities/data_freshness.dart';
import '../../../banking/domain/usecases/banking_usecases.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

final class DashboardLoadRequested extends DashboardEvent {
  const DashboardLoadRequested({this.silent = false});

  /// Refresh without showing a full-screen spinner.
  final bool silent;
  @override
  List<Object?> get props => [silent];
}

final class DashboardState extends Equatable {
  const DashboardState({
    this.status = ViewStatus.initial,
    this.accounts,
    this.recent,
    this.unreadNotifications = 0,
    this.failure,
  });

  final ViewStatus status;
  final Fresh<List<Account>>? accounts;
  final Fresh<List<BankTransaction>>? recent;
  final int unreadNotifications;
  final Failure? failure;

  Account? get primary => accounts?.data.firstOrNull;

  @override
  List<Object?> get props => [status, accounts, recent, unreadNotifications, failure];
}

final class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._accounts, this._recent, this._notifications) : super(const DashboardState()) {
    on<DashboardLoadRequested>(_onLoad, transformer: restartable());
  }

  final GetAccounts _accounts;
  final GetRecentTransactions _recent;
  final GetNotifications _notifications;

  Future<void> _onLoad(DashboardLoadRequested e, Emitter<DashboardState> emit) async {
    if (!e.silent || state.status != ViewStatus.success) {
      emit(DashboardState(status: ViewStatus.loading, accounts: state.accounts, recent: state.recent));
    }
    final (acc, tx, notif) = await (_accounts(), _recent(limit: 4), _notifications()).wait;
    switch (acc) {
      case Err(:final failure):
        emit(DashboardState(status: ViewStatus.failure, failure: failure, accounts: state.accounts, recent: state.recent));
      case Ok(:final value):
        emit(DashboardState(
          status: value.data.isEmpty ? ViewStatus.empty : ViewStatus.success,
          accounts: value,
          recent: tx.valueOrNull,
          unreadNotifications: notif.valueOrNull?.data.where((n) => !n.read).length ?? 0,
        ));
    }
  }
}
