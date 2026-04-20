import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/chat_backend_preference_storage.dart';
import 'data/expert_config_storage.dart';
import 'data/reasoning_preference_storage.dart';
import 'data/chat_database.dart';
import 'data/chat_model_preference_storage.dart';
import 'data/chat_model_service.dart';
import 'data/chat_repository.dart';
import 'domain/chat_backend_preference.dart';
import 'domain/chat_model_preference.dart';
import 'domain/expert_config.dart';
import 'domain/conversation.dart';

// ── Database & Repository ──

final chatDatabaseProvider = FutureProvider<ChatDatabase>((ref) async {
  final db = await ChatDatabase.open();
  ref.onDispose(() => db.close());
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

  Future<void> deleteAll() async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.deleteAllConversations();
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

// ── Backend preference ──

final chatBackendPreferenceStorageProvider =
    FutureProvider<ChatBackendPreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ChatBackendPreferenceStorage(prefs);
});

class ChatBackendPreferenceNotifier
    extends AsyncNotifier<ChatBackendPreference> {
  @override
  Future<ChatBackendPreference> build() async {
    final storage =
        await ref.watch(chatBackendPreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(ChatBackendPreference backend) async {
    final storage =
        await ref.read(chatBackendPreferenceStorageProvider.future);
    state = const AsyncValue<ChatBackendPreference>.loading()
        .copyWithPrevious(state);
    try {
      await storage.write(backend);
      state = AsyncValue.data(backend);
    } catch (error, stack) {
      state = AsyncValue<ChatBackendPreference>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final chatBackendPreferenceProvider =
    AsyncNotifierProvider<ChatBackendPreferenceNotifier,
        ChatBackendPreference>(
  ChatBackendPreferenceNotifier.new,
);

// ── Reasoning preference ──

final chatReasoningPreferenceStorageProvider =
    FutureProvider<ReasoningPreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ReasoningPreferenceStorage(prefs);
});

class ChatReasoningPreferenceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage =
        await ref.watch(chatReasoningPreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(bool enabled) async {
    final storage =
        await ref.read(chatReasoningPreferenceStorageProvider.future);
    state = const AsyncValue<bool>.loading().copyWithPrevious(state);
    try {
      await storage.write(enabled);
      state = AsyncValue.data(enabled);
    } catch (error, stack) {
      state =
          AsyncValue<bool>.error(error, stack).copyWithPrevious(state);
      rethrow;
    }
  }
}

final chatReasoningPreferenceProvider =
    AsyncNotifierProvider<ChatReasoningPreferenceNotifier, bool>(
  ChatReasoningPreferenceNotifier.new,
);

// ── Expert config ──

final chatExpertConfigStorageProvider =
    FutureProvider<ExpertConfigStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ExpertConfigStorage(prefs);
});

class ChatExpertConfigNotifier extends AsyncNotifier<ExpertConfig> {
  @override
  Future<ExpertConfig> build() async {
    final storage =
        await ref.watch(chatExpertConfigStorageProvider.future);
    return storage.read();
  }

  Future<void> setConfig(ExpertConfig config) async {
    final storage =
        await ref.read(chatExpertConfigStorageProvider.future);
    state = const AsyncValue<ExpertConfig>.loading().copyWithPrevious(state);
    try {
      await storage.write(config);
      state = AsyncValue.data(config);
    } catch (error, stack) {
      state = AsyncValue<ExpertConfig>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final chatExpertConfigProvider =
    AsyncNotifierProvider<ChatExpertConfigNotifier, ExpertConfig>(
  ChatExpertConfigNotifier.new,
);

// ── Model service ──

final chatModelServiceProvider = FutureProvider<ChatModelService>((ref) async {
  final modelStorage =
      await ref.watch(chatModelPreferenceStorageProvider.future);
  final backendStorage =
      await ref.watch(chatBackendPreferenceStorageProvider.future);
  return ChatModelService(
    modelStorage: modelStorage,
    backendStorage: backendStorage,
  );
});
