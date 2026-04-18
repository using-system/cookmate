import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/locale_preference_storage.dart';
import 'domain/locale_preference.dart';

final localePreferenceStorageProvider =
    FutureProvider<LocalePreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LocalePreferenceStorage(prefs);
});

class LocalePreferenceNotifier extends AsyncNotifier<LocalePreference> {
  @override
  Future<LocalePreference> build() async {
    final storage = await ref.watch(localePreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(LocalePreference preference) async {
    final storage = await ref.read(localePreferenceStorageProvider.future);
    state = const AsyncValue<LocalePreference>.loading().copyWithPrevious(state);
    try {
      await storage.write(preference);
      state = AsyncValue.data(preference);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

final localePreferenceProvider =
    AsyncNotifierProvider<LocalePreferenceNotifier, LocalePreference>(
  LocalePreferenceNotifier.new,
);

final effectiveLocaleProvider = Provider<Locale?>((ref) {
  final value = ref.watch(localePreferenceProvider).valueOrNull;
  if (value == null) {
    return null;
  }
  return switch (value) {
    SystemLocalePreference() => null,
    ForcedLocalePreference(:final locale) => locale,
  };
});
