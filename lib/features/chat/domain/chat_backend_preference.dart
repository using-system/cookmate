enum ChatBackendPreference {
  gpu,
  cpu;

  static const ChatBackendPreference defaultBackend = ChatBackendPreference.gpu;

  String toStorageValue() => name;

  static ChatBackendPreference fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return defaultBackend;
    }
    for (final backend in ChatBackendPreference.values) {
      if (backend.name == raw) {
        return backend;
      }
    }
    return defaultBackend;
  }
}
