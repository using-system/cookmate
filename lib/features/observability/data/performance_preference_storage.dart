import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PerformancePreferenceStorage {
  PerformancePreferenceStorage(this._prefs);

  static const _key = 'observability_performance_enabled';

  final SharedPreferences _prefs;

  bool read() {
    try {
      return _prefs.getBool(_key) ?? true;
    } catch (error, stack) {
      debugPrint('Failed to read performance preference: $error\n$stack');
      return true;
    }
  }

  Future<void> write(bool enabled) async {
    final didWrite = await _prefs.setBool(_key, enabled);
    if (!didWrite) {
      throw Exception('Failed to persist performance preference.');
    }
  }
}
