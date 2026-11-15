import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/app_language.dart';
import '../domain/settings.dart';

/// Non-sensitive settings in SharedPreferences.
final class PrefsSettingsRepository implements SettingsRepository {
  PrefsSettingsRepository(this._p);
  final SharedPreferences _p;

  static const _k = 'settings.';

  @override
  AccessibilitySettings loadAccessibility() {
    const d = AccessibilitySettings();
    return AccessibilitySettings(
      textScale: (_p.getDouble('${_k}textScale') ?? d.textScale).clamp(1.0, 2.0),
      highContrast: _p.getBool('${_k}highContrast') ?? d.highContrast,
      voiceFeedback: _p.getBool('${_k}voiceFeedback') ?? d.voiceFeedback,
      speechRate: (_p.getDouble('${_k}speechRate') ?? d.speechRate).clamp(0.25, 1.0),
      interactionMode: InteractionMode.values
              .where((m) => m.name == _p.getString('${_k}interactionMode'))
              .firstOrNull ??
          d.interactionMode,
      reduceMotion: _p.getBool('${_k}reduceMotion') ?? d.reduceMotion,
    );
  }

  @override
  Future<void> saveAccessibility(AccessibilitySettings s) async {
    await _p.setDouble('${_k}textScale', s.textScale);
    await _p.setBool('${_k}highContrast', s.highContrast);
    await _p.setBool('${_k}voiceFeedback', s.voiceFeedback);
    await _p.setDouble('${_k}speechRate', s.speechRate);
    await _p.setString('${_k}interactionMode', s.interactionMode.name);
    await _p.setBool('${_k}reduceMotion', s.reduceMotion);
  }

  @override
  AppPreferences loadPreferences() => AppPreferences(
        language: AppLanguage.fromCode(_p.getString('${_k}language')),
        languageChosen: _p.getString('${_k}language') != null,
        onboardingComplete: _p.getBool('${_k}onboardingComplete') ?? false,
        cloudAiEnabled: _p.getBool('${_k}cloudAiEnabled') ?? true,
      );

  @override
  Future<void> savePreferences(AppPreferences p) async {
    if (p.languageChosen) await _p.setString('${_k}language', p.language.code);
    await _p.setBool('${_k}onboardingComplete', p.onboardingComplete);
    await _p.setBool('${_k}cloudAiEnabled', p.cloudAiEnabled);
  }
}
