import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/features/voice/data/natural_speech_synthesizer.dart';

import '../../helpers/test_app.dart';

final class FakePlayer implements AudioClipPlayer {
  final played = <Uint8List>[];
  bool broken = false;
  @override
  Future<void> play(Uint8List wav) async {
    if (broken) throw StateError('no audio output');
    played.add(wav);
  }

  @override
  Future<void> stop() async {
    if (broken) throw StateError('nothing to stop');
  }
}

void main() {
  late FakeSynthesizer device;
  late FakePlayer player;
  late List<String> prompts;
  var allowed = true;
  Future<SpeechAudio?> Function(String) generate = (_) async => null;

  NaturalSpeechSynthesizer build() => NaturalSpeechSynthesizer(
        fallback: device,
        allowed: () async => allowed,
        player: player,
        timeout: const Duration(milliseconds: 200),
        generate: (p) {
          prompts.add(p);
          return generate(p);
        },
      );

  final pcm = (bytes: Uint8List.fromList(List.filled(480, 7)), mimeType: 'audio/L16;codec=pcm;rate=24000');

  setUp(() {
    device = FakeSynthesizer();
    player = FakePlayer();
    prompts = [];
    allowed = true;
    generate = (_) async => pcm;
  });

  test('English reply is spoken by Gemini TTS, wrapped as a playable WAV', () async {
    await build().speak('You have 250,000 BIF.', language: AppLanguage.english, rate: 0.5);
    expect(player.played, hasLength(1));
    final wav = player.played.single;
    expect(String.fromCharCodes(wav.sublist(0, 4)), 'RIFF');
    expect(String.fromCharCodes(wav.sublist(8, 12)), 'WAVE');
    expect(ByteData.sublistView(wav).getUint32(24, Endian.little), 24000);
    expect(wav.length, 44 + 480);
    expect(prompts.single, endsWith(': You have 250,000 BIF.'));
    expect(device.spoken, isEmpty);
  });

  test('on-device (private) replies never go to the cloud voice', () async {
    await build().speak('You have 250,000 BIF.', language: AppLanguage.english, rate: 0.5, private: true);
    expect(prompts, isEmpty);
    expect(player.played, isEmpty);
    expect(device.spoken, ['You have 250,000 BIF.']);
  });

  test('not allowed (setting off / offline) or Kirundi → device voice', () async {
    allowed = false;
    await build().speak('Hello', language: AppLanguage.english, rate: 0.5);
    allowed = true;
    await build().speak('Amahoro', language: AppLanguage.kirundi, rate: 0.5);
    expect(prompts, isEmpty);
    expect(device.spoken, ['Hello', 'Amahoro']);
  });

  test('errors and timeouts fall back to the device voice', () async {
    generate = (_) async => throw Exception('quota');
    await build().speak('One', language: AppLanguage.french, rate: 0.5);
    generate = (_) => Completer<SpeechAudio?>().future; // never answers
    await build().speak('Two', language: AppLanguage.english, rate: 0.5);
    expect(device.spoken, ['One', 'Two']);
  });

  test('repeat is served from cache; pace follows the speech-rate setting', () async {
    final s = build();
    await s.speak('Same text', language: AppLanguage.english, rate: 0.3);
    await s.speak('Same text', language: AppLanguage.english, rate: 0.3);
    expect(prompts, hasLength(1));
    expect(player.played, hasLength(2));
    expect(prompts.single, contains('slowly'));
    expect(NaturalSpeechSynthesizer.prompt('x', language: AppLanguage.french, rate: 0.9), contains('in French'));
  });

  test('a failure pauses the cloud voice: the next replies use the device voice at once', () async {
    final s = build();
    generate = (_) async => throw Exception('App Check token is invalid');
    await s.speak('First', language: AppLanguage.english, rate: 0.5);
    generate = (_) async => pcm;
    await s.speak('Second', language: AppLanguage.english, rate: 0.5);
    expect(prompts, hasLength(1), reason: 'no second cloud attempt during the cooldown');
    expect(device.spoken, ['First', 'Second']);
  });

  test('broken audio playback never leaves the user without speech', () async {
    player.broken = true;
    await build().speak('Hello', language: AppLanguage.english, rate: 0.5);
    expect(device.spoken, ['Hello']);
  });
}
