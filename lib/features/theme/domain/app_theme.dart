enum AppTheme {
  dark,
  standard,
  pink,
  matrix;

  static const AppTheme defaultTheme = AppTheme.dark;

  String toStorageValue() => name;

  static AppTheme fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return defaultTheme;
    }
    for (final theme in AppTheme.values) {
      if (theme.name == raw) {
        return theme;
      }
    }
    return defaultTheme;
  }
}
