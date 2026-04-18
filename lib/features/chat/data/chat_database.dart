import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/chat_message.dart';
import '../domain/conversation.dart';

class ChatDatabase {
  ChatDatabase._(this._db);

  final Database _db;

  static Future<ChatDatabase> open() async {
    final dbPath = join(await getDatabasesPath(), 'cookmate_chat.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return ChatDatabase._(db);
  }

  factory ChatDatabase.forTesting(Database db) => ChatDatabase._(db);

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Conversation>> getConversations() async {
    final rows = await _db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Conversation.fromMap).toList();
  }

  Future<void> insertConversation(Conversation conversation) async {
    await _db.insert('conversations', conversation.toMap());
  }

  Future<void> updateConversationTitle(String id, String title) async {
    await _db.update(
      'conversations',
      {'title': title, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteConversation(String id) async {
    await _db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final rows = await _db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> insertMessage(ChatMessage message) async {
    await _db.insert('messages', message.toMap());
    await _db.update(
      'conversations',
      {'updated_at': message.createdAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [message.conversationId],
    );
  }

  Future<void> close() async {
    await _db.close();
  }
}
