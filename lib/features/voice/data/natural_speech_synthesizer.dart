import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../../core/l10n/app_language.dart';
import '../domain/speech_synthesizer.dart';
import 'clip_player/clip_player.dart';

/// Generated speech: raw bytes plus their MIME type
/// (Gemini TTS returns `audio/L16;codec=pcm;rate=24000`).
typedef SpeechAudio = ({Uint8List bytes, String mimeType});

/// Turns a prompt into speech audio. Injectable so tests need no network.
typedef SpeechGenerate = Future<SpeechAudio?> Function(String prompt);

/// Plays one audio clip; completes when playback ends or is stopped.
abstract interface class AudioClipPlayer {
  Future<void> play(Uint8List wav);
  Future<void> stop();
}

/// Natural voice through Gemini TTS (Firebase AI Logic), with the device's
/// own TTS engine as the fallback.
///
/// The cloud voice is used only when all of these hold; otherwise the device
/// voice speaks and nothing leaves the phone:
/// * the user allows it (cloud AI and natural voice both on) and we are online;
/// * the language is one Gemini TTS speaks well (English, French);
/// * the text did not come from the on-device model (`private`), so the
///   "On-device AI · private" promise stays true end to end.
final class NaturalSpeechSynthesizer implements SpeechSynthesizer {
  NaturalSpeechSynthesizer({
    required this._fallback,
    required this._allowed,
    required this._generate,
    required this._player,
    this.languages = const {AppLanguage.english, AppLanguage.french},
    this.timeout = const Duration(seconds: 15),
    this.cooldown = const Duration(minutes: 5),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Production wiring: `gemini-3.8-flash-tts` via Firebase AI Logic.
  factory NaturalSpeechSynthesizer.firebase({
    required SpeechSynthesizer fallback,
    required Future<bool> Function() allowed,
    String model = 'gemini-3.8-flash-lite-tts',
    String voice = 'Kore',
  }) {
    GenerativeModel? m;
    return NaturalSpeechSynthesizer(
      fallback: fallback,
      allowed: allowed,
      player: createClipPlayer(),
      generate: (prompt) async {
        m ??= FirebaseAI.googleAI(useLimitedUseAppCheckTokens: true).generativeModel(
          model: model,
          generationConfig: GenerationConfig(
            responseModalities: [ResponseModalities.audio],
            speechConfig: SpeechConfig(voiceName: voice),
          ),
        );
        final r = await m!.generateContent([Content.text(prompt)]);
        for (final p in r.candidates.firstOrNull?.content.parts ?? const <Part>[]) {
          if (p is InlineDataPart && p.mimeType.startsWith('audio/')) return (bytes: p.bytes, mimeType: p.mimeType);
        }
        return null;
      },
    );
  }

  final SpeechSynthesizer _fallback;
  final Future<bool> Function() _allowed;
  final SpeechGenerate _generate;
  final AudioClipPlayer _player;
  final Set<AppLanguage> languages;
  final Duration timeout;

  /// After a cloud failure, use the device voice for this long instead of
  /// making every reply wait for another timeout.
  final Duration cooldown;
  final DateTime Function() _now;
  DateTime? _pausedUntil;

  bool get _cloudPaused => _pausedUntil != null && _now().isBefore(_pausedUntil!);

  /// Small cache so "Repeat" replays instantly and costs nothing.
  final _cache = <String, Uint8List>{};
  int _generation = 0;

  @override
  Future<bool> supports(AppLanguage language) async {
    if (await _fallback.supports(language)) return true;
    return languages.contains(language) && !_cloudPaused && await _safeAllowed();
  }

  Future<bool> _safeAllowed() async {
    try {
      return await _allowed();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> speak(String text, {required AppLanguage language, required double rate, bool private = false}) async {
    await stop();
    final myTurn = ++_generation;
    if (!private && languages.contains(language) && !_cloudPaused && await _safeAllowed()) {
      final wav = await _naturalAudio(text, language, rate);
      if (myTurn != _generation) return; // stopped or replaced while generating
      if (wav != null) {
        try {
          return await _player.play(wav);
        } catch (e) {
          debugPrint('Sauti natural voice: playback failed ($e); using device voice');
          _pausedUntil = _now().add(cooldown); // playback broken here → device voice
        }
      }
      if (myTurn != _generation) return;
    }
    return _fallback.speak(text, language: language, rate: rate, private: private);
  }

  Future<Uint8List?> _naturalAudio(String text, AppLanguage language, double rate) async {
    final key = '${language.code}|${rate.toStringAsFixed(2)}|$text';
    final hit = _cache[key];
    if (hit != null) return hit;
    try {
      final audio = await _generate(prompt(text, language: language, rate: rate)).timeout(timeout);
      if (audio == null) return null;
      final wav = toWav(audio);
      if (_cache.length >= 8) _cache.remove(_cache.keys.first);
      return _cache[key] = wav;
    } catch (e) {
      debugPrint('Sauti natural voice: generation failed ($e); using device voice');
      _pausedUntil = _now().add(cooldown);
      return null; // quota, offline, timeout, blocked → device voice
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    try {
      await _player.stop();
    } catch (_) {/* nothing playing yet */}
    await _fallback.stop();
  }

  /// Style instruction + the exact text. Gemini TTS reads only the text after
  /// the colon; the instruction sets tone and pace.
  static String prompt(String text, {required AppLanguage language, required double rate}) {
    final pace = rate < 0.4
        ? 'slowly'
        : rate > 0.75
            ? 'briskly'
            : 'at a natural conversational pace';
    final lang = language == AppLanguage.french ? 'in French' : 'in English';
    return 'Say $lang, warmly and clearly, $pace: $text';
  }

  /// Wraps raw PCM (`audio/L16;rate=N`) in a WAV header so every platform's
  /// player can decode it. WAV/MP3/OGG input is passed through unchanged.
  static Uint8List toWav(SpeechAudio audio) {
    final mime = audio.mimeType.toLowerCase();
    if (!mime.contains('l16') && !mime.contains('pcm')) return audio.bytes;
    final rate = int.tryParse(RegExp(r'rate=(\d+)').firstMatch(mime)?.group(1) ?? '') ?? 24000;
    const channels = 1, bits = 16;
    final pcm = audio.bytes;
    final h = ByteData(44);
    void ascii(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        h.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    h.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    h
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little) // PCM
      ..setUint16(22, channels, Endian.little)
      ..setUint32(24, rate, Endian.little)
      ..setUint32(28, rate * channels * bits ~/ 8, Endian.little)
      ..setUint16(32, channels * bits ~/ 8, Endian.little)
      ..setUint16(34, bits, Endian.little);
    ascii(36, 'data');
    h.setUint32(40, pcm.length, Endian.little);
    return Uint8List.fromList([...h.buffer.asUint8List(), ...pcm]);
  }
}

/// audioplayers-backed clip player (Android, iOS, web).
final class AudioPlayersClipPlayer implements AudioClipPlayer {
  final _player = AudioPlayer();
  Completer<void>? _done;

  @override
  Future<void> play(Uint8List wav) async {
    final done = _done = Completer<void>();
    final sub = _player.onPlayerComplete.listen((_) {
      if (!done.isCompleted) done.complete();
    });
    try {
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
      await done.future;
    } finally {
      await sub.cancel();
    }
  }

  @override
  Future<void> stop() async {
    final d = _done;
    if (d != null && !d.isCompleted) d.complete();
    await _player.stop();
  }
}
