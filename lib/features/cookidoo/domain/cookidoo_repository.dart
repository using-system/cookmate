import 'models/cookidoo_recipe_detail.dart';
import 'models/cookidoo_recipe_overview.dart';

abstract class CookidooRepository {
  Future<List<CookidooRecipeOverview>> searchRecipes(
    String query, {
    int limit = 5,
  });

  Future<CookidooRecipeDetail> getRecipeDetail(String recipeId);

  Future<bool> isAuthenticated();
}
