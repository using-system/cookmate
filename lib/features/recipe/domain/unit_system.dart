enum UnitSystem {
  metric,
  imperial;

  static const UnitSystem defaultValue = UnitSystem.metric;

  String toStorageValue() => name;

  static UnitSystem fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) return defaultValue;
    for (final v in UnitSystem.values) {
      if (v.name == raw) return v;
    }
    return defaultValue;
  }
}
