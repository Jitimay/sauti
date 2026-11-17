import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../natural_speech_synthesizer.dart';

AudioClipPlayer createClipPlayer() => WebClipPlayer();

/// Plays a WAV clip with the browser's own <audio> element (blob URL).
final class WebClipPlayer implements AudioClipPlayer {
  web.HTMLAudioElement? _el;
  String? _url;
  Completer<void>? _done;

  @override
  Future<void> play(Uint8List wav) async {
    await stop();
    final url = web.URL.createObjectURL(web.Blob([wav.toJS].toJS, web.BlobPropertyBag(type: 'audio/wav')));
    final el = web.HTMLAudioElement()..src = url;
    final done = Completer<void>();
    _el = el;
    _url = url;
    _done = done;
    el.onended = ((web.Event _) {
      if (!done.isCompleted) done.complete();
    }).toJS;
    el.onerror = ((web.Event _) {
      if (!done.isCompleted) done.completeError(StateError('audio element error'));
    }).toJS;
    try {
      await el.play().toDart;
      await done.future;
    } finally {
      if (identical(_el, el)) _release();
    }
  }

  void _release() {
    final url = _url;
    if (url != null) web.URL.revokeObjectURL(url);
    _el = null;
    _url = null;
  }

  @override
  Future<void> stop() async {
    final d = _done;
    if (d != null && !d.isCompleted) d.complete();
    _el?.pause();
    _release();
  }
}
