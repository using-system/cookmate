# Bootstrap Cookmate — Design

**Date:** 2026-04-18
**Status:** Approved

## Context

Cookmate is a future Flutter mobile application (Android + iOS) intended to become an
AI chat assistant for Thermomix recipes, powered by an on-device Gemma model and the
Cookidoo API. This document covers only the **initial bootstrap**: a runnable shell with
a login screen that stores Cookidoo credentials and a logged-in area with two empty tabs.

No real authentication, no Cookidoo API call, and no AI feature is in scope here.

## Goals

- Runnable Flutter app on Android and iOS.
- Persistent "logged-in" state based on whether Cookidoo credentials are stored locally.
- Cookidoo credentials stored securely (Keychain on iOS, Keystore on Android) so they can
  be reused later by the Cookidoo API client.
- Foundation that will not need to be rewritten when we add the real Cookidoo client and
  the on-device LLM (sound state management, routing, and feature-based folder layout).

## Non-Goals

- No HTTP call to Cookidoo, no real credential validation.
- No email/password format validation, no "remember me" toggle (credentials are always
  persisted on successful login).
- No automated tests at this stage (will be added together with the real auth flow).
- No custom splash screen, no in-app theming controls.
- No internationalization (UI strings are French and hardcoded for now).
- No analytics, crash reporting, or CI configuration.

## Tech Stack

- Flutter (latest stable), Dart 3+.
- `flutter_riverpod` — state management.
- `go_router` — declarative routing with auth-based redirect guard.
- `flutter_secure_storage` — encrypted credential storage.
- Material 3, light/dark theme following the system setting.
- Minimum platforms: Android API 24 (Flutter stable default; `encryptedSharedPreferences: true` requires API 23+), iOS 13 (Flutter stable default; `flutter_secure_storage` supports iOS 9+).

## App Identity

- Display name: `Cookmate`.
- Application id / bundle id: `com.cookmate.app` (both platforms).

## Architecture

Feature-based folder layout under `lib/`:

```
lib/
  main.dart                              # runApp(ProviderScope(MyApp()))
  app.dart                               # MaterialApp.router + theme
  core/
    router.dart                          # GoRouter + auth redirect
    theme.dart                           # light/dark Material 3 themes
  features/
    auth/
      data/credentials_storage.dart      # FlutterSecureStorage wrapper
      data/auth_repository.dart          # save/load/clear credentials
      domain/cookidoo_credentials.dart   # value object
      providers.dart                     # Riverpod providers (storage, repo, auth state)
      presentation/login_page.dart       # email + password form
    home/
      presentation/home_shell.dart       # Scaffold with BottomNavigationBar
    chat/
      presentation/chat_page.dart        # placeholder, empty body
    settings/
      presentation/settings_page.dart    # logout button
```

Each feature owns its presentation, data, and providers and exposes only what other
features need (kept minimal here: `authStateProvider` is the only cross-feature concern).

## Data Model

```dart
class CookidooCredentials {
  final String email;
  final String password;
  const CookidooCredentials({required this.email, required this.password});
}
```

Persisted in `flutter_secure_storage` under two keys:

- `cookidoo_email`
- `cookidoo_password`

The wrapper exposes `read() -> CookidooCredentials?`, `write(creds)`, and `clear()`.
Returning `null` from `read()` when either key is missing is what drives the
"not logged in" state.

## Authentication Flow

There is no remote authentication yet. "Logged in" is a local concept defined as
"credentials are present in secure storage".

1. App start: `authStateProvider` reads secure storage once at startup and exposes
   `AsyncValue<bool>` (loading → true/false).
2. Login page: user fills email + password and taps "Se connecter".
   - `AuthRepository.saveCredentials(creds)` writes both keys to secure storage.
   - `authStateProvider` is refreshed → becomes `true`.
   - Router redirects to `/home/chat`.
3. Settings page: tapping "Se déconnecter" calls `AuthRepository.clearCredentials()`
   which clears both keys, refreshes `authStateProvider` → `false`, router redirects
   to `/login`.

### Routing & Guard

`go_router` configuration:

- `/login` → `LoginPage`
- `/home` → `HomeShell` (shell route)
  - `/home/chat` → `ChatPage` (default tab)
  - `/home/settings` → `SettingsPage`

Redirect rules (executed on every navigation, also re-fired when `authStateProvider`
changes via a `Listenable` adapter):

- While `authStateProvider` is loading → no redirect. The initial location is
  `/login`, so the user briefly sees the login screen until the auth state resolves.
  A dedicated splash/loading screen is not in scope for this bootstrap.
- If not authenticated and target is not `/login` → redirect to `/login`.
- If authenticated and target is `/login` → redirect to `/home/chat`.

## UI

- `LoginPage`: centered form, app title, email field, password field (obscured),
  "Se connecter" button. Button is disabled while either field is empty. No spinner /
  error handling needed (the call is local and synchronous from the user's perspective).
- `HomeShell`: `Scaffold` with a `BottomNavigationBar` driven by `go_router`'s
  `StatefulShellRoute` so each tab keeps its own navigation state.
- `ChatPage`: empty `Center(child: Text('Chat'))` placeholder.
- `SettingsPage`: a single "Se déconnecter" button. After logout, the redirect rule sends
  the user back to `/login` automatically.

## Error Handling

Intentionally minimal. The only failure mode at this stage is `flutter_secure_storage`
throwing on read/write, which is treated as "not authenticated" on read and surfaced as
a `SnackBar` on write/clear. No retry logic, no telemetry.

## Out of Scope (Explicit Reminders)

- No call to Cookidoo, no token, no session.
- No tests in this bootstrap; we will introduce them with the real auth + API integration.
- No CI workflow, no release signing setup.
- No on-device LLM integration; chat tab is a deliberate placeholder.

## Follow-up Work (Not Part of This Spec)

- Real Cookidoo authentication and API client, replacing the local-only flow.
- Chat feature with on-device Gemma inference.
- Test suite (unit + widget + integration).
- CI pipeline and release configuration.
- Internationalization (FR + EN).
