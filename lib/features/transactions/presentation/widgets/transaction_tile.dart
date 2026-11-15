import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../banking/domain/entities/bank_transaction.dart';

/// One transaction row. Direction is conveyed by icon, sign AND words —
/// never by colour alone. The whole row is one screen-reader node.
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, this.onTap, this.dense = false});
  final BankTransaction transaction;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final l = context.l10n;
    final s = StatusColors.of(context);
    final amount = context.money(t.signedAmount, signed: true);
    final date = shortDate(context, t.timestamp);
    final semantic = t.isIncoming
        ? l.txSemanticIn(context.money(t.amount), t.counterparty, date)
        : l.txSemanticOut(context.money(t.amount), t.counterparty, date);
    return MergeSemantics(
      child: Semantics(
        label: semantic,
        button: onTap != null,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: dense ? 8 : 12, horizontal: 4),
            child: Row(children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: t.isIncoming ? s.successBg : Theme.of(context).colorScheme.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: t.isIncoming ? s.success : Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Icon(t.isIncoming ? Icons.south_west_rounded : t.category.icon,
                    color: t.isIncoming ? s.success : Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t.counterparty, style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('${t.isIncoming ? l.received : t.category.label(l)} · $date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: s.muted)),
                ]),
              ),
              const SizedBox(width: 8),
              Text(amount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: t.isIncoming ? s.success : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
            ]),
          ),
        ),
      ),
    );
  }
}
