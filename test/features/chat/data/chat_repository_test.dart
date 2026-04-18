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

  test('renameConversation updates the title', () async {
    final conv = await repository.createConversation('Old');
    await repository.renameConversation(conv.id, 'New');

    final list = await repository.getConversations();
    expect(list.first.title, 'New');
  });
}
