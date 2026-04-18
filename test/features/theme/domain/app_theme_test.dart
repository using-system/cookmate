import 'package:cookmate/features/theme/domain/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme.defaultTheme', () {
    test('is AppTheme.dark', () {
      expect(AppTheme.defaultTheme, AppTheme.dark);
    });

    test('is the first value declared on the enum', () {
      expect(AppTheme.values.first, AppTheme.defaultTheme);
    });
  });

  group('AppTheme.toStorageValue', () {
    test('serializes every variant to its enum name', () {
      for (final theme in AppTheme.values) {
        expect(theme.toStorageValue(), theme.name);
      }
    });
  });

  group('AppTheme.fromStorageValue', () {
    test('parses every known enum name back to its value', () {
      for (final theme in AppTheme.values) {
        expect(AppTheme.fromStorageValue(theme.name), theme);
      }
    });

    test('returns defaultTheme when raw is null', () {
      expect(AppTheme.fromStorageValue(null), AppTheme.defaultTheme);
    });

    test('returns defaultTheme when raw is empty', () {
      expect(AppTheme.fromStorageValue(''), AppTheme.defaultTheme);
    });

    test('returns defaultTheme when raw is unknown', () {
      expect(AppTheme.fromStorageValue('rainbow'), AppTheme.defaultTheme);
    });
  });
}
