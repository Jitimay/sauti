import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/l10n/app_language.dart';
import '../domain/speech_recognizer.dart';

SpeechRecognizer createSpeechRecognizer() => PlatformSpeechRecognizer();

/// Native speech_to_text adapter. Locale availability is reported by the engine.
final class PlatformSpeechRecognizer implements SpeechRecognizer {
  PlatformSpeechRecognizer({
    SpeechToText? engine,
    Future<bool> Function()? requestMicrophone,
  }) : _stt = engine ?? SpeechToText(),
       _requestMicrophone = requestMicrophone ?? _requestPlatformMicrophone;

  final SpeechToText _stt;
  final Future<bool> Function() _requestMicrophone;
  StreamController<RecognitionEvent>? _active;
  bool _ready = false;

  static Future<bool> _requestPlatformMicrophone() async =>
      (await Permission.microphone.request()).isGranted;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    if (!await _requestMicrophone()) return false;
    _ready = await _stt.initialize(onError: _onError, onStatus: _onStatus);
    return _ready;
  }

  @override
  Future<RecognitionLocale> resolveLocale(AppLanguage language) async {
    if (!await initialize()) {
      return RecognitionLocale(
        requested: language,
        localeId: null,
        isExactMatch: false,
      );
    }
    final available = (await _stt.locales()).map((l) => l.localeId).toList();
    String norm(String s) => s.replaceAll('-', '_').toLowerCase();
    for (final candidate in language.speechLocaleCandidates) {
      final hit =
          available.where((a) => norm(a) == norm(candidate)).firstOrNull ??
          (candidate.contains('_')
              ? null
              : available
                    .where((a) => norm(a).startsWith('${norm(candidate)}_'))
                    .firstOrNull);
      if (hit != null) {
        return RecognitionLocale(
          requested: language,
          localeId: hit,
          isExactMatch: true,
        );
      }
    }
    return RecognitionLocale(
      requested: language,
      localeId: null,
      isExactMatch: false,
    );
  }

  @override
  Stream<RecognitionEvent> listen({
    required String localeId,
    Duration maxDuration = const Duration(seconds: 15),
    Duration silenceTimeout = const Duration(seconds: 3),
  }) {
    final c = StreamController<RecognitionEvent>();
    _active = c;
    unawaited(_start(c, localeId, maxDuration, silenceTimeout));
    return c.stream;
  }

  Future<void> _start(
    StreamController<RecognitionEvent> session,
    String localeId,
    Duration maxDuration,
    Duration silenceTimeout,
  ) async {
    try {
      final ready = await initialize();
      if (session.isClosed) return;
      if (!ready) {
        _finish(
          session,
          const RecognitionError(RecognitionErrorKind.permissionDenied),
        );
        return;
      }
      await _stt.listen(
        onResult: (SpeechRecognitionResult result) {
          if (session.isClosed) return;
          if (!result.finalResult) {
            session.add(RecognitionPartial(result.recognizedWords));
            return;
          }
          final text = result.recognizedWords.trim();
          _finish(
            session,
            text.isEmpty
                ? const RecognitionError(RecognitionErrorKind.noMatch)
                : RecognitionFinal(text),
          );
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: maxDuration,
          pauseFor: silenceTimeout,
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
      );
    } catch (_) {
      _finish(
        session,
        const RecognitionError(RecognitionErrorKind.unavailable),
      );
    }
  }

  void _finish(
    StreamController<RecognitionEvent> session,
    RecognitionEvent event,
  ) {
    if (session.isClosed) return;
    session.add(event);
    unawaited(session.close());
  }

  void _onError(SpeechRecognitionError e) {
    final c = _active;
    if (c == null || c.isClosed) return;
    final kind = switch (e.errorMsg) {
      'error_no_match' ||
      'error_speech_timeout' ||
      'no-speech' => RecognitionErrorKind.noMatch,
      'error_network' ||
      'error_network_timeout' ||
      'error_server' ||
      'network' => RecognitionErrorKind.network,
      'error_language_not_supported' ||
      'error_language_unavailable' ||
      'language-not-supported' ||
      'language-unavailable' => RecognitionErrorKind.languageUnsupported,
      'error_permission' ||
      'error_insufficient_permissions' ||
      'not-allowed' => RecognitionErrorKind.permissionDenied,
      'service-not-allowed' ||
      'audio-capture' => RecognitionErrorKind.unavailable,
      _ => RecognitionErrorKind.unknown,
    };
    _finish(c, RecognitionError(kind, e.errorMsg));
  }

  void _onStatus(String status) {
    // 'done' without a final result (e.g. silence): close the session cleanly.
    final c = _active;
    if (status == SpeechToText.doneStatus && c != null && !c.isClosed) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        _finish(c, const RecognitionError(RecognitionErrorKind.noMatch));
      });
    }
  }

  @override
  Future<void> stop() => _stt.stop();

  @override
  Future<void> cancel() async {
    await _stt.cancel();
    final c = _active;
    if (c != null && !c.isClosed) await c.close();
  }
}
