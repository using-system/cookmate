# Cookidoo Search Integration

## Overview

Integrate Cookidoo (Thermomix recipe platform) as a recipe inspiration source for the on-device LLM agent. When a user asks for a recipe, the agent automatically searches Cookidoo for similar recipes and uses the results as inspiration to produce a tailored response.

The Cookidoo service layer is designed as a **reusable domain/data layer** — consumable by the LLM tool handler today and by dedicated UI screens in the future.

## Goals

- Agent uses Cookidoo search transparently when generating recipes (no explicit user request needed)
- Recipe search works without authentication
- Full recipe detail (ingredients, steps) requires Cookidoo credentials configured in Settings
- Service layer is independent of the chat/LLM feature and reusable across the app

## Non-Goals

- Shopping list, calendar, or collection management (future scope)
- Web scraping or Algolia direct access — we use the discovered REST API
- Encrypting credentials beyond SharedPreferences sandbox

## API Discovery

### Search endpoint (no auth required)

```
GET https://{countryCode}.tmmobile.vorwerk-digital.com/search/api/{lang}/search
    ?query=poulet+curry&context=recipes&limit=5
```

Response:
```json
{
  "data": [
    {
      "id": "r145192",
      "title": "Quiche au poulet, curry et champignons",
      "rating": 4.5,
      "numberOfRatings": 321,
      "totalTime": 2700,
      "image": "https://assets.tmecosys.com/image/upload/{transformation}/...",
      "objectID": "r145192",
      "descriptiveAssets": [{"square": "..."}]
    }
  ]
}
```

### Recipe detail endpoint (auth required)

```
GET https://{countryCode}.tmmobile.vorwerk-digital.com/recipes/recipe/{lang}/{id}
    Authorization: Bearer {access_token}
    Accept: application/vnd.vorwerk.recipe.embedded.hal+json
```

Returns full recipe with ingredient groups, step groups, nutrition, and Thermomix version compatibility.

### Authentication (OAuth2 ROPC)

```
POST https://{countryCode}.tmmobile.vorwerk-digital.com/ciam/auth/token
    Authorization: Basic a3VwZmVyd2Vyay1jbGllbnQtbndvdDpMczUwT04xd295U3FzMWRDZEpnZQ==
    Content-Type: application/x-www-form-urlencoded
    Body: grant_type=password&username={email}&password={password}
```

Token valid ~12h. Refresh via `grant_type=refresh_token&refresh_token={token}&client_id=kupferwerk-client-nwot`.

### Country code mapping

Derived from app locale: `fr-FR` → `fr`, `de-DE` → `de`, `es-ES` → `es`, `en-GB` → `gb`.

### Image URL

Replace `{transformation}` placeholder with:
- Thumbnail: `t_web_shared_recipe_221x240`
- Full: `t_web_rdp_recipe_584x480_1_5x`

## Data Models

### CookidooRecipeOverview (search result)

| Field | Type | Description |
|-------|------|-------------|
| id | String | Recipe ID (e.g. "r145192") |
| title | String | Recipe title |
| rating | double | Average rating |
| numberOfRatings | int | Number of ratings |
| totalTime | int | Total time in seconds |
| imageUrl | String | Image URL with `{transformation}` placeholder |

### CookidooRecipeDetail (full recipe, auth required)

| Field | Type | Description |
|-------|------|-------------|
| id | String | Recipe ID |
| title | String | Recipe title |
| rating | double | Average rating |
| totalTime | int | Total time in seconds |
| imageUrl | String | Image URL |
| servingSize | String | e.g. "4 parts" |
| ingredientGroups | List\<IngredientGroup\> | Grouped ingredients with quantities and units |
| stepGroups | List\<StepGroup\> | Grouped steps with formatted instructions |
| nutrition | NutritionInfo? | Calories, protein, fat, carbs |
| thermomixVersions | List\<String\> | e.g. ["TM5", "TM6"] |

### CookidooCredentials

| Field | Type | Description |
|-------|------|-------------|
| email | String | Cookidoo account email |
| password | String | Cookidoo account password |

### CookidooAuthToken (in-memory only, not persisted)

| Field | Type | Description |
|-------|------|-------------|
| accessToken | String | Bearer token |
| refreshToken | String | Refresh token |
| expiresAt | DateTime | Expiration timestamp |

### Exceptions

- `CookidooAuthException` — invalid credentials or expired session
- `CookidooNotFoundException` — recipe ID not found
- `CookidooNetworkException` — connectivity or server error

## Architecture

### File structure

```
lib/features/cookidoo/
  ├── data/
  │   ├── cookidoo_client.dart              # HTTP client (auth + API calls)
  │   └── cookidoo_repository_impl.dart     # Repository implementation
  ├── domain/
  │   ├── models/
  │   │   ├── cookidoo_recipe_overview.dart
  │   │   ├── cookidoo_recipe_detail.dart
  │   │   ├── cookidoo_auth_token.dart
  │   │   ├── cookidoo_credentials.dart
  │   │   └── cookidoo_exceptions.dart
  │   └── cookidoo_repository.dart          # Abstract interface
  └── providers.dart                        # Riverpod providers
```

### CookidooClient

Manages HTTP calls and OAuth2 token lifecycle:

```
CookidooClient
  ├── login(email, password) → CookidooAuthToken
  ├── refreshToken(refreshToken) → CookidooAuthToken
  ├── searchRecipes(query, {limit, lang}) → List<CookidooRecipeOverview>
  └── getRecipeDetail(id, {lang}) → CookidooRecipeDetail
```

- Token kept in memory, auto-refreshed when expired
- Search works without token
- Detail requires valid token; auto-login on first call if credentials are available

### CookidooRepository (abstract)

```dart
abstract class CookidooRepository {
  Future<List<CookidooRecipeOverview>> searchRecipes(String query, {int limit = 5});
  Future<CookidooRecipeDetail> getRecipeDetail(String recipeId);
  Future<bool> isAuthenticated();
}
```

### Riverpod providers

```dart
final cookidooClientProvider = Provider((ref) => CookidooClient());

final cookidooRepositoryProvider = Provider((ref) {
  final client = ref.watch(cookidooClientProvider);
  final locale = ref.watch(localeProvider);
  final credentials = ref.watch(cookidooCredentialsProvider);
  return CookidooRepositoryImpl(client, locale: locale, credentials: credentials);
});
```

The repository is the single entry point — consumed by the tool handler and future UI screens identically.

## Settings UI

New **Cookidoo** section in the existing Settings screen:

- Email text field
- Password text field (`obscureText: true`)
- "Test" button that calls `login()` and shows success/failure feedback
- Stored via SharedPreferences (`cookidoo_email`, `cookidoo_password`)
- All UI strings in ARB files (en, fr, de, es)

## LLM Integration

### Skill: `assets/skills/search-recipe/SKILL.md`

```yaml
name: search-recipe
description: Search for Thermomix recipes on Cookidoo
type: intent
```

Skill instructions tell the LLM to:
- Use `search_recipes` automatically when the user asks for a recipe
- Use results as **inspiration**, not verbatim copy — adapt to user context (portions, restrictions, level)
- Call `get_recipe_detail` for promising results when credentials are available
- Not mention Cookidoo explicitly unless the user asks

### Tool handler: SearchRecipesHandler

Two functions exposed to the LLM:

| Function | Parameters | Returns |
|----------|-----------|---------|
| `search_recipes` | query (string), limit? (int) | List of recipe overviews (title, rating, time) |
| `get_recipe_detail` | recipe_id (string) | Full recipe (ingredients, steps, nutrition) |

### Typical flow

1. User: "make me a chicken curry"
2. LLM calls `search_recipes("chicken curry")`
3. Handler queries repository → returns 5 results
4. LLM picks the most relevant, calls `get_recipe_detail("r145192")`
5. Handler returns ingredients/steps
6. LLM uses these as inspiration to produce a recipe adapted to the user's profile

If no credentials are configured, only `search_recipes` works. `get_recipe_detail` returns a message asking the user to configure credentials in Settings.

## Dependencies

| Package | Purpose |
|---------|---------|
| `http` | HTTP client for Cookidoo API calls |

No other packages needed. Update `SPEC.md` to reflect the addition.

## Files Changed

| Action | File |
|--------|------|
| Create | `lib/features/cookidoo/data/cookidoo_client.dart` |
| Create | `lib/features/cookidoo/data/cookidoo_repository_impl.dart` |
| Create | `lib/features/cookidoo/domain/models/cookidoo_recipe_overview.dart` |
| Create | `lib/features/cookidoo/domain/models/cookidoo_recipe_detail.dart` |
| Create | `lib/features/cookidoo/domain/models/cookidoo_auth_token.dart` |
| Create | `lib/features/cookidoo/domain/models/cookidoo_credentials.dart` |
| Create | `lib/features/cookidoo/domain/models/cookidoo_exceptions.dart` |
| Create | `lib/features/cookidoo/domain/cookidoo_repository.dart` |
| Create | `lib/features/cookidoo/providers.dart` |
| Create | `lib/features/tools/handlers/search_recipes_handler.dart` |
| Create | `assets/skills/search-recipe/SKILL.md` |
| Modify | `lib/features/settings/` (add Cookidoo section) |
| Modify | `lib/features/tools/providers.dart` (register handler) |
| Modify | `lib/l10n/app_*.arb` (4 files, new keys) |
| Modify | `pubspec.yaml` (add `http`) |
| Modify | `SPEC.md` (document `http` package) |
