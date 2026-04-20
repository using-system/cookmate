import '../domain/cookidoo_repository.dart';
import '../domain/models/cookidoo_credentials.dart';
import '../domain/models/cookidoo_exceptions.dart';
import '../domain/models/cookidoo_recipe_detail.dart';
import '../domain/models/cookidoo_recipe_overview.dart';
import 'cookidoo_client.dart';

class CookidooRepositoryImpl implements CookidooRepository {
  CookidooRepositoryImpl({
    required this.client,
    required this.locale,
    this.credentials,
  });

  final CookidooClient client;
  final String locale;
  final CookidooCredentials? credentials;

  String get _lang => locale;
  String get _countryCode => CookidooClient.countryCodeFromLocale(locale);

  @override
  Future<List<CookidooRecipeOverview>> searchRecipes(
    String query, {
    int limit = 5,
  }) {
    return client.searchRecipes(
      query,
      lang: _lang,
      countryCode: _countryCode,
      limit: limit,
    );
  }

  @override
  Future<CookidooRecipeDetail> getRecipeDetail(String recipeId) {
    final creds = credentials;
    if (creds == null || creds.isEmpty) {
      throw const CookidooAuthException(
        'Cookidoo credentials not configured',
      );
    }
    return client.getRecipeDetail(
      recipeId,
      lang: _lang,
      countryCode: _countryCode,
      credentials: creds,
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    final creds = credentials;
    if (creds == null || creds.isEmpty) return false;
    try {
      await client.login(creds, countryCode: _countryCode);
      return true;
    } on CookidooAuthException {
      return false;
    }
  }
}
