import 'package:cookmate/features/chat/domain/expert_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpertConfig', () {
    test('default values match spec', () {
      const config = ExpertConfig();
      expect(config.maxTokens, 8000);
      expect(config.topK, 40);
      expect(config.topP, 0.9);
      expect(config.temperature, 0.8);
    });

    test('copyWith replaces only specified fields', () {
      const config = ExpertConfig();
      final modified = config.copyWith(maxTokens: 4000, temperature: 0.5);
      expect(modified.maxTokens, 4000);
      expect(modified.topK, 40);
      expect(modified.topP, 0.9);
      expect(modified.temperature, 0.5);
    });

    test('equality works for identical values', () {
      const a = ExpertConfig();
      const b = ExpertConfig();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality fails for different values', () {
      const a = ExpertConfig();
      final b = a.copyWith(topK: 10);
      expect(a, isNot(equals(b)));
    });
  });
}
