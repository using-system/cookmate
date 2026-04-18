import 'package:cookmate/features/theme/data/theme_preference_storage.dart';
import 'package:cookmate/features/theme/domain/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemePreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = ThemePreferenceStorage(prefs);
  });

  test('read returns AppTheme.dark when nothing is stored', () {
    expect(storage.read(), AppTheme.dark);
  });

  test('read returns the stored theme for every known value', () async {
    for (final theme in AppTheme.values) {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_preference': theme.name,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = ThemePreferenceStorage(prefs);

      expect(storage.read(), theme);
    }
  });

  test('read returns AppTheme.dark when stored value is unknown', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_preference': 'rainbow',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = ThemePreferenceStorage(prefs);

    expect(storage.read(), AppTheme.dark);
  });

  test('write then read returns the written theme', () async {
    await storage.write(AppTheme.matrix);

    expect(storage.read(), AppTheme.matrix);
  });

  test('write overwrites a previous value', () async {
    await storage.write(AppTheme.pink);
    await storage.write(AppTheme.standard);

    expect(storage.read(), AppTheme.standard);
  });
}
