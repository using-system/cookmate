import 'package:cookmate/features/chat/data/chat_database.dart';
import 'package:cookmate/features/chat/data/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ChatRepository repository;
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
    final chatDb = ChatDatabase.forTesting(db);
    repository = ChatRepository(chatDb);
  });

  tearDown(() async {
    await db.close();
  });

  test('createConversation returns a new conversation with default title', () async {
    final conv = await repository.createConversation('New conversation');

    expect(conv.title, 'New conversation');
    expect(conv.id, isNotEmpty);

    final list = await repository.getConversations();
    expect(list.length, 1);
  });

  test('addUserMessage inserts a message with role user', () async {
    final conv = await repository.createConversation('Test');
    await repository.addUserMessage(conv.id, 'Hello');

    final messages = await repository.getMessages(conv.id);
    expect(messages.length, 1);
    expect(messages.first.role, 'user');
    expect(messages.first.content, 'Hello');
  });

  test('addAssistantMessage inserts a message with role assistant', () async {
    final conv = await repository.createConversation('Test');
    await repository.addAssistantMessage(conv.id, 'Hi there');

    final messages = await repository.getMessages(conv.id);
    expect(messages.length, 1);
    expect(messages.first.role, 'assistant');
    expect(messages.first.content, 'Hi there');
  });

  test('deleteConversation removes conversation', () async {
    final conv = await repository.createConversation('Doomed');
    await repository.deleteConversation(conv.id);

    expect(await repository.getConversations(), isEmpty);
  });

  test('deleteAllConversations removes all conversations and their messages',
      () async {
    final conv1 = await repository.createConversation('First');
    final conv2 = await repository.createConversation('Second');
    await repository.addUserMessage(conv1.id, 'Hello');
    await repository.addUserMessage(conv2.id, 'World');

    await repository.deleteAllConversations();

    expect(await repository.getConversations(), isEmpty);
    expect(await repository.getMessages(conv1.id), isEmpty);
    expect(await repository.getMessages(conv2.id), isEmpty);
  });

  test('renameConversation updates the title', () async {
    final conv = await repository.createConversation('Old');
    await repository.renameConversation(conv.id, 'New');

    final list = await repository.getConversations();
    expect(list.first.title, 'New');
  });

  test('addImageMessage persists with type image and mediaPath', () async {
    final conv = await repository.createConversation('Test');
    final msg =
        await repository.addImageMessage(conv.id, 'Photo', '/path/img.jpg');

    expect(msg.type, 'image');
    expect(msg.mediaPath, '/path/img.jpg');
    expect(msg.content, 'Photo');
    expect(msg.role, 'user');

    final messages = await repository.getMessages(conv.id);
    expect(messages.length, 1);
    expect(messages.first.type, 'image');
    expect(messages.first.mediaPath, '/path/img.jpg');
  });

  test('addAudioMessage persists with type audio and mediaPath', () async {
    final conv = await repository.createConversation('Test');
    final msg = await repository.addAudioMessage(conv.id, '/path/audio.m4a');

    expect(msg.type, 'audio');
    expect(msg.mediaPath, '/path/audio.m4a');
    expect(msg.content, '');
    expect(msg.role, 'user');

    final messages = await repository.getMessages(conv.id);
    expect(messages.length, 1);
    expect(messages.first.type, 'audio');
    expect(messages.first.mediaPath, '/path/audio.m4a');
  });
}
