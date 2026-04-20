import 'package:cookmate/features/chat/data/chat_database.dart';
import 'package:cookmate/features/chat/domain/chat_message.dart';
import 'package:cookmate/features/chat/domain/conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ChatDatabase chatDb;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
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
            type TEXT NOT NULL DEFAULT 'text',
            media_path TEXT,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    chatDb = ChatDatabase.forTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('conversations', () {
    test('insertConversation and getConversations', () async {
      final now = DateTime.now();
      final conv = Conversation(
        id: 'c1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      await chatDb.insertConversation(conv);
      final list = await chatDb.getConversations();

      expect(list.length, 1);
      expect(list.first.id, 'c1');
      expect(list.first.title, 'Test');
    });

    test('getConversations returns ordered by updated_at DESC', () async {
      final old = DateTime(2026, 1, 1);
      final recent = DateTime(2026, 4, 18);

      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Old',
        createdAt: old,
        updatedAt: old,
      ));
      await chatDb.insertConversation(Conversation(
        id: 'c2',
        title: 'Recent',
        createdAt: recent,
        updatedAt: recent,
      ));

      final list = await chatDb.getConversations();
      expect(list.first.id, 'c2');
      expect(list.last.id, 'c1');
    });

    test('updateConversationTitle updates title', () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Old',
        createdAt: now,
        updatedAt: now,
      ));

      await chatDb.updateConversationTitle('c1', 'New title');
      final list = await chatDb.getConversations();

      expect(list.first.title, 'New title');
    });

    test('insertMessage updates conversation updated_at and reorders list',
        () async {
      final old = DateTime(2026, 1, 1);
      final recent = DateTime(2026, 4, 18);

      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Old conv',
        createdAt: old,
        updatedAt: old,
      ));
      await chatDb.insertConversation(Conversation(
        id: 'c2',
        title: 'Recent conv',
        createdAt: recent,
        updatedAt: recent,
      ));

      // c2 is on top initially.
      var list = await chatDb.getConversations();
      expect(list.first.id, 'c2');

      // Add a message to the old conversation — it should jump to the top.
      await chatDb.insertMessage(ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: 'user',
        content: 'Hello',
        createdAt: DateTime(2026, 5, 1),
      ));

      list = await chatDb.getConversations();
      expect(list.first.id, 'c1');
    });

    test('deleteAllConversations removes all conversations and messages',
        () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'First',
        createdAt: now,
        updatedAt: now,
      ));
      await chatDb.insertConversation(Conversation(
        id: 'c2',
        title: 'Second',
        createdAt: now,
        updatedAt: now,
      ));
      await chatDb.insertMessage(ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: 'user',
        content: 'Hello',
        createdAt: now,
      ));
      await chatDb.insertMessage(ChatMessage(
        id: 'm2',
        conversationId: 'c2',
        role: 'user',
        content: 'World',
        createdAt: now,
      ));

      await chatDb.deleteAllConversations();

      expect(await chatDb.getConversations(), isEmpty);
      expect(await chatDb.getMessages('c1'), isEmpty);
      expect(await chatDb.getMessages('c2'), isEmpty);
    });

    test('deleteAllConversations on empty database does nothing', () async {
      await chatDb.deleteAllConversations();
      expect(await chatDb.getConversations(), isEmpty);
    });

    test('deleteConversation removes conversation and its messages', () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Doomed',
        createdAt: now,
        updatedAt: now,
      ));
      await chatDb.insertMessage(ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: 'user',
        content: 'Hello',
        createdAt: now,
      ));

      await chatDb.deleteConversation('c1');

      expect(await chatDb.getConversations(), isEmpty);
      expect(await chatDb.getMessages('c1'), isEmpty);
    });
  });

  group('messages', () {
    test('insertMessage and getMessages', () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Conv',
        createdAt: now,
        updatedAt: now,
      ));
      final msg = ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: 'user',
        content: 'Hello',
        createdAt: now,
      );

      await chatDb.insertMessage(msg);
      final list = await chatDb.getMessages('c1');

      expect(list.length, 1);
      expect(list.first.content, 'Hello');
    });

    test('getMessages returns ordered by created_at ASC', () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Conv',
        createdAt: now,
        updatedAt: now,
      ));

      await chatDb.insertMessage(ChatMessage(
        id: 'm2',
        conversationId: 'c1',
        role: 'assistant',
        content: 'Second',
        createdAt: now.add(const Duration(seconds: 1)),
      ));
      await chatDb.insertMessage(ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: 'user',
        content: 'First',
        createdAt: now,
      ));

      final list = await chatDb.getMessages('c1');
      expect(list.first.content, 'First');
      expect(list.last.content, 'Second');
    });
  });
}
