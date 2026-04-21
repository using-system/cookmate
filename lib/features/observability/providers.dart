import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/crashlytics_preference_storage.dart';

final crashlyticsPreferenceStorageProvider =
    FutureProvider<CrashlyticsPreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return CrashlyticsPreferenceStorage(prefs);
});

class CrashlyticsPreferenceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage =
        await ref.watch(crashlyticsPreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(bool enabled) async {
    final storage =
        await ref.read(crashlyticsPreferenceStorageProvider.future);
    state = const AsyncValue<bool>.loading().copyWithPrevious(state);
    try {
      await storage.write(enabled);
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(enabled);
      }
      state = AsyncValue.data(enabled);
    } catch (error, stack) {
      state =
          AsyncValue<bool>.error(error, stack).copyWithPrevious(state);
      rethrow;
    }
  }
}

final crashlyticsPreferenceProvider =
    AsyncNotifierProvider<CrashlyticsPreferenceNotifier, bool>(
  CrashlyticsPreferenceNotifier.new,
);
