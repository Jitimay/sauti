import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/features/voice/data/platform_speech_synthesizer.dart';

Map<String, String> v(String name, String locale) => {'name': name, 'locale': locale};

void main() {
  final mac = [
    v('Albert', 'en-US'),
    v('Bad News', 'en-US'),
    v('Fred', 'en-US'),
    v('Samantha', 'en-US'),
    v('Ava (Premium)', 'en-US'),
    v('Google US English', 'en-US'),
    v('Amélie', 'fr-CA'),
    v('Thomas', 'fr-FR'),
  ];

  test('never the novelty default; premium local voice wins', () {
    expect(PlatformSpeechSynthesizer.pickVoice(mac, 'en-US', private: true)!['name'], 'Ava (Premium)');
  });

  test('private answers skip cloud voices even when nothing better exists', () {
    final only = [v('Albert', 'en-US'), v('Google US English', 'en-US'), v('Samantha', 'en-US')];
    expect(PlatformSpeechSynthesizer.pickVoice(only, 'en-US', private: true)!['name'], 'Samantha');
  });

  test('French picks a French voice, preferring the exact locale', () {
    expect(PlatformSpeechSynthesizer.pickVoice(mac, 'fr-FR', private: false)!['name'], 'Thomas');
  });

  test('Android: offline neural voice preferred for private answers', () {
    final android = [v('en-us-x-iob-network', 'en-US'), v('en-us-x-iol-local', 'en-US')];
    expect(PlatformSpeechSynthesizer.pickVoice(android, 'en-US', private: true)!['name'], 'en-us-x-iol-local');
  });

  test('only novelty voices → engine default (null)', () {
    expect(PlatformSpeechSynthesizer.pickVoice([v('Albert', 'en-US')], 'en-US', private: false), isNull);
  });

  test("this Mac's real list (French macOS): Samantha for English, Thomas for French", () {
    final real = [
      v('Thomas', 'fr-FR'), v('Albert', 'en-US'), v('Amélie', 'fr-CA'), v('Bonnes nouvelles', 'en-US'),
      v('Bouffon', 'en-US'), v('Bulles', 'en-US'), v('Daniel', 'en-GB'), v('Samantha', 'en-US'),
      v('Google US English', 'en-US'), v('Google français', 'fr-FR'),
    ];
    expect(PlatformSpeechSynthesizer.pickVoice(real, 'en-US', private: true)!['name'], 'Samantha');
    expect(PlatformSpeechSynthesizer.pickVoice(real, 'fr-FR', private: true)!['name'], 'Thomas');
  });
}
