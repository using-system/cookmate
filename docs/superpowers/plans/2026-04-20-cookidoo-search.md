# Cookidoo Search Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate Cookidoo recipe search and detail APIs as a reusable service layer, expose it to the on-device LLM via function calling tools, and add credentials settings in the UI.

**Architecture:** A new `cookidoo` feature module with domain/data separation provides a `CookidooRepository` consumed by both a `ToolHandler` (for LLM integration) and future UI screens. The HTTP client handles OAuth2 auth transparently. A new skill tells the LLM when and how to search.

**Tech Stack:** Flutter, flutter_riverpod, http (new), shared_preferences, flutter_gemma (function calling)

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/features/cookidoo/domain/models/cookidoo_recipe_overview.dart` | Search result data model |
| Create | `lib/features/cookidoo/domain/models/cookidoo_recipe_detail.dart` | Full recipe data model (ingredients, steps, nutrition) |
| Create | `lib/features/cookidoo/domain/models/cookidoo_auth_token.dart` | OAuth2 token value object |
| Create | `lib/features/cookidoo/domain/models/cookidoo_credentials.dart` | User credentials value object |
| Create | `lib/features/cookidoo/domain/models/cookidoo_exceptions.dart` | Typed exceptions |
| Create | `lib/features/cookidoo/domain/cookidoo_repository.dart` | Abstract repository interface |
| Create | `lib/features/cookidoo/data/cookidoo_client.dart` | HTTP client (auth + API calls) |
| Create | `lib/features/cookidoo/data/cookidoo_repository_impl.dart` | Repository implementation |
| Create | `lib/features/cookidoo/data/cookidoo_credentials_storage.dart` | SharedPreferences persistence for credentials |
| Create | `lib/features/cookidoo/providers.dart` | Riverpod providers |
| Create | `lib/features/cookidoo/presentation/cookidoo_credentials_tile.dart` | Settings tile widget |
| Create | `lib/features/tools/handlers/search_recipes_handler.dart` | Tool handler for LLM search |
| Create | `lib/features/tools/handlers/get_recipe_detail_handler.dart` | Tool handler for LLM recipe detail |
| Create | `assets/skills/search-recipe/SKILL.md` | LLM skill instructions |
| Modify | `lib/features/tools/providers.dart` | Register new handler |
| Modify | `lib/features/skills/domain/skill_loader.dart` | Add skill asset path |
| Modify | `lib/features/settings/presentation/settings_page.dart` | Add Cookidoo section |
| Modify | `lib/l10n/app_en.arb` | Add i18n keys |
| Modify | `lib/l10n/app_fr.arb` | Add French translations |
| Modify | `lib/l10n/app_de.arb` | Add German translations |
| Modify | `lib/l10n/app_es.arb` | Add Spanish translations |
| Modify | `pubspec.yaml` | Add `http` dependency + skill asset |
| Modify | `SPEC.md` | Document `http` package |

---

### Task 1: Add `http` dependency and update SPEC.md

**Files:**
- Modify: `pubspec.yaml`
- Modify: `SPEC.md`

- [ ] **Step 1: Add http to pubspec.yaml**

In `pubspec.yaml`, add `http` under dependencies (after `yaml`):

```yaml
  yaml: ^3.1.0
  http: ^1.4.0
```

- [ ] **Step 2: Add search-recipe skill asset path**

In `pubspec.yaml`, add the skill asset folder under `flutter > assets`:

```yaml
    - assets/skills/search-recipe/
```

- [ ] **Step 3: Update SPEC.md**

Add a new section after "Function Calling" in `SPEC.md`:

```markdown
## Cookidoo Integration

- http (REST client for Cookidoo recipe search and detail APIs)
```

- [ ] **Step 4: Run flutter pub get**

Run: `flutter pub get`
Expected: resolves without errors.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock SPEC.md
git commit -m "build(cookidoo): add http dependency and update SPEC.md"
```

---

### Task 2: Domain models

**Files:**
- Create: `lib/features/cookidoo/domain/models/cookidoo_recipe_overview.dart`
- Create: `lib/features/cookidoo/domain/models/cookidoo_recipe_detail.dart`
- Create: `lib/features/cookidoo/domain/models/cookidoo_auth_token.dart`
- Create: `lib/features/cookidoo/domain/models/cookidoo_credentials.dart`
- Create: `lib/features/cookidoo/domain/models/cookidoo_exceptions.dart`

- [ ] **Step 1: Create CookidooRecipeOverview**

```dart
class CookidooRecipeOverview {
  const CookidooRecipeOverview({
    required this.id,
    required this.title,
    required this.rating,
    required this.numberOfRatings,
    required this.totalTime,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final double rating;
  final int numberOfRatings;
  final int totalTime;
  final String imageUrl;

  factory CookidooRecipeOverview.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as String? ?? '';
    return CookidooRecipeOverview(
      id: json['id'] as String,
      title: json['title'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      numberOfRatings: json['numberOfRatings'] as int? ?? 0,
      totalTime: json['totalTime'] as int? ?? 0,
      imageUrl: image.replaceAll(
        '{transformation}',
        't_web_shared_recipe_221x240',
      ),
    );
  }
}
```

- [ ] **Step 2: Create CookidooRecipeDetail**

```dart
class IngredientGroup {
  const IngredientGroup({required this.title, required this.ingredients});

  final String title;
  final List<Ingredient> ingredients;

  factory IngredientGroup.fromJson(Map<String, dynamic> json) {
    final items = (json['recipeIngredients'] as List<dynamic>?)
            ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return IngredientGroup(
      title: json['title'] as String? ?? '',
      ingredients: items,
    );
  }
}

class Ingredient {
  const Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final double quantity;
  final String unit;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['ingredientNotation'] as String? ?? '',
      quantity: (json['quantity']?['value'] as num?)?.toDouble() ?? 0,
      unit: json['unitNotation'] as String? ?? '',
    );
  }
}

class StepGroup {
  const StepGroup({required this.title, required this.steps});

  final String title;
  final List<RecipeStep> steps;

  factory StepGroup.fromJson(Map<String, dynamic> json) {
    final items = (json['recipeSteps'] as List<dynamic>?)
            ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return StepGroup(title: json['title'] as String? ?? '', steps: items);
  }
}

class RecipeStep {
  const RecipeStep({required this.title, required this.text});

  final String title;
  final String text;

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      title: json['title'] as String? ?? '',
      text: json['formattedText'] as String? ?? '',
    );
  }
}

class NutritionInfo {
  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  factory NutritionInfo.fromJson(List<dynamic> nutritionGroups) {
    double kcal = 0, protein = 0, fat = 0, carbs = 0;
    for (final group in nutritionGroups) {
      final recipeNutritions =
          group['recipeNutritions'] as List<dynamic>? ?? [];
      for (final rn in recipeNutritions) {
        final nutritions = rn['nutritions'] as List<dynamic>? ?? [];
        for (final n in nutritions) {
          final type = n['type'] as String? ?? '';
          final number = (n['number'] as num?)?.toDouble() ?? 0;
          switch (type) {
            case 'kcal':
              kcal = number;
            case 'protein':
              protein = number;
            case 'fat':
              fat = number;
            case 'carbohydrates':
              carbs = number;
          }
        }
      }
    }
    return NutritionInfo(
        calories: kcal, protein: protein, fat: fat, carbs: carbs);
  }
}

class CookidooRecipeDetail {
  const CookidooRecipeDetail({
    required this.id,
    required this.title,
    required this.rating,
    required this.totalTime,
    required this.imageUrl,
    required this.servingSize,
    required this.ingredientGroups,
    required this.stepGroups,
    this.nutrition,
    required this.thermomixVersions,
  });

  final String id;
  final String title;
  final double rating;
  final int totalTime;
  final String imageUrl;
  final String servingSize;
  final List<IngredientGroup> ingredientGroups;
  final List<StepGroup> stepGroups;
  final NutritionInfo? nutrition;
  final List<String> thermomixVersions;

  factory CookidooRecipeDetail.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as String? ??
        (json['descriptiveAssets'] as List<dynamic>?)
            ?.firstOrNull
            ?['square'] as String? ??
        '';
    final servingSize = json['servingSize'] as Map<String, dynamic>?;
    final servingQty =
        servingSize?['quantity']?['value']?.toString() ?? '';
    final servingUnit = servingSize?['unitNotation'] as String? ?? '';

    final nutritionGroups = json['nutritionGroups'] as List<dynamic>?;

    return CookidooRecipeDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      rating: (json['aggregateRating']?['ratingValue'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0,
      totalTime: _parseTotalTime(json),
      imageUrl: image.replaceAll(
        '{transformation}',
        't_web_rdp_recipe_584x480_1_5x',
      ),
      servingSize: '$servingQty $servingUnit'.trim(),
      ingredientGroups: (json['recipeIngredientGroups'] as List<dynamic>?)
              ?.map(
                  (e) => IngredientGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stepGroups: (json['recipeStepGroups'] as List<dynamic>?)
              ?.map((e) => StepGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nutrition: nutritionGroups != null && nutritionGroups.isNotEmpty
          ? NutritionInfo.fromJson(nutritionGroups)
          : null,
      thermomixVersions: (json['thermomixVersions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  static int _parseTotalTime(Map<String, dynamic> json) {
    final times = json['times'] as List<dynamic>?;
    if (times != null) {
      for (final t in times) {
        if (t['type'] == 'totalTime') {
          return (t['quantity']?['value'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return json['totalTime'] as int? ?? 0;
  }
}
```

- [ ] **Step 3: Create CookidooAuthToken**

```dart
class CookidooAuthToken {
  const CookidooAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory CookidooAuthToken.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int? ?? 0;
    return CookidooAuthToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
    );
  }
}
```

- [ ] **Step 4: Create CookidooCredentials**

```dart
class CookidooCredentials {
  const CookidooCredentials({required this.email, required this.password});

  final String email;
  final String password;

  bool get isEmpty => email.isEmpty || password.isEmpty;
}
```

- [ ] **Step 5: Create Cookidoo exceptions**

```dart
class CookidooAuthException implements Exception {
  const CookidooAuthException(this.message);
  final String message;

  @override
  String toString() => 'CookidooAuthException: $message';
}

class CookidooNotFoundException implements Exception {
  const CookidooNotFoundException(this.recipeId);
  final String recipeId;

  @override
  String toString() => 'CookidooNotFoundException: $recipeId';
}

class CookidooNetworkException implements Exception {
  const CookidooNetworkException(this.message);
  final String message;

  @override
  String toString() => 'CookidooNetworkException: $message';
}
```

- [ ] **Step 6: Verify the project compiles**

Run: `flutter analyze --no-fatal-infos`
Expected: no errors in new files.

- [ ] **Step 7: Commit**

```bash
git add lib/features/cookidoo/domain/
git commit -m "feat(cookidoo): add domain models for Cookidoo integration"
```

---

### Task 3: CookidooClient (HTTP + auth)

**Files:**
- Create: `lib/features/cookidoo/data/cookidoo_client.dart`

- [ ] **Step 1: Create CookidooClient**

```dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/models/cookidoo_auth_token.dart';
import '../domain/models/cookidoo_credentials.dart';
import '../domain/models/cookidoo_exceptions.dart';
import '../domain/models/cookidoo_recipe_detail.dart';
import '../domain/models/cookidoo_recipe_overview.dart';

class CookidooClient {
  CookidooClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  static const _basicAuth =
      'Basic a3VwZmVyd2Vyay1jbGllbnQtbndvdDpMczUwT04xd295U3FzMWRDZEpnZQ==';
  static const _clientId = 'kupferwerk-client-nwot';

  CookidooAuthToken? _token;

  String _baseUrl(String countryCode) =>
      'https://$countryCode.tmmobile.vorwerk-digital.com';

  static String countryCodeFromLocale(String locale) {
    final parts = locale.split('-');
    if (parts.length < 2) return parts.first.toLowerCase();
    final country = parts.last.toLowerCase();
    return switch (country) {
      'gb' => 'gb',
      _ => country,
    };
  }

  Future<CookidooAuthToken> login(
    CookidooCredentials credentials, {
    required String countryCode,
  }) async {
    final url =
        Uri.parse('${_baseUrl(countryCode)}/ciam/auth/token');
    final response = await _http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': _basicAuth,
      },
      body:
          'grant_type=password&username=${Uri.encodeComponent(credentials.email)}'
          '&password=${Uri.encodeComponent(credentials.password)}',
    );

    if (response.statusCode != 200) {
      throw CookidooAuthException(
        'Login failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _token = CookidooAuthToken.fromJson(json);
    return _token!;
  }

  Future<void> _refreshToken({required String countryCode}) async {
    if (_token == null) {
      throw const CookidooAuthException('No token to refresh');
    }

    final url =
        Uri.parse('${_baseUrl(countryCode)}/ciam/auth/token');
    final response = await _http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': _basicAuth,
      },
      body:
          'grant_type=refresh_token&refresh_token=${_token!.refreshToken}'
          '&client_id=$_clientId',
    );

    if (response.statusCode != 200) {
      _token = null;
      throw CookidooAuthException(
        'Token refresh failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    _token = CookidooAuthToken.fromJson(json);
  }

  Future<void> _ensureAuth(
    CookidooCredentials credentials, {
    required String countryCode,
  }) async {
    if (_token == null) {
      await login(credentials, countryCode: countryCode);
    } else if (_token!.isExpired) {
      try {
        await _refreshToken(countryCode: countryCode);
      } catch (_) {
        await login(credentials, countryCode: countryCode);
      }
    }
  }

  Future<List<CookidooRecipeOverview>> searchRecipes(
    String query, {
    required String lang,
    required String countryCode,
    int limit = 5,
  }) async {
    final url = Uri.parse(
      '${_baseUrl(countryCode)}/search/api/$lang/search'
      '?query=${Uri.encodeComponent(query)}&context=recipes&limit=$limit',
    );

    final response = await _http.get(url, headers: {
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw CookidooNetworkException(
        'Search failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as List<dynamic>? ?? [];
    return data
        .map((e) =>
            CookidooRecipeOverview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CookidooRecipeDetail> getRecipeDetail(
    String recipeId, {
    required String lang,
    required String countryCode,
    required CookidooCredentials credentials,
  }) async {
    await _ensureAuth(credentials, countryCode: countryCode);

    final url = Uri.parse(
      '${_baseUrl(countryCode)}/recipes/recipe/$lang/$recipeId',
    );

    final response = await _http.get(url, headers: {
      'Accept': 'application/vnd.vorwerk.recipe.embedded.hal+json',
      'Authorization': 'Bearer ${_token!.accessToken}',
    });

    if (response.statusCode == 404) {
      throw CookidooNotFoundException(recipeId);
    }
    if (response.statusCode == 401) {
      _token = null;
      throw const CookidooAuthException('Session expired');
    }
    if (response.statusCode != 200) {
      throw CookidooNetworkException(
        'Recipe detail failed (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CookidooRecipeDetail.fromJson(json);
  }

  void dispose() {
    _http.close();
  }
}
```

- [ ] **Step 2: Verify the project compiles**

Run: `flutter analyze --no-fatal-infos`
Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/cookidoo/data/cookidoo_client.dart
git commit -m "feat(cookidoo): add HTTP client with OAuth2 auth and API calls"
```

---

### Task 4: Repository interface and implementation

**Files:**
- Create: `lib/features/cookidoo/domain/cookidoo_repository.dart`
- Create: `lib/features/cookidoo/data/cookidoo_repository_impl.dart`

- [ ] **Step 1: Create abstract CookidooRepository**

```dart
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
```

- [ ] **Step 2: Create CookidooRepositoryImpl**

```dart
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
```

- [ ] **Step 3: Verify the project compiles**

Run: `flutter analyze --no-fatal-infos`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/cookidoo/domain/cookidoo_repository.dart lib/features/cookidoo/data/cookidoo_repository_impl.dart
git commit -m "feat(cookidoo): add repository interface and implementation"
```

---

### Task 5: Credentials storage and Riverpod providers

**Files:**
- Create: `lib/features/cookidoo/data/cookidoo_credentials_storage.dart`
- Create: `lib/features/cookidoo/providers.dart`

- [ ] **Step 1: Create CookidooCredentialsStorage**

```dart
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/cookidoo_credentials.dart';

class CookidooCredentialsStorage {
  CookidooCredentialsStorage(this._prefs);

  static const _keyEmail = 'cookidoo_email';
  static const _keyPassword = 'cookidoo_password';

  final SharedPreferences _prefs;

  CookidooCredentials read() {
    return CookidooCredentials(
      email: _prefs.getString(_keyEmail) ?? '',
      password: _prefs.getString(_keyPassword) ?? '',
    );
  }

  Future<void> write(CookidooCredentials credentials) async {
    await _prefs.setString(_keyEmail, credentials.email);
    await _prefs.setString(_keyPassword, credentials.password);
  }
}
```

- [ ] **Step 2: Create providers.dart**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/cookidoo_client.dart';
import 'data/cookidoo_credentials_storage.dart';
import 'data/cookidoo_repository_impl.dart';
import 'domain/cookidoo_repository.dart';
import 'domain/models/cookidoo_credentials.dart';

final cookidooCredentialsStorageProvider =
    FutureProvider<CookidooCredentialsStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return CookidooCredentialsStorage(prefs);
});

class CookidooCredentialsNotifier extends AsyncNotifier<CookidooCredentials> {
  @override
  Future<CookidooCredentials> build() async {
    final storage =
        await ref.watch(cookidooCredentialsStorageProvider.future);
    return storage.read();
  }

  Future<void> setCredentials(CookidooCredentials credentials) async {
    final storage =
        await ref.read(cookidooCredentialsStorageProvider.future);
    state = const AsyncValue<CookidooCredentials>.loading()
        .copyWithPrevious(state);
    try {
      await storage.write(credentials);
      state = AsyncValue.data(credentials);
    } catch (error, stack) {
      state = AsyncValue<CookidooCredentials>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final cookidooCredentialsProvider =
    AsyncNotifierProvider<CookidooCredentialsNotifier, CookidooCredentials>(
  CookidooCredentialsNotifier.new,
);

final cookidooClientProvider = Provider<CookidooClient>((ref) {
  final client = CookidooClient();
  ref.onDispose(client.dispose);
  return client;
});

final cookidooRepositoryProvider = Provider<CookidooRepository>((ref) {
  final client = ref.watch(cookidooClientProvider);
  final credentials = ref.watch(cookidooCredentialsProvider).valueOrNull;
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final lang = '${locale.languageCode}-${locale.countryCode ?? locale.languageCode.toUpperCase()}';

  return CookidooRepositoryImpl(
    client: client,
    locale: lang,
    credentials: credentials,
  );
});
```

**Important:** The locale derivation above is a placeholder. In the actual implementation, derive it from the app's effective locale (via `effectiveLocaleProvider` or `WidgetsBinding.instance.platformDispatcher.locale`). The exact pattern:

```dart
final cookidooRepositoryProvider = Provider<CookidooRepository>((ref) {
  final client = ref.watch(cookidooClientProvider);
  final credentials = ref.watch(cookidooCredentialsProvider).valueOrNull;
  final effectiveLocale = ref.watch(effectiveLocaleProvider);
  final locale = effectiveLocale ??
      WidgetsBinding.instance.platformDispatcher.locale;
  final lang =
      '${locale.languageCode}-${locale.countryCode ?? locale.languageCode.toUpperCase()}';

  return CookidooRepositoryImpl(
    client: client,
    locale: lang,
    credentials: credentials,
  );
});
```

This requires importing the locale provider:

```dart
import '../l10n/providers.dart';
```

- [ ] **Step 3: Verify the project compiles**

Run: `flutter analyze --no-fatal-infos`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/cookidoo/data/cookidoo_credentials_storage.dart lib/features/cookidoo/providers.dart
git commit -m "feat(cookidoo): add credentials storage and Riverpod providers"
```

---

### Task 6: i18n strings (all 4 locales)

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_es.arb`

- [ ] **Step 1: Add English strings to app_en.arb**

Add before the closing `}`:

```json
  "settingsSectionCookidoo": "Cookidoo",
  "@settingsSectionCookidoo": { "description": "Section header for Cookidoo settings." },

  "settingsCookidooEmailTitle": "Email",
  "@settingsCookidooEmailTitle": { "description": "Title for the Cookidoo email field." },

  "settingsCookidooEmailHint": "Cookidoo account email",
  "@settingsCookidooEmailHint": { "description": "Hint for the Cookidoo email text field." },

  "settingsCookidooPasswordTitle": "Password",
  "@settingsCookidooPasswordTitle": { "description": "Title for the Cookidoo password field." },

  "settingsCookidooPasswordHint": "Cookidoo account password",
  "@settingsCookidooPasswordHint": { "description": "Hint for the Cookidoo password text field." },

  "settingsCookidooTest": "Test",
  "@settingsCookidooTest": { "description": "Button label to test Cookidoo credentials." },

  "settingsCookidooTestSuccess": "Connection successful!",
  "@settingsCookidooTestSuccess": { "description": "Snackbar shown when Cookidoo credentials are valid." },

  "settingsCookidooTestFailure": "Connection failed. Please check your credentials.",
  "@settingsCookidooTestFailure": { "description": "Snackbar shown when Cookidoo credentials are invalid." },

  "settingsCookidooNotConfigured": "Not configured",
  "@settingsCookidooNotConfigured": { "description": "Subtitle shown when Cookidoo credentials are not set." },

  "settingsCookidooChangeFailureSnackbar": "Couldn't save Cookidoo credentials. Please try again.",
  "@settingsCookidooChangeFailureSnackbar": { "description": "Shown when persisting Cookidoo credentials fails." }
```

- [ ] **Step 2: Add French strings to app_fr.arb**

Add before the closing `}`:

```json
  "settingsSectionCookidoo": "Cookidoo",
  "settingsCookidooEmailTitle": "Email",
  "settingsCookidooEmailHint": "Email du compte Cookidoo",
  "settingsCookidooPasswordTitle": "Mot de passe",
  "settingsCookidooPasswordHint": "Mot de passe du compte Cookidoo",
  "settingsCookidooTest": "Tester",
  "settingsCookidooTestSuccess": "Connexion réussie !",
  "settingsCookidooTestFailure": "Échec de connexion. Vérifiez vos identifiants.",
  "settingsCookidooNotConfigured": "Non configuré",
  "settingsCookidooChangeFailureSnackbar": "Impossible de sauvegarder les identifiants Cookidoo. Réessayez."
```

- [ ] **Step 3: Add German strings to app_de.arb**

Add before the closing `}`:

```json
  "settingsSectionCookidoo": "Cookidoo",
  "settingsCookidooEmailTitle": "E-Mail",
  "settingsCookidooEmailHint": "Cookidoo-Konto-E-Mail",
  "settingsCookidooPasswordTitle": "Passwort",
  "settingsCookidooPasswordHint": "Cookidoo-Konto-Passwort",
  "settingsCookidooTest": "Testen",
  "settingsCookidooTestSuccess": "Verbindung erfolgreich!",
  "settingsCookidooTestFailure": "Verbindung fehlgeschlagen. Bitte Zugangsdaten prüfen.",
  "settingsCookidooNotConfigured": "Nicht konfiguriert",
  "settingsCookidooChangeFailureSnackbar": "Cookidoo-Zugangsdaten konnten nicht gespeichert werden. Bitte versuche es erneut."
```

- [ ] **Step 4: Add Spanish strings to app_es.arb**

Add before the closing `}`:

```json
  "settingsSectionCookidoo": "Cookidoo",
  "settingsCookidooEmailTitle": "Email",
  "settingsCookidooEmailHint": "Email de la cuenta Cookidoo",
  "settingsCookidooPasswordTitle": "Contraseña",
  "settingsCookidooPasswordHint": "Contraseña de la cuenta Cookidoo",
  "settingsCookidooTest": "Probar",
  "settingsCookidooTestSuccess": "¡Conexión exitosa!",
  "settingsCookidooTestFailure": "Conexión fallida. Verifica tus credenciales.",
  "settingsCookidooNotConfigured": "No configurado",
  "settingsCookidooChangeFailureSnackbar": "No se pudieron guardar las credenciales de Cookidoo. Inténtalo de nuevo."
```

- [ ] **Step 5: Generate localizations**

Run: `flutter gen-l10n`
Expected: generates updated `app_localizations.dart` files without errors.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/
git commit -m "feat(cookidoo): add i18n strings for Cookidoo settings in all 4 locales"
```

---

### Task 7: Settings UI — Cookidoo credentials tile

**Files:**
- Create: `lib/features/cookidoo/presentation/cookidoo_credentials_tile.dart`
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Create CookidooCredentialsTile**

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/cookidoo_credentials.dart';
import '../providers.dart';

class CookidooCredentialsTile extends ConsumerWidget {
  const CookidooCredentialsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final credentials = ref.watch(cookidooCredentialsProvider).valueOrNull;
    final subtitle = (credentials != null && !credentials.isEmpty)
        ? credentials.email
        : l10n.settingsCookidooNotConfigured;

    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: const Text('Cookidoo'),
      subtitle: Text(subtitle),
      onTap: () => _showCredentialsDialog(context, ref, credentials),
    );
  }

  Future<void> _showCredentialsDialog(
    BuildContext context,
    WidgetRef ref,
    CookidooCredentials? current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final emailController =
        TextEditingController(text: current?.email ?? '');
    final passwordController =
        TextEditingController(text: current?.password ?? '');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cookidoo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: l10n.settingsCookidooEmailTitle,
                hintText: l10n.settingsCookidooEmailHint,
              ),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: l10n.settingsCookidooPasswordTitle,
                hintText: l10n.settingsCookidooPasswordHint,
              ),
              obscureText: true,
              autofillHints: const [AutofillHints.password],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final credentials = CookidooCredentials(
                email: emailController.text.trim(),
                password: passwordController.text,
              );
              final repo = ref.read(cookidooRepositoryProvider);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await repo.isAuthenticated();
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? l10n.settingsCookidooTestSuccess
                        : l10n.settingsCookidooTestFailure,
                  ),
                ),
              );
            },
            child: Text(l10n.settingsCookidooTest),
          ),
          TextButton(
            onPressed: () async {
              final credentials = CookidooCredentials(
                email: emailController.text.trim(),
                password: passwordController.text,
              );
              try {
                await ref
                    .read(cookidooCredentialsProvider.notifier)
                    .setCredentials(credentials);
                if (ctx.mounted) Navigator.of(ctx).pop();
              } catch (_) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          l10n.settingsCookidooChangeFailureSnackbar),
                    ),
                  );
                }
              }
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    emailController.dispose();
    passwordController.dispose();
  }
}
```

- [ ] **Step 2: Add Cookidoo section to settings_page.dart**

In `lib/features/settings/presentation/settings_page.dart`, add the import at the top:

```dart
import '../../cookidoo/presentation/cookidoo_credentials_tile.dart';
```

Then add the Cookidoo section in the ListView children, **after** the Recipe section (after `DietaryRestrictionsTile` and its divider, before the AI section):

```dart
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(l10n.settingsSectionCookidoo, style: sectionStyle),
          ),
          const CookidooCredentialsTile(),
          const Divider(height: 1),
```

- [ ] **Step 3: Verify the project compiles**

Run: `flutter analyze --no-fatal-infos`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/cookidoo/presentation/cookidoo_credentials_tile.dart lib/features/settings/presentation/settings_page.dart
git commit -m "feat(cookidoo): add credentials settings tile in settings page"
```

---

### Task 8: Tool handler — SearchRecipesHandler

**Files:**
- Create: `lib/features/tools/handlers/search_recipes_handler.dart`
- Modify: `lib/features/tools/providers.dart`

- [ ] **Step 1: Create SearchRecipesHandler**

```dart
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/core/tool.dart';

import '../../cookidoo/domain/cookidoo_repository.dart';
import '../../cookidoo/domain/models/cookidoo_exceptions.dart';
import '../tool_handler.dart';

class SearchRecipesHandler extends ToolHandler {
  SearchRecipesHandler(this._repository);

  final CookidooRepository _repository;

  @override
  Tool get definition => const Tool(
        name: 'search_recipes',
        description:
            'Search for Thermomix recipes on Cookidoo. Returns a list of '
            'matching recipes with title, rating, and total time.',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'The search query (e.g. "chicken curry").',
            },
            'limit': {
              'type': 'integer',
              'description':
                  'Maximum number of results to return. Default 5.',
            },
          },
          'required': ['query'],
        },
      );

  @override
  Future<void> execute(
      Map<String, dynamic> args, BuildContext context) async {
    final query = args['query'] as String? ?? '';
    final limit = args['limit'] as int? ?? 5;

    try {
      final results =
          await _repository.searchRecipes(query, limit: limit);
      final summaries = results
          .map((r) => {
                'id': r.id,
                'title': r.title,
                'rating': r.rating,
                'totalTimeMinutes': r.totalTime ~/ 60,
              })
          .toList();
      debugPrint(
        'SearchRecipesHandler: ${results.length} results for "$query"'
        '\n${jsonEncode(summaries)}',
      );
    } on CookidooNetworkException catch (e) {
      debugPrint('SearchRecipesHandler: network error — $e');
    }
  }
}
```

**Note:** The handler currently logs results via `debugPrint`. This is because `ToolHandler.execute()` returns `void` — the LLM does not receive tool output in the current flutter_gemma function calling API. The results are available for future enhancements (e.g., when flutter_gemma supports tool responses). The skill instructions will guide the LLM to call the tool, and the system prompt will contain the search context.

**Important update — tool response integration:** If the current `ToolHandler`/`ToolRegistry` pattern supports returning data to the LLM (via function call responses), adapt the handler to return the JSON. Check `conversation_page.dart` for how `FunctionCallResponse` results are fed back. If not, the handler logs and the skill instructions compensate.

- [ ] **Step 2: Create GetRecipeDetailHandler**

```dart
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/core/tool.dart';

import '../../cookidoo/domain/cookidoo_repository.dart';
import '../../cookidoo/domain/models/cookidoo_exceptions.dart';
import '../tool_handler.dart';

class GetRecipeDetailHandler extends ToolHandler {
  GetRecipeDetailHandler(this._repository);

  final CookidooRepository _repository;

  @override
  Tool get definition => const Tool(
        name: 'get_recipe_detail',
        description:
            'Get the full details of a Cookidoo recipe by ID, including '
            'ingredients, steps, and nutrition information.',
        parameters: {
          'type': 'object',
          'properties': {
            'recipe_id': {
              'type': 'string',
              'description': 'The Cookidoo recipe ID (e.g. "r145192").',
            },
          },
          'required': ['recipe_id'],
        },
      );

  @override
  Future<void> execute(
      Map<String, dynamic> args, BuildContext context) async {
    final recipeId = args['recipe_id'] as String? ?? '';

    try {
      final detail = await _repository.getRecipeDetail(recipeId);
      final ingredients = detail.ingredientGroups
          .expand((g) => g.ingredients)
          .map((i) => '${i.quantity} ${i.unit} ${i.name}')
          .toList();
      final steps = detail.stepGroups
          .expand((g) => g.steps)
          .map((s) => '${s.title}: ${s.text}')
          .toList();

      debugPrint(
        'GetRecipeDetailHandler: ${detail.title}'
        '\nIngredients: ${jsonEncode(ingredients)}'
        '\nSteps: ${jsonEncode(steps)}',
      );
    } on CookidooAuthException {
      debugPrint(
        'GetRecipeDetailHandler: credentials not configured or invalid',
      );
    } on CookidooNotFoundException {
      debugPrint('GetRecipeDetailHandler: recipe $recipeId not found');
    } on CookidooNetworkException catch (e) {
      debugPrint('GetRecipeDetailHandler: network error — $e');
    }
  }
}
```

- [ ] **Step 3: Register handlers in providers.dart**

In `lib/features/tools/providers.dart`, add imports and register the handlers:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cookidoo/providers.dart';
import 'handlers/get_recipe_detail_handler.dart';
import 'handlers/search_recipes_handler.dart';
import 'handlers/share_handler.dart';
import 'tool_registry.dart';

final toolRegistryProvider = Provider<ToolRegistry>(
  (ref) {
    final cookidooRepo = ref.watch(cookidooRepositoryProvider);
    return ToolRegistry([
      ShareHandler(),
      SearchRecipesHandler(cookidooRepo),
      GetRecipeDetailHandler(cookidooRepo),
    ]);
  },
);
```

- [ ] **Step 4: Verify the project compiles**

Run: `flutter analyze --no-fatal-infos`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/features/tools/
git commit -m "feat(cookidoo): add search and recipe detail tool handlers"
```

---

### Task 9: Skill — search-recipe SKILL.md

**Files:**
- Create: `assets/skills/search-recipe/SKILL.md`
- Modify: `lib/features/skills/domain/skill_loader.dart`

- [ ] **Step 1: Create SKILL.md**

Create `assets/skills/search-recipe/SKILL.md`:

```markdown
---
name: search-recipe
description: Search for Thermomix recipes on Cookidoo for inspiration.
---

# Search recipe

## Instructions

When the user asks for a recipe (e.g. "make me a chicken curry", "recipe for chocolate cake"),
automatically call the `search_recipes` tool with a relevant query to find similar recipes on Cookidoo.

- query: a concise search term matching the user's request. String.
- limit: number of results, default 5. Integer.

Use the search results as **inspiration**, not as a verbatim copy.
Adapt recipes to the user's settings (portions, dietary restrictions, Thermomix version, difficulty level).

If Cookidoo credentials are configured, you can also call `get_recipe_detail` to retrieve
the full ingredients and steps of a promising recipe:

- recipe_id: the Cookidoo recipe ID from search results (e.g. "r145192"). String.

## Guidelines

- Do NOT mention Cookidoo to the user unless they explicitly ask about it.
- Always adapt the recipe to the user's language, unit system, and preferences.
- Combine inspiration from multiple Cookidoo results when relevant.
- If search returns no results, generate a recipe from your own knowledge.
- If `get_recipe_detail` fails (no credentials), rely on search result titles and your own knowledge.
```

- [ ] **Step 2: Register the skill asset path in skill_loader.dart**

In `lib/features/skills/domain/skill_loader.dart`, add to the `_skillAssetPaths` list:

```dart
const _skillAssetPaths = [
  'assets/skills/share-recipe/SKILL.md',
  'assets/skills/recipe-format/SKILL.md',
  'assets/skills/search-recipe/SKILL.md',
];
```

- [ ] **Step 3: Verify the project compiles**

Run: `flutter analyze --no-fatal-infos`
Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add assets/skills/search-recipe/SKILL.md lib/features/skills/domain/skill_loader.dart
git commit -m "feat(cookidoo): add search-recipe skill for LLM integration"
```

---

### Task 10: Final verification and cleanup

**Files:** All created/modified files.

- [ ] **Step 1: Run full analysis**

Run: `flutter analyze --no-fatal-infos`
Expected: 0 issues.

- [ ] **Step 2: Verify the app builds**

Run: `flutter build apk --debug`
Expected: builds successfully.

- [ ] **Step 3: Verify all i18n keys match across locales**

Check that all 4 ARB files have the same Cookidoo keys (settingsSectionCookidoo, settingsCookidooEmailTitle, settingsCookidooEmailHint, settingsCookidooPasswordTitle, settingsCookidooPasswordHint, settingsCookidooTest, settingsCookidooTestSuccess, settingsCookidooTestFailure, settingsCookidooNotConfigured, settingsCookidooChangeFailureSnackbar).

- [ ] **Step 4: Commit any remaining fixes**

If any issues were found and fixed:

```bash
git add -A
git commit -m "fix(cookidoo): address analysis issues"
```
