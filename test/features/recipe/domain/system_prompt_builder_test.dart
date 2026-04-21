import 'package:cookmate/features/recipe/domain/recipe_config.dart';
import 'package:cookmate/features/recipe/domain/recipe_level.dart';
import 'package:cookmate/features/recipe/domain/system_prompt_builder.dart';
import 'package:cookmate/features/recipe/domain/tm_version.dart';
import 'package:cookmate/features/recipe/domain/unit_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildSystemPrompt', () {
    test('contains expected config values in output', () {
      const config = RecipeConfig(
        tmVersion: TmVersion.tm6,
        unitSystem: UnitSystem.metric,
        portions: 4,
        level: RecipeLevel.beginner,
        dietaryRestrictions: '',
      );

      final prompt = buildSystemPrompt(config: config, language: 'en');

      expect(prompt, contains('TM6'));
      expect(prompt, contains('metric'));
      expect(prompt, contains('4 servings'));
      expect(prompt, contains('beginner'));
    });

    test('uses "aucune" when dietary restrictions are empty', () {
      const config = RecipeConfig(dietaryRestrictions: '');
      final prompt = buildSystemPrompt(config: config, language: 'fr');
      expect(prompt, contains('aucune'));
    });

    test('includes dietary restrictions when provided', () {
      const config = RecipeConfig(dietaryRestrictions: 'gluten-free, vegan');
      final prompt = buildSystemPrompt(config: config, language: 'en');
      expect(prompt, contains('gluten-free, vegan'));
      expect(prompt, isNot(contains('aucune')));
    });

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
      // Should not throw and should not contain extra instructions.
      expect(prompt, isNotEmpty);
    });

    test('includes the language in output', () {
      const config = RecipeConfig();
      final prompt = buildSystemPrompt(config: config, language: 'de');
      expect(prompt, contains('de'));
    });

    test('tm version name is uppercased', () {
      const config = RecipeConfig(tmVersion: TmVersion.tm5);
      final prompt = buildSystemPrompt(config: config, language: 'en');
      expect(prompt, contains('TM5'));
    });

    test('portions value is reflected in prompt', () {
      const config = RecipeConfig(portions: 6);
      final prompt = buildSystemPrompt(config: config, language: 'en');
      expect(prompt, contains('6 servings'));
    });

    test('imperial unit system appears in prompt', () {
      const config = RecipeConfig(unitSystem: UnitSystem.imperial);
      final prompt = buildSystemPrompt(config: config, language: 'en');
      expect(prompt, contains('imperial'));
    });
  });
}
