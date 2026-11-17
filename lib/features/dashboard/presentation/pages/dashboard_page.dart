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
          toolbarHeight: 76,
          title: Row(children: [
            InitialsAvatar(name.isEmpty ? '?' : name, size: 44),
            const SizedBox(width: 12),
            Flexible(
              child: Semantics(
                header: true,
                child: Text(l.greetingName(name),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
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
                  padding: const EdgeInsets.only(top: 4, bottom: 128),
                  children: [
                    const SizedBox(height: 8),
                    if (acc != null)
                      BalanceCard(account: acc, fresh: state.accounts!, onTap: () => context.push(Routes.accounts)),
                    const SizedBox(height: 16),
                    _QuickActions(simplified: simplified),
                    SectionHeader(l.recentActivity, action: l.seeAll, onAction: () => context.go(Routes.activity)),
                    if (state.recent == null || state.recent!.data.isEmpty)
                      EmptyView(message: l.noTransactionsYet)
                    else
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Column(children: [
                            for (final (i, t) in state.recent!.data.take(simplified ? 3 : 4).indexed) ...[
                              if (i > 0) const Divider(indent: 72, endIndent: 8),
                              TransactionTile(transaction: t, onTap: () => context.push(Routes.transaction(t.id))),
                            ],
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
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
      label: '${context.l10n.notificationsTooltip}. ${context.l10n.unreadNotifications(unread)}',
      button: true,
      excludeSemantics: true,
      child: IconButton(
        onPressed: () => context.push(Routes.notifications),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: const Icon(Icons.notifications_none_rounded, size: 28),
        ),
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
    void open(String route) => route == Routes.activity ? context.go(route) : context.push(route);
    // Simplified mode or enlarged text: big, full-width rows, so labels are
    // never squeezed into narrow columns or broken mid-word.
    final largeText = MediaQuery.textScalerOf(context).scale(10) / 10 > 1.3;
    if (simplified || largeText) {
      return Column(children: [
        for (final (icon, label, route) in actions) ...[
          _BigAction(icon: icon, label: label, onTap: () => open(route)),
          const SizedBox(height: 12),
        ],
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final (icon, label, route) in actions)
            Expanded(child: _ActionButton(icon: icon, label: label, onTap: () => open(route))),
        ]),
      ),
    );
  }
}

/// Round icon with its label underneath; the whole column is the target.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                IconBubble(icon, size: 56),
                const SizedBox(height: 10),
                Text(label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 15.5, height: 1.2)),
              ]),
            ),
          ),
        ),
      );
}

class _BigAction extends StatelessWidget {
  const _BigAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                IconBubble(icon, size: 64),
                const SizedBox(width: 18),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleLarge)),
                const Icon(Icons.chevron_right_rounded, size: 32),
              ]),
            ),
          ),
        ),
      );
}

/// The voice entry point: always reachable, centred above the navigation.
class _TalkButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = StatusColors.of(context);
    final hc = st.isHighContrast;
    return Semantics(
      button: true,
      label: l.talkToSauti,
      hint: l.talkToSautiHint,
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: hc ? null : const [BoxShadow(color: Color(0x400A1D35), blurRadius: 20, offset: Offset(0, 8), spreadRadius: -4)],
        ),
        child: Material(
          color: hc ? AppColors.hcAccent : AppColors.navy,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => context.go(Routes.assistant),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 26, 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: hc ? Colors.black : st.accent, shape: BoxShape.circle),
                  child: Icon(Icons.mic_rounded, size: 26, color: hc ? AppColors.hcAccent : AppColors.navyDeep),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(l.talkToSauti,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: hc ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w800,
                          )),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
