import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_theme.dart';

class ThemePreferenceStorage {
  ThemePreferenceStorage(this._prefs);

  static const _key = 'theme_preference';

  final SharedPreferences _prefs;

  AppTheme read() {
    try {
      return AppTheme.fromStorageValue(_prefs.getString(_key));
    } catch (error, stack) {
      debugPrint('Failed to read theme preference: $error\n$stack');
      return AppTheme.defaultTheme;
    }
  }

  Future<void> write(AppTheme theme) async {
    final didWrite = await _prefs.setString(_key, theme.toStorageValue());
    if (!didWrite) {
      throw Exception('Failed to persist theme preference.');
    }
  }
}
