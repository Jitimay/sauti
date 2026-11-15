import '../../../../core/l10n/app_language.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/clock.dart';
import '../entities/agent_card.dart';
import '../entities/chat_message.dart';
import '../entities/tool_call.dart';
import '../entities/tool_spec.dart';
import '../providers/ai_provider.dart';
import '../tools/agent_tool.dart';
import '../tools/tool_registry.dart';
import 'grounding_guard.dart';

sealed class AgentEvent {
  const AgentEvent();
}

final class AgentProviderSelected extends AgentEvent {
  const AgentProviderSelected(this.kind, {required this.isFallback});
  final AiProviderKind kind;
  final bool isFallback;
}

final class AgentToolStarted extends AgentEvent {
  const AgentToolStarted(this.toolName);
  final String toolName;
}

final class AgentToolFinished extends AgentEvent {
  const AgentToolFinished(this.record);
  final ToolExecutionRecord record;
}

final class AgentReplied extends AgentEvent {
  const AgentReplied(this.message);
  final ChatMessage message;
}

/// Selects an inference path, runs the tool-calling loop through the
/// permissioned [ToolRegistry], and falls back safely.
///
/// Order of preference is the order of [providers]. A provider is skipped if
/// unavailable (offline, not configured, disabled) and abandoned on error,
/// in which case the next provider answers and the reply is flagged
/// `usedFallback`. The last provider must be the deterministic local engine,
/// which never throws.
final class AgentOrchestrator {
  AgentOrchestrator({
    required List<AiProvider> providers,
    required this._registry,
    required this._clock,
    required this._newId,
    required this.drafts,
    this.granted = const {
      ToolPermission.readAccounts,
      ToolPermission.readTransactions,
      ToolPermission.readBeneficiaries,
      ToolPermission.readNotifications,
      ToolPermission.prepareTransfer,
    },
    this.maxToolRounds = 4,
    this.historyWindow = 10,
    this.guard = const GroundingGuard(),
    this._logger = const PrintLogger(),
  })  : assert(providers.isNotEmpty),
        _providers = providers;

  final List<AiProvider> _providers;
  final ToolRegistry _registry;
  final Clock _clock;
  final String Function() _newId;
  final AppLogger _logger;
  final SessionDraftStore drafts;
  final Set<ToolPermission> granted;
  final int maxToolRounds;
  final int historyWindow;
  final GroundingGuard guard;

  Stream<AgentEvent> run({
    required String userText,
    required List<ChatMessage> history,
    required AppLanguage language,
  }) async* {
    final available = <AiProvider>[];
    for (final p in _providers) {
      if (await _safeAvailable(p)) available.add(p);
    }
    if (available.isEmpty) available.add(_providers.last);

    for (var i = 0; i < available.length; i++) {
      final provider = available[i];
      final isLast = i == available.length - 1;
      yield AgentProviderSelected(provider.kind, isFallback: i > 0 || provider != _providers.first);
      final events = <AgentEvent>[];
      final draftsBefore = drafts.ids;
      try {
        await for (final e in _runWith(provider, userText, history, language, usedFallback: i > 0)) {
          // Tool progress is streamed live; the reply is held until the loop
          // completes successfully so a failing provider never half-answers.
          if (e is AgentReplied) {
            events.add(e);
          } else {
            yield e;
          }
        }
        yield* Stream.fromIterable(events);
        return;
      } on AiProviderException catch (e) {
        _logger.warn('agent', '${provider.kind.name} failed → fallback', e);
        // Drafts created by an abandoned attempt were never shown to the user;
        // drop them so the fallback provider's draft is the only one.
        drafts.ids.difference(draftsBefore).forEach(drafts.remove);
        if (isLast) rethrow;
      }
    }
  }

  Future<bool> _safeAvailable(AiProvider p) async {
    try {
      return await p.isAvailable();
    } catch (_) {
      return false;
    }
  }

  Stream<AgentEvent> _runWith(
    AiProvider provider,
    String userText,
    List<ChatMessage> history,
    AppLanguage language, {
    required bool usedFallback,
  }) async* {
    final caller = provider.kind == AiProviderKind.cloud ? ToolCaller.cloudModel : ToolCaller.localEngine;
    final ctx = ToolContext(caller: caller, language: language, granted: granted, drafts: drafts);
    final turns = <AiTurn>[
      for (final m in history.reversed.take(historyWindow).toList().reversed)
        if (!m.isError) m.role == ChatRole.user ? UserTurn(m.text) : AssistantTurn(m.text),
      UserTurn(userText),
    ];
    final tools = _registry.specsFor(caller, granted);
    final records = <ToolExecutionRecord>[];

    for (var round = 0; round <= maxToolRounds; round++) {
      final response = await provider.generateResponse(AiRequest(language: language, turns: turns, tools: tools));
      switch (response) {
        case AiToolCallResponse(:final calls, :final providerNative):
          if (round == maxToolRounds || calls.isEmpty) {
            throw const AiProviderException(AiErrorKind.invalidResponse, 'tool loop did not converge');
          }
          final roundRecords = <ToolExecutionRecord>[];
          for (final call in calls.take(5)) {
            yield AgentToolStarted(call.name);
            final rec = await _registry.execute(call, ctx);
            roundRecords.add(rec);
            yield AgentToolFinished(rec);
          }
          records.addAll(roundRecords);
          turns
            ..add(ToolCallsTurn(calls.take(5).toList(), providerNative: providerNative))
            ..add(ToolResultsTurn(roundRecords));
        case AiTextResponse(:final text):
          if (provider.kind == AiProviderKind.cloud) {
            final bad = guard.ungroundedAmounts(text, userText: userText, records: records);
            if (bad.isNotEmpty) {
              throw AiProviderException(AiErrorKind.invalidResponse, 'ungrounded amounts: $bad');
            }
          }
          final cards = <AgentCard>[
            for (final r in records)
              if (r.card != null) r.card!,
          ];
          yield AgentReplied(ChatMessage(
            id: _newId(),
            role: ChatRole.assistant,
            text: text.trim(),
            timestamp: _clock.now(),
            cards: _dedupe(cards),
            toolsUsed: [for (final r in records) r.request.name],
            provider: provider.kind,
            usedFallback: usedFallback,
          ));
          return;
      }
    }
  }

  /// Keep only the most informative card per type (last one wins).
  List<AgentCard> _dedupe(List<AgentCard> cards) {
    final byType = <Type, AgentCard>{};
    for (final c in cards) {
      byType[c.runtimeType] = c;
    }
    return byType.values.toList();
  }
}
