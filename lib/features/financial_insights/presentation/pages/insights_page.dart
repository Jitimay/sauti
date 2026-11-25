import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/utils/view_status.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../banking/domain/services/spending_analyzer.dart';
import '../bloc/insights_bloc.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => InsightsBloc(sl(), sl())..add(const InsightsRequested()),
    child: Scaffold(
      appBar: AppBar(title: Text(context.l10n.insightsTitle)),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: ResponsiveBody(child: _InsightsBody())),
        ],
      ),
    ),
  );
}

class _InsightsBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocBuilder<InsightsBloc, InsightsState>(
      builder: (context, s) {
        final selector = SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              label: Text(l.thisMonth, textAlign: TextAlign.center),
            ),
            ButtonSegment(
              value: 1,
              label: Text(l.lastMonth, textAlign: TextAlign.center),
            ),
          ],
          selected: {s.monthOffset},
          onSelectionChanged: (v) => context.read<InsightsBloc>().add(
            InsightsRequested(monthOffset: v.first),
          ),
        );
        final Widget body = switch (s.status) {
          ViewStatus.failure => ErrorView(
            failure: s.failure!,
            onRetry: () => context.read<InsightsBloc>().add(
              InsightsRequested(monthOffset: s.monthOffset),
            ),
          ),
          ViewStatus.empty => EmptyView(message: l.noSpending),
          ViewStatus.success => _Summary(
            summary: s.summary!.data,
            badge: FreshnessBadge(s.summary!),
          ),
          _ => const LoadingView(),
        };
        return ListView(
          children: [
            const SizedBox(height: 12),
            selector,
            const SizedBox(height: 16),
            body,
          ],
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary, required this.badge});
  final SpendingSummary summary;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = StatusColors.of(context);
    final change = summary.changePercent;
    final total = summary.totalSpent.minorUnits;
    final scheme = Theme.of(context).colorScheme;
    final palette = [scheme.primary, scheme.tertiary, scheme.secondary];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        badge,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: l.totalSpent,
                value: context.money(summary.totalSpent),
                icon: Icons.north_east_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Stat(
                label: l.totalReceived,
                value: context.money(summary.totalReceived),
                icon: Icons.south_west_rounded,
                color: st.success,
              ),
            ),
          ],
        ),
        if (change != null && change != 0) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Icon(
                  change > 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: change > 0 ? st.warning : st.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    change > 0
                        ? l.spentMoreThanLast(change)
                        : l.spentLessThanLast(-change),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (total > 0) ...[
          SectionHeader(l.byCategory),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: 120,
                      child: CustomPaint(
                        painter: _SpendingDonut(
                          shares: [
                            for (final category in summary.byCategory)
                              category.total.minorUnits / total,
                          ],
                          palette: palette,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final (index, c) in summary.byCategory.indexed)
                    Semantics(
                      label: l.categoryShareSemantic(
                        c.category.label(l),
                        context.money(c.total),
                        (c.total.minorUnits * 100 / total).round(),
                      ),
                      excludeSemantics: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  c.category.icon,
                                  size: 22,
                                  color: palette[index % palette.length],
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c.category.label(l),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    context.money(c.total),
                                    textAlign: TextAlign.end,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: c.total.minorUnits / total,
                                color: palette[index % palette.length],
                                minHeight: 12,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
  final String label, value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) => Card(
    child: MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SpendingDonut extends CustomPainter {
  const _SpendingDonut({required this.shares, required this.palette});

  final List<double> shares;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 16.0;
    final arc = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    var start = -math.pi / 2;
    for (final (index, share) in shares.indexed) {
      final sweep = 2 * math.pi * share;
      paint.color = palette[index % palette.length];
      canvas.drawArc(arc, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_SpendingDonut oldDelegate) =>
      oldDelegate.shares != shares || oldDelegate.palette != palette;
}
