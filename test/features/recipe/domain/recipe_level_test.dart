import 'package:cookmate/features/recipe/domain/recipe_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeLevel', () {
    test('defaultValue is allLevels', () {
      expect(RecipeLevel.defaultValue, RecipeLevel.allLevels);
    });

    test('toStorageValue returns enum name', () {
      expect(RecipeLevel.beginner.toStorageValue(), 'beginner');
      expect(RecipeLevel.intermediate.toStorageValue(), 'intermediate');
      expect(RecipeLevel.advanced.toStorageValue(), 'advanced');
      expect(RecipeLevel.allLevels.toStorageValue(), 'allLevels');
    });

    test('fromStorageValue returns matching enum value', () {
      expect(RecipeLevel.fromStorageValue('beginner'), RecipeLevel.beginner);
      expect(RecipeLevel.fromStorageValue('intermediate'), RecipeLevel.intermediate);
      expect(RecipeLevel.fromStorageValue('advanced'), RecipeLevel.advanced);
      expect(RecipeLevel.fromStorageValue('allLevels'), RecipeLevel.allLevels);
    });

    test('fromStorageValue returns default for null', () {
      expect(RecipeLevel.fromStorageValue(null), RecipeLevel.defaultValue);
    });

    test('fromStorageValue returns default for empty string', () {
      expect(RecipeLevel.fromStorageValue(''), RecipeLevel.defaultValue);
    });

    test('fromStorageValue returns default for unknown value', () {
      expect(RecipeLevel.fromStorageValue('expert'), RecipeLevel.defaultValue);
    });

    test('toStorageValue and fromStorageValue roundtrip for all values', () {
      for (final v in RecipeLevel.values) {
        expect(RecipeLevel.fromStorageValue(v.toStorageValue()), v);
      }
    });
  });
}
