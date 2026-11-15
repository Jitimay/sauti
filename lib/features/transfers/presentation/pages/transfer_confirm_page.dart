import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/money/money_formatter.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../core/widgets/status_banners.dart';
import '../../../ai_agent/presentation/bloc/agent_bloc.dart';
import '../../../authentication/presentation/widgets/auth_widgets.dart';
import '../../../banking/domain/entities/transfer.dart';
import '../../../settings/presentation/bloc/accessibility_bloc.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';
import '../../../voice/presentation/bloc/voice_bloc.dart';
import '../../domain/entities/transfer_stage.dart';
import '../bloc/transfer_bloc.dart';
import '../widgets/transfer_summary.dart';

/// Steps 6–10 of the workflow: show/speak details → authenticate on device →
/// explicit "Send" → bank-verified result. Voice can never press "Send".
class TransferConfirmPage extends StatefulWidget {
  const TransferConfirmPage({super.key, this.draft});

  /// Draft handed over from the agent. Null when coming from the manual form.
  final TransferDraft? draft;

  @override
  State<TransferConfirmPage> createState() => _TransferConfirmPageState();
}

class _TransferConfirmPageState extends State<TransferConfirmPage> {
  final _password = TextEditingController();
  bool _usePassword = false;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TransferBloc>();
    final d = widget.draft;
    if (d != null && bloc.state.draft?.id != d.id) bloc.add(TransferDraftCreated(d));
    context.read<AgentBloc>().add(const AgentConfirmationHandled());
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakSummary());
  }

  void _speakSummary() {
    final d = widget.draft ?? context.read<TransferBloc>().state.draft;
    if (d == null || !context.read<AccessibilityBloc>().state.voiceFeedback) return;
    final l = context.l10n;
    context.read<VoiceBloc>().add(SpeechPlaybackStarted(
          '${l.confirmTo} ${d.beneficiary.name}. ${l.detailAmount}: ${MoneyFormatter.spoken(d.amount, locale: context.langCode)}. ${l.notSentYet}',
          language: context.read<PreferencesCubit>().state.language,
          rate: context.read<AccessibilityBloc>().state.speechRate,
        ));
  }

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return BlocConsumer<TransferBloc, TransferState>(
      listenWhen: (a, b) => a.stage != b.stage,
      listener: (context, s) {
        if (s.stage == TransferStage.completed) {
          _password.clear();
          context.pushReplacement(Routes.transferReceipt);
        } else if (s.stage == TransferStage.awaitingConfirmation) {
          _password.clear();
        } else if (s.stage == TransferStage.cancelled) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.transferCancelled)));
          context.pop();
        }
      },
      builder: (context, s) {
        final d = s.draft;
        return PopScope(
          canPop: s.stage != TransferStage.submitting,
          child: Scaffold(
            appBar: AppBar(title: Text(l.confirmTitle)),
            body: Column(children: [
              const OfflineBanner(),
              Expanded(
                child: d == null
                    ? const SizedBox.shrink()
                    : ResponsiveBody(
                        child: ListView(children: [
                          const SizedBox(height: 12),
                          TransferSummary(draft: d),
                          const SizedBox(height: 20),
                          ..._steps(context, s, d),
                          const SizedBox(height: 32),
                        ]),
                      ),
              ),
            ]),
          ),
        );
      },
    );
  }

  List<Widget> _steps(BuildContext context, TransferState s, TransferDraft d) {
    final l = context.l10n;
    final st = StatusColors.of(context);
    final bloc = context.read<TransferBloc>();
    final verified = s.stage == TransferStage.awaitingConfirmation || s.stage == TransferStage.submitting;
    final cancel = OutlinedButton.icon(
      onPressed: s.stage == TransferStage.submitting ? null : () => bloc.add(const TransferCancelled()),
      icon: const Icon(Icons.close_rounded),
      label: Text(l.cancelTransfer),
    );

    if (s.stage == TransferStage.failed) {
      return [
        Semantics(header: true, child: Text(l.transferFailedTitle, style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(height: 8),
        if (s.outcomeUnknown)
          Text(l.transferUnknownBody, style: Theme.of(context).textTheme.bodyLarge)
        else if (s.failure != null)
          FailureBox(s.failure!.code),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => bloc.add(TransferDraftCreated(d)), child: Text(l.retry)),
        const SizedBox(height: 12),
        cancel,
      ];
    }

    return [
      // ---- Step 1: authenticate ----
      _StepHeader(number: 1, title: l.stepVerify, done: verified),
      const SizedBox(height: 8),
      if (verified)
        Semantics(
          liveRegion: true,
          child: Row(children: [
            Icon(Icons.verified_rounded, color: st.success),
            const SizedBox(width: 8),
            Text(l.verified, style: TextStyle(color: st.success, fontWeight: FontWeight.w700, fontSize: 18)),
          ]),
        )
      else ...[
        if (s.failure != null) ...[FailureBox(s.failure!.code), const SizedBox(height: 12)],
        if (!s.deviceAuthAvailable) Text(l.deviceAuthUnavailable, style: Theme.of(context).textTheme.bodyMedium),
        if (s.deviceAuthAvailable && !_usePassword) ...[
          FilledButton.icon(
            onPressed: s.stage == TransferStage.authenticating
                ? null
                : () => bloc.add(TransferAuthenticationRequested(l.authReason(context.money(d.amount), d.beneficiary.name))),
            icon: const Icon(Icons.fingerprint_rounded),
            label: Text(l.authenticateButton),
          ),
          TextButton(onPressed: () => setState(() => _usePassword = true), child: Text(l.usePassword)),
        ] else ...[
          Text(l.passwordFallbackHint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          PasswordField(
            controller: _password,
            label: l.password,
            onSubmitted: (_) => bloc.add(TransferPasswordSubmitted(_password.text)),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: s.stage == TransferStage.authenticating ? null : () => bloc.add(TransferPasswordSubmitted(_password.text)),
            child: Text(l.verifyPassword),
          ),
        ],
      ],
      const SizedBox(height: 24),
      // ---- Step 2: explicit confirmation ----
      _StepHeader(number: 2, title: l.stepConfirm, done: false, enabled: verified),
      const SizedBox(height: 8),
      if (verified) Text(l.authExpiresHint, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      if (s.stage == TransferStage.submitting)
        Semantics(
          liveRegion: true,
          label: l.sending,
          child: Row(children: [
            const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 16),
            Expanded(child: Text(l.sending, style: Theme.of(context).textTheme.bodyLarge)),
          ]),
        )
      else
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
          // Disabled until verified: authentication alone never sends money.
          onPressed: verified ? () => bloc.add(const TransferSubmitted()) : null,
          icon: const Icon(Icons.send_rounded),
          label: Text(l.sendNow(context.money(d.amount))),
        ),
      const SizedBox(height: 12),
      cancel,
    ];
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.number, required this.title, required this.done, this.enabled = true});
  final int number;
  final String title;
  final bool done;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Row(children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: enabled ? scheme.primary : scheme.outline,
          foregroundColor: enabled ? scheme.onPrimary : scheme.surface,
          child: done ? const Icon(Icons.check_rounded, size: 18) : Text('$number'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: enabled ? null : scheme.onSurfaceVariant)),
        ),
      ]),
    );
  }
}
