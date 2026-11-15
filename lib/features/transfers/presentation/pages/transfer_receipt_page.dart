import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../../core/widgets/layout.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../settings/presentation/bloc/accessibility_bloc.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';
import '../../../voice/presentation/bloc/voice_bloc.dart';
import '../bloc/transfer_bloc.dart';

/// Step 11: shown ONLY when the bank returned a receipt.
class TransferReceiptPage extends StatefulWidget {
  const TransferReceiptPage({super.key});

  @override
  State<TransferReceiptPage> createState() => _TransferReceiptPageState();
}

class _TransferReceiptPageState extends State<TransferReceiptPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardLoadRequested(silent: true));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final r = context.read<TransferBloc>().state.receipt;
      if (r == null || !context.read<AccessibilityBloc>().state.voiceFeedback) return;
      context.read<VoiceBloc>().add(SpeechPlaybackStarted(
            context.l10n.receiptSpoken(MoneyFormatter.spoken(r.amount, locale: context.langCode), r.beneficiaryName, r.reference),
            language: context.read<PreferencesCubit>().state.language,
            rate: context.read<AccessibilityBloc>().state.speechRate,
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.watch<TransferBloc>().state.receipt;
    final st = StatusColors.of(context);
    if (r == null) {
      // Defensive: no receipt means no success screen.
      return Scaffold(appBar: AppBar(), body: Center(child: Text(l.failureUnexpected)));
    }
    Widget row(String k, String v) => MergeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Expanded(child: Text(k, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: st.muted))),
              Flexible(child: Text(v, textAlign: TextAlign.end, style: Theme.of(context).textTheme.titleMedium)),
            ]),
          ),
        );
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: ResponsiveBody(
            child: ListView(children: [
              const SizedBox(height: 32),
              Semantics(
                liveRegion: true,
                label: l.receiptSpoken(context.money(r.amount), r.beneficiaryName, r.reference),
                excludeSemantics: true,
                child: Column(children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(color: st.successBg, shape: BoxShape.circle, border: Border.all(color: st.success, width: 3)),
                    child: Icon(Icons.check_rounded, size: 64, color: st.success),
                  ),
                  const SizedBox(height: 20),
                  Text(l.receiptTitle, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.verified_rounded, color: st.success, size: 20),
                    const SizedBox(width: 6),
                    Text(l.receiptVerified, style: TextStyle(color: st.success, fontWeight: FontWeight.w700, fontSize: 16)),
                  ]),
                  const SizedBox(height: 20),
                  Text(context.money(r.amount), style: Theme.of(context).textTheme.displaySmall),
                  Text('${l.confirmTo} ${r.beneficiaryName}', style: Theme.of(context).textTheme.titleMedium),
                ]),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    row(l.receiptReference, r.reference),
                    row(l.receiptDate, '${shortDate(context, r.executedAt)} ${hhmm(r.executedAt)}'),
                    row(l.confirmFee, context.money(r.fee)),
                    row(l.receiptNewBalance, context.money(r.newBalance)),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go(Routes.home), child: Text(l.done)),
            ]),
          ),
        ),
      ),
    );
  }
}
