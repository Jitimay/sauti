import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/features/ai_agent/domain/entities/agent_card.dart';
import 'package:sauti/features/ai_agent/domain/entities/chat_message.dart';
import 'package:sauti/features/ai_agent/domain/entities/tool_call.dart';
import 'package:sauti/features/ai_agent/domain/providers/ai_provider.dart';
import 'package:sauti/features/ai_agent/domain/services/agent_orchestrator.dart';
import 'package:sauti/features/ai_agent/domain/services/grounding_guard.dart';

import '../../helpers/fakes.dart';

/// Scripted cloud provider for tests.
final class ScriptedCloud implements AiProvider {
  ScriptedCloud(this.script, {this.available = true});
  final List<AiResponse Function(AiRequest)> script;
  bool available;
  int calls = 0;
  final requests = <AiRequest>[];

  @override
  AiProviderKind get kind => AiProviderKind.cloud;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<AiCapabilities> getCapabilities() async => throw UnimplementedError();
  @override
  Future<AiResponse> generateResponse(AiRequest r) async {
    requests.add(r);
    if (calls >= script.length) throw const AiProviderException(AiErrorKind.unavailable);
    return script[calls++](r);
  }
}

Future<ChatMessage> ask(TestStack s, String text, {AppLanguage lang = AppLanguage.english}) async {
  final events = await s.orchestrator.run(userText: text, history: const [], language: lang).toList();
  return (events.last as AgentReplied).message;
}

void main() {
  group('local deterministic agent (offline-capable)', () {
    test('Scenario 1: balance from the banking tool', () async {
      final s = TestStack();
      final m = await ask(s, 'How much money do I have?');
      expect(m.text, contains('250,000 BIF'));
      expect(m.toolsUsed, ['get_account_balance']);
      expect(m.cards.single, isA<BalanceCard>());
      expect(m.provider, AiProviderKind.localDeterministic);
    });

    test('Scenario 2: recent transactions', () async {
      final m = await ask(TestStack(), 'Show me the last five transactions');
      expect(m.cards.single, isA<TransactionsCard>());
      expect((m.cards.single as TransactionsCard).transactions.data.length, 5);
    });

    test('Scenario 3: explain last transaction', () async {
      final m = await ask(TestStack(), 'Explain my last transaction');
      expect(m.text, contains('Jean Ndayishimiye'));
      expect(m.text, contains('50,000 BIF'));
      expect(m.cards.single, isA<TransactionDetailCard>());
    });

    test('Scenario 4: transfer is prepared, never sent', () async {
      final s = TestStack();
      final m = await ask(s, 'Send 20,000 BIF to Jean');
      expect(m.cards.single, isA<TransferDraftCard>());
      expect(m.text, contains('Nothing has been sent'));
      expect(s.simulated.appliedTransfers, 0);
    });

    test('French and Kirundi replies', () async {
      final fr = await ask(TestStack(), 'Quel est mon solde ?', lang: AppLanguage.french);
      expect(fr.text, contains('disponibles'));
      final rn = await ask(TestStack(), 'Amafaranga mfise ni angahe?', lang: AppLanguage.kirundi);
      expect(rn.text, contains('ufise'));
    });

    test('spending answer uses deterministic totals', () async {
      final m = await ask(TestStack(), 'How much did I spend this month?');
      expect(m.text, contains('60,000 BIF'));
      expect(m.text, contains('groceries'));
    });

    test('received today', () async {
      final m = await ask(TestStack(), 'Did I receive any money today?');
      expect(m.text, contains('Jean Ndayishimiye'));
    });

    test('Scenario 7: offline uses cached data and says so', () async {
      final s = TestStack();
      await ask(s, 'What is my balance?');
      s.network.set(false);
      final m = await ask(s, 'What is my balance?');
      expect(m.text, contains('offline'));
      expect(m.text, contains('250,000 BIF'));
      expect((m.cards.single as BalanceCard).accounts.isCached, isTrue);
    });

    test('offline transfer is refused, never queued', () async {
      final s = TestStack();
      s.network.set(false);
      final m = await ask(s, 'Send 20000 BIF to Jean');
      expect(m.text, contains('never queued'));
      s.network.set(true);
      expect(s.simulated.appliedTransfers, 0);
    });

    test('unknown beneficiary is refused', () async {
      final m = await ask(TestStack(), 'Send 5000 BIF to Pierre');
      expect(m.text, contains('not among your saved recipients'));
      expect(m.cards, isEmpty);
    });
  });

  group('hybrid provider selection', () {
    test('cloud is used when available and can call tools', () async {
      final cloud = ScriptedCloud([
        (_) => const AiToolCallResponse([ToolCallRequest(id: '1', name: 'get_account_balance', args: {})]),
        (r) => const AiTextResponse('You have 250,000 BIF available.'),
      ]);
      final s = TestStack(extraProviders: [cloud]);
      final m = await ask(s, 'balance?');
      expect(m.provider, AiProviderKind.cloud);
      expect(m.usedFallback, isFalse);
      expect(m.cards.single, isA<BalanceCard>());
      expect(cloud.requests.first.tools.map((t) => t.name), isNot(contains('submit_transfer')));
    });

    test('Scenario 8: cloud unavailable → deterministic fallback', () async {
      final cloud = ScriptedCloud([], available: false);
      final m = await ask(TestStack(extraProviders: [cloud]), 'How much money do I have?');
      expect(m.provider, AiProviderKind.localDeterministic);
      expect(m.text, contains('250,000 BIF'));
    });

    test('cloud error mid-request → fallback flagged', () async {
      final cloud = ScriptedCloud([]); // throws on first call
      final m = await ask(TestStack(extraProviders: [cloud]), 'How much money do I have?');
      expect(m.provider, AiProviderKind.localDeterministic);
      expect(m.usedFallback, isTrue);
    });

    test('hallucinated amount from the model is discarded', () async {
      final cloud = ScriptedCloud([(_) => const AiTextResponse('Your balance is 9,999,999 BIF.')]);
      final m = await ask(TestStack(extraProviders: [cloud]), 'How much money do I have?');
      expect(m.provider, AiProviderKind.localDeterministic);
      expect(m.text, contains('250,000 BIF'));
      expect(m.text, isNot(contains('9,999,999')));
    });

    test('drafts from an abandoned cloud attempt are dropped on fallback', () async {
      final cloud = ScriptedCloud([
        (_) => const AiToolCallResponse(
            [ToolCallRequest(id: '1', name: 'prepare_transfer', args: {'recipient_name': 'Jean', 'amount': 20000})]),
        (_) => const AiTextResponse('Done: 7,777,777 BIF sent.'), // ungrounded → fallback
      ]);
      final s = TestStack(extraProviders: [cloud]);
      final m = await ask(s, 'Send 20000 BIF to Jean');
      expect(m.provider, AiProviderKind.localDeterministic);
      expect(s.drafts.ids, hasLength(1), reason: 'only the fallback draft remains');
      expect(m.cards.whereType<TransferDraftCard>().single.draft.id, s.drafts.ids.single);
      expect(s.simulated.appliedTransfers, 0);
    });

    test('model tool loop that never converges falls back', () async {
      final cloud = ScriptedCloud(List.filled(
          10, (_) => const AiToolCallResponse([ToolCallRequest(id: 'x', name: 'get_account_balance', args: {})])));
      final m = await ask(TestStack(extraProviders: [cloud]), 'balance');
      expect(m.provider, AiProviderKind.localDeterministic);
    });

    test('model attempting a forbidden tool gets a rejection result, not execution', () async {
      final cloud = ScriptedCloud([
        (_) => const AiToolCallResponse([ToolCallRequest(id: '1', name: 'submit_transfer', args: {'amount': 1})]),
        (r) {
          final res = (r.turns.last as ToolResultsTurn).records.single;
          expect(res.status, ToolExecutionStatus.rejected);
          return const AiTextResponse('I cannot do that.');
        },
      ]);
      final s = TestStack(extraProviders: [cloud]);
      final m = await ask(s, 'send all my money now');
      expect(m.text, 'I cannot do that.');
      expect(s.simulated.appliedTransfers, 0);
    });
  });

  group('GroundingGuard', () {
    const g = GroundingGuard();
    test('accepts figures from tools, user text, and simple sums', () {
      final rec = ToolExecutionRecord(
        request: const ToolCallRequest(id: '1', name: 'x', args: {}),
        status: ToolExecutionStatus.succeeded,
        modelPayload: const {'amount': 15000, 'b': {'amount': 30000}},
        duration: Duration.zero,
      );
      expect(g.ungroundedAmounts('You spent 45,000 BIF: 15 000 BIF and 30.000 BIF', userText: '', records: [rec]), isEmpty);
      expect(g.ungroundedAmounts('Sending 20,000 BIF', userText: 'send 20000 to jean', records: const []), isEmpty);
      expect(g.ungroundedAmounts('You have 1,000,000 BIF', userText: '', records: [rec]), {1000000});
    });

    test('catches bare grouped figures without a currency word', () {
      final rec = ToolExecutionRecord(
        request: const ToolCallRequest(id: '1', name: 'x', args: {}),
        status: ToolExecutionStatus.succeeded,
        modelPayload: const {'amount': 250000},
        duration: Duration.zero,
      );
      expect(g.ungroundedAmounts('Your balance is 999,999.', userText: '', records: [rec]), {999999});
      expect(g.ungroundedAmounts('Your balance is 250 000.', userText: '', records: [rec]), isEmpty);
      expect(g.ungroundedAmounts('You made 3 transfers on 2026-11-15.', userText: '', records: [rec]), isEmpty);
    });
  });
}
