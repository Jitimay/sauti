import 'package:equatable/equatable.dart';

import '../../../core/l10n/app_language.dart';

enum InteractionMode { standard, simplified }

final class AccessibilitySettings extends Equatable {
  const AccessibilitySettings({
    this.textScale = 1.0,
    this.highContrast = false,
    this.voiceFeedback = true,
    this.speechRate = 0.5,
    this.interactionMode = InteractionMode.standard,
    this.reduceMotion = false,
  });

  static const textScales = [1.0, 1.15, 1.3, 1.5, 1.75, 2.0];

  /// Extra scale applied on top of the OS text scale.
  final double textScale;
  final bool highContrast;

  /// Speak agent replies aloud automatically.
  final bool voiceFeedback;

  /// 0.25 (slow) – 1.0 (fast).
  final double speechRate;
  final InteractionMode interactionMode;
  final bool reduceMotion;

  AccessibilitySettings copyWith({
    double? textScale,
    bool? highContrast,
    bool? voiceFeedback,
    double? speechRate,
    InteractionMode? interactionMode,
    bool? reduceMotion,
  }) =>
      AccessibilitySettings(
        textScale: textScale ?? this.textScale,
        highContrast: highContrast ?? this.highContrast,
        voiceFeedback: voiceFeedback ?? this.voiceFeedback,
        speechRate: speechRate ?? this.speechRate,
        interactionMode: interactionMode ?? this.interactionMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  @override
  List<Object?> get props => [textScale, highContrast, voiceFeedback, speechRate, interactionMode, reduceMotion];
}

final class AppPreferences extends Equatable {
  const AppPreferences({
    this.language = AppLanguage.english,
    this.languageChosen = false,
    this.onboardingComplete = false,
    this.cloudAiEnabled = true,
  });

  final AppLanguage language;
  final bool languageChosen;
  final bool onboardingComplete;

  /// User consent for sending minimised banking data to the cloud model.
  final bool cloudAiEnabled;

  AppPreferences copyWith({AppLanguage? language, bool? languageChosen, bool? onboardingComplete, bool? cloudAiEnabled}) =>
      AppPreferences(
        language: language ?? this.language,
        languageChosen: languageChosen ?? this.languageChosen,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        cloudAiEnabled: cloudAiEnabled ?? this.cloudAiEnabled,
      );

  @override
  List<Object?> get props => [language, languageChosen, onboardingComplete, cloudAiEnabled];
}

abstract interface class SettingsRepository {
  AccessibilitySettings loadAccessibility();
  Future<void> saveAccessibility(AccessibilitySettings s);
  AppPreferences loadPreferences();
  Future<void> savePreferences(AppPreferences p);
}
