import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'demo_network_switch.dart';
import 'network_status.dart';

/// [NetworkStatus] backed by connectivity_plus, combined with the demo
/// offline switch. Note: connectivity ≠ reachability; backend calls still
/// handle network errors explicitly.
final class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus(this._connectivity, this._demoSwitch);

  final Connectivity _connectivity;
  final DemoNetworkSwitch _demoSwitch;

  static bool _hasLink(List<ConnectivityResult> r) => r.any((c) => c != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async {
    if (_demoSwitch.simulateOffline) return false;
    try {
      return _hasLink(await _connectivity.checkConnectivity());
    } catch (_) {
      return true; // Unknown: let the actual request decide.
    }
  }

  @override
  Stream<bool> watch() async* {
    yield await isOnline();
    final merged = StreamController<bool>();
    final subs = <StreamSubscription<dynamic>>[
      _connectivity.onConnectivityChanged.listen((_) async => merged.add(await isOnline())),
      _demoSwitch.changes.listen((_) async => merged.add(await isOnline())),
    ];
    merged.onCancel = () async {
      for (final s in subs) {
        await s.cancel();
      }
    };
    yield* merged.stream.distinct();
  }
}
