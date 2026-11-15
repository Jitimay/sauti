import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../../domain/entities/agent_card.dart';
import '../bloc/agent_bloc.dart';

/// Renders verified tool output. Numbers shown here come from the bank via
/// tools — never from model-generated text.
class AgentCardView extends StatelessWidget {
  const AgentCardView({super.key, required this.card, required this.interactive});
  final AgentCard card;

  /// Only the latest message's action buttons are active.
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return switch (card) {
      BalanceCard(:final accounts) => _Frame(
          badge: FreshnessBadge(accounts),
          child: Column(children: [
            for (final a in accounts.data)
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Expanded(child: Text('${a.name} · ${a.maskedNumber}', style: Theme.of(context).textTheme.bodyLarge)),
                    Text(context.money(a.availableBalance), style: Theme.of(context).textTheme.titleLarge),
                  ]),
                ),
              ),
          ]),
        ),
      TransactionsCard(:final transactions) => _Frame(
          badge: FreshnessBadge(transactions),
          child: Column(children: [
            for (final t in transactions.data.take(6))
              TransactionTile(transaction: t, dense: true, onTap: () => context.push(Routes.transaction(t.id))),
          ]),
        ),
      TransactionDetailCard(:final explanation) => _Frame(
          child: Column(children: [
            TransactionTile(
              transaction: explanation.transaction,
              onTap: () => context.push(Routes.transaction(explanation.transaction.id)),
            ),
            if (explanation.isRecurring) _Fact(Icons.repeat_rounded, l.recurringPayment),
            if (explanation.fee != null) _Fact(Icons.receipt_long_rounded, '${l.detailFee}: ${context.money(explanation.fee!)}'),
          ]),
        ),
      SpendingCard(:final summary) => _Frame(
          badge: FreshnessBadge(summary),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            MergeSemantics(
              child: Row(children: [
                Expanded(child: Text(l.totalSpent, style: Theme.of(context).textTheme.bodyLarge)),
                Text(context.money(summary.data.totalSpent), style: Theme.of(context).textTheme.titleLarge),
              ]),
            ),
            const Divider(height: 20),
            for (final c in summary.data.byCategory.take(4))
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    Icon(c.category.icon, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.category.label(l))),
                    Text(context.money(c.total), style: Theme.of(context).textTheme.titleMedium),
                  ]),
                ),
              ),
            TextButton(onPressed: () => context.push(Routes.insights), child: Text(l.seeAll)),
          ]),
        ),
      NotificationsCard(:final notifications) => _Frame(
          badge: FreshnessBadge(notifications),
          child: Column(children: [
            for (final n in notifications.data)
              MergeSemantics(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(n.icon),
                    const SizedBox(width: 10),
                    Expanded(child: Text(n.text(context), style: Theme.of(context).textTheme.bodyLarge)),
                  ]),
                ),
              ),
          ]),
        ),
      BeneficiariesCard(:final beneficiaries) => _Frame(
          child: Column(children: [
            for (final b in beneficiaries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(b.name.characters.first)),
                title: Text(b.name),
                subtitle: Text('${b.institution} · ${b.maskedAccount}'),
              ),
          ]),
        ),
      TransferDraftCard(:final draft) => _DraftCard(card: card as TransferDraftCard, interactive: interactive, key: ValueKey(draft.id)),
      RecipientChoiceCard(:final candidates, :final amount) => _Frame(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(header: true, child: Text(l.chooseRecipientCard, style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 8),
            for (final b in candidates)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: interactive
                      ? () => context.read<AgentBloc>().add(AgentMessageSubmitted(
                            l.sendToThisPerson(context.money(amount), b.name),
                            language: context.read<PreferencesCubit>().state.language,
                          ))
                      : null,
                  child: Text('${b.name} · ${b.maskedAccount}'),
                ),
              ),
          ]),
        ),
    };
  }
}

class _DraftCard extends StatelessWidget {
  const _DraftCard({super.key, required this.card, required this.interactive});
  final TransferDraftCard card;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final d = card.draft;
    final st = StatusColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: st.warning, width: 2),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.pending_actions_rounded, color: st.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l.draftCardTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: st.warning)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        MergeSemantics(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.beneficiary.name, style: Theme.of(context).textTheme.titleLarge),
            Text('${d.beneficiary.institution} · ${d.beneficiary.maskedAccount}', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(context.money(d.amount), style: Theme.of(context).textTheme.headlineMedium),
            Text('${l.confirmBalanceAfter}: ${context.money(d.balanceAfter)}', style: Theme.of(context).textTheme.bodyMedium),
          ]),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: interactive ? () => context.push(Routes.transferConfirm, extra: d) : null,
          icon: const Icon(Icons.fact_check_rounded),
          label: Text(l.reviewAndConfirm),
        ),
      ]),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.badge});
  final Widget child;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (badge != null) ...[badge!, const SizedBox(height: 8)],
            child,
          ]),
        ),
      );
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}
