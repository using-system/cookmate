import 'package:cookmate/core/theme.dart';
import 'package:cookmate/features/theme/domain/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildThemeData', () {
    test('returns a Material 3 ThemeData for every AppTheme', () {
      for (final theme in AppTheme.values) {
        final data = buildThemeData(theme);

        expect(data.useMaterial3, isTrue, reason: 'theme=$theme');
      }
    });

    test('Dark is dark', () {
      expect(buildThemeData(AppTheme.dark).brightness, Brightness.dark);
    });

    test('Standard is light', () {
      expect(buildThemeData(AppTheme.standard).brightness, Brightness.light);
    });

    test('Pink is light', () {
      expect(buildThemeData(AppTheme.pink).brightness, Brightness.light);
    });

    test('Matrix is dark with pure black scaffold and phosphor palette', () {
      final data = buildThemeData(AppTheme.matrix);

      expect(data.brightness, Brightness.dark);
      expect(data.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(data.colorScheme.primary, const Color(0xFF00FF41));
      expect(data.colorScheme.onPrimary, const Color(0xFF000000));
      expect(data.colorScheme.secondary, const Color(0xFF39FF14));
      expect(data.colorScheme.onSecondary, const Color(0xFF000000));
      expect(data.colorScheme.surface, const Color(0xFF0A0F0A));
      expect(data.colorScheme.onSurface, const Color(0xFF39FF14));
      expect(data.colorScheme.error, const Color(0xFFFF5555));
      expect(data.colorScheme.onError, const Color(0xFF000000));
    });
  });
}
