import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'network_status.dart';

/// App-wide online/offline state for banners and UI decisions.
final class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(NetworkStatus network) : super(true) {
    _sub = network.watch().listen(emit);
  }

  late final StreamSubscription<bool> _sub;

  bool get isOnline => state;

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
