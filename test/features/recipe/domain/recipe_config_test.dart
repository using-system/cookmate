import 'package:cookmate/features/recipe/domain/recipe_config.dart';
import 'package:cookmate/features/recipe/domain/recipe_level.dart';
import 'package:cookmate/features/recipe/domain/tm_version.dart';
import 'package:cookmate/features/recipe/domain/unit_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeConfig', () {
    test('default values match spec', () {
      const config = RecipeConfig();
      expect(config.tmVersion, TmVersion.defaultValue);
      expect(config.unitSystem, UnitSystem.defaultValue);
      expect(config.portions, RecipeConfig.defaultPortions);
      expect(config.level, RecipeLevel.defaultValue);
      expect(config.dietaryRestrictions, '');
    });

    test('defaultPortions is 4', () {
      expect(RecipeConfig.defaultPortions, 4);
    });

    test('copyWith replaces only specified fields', () {
      const config = RecipeConfig();
      final modified = config.copyWith(
        tmVersion: TmVersion.tm7,
        portions: 6,
      );
      expect(modified.tmVersion, TmVersion.tm7);
      expect(modified.unitSystem, UnitSystem.defaultValue);
      expect(modified.portions, 6);
      expect(modified.level, RecipeLevel.defaultValue);
      expect(modified.dietaryRestrictions, '');
    });

    test('copyWith with no arguments returns equal config', () {
      const config = RecipeConfig(
        tmVersion: TmVersion.tm5,
        unitSystem: UnitSystem.imperial,
        portions: 8,
        level: RecipeLevel.advanced,
        dietaryRestrictions: 'vegan',
      );
      final copy = config.copyWith();
      expect(copy, equals(config));
    });

    test('equality holds for identical values', () {
      const a = RecipeConfig();
      const b = RecipeConfig();
      expect(a, equals(b));
    });

    test('hashCode matches for equal configs', () {
      const a = RecipeConfig();
      const b = RecipeConfig();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality fails when fields differ', () {
      const a = RecipeConfig();
      final b = a.copyWith(tmVersion: TmVersion.tm5);
      expect(a, isNot(equals(b)));
    });

    test('hashCode differs for non-equal configs', () {
      const a = RecipeConfig();
      final b = a.copyWith(unitSystem: UnitSystem.imperial);
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('equality covers all fields', () {
      const base = RecipeConfig();
      expect(base, isNot(equals(base.copyWith(tmVersion: TmVersion.tm5))));
      expect(base, isNot(equals(base.copyWith(unitSystem: UnitSystem.imperial))));
      expect(base, isNot(equals(base.copyWith(portions: 8))));
      expect(base, isNot(equals(base.copyWith(level: RecipeLevel.beginner))));
      expect(base, isNot(equals(base.copyWith(dietaryRestrictions: 'gluten-free'))));
    });
  });
}
