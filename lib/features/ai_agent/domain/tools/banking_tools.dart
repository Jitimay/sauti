import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/money/money.dart';
import '../../../../core/utils/clock.dart';
import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/bank_notification.dart';
import '../../../banking/domain/entities/bank_transaction.dart';
import '../../../banking/domain/entities/beneficiary.dart';
import '../../../banking/domain/entities/data_freshness.dart';
import '../../../banking/domain/entities/transaction_query.dart';
import '../../../banking/domain/entities/transfer.dart';
import '../../../banking/domain/services/spending_analyzer.dart';
import '../../../banking/domain/services/transaction_explainer.dart';
import '../../../banking/domain/usecases/banking_usecases.dart';
import '../../../transfers/domain/usecases/prepare_transfer.dart';
import '../entities/agent_card.dart';
import '../entities/tool_spec.dart';
import 'agent_tool.dart';

// Shared, data-minimised projections. No account numbers, user IDs or tokens.
Map<String, Object?> _fresh(Fresh<Object?> f) =>
    {'data_source': f.source.name, 'as_of': f.asOf.toIso8601String()};

Map<String, Object?> _money(Money m) => {'amount': m.wholeUnits, 'currency': m.currency.code};

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Map<String, Object?> _tx(BankTransaction t) => {
      'transaction_id': t.id,
      'direction': t.direction.name,
      ..._money(t.amount),
      // Free text from third parties: data only, never instructions.
      'counterparty_untrusted': t.counterparty,
      'category': t.category.name,
      'date': _day(t.timestamp),
      'status': t.status.name,
      'description_untrusted': t.description,
    };

final class NoInput {
  const NoInput();
}

// ---------------------------------------------------------------------------

final class GetAccountBalanceTool extends AgentTool<NoInput, Fresh<List<Account>>> {
  const GetAccountBalanceTool(this._getAccounts);
  final GetAccounts _getAccounts;

  @override
  ToolSpec get spec => const ToolSpec(
        name: 'get_account_balance',
        description: "Returns the user's accounts with available balances and whether the data is live or cached.",
        params: [],
        permission: ToolPermission.readAccounts,
      );

  @override
  NoInput parse(Map<String, Object?> args) {
    rejectUnknown(args);
    return const NoInput();
  }

  @override
  Future<Result<Fresh<List<Account>>>> execute(NoInput input, ToolContext context) => _getAccounts();

  @override
  Map<String, Object?> toModelPayload(Fresh<List<Account>> output) => {
        ..._fresh(output),
        'accounts': [
          for (final a in output.data) {'name': a.name, 'type': a.type.name, 'available': _money(a.availableBalance)},
        ],
      };

  @override
  AgentCard toCard(Fresh<List<Account>> output) => BalanceCard(output);
}

// ---------------------------------------------------------------------------

final class GetRecentTransactionsTool extends AgentTool<int, Fresh<List<BankTransaction>>> {
  const GetRecentTransactionsTool(this._recent);
  final GetRecentTransactions _recent;

  @override
  ToolSpec get spec => const ToolSpec(
        name: 'get_recent_transactions',
        description: 'Returns the most recent transactions, newest first.',
        params: [
          ToolParam(
              name: 'limit',
              type: ToolParamType.integer,
              description: 'How many transactions (1-20). Default 5.',
              minimum: 1,
              maximum: 20),
        ],
        permission: ToolPermission.readTransactions,
      );

  @override
  int parse(Map<String, Object?> args) {
    rejectUnknown(args);
    return optInt(args, 'limit', min: 1, max: 20) ?? 5;
  }

  @override
  Future<Result<Fresh<List<BankTransaction>>>> execute(int limit, ToolContext c) => _recent(limit: limit);

  @override
  Map<String, Object?> toModelPayload(Fresh<List<BankTransaction>> output) =>
      {..._fresh(output), 'transactions': output.data.map(_tx).toList()};

  @override
  AgentCard toCard(Fresh<List<BankTransaction>> output) => TransactionsCard(output);
}

// ---------------------------------------------------------------------------

final class SearchTransactionsTool extends AgentTool<TransactionQuery, Fresh<List<BankTransaction>>> {
  const SearchTransactionsTool(this._search, this._clock);
  final SearchTransactions _search;
  final Clock _clock;

  @override
  ToolSpec get spec => ToolSpec(
        name: 'search_transactions',
        description: 'Searches transactions by counterparty name, direction, category, exact amount, '
            'a specific date, or a number of past days.',
        params: [
          const ToolParam(name: 'counterparty', type: ToolParamType.string, description: 'Name to search for.'),
          const ToolParam(
              name: 'direction',
              type: ToolParamType.enumeration,
              description: 'incoming = money received, outgoing = money spent/sent.',
              enumValues: ['incoming', 'outgoing']),
          ToolParam(
              name: 'category',
              type: ToolParamType.enumeration,
              description: 'Transaction category.',
              enumValues: TransactionCategory.values.map((e) => e.name).toList()),
          const ToolParam(
              name: 'amount', type: ToolParamType.integer, description: 'Exact amount in BIF.', minimum: 1),
          const ToolParam(name: 'on_date', type: ToolParamType.string, description: 'Specific day, YYYY-MM-DD.'),
          const ToolParam(
              name: 'days_back',
              type: ToolParamType.integer,
              description: 'Only the last N days (1-365).',
              minimum: 1,
              maximum: 365),
          const ToolParam(
              name: 'limit', type: ToolParamType.integer, description: 'Max results (1-20).', minimum: 1, maximum: 20),
        ],
        permission: ToolPermission.readTransactions,
      );

  @override
  TransactionQuery parse(Map<String, Object?> args) {
    rejectUnknown(args);
    final amount = optInt(args, 'amount', min: 1, max: 1000000000);
    final daysBack = optInt(args, 'days_back', min: 1, max: 365);
    final onDate = optString(args, 'on_date', maxLength: 10);
    DateTime? from, to;
    if (onDate != null) {
      final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(onDate);
      if (m == null) throw const ToolArgumentException(FailureCode.validation, 'on_date must be YYYY-MM-DD');
      final (y, mo, d) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
      final day = DateTime(y, mo, d);
      // DateTime silently rolls over (2026-13-45 → 2027-02-14); reject that.
      if (day.year != y || day.month != mo || day.day != d) {
        throw const ToolArgumentException(FailureCode.validation, 'on_date is not a real date');
      }
      from = day;
      to = DateTime(y, mo, d + 1);
    } else if (daysBack != null) {
      final now = _clock.now();
      from = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysBack - 1));
    }
    return TransactionQuery(
      text: optString(args, 'counterparty', maxLength: 60),
      direction: optEnum(args, 'direction', TransactionDirection.values),
      category: optEnum(args, 'category', TransactionCategory.values),
      amount: amount == null ? null : Money.bif(amount),
      from: from,
      to: to,
      limit: optInt(args, 'limit', min: 1, max: 20) ?? 10,
    );
  }

  @override
  Future<Result<Fresh<List<BankTransaction>>>> execute(TransactionQuery q, ToolContext c) => _search(q);

  @override
  Map<String, Object?> toModelPayload(Fresh<List<BankTransaction>> output) =>
      {..._fresh(output), 'count': output.data.length, 'transactions': output.data.map(_tx).toList()};

  @override
  AgentCard toCard(Fresh<List<BankTransaction>> output) => TransactionsCard(output);
}

// ---------------------------------------------------------------------------

final class GetTransactionDetailsTool extends AgentTool<String, BankTransaction> {
  const GetTransactionDetailsTool(this._details);
  final GetTransactionDetails _details;

  @override
  ToolSpec get spec => const ToolSpec(
        name: 'get_transaction_details',
        description: 'Returns one transaction by its transaction_id (from a previous tool result).',
        params: [
          ToolParam(name: 'transaction_id', type: ToolParamType.string, description: 'ID from a tool result.', required: true),
        ],
        permission: ToolPermission.readTransactions,
      );

  @override
  String parse(Map<String, Object?> args) {
    rejectUnknown(args);
    final id = reqString(args, 'transaction_id', maxLength: 64);
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      throw const ToolArgumentException(FailureCode.validation, 'invalid transaction_id');
    }
    return id;
  }

  @override
  Future<Result<BankTransaction>> execute(String id, ToolContext c) => _details(id);

  @override
  Map<String, Object?> toModelPayload(BankTransaction output) => {'transaction': _tx(output)};

  @override
  AgentCard toCard(BankTransaction output) => TransactionsCard(Fresh.live([output], output.timestamp));
}

// ---------------------------------------------------------------------------

final class ExplainTransactionTool extends AgentTool<String?, TransactionExplanation> {
  const ExplainTransactionTool(this._explain);
  final ExplainTransaction _explain;

  @override
  ToolSpec get spec => const ToolSpec(
        name: 'explain_transaction',
        description: 'Computes verifiable facts about a transaction (recurring?, fee, share of monthly category '
            'spending). Omit transaction_id for the most recent transaction.',
        params: [
          ToolParam(name: 'transaction_id', type: ToolParamType.string, description: 'Optional transaction ID.'),
        ],
        permission: ToolPermission.readTransactions,
      );

  @override
  String? parse(Map<String, Object?> args) {
    rejectUnknown(args);
    final id = optString(args, 'transaction_id', maxLength: 64);
    if (id != null && !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) {
      throw const ToolArgumentException(FailureCode.validation, 'invalid transaction_id');
    }
    return id;
  }

  @override
  Future<Result<TransactionExplanation>> execute(String? id, ToolContext c) => _explain(id: id);

  @override
  Map<String, Object?> toModelPayload(TransactionExplanation output) => {
        'transaction': _tx(output.transaction),
        'is_recurring': output.isRecurring,
        'similar_transactions_count': output.similarCount,
        'share_of_month_category_spending_percent': output.categoryShareOfMonthPercent,
        if (output.fee != null) 'fee': _money(output.fee!),
      };

  @override
  AgentCard toCard(TransactionExplanation output) => TransactionDetailCard(output);
}

// ---------------------------------------------------------------------------

final class SpendingInput {
  const SpendingInput(this.category, this.monthOffset);
  final TransactionCategory? category;
  final int monthOffset;
}

final class CalculateMonthlySpendingTool extends AgentTool<SpendingInput, Fresh<SpendingSummary>> {
  const CalculateMonthlySpendingTool(this._calc, this._clock);
  final CalculateMonthlySpending _calc;
  final Clock _clock;

  @override
  ToolSpec get spec => ToolSpec(
        name: 'calculate_monthly_spending',
        description: 'Deterministically totals spending for a month, by category, with comparison to the previous '
            'month. Use this for any spending question; never compute totals yourself.',
        params: [
          ToolParam(
              name: 'category',
              type: ToolParamType.enumeration,
              description: 'Optional category filter.',
              enumValues: TransactionCategory.values.map((e) => e.name).toList()),
          const ToolParam(
              name: 'month_offset',
              type: ToolParamType.integer,
              description: '0 = this month, 1 = last month (0-11).',
              minimum: 0,
              maximum: 11),
        ],
        permission: ToolPermission.readTransactions,
      );

  @override
  SpendingInput parse(Map<String, Object?> args) {
    rejectUnknown(args);
    return SpendingInput(optEnum(args, 'category', TransactionCategory.values),
        optInt(args, 'month_offset', min: 0, max: 11) ?? 0);
  }

  @override
  Future<Result<Fresh<SpendingSummary>>> execute(SpendingInput i, ToolContext c) {
    final now = _clock.now();
    return _calc(month: DateTime(now.year, now.month - i.monthOffset), category: i.category);
  }

  @override
  Map<String, Object?> toModelPayload(Fresh<SpendingSummary> output) {
    final s = output.data;
    return {
      ..._fresh(output),
      'month': '${s.periodStart.year}-${s.periodStart.month.toString().padLeft(2, '0')}',
      'total_spent': _money(s.totalSpent),
      'total_received': _money(s.totalReceived),
      'previous_month_spent': _money(s.previousPeriodSpent),
      'change_percent_vs_previous': s.changePercent,
      'by_category': [
        for (final c in s.byCategory) {'category': c.category.name, ..._money(c.total), 'count': c.count},
      ],
    };
  }

  @override
  AgentCard toCard(Fresh<SpendingSummary> output) => SpendingCard(output);
}

// ---------------------------------------------------------------------------

final class ListBeneficiariesTool extends AgentTool<NoInput, List<Beneficiary>> {
  const ListBeneficiariesTool(this._list);
  final ListBeneficiaries _list;

  @override
  ToolSpec get spec => const ToolSpec(
        name: 'list_beneficiaries',
        description: "Lists the user's saved transfer recipients (names only).",
        params: [],
        permission: ToolPermission.readBeneficiaries,
      );

  @override
  NoInput parse(Map<String, Object?> args) {
    rejectUnknown(args);
    return const NoInput();
  }

  @override
  Future<Result<List<Beneficiary>>> execute(NoInput i, ToolContext c) => _list();

  @override
  Map<String, Object?> toModelPayload(List<Beneficiary> output) =>
      {'beneficiaries': [for (final b in output) {'name': b.name, 'institution': b.institution}]};

  @override
  AgentCard toCard(List<Beneficiary> output) => BeneficiariesCard(output);
}

// ---------------------------------------------------------------------------

final class PrepareTransferInput {
  const PrepareTransferInput(this.recipientName, this.amount, this.note);
  final String recipientName;
  final Money amount;
  final String? note;
}

/// Output of [PrepareTransferTool]: the outcome plus the (validated) input
/// needed to render a recipient-choice card.
final class PrepareTransferResult {
  const PrepareTransferResult(this.outcome, this.input);
  final PrepareTransferOutcome outcome;
  final PrepareTransferInput input;
}

/// Creates a transfer DRAFT only. Execution requires the user to
/// authenticate on the device and press "Send" in the confirmation screen.
final class PrepareTransferTool extends AgentTool<PrepareTransferInput, PrepareTransferResult> {
  const PrepareTransferTool(this._prepare);
  final PrepareTransfer _prepare;

  @override
  ToolSpec get spec => const ToolSpec(
        name: 'prepare_transfer',
        description: 'Prepares (does NOT send) a transfer to a SAVED beneficiary. The app then asks the user to '
            'authenticate and confirm on screen. Never claim money was sent after calling this.',
        params: [
          ToolParam(
              name: 'recipient_name',
              type: ToolParamType.string,
              description: 'Name of a saved beneficiary as said by the user.',
              required: true),
          ToolParam(
              name: 'amount',
              type: ToolParamType.integer,
              description: 'Whole amount in BIF, exactly as stated by the user.',
              required: true,
              minimum: 1),
          ToolParam(name: 'note', type: ToolParamType.string, description: 'Optional short note.'),
        ],
        permission: ToolPermission.prepareTransfer,
      );

  @override
  PrepareTransferInput parse(Map<String, Object?> args) {
    rejectUnknown(args);
    final name = reqString(args, 'recipient_name', maxLength: 60);
    final amount = optInt(args, 'amount', min: 1, max: 1000000000) ??
        (throw const ToolArgumentException(FailureCode.invalidAmount, 'amount is required'));
    return PrepareTransferInput(name, Money.bif(amount), optString(args, 'note', maxLength: 140));
  }

  @override
  Future<Result<PrepareTransferResult>> execute(PrepareTransferInput i, ToolContext c) async {
    final r = await _prepare(beneficiaryName: i.recipientName, amount: i.amount, note: i.note);
    if (r case Ok(value: TransferPrepared(:final draft))) c.drafts.put(draft);
    return r.map((o) => PrepareTransferResult(o, i));
  }

  @override
  Map<String, Object?> toModelPayload(PrepareTransferResult output) => switch (output.outcome) {
        TransferPrepared(:final draft) => {
            'draft_id': draft.id,
            'state': 'draft_created_not_sent',
            'next_step': 'user_must_authenticate_and_confirm_on_screen',
            'recipient': draft.beneficiary.name,
            ..._money(draft.amount),
            'fee': _money(draft.fee),
            'balance_after': _money(draft.balanceAfter),
          },
        TransferNeedsRecipientChoice(:final resolution) => {
            'state': 'recipient_ambiguous',
            'candidates': resolution.candidates.map((b) => b.name).toList(),
          },
      };

  @override
  AgentCard toCard(PrepareTransferResult output) => switch (output.outcome) {
        TransferPrepared(:final draft) => TransferDraftCard(draft),
        TransferNeedsRecipientChoice(:final resolution) => RecipientChoiceCard(
            spokenName: output.input.recipientName, candidates: resolution.candidates, amount: output.input.amount),
      };
}

// ---------------------------------------------------------------------------

/// Re-surfaces the confirmation UI for a draft created in this session.
/// It does NOT execute anything: submission is only possible from the
/// transfer confirmation screen after device authentication.
final class ConfirmTransferTool extends AgentTool<String, TransferDraft> {
  const ConfirmTransferTool();

  @override
  ToolSpec get spec => const ToolSpec(
        name: 'confirm_transfer',
        description: 'Asks the user to review and confirm a prepared draft on screen. Does NOT send money; the user '
            'must authenticate on the device and press Send.',
        params: [
          ToolParam(name: 'draft_id', type: ToolParamType.string, description: 'draft_id from prepare_transfer.', required: true),
        ],
        permission: ToolPermission.prepareTransfer,
      );

  @override
  String parse(Map<String, Object?> args) {
    rejectUnknown(args);
    return reqString(args, 'draft_id', maxLength: 64);
  }

  @override
  Future<Result<TransferDraft>> execute(String draftId, ToolContext c) async {
    final d = c.drafts.get(draftId);
    return d == null ? const Err(NotFoundFailure('draft not created in this session')) : Ok(d);
  }

  @override
  Map<String, Object?> toModelPayload(TransferDraft output) =>
      {'draft_id': output.id, 'state': 'awaiting_user_authentication_and_confirmation', 'sent': false};

  @override
  AgentCard toCard(TransferDraft output) => TransferDraftCard(output);
}

// ---------------------------------------------------------------------------

final class NotificationsInput {
  const NotificationsInput({required this.onlyUnread, required this.limit, required this.receivedToday});
  final bool onlyUnread;
  final int limit;
  final bool receivedToday;
}

final class GetNotificationsTool extends AgentTool<NotificationsInput, Fresh<List<BankNotification>>> {
  const GetNotificationsTool(this._get, this._clock);
  final GetNotifications _get;
  final Clock _clock;

  @override
  ToolSpec get spec => const ToolSpec(
        name: 'get_notifications',
        description: 'Returns banking notifications (payments received, transfers sent, security, reminders).',
        params: [
          ToolParam(
              name: 'filter',
              type: ToolParamType.enumeration,
              description: 'all, unread, or received_today (payments received today).',
              enumValues: ['all', 'unread', 'received_today']),
          ToolParam(name: 'limit', type: ToolParamType.integer, description: '1-10, default 3.', minimum: 1, maximum: 10),
        ],
        permission: ToolPermission.readNotifications,
      );

  @override
  NotificationsInput parse(Map<String, Object?> args) {
    rejectUnknown(args);
    final f = optString(args, 'filter', maxLength: 20) ?? 'all';
    if (!const ['all', 'unread', 'received_today'].contains(f)) {
      throw const ToolArgumentException(FailureCode.validation, 'invalid filter');
    }
    return NotificationsInput(
      onlyUnread: f == 'unread',
      receivedToday: f == 'received_today',
      limit: optInt(args, 'limit', min: 1, max: 10) ?? 3,
    );
  }

  @override
  Future<Result<Fresh<List<BankNotification>>>> execute(NotificationsInput i, ToolContext c) async {
    final r = await _get();
    final now = _clock.now();
    final today = DateTime(now.year, now.month, now.day);
    return r.map((f) => f.map((list) => list
        .where((n) => !i.onlyUnread || !n.read)
        .where((n) => !i.receivedToday || (n.kind == NotificationKind.paymentReceived && !n.timestamp.isBefore(today)))
        .take(i.limit)
        .toList()));
  }

  @override
  Map<String, Object?> toModelPayload(Fresh<List<BankNotification>> output) => {
        ..._fresh(output),
        'notifications': [
          for (final n in output.data)
            {
              'kind': n.kind.name,
              'date': n.timestamp.toIso8601String(),
              if (n.amount != null) ..._money(n.amount!),
              if (n.counterparty != null) 'counterparty_untrusted': n.counterparty,
              if (n.detail != null) 'detail_untrusted': n.detail,
              'read': n.read,
            },
        ],
      };

  @override
  AgentCard toCard(Fresh<List<BankNotification>> output) => NotificationsCard(output);
}
