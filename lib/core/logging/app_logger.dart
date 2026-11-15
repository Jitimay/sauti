/// Minimal logging port. Implementations must never log secrets, PINs,
/// passwords or full account numbers.
abstract interface class AppLogger {
  void info(String tag, String message);
  void warn(String tag, String message, [Object? error]);
}

final class PrintLogger implements AppLogger {
  const PrintLogger();
  @override
  void info(String tag, String message) {
    // ignore: avoid_print
    assert(() { print('[I][$tag] $message'); return true; }());
  }

  @override
  void warn(String tag, String message, [Object? error]) {
    // ignore: avoid_print
    assert(() { print('[W][$tag] $message ${error ?? ''}'); return true; }());
  }
}
