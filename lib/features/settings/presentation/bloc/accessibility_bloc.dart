import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/settings.dart';

sealed class AccessibilityEvent extends Equatable {
  const AccessibilityEvent();
  @override
  List<Object?> get props => [];
}

final class AccessibilitySettingsLoaded extends AccessibilityEvent {
  const AccessibilitySettingsLoaded();
}

final class FontSizeChanged extends AccessibilityEvent {
  const FontSizeChanged(this.scale);
  final double scale;
  @override
  List<Object?> get props => [scale];
}

final class VoiceFeedbackChanged extends AccessibilityEvent {
  const VoiceFeedbackChanged(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

final class HighContrastChanged extends AccessibilityEvent {
  const HighContrastChanged(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

final class InteractionModeChanged extends AccessibilityEvent {
  const InteractionModeChanged(this.mode);
  final InteractionMode mode;
  @override
  List<Object?> get props => [mode];
}

final class SpeechRateChanged extends AccessibilityEvent {
  const SpeechRateChanged(this.rate);
  final double rate;
  @override
  List<Object?> get props => [rate];
}

final class ReduceMotionChanged extends AccessibilityEvent {
  const ReduceMotionChanged(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}

/// Accessibility settings are applied app-wide (theme, text scale, speech).
final class AccessibilityBloc extends Bloc<AccessibilityEvent, AccessibilitySettings> {
  AccessibilityBloc(this._repo) : super(const AccessibilitySettings()) {
    on<AccessibilitySettingsLoaded>((e, emit) => emit(_repo.loadAccessibility()));
    on<FontSizeChanged>((e, emit) => _save(emit, state.copyWith(textScale: e.scale.clamp(1.0, 2.0))));
    on<VoiceFeedbackChanged>((e, emit) => _save(emit, state.copyWith(voiceFeedback: e.enabled)));
    on<HighContrastChanged>((e, emit) => _save(emit, state.copyWith(highContrast: e.enabled)));
    on<InteractionModeChanged>((e, emit) => _save(emit, state.copyWith(interactionMode: e.mode)));
    on<SpeechRateChanged>((e, emit) => _save(emit, state.copyWith(speechRate: e.rate.clamp(0.25, 1.0))));
    on<ReduceMotionChanged>((e, emit) => _save(emit, state.copyWith(reduceMotion: e.enabled)));
  }

  final SettingsRepository _repo;

  Future<void> _save(Emitter<AccessibilitySettings> emit, AccessibilitySettings next) async {
    emit(next);
    await _repo.saveAccessibility(next);
  }
}
