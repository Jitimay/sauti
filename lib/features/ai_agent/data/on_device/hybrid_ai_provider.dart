import 'dart:async';

import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';

import '../../../../core/l10n/app_language.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/entities/tool_spec.dart';
import '../../domain/providers/ai_provider.dart';
import 'sauti_compact_prompt.dart';

/// Hybrid inference through a native bridge: the on-device model first
/// (Apple Foundation Models on iOS), Gemini via Firebase AI Logic as the cloud
/// fallback when the user allows cloud AI and the device is online.
///
/// The native session drives the tool loop; each tool call comes back here and
/// runs through the orchestrator's permissioned [ToolExecutor], so validation,
/// permissions, audit and the grounding guard are identical to the other
/// providers.
final class HybridAiProvider implements AiProvider, LanguageAwareProvider {
  HybridAiProvider({
    required this._client,
    required this._cloudAllowed,
    required this._now,
    required this.cloudModel,
    this.historyTurns = 4,
    this.timeout = const Duration(seconds: 10),
  });

  final HybridAiClient _client;

  /// User setting + connectivity + Firebase configured.
  final Future<bool> Function() _cloudAllowed;
  final DateTime Function() _now;
  final String cloudModel;

  /// Prior user/assistant turns included in the prompt (context is small).
  final int historyTurns;

  /// Upper bound for one native request, including its tool calls.
  final Duration timeout;

  @override
  AiProviderKind get kind => AiProviderKind.onDeviceLlm;

  @override
  Future<bool> isAvailable() async => (await _route(AppLanguage.english)) != null;

  /// Whether this provider can answer in [language] right now.
  @override
  Future<bool> isAvailableFor(AppLanguage language) async => (await _route(language)) != null;

  @override
  Future<AiCapabilities> getCapabilities() async => const AiCapabilities(
        kind: AiProviderKind.onDeviceLlm,
        toolCalling: true,
        freeformConversation: true,
        worksOffline: true,
        languages: {AppLanguage.english, AppLanguage.french},
      );

  /// Decides which engines may run. Returns null when none can.
  /// When on-device is not available, return null so the cloud-only
  /// GeminiAiProvider handles the request (it uses function calling properly,
  /// vs. the native session which has its own timeout behaviour).
  Future<({bool onDevice, bool cloud})?> _route(AppLanguage language) async {
    final status = await _client.status(languageCode: language.code);
    final onDevice = status.onDeviceAvailable && status.onDeviceSupportsLanguage;
    if (!onDevice) return null; // let GeminiAiProvider handle cloud
    final cloud = status.cloudAvailable && await _cloudAllowed();
    return (onDevice: true, cloud: cloud);
  }

  @override
  Future<AiResponse> generateResponse(AiRequest request) async {
    final execute = request.executeTool;
    if (execute == null) {
      throw const AiProviderException(AiErrorKind.unavailable, 'hybrid provider needs a tool executor');
    }
    final route = await _route(request.language);
    if (route == null) {
      throw const AiProviderException(AiErrorKind.unavailable, 'no on-device model and cloud not allowed');
    }

    var callSeq = 0;
    try {
      final result = await _client.respond(
        instructions: SautiCompactPrompt.build(request.language, today: _now()),
        prompt: buildPrompt(request.turns, historyTurns: historyTurns),
        tools: [for (final t in request.tools) toHybridSpec(t)],
        languageCode: request.language.code,
        allowOnDevice: route.onDevice,
        allowCloud: route.cloud,
        cloudModel: cloudModel,
        onToolCall: (name, args) async =>
            (await execute(ToolCallRequest(id: 'native-${callSeq++}', name: name, args: args))).modelPayload,
      ).timeout(timeout);
      return AiTextResponse(
        result.text,
        servedBy: result.source == HybridSource.cloud ? AiProviderKind.cloud : AiProviderKind.onDeviceLlm,
      );
    } on TimeoutException {
      // A stuck generation must never freeze the assistant (AgentBloc drops
      // new messages while one is running); the orchestrator falls back.
      throw const AiProviderException(AiErrorKind.timeout, 'on-device generation timed out');
    } on HybridAiException catch (e) {
      throw AiProviderException(_errorKind(e.code), '${e.code}: ${e.message ?? ''}');
    }
  }

  static AiErrorKind _errorKind(String code) => switch (code) {
        'unavailable' || 'unsupportedLanguage' || 'network' => AiErrorKind.unavailable,
        'quota' => AiErrorKind.quota,
        'blocked' => AiErrorKind.blocked,
        'contextTooLarge' || 'toolLoop' => AiErrorKind.invalidResponse,
        _ => AiErrorKind.unknown,
      };

  /// Flattens recent conversation into one prompt: the native session is
  /// created per request, so history travels as text (tool results do not).
  static String buildPrompt(List<AiTurn> turns, {required int historyTurns}) {
    final textTurns = [
      for (final t in turns)
        if (t is UserTurn || t is AssistantTurn) t,
    ];
    if (textTurns.isEmpty) return '';
    final current = textTurns.last;
    final earlier = textTurns.sublist(0, textTurns.length - 1);
    final recent = earlier.length > historyTurns ? earlier.sublist(earlier.length - historyTurns) : earlier;
    String text(AiTurn t) => switch (t) {
          UserTurn(:final text) => text,
          AssistantTurn(:final text) => text,
          _ => '',
        };
    if (recent.isEmpty) return text(current);
    return [
      'Conversation so far:',
      for (final t in recent) '${t is UserTurn ? 'User' : 'Sauti'}: ${text(t)}',
      '',
      'User: ${text(current)}',
    ].join('\n');
  }

  static HybridToolSpec toHybridSpec(ToolSpec spec) => HybridToolSpec(
        name: spec.name,
        description: spec.description,
        params: [
          for (final p in spec.params)
            HybridToolParam(
              name: p.name,
              type: switch (p.type) {
                ToolParamType.string => HybridParamType.string,
                ToolParamType.integer => HybridParamType.integer,
                ToolParamType.enumeration => HybridParamType.enumeration,
              },
              description: p.description,
              required: p.required,
              enumValues: p.enumValues,
              minimum: p.minimum,
              maximum: p.maximum,
            ),
        ],
      );
}
