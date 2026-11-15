import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_language.dart';
import '../../../../core/money/money.dart';
import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/bank_notification.dart';
import '../../../banking/domain/entities/bank_transaction.dart';
import '../../../banking/domain/entities/beneficiary.dart';
import '../../../banking/domain/entities/data_freshness.dart';
import '../../../banking/domain/services/spending_analyzer.dart';
import '../../../banking/domain/services/transaction_explainer.dart';
import '../../../transfers/domain/usecases/prepare_transfer.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/providers/ai_provider.dart';
import '../../domain/tools/banking_tools.dart';
import 'agent_phrasebook.dart';
import 'intent_parser.dart';

/// Deterministic on-device agent. Not an LLM: it maps recognised intents to
/// the same typed tools the cloud model uses, then renders replies from
/// localized templates using the *typed* tool output. Always available,
/// works offline, never throws for user input.
final class LocalIntentProvider implements AiProvider {
  const LocalIntentProvider({this.parser = const IntentParser(), required this.now});

  final IntentParser parser;
  final DateTime Function() now;

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
      final calls = _callsFor(intent);
      if (calls != null) return AiToolCallResponse(calls);
      return AiTextResponse(_direct(intent, p));
    }
    return AiTextResponse(_compose(intent, results, p));
  }

  List<ToolCallRequest>? _callsFor(ParsedIntent i) {
    ToolCallRequest c(String name, [Map<String, Object?> args = const {}]) =>
        ToolCallRequest(id: 'local-$name', name: name, args: args);
    String day(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return switch (i.type) {
      IntentType.balance => [c('get_account_balance')],
      IntentType.recentTransactions => [c('get_recent_transactions', {'limit': i.count ?? 5})],
      IntentType.searchIncoming => [
          c('search_transactions', {
            'direction': 'incoming',
            if (i.amount != null) 'amount': i.amount!.wholeUnits,
            if (i.yesterday) 'on_date': day(now().subtract(const Duration(days: 1))),
            'limit': 5,
          }),
        ],
      IntentType.searchCounterparty => [c('search_transactions', {'counterparty': i.name, 'limit': 5})],
      IntentType.spending => [
          c('calculate_monthly_spending', {
            if (i.category != null) 'category': i.category!.name,
            'month_offset': i.monthOffset,
          }),
        ],
      IntentType.explainTransaction => [
          c('explain_transaction', {if (i.transactionId != null) 'transaction_id': i.transactionId}),
        ],
      IntentType.notifications => [c('get_notifications', {'filter': 'all', 'limit': i.count ?? 3})],
      IntentType.receivedToday => [c('get_notifications', {'filter': 'received_today', 'limit': 10})],
      IntentType.beneficiaries => [c('list_beneficiaries')],
      IntentType.transfer when i.amount != null && i.name != null => [
          c('prepare_transfer', {'recipient_name': i.name, 'amount': i.amount!.wholeUnits}),
        ],
      _ => null,
    };
  }

  String _direct(ParsedIntent i, AgentPhrasebook p) => switch (i.type) {
        IntentType.transfer when i.amount == null => p.transferNeedsAmount(),
        IntentType.transfer => p.transferNeedsRecipient(),
        IntentType.greeting => p.greeting(),
        IntentType.thanks => p.thanks(),
        IntentType.help => p.help(),
        _ => p.unknown(),
      };

  String _compose(ParsedIntent intent, List<ToolExecutionRecord> results, AgentPhrasebook p) {
    final r = results.last;
    if (!r.ok) return _failureText(r.failure, intent, p);
    final out = r.output;
    String cached(Fresh<Object?> f) => f.isCached ? p.cachedPrefix(f.asOf) : '';

    switch (out) {
      case final Fresh<List<Account>> f:
        if (f.data.isEmpty) return p.noTransactions();
        final main = f.data.first;
        final others = f.data.skip(1).toList();
        final b = StringBuffer(cached(f))..write(p.balance(main.name, main.availableBalance));
        if (others.isNotEmpty) {
          b.write(p.otherAccounts(others.length, Money.sum(others.map((a) => a.availableBalance), main.balance.currency)));
        }
        return b.toString();

      case final Fresh<List<BankTransaction>> f:
        if (f.data.isEmpty) {
          return cached(f) + (intent.type == IntentType.searchIncoming ? p.incomingSearchNone() : p.noTransactions());
        }
        return [cached(f) + p.recentHeader(f.data.length), ...f.data.map(p.txLine)].join('\n');

      case final BankTransaction t:
        return p.txLine(t);

      case final TransactionExplanation e:
        final t = e.transaction;
        final c = p.category(t.category);
        final b = StringBuffer(t.isIncoming ? p.explainIncoming(t) : p.explainOutgoing(t, c));
        if (e.isRecurring) b.write(p.explainRecurring());
        if (e.categoryShareOfMonthPercent != null && e.categoryShareOfMonthPercent! < 100) {
          b.write(p.explainShare(e.categoryShareOfMonthPercent!, c));
        }
        if (e.fee != null && e.fee!.isPositive) b.write(p.explainFee(e.fee!));
        return b.toString();

      case final Fresh<SpendingSummary> f:
        final s = f.data;
        final b = StringBuffer(cached(f))
          ..write(p.spending(s.totalSpent,
              categoryName: intent.category == null ? null : p.category(intent.category!),
              lastMonth: intent.monthOffset == 1));
        if (intent.category == null && s.topCategory != null) {
          b.write(p.spendingTop(p.category(s.topCategory!.category), s.topCategory!.total));
        }
        if (s.changePercent != null) b.write(p.spendingChange(s.changePercent!));
        return b.toString();

      case final Fresh<List<BankNotification>> f:
        if (intent.type == IntentType.receivedToday) {
          if (f.data.isEmpty) return cached(f) + p.nothingReceivedToday();
          return [cached(f) + p.receivedTodayHeader(f.data.length), ...f.data.map(p.notification)].join('\n');
        }
        if (f.data.isEmpty) return cached(f) + p.noNotifications();
        return cached(f) + f.data.map(p.notification).join('\n');

      case final List<Beneficiary> list:
        return p.beneficiaries(list.map((b) => b.name).toList());

      case final PrepareTransferResult res:
        return switch (res.outcome) {
          TransferPrepared(:final draft) => p.draftReady(draft.beneficiary.name, draft.amount, draft.balanceAfter),
          TransferNeedsRecipientChoice(:final resolution) =>
            p.recipientChoice(res.input.recipientName, resolution.candidates.map((b) => b.name).toList()),
        };
    }
    return p.genericError();
  }

  String _failureText(Failure? f, ParsedIntent intent, AgentPhrasebook p) => switch (f?.code) {
        FailureCode.network => p.offlineNoData(),
        FailureCode.offlineNotAllowed => p.offlineNoTransfer(),
        FailureCode.beneficiaryNotFound => p.beneficiaryUnknown(intent.name),
        FailureCode.insufficientFunds => p.insufficientFunds(),
        FailureCode.invalidAmount => p.invalidAmount(),
        FailureCode.limitExceeded => p.limitExceeded(),
        FailureCode.toolNotPermitted => p.toolRejected(),
        FailureCode.notFound => p.noTransactions(),
        _ => p.genericError(),
      };
}
