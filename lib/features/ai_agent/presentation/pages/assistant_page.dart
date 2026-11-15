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
          listenWhen: (a, b) => b.messages.length > a.messages.length && b.messages.last.role == ChatRole.assistant,
          listener: (context, s) {
            final a11y = context.read<AccessibilityBloc>().state;
            if (a11y.voiceFeedback || s.lastReplyViaVoice) {
              context.read<VoiceBloc>().add(SpeechPlaybackStarted(s.messages.last.text, language: _lang, rate: a11y.speechRate));
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
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(flex: 3, child: Semantics(liveRegion: true, child: Text(text, style: Theme.of(context).textTheme.titleMedium))),
        if (provider != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Semantics(
              label: providerLabel(l, provider),
              excludeSemantics: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(providerIcon(provider), size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      providerLabel(l, provider),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: st.muted),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
      ]),
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
      return ResponsiveBody(
        child: ListView(children: [
          const SizedBox(height: 24),
          const Center(child: SautiMark(size: 72)),
          const SizedBox(height: 16),
          Semantics(header: true, child: Text(l.tryAsking, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 16),
          for (final s in [l.suggestionBalance, l.suggestionExplain, l.suggestionSend, l.suggestionSpending, l.suggestionNotifications])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
                onPressed: () => onSuggestion(s),
                child: Text('“$s”'),
              ),
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
          margin: const EdgeInsets.only(left: 48, bottom: 12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.only(top: 2), child: SautiMark(size: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: 'Sauti: ${message.text}',
              excludeSemantics: true,
              child: Text(message.text, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ]),
        if (message.cards.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final c in message.cards)
            Padding(
              padding: const EdgeInsets.only(left: 38, bottom: 8),
              child: AgentCardView(card: c, interactive: isLatest),
            ),
        ],
        Padding(
          padding: const EdgeInsets.only(left: 38, top: 4),
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
            if (message.usedFallback)
              Text(l.fallbackNotice, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: st.warning))
            else if (message.provider != null)
              Text(providerLabel(l, message.provider!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: st.muted)),
            if (isLatest)
              TextButton.icon(
                icon: const Icon(Icons.replay_rounded),
                label: Text(l.repeat),
                onPressed: () => context.read<VoiceBloc>().add(SpeechPlaybackStarted(
                      message.text,
                      language: context.read<PreferencesCubit>().state.language,
                      rate: context.read<AccessibilityBloc>().state.speechRate,
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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: ResponsiveBody(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (voice.partial.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('“${voice.partial}”',
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontStyle: FontStyle.italic)),
            ),
          VoiceOrb(
            state: orbState,
            label: orbLabel,
            size: context.watch<AccessibilityBloc>().state.textScale > 1.4 ? 96 : 88,
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
                decoration: InputDecoration(hintText: l.typeMessage, labelText: l.typeMessage),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: l.send,
              onPressed: agent.busy ? null : () => onSend(null),
              icon: const Icon(Icons.arrow_upward_rounded),
            ),
          ]),
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
