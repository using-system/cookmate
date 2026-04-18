import 'package:cookmate/core/theme.dart';
import 'package:cookmate/features/theme/domain/app_theme.dart';
import 'package:cookmate/features/theme/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('themePreferenceProvider', () {
    test('builds with AppTheme.dark when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final value = await container.read(themePreferenceProvider.future);

      expect(value, AppTheme.dark);
    });

    test('builds with the stored theme when one exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_preference': 'matrix',
      });
      final container = createContainer();

      final value = await container.read(themePreferenceProvider.future);

      expect(value, AppTheme.matrix);
    });

    test('setPreference updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(themePreferenceProvider.future);

      await container
          .read(themePreferenceProvider.notifier)
          .setPreference(AppTheme.pink);

      expect(
        container.read(themePreferenceProvider).valueOrNull,
        AppTheme.pink,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_preference'), 'pink');
    });
  });

  group('themeDataProvider', () {
    test('returns the default theme while preference is loading', () {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final data = container.read(themeDataProvider);

      expect(data.brightness, Brightness.dark);
      expect(
        data.colorScheme.primary,
        buildThemeData(AppTheme.defaultTheme).colorScheme.primary,
      );
    });

    test('returns the stored theme once loaded', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_preference': 'standard',
      });
      final container = createContainer();
      await container.read(themePreferenceProvider.future);

      final data = container.read(themeDataProvider);

      expect(data.brightness, Brightness.light);
      expect(
        data.colorScheme.primary,
        buildThemeData(AppTheme.standard).colorScheme.primary,
      );
    });

    test('rebuilds when preference changes', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(themePreferenceProvider.future);

      await container
          .read(themePreferenceProvider.notifier)
          .setPreference(AppTheme.matrix);

      final data = container.read(themeDataProvider);
      expect(data.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(data.colorScheme.primary, const Color(0xFF00FF41));
    });
  });
}
