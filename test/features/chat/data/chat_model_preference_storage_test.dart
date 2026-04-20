import 'package:cookmate/features/chat/data/chat_model_preference_storage.dart';
import 'package:cookmate/features/chat/domain/chat_model_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatModelPreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = ChatModelPreferenceStorage(prefs);
  });

  test('read returns gemma4E4B when nothing is stored', () {
    expect(storage.read(), ChatModelPreference.gemma4E4B);
  });

  test('read returns the stored model for every known value', () async {
    for (final model in ChatModelPreference.values) {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_model_preference': model.name,
      });
      final prefs = await SharedPreferences.getInstance();
      final s = ChatModelPreferenceStorage(prefs);

      expect(s.read(), model);
    }
  });

  test('read returns gemma4E4B when stored value is unknown', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chat_model_preference': 'gemma99',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = ChatModelPreferenceStorage(prefs);

    expect(s.read(), ChatModelPreference.gemma4E4B);
  });

  test('write then read returns the written model', () async {
    await storage.write(ChatModelPreference.gemma4E4B);

    expect(storage.read(), ChatModelPreference.gemma4E4B);
  });

  test('write overwrites a previous value', () async {
    await storage.write(ChatModelPreference.gemma4E4B);
    await storage.write(ChatModelPreference.gemma4E2B);

    expect(storage.read(), ChatModelPreference.gemma4E2B);
  });

  test('readInstalled returns null when nothing is stored', () {
    expect(storage.readInstalled(), isNull);
  });

  test('writeInstalled then readInstalled returns the written model', () async {
    await storage.writeInstalled(ChatModelPreference.gemma4E4B);

    expect(storage.readInstalled(), ChatModelPreference.gemma4E4B);
  });

  test('readInstalled returns null for unknown stored value', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chat_model_installed': 'gemma99',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = ChatModelPreferenceStorage(prefs);

    expect(s.readInstalled(), isNull);
  });

  test('clearInstalled removes the installed model', () async {
    await storage.writeInstalled(ChatModelPreference.gemma4E4B);
    await storage.clearInstalled();

    expect(storage.readInstalled(), isNull);
  });
}
