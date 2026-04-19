import 'package:uuid/uuid.dart';

import '../domain/chat_message.dart';
import '../domain/conversation.dart';
import 'chat_database.dart';

class ChatRepository {
  ChatRepository(this._db);

  final ChatDatabase _db;
  final _uuid = const Uuid();

  Future<List<Conversation>> getConversations() => _db.getConversations();

  Future<Conversation> createConversation(String defaultTitle) async {
    final now = DateTime.now();
    final conv = Conversation(
      id: _uuid.v4(),
      title: defaultTitle,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertConversation(conv);
    return conv;
  }

  Future<void> renameConversation(String id, String title) =>
      _db.updateConversationTitle(id, title);

  Future<void> deleteConversation(String id) => _db.deleteConversation(id);

  Future<List<ChatMessage>> getMessages(String conversationId) =>
      _db.getMessages(conversationId);

  Future<ChatMessage> addUserMessage(
      String conversationId, String content) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
    await _db.insertMessage(msg);
    return msg;
  }

  Future<ChatMessage> addAssistantMessage(
      String conversationId, String content) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: 'assistant',
      content: content,
      createdAt: DateTime.now(),
    );
    await _db.insertMessage(msg);
    return msg;
  }

  Future<ChatMessage> addImageMessage(
      String conversationId, String caption, String mediaPath) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: 'user',
      content: caption,
      createdAt: DateTime.now(),
      type: 'image',
      mediaPath: mediaPath,
    );
    await _db.insertMessage(msg);
    return msg;
  }

  Future<ChatMessage> addAudioMessage(
      String conversationId, String mediaPath) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: 'user',
      content: '',
      createdAt: DateTime.now(),
      type: 'audio',
      mediaPath: mediaPath,
    );
    await _db.insertMessage(msg);
    return msg;
  }
}
