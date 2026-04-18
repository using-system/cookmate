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
}
