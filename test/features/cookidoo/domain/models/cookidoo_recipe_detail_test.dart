import 'package:cookmate/features/cookidoo/domain/models/cookidoo_recipe_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Ingredient.fromJson', () {
    test('parses all fields', () {
      final json = {
        'ingredientNotation': 'Chicken breast',
        'quantity': {'value': 300},
        'unitNotation': 'g',
      };

      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.name, 'Chicken breast');
      expect(ingredient.quantity, 300.0);
      expect(ingredient.unit, 'g');
    });

    test('defaults to empty/zero when fields are missing', () {
      final ingredient = Ingredient.fromJson({});

      expect(ingredient.name, '');
      expect(ingredient.quantity, 0.0);
      expect(ingredient.unit, '');
    });

    test('handles null quantity gracefully', () {
      final json = {
        'ingredientNotation': 'Salt',
        'quantity': null,
        'unitNotation': 'pinch',
      };

      final ingredient = Ingredient.fromJson(json);

      expect(ingredient.quantity, 0.0);
    });
  });

  group('IngredientGroup.fromJson', () {
    test('parses title and ingredients', () {
      final json = {
        'title': 'Main ingredients',
        'recipeIngredients': [
          {
            'ingredientNotation': 'Onion',
            'quantity': {'value': 1},
            'unitNotation': 'piece',
          },
        ],
      };

      final group = IngredientGroup.fromJson(json);

      expect(group.title, 'Main ingredients');
      expect(group.ingredients, hasLength(1));
      expect(group.ingredients[0].name, 'Onion');
    });

    test('returns empty list when recipeIngredients is absent', () {
      final group = IngredientGroup.fromJson({'title': 'Sauce'});

      expect(group.ingredients, isEmpty);
    });

    test('defaults title to empty string when missing', () {
      final group = IngredientGroup.fromJson({});

      expect(group.title, '');
    });
  });

  group('RecipeStep.fromJson', () {
    test('parses title and formattedText', () {
      final json = {
        'title': 'Step 1',
        'formattedText': 'Chop the onions finely.',
      };

      final step = RecipeStep.fromJson(json);

      expect(step.title, 'Step 1');
      expect(step.text, 'Chop the onions finely.');
    });

    test('defaults to empty strings when fields are missing', () {
      final step = RecipeStep.fromJson({});

      expect(step.title, '');
      expect(step.text, '');
    });
  });

  group('StepGroup.fromJson', () {
    test('parses title and steps', () {
      final json = {
        'title': 'Preparation',
        'recipeSteps': [
          {'title': 'Step 1', 'formattedText': 'Preheat oven.'},
        ],
      };

      final group = StepGroup.fromJson(json);

      expect(group.title, 'Preparation');
      expect(group.steps, hasLength(1));
      expect(group.steps[0].title, 'Step 1');
    });

    test('returns empty steps when recipeSteps is absent', () {
      final group = StepGroup.fromJson({});

      expect(group.steps, isEmpty);
    });
  });

  group('NutritionInfo.fromJson', () {
    test('extracts kcal, protein, fat and carbohydrates from nested structure', () {
      final nutritionGroups = [
        {
          'recipeNutritions': [
            {
              'nutritions': [
                {'type': 'kcal', 'number': 350},
                {'type': 'protein', 'number': 25.5},
                {'type': 'fat', 'number': 12.0},
                {'type': 'carbohydrates', 'number': 40.0},
              ],
            },
          ],
        },
      ];

      final nutrition = NutritionInfo.fromJson(nutritionGroups);

      expect(nutrition.calories, 350.0);
      expect(nutrition.protein, 25.5);
      expect(nutrition.fat, 12.0);
      expect(nutrition.carbs, 40.0);
    });

    test('returns zeros when groups are empty', () {
      final nutrition = NutritionInfo.fromJson([]);

      expect(nutrition.calories, 0.0);
      expect(nutrition.protein, 0.0);
      expect(nutrition.fat, 0.0);
      expect(nutrition.carbs, 0.0);
    });

    test('ignores unknown nutrition types', () {
      final nutritionGroups = [
        {
          'recipeNutritions': [
            {
              'nutritions': [
                {'type': 'unknown_type', 'number': 999},
                {'type': 'kcal', 'number': 200},
              ],
            },
          ],
        },
      ];

      final nutrition = NutritionInfo.fromJson(nutritionGroups);

      expect(nutrition.calories, 200.0);
      expect(nutrition.protein, 0.0);
    });
  });

  group('CookidooRecipeDetail.fromJson', () {
    Map<String, dynamic> fullJson() => {
          'id': 'r145192',
          'title': 'Bolognese',
          'aggregateRating': {'ratingValue': 4.7},
          'times': [
            {
              'type': 'totalTime',
              'quantity': {'value': 3600},
            },
          ],
          'image': 'https://cdn.example.com/{transformation}/bolo.jpg',
          'servingSize': {
            'quantity': {'value': 4},
            'unitNotation': 'servings',
          },
          'recipeIngredientGroups': [
            {
              'title': 'Meat sauce',
              'recipeIngredients': [
                {
                  'ingredientNotation': 'Ground beef',
                  'quantity': {'value': 500},
                  'unitNotation': 'g',
                },
              ],
            },
          ],
          'recipeStepGroups': [
            {
              'title': 'Cooking',
              'recipeSteps': [
                {'title': 'Brown meat', 'formattedText': 'Brown the meat.'},
              ],
            },
          ],
          'nutritionGroups': [
            {
              'recipeNutritions': [
                {
                  'nutritions': [
                    {'type': 'kcal', 'number': 600},
                  ],
                },
              ],
            },
          ],
          'thermomixVersions': ['TM5', 'TM6'],
        };

    test('parses a complete recipe detail', () {
      final detail = CookidooRecipeDetail.fromJson(fullJson());

      expect(detail.id, 'r145192');
      expect(detail.title, 'Bolognese');
      expect(detail.rating, 4.7);
      expect(detail.totalTime, 3600);
      expect(detail.imageUrl,
          'https://cdn.example.com/t_web_rdp_recipe_584x480_1_5x/bolo.jpg');
      expect(detail.servingSize, '4 servings');
      expect(detail.ingredientGroups, hasLength(1));
      expect(detail.stepGroups, hasLength(1));
      expect(detail.nutrition, isNotNull);
      expect(detail.nutrition!.calories, 600.0);
      expect(detail.thermomixVersions, ['TM5', 'TM6']);
    });

    test('image transformation is applied', () {
      final detail = CookidooRecipeDetail.fromJson(fullJson());
      expect(detail.imageUrl, contains('t_web_rdp_recipe_584x480_1_5x'));
      expect(detail.imageUrl, isNot(contains('{transformation}')));
    });

    test('falls back to rating field when aggregateRating is absent', () {
      final json = fullJson()
        ..remove('aggregateRating')
        ..['rating'] = 3.8;

      final detail = CookidooRecipeDetail.fromJson(json);

      expect(detail.rating, 3.8);
    });

    test('falls back to totalTime field when times array is absent', () {
      final json = fullJson()
        ..remove('times')
        ..['totalTime'] = 1800;

      final detail = CookidooRecipeDetail.fromJson(json);

      expect(detail.totalTime, 1800);
    });

    test('uses descriptiveAssets for image when image field is absent', () {
      final json = fullJson()..remove('image');
      json['descriptiveAssets'] = [
        {'square': 'https://cdn.example.com/{transformation}/square.jpg'},
      ];

      final detail = CookidooRecipeDetail.fromJson(json);

      expect(detail.imageUrl, contains('t_web_rdp_recipe_584x480_1_5x'));
      expect(detail.imageUrl, contains('square.jpg'));
    });

    test('nutrition is null when nutritionGroups is absent', () {
      final json = fullJson()..remove('nutritionGroups');

      final detail = CookidooRecipeDetail.fromJson(json);

      expect(detail.nutrition, isNull);
    });

    test('nutrition is null when nutritionGroups is empty', () {
      final json = fullJson();
      json['nutritionGroups'] = <dynamic>[];

      final detail = CookidooRecipeDetail.fromJson(json);

      expect(detail.nutrition, isNull);
    });

    test('empty lists when ingredient/step groups are absent', () {
      final json = fullJson()
        ..remove('recipeIngredientGroups')
        ..remove('recipeStepGroups');

      final detail = CookidooRecipeDetail.fromJson(json);

      expect(detail.ingredientGroups, isEmpty);
      expect(detail.stepGroups, isEmpty);
    });

    test('servingSize is trimmed when unit is absent', () {
      final json = fullJson();
      json['servingSize'] = {'quantity': null, 'unitNotation': null};

      final detail = CookidooRecipeDetail.fromJson(json);

      expect(detail.servingSize, '');
    });
  });
}
