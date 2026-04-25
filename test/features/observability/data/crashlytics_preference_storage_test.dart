import 'package:cookmate/features/observability/data/crashlytics_preference_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CrashlyticsPreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = CrashlyticsPreferenceStorage(prefs);
  });

  test('read returns true when nothing is stored', () {
    expect(storage.read(), true);
  });

  test('write then read returns the written value', () async {
    await storage.write(true);
    expect(storage.read(), true);
  });

  test('write overwrites a previous value', () async {
    await storage.write(true);
    await storage.write(false);
    expect(storage.read(), false);
  });

  test('read returns true when stored value is corrupted', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'observability_crashlytics_enabled': 'not_a_bool',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = CrashlyticsPreferenceStorage(prefs);
    expect(s.read(), true);
  });
}
