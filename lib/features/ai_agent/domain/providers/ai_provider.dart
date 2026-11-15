import 'package:equatable/equatable.dart';

import '../../../../core/l10n/app_language.dart';
import '../entities/tool_call.dart';
import '../entities/tool_spec.dart';

enum AiProviderKind {
  /// Gemini via Firebase AI Logic.
  cloud,

  /// Reserved for a future on-device LLM. Not shipped: the Flutter Firebase AI
  /// SDK has no on-device inference (see docs/AI_ARCHITECTURE.md).
  onDeviceLlm,

  /// Deterministic local intent engine (not an LLM). Works offline.
  localDeterministic,
}

final class AiCapabilities extends Equatable {
  const AiCapabilities({
    required this.kind,
    required this.toolCalling,
    required this.freeformConversation,
    required this.worksOffline,
    required this.languages,
  });

  final AiProviderKind kind;
  final bool toolCalling;
  final bool freeformConversation;
  final bool worksOffline;
  final Set<AppLanguage> languages;

  @override
  List<Object?> get props => [kind, toolCalling, freeformConversation, worksOffline, languages];
}

/// Conversation turns as seen by providers.
sealed class AiTurn {
  const AiTurn();
}

final class UserTurn extends AiTurn {
  const UserTurn(this.text);
  final String text;
}

final class AssistantTurn extends AiTurn {
  const AssistantTurn(this.text);
  final String text;
}

final class ToolCallsTurn extends AiTurn {
  const ToolCallsTurn(this.calls, {this.providerNative});
  final List<ToolCallRequest> calls;

  /// Opaque provider data (e.g. a model `Content` with thought signatures)
  /// that must be echoed back verbatim by the same provider.
  final Object? providerNative;
}

final class ToolResultsTurn extends AiTurn {
  const ToolResultsTurn(this.records);
  final List<ToolExecutionRecord> records;
}

final class AiRequest {
  const AiRequest({required this.language, required this.turns, required this.tools});
  final AppLanguage language;
  final List<AiTurn> turns;
  final List<ToolSpec> tools;
}

sealed class AiResponse {
  const AiResponse();
}

final class AiTextResponse extends AiResponse {
  const AiTextResponse(this.text);
  final String text;
}

final class AiToolCallResponse extends AiResponse {
  const AiToolCallResponse(this.calls, {this.providerNative});
  final List<ToolCallRequest> calls;
  final Object? providerNative;
}

enum AiErrorKind { unavailable, quota, blocked, timeout, invalidResponse, unknown }

final class AiProviderException implements Exception {
  const AiProviderException(this.kind, [this.detail]);
  final AiErrorKind kind;
  final String? detail;
  @override
  String toString() => 'AiProviderException(${kind.name}${detail == null ? '' : ': $detail'})';
}

abstract interface class AiProvider {
  AiProviderKind get kind;

  Future<bool> isAvailable();

  Future<AiCapabilities> getCapabilities();

  /// Throws [AiProviderException] on failure.
  Future<AiResponse> generateResponse(AiRequest request);
}
