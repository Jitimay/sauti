import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';

import '../../../../core/l10n/app_language.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/entities/tool_spec.dart';
import '../../domain/providers/ai_provider.dart';
import 'sauti_system_prompt.dart';

/// Sends a full request to a Gemini model. Injected so tests can supply a fake.
typedef GeminiGenerate = Future<GenerateContentResponse> Function({
  required List<Content> contents,
  required Content systemInstruction,
  required List<Tool> tools,
});

/// Cloud inference via Firebase AI Logic (Gemini Developer API backend).
///
/// * Function calling uses typed declarations generated from [ToolSpec]s.
/// * Only data-minimised tool payloads are sent (see banking_tools.dart).
/// * App Check tokens are attached by the SDK when App Check is activated.
final class GeminiAiProvider implements AiProvider {
  GeminiAiProvider({
    required this._generate,
    required this._isEnabled,
    required this._now,
    this.timeout = const Duration(seconds: 20),
  });

  /// Production wiring using `FirebaseAI.googleAI()`.
  factory GeminiAiProvider.firebase({
    required String model,
    required Future<bool> Function() isEnabled,
    required DateTime Function() now,
  }) {
    final cache = <String, GenerativeModel>{};
    return GeminiAiProvider(
      isEnabled: isEnabled,
      now: now,
      generate: ({required contents, required systemInstruction, required tools}) {
        // The system prompt embeds language + date, so models are cached per prompt.
        final key = (systemInstruction.parts.first as TextPart).text;
        final m = cache.putIfAbsent(
          key,
          () => FirebaseAI.googleAI(useLimitedUseAppCheckTokens: true).generativeModel(
            model: model,
            systemInstruction: systemInstruction,
            tools: tools,
            toolConfig: ToolConfig(functionCallingConfig: FunctionCallingConfig.auto()),
            // Banking lookups need little deliberation; low thinking (the lowest
            // level gemini-3.8-flash accepts) shortens each round trip.
            generationConfig: GenerationConfig(
              temperature: 0.2,
              maxOutputTokens: 600,
              thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
            ),
          ),
        );
        return m.generateContent(contents);
      },
    );
  }

  final GeminiGenerate _generate;
  final Future<bool> Function() _isEnabled;
  final DateTime Function() _now;
  final Duration timeout;

  @override
  AiProviderKind get kind => AiProviderKind.cloud;

  @override
  Future<bool> isAvailable() => _isEnabled();

  @override
  Future<AiCapabilities> getCapabilities() async => AiCapabilities(
        kind: kind,
        toolCalling: true,
        freeformConversation: true,
        worksOffline: false,
        languages: AppLanguage.values.toSet(),
      );

  @override
  Future<AiResponse> generateResponse(AiRequest request) async {
    final GenerateContentResponse res;
    try {
      res = await _generate(
        contents: toContents(request.turns),
        systemInstruction: Content.system(SautiSystemPrompt.build(request.language, today: _now())),
        tools: [Tool.functionDeclarations(request.tools.map(toDeclaration).toList())],
      ).timeout(timeout);
    } on TimeoutException {
      throw const AiProviderException(AiErrorKind.timeout);
    } on QuotaExceeded catch (e) {
      throw AiProviderException(AiErrorKind.quota, e.message);
    } on InvalidApiKey catch (e) {
      throw AiProviderException(AiErrorKind.unavailable, e.message);
    } on ServiceApiNotEnabled catch (e) {
      throw AiProviderException(AiErrorKind.unavailable, e.message);
    } on UnsupportedUserLocation catch (e) {
      throw AiProviderException(AiErrorKind.unavailable, e.message);
    } on FirebaseAIException catch (e) {
      throw AiProviderException(AiErrorKind.unknown, e.message);
    } catch (e) {
      throw AiProviderException(AiErrorKind.unavailable, e.runtimeType.toString());
    }

    if (res.candidates.isEmpty) {
      throw AiProviderException(AiErrorKind.blocked, res.promptFeedback?.blockReason?.name);
    }
    final calls = res.functionCalls.toList();
    if (calls.isNotEmpty) {
      return AiToolCallResponse(
        [
          for (var i = 0; i < calls.length; i++)
            ToolCallRequest(
              id: calls[i].id ?? 'call-$i',
              name: calls[i].name,
              args: Map<String, Object?>.from(calls[i].args),
            ),
        ],
        providerNative: res.candidates.first.content,
      );
    }
    final String? text;
    try {
      text = res.text?.trim();
    } on FirebaseAIException catch (e) {
      throw AiProviderException(AiErrorKind.blocked, e.message);
    }
    if (text == null || text.isEmpty) throw const AiProviderException(AiErrorKind.invalidResponse, 'empty');
    return AiTextResponse(text);
  }

  /// Maps provider-neutral turns to Gemini contents.
  static List<Content> toContents(List<AiTurn> turns) => [
        for (final t in turns)
          switch (t) {
            UserTurn(:final text) => Content.text(text),
            AssistantTurn(:final text) => Content.model([TextPart(text)]),
            // Echo the model's own content (keeps thought signatures intact).
            ToolCallsTurn(:final providerNative?) when providerNative is Content => providerNative,
            ToolCallsTurn(:final calls) => Content.model([for (final c in calls) FunctionCall(c.name, c.args, id: c.id)]),
            ToolResultsTurn(:final records) => Content.functionResponses([
                for (final r in records)
                  FunctionResponse(r.request.name, r.modelPayload, id: r.request.id.startsWith('call-') ? null : r.request.id),
              ]),
          },
      ];

  static FunctionDeclaration toDeclaration(ToolSpec spec) => FunctionDeclaration(
        spec.name,
        spec.description,
        parameters: {for (final p in spec.params) p.name: _schema(p)},
        optionalParameters: [for (final p in spec.params) if (!p.required) p.name],
      );

  static Schema _schema(ToolParam p) => switch (p.type) {
        ToolParamType.string => Schema.string(description: p.description),
        ToolParamType.integer => Schema.integer(description: p.description, minimum: p.minimum, maximum: p.maximum),
        ToolParamType.enumeration => Schema.enumString(enumValues: p.enumValues, description: p.description),
      };
}
