import 'package:cookmate/features/chat/data/chat_backend_preference_storage.dart';
import 'package:cookmate/features/chat/data/chat_model_preference_storage.dart';
import 'package:cookmate/features/chat/data/chat_model_service.dart';
import 'package:cookmate/features/chat/domain/chat_backend_preference.dart';
import 'package:cookmate/features/chat/domain/chat_model_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatModelPreferenceStorage modelStorage;
  late ChatBackendPreferenceStorage backendStorage;
  late ChatModelService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    modelStorage = ChatModelPreferenceStorage(prefs);
    backendStorage = ChatBackendPreferenceStorage(prefs);
    service = ChatModelService(
      modelStorage: modelStorage,
      backendStorage: backendStorage,
    );
  });

  group('switchModel', () {
    test('saves the new model preference', () async {
      await service.switchModel(ChatModelPreference.gemma4E4B);

      expect(modelStorage.read(), ChatModelPreference.gemma4E4B);
    });

    test('clears the installed flag', () async {
      await modelStorage.writeInstalled(ChatModelPreference.gemma4E2B);
      await service.switchModel(ChatModelPreference.gemma4E4B);

      expect(modelStorage.readInstalled(), isNull);
    });
  });

  group('switchBackend', () {
    test('saves the new backend preference', () async {
      await service.switchBackend(ChatBackendPreference.cpu);

      expect(backendStorage.read(), ChatBackendPreference.cpu);
    });
  });
}
