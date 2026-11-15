import '../../../../core/l10n/app_language.dart';
import '../../domain/providers/ai_provider.dart';
import 'agent_phrasebook.dart';
import 'intent_agent.dart';
import 'intent_parser.dart';

/// Deterministic on-device agent. Not an LLM: it maps recognised intents to
/// the same typed tools the cloud model uses, then renders replies from
/// localized templates using the *typed* tool output. Always available,
/// works offline, never throws for user input.
final class LocalIntentProvider implements AiProvider {
  const LocalIntentProvider({this.parser = const IntentParser(), required this.now});

  final IntentParser parser;
  final DateTime Function() now;

  IntentAgent get _agent => IntentAgent(now: now);

  @override
  AiProviderKind get kind => AiProviderKind.localDeterministic;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<AiCapabilities> getCapabilities() async => AiCapabilities(
        kind: kind,
        toolCalling: true,
        freeformConversation: false,
        worksOffline: true,
        languages: AppLanguage.values.toSet(),
      );

  @override
  Future<AiResponse> generateResponse(AiRequest request) async {
    final lastUserIndex = request.turns.lastIndexWhere((t) => t is UserTurn);
    final userText = (request.turns[lastUserIndex] as UserTurn).text;
    final intent = parser.parse(userText);
    final results = request.turns.skip(lastUserIndex + 1).whereType<ToolResultsTurn>().expand((t) => t.records).toList();
    final p = AgentPhrasebook.of(request.language);

    if (results.isEmpty) {
      final calls = _agent.callsFor(intent);
      if (calls != null) return AiToolCallResponse(calls);
      return AiTextResponse(_agent.direct(intent, p));
    }
    return AiTextResponse(_agent.compose(intent, results, p));
  }

}
