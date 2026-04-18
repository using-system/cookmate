import 'package:cookmate/features/chat/data/chat_backend_preference_storage.dart';
import 'package:cookmate/features/chat/domain/chat_backend_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatBackendPreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = ChatBackendPreferenceStorage(prefs);
  });

  test('read returns gpu when nothing is stored', () {
    expect(storage.read(), ChatBackendPreference.gpu);
  });

  test('read returns the stored backend for every known value', () async {
    for (final backend in ChatBackendPreference.values) {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_backend_preference': backend.name,
      });
      final prefs = await SharedPreferences.getInstance();
      final s = ChatBackendPreferenceStorage(prefs);

      expect(s.read(), backend);
    }
  });

  test('read returns gpu when stored value is unknown', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chat_backend_preference': 'tpu',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = ChatBackendPreferenceStorage(prefs);

    expect(s.read(), ChatBackendPreference.gpu);
  });

  test('write then read returns the written backend', () async {
    await storage.write(ChatBackendPreference.cpu);

    expect(storage.read(), ChatBackendPreference.cpu);
  });

  test('write overwrites a previous value', () async {
    await storage.write(ChatBackendPreference.cpu);
    await storage.write(ChatBackendPreference.gpu);

    expect(storage.read(), ChatBackendPreference.gpu);
  });
}
