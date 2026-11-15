import 'package:flutter_test/flutter_test.dart';
import 'package:sauti/core/error/failure.dart';
import 'package:sauti/core/l10n/app_language.dart';
import 'package:sauti/features/ai_agent/domain/entities/agent_card.dart';
import 'package:sauti/features/ai_agent/domain/entities/tool_call.dart';
import 'package:sauti/features/ai_agent/domain/entities/tool_spec.dart';
import 'package:sauti/features/ai_agent/domain/tools/agent_tool.dart';

import '../../helpers/fakes.dart';

void main() {
  late TestStack s;
  late ToolContext model;
  setUp(() {
    s = TestStack();
    model = ToolContext(
      caller: ToolCaller.cloudModel,
      language: AppLanguage.english,
      granted: s.orchestrator.granted,
      drafts: s.drafts,
    );
  });

  Future<ToolExecutionRecord> run(String name, Map<String, Object?> args, [ToolContext? ctx]) =>
      s.registry.execute(ToolCallRequest(id: 'c', name: name, args: args), ctx ?? model);

  test('every tool has a description and typed params', () {
    final specs = s.registry.specsFor(ToolCaller.cloudModel, s.orchestrator.granted);
    expect(specs.map((e) => e.name), containsAll(['get_account_balance', 'prepare_transfer', 'confirm_transfer']));
    for (final spec in specs) {
      expect(spec.description.length, greaterThan(20), reason: spec.name);
    }
  });

  test('balance tool returns minimised payload with provenance', () async {
    final r = await run('get_account_balance', {});
    expect(r.ok, isTrue);
    expect(r.modelPayload['data_source'], 'live');
    expect(r.card, isA<BalanceCard>());
    expect(r.modelPayload.toString(), isNot(contains('4821')), reason: 'no account numbers to the model');
  });

  test('unknown tool is rejected', () async {
    final r = await run('execute_transfer_now', {'amount': 1});
    expect(r.status, ToolExecutionStatus.rejected);
    expect(r.failure?.code, FailureCode.toolNotPermitted);
  });

  test('tools outside granted permissions are rejected', () async {
    final ctx = ToolContext(caller: ToolCaller.cloudModel, language: AppLanguage.english, granted: const {}, drafts: s.drafts);
    final r = await run('get_account_balance', {}, ctx);
    expect(r.status, ToolExecutionStatus.rejected);
  });

  test('search on_date rejects impossible dates instead of rolling over', () async {
    expect((await run('search_transactions', {'on_date': '2026-13-45'})).status, ToolExecutionStatus.rejected);
    expect((await run('search_transactions', {'on_date': '2026-02-30'})).status, ToolExecutionStatus.rejected);
    expect((await run('search_transactions', {'on_date': '2026-11-15'})).ok, isTrue);
  });

  group('malicious / misleading model arguments', () {
    test('unknown extra arguments are rejected (e.g. injected account id)', () async {
      final r = await run('prepare_transfer', {'recipient_name': 'Jean', 'amount': 1000, 'from_account': 'other-user'});
      expect(r.status, ToolExecutionStatus.rejected);
      expect(s.drafts.latest, isNull);
    });

    test('negative, fractional, huge and string-injected amounts are rejected', () async {
      for (final amount in [-20000, 20000.5, 1e15, '20000; DROP', 'twenty']) {
        final r = await run('prepare_transfer', {'recipient_name': 'Jean', 'amount': amount});
        expect(r.ok, isFalse, reason: '$amount');
      }
      expect(s.simulated.appliedTransfers, 0);
    });

    test('unsaved recipient cannot be targeted', () async {
      final r = await run('prepare_transfer', {'recipient_name': 'Attacker Account 99887766', 'amount': 1000});
      expect(r.status, ToolExecutionStatus.failed);
      expect(r.failure?.code, FailureCode.beneficiaryNotFound);
    });

    test('confirm_transfer only accepts drafts created by the app this session', () async {
      final r = await run('confirm_transfer', {'draft_id': 'invented-by-model'});
      expect(r.ok, isFalse);
    });

    test('confirm_transfer never moves money', () async {
      final prep = await run('prepare_transfer', {'recipient_name': 'Jean', 'amount': 20000});
      final draftId = prep.modelPayload['draft_id']! as String;
      final r = await run('confirm_transfer', {'draft_id': draftId});
      expect(r.ok, isTrue);
      expect(r.modelPayload['sent'], false);
      expect(s.simulated.appliedTransfers, 0);
    });

    test('bad transaction ids and dates are rejected', () async {
      expect((await run('get_transaction_details', {'transaction_id': '../../users/x'})).ok, isFalse);
      expect((await run('search_transactions', {'on_date': 'yesterday'})).ok, isFalse);
      expect((await run('search_transactions', {'direction': 'sideways'})).ok, isFalse);
      expect((await run('get_recent_transactions', {'limit': 10000})).ok, isFalse);
    });
  });

  test('transaction descriptions reach the model only as *_untrusted data', () async {
    final r = await run('get_recent_transactions', {'limit': 2});
    final txs = r.modelPayload['transactions']! as List;
    expect((txs.first as Map).containsKey('description_untrusted'), isTrue);
    expect((txs.first as Map).containsKey('counterparty_untrusted'), isTrue);
    expect((txs.first as Map).containsKey('counterparty'), isFalse);
    expect((txs.first as Map).containsKey('description'), isFalse);
  });

  test('audit trail records every call without arguments', () async {
    await run('get_account_balance', {});
    await run('nope', {});
    expect(s.registry.auditTrail.length, 2);
    expect(s.registry.auditTrail.last.status, ToolExecutionStatus.rejected);
  });
}
