import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/view_status.dart';
import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/data_freshness.dart';
import '../../../banking/domain/usecases/banking_usecases.dart';

sealed class AccountEvent extends Equatable {
  const AccountEvent();
  @override
  List<Object?> get props => [];
}

final class AccountLoadRequested extends AccountEvent {
  const AccountLoadRequested();
}

final class AccountState extends Equatable {
  const AccountState({this.status = ViewStatus.initial, this.accounts, this.failure});
  final ViewStatus status;
  final Fresh<List<Account>>? accounts;
  final Failure? failure;
  @override
  List<Object?> get props => [status, accounts, failure];
}

/// Spec events AccountLoaded / AccountLoadFailed are represented as the
/// resulting states (success / failure) to avoid redundant internal events.
final class AccountBloc extends Bloc<AccountEvent, AccountState> {
  AccountBloc(this._get) : super(const AccountState()) {
    on<AccountLoadRequested>((e, emit) async {
      emit(AccountState(status: ViewStatus.loading, accounts: state.accounts));
      final r = await _get();
      emit(switch (r) {
        Ok(:final value) => AccountState(status: value.data.isEmpty ? ViewStatus.empty : ViewStatus.success, accounts: value),
        Err(:final failure) => AccountState(status: ViewStatus.failure, failure: failure),
      });
    }, transformer: restartable());
  }

  final GetAccounts _get;
}
