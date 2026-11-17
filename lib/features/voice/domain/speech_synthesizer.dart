import '../../../core/l10n/app_language.dart';

/// Text-to-speech port.
abstract interface class SpeechSynthesizer {
  /// Whether a voice exists on this device for [language].
  Future<bool> supports(AppLanguage language);

  /// Speaks [text]; completes when speech finishes or is stopped.
  /// [rate] is normalised 0.25 (slow) – 1.0 (fast).
  /// [private]: the text must not leave the device (e.g. it was produced by
  /// the on-device model), so no cloud voice may be used.
  Future<void> speak(String text, {required AppLanguage language, required double rate, bool private = false});

  Future<void> stop();
}
