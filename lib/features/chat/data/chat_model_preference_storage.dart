import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/chat_model_preference.dart';

class ChatModelPreferenceStorage {
  ChatModelPreferenceStorage(this._prefs);

  static const _key = 'chat_model_preference';

  final SharedPreferences _prefs;

  ChatModelPreference read() {
    try {
      return ChatModelPreference.fromStorageValue(_prefs.getString(_key));
    } catch (error, stack) {
      debugPrint('Failed to read chat model preference: $error\n$stack');
      return ChatModelPreference.defaultModel;
    }
  }

  Future<void> write(ChatModelPreference model) async {
    final didWrite = await _prefs.setString(_key, model.toStorageValue());
    if (!didWrite) {
      throw Exception('Failed to persist chat model preference.');
    }
  }
}
