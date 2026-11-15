import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/utils/view_status.dart';
import '../../../banking/domain/entities/bank_notification.dart';
import '../../../banking/domain/entities/data_freshness.dart';
import '../../../banking/domain/usecases/banking_usecases.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

final class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested();
}

final class NotificationMarkedRead extends NotificationsEvent {
  const NotificationMarkedRead(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

final class NotificationsState extends Equatable {
  const NotificationsState({this.status = ViewStatus.initial, this.items, this.failure});
  final ViewStatus status;
  final Fresh<List<BankNotification>>? items;
  final Failure? failure;
  @override
  List<Object?> get props => [status, items, failure];
}

final class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc(this._get, this._markRead) : super(const NotificationsState()) {
    on<NotificationsLoadRequested>((e, emit) async {
      emit(NotificationsState(status: ViewStatus.loading, items: state.items));
      final r = await _get();
      emit(switch (r) {
        Ok(:final value) => NotificationsState(status: value.data.isEmpty ? ViewStatus.empty : ViewStatus.success, items: value),
        Err(:final failure) => NotificationsState(status: ViewStatus.failure, failure: failure),
      });
    }, transformer: restartable());

    on<NotificationMarkedRead>((e, emit) async {
      final r = await _markRead(e.id);
      final items = state.items;
      if (r.isOk && items != null) {
        emit(NotificationsState(
          status: state.status,
          items: items.map((l) => [for (final n in l) n.id == e.id ? n.markRead() : n]),
        ));
      } else if (r case Err(:final failure)) {
        emit(NotificationsState(status: state.status, items: items, failure: failure));
      }
    }, transformer: sequential());
  }

  final GetNotifications _get;
  final MarkNotificationRead _markRead;
}
