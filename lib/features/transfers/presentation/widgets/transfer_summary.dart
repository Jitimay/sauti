import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../banking/domain/entities/transfer.dart';

/// Read-only summary of a draft. Large type, one fact per line, and a single
/// coherent screen-reader announcement.
class TransferSummary extends StatelessWidget {
  const TransferSummary({super.key, required this.draft});
  final TransferDraft draft;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = StatusColors.of(context);
    final spokenAmount = MoneyFormatter.spoken(draft.amount, locale: context.langCode);
    Widget row(String k, String v, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 120, child: Text(k, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: st.muted))),
            Expanded(
              child: Text(v,
                  textAlign: TextAlign.end,
                  style: strong ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.titleMedium),
            ),
          ]),
        );
    return Semantics(
      container: true,
      label: '${l.confirmTo} ${draft.beneficiary.name}, ${draft.beneficiary.maskedAccount}. '
          '${l.detailAmount}: $spokenAmount. ${l.confirmBalanceAfter}: ${context.money(draft.balanceAfter)}. ${l.notSentYet}',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.confirmTo, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: st.muted)),
            const SizedBox(height: 4),
            Text(draft.beneficiary.name, style: Theme.of(context).textTheme.headlineSmall),
            Text('${draft.beneficiary.institution} · ${draft.beneficiary.maskedAccount}',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(context.money(draft.amount), style: Theme.of(context).textTheme.displaySmall),
            ),
            const Divider(height: 32),
            row(l.confirmFrom, draft.fromAccountMasked),
            row(l.confirmFee, context.money(draft.fee)),
            row(l.confirmTotal, context.money(draft.total), strong: true),
            row(l.confirmBalanceAfter, context.money(draft.balanceAfter)),
            if (draft.note != null) row(l.noteLabel, draft.note!),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.info_outline_rounded, color: st.warning),
              const SizedBox(width: 8),
              Expanded(child: Text(l.notSentYet, style: TextStyle(color: st.warning, fontWeight: FontWeight.w700))),
            ]),
          ]),
        ),
      ),
    );
  }
}
