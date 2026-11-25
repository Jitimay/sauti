import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/app.dart';
import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/network/connectivity_cubit.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../banking/domain/entities/bank_transaction.dart';
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/balance_card.dart';

/// Shows the available balance, quick actions and recent transactions.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final simplified = context.simplifiedMode;
    const reload = DashboardLoadRequested(silent: true);

    return BlocListener<ConnectivityCubit, bool>(
      listenWhen: (a, b) => !a && b,
      listener: (context, _) => context.read<DashboardBloc>().add(reload),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              if (state.status == ViewStatus.loading &&
                  state.accounts == null) {
                return const LoadingView();
              }
              if (state.status == ViewStatus.failure &&
                  state.accounts == null) {
                return ErrorView(
                  failure: state.failure!,
                  onRetry: () => context.read<DashboardBloc>().add(
                    const DashboardLoadRequested(),
                  ),
                );
              }

              final account = state.primary;
              final transactions =
                  state.recent?.data.take(simplified ? 3 : 4).toList() ??
                  const <BankTransaction>[];
              return ResponsiveBody(
                maxWidth: 1120,
                child: RefreshIndicator(
                  onRefresh: () async =>
                      context.read<DashboardBloc>().add(reload),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 14, bottom: 24),
                    children: [
                      const _DashboardHeader(),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 24.0;
                          final width = constraints.maxWidth;
                          final scale =
                              MediaQuery.textScalerOf(context).scale(16) / 16;
                          final split = !simplified && width >= 760 * scale;
                          final overviewWidth = split
                              ? (width - gap) * 0.46
                              : width;

                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              SizedBox(
                                width: overviewWidth,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (account != null) ...[
                                      BalanceCard(
                                        account: account,
                                        fresh: state.accounts!,
                                        onTap: () =>
                                            context.push(Routes.accounts),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    FilledButton.icon(
                                      onPressed: () =>
                                          context.go(Routes.assistant),
                                      icon: const Icon(Icons.mic_rounded),
                                      label: Text(
                                        context.l10n.talkToSauti,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _QuickActions(simplified: simplified),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: split
                                    ? width - gap - overviewWidth
                                    : width,
                                child: _RecentActivity(
                                  transactions: transactions,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthBloc, String>(
      (bloc) => bloc.state.user?.firstName ?? '',
    );
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = StatusColors.of(context);
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(Radii.md),
              border: status.isHighContrast
                  ? Border.all(color: status.accent)
                  : null,
            ),
            child: Text(
              name.isEmpty ? '?' : name.characters.first.toUpperCase(),
              textScaler: TextScaler.noScaling,
              style: theme.textTheme.titleLarge?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              context.l10n.greetingName(name),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const _NotificationsButton(),
      ],
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  const _NotificationsButton();

  @override
  Widget build(BuildContext context) {
    final unread = context.select<DashboardBloc, int>(
      (bloc) => bloc.state.unreadNotifications,
    );
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final status = StatusColors.of(context);
    void openNotifications() => context.push(Routes.notifications);
    return Semantics(
      label: '${l.notificationsTooltip}. ${l.unreadNotifications(unread)}',
      button: true,
      excludeSemantics: true,
      onTap: openNotifications,
      child: IconButton.outlined(
        onPressed: openNotifications,
        tooltip: l.notificationsTooltip,
        style: IconButton.styleFrom(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: status.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
        ),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread', textScaler: TextScaler.noScaling),
          child: const Icon(Icons.notifications_none_rounded),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.simplified});
  final bool simplified;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final actions = [
      (Icons.swap_horiz_rounded, l.actionSend, Routes.transfer),
      (
        Icons.account_balance_wallet_outlined,
        l.actionAccounts,
        Routes.accounts,
      ),
      (Icons.receipt_long_outlined, l.transactionsTitle, Routes.activity),
    ];

    void open(String route) =>
        route == Routes.activity ? context.go(route) : context.push(route);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.quickActions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
            final stacked = simplified || constraints.maxWidth < 300 * scale;
            const gap = 8.0;
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: [
                  for (final (icon, label, route) in actions)
                    _QuickActionCard(
                      icon: icon,
                      label: label,
                      horizontal: true,
                      onTap: () => open(route),
                    ),
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: [
                  for (final (icon, label, route) in actions)
                    Expanded(
                      child: _QuickActionCard(
                        icon: icon,
                        label: label,
                        horizontal: false,
                        onTap: () => open(route),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.horizontal,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool horizontal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final leading = ExcludeSemantics(
      child: IconBubble(icon, size: 38, iconSize: 21),
    );
    final title = Text(
      label,
      textAlign: horizontal ? TextAlign.start : TextAlign.center,
      style: theme.textTheme.labelMedium?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
    return Material(
      color: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: StatusColors.of(context).line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: horizontal
                ? Row(
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(child: title),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [leading, const SizedBox(height: 8), title],
                  ),
          ),
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.transactions});
  final List<BankTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l.recentActivity,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(Routes.activity),
                  child: Text(l.seeAll),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (transactions.isEmpty)
            EmptyView(message: l.noTransactionsYet)
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  for (final (index, transaction) in transactions.indexed) ...[
                    if (index > 0)
                      const Divider(indent: 70, endIndent: 8, height: 1),
                    TransactionTile(
                      transaction: transaction,
                      onTap: () =>
                          context.push(Routes.transaction(transaction.id)),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
