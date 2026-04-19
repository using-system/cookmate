import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/recipe_config_storage.dart';
import 'domain/recipe_config.dart';

final recipeConfigStorageProvider =
    FutureProvider<RecipeConfigStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return RecipeConfigStorage(prefs);
});

class RecipeConfigNotifier extends AsyncNotifier<RecipeConfig> {
  @override
  Future<RecipeConfig> build() async {
    final storage = await ref.watch(recipeConfigStorageProvider.future);
    return storage.read();
  }

  Future<void> setConfig(RecipeConfig config) async {
    final storage = await ref.read(recipeConfigStorageProvider.future);
    state = const AsyncValue<RecipeConfig>.loading().copyWithPrevious(state);
    try {
      await storage.write(config);
      state = AsyncValue.data(config);
    } catch (error, stack) {
      state = AsyncValue<RecipeConfig>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final recipeConfigProvider =
    AsyncNotifierProvider<RecipeConfigNotifier, RecipeConfig>(
  RecipeConfigNotifier.new,
);
