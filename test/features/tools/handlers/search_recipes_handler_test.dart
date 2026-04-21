import 'package:cookmate/features/cookidoo/domain/cookidoo_repository.dart';
import 'package:cookmate/features/cookidoo/domain/models/cookidoo_recipe_detail.dart';
import 'package:cookmate/features/cookidoo/domain/models/cookidoo_recipe_overview.dart';
import 'package:cookmate/features/tools/handlers/search_recipes_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements CookidooRepository {
  List<CookidooRecipeOverview> results = [];
  String? lastQuery;
  int? lastLimit;

  @override
  Future<List<CookidooRecipeOverview>> searchRecipes(
    String query, {
    int limit = 5,
  }) async {
    lastQuery = query;
    lastLimit = limit;
    return results;
  }

  @override
  Future<CookidooRecipeDetail> getRecipeDetail(String recipeId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isAuthenticated() async => true;
}

class _FakeBuildContext extends Fake implements BuildContext {}

void main() {
  group('SearchRecipesHandler definition', () {
    test('has name "search_recipes"', () {
      final handler = SearchRecipesHandler(_FakeRepository());
      expect(handler.definition.name, 'search_recipes');
    });

    test('has required parameter "query"', () {
      final handler = SearchRecipesHandler(_FakeRepository());
      final required = handler.definition.parameters['required'] as List;
      expect(required, contains('query'));
    });

    test('has optional parameter "limit"', () {
      final handler = SearchRecipesHandler(_FakeRepository());
      final properties =
          handler.definition.parameters['properties'] as Map<String, dynamic>;
      expect(properties.containsKey('limit'), isTrue);
    });
  });

  group('SearchRecipesHandler.execute', () {
    test('returns recipes list under "recipes" key', () async {
      final repo = _FakeRepository()
        ..results = [
          const CookidooRecipeOverview(
            id: 'r1',
            title: 'Pasta',
            rating: 4.5,
            numberOfRatings: 20,
            totalTime: 1800,
            imageUrl: '',
          ),
        ];

      final handler = SearchRecipesHandler(repo);
      final result = await handler.execute(
        {'query': 'pasta', 'limit': 3},
        _FakeBuildContext(),
      );

      expect(result, isNotNull);
      expect(result!.containsKey('recipes'), isTrue);
      final recipes = result['recipes'] as List;
      expect(recipes, hasLength(1));
      expect(recipes[0]['id'], 'r1');
      expect(recipes[0]['title'], 'Pasta');
      expect(recipes[0]['rating'], 4.5);
    });

    test('totalTimeMinutes is computed as totalTime ~/ 60', () async {
      final repo = _FakeRepository()
        ..results = [
          const CookidooRecipeOverview(
            id: 'r1',
            title: 'Soup',
            rating: 0,
            numberOfRatings: 0,
            totalTime: 3600,
            imageUrl: '',
          ),
        ];

      final handler = SearchRecipesHandler(repo);
      final result = await handler.execute({'query': 'soup'}, _FakeBuildContext());

      final recipes = result!['recipes'] as List;
      expect(recipes[0]['totalTimeMinutes'], 60);
    });

    test('passes query and limit to repository', () async {
      final repo = _FakeRepository();
      final handler = SearchRecipesHandler(repo);

      await handler.execute({'query': 'risotto', 'limit': 10}, _FakeBuildContext());

      expect(repo.lastQuery, 'risotto');
      expect(repo.lastLimit, 10);
    });

    test('defaults limit to 5 when not provided', () async {
      final repo = _FakeRepository();
      final handler = SearchRecipesHandler(repo);

      await handler.execute({'query': 'cake'}, _FakeBuildContext());

      expect(repo.lastLimit, 5);
    });

    test('returns error key on network exception', () async {
      final repo = _FakeRepository();
      // Override to throw a network exception.
      final handler = SearchRecipesHandler(_ThrowingRepository());

      final result = await handler.execute({'query': 'anything'}, _FakeBuildContext());

      expect(result, isNotNull);
      expect(result!.containsKey('error'), isTrue);
    });

    test('returns empty recipes list when repository returns no results', () async {
      final repo = _FakeRepository();
      final handler = SearchRecipesHandler(repo);

      final result =
          await handler.execute({'query': 'xyz_no_results'}, _FakeBuildContext());

      final recipes = result!['recipes'] as List;
      expect(recipes, isEmpty);
    });
  });
}

class _ThrowingRepository implements CookidooRepository {
  @override
  Future<List<CookidooRecipeOverview>> searchRecipes(String query,
      {int limit = 5}) async {
    throw Exception('network error');
  }

  @override
  Future<CookidooRecipeDetail> getRecipeDetail(String recipeId) {
    throw UnimplementedError();
  }

  @override
  Future<bool> isAuthenticated() async => false;
}
