import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/locale_preference.dart';

class LocalePreferenceStorage {
  LocalePreferenceStorage(this._prefs);

  static const _key = 'locale_preference';

  final SharedPreferences _prefs;

  LocalePreference read() {
    try {
      return LocalePreference.fromStorageValue(_prefs.getString(_key));
    } catch (error, stack) {
      debugPrint('Failed to read locale preference: $error\n$stack');
      return const SystemLocalePreference();
    }
  }

  Future<void> write(LocalePreference preference) async {
    await _prefs.setString(_key, preference.toStorageValue());
  }
}
