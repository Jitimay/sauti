import 'package:equatable/equatable.dart';

import '../../../core/l10n/app_language.dart';

enum InteractionMode { standard, simplified }

final class AccessibilitySettings extends Equatable {
  const AccessibilitySettings({
    this.textScale = 1.0,
    this.highContrast = false,
    this.voiceFeedbackChoice,
    this.speechRate = 0.5,
    this.interactionMode = InteractionMode.standard,
    this.reduceMotion = false,
  });

  static const textScales = [1.0, 1.15, 1.3, 1.5, 1.75, 2.0];

  /// Extra scale applied on top of the OS text scale.
  final double textScale;
  final bool highContrast;

  /// Speak agent replies aloud automatically.
  bool get voiceFeedback => voiceFeedbackChoice == true;

  /// Null until the user explicitly chooses whether to enable automatic voice.
  final bool? voiceFeedbackChoice;

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
        voiceFeedbackChoice: voiceFeedback ?? voiceFeedbackChoice,
        speechRate: speechRate ?? this.speechRate,
        interactionMode: interactionMode ?? this.interactionMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  @override
  List<Object?> get props => [textScale, highContrast, voiceFeedbackChoice, speechRate, interactionMode, reduceMotion];
}

enum AiInferenceMode { auto, cloud, onDevice }

final class AppPreferences extends Equatable {
  const AppPreferences({
    this.language = AppLanguage.english,
    this.languageChosen = false,
    this.onboardingComplete = false,
    this.cloudAiEnabled = true,
    this.aiInferenceMode = AiInferenceMode.auto,
    this.naturalVoiceEnabled = true,
  });

  final AppLanguage language;
  final bool languageChosen;
  final bool onboardingComplete;

  /// User consent for sending minimised banking data to the cloud model.
  final bool cloudAiEnabled;
  final AiInferenceMode aiInferenceMode;

  bool get allowsCloudInference => cloudAiEnabled && aiInferenceMode != AiInferenceMode.onDevice;

  /// Replies read aloud by Gemini TTS (cloud) instead of the device voice.
  final bool naturalVoiceEnabled;

  AppPreferences copyWith({
    AppLanguage? language,
    bool? languageChosen,
    bool? onboardingComplete,
    bool? cloudAiEnabled,
    AiInferenceMode? aiInferenceMode,
    bool? naturalVoiceEnabled,
  }) =>
      AppPreferences(
        language: language ?? this.language,
        languageChosen: languageChosen ?? this.languageChosen,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        cloudAiEnabled: cloudAiEnabled ?? this.cloudAiEnabled,
        aiInferenceMode: aiInferenceMode ?? this.aiInferenceMode,
        naturalVoiceEnabled: naturalVoiceEnabled ?? this.naturalVoiceEnabled,
      );

  @override
  List<Object?> get props => [language, languageChosen, onboardingComplete, cloudAiEnabled, aiInferenceMode, naturalVoiceEnabled];
}

abstract interface class SettingsRepository {
  AccessibilitySettings loadAccessibility();
  Future<void> saveAccessibility(AccessibilitySettings s);
  AppPreferences loadPreferences();
  Future<void> savePreferences(AppPreferences p);
}
