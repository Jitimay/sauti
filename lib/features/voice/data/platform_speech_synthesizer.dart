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
    final known = _resolved[language];
    if (known != null) return known;
    // Browsers load their voice list asynchronously: an early "no voice" is
    // often just "not loaded yet". Retry briefly, and never cache a miss.
    for (var attempt = 0; attempt < 4; attempt++) {
      for (final c in language.speechLocaleCandidates) {
        final tag = c.replaceAll('_', '-');
        try {
          final ok = await _tts.isLanguageAvailable(tag);
          if (ok == true || ok == 1) return _resolved[language] = tag;
        } catch (_) {/* engine without query support */}
      }
      if (attempt < 3) await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  @override
  Future<bool> supports(AppLanguage language) async => await _voiceLocale(language) != null;

  @override
  Future<void> speak(String text, {required AppLanguage language, required double rate, bool private = false}) async {
    await stop();
    final locale = await _voiceLocale(language);
    if (locale == null) throw StateError('No TTS voice for ${language.code}');
    await _tts.setLanguage(locale);
    final voice = await _bestVoice(locale, private: private);
    if (voice != null) await _tts.setVoice(voice);
    // flutter_tts: 0.5 is normal speed on Android/iOS.
    await _tts.setSpeechRate((rate.clamp(0.25, 1.0)) * 0.6);
    final c = _speaking = Completer<void>();
    await _tts.speak(text);
    return c.future;
  }

  final Map<String, Map<String, String>?> _voiceCache = {};

  Future<Map<String, String>?> _bestVoice(String locale, {required bool private}) async {
    final key = '$locale|$private';
    if (_voiceCache[key] != null) return _voiceCache[key];
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return null;
      final voices = [
        for (final v in raw)
          if (v is Map && v['name'] != null && v['locale'] != null)
            {'name': '${v['name']}', 'locale': '${v['locale']}'},
      ];
      final best = pickVoice(voices, locale, private: private);
      if (best != null) _voiceCache[key] = best;
      return best;
    } catch (_) {
      return null; // engine default
    }
  }

  /// Chooses the most natural installed voice for [locale]. Engines default to
  /// the first voice in their list, which on macOS is a novelty voice
  /// ("Albert", "Bad News"). [private]: skip voices that synthesise in the
  /// cloud, so on-device answers stay on the device.
  static Map<String, String>? pickVoice(List<Map<String, String>> voices, String locale, {required bool private}) {
    final lang = locale.split('-').first.toLowerCase();
    final want = locale.toLowerCase().replaceAll('_', '-');
    int score(Map<String, String> v) {
      final name = v['name']!.toLowerCase();
      final loc = v['locale']!.toLowerCase().replaceAll('_', '-');
      var s = 0;
      if (loc == want) s += 8;
      if (RegExp(r'premium').hasMatch(name)) s += 60;
      if (RegExp(r'enhanced|neural|natural|wavenet|studio').hasMatch(name)) s += 45;
      if (_goodNames.any((g) => name == g || name.startsWith('$g '))) s += 25;
      if (name.contains('-local')) s += 6; // Android offline neural voices
      if (_novelty.any((n) => name == n || name.startsWith('$n '))) s -= 200;
      final cloud = name.contains('online') || name.startsWith('google ') || name.contains('-network');
      if (cloud) s += private ? -500 : 10;
      return s;
    }

    final candidates = voices.where((v) => v['locale']!.toLowerCase().replaceAll('_', '-').startsWith(lang)).toList();
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => score(b).compareTo(score(a)));
    final best = candidates.first;
    return score(best) < -100 ? null : best; // only novelty or cloud-for-private left
  }

  static const _goodNames = [
    'samantha', 'ava', 'zoe', 'allison', 'susan', 'tom', 'evan', 'nathan', 'joelle', 'noelle', 'daniel', 'karen',
    'moira', 'serena', 'tessa', 'amélie', 'amelie', 'thomas', 'audrey', 'aurélie', 'aurelie', 'marie',
  ];

  static const _novelty = [
    'albert', 'bad news', 'bahh', 'bells', 'boing', 'bubbles', 'cellos', 'good news', 'jester', 'organ',
    'superstar', 'trinoids', 'whisper', 'wobble', 'zarvox', 'junior', 'ralph', 'fred', 'kathy', 'grandma',
    'grandpa', 'rocko', 'shelley', 'flo', 'eddy', 'reed', 'sandy', 'deranged', 'hysterical', 'pipe organ',
    // The same novelty voices on a French-language macOS.
    'bonnes nouvelles', 'mauvaises nouvelles', 'bouffon', 'bulles', 'cloches', 'murmure', 'orgue',
    'trinoïdes', 'violoncelles', 'superstar', 'grand-mère', 'grand-père',
  ];

  @override
  Future<void> stop() async {
    await _tts.stop();
    _complete();
  }
}
