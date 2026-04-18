import 'package:flutter/material.dart';

import '../features/theme/domain/app_theme.dart';

ThemeData buildThemeData(AppTheme theme) {
  switch (theme) {
    case AppTheme.dark:
      return _buildDark();
    case AppTheme.standard:
      return _buildStandard();
    case AppTheme.pink:
      return _buildPink();
    case AppTheme.matrix:
      return _buildMatrix();
  }
}

ThemeData _buildDark() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

ThemeData _buildStandard() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      useMaterial3: true,
    );

ThemeData _buildPink() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEC407A)),
      useMaterial3: true,
    );

ThemeData _buildMatrix() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF00FF41),
    onPrimary: Color(0xFF000000),
    secondary: Color(0xFF39FF14),
    onSecondary: Color(0xFF000000),
    surface: Color(0xFF0A0F0A),
    onSurface: Color(0xFF39FF14),
    error: Color(0xFFFF5555),
    onError: Color(0xFF000000),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF000000),
    useMaterial3: true,
  );
}
