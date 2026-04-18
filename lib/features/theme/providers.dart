import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import '../../core/theme.dart';
import 'data/theme_preference_storage.dart';
import 'domain/app_theme.dart';

final themePreferenceStorageProvider =
    FutureProvider<ThemePreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ThemePreferenceStorage(prefs);
});

class ThemePreferenceNotifier extends AsyncNotifier<AppTheme> {
  @override
  Future<AppTheme> build() async {
    final storage = await ref.watch(themePreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(AppTheme theme) async {
    final storage = await ref.read(themePreferenceStorageProvider.future);
    state = const AsyncValue<AppTheme>.loading().copyWithPrevious(state);
    try {
      await storage.write(theme);
      state = AsyncValue.data(theme);
    } catch (error, stack) {
      state = AsyncValue<AppTheme>.error(error, stack).copyWithPrevious(state);
      rethrow;
    }
  }
}

final themePreferenceProvider =
    AsyncNotifierProvider<ThemePreferenceNotifier, AppTheme>(
  ThemePreferenceNotifier.new,
);

final themeDataProvider = Provider<ThemeData>((ref) {
  final theme =
      ref.watch(themePreferenceProvider).valueOrNull ?? AppTheme.defaultTheme;
  return buildThemeData(theme);
});
