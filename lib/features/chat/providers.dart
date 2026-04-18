import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/chat_database.dart';
import 'data/chat_model_preference_storage.dart';
import 'data/chat_repository.dart';
import 'domain/chat_model_preference.dart';
import 'domain/conversation.dart';
import 'domain/chat_message.dart';

// ── Database & Repository ──

final chatDatabaseProvider = FutureProvider<ChatDatabase>((ref) async {
  final db = await ChatDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final chatRepositoryProvider = FutureProvider<ChatRepository>((ref) async {
  final db = await ref.watch(chatDatabaseProvider.future);
  return ChatRepository(db);
});

// ── Conversations list ──

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final repo = await ref.watch(chatRepositoryProvider.future);
    return repo.getConversations();
  }

  Future<Conversation> create(String defaultTitle) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    final conv = await repo.createConversation(defaultTitle);
    ref.invalidateSelf();
    return conv;
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.deleteConversation(id);
    ref.invalidateSelf();
  }

  Future<void> rename(String id, String title) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.renameConversation(id, title);
    ref.invalidateSelf();
  }
}

// ── Messages for a conversation ──

final messagesProvider = AsyncNotifierProvider.family<MessagesNotifier,
    List<ChatMessage>, String>(
  MessagesNotifier.new,
);

class MessagesNotifier
    extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String arg) async {
    final repo = await ref.watch(chatRepositoryProvider.future);
    return repo.getMessages(arg);
  }

  Future<void> addUserMessage(String content) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.addUserMessage(arg, content);
    ref.invalidateSelf();
  }

  Future<void> addAssistantMessage(String content) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.addAssistantMessage(arg, content);
    ref.invalidateSelf();
  }
}

// ── Model preference ──

final chatModelPreferenceStorageProvider =
    FutureProvider<ChatModelPreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ChatModelPreferenceStorage(prefs);
});

class ChatModelPreferenceNotifier extends AsyncNotifier<ChatModelPreference> {
  @override
  Future<ChatModelPreference> build() async {
    final storage =
        await ref.watch(chatModelPreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(ChatModelPreference model) async {
    final storage =
        await ref.read(chatModelPreferenceStorageProvider.future);
    state = const AsyncValue<ChatModelPreference>.loading()
        .copyWithPrevious(state);
    try {
      await storage.write(model);
      state = AsyncValue.data(model);
    } catch (error, stack) {
      state = AsyncValue<ChatModelPreference>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final chatModelPreferenceProvider =
    AsyncNotifierProvider<ChatModelPreferenceNotifier, ChatModelPreference>(
  ChatModelPreferenceNotifier.new,
);

/// Whether the currently installed model matches the user's preference.
final isPreferredModelInstalledProvider = FutureProvider<bool>((ref) async {
  final storage = await ref.watch(chatModelPreferenceStorageProvider.future);
  final preferred = storage.read();
  final installed = storage.readInstalled();
  return installed == preferred;
});

/// Mark the given model as the one currently installed on disk.
final markModelInstalledProvider =
    FutureProvider.family<void, ChatModelPreference>((ref, model) async {
  final storage = await ref.read(chatModelPreferenceStorageProvider.future);
  await storage.writeInstalled(model);
});
