enum ChatModelPreference {
  gemma4E2B,
  gemma4E4B;

  static const ChatModelPreference defaultModel = ChatModelPreference.gemma4E2B;

  String toStorageValue() => name;

  static ChatModelPreference fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return defaultModel;
    }
    for (final model in ChatModelPreference.values) {
      if (model.name == raw) {
        return model;
      }
    }
    return defaultModel;
  }
}
