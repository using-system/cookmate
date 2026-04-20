import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReasoningPreferenceStorage {
  ReasoningPreferenceStorage(this._prefs);

  static const _key = 'chat_reasoning_preference';

  final SharedPreferences _prefs;

  bool read() {
    try {
      return _prefs.getBool(_key) ?? false;
    } catch (error, stack) {
      debugPrint('Failed to read reasoning preference: $error\n$stack');
      return false;
    }
  }

  Future<void> write(bool enabled) async {
    final didWrite = await _prefs.setBool(_key, enabled);
    if (!didWrite) {
      throw Exception('Failed to persist reasoning preference.');
    }
  }
}
