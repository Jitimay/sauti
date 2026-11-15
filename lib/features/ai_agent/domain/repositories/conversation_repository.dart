import '../entities/chat_message.dart';

/// Local conversation history. Stores message text only (no cards, no
/// account data beyond what was spoken), capped in size, clearable.
abstract interface class ConversationRepository {
  Future<List<ChatMessage>> load();
  Future<void> save(List<ChatMessage> messages);
  Future<void> clear();
}
