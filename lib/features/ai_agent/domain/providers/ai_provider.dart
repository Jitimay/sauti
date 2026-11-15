import 'package:equatable/equatable.dart';

import '../../../../core/l10n/app_language.dart';
import '../entities/tool_call.dart';
import '../entities/tool_spec.dart';

enum AiProviderKind {
  /// Gemini via Firebase AI Logic.
  cloud,

  /// An on-device LLM (e.g. Apple Foundation Models on iOS), reached through
  /// a native bridge. Data stays on the device.
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

/// Runs one tool call through the permissioned registry and returns the
/// data-minimised payload for the model. Supplied by the orchestrator.
typedef ToolExecutor = Future<Map<String, Object?>> Function(ToolCallRequest call);

final class AiRequest {
  const AiRequest({required this.language, required this.turns, required this.tools, this.executeTool});
  final AppLanguage language;
  final List<AiTurn> turns;
  final List<ToolSpec> tools;

  /// For providers whose runtime drives the tool loop itself (for example
  /// Apple's Foundation Models sessions). Such providers call this for each
  /// tool and return only the final [AiTextResponse]. Providers that return
  /// [AiToolCallResponse] instead ignore it.
  final ToolExecutor? executeTool;
}

sealed class AiResponse {
  const AiResponse();
}

final class AiTextResponse extends AiResponse {
  const AiTextResponse(this.text, {this.servedBy});
  final String text;

  /// Which inference path actually produced this text, when a provider can
  /// use more than one (e.g. on-device first, cloud fallback).
  final AiProviderKind? servedBy;
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

/// Optional: a provider whose availability depends on the request language
/// (e.g. an on-device model that does not support Kirundi).
abstract interface class LanguageAwareProvider {
  Future<bool> isAvailableFor(AppLanguage language);
}

abstract interface class AiProvider {
  AiProviderKind get kind;

  Future<bool> isAvailable();

  Future<AiCapabilities> getCapabilities();

  /// Throws [AiProviderException] on failure.
  Future<AiResponse> generateResponse(AiRequest request);
}
