import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme/app_colors.dart';
import '../../features/banking/domain/entities/data_freshness.dart';
import '../l10n/l10n_ext.dart';
import '../network/connectivity_cubit.dart';

/// Always-visible strip that makes simulated data impossible to mistake for
/// real banking. Rendered above every route in DEMO mode.
///
/// Calm rather than alarming (a dark band with an amber "DEMO" tag), so it is
/// unmistakable without competing with the content for attention.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);
    final hc = status.isHighContrast;
    final text = context.l10n.demoBanner;
    // "DEMO · simulated bank · no real money" → tag + rest.
    final split = text.indexOf('·');
    final tag = split > 0 ? text.substring(0, split).trim() : text;
    final rest = split > 0 ? text.substring(split + 1).trim() : '';
    final fg = hc ? status.accent : Colors.white;
    final badge = hc ? status.accent : AppColors.amber;
    return Semantics(
      container: true,
      label: text,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: hc ? Colors.black : AppColors.navyDeep,
          border: hc ? Border(bottom: BorderSide(color: status.accent, width: 2)) : null,
        ),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 6, bottom: 6, left: 16, right: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: badge, borderRadius: BorderRadius.circular(6)),
            child: Text(tag,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w800)),
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(rest,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg.withValues(alpha: hc ? 1 : 0.92))),
            ),
          ],
        ]),
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
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: s.warningBg,
                borderRadius: BorderRadius.circular(Radii.md),
                border: Border.all(color: s.warning.withValues(alpha: s.isHighContrast ? 1 : 0.35), width: s.isHighContrast ? 2 : 1),
              ),
              child: Row(children: [
                Icon(Icons.cloud_off_rounded, color: s.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(context.l10n.offlineBanner,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: s.warning, fontWeight: FontWeight.w700)),
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
    final Color fg;
    final Color bg;
    if (onDark && !s.isHighContrast) {
      fg = cached ? const Color(0xFFFFD49A) : const Color(0xFFB8F0C8);
      bg = Colors.white.withValues(alpha: 0.10);
    } else {
      fg = cached ? s.warning : s.success;
      bg = cached ? s.warningBg : s.successBg;
    }
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: s.isHighContrast ? Border.all(color: fg, width: 1.5) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (cached)
            Icon(Icons.history_rounded, size: 16, color: fg)
          else
            Container(width: 8, height: 8, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}
