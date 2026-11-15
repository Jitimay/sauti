import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_language.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/agent_card.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/tool_call.dart';
import '../../domain/providers/ai_provider.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/services/agent_orchestrator.dart';
import '../../domain/tools/agent_tool.dart';

// ---- Events ----
sealed class AgentUiEvent extends Equatable {
  const AgentUiEvent();
  @override
  List<Object?> get props => [];
}

final class AgentStarted extends AgentUiEvent {
  const AgentStarted();
}

final class AgentMessageSubmitted extends AgentUiEvent {
  const AgentMessageSubmitted(this.text, {required this.language, this.viaVoice = false});
  final String text;
  final AppLanguage language;
  final bool viaVoice;
  @override
  List<Object?> get props => [text, language, viaVoice];
}

final class AgentConversationCleared extends AgentUiEvent {
  const AgentConversationCleared();
}

/// The user has opened (or dismissed) the confirmation flow for a draft.
final class AgentConfirmationHandled extends AgentUiEvent {
  const AgentConfirmationHandled();
}

// ---- State ----
enum AgentPhase { idle, processing, executingTool, awaitingConfirmation, error }

final class AgentState extends Equatable {
  const AgentState({
    this.messages = const [],
    this.phase = AgentPhase.idle,
    this.activeTool,
    this.provider,
    this.failure,
    this.lastReplyViaVoice = false,
  });

  final List<ChatMessage> messages;
  final AgentPhase phase;
  final String? activeTool;
  final AiProviderKind? provider;
  final FailureCode? failure;

  /// Whether the last reply answered a spoken request (drives auto-speech).
  final bool lastReplyViaVoice;

  ChatMessage? get lastAssistant => messages.lastWhere((m) => m.role == ChatRole.assistant, orElse: () => _none);
  static final _none = ChatMessage(id: '', role: ChatRole.assistant, text: '', timestamp: DateTime(0));

  bool get busy => phase == AgentPhase.processing || phase == AgentPhase.executingTool;

  AgentState copyWith({
    List<ChatMessage>? messages,
    AgentPhase? phase,
    String? Function()? activeTool,
    AiProviderKind? Function()? provider,
    FailureCode? Function()? failure,
    bool? lastReplyViaVoice,
  }) =>
      AgentState(
        messages: messages ?? this.messages,
        phase: phase ?? this.phase,
        activeTool: activeTool != null ? activeTool() : this.activeTool,
        provider: provider != null ? provider() : this.provider,
        failure: failure != null ? failure() : this.failure,
        lastReplyViaVoice: lastReplyViaVoice ?? this.lastReplyViaVoice,
      );

  @override
  List<Object?> get props => [messages, phase, activeTool, provider, failure, lastReplyViaVoice];
}

/// Conversation state for the assistant. Orchestration, tool execution and
/// provider selection live in [AgentOrchestrator]; this BLoC only maps its
/// event stream (provider selected → tool started/finished → reply) to UI
/// state. The spec's AgentResponseReceived / AgentToolExecutionRequested /
/// AgentConfirmationRequired / AgentExecutionFailed correspond to the
/// orchestrator events handled in [_onSubmitted].
final class AgentBloc extends Bloc<AgentUiEvent, AgentState> {
  AgentBloc({
    required this._orchestrator,
    required this._history,
    required this._clock,
    required this._newId,
    required this._drafts,
  }) : super(const AgentState()) {
    on<AgentStarted>(_onStarted);
    // Banking requests are processed one at a time; extra taps are dropped.
    on<AgentMessageSubmitted>(_onSubmitted, transformer: droppable());
    on<AgentConversationCleared>(_onCleared, transformer: droppable());
    on<AgentConfirmationHandled>((e, emit) {
      if (state.phase == AgentPhase.awaitingConfirmation) emit(state.copyWith(phase: AgentPhase.idle));
    });
  }

  final AgentOrchestrator _orchestrator;
  final ConversationRepository _history;
  final Clock _clock;
  final String Function() _newId;
  final SessionDraftStore _drafts;

  Future<void> _onStarted(AgentStarted e, Emitter<AgentState> emit) async {
    if (state.messages.isNotEmpty) return;
    emit(state.copyWith(messages: await _history.load()));
  }

  Future<void> _onSubmitted(AgentMessageSubmitted e, Emitter<AgentState> emit) async {
    final text = e.text.trim();
    if (text.isEmpty) return;
    final history = state.messages;
    final userMsg = ChatMessage(id: _newId(), role: ChatRole.user, text: text, timestamp: _clock.now());
    emit(state.copyWith(
      messages: [...history, userMsg],
      phase: AgentPhase.processing,
      activeTool: () => null,
      failure: () => null,
    ));

    try {
      await for (final ev in _orchestrator.run(userText: text, history: history, language: e.language)) {
        switch (ev) {
          case AgentProviderSelected(:final kind):
            emit(state.copyWith(provider: () => kind));
          case AgentToolStarted(:final toolName):
            emit(state.copyWith(phase: AgentPhase.executingTool, activeTool: () => toolName));
          case AgentToolFinished(:final record):
            emit(state.copyWith(
              phase: AgentPhase.processing,
              activeTool: () => null,
              failure: () => record.status == ToolExecutionStatus.succeeded ? null : record.failure?.code,
            ));
          case AgentReplied(:final message):
            final awaiting = message.cards.any((c) => c is TransferDraftCard);
            emit(state.copyWith(
              messages: [...state.messages, message],
              phase: awaiting ? AgentPhase.awaitingConfirmation : AgentPhase.idle,
              activeTool: () => null,
              lastReplyViaVoice: e.viaVoice,
            ));
        }
      }
    } catch (_) {
      // Last-resort: the deterministic provider failed (should not happen).
      emit(state.copyWith(phase: AgentPhase.error, activeTool: () => null, failure: () => FailureCode.aiUnavailable));
    }
    await _history.save(state.messages);
  }

  Future<void> _onCleared(AgentConversationCleared e, Emitter<AgentState> emit) async {
    await _history.clear();
    _drafts.clear();
    emit(const AgentState());
  }
}
