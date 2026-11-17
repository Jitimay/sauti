import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_language.dart';
import '../../domain/settings.dart';

final class PreferencesCubit extends Cubit<AppPreferences> {
  PreferencesCubit(this._repo) : super(_repo.loadPreferences());

  final SettingsRepository _repo;

  Future<void> _set(AppPreferences p) async {
    emit(p);
    await _repo.savePreferences(p);
  }

  Future<void> setLanguage(AppLanguage l) => _set(state.copyWith(language: l, languageChosen: true));
  Future<void> completeOnboarding() => _set(state.copyWith(onboardingComplete: true));
  Future<void> setCloudAi(bool enabled) => _set(state.copyWith(cloudAiEnabled: enabled));
  Future<void> setNaturalVoice(bool enabled) => _set(state.copyWith(naturalVoiceEnabled: enabled));
}
