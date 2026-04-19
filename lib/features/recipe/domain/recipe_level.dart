enum RecipeLevel {
  beginner,
  intermediate,
  advanced,
  allLevels;

  static const RecipeLevel defaultValue = RecipeLevel.allLevels;

  String toStorageValue() => name;

  static RecipeLevel fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) return defaultValue;
    for (final v in RecipeLevel.values) {
      if (v.name == raw) return v;
    }
    return defaultValue;
  }
}
