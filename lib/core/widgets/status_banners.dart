import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../features/banking/domain/entities/data_freshness.dart';
import '../l10n/l10n_ext.dart';
import '../network/connectivity_cubit.dart';

/// Always-visible strip that makes simulated data impossible to mistake for
/// real banking. Rendered above every route in DEMO mode.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final hc = Theme.of(context).colorScheme.brightness == Brightness.dark;
    return Semantics(
      container: true,
      label: context.l10n.demoBanner,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        color: hc ? Colors.black : AppColors.amber,
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 4, bottom: 4, left: 16, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined, size: 18, color: hc ? status.accent : Colors.black),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.l10n.demoBanner,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: hc ? status.accent : Colors.black,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when offline. Uses icon + text (never colour alone).
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityCubit>().state;
    final s = StatusColors.of(context);
    final banner = online
        ? const SizedBox(width: double.infinity)
        : Semantics(
            liveRegion: true,
            child: Container(
              width: double.infinity,
              color: s.warningBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Icon(Icons.cloud_off_rounded, color: s.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(context.l10n.offlineBanner, style: TextStyle(color: s.warning, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          );
    // Reduced motion: no size animation at all.
    if (MediaQuery.disableAnimationsOf(context)) return banner;
    return AnimatedSize(duration: const Duration(milliseconds: 200), child: banner);
  }
}

/// Labels data as live or cached (with time).
class FreshnessBadge extends StatelessWidget {
  const FreshnessBadge(this.fresh, {super.key, this.onDark = false});
  final Fresh<Object?> fresh;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final s = StatusColors.of(context);
    final cached = fresh.isCached;
    final label = cached ? context.l10n.cachedAt(hhmm(fresh.asOf)) : context.l10n.liveData;
    final fg = onDark ? Colors.white : (cached ? s.warning : s.success);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: fg.withValues(alpha: onDark ? 0.6 : 1)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(cached ? Icons.history_rounded : Icons.circle, size: cached ? 16 : 9, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
