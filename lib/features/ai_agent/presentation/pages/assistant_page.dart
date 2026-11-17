import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/l10n/app_language.dart';
import '../../../../core/l10n/l10n_ext.dart';
import '../../../../core/widgets/layout.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/bloc/accessibility_bloc.dart';
import '../../../settings/presentation/bloc/preferences_cubit.dart';
import '../../../voice/domain/speech_recognizer.dart';
import '../../../voice/presentation/bloc/voice_bloc.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/providers/ai_provider.dart';
import '../bloc/agent_bloc.dart';
import '../widgets/agent_cards.dart';
import '../widgets/voice_orb.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    context.read<AgentBloc>().add(const AgentStarted());
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  AppLanguage get _lang => context.read<PreferencesCubit>().state.language;

  void _sendText([String? text]) {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    context.read<VoiceBloc>().add(const SpeechPlaybackStopped());
    context.read<AgentBloc>().add(AgentMessageSubmitted(t, language: _lang));
    _input.clear();
  }

  void _onOrb(VoiceState voice) {
    final bloc = context.read<VoiceBloc>();
    switch (voice.status) {
      case VoiceStatus.listening:
        bloc.add(const VoiceListeningStopped());
      case VoiceStatus.speaking:
        bloc.add(const SpeechPlaybackStopped());
      default:
        bloc.add(VoiceListeningStarted(_lang));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return MultiBlocListener(
      listeners: [
        // Speech recognized → agent.
        BlocListener<VoiceBloc, VoiceState>(
          listenWhen: (a, b) => b.recognized != null && a.recognized?.seq != b.recognized?.seq,
          listener: (context, v) => context.read<AgentBloc>().add(
                AgentMessageSubmitted(v.recognized!.text, language: _lang, viaVoice: true),
              ),
        ),
        // New assistant reply → speak (if enabled or the request was spoken).
        BlocListener<AgentBloc, AgentState>(
          // Only a reply generated just now (exactly one new message after the
          // user's turn). Restoring saved history must never be read aloud.
          listenWhen: (a, b) =>
              b.messages.length == a.messages.length + 1 &&
              b.messages.last.role == ChatRole.assistant &&
              a.messages.isNotEmpty &&
              a.messages.last.role == ChatRole.user,
          listener: (context, s) {
            final a11y = context.read<AccessibilityBloc>().state;
            if (a11y.voiceFeedback || s.lastReplyViaVoice) {
              final last = s.messages.last;
              context.read<VoiceBloc>().add(SpeechPlaybackStarted(last.text,
                  language: _lang, rate: a11y.speechRate, private: last.provider == AiProviderKind.onDeviceLlm));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(header: true, child: Text(l.assistantTitle)),
          actions: [
            IconButton(
              tooltip: l.historyTitle,
              icon: const Icon(Icons.history_rounded),
              onPressed: () => context.push(Routes.history),
            ),
            IconButton(
              tooltip: l.clearConversation,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => context.read<AgentBloc>().add(const AgentConversationCleared()),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(children: [
            const _StatusStrip(),
            Expanded(child: _Messages(onSuggestion: _sendText)),
            const _VoiceNotices(),
            _Composer(
              controller: _input,
              focusNode: _inputFocus,
              onSend: _sendText,
              onOrb: _onOrb,
            ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Single live region announcing the assistant state.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip();

  static String toolWhat(AppLocalizations l, String tool) => switch (tool) {
        'get_account_balance' => l.toolWhatBalance,
        'calculate_monthly_spending' => l.toolWhatSpending,
        'list_beneficiaries' => l.toolWhatBeneficiaries,
        'prepare_transfer' || 'confirm_transfer' => l.toolWhatTransfer,
        'get_notifications' => l.toolWhatNotifications,
        _ => l.toolWhatTransactions,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final agent = context.watch<AgentBloc>().state;
    final voice = context.watch<VoiceBloc>().state;
    final st = StatusColors.of(context);
    final (IconData icon, String text) = switch ((voice.status, agent.phase)) {
      (VoiceStatus.listening || VoiceStatus.preparing, _) => (Icons.hearing_rounded, l.stateListening),
      (_, AgentPhase.executingTool) => (Icons.manage_search_rounded, l.toolRunning(toolWhat(l, agent.activeTool ?? ''))),
      (_, AgentPhase.processing) => (Icons.psychology_alt_rounded, l.stateProcessing),
      (VoiceStatus.speaking, _) => (Icons.record_voice_over_rounded, l.stateResponding),
      (_, AgentPhase.awaitingConfirmation) => (Icons.pending_actions_rounded, l.stateAwaitingConfirmation),
      (_, AgentPhase.error) || (VoiceStatus.error, _) => (Icons.error_outline_rounded, l.stateError),
      _ => (Icons.graphic_eq_rounded, l.stateIdle),
    };
    final provider = agent.provider;
    final busy = agent.busy || voice.status == VoiceStatus.listening;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: st.line, width: st.isHighContrast ? 2 : 1),
        ),
        child: Row(children: [
          IconBubble(icon, size: 40, background: busy ? st.accentSoft : null,
              color: busy && !st.isHighContrast ? AppColors.amberDeep : null),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Semantics(
              liveRegion: true,
              child: Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
          if (provider != null) ...[
            const SizedBox(width: 8),
            Flexible(flex: 2, child: ProviderBadge(provider)),
          ],
        ]),
      ),
    );
  }
}

class _Messages extends StatelessWidget {
  const _Messages({required this.onSuggestion});
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final messages = context.select<AgentBloc, List<ChatMessage>>((b) => b.state.messages);
    if (messages.isEmpty) {
      final suggestions = [
        (Icons.account_balance_wallet_rounded, l.suggestionBalance),
        (Icons.receipt_long_rounded, l.suggestionExplain),
        (Icons.north_east_rounded, l.suggestionSend),
        (Icons.pie_chart_rounded, l.suggestionSpending),
        (Icons.notifications_none_rounded, l.suggestionNotifications),
      ];
      return ResponsiveBody(
        child: ListView(padding: const EdgeInsets.only(bottom: 16), children: [
          const SizedBox(height: 12),
          const Center(child: SautiMark(size: 64)),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(l.tryAsking, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: 18),
          for (final (icon, s) in suggestions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Suggestion(icon: icon, text: s, onTap: () => onSuggestion(s)),
            ),
        ]),
      );
    }
    final lastAssistantId = messages.lastWhere((m) => m.role == ChatRole.assistant, orElse: () => messages.last).id;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[messages.length - 1 - i];
        return ResponsiveBody(
          child: m.role == ChatRole.user
              ? _UserBubble(message: m)
              : _AssistantMessage(message: m, isLatest: m.id == lastAssistantId),
        );
      },
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: '${context.l10n.you}: ${message.text}',
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(left: 56, bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(6),
            ),
          ),
          child: Text(message.text, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onPrimary)),
        ),
      ),
    );
  }
}

class _AssistantMessage extends StatelessWidget {
  const _AssistantMessage({required this.message, required this.isLatest});
  final ChatMessage message;
  final bool isLatest;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = StatusColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18, right: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: scheme.surface, shape: BoxShape.circle, border: Border.all(color: st.line)),
            child: const SautiMark(size: 26),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border.all(color: st.line, width: st.isHighContrast ? 2 : 1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Semantics(
                label: 'Sauti: ${message.text}',
                excludeSemantics: true,
                child: Text(message.text, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
          ),
        ]),
        if (message.cards.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final c in message.cards)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 8),
              child: AgentCardView(card: c, interactive: isLatest),
            ),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 44, top: 6),
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, runSpacing: 4, children: [
            if (message.usedFallback)
              ProviderBadge(message.provider ?? AiProviderKind.localDeterministic, fallback: true)
            else if (message.provider != null)
              ProviderBadge(message.provider!),
            if (isLatest)
              TextButton.icon(
                icon: const Icon(Icons.replay_rounded),
                label: Text(l.repeat),
                onPressed: () => context.read<VoiceBloc>().add(SpeechPlaybackStarted(
                      message.text,
                      language: context.read<PreferencesCubit>().state.language,
                      rate: context.read<AccessibilityBloc>().state.speechRate,
                      private: message.provider == AiProviderKind.onDeviceLlm,
                    )),
              ),
          ]),
        ),
      ]),
    );
  }
}

/// Voice errors and language-support notices with actionable fallbacks.
class _VoiceNotices extends StatelessWidget {
  const _VoiceNotices();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = context.watch<VoiceBloc>().state;
    final st = StatusColors.of(context);
    String? text;
    Widget? action;
    if (v.status == VoiceStatus.error) {
      switch (v.error) {
        case RecognitionErrorKind.languageUnsupported:
          final lang = v.unsupportedLanguage ?? AppLanguage.kirundi;
          text = l.voiceLanguageUnsupported(lang.nativeName);
          if (lang != AppLanguage.french) {
            action = TextButton(
              onPressed: () => context.read<VoiceBloc>().add(VoiceListeningStarted(
                    context.read<PreferencesCubit>().state.language,
                    overrideLanguage: AppLanguage.french,
                  )),
              child: Text(l.useFrenchVoice),
            );
          }
        case RecognitionErrorKind.permissionDenied:
          text = l.failureVoicePermission;
        case RecognitionErrorKind.noMatch:
          text = l.noSpeechHeard;
        case RecognitionErrorKind.network:
          text = l.failureNetwork;
        default:
          text = l.failureVoiceUnavailable;
      }
    } else if (v.ttsUnavailableFor != null) {
      text = l.ttsUnavailable(v.ttsUnavailableFor!.nativeName);
    }
    if (text == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        color: st.warningBg,
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        // Stacked layout so long translations never overflow.
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 12), child: Icon(Icons.info_outline_rounded, color: st.warning)),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(text, style: TextStyle(color: st.warning, fontWeight: FontWeight.w600)),
              ),
            ),
            IconButton(
              tooltip: l.close,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.read<VoiceBloc>().add(const VoiceErrorDismissed()),
            ),
          ]),
          if (action != null) Padding(padding: const EdgeInsets.only(left: 24), child: action),
        ]),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.focusNode, required this.onSend, required this.onOrb});
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String?> onSend;
  final ValueChanged<VoiceState> onOrb;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final voice = context.watch<VoiceBloc>().state;
    final agent = context.watch<AgentBloc>().state;
    final orbState = switch ((voice.status, agent.phase)) {
      (VoiceStatus.listening || VoiceStatus.preparing, _) => OrbState.listening,
      (VoiceStatus.speaking, _) => OrbState.speaking,
      (_, AgentPhase.processing || AgentPhase.executingTool) => OrbState.thinking,
      (_, AgentPhase.awaitingConfirmation) => OrbState.confirm,
      (VoiceStatus.error, _) => OrbState.error,
      _ => OrbState.idle,
    };
    final orbLabel = switch (orbState) {
      OrbState.listening => l.stopListening,
      OrbState.speaking => l.stopSpeaking,
      _ => l.startListening,
    };
    final st = StatusColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        border: st.isHighContrast ? Border(top: BorderSide(color: st.line, width: 2)) : null,
        boxShadow: st.isHighContrast
            ? null
            : const [BoxShadow(color: Color(0x140F2A4A), blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: ResponsiveBody(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (voice.partial.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('“${voice.partial}”',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
            ),
          VoiceOrb(
            state: orbState,
            label: orbLabel,
            size: context.watch<AccessibilityBloc>().state.textScale > 1.4 ? 88 : 76,
            onPressed: agent.busy ? null : () => onOrb(voice),
          ),
          Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !agent.busy,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(null),
                decoration: InputDecoration(
                  hintText: l.typeMessage,
                  labelText: l.typeMessage,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  fillColor: st.isHighContrast ? Colors.black : AppColors.canvas,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: st.isHighContrast ? st.line : Colors.transparent, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: l.send,
              style: IconButton.styleFrom(minimumSize: const Size(58, 58)),
              onPressed: agent.busy ? null : () => onSend(null),
              icon: const Icon(Icons.arrow_upward_rounded, size: 26),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.icon, required this.text, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
              child: Row(children: [
                ExcludeSemantics(child: IconBubble(icon, size: 40)),
                const SizedBox(width: 14),
                Expanded(child: Text('“$text”', style: Theme.of(context).textTheme.titleSmall)),
                ExcludeSemantics(
                  child: Icon(Icons.arrow_forward_rounded, size: 20, color: StatusColors.of(context).muted),
                ),
              ]),
            ),
          ),
        ),
      );
}

/// Which engine answered, colour-coded AND worded: on-device (private, green
/// with a lock), cloud (blue), basic mode (neutral).
class ProviderBadge extends StatelessWidget {
  const ProviderBadge(this.provider, {super.key, this.fallback = false});
  final AiProviderKind provider;
  final bool fallback;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = StatusColors.of(context);
    final label = fallback ? l.fallbackNotice : providerLabel(l, provider);
    final (Color fg, Color bg) = fallback
        ? (st.warning, st.warningBg)
        : switch (provider) {
            AiProviderKind.onDeviceLlm => (st.success, st.successBg),
            AiProviderKind.cloud => (Theme.of(context).colorScheme.primary,
                st.isHighContrast ? Colors.black : AppColors.navyTint),
            AiProviderKind.localDeterministic => (st.muted, st.sunken),
          };
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: st.isHighContrast ? Border.all(color: fg, width: 1.5) : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(fallback ? Icons.info_outline_rounded : providerIcon(provider), size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

/// Honest label for the engine that answered.
String providerLabel(AppLocalizations l, AiProviderKind p) => switch (p) {
      AiProviderKind.cloud => l.providerCloud,
      AiProviderKind.onDeviceLlm => l.providerOnDeviceAi,
      AiProviderKind.localDeterministic => l.providerLocal,
    };

IconData providerIcon(AiProviderKind p) => switch (p) {
      AiProviderKind.cloud => Icons.cloud_outlined,
      AiProviderKind.onDeviceLlm => Icons.lock_outline_rounded,
      AiProviderKind.localDeterministic => Icons.rule_rounded,
    };
