import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../banking/domain/entities/account.dart';
import '../../../banking/domain/entities/data_freshness.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.account, required this.fresh, this.onTap});
  final Account account;
  final Fresh<Object?> fresh;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hc = Theme.of(context).colorScheme.brightness == Brightness.dark;
    final bg = hc ? Colors.black : AppColors.navy;
    final spoken = MoneyFormatter.spoken(account.availableBalance, locale: context.langCode);
    return Semantics(
      container: true,
      button: onTap != null,
      label: '${l.availableBalance}: $spoken. ${account.name} ${account.maskedNumber}. '
          '${fresh.isCached ? l.cachedAt(hhmm(fresh.asOf)) : l.liveData}',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: hc ? BorderSide(color: StatusColors.of(context).accent, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(l.availableBalance,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                  FreshnessBadge(fresh, onDark: true),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.money(account.availableBalance),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Text('${account.name} · ${account.maskedNumber}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
            ]),
          ),
        ),
      ),
    );
  }
}
