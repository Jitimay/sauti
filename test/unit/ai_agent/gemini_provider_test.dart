import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/features/ai_agent/data/cloud/gemini_ai_provider.dart';
import 'package:sauti/features/ai_agent/data/cloud/sauti_system_prompt.dart';
import 'package:sauti/features/ai_agent/domain/entities/tool_call.dart';
import 'package:sauti/features/ai_agent/domain/entities/tool_spec.dart';
import 'package:sauti/features/ai_agent/domain/providers/ai_provider.dart';

import '../../helpers/fakes.dart';

GenerateContentResponse resp(List<Part> parts) =>
    GenerateContentResponse([Candidate(Content.model(parts), null, null, FinishReason.stop, null)], null);

void main() {
  const spec = ToolSpec(
    name: 'prepare_transfer',
    description: 'Prepares a transfer to a saved beneficiary.',
    params: [
      ToolParam(name: 'recipient_name', type: ToolParamType.string, description: 'name', required: true),
      ToolParam(name: 'amount', type: ToolParamType.integer, description: 'BIF', required: true, minimum: 1),
      ToolParam(name: 'kind', type: ToolParamType.enumeration, description: 'k', enumValues: ['a', 'b']),
    ],
    permission: ToolPermission.prepareTransfer,
  );

  test('ToolSpec maps to a FunctionDeclaration with optional params', () {
    final json = GeminiAiProvider.toDeclaration(spec).toJson();
    expect(json['name'], 'prepare_transfer');
    final params = json['parameters']! as Map;
    expect((params['properties']! as Map).keys, containsAll(['recipient_name', 'amount', 'kind']));
    expect(params['required'], containsAll(['recipient_name', 'amount']));
    expect(params['required'], isNot(contains('kind')));
  });

  test('function calls become ToolCallRequests and keep native content', () async {
    late List<Content> sent;
    final p = GeminiAiProvider(
      isEnabled: () async => true,
      now: () => testNow,
      generate: ({required contents, required systemInstruction, required tools}) async {
        sent = contents;
        return resp([const FunctionCall('get_account_balance', {}, id: 'fc1')]);
      },
    );
    final r = await p.generateResponse(
        AiRequest(language: AppLanguage.french, turns: const [UserTurn('solde?')], tools: const [spec]));
    expect(r, isA<AiToolCallResponse>());
    final call = (r as AiToolCallResponse).calls.single;
    expect(call.name, 'get_account_balance');
    expect(call.id, 'fc1');
    expect(r.providerNative, isA<Content>());
    expect(sent.single.role, 'user');
  });

  test('tool results are sent back as function responses with minimised payload', () {
    final contents = GeminiAiProvider.toContents([
      const UserTurn('balance'),
      const ToolCallsTurn([ToolCallRequest(id: 'fc1', name: 'get_account_balance', args: {})]),
      const ToolResultsTurn([
        ToolExecutionRecord(
          request: ToolCallRequest(id: 'fc1', name: 'get_account_balance', args: {}),
          status: ToolExecutionStatus.succeeded,
          modelPayload: {'status': 'ok'},
          duration: Duration.zero,
        ),
      ]),
    ]);
    expect(contents.length, 3);
    expect(contents[1].parts.single, isA<FunctionCall>());
    final fr = contents[2].parts.single as FunctionResponse;
    expect(fr.name, 'get_account_balance');
    expect(fr.response, {'status': 'ok'});
  });

  test('SDK errors become AiProviderException (triggers fallback)', () async {
    final p = GeminiAiProvider(
      isEnabled: () async => true,
      now: () => testNow,
      generate: ({required contents, required systemInstruction, required tools}) async =>
          throw QuotaExceeded('quota'),
    );
    expect(
      () => p.generateResponse(const AiRequest(language: AppLanguage.english, turns: [UserTurn('x')], tools: [])),
      throwsA(isA<AiProviderException>().having((e) => e.kind, 'kind', AiErrorKind.quota)),
    );
  });

  test('system prompt enforces language and safety rules', () {
    final s = SautiSystemPrompt.build(AppLanguage.kirundi, today: testNow);
    expect(s, contains('Ikirundi'));
    expect(s, contains('NOTHING HAS BEEN SENT'));
    expect(s, contains('PIN'));
    expect(s, contains('_untrusted'));
    expect(s, contains('2026-11-18'));
  });
}
