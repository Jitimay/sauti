import 'package:equatable/equatable.dart';

import '../../../core/l10n/app_language.dart';

enum RecognitionErrorKind { permissionDenied, unavailable, languageUnsupported, noMatch, network, unknown }

sealed class RecognitionEvent extends Equatable {
  const RecognitionEvent();
  @override
  List<Object?> get props => [];
}

final class RecognitionPartial extends RecognitionEvent {
  const RecognitionPartial(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

final class RecognitionFinal extends RecognitionEvent {
  const RecognitionFinal(this.text);
  final String text;
  @override
  List<Object?> get props => [text];
}

final class RecognitionError extends RecognitionEvent {
  const RecognitionError(this.kind, [this.detail]);
  final RecognitionErrorKind kind;
  final String? detail;
  @override
  List<Object?> get props => [kind, detail];
}

/// Which locale the recognizer will actually use for a requested language.
final class RecognitionLocale extends Equatable {
  const RecognitionLocale({required this.requested, required this.localeId, required this.isExactMatch});

  final AppLanguage requested;

  /// Platform locale id, or null if the language is unsupported on this device.
  final String? localeId;
  final bool isExactMatch;

  bool get supported => localeId != null;

  @override
  List<Object?> get props => [requested, localeId, isExactMatch];
}

/// Speech-to-text port. Independent of LLM and TTS so each can be replaced.
abstract interface class SpeechRecognizer {
  /// Requests microphone permission if needed and initialises the engine.
  Future<bool> initialize();

  Future<RecognitionLocale> resolveLocale(AppLanguage language);

  /// Listens once, emitting partial results then a single final result or
  /// error, and completes. Always bounded by [maxDuration] — the microphone
  /// is never left open indefinitely.
  Stream<RecognitionEvent> listen({
    required String localeId,
    Duration maxDuration = const Duration(seconds: 15),
    Duration silenceTimeout = const Duration(seconds: 3),
  });

  Future<void> stop();
  Future<void> cancel();
}
