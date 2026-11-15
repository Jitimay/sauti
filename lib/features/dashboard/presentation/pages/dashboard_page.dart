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
import '../../../transactions/presentation/widgets/transaction_tile.dart';
import '../bloc/dashboard_bloc.dart';
import '../widgets/balance_card.dart';

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
    final l = context.l10n;
    final name = context.select<AuthBloc, String>((b) => b.state.user?.firstName ?? '');
    final simplified = context.simplifiedMode;
    return BlocListener<ConnectivityCubit, bool>(
      // Coming back online refreshes live data automatically.
      listenWhen: (a, b) => !a && b,
      listener: (context, _) => context.read<DashboardBloc>().add(const DashboardLoadRequested(silent: true)),
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(header: true, child: Text(l.greetingName(name))),
          actions: [_NotificationsButton()],
        ),
        floatingActionButton: _TalkButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            if (state.status == ViewStatus.loading && state.accounts == null) return const LoadingView();
            if (state.status == ViewStatus.failure && state.accounts == null) {
              return ErrorView(
                failure: state.failure!,
                onRetry: () => context.read<DashboardBloc>().add(const DashboardLoadRequested()),
              );
            }
            final acc = state.primary;
            return RefreshIndicator(
              onRefresh: () async => context.read<DashboardBloc>().add(const DashboardLoadRequested(silent: true)),
              child: ResponsiveBody(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    const SizedBox(height: 8),
                    if (acc != null)
                      BalanceCard(account: acc, fresh: state.accounts!, onTap: () => context.push(Routes.accounts)),
                    SectionHeader(l.quickActions),
                    _QuickActions(simplified: simplified),
                    SectionHeader(l.recentActivity, action: l.seeAll, onAction: () => context.go(Routes.activity)),
                    if (state.recent == null || state.recent!.data.isEmpty)
                      EmptyView(message: l.noTransactionsYet)
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Column(children: [
                            for (final t in state.recent!.data.take(simplified ? 3 : 4))
                              TransactionTile(transaction: t, onTap: () => context.push(Routes.transaction(t.id))),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final unread = context.select<DashboardBloc, int>((b) => b.state.unreadNotifications);
    return Semantics(
      label: '${context.l10n.notificationsTooltip}. ${context.l10n.unreadNotifications(unread)}',
      button: true,
      excludeSemantics: true,
      child: IconButton(
        onPressed: () => context.push(Routes.notifications),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: const Icon(Icons.notifications_outlined, size: 28),
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
      (Icons.north_east_rounded, l.actionSend, Routes.transfer),
      (Icons.receipt_long_rounded, l.actionHistory, Routes.activity),
      if (!simplified) (Icons.insights_rounded, l.actionInsights, Routes.insights),
      if (!simplified) (Icons.account_balance_rounded, l.actionAccounts, Routes.accounts),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = simplified ? 2 : (c.maxWidth > 520 ? 4 : 2);
      final w = (c.maxWidth - (cols - 1) * 12) / cols;
      return Wrap(spacing: 12, runSpacing: 12, children: [
        for (final (icon, label, route) in actions)
          SizedBox(
            width: w,
            child: _ActionTile(
              icon: icon,
              label: label,
              big: simplified,
              onTap: () => route == Routes.activity ? context.go(route) : context.push(route),
            ),
          ),
      ]);
    });
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.big = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: big ? 120 : 96),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: big ? 36 : 28, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TalkButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hc = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Semantics(
      button: true,
      label: l.talkToSauti,
      hint: l.talkToSautiHint,
      excludeSemantics: true,
      child: SizedBox(
        height: 64,
        child: FloatingActionButton.extended(
          heroTag: 'talk',
          backgroundColor: hc ? AppColors.hcAccent : AppColors.navy,
          foregroundColor: hc ? Colors.black : Colors.white,
          onPressed: () => context.go(Routes.assistant),
          icon: Icon(Icons.mic_rounded, size: 28, color: hc ? Colors.black : AppColors.amber),
          label: Text(l.talkToSauti, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: hc ? Colors.black : Colors.white)),
        ),
      ),
    );
  }
}
