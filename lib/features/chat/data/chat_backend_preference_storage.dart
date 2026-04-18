import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/chat_backend_preference.dart';

class ChatBackendPreferenceStorage {
  ChatBackendPreferenceStorage(this._prefs);

  static const _key = 'chat_backend_preference';

  final SharedPreferences _prefs;

  ChatBackendPreference read() {
    try {
      return ChatBackendPreference.fromStorageValue(_prefs.getString(_key));
    } catch (error, stack) {
      debugPrint('Failed to read chat backend preference: $error\n$stack');
      return ChatBackendPreference.defaultBackend;
    }
  }

  Future<void> write(ChatBackendPreference backend) async {
    final didWrite = await _prefs.setString(_key, backend.toStorageValue());
    if (!didWrite) {
      throw Exception('Failed to persist chat backend preference.');
    }
  }
}
