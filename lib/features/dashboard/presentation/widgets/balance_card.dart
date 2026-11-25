import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/data_freshness.dart';

/// Shows the available balance and when the underlying data was last synced.
class BalanceCard extends StatefulWidget {
  const BalanceCard({
    super.key,
    required this.account,
    required this.fresh,
    this.onTap,
  });

  final Account account;
  final Fresh<Object?> fresh;
  final VoidCallback? onTap;

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = StatusColors.of(context);
    final highContrast = status.isHighContrast;
    final text = Theme.of(context).textTheme;
    final account = widget.account;
    final toggleLabel = _hidden ? l.showBalance : l.hideBalance;
    final freshness = widget.fresh.isCached
        ? l.cachedAt(hhmm(widget.fresh.asOf))
        : l.liveData;
    final balanceLabel = [
      if (!_hidden)
        '${l.availableBalance}: ${MoneyFormatter.spoken(account.availableBalance, locale: context.langCode)}.',
      '${account.name} ${account.maskedNumber}.',
      freshness,
    ].join(' ');

    final supporting = highContrast ? Colors.white : const Color(0xFFDCE7FF);
    final rule = highContrast ? status.line : const Color(0xFF526991);
    final radius = BorderRadius.circular(Radii.xl);

    return Material(
      color: highContrast ? Colors.black : const Color(0xFF152953),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: highContrast
            ? BorderSide(color: status.accent, width: 2)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: highContrast
            ? null
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF132344), Color(0xFF204686)],
                ),
              ),
        child: CustomPaint(
          painter: highContrast ? null : const _BalanceRings(),
          child: InkWell(
            onTap: widget.onTap,
            excludeFromSemantics: true,
            borderRadius: radius,
            splashColor: Colors.white.withValues(alpha: 0.12),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            focusColor: Colors.white.withValues(alpha: 0.15),
            hoverColor: Colors.white.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ExcludeSemantics(
                          child: Text(
                            l.availableBalance,
                            style: text.bodyMedium?.copyWith(
                              color: supporting,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Semantics(
                        container: true,
                        button: true,
                        label: toggleLabel,
                        excludeSemantics: true,
                        onTap: _toggleVisibility,
                        child: IconButton(
                          tooltip: toggleLabel,
                          icon: Icon(
                            _hidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          style: IconButton.styleFrom(
                            foregroundColor: highContrast
                                ? status.accent
                                : Colors.white,
                            backgroundColor: highContrast
                                ? Colors.black
                                : const Color(0xFF294674),
                            side: BorderSide(
                              color: highContrast ? status.accent : rule,
                            ),
                          ),
                          onPressed: _toggleVisibility,
                        ),
                      ),
                    ],
                  ),
                  Semantics(
                    container: true,
                    button: widget.onTap != null,
                    label: balanceLabel,
                    excludeSemantics: true,
                    onTap: widget.onTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hidden
                              ? '••••••'
                              : context.money(account.availableBalance),
                          style: text.displaySmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FreshnessBadge(widget.fresh, onDark: true),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: rule),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Icon(
                              Icons.credit_card_rounded,
                              size: 18,
                              color: supporting,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${account.name} · ${account.maskedNumber}',
                                style: text.bodySmall?.copyWith(
                                  color: supporting,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.onTap != null)
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: supporting,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleVisibility() => setState(() => _hidden = !_hidden);
}

class _BalanceRings extends CustomPainter {
  const _BalanceRings();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width + 12, 10);
    final paint = Paint()
      ..color = const Color(0x2475A8FF)
      ..style = PaintingStyle.stroke;
    for (final radius in [52.0, 82.0, 114.0, 148.0]) {
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BalanceRings oldDelegate) => false;
}
