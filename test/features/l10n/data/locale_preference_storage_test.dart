import 'package:cookmate/features/l10n/data/locale_preference_storage.dart';
import 'package:cookmate/features/l10n/domain/locale_preference.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalePreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalePreferenceStorage(prefs);
  });

  test('read returns SystemLocalePreference when nothing is stored', () {
    expect(storage.read(), const SystemLocalePreference());
  });

  test('read returns SystemLocalePreference when stored value is "system"',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'locale_preference': 'system',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalePreferenceStorage(prefs);

    expect(storage.read(), const SystemLocalePreference());
  });

  test('read returns ForcedLocalePreference when stored value is a language code',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'locale_preference': 'fr',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalePreferenceStorage(prefs);

    expect(storage.read(), ForcedLocalePreference(const Locale('fr')));
  });

  test('write then read returns the forced preference', () async {
    await storage.write(ForcedLocalePreference(const Locale('es')));

    expect(storage.read(), ForcedLocalePreference(const Locale('es')));
  });

  test('write then read returns the system preference', () async {
    await storage.write(ForcedLocalePreference(const Locale('de')));
    await storage.write(const SystemLocalePreference());

    expect(storage.read(), const SystemLocalePreference());
  });
}
