import '../../../core/l10n/app_language.dart';

/// Text-to-speech port.
abstract interface class SpeechSynthesizer {
  /// Whether a voice exists on this device for [language].
  Future<bool> supports(AppLanguage language);

  /// Speaks [text]; completes when speech finishes or is stopped.
  /// [rate] is normalised 0.25 (slow) – 1.0 (fast).
  Future<void> speak(String text, {required AppLanguage language, required double rate});

  Future<void> stop();
}
