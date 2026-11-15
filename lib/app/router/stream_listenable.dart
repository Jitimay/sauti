import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges BLoC streams to go_router's refreshListenable.
final class StreamListenable extends ChangeNotifier {
  StreamListenable(List<Stream<dynamic>> streams) {
    for (final s in streams) {
      _subs.add(s.listen((_) => notifyListeners()));
    }
  }
  final _subs = <StreamSubscription<dynamic>>[];

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
