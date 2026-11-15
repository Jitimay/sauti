import 'dart:async';

import 'package:sauti/core/network/network_status.dart';
import 'package:sauti/core/utils/clock.dart';
import 'package:sauti/features/ai_agent/data/local/local_intent_provider.dart';
import 'package:sauti/features/ai_agent/domain/providers/ai_provider.dart';
import 'package:sauti/features/ai_agent/domain/services/agent_orchestrator.dart';
import 'package:sauti/features/ai_agent/domain/tools/agent_tool.dart';
import 'package:sauti/features/ai_agent/domain/tools/banking_tools.dart';
import 'package:sauti/features/ai_agent/domain/tools/tool_registry.dart';
import 'package:sauti/features/banking/data/datasources/bank_snapshot_store.dart';
import 'package:sauti/features/banking/data/repositories/caching_bank_repository.dart';
import 'package:sauti/features/banking/data/repositories/simulated_bank_repository.dart';
import 'package:sauti/features/banking/domain/entities/transfer_policy.dart';
import 'package:sauti/features/banking/domain/services/transfer_preparer.dart';
import 'package:sauti/features/banking/domain/usecases/banking_usecases.dart';
import 'package:sauti/features/transfers/domain/usecases/prepare_transfer.dart';
import 'package:sauti/features/transfers/domain/usecases/submit_transfer.dart';

/// Wednesday 18 Nov 2026, 10:00 — fixed so demo data is deterministic.
DateTime get testNow => DateTime(2026, 11, 18, 10);

final class FakeNetwork implements NetworkStatus {
  FakeNetwork({this.online = true});
  bool online;
  final _c = StreamController<bool>.broadcast();
  void set(bool v) {
    online = v;
    _c.add(v);
  }

  @override
  Future<bool> isOnline() async => online;
  @override
  Stream<bool> watch() async* {
    yield online;
    yield* _c.stream;
  }
}

int _ids = 0;
String testId() => 'id-${_ids++}';

/// Full in-memory demo stack used across unit, bloc and widget tests.
final class TestStack {
  TestStack({bool online = true, TransferPolicy policy = TransferPolicy.bifDefault, List<AiProvider>? extraProviders})
      : network = FakeNetwork(online: online),
        clock = FixedClock(testNow) {
    simulated = SimulatedBankRepository(clock: clock, network: network, policy: policy, latency: Duration.zero);
    bank = CachingBankRepository(simulated, snapshots);
    preparer = TransferPreparer(policy: policy, clock: clock, newId: testId);
    prepareTransfer = PrepareTransfer(bank, preparer, network);
    submitTransfer = SubmitTransfer(bank, clock, network);
    registry = ToolRegistry([
      GetAccountBalanceTool(GetAccounts(bank)),
      GetRecentTransactionsTool(GetRecentTransactions(bank)),
      SearchTransactionsTool(SearchTransactions(bank), clock),
      GetTransactionDetailsTool(GetTransactionDetails(bank)),
      ExplainTransactionTool(ExplainTransaction(bank)),
      CalculateMonthlySpendingTool(CalculateMonthlySpending(bank, clock), clock),
      ListBeneficiariesTool(ListBeneficiaries(bank)),
      PrepareTransferTool(prepareTransfer),
      const ConfirmTransferTool(),
      GetNotificationsTool(GetNotifications(bank), clock),
    ]);
    orchestrator = AgentOrchestrator(
      providers: [...?extraProviders, LocalIntentProvider(now: clock.now)],
      registry: registry,
      clock: clock,
      newId: testId,
      drafts: drafts,
    );
  }

  final FakeNetwork network;
  final FixedClock clock;
  final snapshots = InMemoryBankSnapshotStore();
  final drafts = SessionDraftStore();
  late final SimulatedBankRepository simulated;
  late final CachingBankRepository bank;
  late final TransferPreparer preparer;
  late final PrepareTransfer prepareTransfer;
  late final SubmitTransfer submitTransfer;
  late final ToolRegistry registry;
  late final AgentOrchestrator orchestrator;
}
