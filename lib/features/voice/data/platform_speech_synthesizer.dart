import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/l10n/app_language.dart';
import '../domain/speech_synthesizer.dart';

/// flutter_tts adapter. Uses the device's installed TTS voices.
final class PlatformSpeechSynthesizer implements SpeechSynthesizer {
  PlatformSpeechSynthesizer([FlutterTts? tts]) : _tts = tts ?? FlutterTts() {
    _tts
      ..setCompletionHandler(_complete)
      ..setCancelHandler(_complete)
      ..setErrorHandler((_) => _complete());
  }

  final FlutterTts _tts;
  Completer<void>? _speaking;
  final Map<AppLanguage, String?> _resolved = {};

  void _complete() {
    final c = _speaking;
    if (c != null && !c.isCompleted) c.complete();
  }

  Future<String?> _voiceLocale(AppLanguage language) async {
    if (_resolved.containsKey(language)) return _resolved[language];
    String? hit;
    for (final c in language.speechLocaleCandidates) {
      final tag = c.replaceAll('_', '-');
      try {
        final ok = await _tts.isLanguageAvailable(tag);
        if (ok == true || ok == 1) {
          hit = tag;
          break;
        }
      } catch (_) {/* engine without query support */}
    }
    return _resolved[language] = hit;
  }

  @override
  Future<bool> supports(AppLanguage language) async => await _voiceLocale(language) != null;

  @override
  Future<void> speak(String text, {required AppLanguage language, required double rate}) async {
    await stop();
    final locale = await _voiceLocale(language);
    if (locale == null) throw StateError('No TTS voice for ${language.code}');
    await _tts.setLanguage(locale);
    // flutter_tts: 0.5 is normal speed on Android/iOS.
    await _tts.setSpeechRate((rate.clamp(0.25, 1.0)) * 0.6);
    final c = _speaking = Completer<void>();
    await _tts.speak(text);
    return c.future;
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _complete();
  }
}
