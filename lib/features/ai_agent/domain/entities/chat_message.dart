import 'package:equatable/equatable.dart';

import '../providers/ai_provider.dart';
import 'agent_card.dart';

enum ChatRole { user, assistant }

final class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.cards = const [],
    this.toolsUsed = const [],
    this.provider,
    this.isError = false,
    this.usedFallback = false,
  });

  final String id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final List<AgentCard> cards;
  final List<String> toolsUsed;
  final AiProviderKind? provider;
  final bool isError;

  /// True when the preferred provider failed and a fallback answered.
  final bool usedFallback;

  @override
  List<Object?> get props => [id, role, text, timestamp, cards, toolsUsed, provider, isError, usedFallback];
}
