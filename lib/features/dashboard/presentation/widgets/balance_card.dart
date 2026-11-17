import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/data_freshness.dart';

/// The hero: available balance, large and calm, on deep navy with the Sauti
/// "sound rings" drawn faintly in the corner.
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.account, required this.fresh, this.onTap});
  final Account account;
  final Fresh<Object?> fresh;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = StatusColors.of(context);
    final hc = st.isHighContrast;
    final text = Theme.of(context).textTheme;
    final spoken = MoneyFormatter.spoken(account.availableBalance, locale: context.langCode);
    final soft = Colors.white.withValues(alpha: 0.78);
    return Semantics(
      container: true,
      button: onTap != null,
      label: '${l.availableBalance}: $spoken. ${account.name} ${account.maskedNumber}. '
          '${fresh.isCached ? l.cachedAt(hhmm(fresh.asOf)) : l.liveData}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Radii.xl),
          color: hc ? Colors.black : null,
          gradient: hc
              ? null
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.navyLight, AppColors.navy, AppColors.navyDeep],
                  stops: [0, 0.55, 1],
                ),
          border: hc ? Border.all(color: st.accent, width: 2) : null,
          boxShadow: hc
              ? null
              : const [BoxShadow(color: Color(0x290F2A4A), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -6)],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Radii.xl),
            child: Stack(children: [
              if (!hc)
                Positioned(
                  right: -84,
                  top: -84,
                  child: CustomPaint(size: const Size(220, 220), painter: _RingsPainter(accent: st.accent)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l.availableBalance, style: text.titleSmall?.copyWith(color: soft)),
                      FreshnessBadge(fresh, onDark: true),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.money(account.availableBalance),
                      style: text.displayMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [
                    Icon(Icons.account_balance_rounded, size: 18, color: soft),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${account.name} · ${account.maskedNumber}',
                          style: text.bodyMedium?.copyWith(color: soft, fontWeight: FontWeight.w600)),
                    ),
                    if (onTap != null) Icon(Icons.chevron_right_rounded, color: soft),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.accent});
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    for (final (f, a) in [(0.95, 0.05), (0.68, 0.07), (0.42, 0.09)]) {
      canvas.drawCircle(c, r * f, ring..color = Colors.white.withValues(alpha: a));
    }
    canvas.drawCircle(c, r * 0.16, Paint()..color = accent.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.accent != accent;
}
