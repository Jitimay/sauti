import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/providers/ai_provider.dart';
import '../../domain/repositories/conversation_repository.dart';

final class SecureConversationRepository implements ConversationRepository {
  SecureConversationRepository(this._storage, {this.maxMessages = 60});

  final FlutterSecureStorage _storage;
  final int maxMessages;
  static const _key = 'conversation_v1';

  @override
  Future<List<ChatMessage>> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List).map((e) {
        final m = (e as Map).cast<String, Object?>();
        return ChatMessage(
          id: m['id']! as String,
          role: m['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
          text: m['text']! as String,
          timestamp: DateTime.parse(m['ts']! as String),
          provider: AiProviderKind.values.where((p) => p.name == m['provider']).firstOrNull,
          isError: (m['err'] as bool?) ?? false,
        );
      }).toList();
    } catch (_) {
      await clear();
      return const [];
    }
  }

  @override
  Future<void> save(List<ChatMessage> messages) async {
    final keep = messages.length > maxMessages ? messages.sublist(messages.length - maxMessages) : messages;
    await _storage.write(
      key: _key,
      value: jsonEncode([
        for (final m in keep)
          {
            'id': m.id,
            'role': m.role.name,
            'text': m.text,
            'ts': m.timestamp.toIso8601String(),
            if (m.provider != null) 'provider': m.provider!.name,
            if (m.isError) 'err': true,
          },
      ]),
    );
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

final class InMemoryConversationRepository implements ConversationRepository {
  List<ChatMessage> _m = const [];
  @override
  Future<List<ChatMessage>> load() async => _m;
  @override
  Future<void> save(List<ChatMessage> messages) async => _m = List.unmodifiable(messages);
  @override
  Future<void> clear() async => _m = const [];
}
