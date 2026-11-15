import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../ai_agent/presentation/bloc/agent_bloc.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';
import '../bloc/transaction_bloc.dart';

class TransactionDetailsPage extends StatelessWidget {
  const TransactionDetailsPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => TransactionDetailsCubit(sl())..load(id),
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.transactionDetailsTitle)),
          body: BlocBuilder<TransactionDetailsCubit, TransactionDetailsState>(builder: (context, s) {
            final l = context.l10n;
            if (s.status == ViewStatus.failure) {
              return ErrorView(failure: s.failure!, onRetry: () => context.read<TransactionDetailsCubit>().load(id));
            }
            final e = s.explanation;
            if (e == null) return const LoadingView();
            final t = e.transaction;
            final st = StatusColors.of(context);
            Widget row(String k, String v) => MergeSemantics(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 130, child: Text(k, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: st.muted))),
                      Expanded(child: Text(v, style: Theme.of(context).textTheme.titleMedium)),
                    ]),
                  ),
                );
            return ResponsiveBody(
              child: ListView(children: [
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(context.money(t.signedAmount, signed: true),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: t.isIncoming ? st.success : null)),
                ),
                Text(t.isIncoming ? l.received : l.paid, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(children: [
                      row(l.detailCounterparty, t.counterparty),
                      row(l.detailDate, '${shortDate(context, t.timestamp)} ${hhmm(t.timestamp)}'),
                      row(l.detailCategory, t.category.label(l)),
                      row(l.detailStatus, t.status.label(l)),
                      if (t.fee != null) row(l.detailFee, context.money(t.fee!)),
                      if (t.reference != null) row(l.detailReference, t.reference!),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                if (e.isRecurring)
                  _Fact(icon: Icons.repeat_rounded, text: l.recurringPayment),
                if (!t.isIncoming && e.categoryShareOfMonthPercent != null)
                  _Fact(icon: Icons.pie_chart_outline_rounded, text: l.shareOfCategory(e.categoryShareOfMonthPercent!, t.category.label(l))),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.graphic_eq_rounded),
                  label: Text(l.askSautiExplain),
                  onPressed: () {
                    final lang = context.read<PreferencesCubit>().state.language;
                    // Typed request routed through the same agent + tools.
                    context.read<AgentBloc>().add(AgentMessageSubmitted('${l.askSautiExplain} #${t.id}', language: lang));
                    context.go(Routes.assistant);
                  },
                ),
                const SizedBox(height: 24),
              ]),
            );
          }),
        ),
      );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
        ]),
      );
}
