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

/// Voice and text banking assistant with structured results and inference labels.
class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

bool _requiresDeviceVoice(ChatMessage message) =>
    message.provider != AiProviderKind.cloud &&
    message.provider != AiProviderKind.localDeterministic;

class _AssistantPageState extends State<AssistantPage> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  bool _audioMuted = false;
  bool _askingForVoicePermission = false;

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
    final voice = context.read<VoiceBloc>();
    voice.add(
      voice.state.status == VoiceStatus.error
          ? const VoiceErrorDismissed()
          : const SpeechPlaybackStopped(),
    );
    context.read<AgentBloc>().add(AgentMessageSubmitted(t, language: _lang));
    _input.clear();
  }

  void _toggleAudio() {
    setState(() => _audioMuted = !_audioMuted);
    if (_audioMuted) {
      context.read<VoiceBloc>().add(const SpeechPlaybackStopped());
    }
  }

  Future<void> _maybeSpeakReply(AgentState reply) async {
    if (_audioMuted ||
        GoRouter.of(context).routeInformationProvider.value.uri.path !=
            Routes.assistant) {
      return;
    }
    final accessibility = context.read<AccessibilityBloc>();
    final settings = accessibility.state;
    final message = reply.messages.last;
    final language = _lang;
    if (!settings.voiceFeedback) {
      if (!reply.lastReplyViaVoice ||
          settings.voiceFeedbackChoice != null ||
          _askingForVoicePermission) {
        return;
      }
      _askingForVoicePermission = true;
      final l = context.l10n;
      final allowed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.voiceConsentTitle),
          content: Text(l.voiceConsentBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l.voiceConsentDecline),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l.voiceConsentAllow),
            ),
          ],
        ),
      );
      if (!mounted) return;
      _askingForVoicePermission = false;
      if (allowed == null) return;
      accessibility.add(VoiceFeedbackChanged(allowed));
      if (!allowed ||
          _audioMuted ||
          context.read<AgentBloc>().state.messages.lastOrNull?.id !=
              message.id) {
        return;
      }
    }

    context.read<VoiceBloc>().add(
      SpeechPlaybackStarted(
        message.text,
        language: language,
        rate: accessibility.state.speechRate,
        private: _requiresDeviceVoice(message),
      ),
    );
  }

  void _onOrb(VoiceState voice) {
    final bloc = context.read<VoiceBloc>();
    switch (voice.status) {
      case VoiceStatus.listening || VoiceStatus.preparing:
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
    final voice = context.watch<VoiceBloc>().state;
    final isListening = voice.status == VoiceStatus.listening;
    final hc = StatusColors.of(context).isHighContrast;
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 420;
    final simplifiedTitle =
        compact && MediaQuery.textScalerOf(context).scale(22) > 32;
    final audioLabel = _audioMuted ? l.unmuteVoice : l.muteVoice;
    final audioIcon = _audioMuted
        ? Icons.volume_off_rounded
        : Icons.volume_up_rounded;

    void openHistory() => context.push(Routes.history);
    void clearConversation() =>
        context.read<AgentBloc>().add(const AgentConversationCleared());

    return MultiBlocListener(
      listeners: [
        // Speech recognized -> agent
        BlocListener<VoiceBloc, VoiceState>(
          listenWhen: (a, b) =>
              b.recognized != null && a.recognized?.seq != b.recognized?.seq,
          listener: (context, v) => context.read<AgentBloc>().add(
            AgentMessageSubmitted(
              v.recognized!.text,
              language: _lang,
              viaVoice: true,
            ),
          ),
        ),
        // New assistant reply -> speak
        BlocListener<AgentBloc, AgentState>(
          listenWhen: (a, b) =>
              b.messages.length == a.messages.length + 1 &&
              b.messages.last.role == ChatRole.assistant &&
              a.messages.isNotEmpty &&
              a.messages.last.role == ChatRole.user,
          listener: (context, state) => _maybeSpeakReply(state),
        ),
      ],
      child: Scaffold(
        backgroundColor: isListening && !hc ? AppColors.navyDeep : null,
        appBar: AppBar(
          backgroundColor: isListening && !hc ? AppColors.navyDeep : null,
          foregroundColor: isListening && !hc ? Colors.white : null,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => context.go(Routes.home),
          ),
          titleSpacing: compact ? 8 : null,
          title: Semantics(
            header: true,
            label: l.assistantTitle,
            excludeSemantics: true,
            child: Text(
              simplifiedTitle ? l.appName : l.assistantTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: isListening && !hc ? Colors.white : null,
              ),
            ),
          ),
          actions: compact
              ? [
                  PopupMenuButton<VoidCallback>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (action) => action(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: _toggleAudio,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(audioIcon),
                          title: Text(audioLabel),
                        ),
                      ),
                      PopupMenuItem(
                        value: openHistory,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.history_rounded),
                          title: Text(l.historyTitle),
                        ),
                      ),
                      PopupMenuItem(
                        value: clearConversation,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.delete_sweep_outlined),
                          title: Text(l.clearConversation),
                        ),
                      ),
                    ],
                  ),
                ]
              : [
                  IconButton(
                    tooltip: audioLabel,
                    icon: Icon(
                      audioIcon,
                      color: isListening && !hc ? Colors.white : scheme.primary,
                    ),
                    onPressed: _toggleAudio,
                  ),
                  IconButton(
                    tooltip: l.historyTitle,
                    icon: const Icon(Icons.history_rounded),
                    onPressed: openHistory,
                  ),
                  IconButton(
                    tooltip: l.clearConversation,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: clearConversation,
                  ),
                ],
        ),
        body: SafeArea(
          top: false,
          child: isListening
              ? _VoiceListeningView(
                  partialText: voice.partial,
                  onCancel: () => context.read<VoiceBloc>().add(
                    const VoiceListeningStopped(),
                  ),
                )
              : Column(
                  children: [
                    const _StatusStrip(),
                    Expanded(child: _Messages(onSuggestion: _sendText)),
                    const _VoiceNotices(),
                    _Composer(
                      controller: _input,
                      focusNode: _inputFocus,
                      onSend: _sendText,
                      onOrb: _onOrb,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Dedicated listening view that keeps the transcript and stop action visible.
class _VoiceListeningView extends StatelessWidget {
  const _VoiceListeningView({
    required this.partialText,
    required this.onCancel,
  });
  final String partialText;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final highContrast = StatusColors.of(context).isHighContrast;
    final foreground = highContrast ? scheme.onSurface : Colors.white;
    return ResponsiveBody(
      maxWidth: 760,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l.stateListening,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                color: highContrast ? scheme.surface : AppColors.blueDeep,
                shape: BoxShape.circle,
                border: Border.all(
                  color: foreground.withValues(alpha: highContrast ? 1 : 0.2),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(Icons.mic_rounded, color: foreground, size: 46),
              ),
            ),
            const SizedBox(height: 36),
            ExcludeSemantics(
              child: SoundwaveBars(
                color: highContrast ? scheme.primary : const Color(0xFF68D6BC),
                barCount: 18,
                height: 42,
              ),
            ),
            const SizedBox(height: 36),
            Text(
              partialText.isNotEmpty ? '“$partialText”' : l.startListening,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '“${l.suggestionBalance}”',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: foreground,
                side: BorderSide(color: foreground, width: 1.5),
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: onCancel,
              child: Text(
                l.cancel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

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
    final status = switch ((voice.status, agent.phase)) {
      (VoiceStatus.preparing, _) => (Icons.mic_rounded, l.stateMicrophoneAccess),
      (VoiceStatus.listening, _) => (
        Icons.hearing_rounded,
        l.stateListening,
      ),
      (_, AgentPhase.executingTool) => (
        Icons.manage_search_rounded,
        l.toolRunning(toolWhat(l, agent.activeTool ?? '')),
      ),
      (_, AgentPhase.processing) => (
        Icons.psychology_alt_rounded,
        l.stateProcessing,
      ),
      (VoiceStatus.speaking, _) => (
        Icons.record_voice_over_rounded,
        l.stateResponding,
      ),
      (_, AgentPhase.awaitingConfirmation) => (
        Icons.pending_actions_rounded,
        l.stateAwaitingConfirmation,
      ),
      (_, AgentPhase.error) => (Icons.error_outline_rounded, l.stateError),
      _ => null,
    };
    if (status == null) return const SizedBox.shrink();
    final (icon, text) = status;
    final isError = agent.phase == AgentPhase.error;
    final (foreground, background) = isError
        ? (st.error, st.errorBg)
        : (
            Theme.of(context).colorScheme.onSurface,
            Theme.of(context).colorScheme.surface,
          );

    return ResponsiveBody(
      maxWidth: 760,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: st.line, width: st.isHighContrast ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
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
    final messages = context.select<AgentBloc, List<ChatMessage>>(
      (b) => b.state.messages,
    );

    if (messages.isEmpty) {
      final suggestions = [
        (Icons.account_balance_wallet_rounded, l.suggestionBalance),
        (Icons.receipt_long_rounded, l.suggestionExplain),
        (Icons.north_east_rounded, l.suggestionSend),
        (Icons.pie_chart_rounded, l.suggestionSpending),
        (Icons.notifications_none_rounded, l.suggestionNotifications),
      ];
      return ResponsiveBody(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          children: [
            const _AssistantIntro(),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 12.0;
                final columns =
                    constraints.maxWidth >= 600 &&
                        MediaQuery.textScalerOf(context).scale(16) < 23
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;

                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final (index, suggestion) in suggestions.indexed)
                      SizedBox(
                        width: index == 0 ? constraints.maxWidth : width,
                        child: _Suggestion(
                          icon: suggestion.$1,
                          text: suggestion.$2,
                          primary: index == 0,
                          onTap: () => onSuggestion(suggestion.$2),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    final lastAssistantId = messages
        .lastWhere(
          (m) => m.role == ChatRole.assistant,
          orElse: () => messages.last,
        )
        .id;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[messages.length - 1 - i];
        return ResponsiveBody(
          maxWidth: 760,
          child: m.role == ChatRole.user
              ? _UserBubble(message: m)
              : _AssistantMessage(
                  message: m,
                  isLatest: m.id == lastAssistantId,
                ),
        );
      },
    );
  }
}

class _AssistantIntro extends StatelessWidget {
  const _AssistantIntro();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final st = StatusColors.of(context);
    final foreground = st.isHighContrast
        ? theme.colorScheme.onSurface
        : Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: st.isHighContrast ? theme.colorScheme.surface : null,
        gradient: st.isHighContrast
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF152953), AppColors.blueDeep],
              ),
        border: st.isHighContrast ? Border.all(color: st.line, width: 2) : null,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SautiMark(size: 42, onDark: true),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              l.tryAsking,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: foreground,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.stateIdle,
            style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final st = StatusColors.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '${context.l10n.you}: ${message.text}',
      excludeSemantics: true,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Container(
          margin: const EdgeInsetsDirectional.only(start: 44, bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: st.isHighContrast ? scheme.surface : scheme.primaryContainer,
            border: st.isHighContrast
                ? Border.all(color: st.line, width: 2)
                : null,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(Radii.lg),
              topEnd: Radius.circular(Radii.lg),
              bottomStart: Radius.circular(Radii.lg),
              bottomEnd: Radius.circular(6),
            ),
          ),
          child: Text(
            message.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: st.isHighContrast
                  ? scheme.onSurface
                  : scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: st.isHighContrast
                          ? scheme.surface
                          : scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(Radii.sm),
                      border: st.isHighContrast
                          ? Border.all(color: st.line, width: 2)
                          : null,
                    ),
                    child: const Center(child: SautiMark(size: 23)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (message.provider case final provider?)
                          ProviderBadge(provider),
                        if (message.usedFallback)
                          ProviderBadge(
                            message.provider ??
                                AiProviderKind.localDeterministic,
                            fallback: true,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Sauti: ${message.text}',
                excludeSemantics: true,
                child: Text(message.text, style: theme.textTheme.bodyLarge),
              ),
              for (final card in message.cards)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AgentCardView(card: card, interactive: isLatest),
                ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: const Icon(Icons.volume_up_outlined, size: 20),
                  label: Text(l.repeat),
                  onPressed: () => context.read<VoiceBloc>().add(
                    SpeechPlaybackStarted(
                      message.text,
                      language: context.read<PreferencesCubit>().state.language,
                      rate: context.read<AccessibilityBloc>().state.speechRate,
                      private: _requiresDeviceVoice(message),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onOrb,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String?> onSend;
  final ValueChanged<VoiceState> onOrb;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final agent = context.watch<AgentBloc>().state;
    final voice = context.watch<VoiceBloc>().state;
    final st = StatusColors.of(context);

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (IconData voiceIcon, String voiceLabel) = switch (voice.status) {
      VoiceStatus.listening ||
      VoiceStatus.preparing => (Icons.stop_rounded, l.stopListening),
      VoiceStatus.speaking => (Icons.volume_off_rounded, l.stopSpeaking),
      _ => (Icons.mic_rounded, l.startListening),
    };
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: st.line, width: st.isHighContrast ? 2 : 1),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: st.line, width: st.isHighContrast ? 2 : 1),
        ),
      ),
      child: ResponsiveBody(
        maxWidth: 760,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
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
                  labelText: l.typeMessage,
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  fillColor: st.sunken,
                  filled: true,
                  border: outline,
                  enabledBorder: outline,
                  focusedBorder: outline.copyWith(
                    borderSide: BorderSide(color: scheme.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: voiceLabel,
              excludeFromSemantics: true,
              child: IconButton.filledTonal(
                onPressed: agent.busy ? null : () => onOrb(voice),
                icon: Icon(voiceIcon, semanticLabel: voiceLabel),
                style: IconButton.styleFrom(
                  backgroundColor: st.isHighContrast
                      ? scheme.surface
                      : scheme.primaryContainer,
                  foregroundColor: st.isHighContrast
                      ? scheme.primary
                      : scheme.onPrimaryContainer,
                  side: st.isHighContrast
                      ? BorderSide(color: scheme.primary, width: 2)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              tooltip: l.send,
              onPressed: agent.busy ? null : () => onSend(null),
              icon: const Icon(Icons.send_rounded),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                side: st.isHighContrast
                    ? BorderSide(color: scheme.primary, width: 2)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.icon,
    required this.text,
    required this.onTap,
    required this.primary,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final st = StatusColors.of(context);
    final highlighted = primary && !st.isHighContrast;
    return Card(
      color: highlighted ? scheme.primaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(
          color: highlighted ? scheme.primary.withValues(alpha: 0.25) : st.line,
          width: st.isHighContrast ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              IconBubble(
                icon,
                size: 36,
                background: highlighted ? scheme.surface : null,
                color: scheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '“$text”',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: highlighted
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                    fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            AiProviderKind.cloud => (
              Theme.of(context).colorScheme.primary,
              st.isHighContrast ? Colors.black : AppColors.navyTint,
            ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              fallback ? Icons.info_outline_rounded : providerIcon(provider),
              size: 16,
              color: fg,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
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
          final lang = v.unsupportedLanguage;
          text = lang == null
              ? l.failureVoiceLanguage
              : l.voiceLanguageUnsupported(lang.nativeName);
          if (lang == AppLanguage.kirundi) {
            action = TextButton(
              onPressed: () => context.read<VoiceBloc>().add(
                VoiceListeningStarted(
                  context.read<PreferencesCubit>().state.language,
                  overrideLanguage: AppLanguage.french,
                ),
              ),
              child: Text(l.useFrenchVoice),
            );
          }
        case RecognitionErrorKind.permissionDenied:
          text = l.failureVoicePermission;
        case RecognitionErrorKind.microphoneUnavailable:
          text = l.failureMicrophoneCapture;
        case RecognitionErrorKind.serviceUnavailable:
          text = l.failureSpeechService;
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
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: st.warningBg,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: st.warning.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: st.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: st.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
