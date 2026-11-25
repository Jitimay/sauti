import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/features/ai_agent/data/local/intent_parser.dart';
import 'package:sauti/features/ai_agent/data/on_device/hybrid_intent_provider.dart';
import 'package:sauti/features/ai_agent/data/on_device/intent_schema.dart';
import 'package:sauti/features/ai_agent/domain/entities/agent_card.dart';
import 'package:sauti/features/ai_agent/domain/entities/chat_message.dart';
import 'package:sauti/features/ai_agent/domain/providers/ai_provider.dart';
import 'package:sauti/features/ai_agent/domain/services/agent_orchestrator.dart';
import 'package:sauti_hybrid_ai/sauti_hybrid_ai.dart';

import '../../helpers/fakes.dart';

/// Behaves like Gemini Nano via Firebase AI Logic: returns a JSON intent.
base class FakeIntentClient implements HybridAiClient {
  FakeIntentClient(
    this.json, {
    this.state = OnDeviceState.available,
    this.source = HybridSource.onDevice,
  });
  Map<String, Object?> json;
  OnDeviceState state;
  HybridSource source;
  final calls = <({bool onDevice, bool cloud})>[];

  @override
  Future<HybridStatus> status({required String languageCode}) async =>
      HybridStatus(
        onDeviceAvailable: state == OnDeviceState.available,
        onDeviceReason: state.name,
        onDeviceSupportsLanguage: true,
        cloudAvailable: true,
        onDeviceState: state,
      );

  @override
  Future<HybridJsonResult> generateJson({
    required String instructions,
    required String prompt,
    required Map<String, Object?> schema,
    required bool allowOnDevice,
    required bool allowCloud,
    required String cloudModel,
  }) async {
    calls.add((onDevice: allowOnDevice, cloud: allowCloud));
    return HybridJsonResult(json: json, source: source);
  }

  @override
  Future<OnDeviceState> prepareOnDevice() async => state;

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
  }) => throw const HybridAiException('unavailable');
}

void main() {
  late TestStack s;

  Future<ChatMessage> ask(
    String text, {
    AppLanguage lang = AppLanguage.english,
  }) async {
    final events = await s.orchestrator
        .run(userText: text, history: const [], language: lang)
        .toList();
    return (events.last as AgentReplied).message;
  }

  HybridIntentProvider provider(
    FakeIntentClient c, {
    bool cloudAllowed = false,
  }) => HybridIntentProvider(
    client: c,
    cloudAllowed: () async => cloudAllowed,
    now: () => testNow,
    cloudModel: 'gemini-test',
  );

  test('Gemini Nano labels the intent; Sauti tools and templates answer, labelled on-device', () async {
    final client = FakeIntentClient({'intent': 'balance'});
    s = TestStack(extraProviders: [provider(client)]);
    final m = await ask('What do I have left in the bank?');
    expect(m.provider, AiProviderKind.onDeviceLlm);
    expect(m.cards.single, isA<BalanceCard>());
    expect(m.text, contains('250,000 BIF'));
    expect(client.calls.single, (onDevice: true, cloud: false));
  });

  test('transfer intent only drafts, with the amount the user said, never the model\'s', () async {
    final client = FakeIntentClient({
      'intent': 'transfer',
      'amount': 999999,
      'name': 'Jean',
    });
    s = TestStack(extraProviders: [provider(client)]);
    final m = await ask('Please send 20,000 to Jean');
    expect(
      m.cards.whereType<TransferDraftCard>().single.draft.amount.wholeUnits,
      20000,
    );
    expect(
      s.simulated.appliedTransfers,
      0,
      reason: 'a model can never move money',
    );
  });

  test('a recipient the user never said is dropped', () {
    final i = IntentSchema.toIntent({
      'intent': 'transfer',
      'amount': 5000,
      'name': 'Aline',
    }, userText: 'send 5000 to Jean');
    expect(i.type, IntentType.transfer);
    expect(i.name, isNull);
  });

  test(
    'Nano not downloaded uses the Firebase SDK cloud fallback when permitted',
    () async {
      final client = FakeIntentClient(
        {'intent': 'balance'},
        state: OnDeviceState.downloadable,
        source: HybridSource.cloud,
      );
      s = TestStack(extraProviders: [provider(client, cloudAllowed: true)]);
      final reply = await ask('How much money do I have?');
      expect(reply.provider, AiProviderKind.cloud);
      expect(reply.cards.single, isA<BalanceCard>());
      expect(client.calls.single, (onDevice: true, cloud: true));

      s = TestStack(extraProviders: [provider(client)]);
      expect(
        (await ask('How much money do I have?')).provider,
        AiProviderKind.localDeterministic,
      );
      expect(client.calls, hasLength(1));
    },
  );

  test('Kirundi skips on-device intent classification', () async {
    final ready = FakeIntentClient({'intent': 'balance'});
    s = TestStack(extraProviders: [provider(ready)]);
    expect(
      (await ask(
        'Amafaranga mfise ni angahe?',
        lang: AppLanguage.kirundi,
      )).provider,
      AiProviderKind.localDeterministic,
    );
    expect(ready.calls, isEmpty);
  });

  test('unknown from the model falls back to the keyword engine', () async {
    final client = FakeIntentClient({'intent': 'unknown'});
    s = TestStack(extraProviders: [provider(client)]);
    final m = await ask('How much money do I have?');
    expect(m.provider, AiProviderKind.onDeviceLlm);
    expect(m.cards.single, isA<BalanceCard>());
  });
}
