import 'package:cookmate/features/chat/domain/chat_backend_preference.dart';
import 'package:cookmate/features/chat/domain/chat_model_preference.dart';
import 'package:cookmate/features/chat/domain/expert_config.dart';
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
    test('builds with gemma4E4B when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final value =
          await container.read(chatModelPreferenceProvider.future);

      expect(value, ChatModelPreference.gemma4E4B);
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

  group('isPreferredModelInstalledProvider', () {
    test('returns false when no model is installed', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final value =
          await container.read(isPreferredModelInstalledProvider.future);

      expect(value, false);
    });

    test('returns true when installed matches preferred', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_model_preference': 'gemma4E2B',
        'chat_model_installed': 'gemma4E2B',
      });
      final container = createContainer();

      final value =
          await container.read(isPreferredModelInstalledProvider.future);

      expect(value, true);
    });

    test('returns false when installed differs from preferred', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_model_preference': 'gemma4E4B',
        'chat_model_installed': 'gemma4E2B',
      });
      final container = createContainer();

      final value =
          await container.read(isPreferredModelInstalledProvider.future);

      expect(value, false);
    });
  });

  group('chatReasoningPreferenceProvider', () {
    test('builds with false when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      final value = await container.read(chatReasoningPreferenceProvider.future);
      expect(value, false);
    });

    test('builds with stored value when one exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_reasoning_preference': false,
      });
      final container = createContainer();
      final value = await container.read(chatReasoningPreferenceProvider.future);
      expect(value, false);
    });

    test('setPreference updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(chatReasoningPreferenceProvider.future);

      await container
          .read(chatReasoningPreferenceProvider.notifier)
          .setPreference(false);

      expect(
        container.read(chatReasoningPreferenceProvider).valueOrNull,
        false,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('chat_reasoning_preference'), false);
    });
  });

  group('chatExpertConfigProvider', () {
    test('builds with defaults when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      final value = await container.read(chatExpertConfigProvider.future);
      expect(value, const ExpertConfig());
    });

    test('builds with stored values when they exist', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'expert_max_tokens': 16000,
        'expert_top_k': 32,
        'expert_top_p': 0.8,
        'expert_temperature': 1.5,
      });
      final container = createContainer();
      final value = await container.read(chatExpertConfigProvider.future);
      expect(value.maxTokens, 16000);
      expect(value.topK, 32);
      expect(value.topP, 0.8);
      expect(value.temperature, 1.5);
    });

    test('setConfig updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(chatExpertConfigProvider.future);

      const newConfig = ExpertConfig(maxTokens: 4000, temperature: 0.5);
      await container
          .read(chatExpertConfigProvider.notifier)
          .setConfig(newConfig);

      expect(
        container.read(chatExpertConfigProvider).valueOrNull,
        newConfig,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('expert_max_tokens'), 4000);
      expect(prefs.getDouble('expert_temperature'), 0.5);
    });
  });
}
