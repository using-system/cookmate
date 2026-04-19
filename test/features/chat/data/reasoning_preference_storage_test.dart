import 'package:cookmate/features/chat/data/reasoning_preference_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReasoningPreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = ReasoningPreferenceStorage(prefs);
  });

  test('read returns true when nothing is stored', () {
    expect(storage.read(), true);
  });

  test('write then read returns the written value', () async {
    await storage.write(false);
    expect(storage.read(), false);
  });

  test('write overwrites a previous value', () async {
    await storage.write(false);
    await storage.write(true);
    expect(storage.read(), true);
  });

  test('read returns true when stored value is corrupted', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chat_reasoning_preference': 'not_a_bool',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = ReasoningPreferenceStorage(prefs);
    expect(s.read(), true);
  });
}
