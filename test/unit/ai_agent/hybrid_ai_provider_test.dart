import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/features/ai_agent/data/on_device/hybrid_ai_provider.dart';
import 'package:sauti/features/ai_agent/domain/entities/agent_card.dart';
import 'package:sauti/features/ai_agent/domain/entities/chat_message.dart';
import 'package:sauti/features/ai_agent/domain/entities/tool_call.dart';
import 'package:sauti/features/ai_agent/domain/entities/tool_spec.dart';
import 'package:sauti/features/ai_agent/domain/providers/ai_provider.dart';
import 'package:sauti/features/ai_agent/domain/services/agent_orchestrator.dart';
import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';

import '../../helpers/fakes.dart';

/// Behaves like Apple's LanguageModelSession: runs [script] (which may call
/// tools through [HybridToolHandler]) and returns the final text.
final class FakeHybridClient implements HybridAiClient {
  FakeHybridClient({
    this.onDevice = true,
    this.supportsLanguage = true,
    this.cloud = false,
    this.source = HybridSource.onDevice,
    required this.script,
  });

  bool onDevice;
  bool supportsLanguage;
  bool cloud;
  HybridSource source;
  final Future<String> Function(HybridToolHandler tool) script;
  final requests = <({String prompt, List<HybridToolSpec> tools, bool allowOnDevice, bool allowCloud})>[];
  final toolResults = <Map<String, Object?>>[];

  @override
  Future<HybridStatus> status({required String languageCode}) async => HybridStatus(
        onDeviceAvailable: onDevice,
        onDeviceReason: onDevice ? 'available' : 'deviceNotEligible',
        onDeviceSupportsLanguage: supportsLanguage && languageCode != 'rn',
        cloudAvailable: cloud,
      );

  @override
  Future<HybridResult> respond({
    required String instructions,
    required String prompt,
    required List<HybridToolSpec> tools,
    required String languageCode,
    required bool allowOnDevice,
    required bool allowCloud,
    required String cloudModel,
    required HybridToolHandler onToolCall,
  }) async {
    requests.add((prompt: prompt, tools: tools, allowOnDevice: allowOnDevice, allowCloud: allowCloud));
    Future<Map<String, Object?>> recordingTool(String name, Map<String, Object?> args) async {
      final r = await onToolCall(name, args);
      toolResults.add(r);
      return r;
    }

    final text = await script(recordingTool);
    return HybridResult(text: text, source: source);
  }

  @override
  Future<HybridJsonResult> generateJson({
    required String instructions,
    required String prompt,
    required Map<String, Object?> schema,
    required bool allowOnDevice,
    required bool allowCloud,
    required String cloudModel,
  }) =>
      throw const HybridAiException('unavailable');

  @override
  Future<OnDeviceState> prepareOnDevice() async => OnDeviceState.available;
}

void main() {
  late TestStack s;

  Future<ChatMessage> ask(String text, {AppLanguage lang = AppLanguage.english, List<ChatMessage> history = const []}) async {
    final events = await s.orchestrator.run(userText: text, history: history, language: lang).toList();
    return (events.last as AgentReplied).message;
  }

  HybridAiProvider provider(FakeHybridClient c, {bool cloudAllowed = false}) =>
      HybridAiProvider(client: c, cloudAllowed: () async => cloudAllowed, now: () => testNow, cloudModel: 'gemini-test');

  test('on-device model answers through the permissioned tools, labelled on-device', () async {
    final client = FakeHybridClient(script: (tool) async {
      final r = await tool('get_account_balance', {});
      final amount = ((r['accounts']! as List).first as Map)['available']! as Map;
      return 'You have ${amount['amount']} BIF available.';
    });
    s = TestStack(extraProviders: [provider(client)]);
    final m = await ask('How much money do I have?');
    expect(m.provider, AiProviderKind.onDeviceLlm);
    expect(m.usedFallback, isFalse);
    expect(m.cards.single, isA<BalanceCard>());
    expect(m.toolsUsed, ['get_account_balance']);
    expect(client.requests.single.allowCloud, isFalse, reason: 'cloud not allowed → on-device only');
    expect(s.registry.auditTrail.single.request.name, 'get_account_balance');
  });

  test('when on-device is unavailable the hybrid provider is skipped (cloud handled by GeminiAiProvider)', () async {
    final client = FakeHybridClient(
      onDevice: false,
      cloud: true,
      source: HybridSource.cloud,
      script: (tool) async => 'Hello!',
    );
    s = TestStack(extraProviders: [provider(client, cloudAllowed: true)]);
    // HybridAiProvider._route() returns null when onDevice=false, so this
    // provider is skipped. The orchestrator falls through to LocalIntentProvider.
    // Real cloud calls go through GeminiAiProvider (not in this test stack).
    final m = await ask('hello');
    expect(client.requests, isEmpty, reason: 'provider skipped when on-device unavailable');
    expect(m.provider, AiProviderKind.localDeterministic);
  });

  test('Kirundi without on-device support and no cloud → basic mode, not flagged as a failure', () async {
    final client = FakeHybridClient(script: (tool) async => fail('must not be called'));
    s = TestStack(extraProviders: [provider(client)]);
    final m = await ask('Amafaranga mfise ni angahe?', lang: AppLanguage.kirundi);
    expect(m.provider, AiProviderKind.localDeterministic);
    expect(m.usedFallback, isFalse);
    expect(client.requests, isEmpty);
  });

  test('ungrounded figures from the on-device model are discarded', () async {
    final client = FakeHybridClient(script: (tool) async {
      await tool('get_account_balance', {});
      return 'You have 9,999,999 BIF.';
    });
    s = TestStack(extraProviders: [provider(client)]);
    final m = await ask('How much money do I have?');
    expect(m.provider, AiProviderKind.localDeterministic);
    expect(m.text, contains('250,000 BIF'));
    expect(m.text, isNot(contains('9,999,999')));
  });

  test('the on-device model can only prepare a draft; unknown tools are rejected', () async {
    final client = FakeHybridClient(script: (tool) async {
      final prep = await tool('prepare_transfer', {'recipient_name': 'Jean', 'amount': 20000});
      expect(prep['state'], 'draft_created_not_sent');
      final submit = await tool('submit_transfer', {'draft_id': prep['draft_id']});
      expect(submit['status'], 'rejected');
      return 'I prepared 20,000 BIF to Jean Ndayishimiye. Nothing has been sent yet.';
    });
    s = TestStack(extraProviders: [provider(client)]);
    final m = await ask('Send 20000 BIF to Jean');
    expect(m.provider, AiProviderKind.onDeviceLlm);
    expect(m.cards.whereType<TransferDraftCard>(), hasLength(1));
    expect(s.simulated.appliedTransfers, 0);
  });

  test('a native error falls back to the next provider', () async {
    final client = FakeHybridClient(script: (tool) async => throw const HybridAiException('contextTooLarge'));
    s = TestStack(extraProviders: [provider(client)]);
    final m = await ask('How much money do I have?');
    expect(m.provider, AiProviderKind.localDeterministic);
    expect(m.usedFallback, isTrue);
  });

  test('tool progress streams live while the native session is still running', () async {
    final client = FakeHybridClient(script: (tool) async {
      await tool('get_account_balance', {});
      return 'You have 250,000 BIF available.';
    });
    s = TestStack(extraProviders: [provider(client)]);
    final events = await s.orchestrator.run(userText: 'balance', history: const [], language: AppLanguage.english).toList();
    expect(events.map((e) => e.runtimeType.toString()),
        ['AgentProviderSelected', 'AgentToolStarted', 'AgentToolFinished', 'AgentReplied']);
  });

  test('prompt carries recent history; tool specs keep types and ranges', () {
    final prompt = HybridAiProvider.buildPrompt(const [
      UserTurn('one'),
      AssistantTurn('two'),
      UserTurn('three'),
      AssistantTurn('four'),
      UserTurn('five'),
      AssistantTurn('six'),
      UserTurn('now?'),
    ], historyTurns: 4);
    expect(prompt, isNot(contains('one')));
    expect(prompt, isNot(contains('two')));
    expect(prompt, contains('User: three'));
    expect(prompt, contains('Sauti: six'));
    expect(prompt.trim().split('\n').last, 'User: now?');
    expect(HybridAiProvider.buildPrompt(const [UserTurn('hi')], historyTurns: 4), 'hi');

    final spec = HybridAiProvider.toHybridSpec(const ToolSpec(
      name: 'x',
      description: 'd',
      params: [
        ToolParam(name: 'n', type: ToolParamType.integer, description: 'n', minimum: 1, maximum: 20, required: true),
        ToolParam(name: 'e', type: ToolParamType.enumeration, description: 'e', enumValues: ['a', 'b']),
      ],
      permission: ToolPermission.readTransactions,
    ));
    expect(spec.params.first.toMap(),
        {'name': 'n', 'type': 'integer', 'description': 'n', 'required': true, 'enumValues': <String>[], 'minimum': 1, 'maximum': 20});
    expect(spec.params.last.type, HybridParamType.enumeration);
    expect(spec.params.last.toMap().containsKey('minimum'), isFalse);
  });

  test('tool calls from the native side are executed and audited by the registry', () async {
    final client = FakeHybridClient(script: (tool) async {
      await tool('list_beneficiaries', {});
      return 'Your saved recipients are listed on screen.';
    });
    s = TestStack(extraProviders: [provider(client)]);
    await ask('Who can I send money to?');
    final rec = s.registry.auditTrail.single;
    expect(rec.status, ToolExecutionStatus.succeeded);
    expect(client.toolResults.single.containsKey('beneficiaries'), isTrue);
  });
}
