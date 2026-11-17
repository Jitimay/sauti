import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
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
            padding: EdgeInsets.symmetric(vertical: dense ? 8 : 12, horizontal: 8),
            child: Row(children: [
              IconBubble(
                t.isIncoming ? Icons.south_west_rounded : t.category.icon,
                size: dense ? 44 : 48,
                color: t.isIncoming ? s.success : Theme.of(context).colorScheme.onSurface,
                background: t.isIncoming ? s.successBg : s.sunken,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  LayoutBuilder(builder: (context, c) {
                    final name = Text(t.counterparty,
                        style: Theme.of(context).textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis);
                    final value = Text(amount,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: t.isIncoming ? s.success : null,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ));
                    // Narrow (cards in chat, large text): amount under the name.
                    final scale = MediaQuery.textScalerOf(context).scale(1);
                    if (c.maxWidth < 230 * scale) {
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        name,
                        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
                      ]);
                    }
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: name),
                      const SizedBox(width: 12),
                      value,
                    ]);
                  }),
                  const SizedBox(height: 2),
                  Text('${t.isIncoming ? l.received : t.category.label(l)} · $date',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: s.muted)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
