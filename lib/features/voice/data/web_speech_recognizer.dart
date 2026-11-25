import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:permission_handler/permission_handler.dart';
import 'package:web/web.dart' as web;

import '../../../core/l10n/app_language.dart';
import '../domain/speech_recognizer.dart';

SpeechRecognizer createSpeechRecognizer() => WebSpeechRecognizer();

/// Runs one Web Speech session at a time. Browsers control where transcription
/// runs and whether the speech service is available.
final class WebSpeechRecognizer implements SpeechRecognizer {
  WebSpeechRecognizer({
    Future<bool> Function()? requestMicrophone,
    web.SpeechRecognition Function()? createEngine,
  }) : _requestMicrophone = requestMicrophone ?? _requestPlatformMicrophone,
       _createEngine = createEngine ?? _createBrowserEngine;

  final Future<bool> Function() _requestMicrophone;
  final web.SpeechRecognition Function() _createEngine;
  bool _micGranted = false;
  _Session? _active;

  static Future<bool> _requestPlatformMicrophone() async =>
      (await Permission.microphone.request()).isGranted;

  static web.SpeechRecognition _createBrowserEngine() {
    final constructor =
        globalContext.getProperty<JSFunction?>('SpeechRecognition'.toJS) ??
        globalContext.getProperty<JSFunction?>('webkitSpeechRecognition'.toJS);
    if (constructor == null) {
      throw UnsupportedError('Browser has no Web Speech recognition API');
    }
    return constructor.callAsConstructor<web.SpeechRecognition>();
  }

  @override
  Future<bool> initialize() async =>
      _micGranted || (_micGranted = await _requestMicrophone());

  @override
  Future<RecognitionLocale> resolveLocale(AppLanguage language) async {
    final locale = switch (language) {
      AppLanguage.english || AppLanguage.french =>
        language.speechLocaleCandidates.first.replaceAll('_', '-'),
      AppLanguage.kirundi => null,
    };
    return RecognitionLocale(
      requested: language,
      localeId: locale,
      isExactMatch: locale != null,
    );
  }

  @override
  Stream<RecognitionEvent> listen({
    required String localeId,
    Duration maxDuration = const Duration(seconds: 15),
    Duration silenceTimeout = const Duration(seconds: 3),
  }) {
    final session = _Session();
    unawaited(_start(session, localeId, maxDuration));
    return session.events.stream;
  }

  Future<void> _start(_Session session, String localeId, Duration max) async {
    try {
      await cancel();
      _active = session;
      final granted = await initialize();
      if (!identical(_active, session)) return;
      if (!granted) {
        _finish(
          session,
          const RecognitionError(RecognitionErrorKind.permissionDenied),
        );
        return;
      }

      // The browser already ends sessions on silence. A second, shorter
      // app timer can stop the microphone before the user starts speaking.
      session.deadline = Timer(max, () => unawaited(stop()));
      session.elapsed.start();
      _startBrowser(session, localeId);
    } catch (_) {
      _finish(
        session,
        const RecognitionError(RecognitionErrorKind.unavailable),
      );
    }
  }

  void _startBrowser(_Session session, String localeId) {
    try {
      final engine = _createEngine()
        ..lang = localeId
        ..continuous = false
        ..interimResults = true;
      session.engine = engine;
      engine.onspeechstart = ((web.Event _) {
        session.hasSpeech = true;
      }).toJS;
      engine.onresult = ((web.SpeechRecognitionEvent event) {
        if (session.events.isClosed ||
            event.resultIndex >= event.results.length) {
          return;
        }
        final result = event.results.item(event.resultIndex);
        if (result.length == 0) return;
        final text = result.item(0).transcript.trim();
        if (text.isEmpty) return;
        session.hasSpeech = true;
        if (result.isFinal) {
          _finish(session, RecognitionFinal(text));
        } else {
          session.events.add(RecognitionPartial(text));
        }
      }).toJS;
      engine.onnomatch = ((web.Event _) => _handleNoSpeech(
        session,
        localeId,
      )).toJS;
      engine.onend = ((web.Event _) => _handleNoSpeech(session, localeId)).toJS;
      engine.onerror = ((web.SpeechRecognitionErrorEvent event) {
        final kind = switch (event.error) {
          'not-allowed' => RecognitionErrorKind.permissionDenied,
          'language-not-supported' ||
          'language-unavailable' => RecognitionErrorKind.languageUnsupported,
          'audio-capture' => RecognitionErrorKind.microphoneUnavailable,
          'service-not-allowed' => RecognitionErrorKind.serviceUnavailable,
          'network' => RecognitionErrorKind.network,
          'no-speech' || 'aborted' => RecognitionErrorKind.noMatch,
          _ => RecognitionErrorKind.unknown,
        };
        if (kind == RecognitionErrorKind.noMatch) {
          _handleNoSpeech(session, localeId, detail: event.error);
          return;
        }
        if (kind == RecognitionErrorKind.permissionDenied) _micGranted = false;
        _finish(session, RecognitionError(kind, event.error));
      }).toJS;
      engine.start();
    } catch (_) {
      _finish(
        session,
        const RecognitionError(RecognitionErrorKind.unavailable),
      );
    }
  }

  void _handleNoSpeech(_Session session, String localeId, {String? detail}) {
    if (!identical(_active, session) || session.events.isClosed) return;
    // Some browsers end a newly started session before detecting speech.
    // Retry only once, within the same user-initiated listening window.
    if (!session.stopping &&
        !session.hasSpeech &&
        !session.retried &&
        session.elapsed.elapsed < const Duration(seconds: 3)) {
      session.retried = true;
      _releaseEngine(session);
      session.retry = Timer(const Duration(milliseconds: 250), () {
        if (identical(_active, session)) _startBrowser(session, localeId);
      });
      return;
    }
    _finish(session, RecognitionError(RecognitionErrorKind.noMatch, detail));
  }

  void _finish(_Session session, [RecognitionEvent? event]) {
    if (session.events.isClosed) return;
    if (identical(_active, session)) _active = null;
    session.deadline?.cancel();
    session.retry?.cancel();
    _releaseEngine(session);
    if (event != null) session.events.add(event);
    unawaited(session.events.close());
  }

  void _releaseEngine(_Session session) {
    final engine = session.engine;
    if (engine == null) return;
    session.engine = null;
    engine.onspeechstart = null;
    engine.onresult = null;
    engine.onnomatch = null;
    engine.onend = null;
    engine.onerror = null;
    try {
      engine.abort();
    } catch (_) {
      // The browser may have already ended the session.
    }
  }

  @override
  Future<void> stop() async {
    final session = _active;
    if (session == null) return;
    if (session.stopping) return;
    session.stopping = true;
    session.deadline?.cancel();
    session.retry?.cancel();
    const noMatch = RecognitionError(RecognitionErrorKind.noMatch);
    final engine = session.engine;
    if (engine == null) {
      _finish(session, noMatch);
      return;
    }
    session.deadline = Timer(
      const Duration(seconds: 1),
      () => _finish(session, noMatch),
    );
    try {
      engine.stop();
    } catch (_) {
      _finish(session, noMatch);
    }
  }

  @override
  Future<void> cancel() async {
    final session = _active;
    if (session != null) _finish(session);
  }
}

final class _Session {
  final events = StreamController<RecognitionEvent>();
  web.SpeechRecognition? engine;
  Timer? deadline;
  final elapsed = Stopwatch();
  Timer? retry;
  bool hasSpeech = false;
  bool stopping = false;
  bool retried = false;
}
