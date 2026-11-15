import 'dart:async';

/// Demo-only control that simulates loss of connectivity so the offline
/// behaviour can be shown live without toggling airplane mode.
final class DemoNetworkSwitch {
  final _controller = StreamController<bool>.broadcast();
  bool _simulateOffline = false;

  bool get simulateOffline => _simulateOffline;
  Stream<bool> get changes => _controller.stream;

  void set(bool offline) {
    if (offline == _simulateOffline) return;
    _simulateOffline = offline;
    _controller.add(offline);
  }

  Future<void> dispose() => _controller.close();
}
