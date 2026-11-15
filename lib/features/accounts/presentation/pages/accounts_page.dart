import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_banners.dart';
import '../bloc/account_bloc.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => AccountBloc(sl())..add(const AccountLoadRequested()),
        child: Scaffold(
          appBar: AppBar(title: Text(context.l10n.accountsTitle)),
          body: Column(children: [
            const OfflineBanner(),
            Expanded(
              child: BlocBuilder<AccountBloc, AccountState>(builder: (context, s) {
                return switch (s.status) {
                  ViewStatus.initial || ViewStatus.loading => const LoadingView(),
                  ViewStatus.failure => ErrorView(
                      failure: s.failure!, onRetry: () => context.read<AccountBloc>().add(const AccountLoadRequested())),
                  ViewStatus.empty => EmptyView(message: context.l10n.noTransactionsYet),
                  ViewStatus.success => ResponsiveBody(
                      child: ListView(children: [
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerLeft, child: FreshnessBadge(s.accounts!)),
                        const SizedBox(height: 12),
                        for (final a in s.accounts!.data) ...[
                          Card(
                            child: Semantics(
                              container: true,
                              label: '${a.type.label(context.l10n)}, ${a.name}, ${context.l10n.accountNumber(a.maskedNumber)}. '
                                  '${context.l10n.availableBalance}: ${MoneyFormatter.spoken(a.availableBalance, locale: context.langCode)}',
                              excludeSemantics: true,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Icon(a.type.name == 'savings' ? Icons.savings_rounded : Icons.account_balance_wallet_rounded),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(a.type.label(context.l10n), style: Theme.of(context).textTheme.titleMedium)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text('${a.name} · ${context.l10n.accountNumber(a.maskedNumber)}',
                                      style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 4),
                                  Text(a.institution, style: Theme.of(context).textTheme.bodySmall),
                                  const Divider(height: 28),
                                  Text(context.l10n.availableBalance, style: Theme.of(context).textTheme.bodyMedium),
                                  Text(context.money(a.availableBalance), style: Theme.of(context).textTheme.headlineSmall),
                                ]),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ]),
                    ),
                };
              }),
            ),
          ]),
        ),
      );
}
