import 'package:cookmate/features/chat/domain/chat_model_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatModelPreference.defaultModel', () {
    test('is gemma4E4B', () {
      expect(ChatModelPreference.defaultModel, ChatModelPreference.gemma4E4B);
    });
  });

  group('ChatModelPreference.toStorageValue', () {
    test('serializes every variant to its enum name', () {
      for (final model in ChatModelPreference.values) {
        expect(model.toStorageValue(), model.name);
      }
    });
  });

  group('ChatModelPreference.fromStorageValue', () {
    test('parses every known enum name back to its value', () {
      for (final model in ChatModelPreference.values) {
        expect(ChatModelPreference.fromStorageValue(model.name), model);
      }
    });

    test('returns defaultModel when raw is null', () {
      expect(ChatModelPreference.fromStorageValue(null), ChatModelPreference.defaultModel);
    });

    test('returns defaultModel when raw is empty', () {
      expect(ChatModelPreference.fromStorageValue(''), ChatModelPreference.defaultModel);
    });

    test('returns defaultModel when raw is unknown', () {
      expect(ChatModelPreference.fromStorageValue('gemma99'), ChatModelPreference.defaultModel);
    });
  });
}
