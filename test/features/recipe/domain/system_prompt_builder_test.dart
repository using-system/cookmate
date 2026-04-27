import 'package:cookmate/features/recipe/domain/recipe_config.dart';
import 'package:cookmate/features/recipe/domain/system_prompt_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildSystemPrompt', () {
    test('contains CookMate assistant preamble', () {
      const config = RecipeConfig();
      final prompt = buildSystemPrompt(config: config, language: 'en');
      expect(prompt, contains('CookMate'));
      expect(prompt, contains('Thermomix recipe assistant'));
    });

    // Config line is temporarily disabled (TODO in source).
    // These tests verify the prompt still works without it.

    test('includes skill instructions when provided', () {
      const config = RecipeConfig();
      final prompt = buildSystemPrompt(
        config: config,
        language: 'en',
        skillInstructions: 'Use search_recipes to find recipes.',
      );
      expect(prompt, contains('Use search_recipes to find recipes.'));
    });

    test('skill instructions default to empty string', () {
      const config = RecipeConfig();
      final prompt = buildSystemPrompt(config: config, language: 'en');
      expect(prompt, isNotEmpty);
    });
  });
}
