import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_language.dart';
import '../../domain/speech_recognizer.dart';
import '../../domain/speech_synthesizer.dart';

// ---- Events ----
sealed class VoiceEvent extends Equatable {
  const VoiceEvent();
  @override
  List<Object?> get props => [];
}

final class VoiceListeningStarted extends VoiceEvent {
  const VoiceListeningStarted(this.language, {this.overrideLanguage});
  final AppLanguage language;

  /// e.g. French recognition while the UI is in Kirundi (explicit user choice).
  final AppLanguage? overrideLanguage;
  @override
  List<Object?> get props => [language, overrideLanguage];
}

final class VoiceListeningStopped extends VoiceEvent {
  const VoiceListeningStopped();
}

final class _RecognitionReceived extends VoiceEvent {
  const _RecognitionReceived(this.event);
  final RecognitionEvent event;
  @override
  List<Object?> get props => [event];
}

final class SpeechPlaybackStarted extends VoiceEvent {
  const SpeechPlaybackStarted(
    this.text, {
    required this.language,
    required this.rate,
    this.private = false,
  });
  final String text;
  final AppLanguage language;
  final double rate;

  /// Produced on-device: speak with the device voice only.
  final bool private;
  @override
  List<Object?> get props => [text, language, rate, private];
}

final class SpeechPlaybackStopped extends VoiceEvent {
  const SpeechPlaybackStopped();
}

final class VoiceErrorDismissed extends VoiceEvent {
  const VoiceErrorDismissed();
}

// ---- State ----
enum VoiceStatus { idle, preparing, listening, speaking, error }

final class RecognizedUtterance extends Equatable {
  const RecognizedUtterance(this.seq, this.text, this.language);
  final int seq;
  final String text;
  final AppLanguage language;
  @override
  List<Object?> get props => [seq, text, language];
}

final class VoiceState extends Equatable {
  const VoiceState({
    this.status = VoiceStatus.idle,
    this.partial = '',
    this.recognized,
    this.error,
    this.unsupportedLanguage,
    this.ttsUnavailableFor,
    this.lastSpoken,
  });

  final VoiceStatus status;
  final String partial;

  /// Each final recognition gets a new [RecognizedUtterance.seq] so listeners
  /// react exactly once (SpeechRecognized).
  final RecognizedUtterance? recognized;

  /// SpeechRecognitionFailed reason.
  final RecognitionErrorKind? error;
  final AppLanguage? unsupportedLanguage;
  final AppLanguage? ttsUnavailableFor;
  final String? lastSpoken;

  VoiceState copyWith({
    VoiceStatus? status,
    String? partial,
    RecognizedUtterance? recognized,
    RecognitionErrorKind? Function()? error,
    AppLanguage? Function()? unsupportedLanguage,
    AppLanguage? Function()? ttsUnavailableFor,
    String? lastSpoken,
  }) => VoiceState(
    status: status ?? this.status,
    partial: partial ?? this.partial,
    recognized: recognized ?? this.recognized,
    error: error != null ? error() : this.error,
    unsupportedLanguage: unsupportedLanguage != null
        ? unsupportedLanguage()
        : this.unsupportedLanguage,
    ttsUnavailableFor: ttsUnavailableFor != null
        ? ttsUnavailableFor()
        : this.ttsUnavailableFor,
    lastSpoken: lastSpoken ?? this.lastSpoken,
  );

  @override
  List<Object?> get props => [
    status,
    partial,
    recognized,
    error,
    unsupportedLanguage,
    ttsUnavailableFor,
    lastSpoken,
  ];
}

/// Speech-to-text and text-to-speech state. Independent of the AI agent.
final class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  VoiceBloc(
    this._stt,
    this._tts, {
    this.maxListen = const Duration(seconds: 15),
  }) : super(const VoiceState()) {
    on<VoiceListeningStarted>(_onStart, transformer: droppable());
    on<VoiceListeningStopped>(_onStop);
    on<_RecognitionReceived>(_onRecognition);
    on<SpeechPlaybackStarted>(_onSpeak, transformer: restartable());
    on<SpeechPlaybackStopped>(_onStopSpeaking);
    on<VoiceErrorDismissed>(
      (e, emit) => emit(
        state.copyWith(
          status: VoiceStatus.idle,
          error: () => null,
          unsupportedLanguage: () => null,
          ttsUnavailableFor: () => null,
        ),
      ),
    );
  }

  final SpeechRecognizer _stt;
  final SpeechSynthesizer _tts;
  final Duration maxListen;
  StreamSubscription<RecognitionEvent>? _sub;
  int _seq = 0;
  AppLanguage _listeningLanguage = AppLanguage.english;

  Future<void> _onStart(
    VoiceListeningStarted e,
    Emitter<VoiceState> emit,
  ) async {
    if (state.status == VoiceStatus.listening) return;
    emit(
      state.copyWith(
        status: VoiceStatus.preparing,
        partial: '',
        error: () => null,
        unsupportedLanguage: () => null,
      ),
    );

    final lang = e.overrideLanguage ?? e.language;
    final RecognitionLocale locale;
    try {
      await _tts.stop();
      if (state.status != VoiceStatus.preparing) return;
      final ready = await _stt.initialize();
      if (state.status != VoiceStatus.preparing) return;
      if (!ready) {
        return emit(
          state.copyWith(
            status: VoiceStatus.error,
            error: () => RecognitionErrorKind.permissionDenied,
          ),
        );
      }
      locale = await _stt.resolveLocale(lang);
    } catch (_) {
      if (state.status != VoiceStatus.preparing) return;
      return emit(
        state.copyWith(
          status: VoiceStatus.error,
          error: () => RecognitionErrorKind.unavailable,
        ),
      );
    }
    if (state.status != VoiceStatus.preparing) return;
    if (!locale.supported) {
      return emit(
        state.copyWith(
          status: VoiceStatus.error,
          error: () => RecognitionErrorKind.languageUnsupported,
          unsupportedLanguage: () => lang,
        ),
      );
    }
    _listeningLanguage = lang;
    emit(state.copyWith(status: VoiceStatus.listening));
    await _sub?.cancel();
    _sub = _stt
        .listen(localeId: locale.localeId!, maxDuration: maxListen)
        .listen(
          (ev) => add(_RecognitionReceived(ev)),
          onDone: () => _sub = null,
        );
  }

  void _onRecognition(_RecognitionReceived e, Emitter<VoiceState> emit) {
    if (state.status != VoiceStatus.listening) return;
    switch (e.event) {
      case RecognitionPartial(:final text):
        emit(state.copyWith(partial: text));
      case RecognitionFinal(:final text):
        emit(
          state.copyWith(
            status: VoiceStatus.idle,
            partial: '',
            recognized: RecognizedUtterance(++_seq, text, _listeningLanguage),
          ),
        );
      case RecognitionError(:final kind):
        emit(
          state.copyWith(
            status: VoiceStatus.error,
            partial: '',
            error: () => kind,
            unsupportedLanguage: () =>
                kind == RecognitionErrorKind.languageUnsupported
                ? _listeningLanguage
                : null,
          ),
        );
    }
  }

  Future<void> _onStop(
    VoiceListeningStopped e,
    Emitter<VoiceState> emit,
  ) async {
    if (state.status == VoiceStatus.preparing) {
      emit(state.copyWith(status: VoiceStatus.idle));
      return;
    }
    if (state.status != VoiceStatus.listening) return;
    // stop() lets the engine deliver a final result for what was said.
    await _stt.stop();
  }

  Future<void> _onSpeak(
    SpeechPlaybackStarted e,
    Emitter<VoiceState> emit,
  ) async {
    if (state.status == VoiceStatus.listening) {
      return; // never talk over the user
    }
    if (!await _tts.supports(e.language)) {
      return emit(
        state.copyWith(ttsUnavailableFor: () => e.language, lastSpoken: e.text),
      );
    }
    emit(
      state.copyWith(
        status: VoiceStatus.speaking,
        lastSpoken: e.text,
        ttsUnavailableFor: () => null,
      ),
    );
    try {
      await _tts.speak(
        e.text,
        language: e.language,
        rate: e.rate,
        private: e.private,
      );
    } catch (_) {
      emit(state.copyWith(ttsUnavailableFor: () => e.language));
    }
    if (state.status == VoiceStatus.speaking) {
      emit(state.copyWith(status: VoiceStatus.idle));
    }
  }

  Future<void> _onStopSpeaking(
    SpeechPlaybackStopped e,
    Emitter<VoiceState> emit,
  ) async {
    await _tts.stop();
    if (state.status == VoiceStatus.speaking) {
      emit(state.copyWith(status: VoiceStatus.idle));
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _stt.cancel();
    await _tts.stop();
    return super.close();
  }
}
