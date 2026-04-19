enum TmVersion {
  tm5,
  tm6,
  tm7;

  static const TmVersion defaultValue = TmVersion.tm6;

  String toStorageValue() => name;

  static TmVersion fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) return defaultValue;
    for (final v in TmVersion.values) {
      if (v.name == raw) return v;
    }
    return defaultValue;
  }
}
