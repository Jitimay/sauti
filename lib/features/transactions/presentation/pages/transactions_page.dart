import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../banking/domain/entities/bank_transaction.dart';
import '../bloc/transaction_bloc.dart';
import '../widgets/transaction_tile.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => TransactionBloc(sl())..add(const TransactionsLoadRequested()),
        child: const _TransactionsView(),
      );
}

class _TransactionsView extends StatelessWidget {
  const _TransactionsView();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Semantics(header: true, child: Text(l.transactionsTitle))),
      body: ResponsiveBody(
        child: Column(children: [
          TextField(
            onChanged: (v) => context.read<TransactionBloc>().add(
                TransactionFilterChanged(direction: context.read<TransactionBloc>().state.direction, text: v)),
            decoration: InputDecoration(labelText: l.searchTransactions, prefixIcon: const Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: 12),
          BlocBuilder<TransactionBloc, TransactionState>(
            buildWhen: (a, b) => a.direction != b.direction,
            builder: (context, s) => SegmentedButton<TransactionDirection?>(
              showSelectedIcon: true,
              segments: [
                ButtonSegment(value: null, label: Text(l.filterAll)),
                ButtonSegment(value: TransactionDirection.incoming, label: Text(l.filterIncoming)),
                ButtonSegment(value: TransactionDirection.outgoing, label: Text(l.filterOutgoing)),
              ],
              selected: {s.direction},
              onSelectionChanged: (v) => context.read<TransactionBloc>().add(TransactionFilterChanged(direction: v.first)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(builder: (context, s) {
              return switch (s.status) {
                ViewStatus.initial || ViewStatus.loading when s.transactions == null => const LoadingView(),
                ViewStatus.failure => ErrorView(
                    failure: s.failure!,
                    onRetry: () => context.read<TransactionBloc>().add(const TransactionsLoadRequested())),
                ViewStatus.empty => EmptyView(message: l.noTransactionsYet, icon: Icons.search_off_rounded),
                _ => ListView(children: [
                    Align(alignment: Alignment.centerLeft, child: FreshnessBadge(s.transactions!)),
                    const SizedBox(height: 4),
                    for (final t in s.transactions!.data)
                      TransactionTile(transaction: t, onTap: () => context.push(Routes.transaction(t.id))),
                  ]),
              };
            }),
          ),
        ]),
      ),
    );
  }
}
