import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/l10n/app_language.dart';
import '../domain/speech_recognizer.dart';

/// speech_to_text adapter (Android SpeechRecognizer / iOS SFSpeechRecognizer /
/// Web Speech API). Language availability is whatever the device's engine
/// reports — Kirundi is detected, never assumed.
final class PlatformSpeechRecognizer implements SpeechRecognizer {
  PlatformSpeechRecognizer([SpeechToText? stt]) : _stt = stt ?? SpeechToText();

  final SpeechToText _stt;
  StreamController<RecognitionEvent>? _active;
  bool _ready = false;

  @override
  Future<bool> initialize() async {
    if (_ready) return true;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    _ready = await _stt.initialize(onError: _onError, onStatus: _onStatus);
    return _ready;
  }

  @override
  Future<RecognitionLocale> resolveLocale(AppLanguage language) async {
    if (!await initialize()) {
      return RecognitionLocale(requested: language, localeId: null, isExactMatch: false);
    }
    final available = (await _stt.locales()).map((l) => l.localeId).toList();
    String norm(String s) => s.replaceAll('-', '_').toLowerCase();
    for (final candidate in language.speechLocaleCandidates) {
      final hit = available.where((a) => norm(a) == norm(candidate)).firstOrNull ??
          (candidate.contains('_') ? null : available.where((a) => norm(a).startsWith('${norm(candidate)}_')).firstOrNull);
      if (hit != null) return RecognitionLocale(requested: language, localeId: hit, isExactMatch: true);
    }
    return RecognitionLocale(requested: language, localeId: null, isExactMatch: false);
  }

  @override
  Stream<RecognitionEvent> listen({
    required String localeId,
    Duration maxDuration = const Duration(seconds: 15),
    Duration silenceTimeout = const Duration(seconds: 3),
  }) {
    final c = StreamController<RecognitionEvent>();
    _active = c;
    () async {
      if (!await initialize()) {
        c.add(const RecognitionError(RecognitionErrorKind.permissionDenied));
        await c.close();
        return;
      }
      await _stt.listen(
        onResult: (SpeechRecognitionResult r) {
          if (c.isClosed) return;
          if (r.finalResult) {
            c.add(r.recognizedWords.trim().isEmpty
                ? const RecognitionError(RecognitionErrorKind.noMatch)
                : RecognitionFinal(r.recognizedWords));
            c.close();
          } else {
            c.add(RecognitionPartial(r.recognizedWords));
          }
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
    }();
    return c.stream;
  }

  void _onError(SpeechRecognitionError e) {
    final c = _active;
    if (c == null || c.isClosed) return;
    final kind = switch (e.errorMsg) {
      'error_no_match' || 'error_speech_timeout' => RecognitionErrorKind.noMatch,
      'error_network' || 'error_network_timeout' || 'error_server' => RecognitionErrorKind.network,
      'error_language_not_supported' || 'error_language_unavailable' => RecognitionErrorKind.languageUnsupported,
      'error_permission' || 'error_insufficient_permissions' => RecognitionErrorKind.permissionDenied,
      _ => RecognitionErrorKind.unknown,
    };
    c.add(RecognitionError(kind, e.errorMsg));
    c.close();
  }

  void _onStatus(String status) {
    // 'done' without a final result (e.g. silence): close the session cleanly.
    final c = _active;
    if (status == SpeechToText.doneStatus && c != null && !c.isClosed) {
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!c.isClosed) {
          c.add(const RecognitionError(RecognitionErrorKind.noMatch));
          c.close();
        }
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
