import 'dart:async';

import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';

import '../../../../core/l10n/app_language.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/providers/ai_provider.dart';
import '../local/agent_phrasebook.dart';
import '../local/intent_agent.dart';
import '../local/intent_parser.dart';
import 'intent_schema.dart';

/// Hybrid inference for platforms whose on-device model has no function
/// calling: Gemini Nano on Android (Firebase AI Logic hybrid SDK) and in
/// Chrome (Firebase AI Logic JS SDK), with cloud Gemini as fallback.
///
/// The model only labels the request ([IntentSchema]). Sauti then runs its
/// permissioned tools through the orchestrator's [ToolExecutor] and renders
/// the reply from typed tool output in the user's language. So:
///
/// * private by default: on-device, the request never leaves the phone, and
///   banking data is never sent to any model;
/// * no hallucinated figures: the model never writes the reply;
/// * French requests are labelled on-device too; replies use French templates.
///   Kirundi skips the on-device model (unvalidated) and goes to the cloud
///   agent or basic mode.
final class HybridIntentProvider implements AiProvider, LanguageAwareProvider {
  HybridIntentProvider({
    required this._client,
    required this._cloudAllowed,
    required this._now,
    required this.cloudModel,
    this.onDeviceLanguages = const {AppLanguage.english, AppLanguage.french},
    this.timeout = const Duration(seconds: 20),
    this._parser = const IntentParser(),
  });

  final HybridAiClient _client;

  /// User setting + connectivity + Firebase configured.
  final Future<bool> Function() _cloudAllowed;
  final DateTime Function() _now;
  final IntentParser _parser;
  final String cloudModel;

  /// Languages the on-device model is trusted to label.
  final Set<AppLanguage> onDeviceLanguages;
  final Duration timeout;

  @override
  AiProviderKind get kind => AiProviderKind.onDeviceLlm;

  @override
  Future<bool> isAvailable() async => (await _route(AppLanguage.english)) != null;

  @override
  Future<bool> isAvailableFor(AppLanguage language) async => (await _route(language)) != null;

  @override
  Future<AiCapabilities> getCapabilities() async => const AiCapabilities(
        kind: AiProviderKind.onDeviceLlm,
        toolCalling: false,
        freeformConversation: false,
        worksOffline: true,
        languages: {AppLanguage.english, AppLanguage.french, AppLanguage.kirundi},
      );

  Future<({bool onDevice, bool cloud})?> _route(AppLanguage language) async {
    final status = await _client.status(languageCode: language.code);
    final onDevice = status.onDeviceState == OnDeviceState.available && onDeviceLanguages.contains(language);
    if (!onDevice) {
      // Without Gemini Nano, the full cloud agent (function calling) or basic
      // mode answers instead; this provider is the on-device tier.
      return null;
    }
    // Cloud Gemini only as an in-SDK fallback for a failed on-device call.
    return (onDevice: true, cloud: status.cloudAvailable && await _cloudAllowed());
  }

  @override
  Future<AiResponse> generateResponse(AiRequest request) async {
    final execute = request.executeTool;
    if (execute == null) {
      throw const AiProviderException(AiErrorKind.unavailable, 'hybrid intent provider needs a tool executor');
    }
    final route = await _route(request.language);
    if (route == null) throw const AiProviderException(AiErrorKind.unavailable, 'no inference path');

    final lastUser = request.turns.lastWhere((t) => t is UserTurn) as UserTurn;
    final previous = request.turns.reversed.whereType<AssistantTurn>().firstOrNull?.text;

    final HybridJsonResult result;
    try {
      result = await _client
          .generateJson(
            instructions: IntentSchema.instructions(request.language),
            prompt: IntentSchema.prompt(lastUser.text, previousReply: previous),
            schema: IntentSchema.jsonSchema,
            allowOnDevice: route.onDevice,
            allowCloud: route.cloud,
            cloudModel: cloudModel,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const AiProviderException(AiErrorKind.timeout, 'intent model timed out');
    } on HybridAiException catch (e) {
      throw AiProviderException(_errorKind(e.code), '${e.code}: ${e.message ?? ''}');
    }

    var intent = IntentSchema.toIntent(result.json, userText: lastUser.text);
    if (intent.type == IntentType.unknown) {
      // A small model can miss what the keyword engine knows; never do worse
      // than basic mode.
      final keyword = _parser.parse(lastUser.text);
      if (keyword.type != IntentType.unknown) intent = keyword;
    }

    final agent = IntentAgent(now: _now);
    final phrases = AgentPhrasebook.of(request.language);
    final servedBy = result.source == HybridSource.cloud ? AiProviderKind.cloud : AiProviderKind.onDeviceLlm;
    final calls = agent.callsFor(intent);
    if (calls == null) {
      return AiTextResponse(agent.direct(intent, phrases), servedBy: servedBy, renderedFromTools: true);
    }
    final records = <ToolExecutionRecord>[for (final c in calls) await execute(c)];
    return AiTextResponse(agent.compose(intent, records, phrases), servedBy: servedBy, renderedFromTools: true);
  }

  static AiErrorKind _errorKind(String code) => switch (code) {
        'unavailable' || 'unsupportedLanguage' || 'network' => AiErrorKind.unavailable,
        'quota' => AiErrorKind.quota,
        'blocked' => AiErrorKind.blocked,
        'invalidResponse' || 'contextTooLarge' => AiErrorKind.invalidResponse,
        _ => AiErrorKind.unknown,
      };
}
