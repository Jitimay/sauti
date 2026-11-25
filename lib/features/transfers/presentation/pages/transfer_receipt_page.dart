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

/// Screen 9: Transfer Successful! (Receipt screen with festive blue gradient,
/// large green checkmark circle, translucent receipt card, and Done button).
class TransferReceiptPage extends StatefulWidget {
  const TransferReceiptPage({super.key});

  @override
  State<TransferReceiptPage> createState() => _TransferReceiptPageState();
}

class _TransferReceiptPageState extends State<TransferReceiptPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(
      const DashboardLoadRequested(silent: true),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final r = context.read<TransferBloc>().state.receipt;
      if (r == null || !context.read<AccessibilityBloc>().state.voiceFeedback) {
        return;
      }
      context.read<VoiceBloc>().add(
        SpeechPlaybackStarted(
          context.l10n.receiptSpoken(
            MoneyFormatter.spoken(r.amount, locale: context.langCode),
            r.beneficiaryName,
            r.reference,
          ),
          language: context.read<PreferencesCubit>().state.language,
          rate: context.read<AccessibilityBloc>().state.speechRate,
          private: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = context.watch<TransferBloc>().state.receipt;
    final st = StatusColors.of(context);
    final hc = st.isHighContrast;
    final text = Theme.of(context).textTheme;
    const verifiedColor = Color(0xFFB8F0C8);

    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.failureUnexpected)),
      );
    }

    Widget row(String k, String v) => MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: text.bodyMedium?.copyWith(
                  color: hc
                      ? Colors.white70
                      : Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            Flexible(
              child: Text(
                v,
                textAlign: TextAlign.end,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: hc ? Colors.black : AppColors.blueDeep,
        body: Container(
          decoration: hc
              ? null
              : const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF0F2A4A),
                      Color(0xFF091E3A),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
          child: SafeArea(
            child: ResponsiveBody(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                children: [
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    label: l.receiptSpoken(
                      context.money(r.amount),
                      r.beneficiaryName,
                      r.reference,
                    ),
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        // Confetti / celebratory checkmark circle
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.5),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l.receiptTitle,
                          textAlign: TextAlign.center,
                          style: text.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.receiptAmountTo(
                            context.money(r.amount),
                            r.beneficiaryName,
                          ),
                          textAlign: TextAlign.center,
                          style: text.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: verifiedColor,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                l.receiptVerified,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: verifiedColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Translucent receipt card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: hc ? 0.05 : 0.12),
                      borderRadius: BorderRadius.circular(Radii.lg),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: hc ? 1 : 0.25),
                        width: hc ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        row(l.receiptReference, r.reference),
                        const Divider(color: Colors.white24, height: 16),
                        row(
                          l.receiptDate,
                          '${shortDate(context, r.executedAt)} · ${hhmm(r.executedAt)}',
                        ),
                        const Divider(color: Colors.white24, height: 16),
                        row(l.confirmFee, context.money(r.fee)),
                        const Divider(color: Colors.white24, height: 16),
                        row(l.receiptNewBalance, context.money(r.newBalance)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: hc ? AppColors.hcAccent : AppColors.blue,
                      foregroundColor: hc ? Colors.black : Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.lg),
                      ),
                    ),
                    onPressed: () => context.go(Routes.home),
                    child: Text(
                      l.done,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
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
}
