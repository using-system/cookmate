import 'package:cookmate/features/chat/domain/chat_backend_preference.dart';
import 'package:cookmate/features/chat/domain/chat_model_preference.dart';
import 'package:cookmate/features/chat/providers.dart';
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

  group('chatModelPreferenceProvider', () {
    test('builds with gemma4E2B when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final value =
          await container.read(chatModelPreferenceProvider.future);

      expect(value, ChatModelPreference.gemma4E2B);
    });

    test('builds with the stored model when one exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_model_preference': 'gemma4E4B',
      });
      final container = createContainer();

      final value =
          await container.read(chatModelPreferenceProvider.future);

      expect(value, ChatModelPreference.gemma4E4B);
    });

    test('setPreference updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(chatModelPreferenceProvider.future);

      await container
          .read(chatModelPreferenceProvider.notifier)
          .setPreference(ChatModelPreference.gemma4E4B);

      expect(
        container.read(chatModelPreferenceProvider).valueOrNull,
        ChatModelPreference.gemma4E4B,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_model_preference'), 'gemma4E4B');
    });
  });

  group('chatBackendPreferenceProvider', () {
    test('builds with gpu when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final value =
          await container.read(chatBackendPreferenceProvider.future);

      expect(value, ChatBackendPreference.gpu);
    });

    test('builds with the stored backend when one exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_backend_preference': 'cpu',
      });
      final container = createContainer();

      final value =
          await container.read(chatBackendPreferenceProvider.future);

      expect(value, ChatBackendPreference.cpu);
    });

    test('setPreference updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(chatBackendPreferenceProvider.future);

      await container
          .read(chatBackendPreferenceProvider.notifier)
          .setPreference(ChatBackendPreference.cpu);

      expect(
        container.read(chatBackendPreferenceProvider).valueOrNull,
        ChatBackendPreference.cpu,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_backend_preference'), 'cpu');
    });
  });
}
