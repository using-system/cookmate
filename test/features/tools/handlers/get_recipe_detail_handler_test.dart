import 'package:cookmate/features/cookidoo/domain/cookidoo_repository.dart';
import 'package:cookmate/features/cookidoo/domain/models/cookidoo_exceptions.dart';
import 'package:cookmate/features/cookidoo/domain/models/cookidoo_recipe_detail.dart';
import 'package:cookmate/features/cookidoo/domain/models/cookidoo_recipe_overview.dart';
import 'package:cookmate/features/tools/handlers/get_recipe_detail_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBuildContext extends Fake implements BuildContext {}

class _SuccessRepository implements CookidooRepository {
  @override
  Future<CookidooRecipeDetail> getRecipeDetail(String recipeId) async {
    return const CookidooRecipeDetail(
      id: 'r1',
      title: 'Spaghetti Bolognese',
      rating: 4.8,
      totalTime: 3600,
      imageUrl: '',
      servingSize: '4 servings',
      ingredientGroups: [
        IngredientGroup(
          title: 'Main',
          ingredients: [
            Ingredient(name: 'Ground beef', quantity: 500, unit: 'g'),
          ],
        ),
      ],
      stepGroups: [
        StepGroup(
          title: 'Cooking',
          steps: [
            RecipeStep(title: 'Brown', text: 'Brown the meat.'),
          ],
        ),
      ],
      nutrition: NutritionInfo(
        calories: 600,
        protein: 30,
        fat: 20,
        carbs: 50,
      ),
      thermomixVersions: ['TM6'],
    );
  }

  @override
  Future<List<CookidooRecipeOverview>> searchRecipes(String query,
      {int limit = 5}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isAuthenticated() async => true;
}

class _AuthExceptionRepository implements CookidooRepository {
  @override
  Future<CookidooRecipeDetail> getRecipeDetail(String recipeId) async {
    throw const CookidooAuthException('Cookidoo credentials not configured');
  }

  @override
  Future<List<CookidooRecipeOverview>> searchRecipes(String query,
      {int limit = 5}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isAuthenticated() async => false;
}

class _NotFoundRepository implements CookidooRepository {
  @override
  Future<CookidooRecipeDetail> getRecipeDetail(String recipeId) async {
    throw CookidooNotFoundException(recipeId);
  }

  @override
  Future<List<CookidooRecipeOverview>> searchRecipes(String query,
      {int limit = 5}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isAuthenticated() async => false;
}

void main() {
  group('GetRecipeDetailHandler definition', () {
    test('has name "get_recipe_detail"', () {
      final handler = GetRecipeDetailHandler(_SuccessRepository());
      expect(handler.definition.name, 'get_recipe_detail');
    });

    test('has required parameter "recipe_id"', () {
      final handler = GetRecipeDetailHandler(_SuccessRepository());
      final required = handler.definition.parameters['required'] as List;
      expect(required, contains('recipe_id'));
    });

    test('parameters include recipe_id property', () {
      final handler = GetRecipeDetailHandler(_SuccessRepository());
      final properties =
          handler.definition.parameters['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('recipe_id'), isTrue);
    });
  });

  group('GetRecipeDetailHandler.execute', () {
    test('returns recipe details on success', () async {
      final handler = GetRecipeDetailHandler(_SuccessRepository());
      final result = await handler.execute(
          {'recipe_id': 'r1'}, _FakeBuildContext());

      expect(result, isNotNull);
      expect(result!['title'], 'Spaghetti Bolognese');
      expect(result['servingSize'], '4 servings');
      expect(result['rating'], 4.8);
      expect(result['thermomixVersions'], ['TM6']);
    });

    test('flattens ingredients from all groups', () async {
      final handler = GetRecipeDetailHandler(_SuccessRepository());
      final result =
          await handler.execute({'recipe_id': 'r1'}, _FakeBuildContext());

      final ingredients = result!['ingredients'] as List;
      expect(ingredients, hasLength(1));
      expect(ingredients[0], contains('Ground beef'));
    });

    test('flattens steps from all groups', () async {
      final handler = GetRecipeDetailHandler(_SuccessRepository());
      final result =
          await handler.execute({'recipe_id': 'r1'}, _FakeBuildContext());

      final steps = result!['steps'] as List;
      expect(steps, hasLength(1));
      expect(steps[0], contains('Brown'));
    });

    test('includes nutrition when present', () async {
      final handler = GetRecipeDetailHandler(_SuccessRepository());
      final result =
          await handler.execute({'recipe_id': 'r1'}, _FakeBuildContext());

      expect(result!.containsKey('nutrition'), isTrue);
      final nutrition = result['nutrition'] as Map<String, dynamic>;
      expect(nutrition['calories'], 600.0);
    });

    test('totalTimeMinutes is totalTime ~/ 60', () async {
      final handler = GetRecipeDetailHandler(_SuccessRepository());
      final result =
          await handler.execute({'recipe_id': 'r1'}, _FakeBuildContext());

      expect(result!['totalTimeMinutes'], 60);
    });

    test('returns error when credentials not configured', () async {
      final handler = GetRecipeDetailHandler(_AuthExceptionRepository());
      final result =
          await handler.execute({'recipe_id': 'r1'}, _FakeBuildContext());

      expect(result!['error'], contains('credentials'));
    });

    test('returns error when recipe is not found', () async {
      final handler = GetRecipeDetailHandler(_NotFoundRepository());
      final result =
          await handler.execute({'recipe_id': 'r999'}, _FakeBuildContext());

      expect(result!['error'], contains('r999'));
    });
  });
}
