# Cookmate — Claude Code Guide

Cookmate is a Flutter mobile app (Android + iOS) intended to become an AI chat assistant for Thermomix recipes. Current state: bootstrap shell with login + two-tab home, plus full FR/EN/ES/DE internationalization. No Cookidoo API and no on-device LLM yet.

## Tech stack

- Flutter (Dart SDK `^3.11.5`), Material 3, system-driven dark mode.
- `flutter_riverpod` for state management.
- `go_router` with `StatefulShellRoute` for navigation + auth redirect guard.
- `flutter_secure_storage` for credentials; `shared_preferences` for non-sensitive preferences (like the locale override).
- Official Flutter `gen_l10n` toolchain for i18n (ARB files under `lib/l10n/`).

## Architecture

Feature-based layout under `lib/`:

```
lib/
  main.dart                              # runApp(ProviderScope(CookmateApp()))
  app.dart                               # MaterialApp.router, themes, l10n wiring
  core/                                  # cross-feature code (router, theme)
  l10n/                                  # ARB files + generated AppLocalizations
  features/<name>/
    domain/                              # pure-Dart value objects, sealed types
    data/                                # storage wrappers, repositories
    providers.dart                       # Riverpod providers for the feature
    presentation/                        # widgets + pages
```

Rules:
- Features expose only what cross-feature code needs (usually a single `*Provider`). Keep internals private.
- Domain layer depends on nothing above itself — no Riverpod, no storage, no Flutter material widgets (only `dart:ui`/`flutter/widgets` for types like `Locale`).
- `shared_preferences` currently lives inside `features/l10n/providers.dart`. When a second feature needs it, hoist `sharedPreferencesProvider` into `lib/core/`.

## Internationalization workflow — REQUIRED

**Any time UI-visible text is added, removed, or reworded, the ARB files MUST be updated in the same change.** Never hardcode user-facing strings in widgets.

- Source of truth: [lib/l10n/app_en.arb](lib/l10n/app_en.arb). Every new key goes here first with an `@key` description for translators.
- Mirror every new key in [lib/l10n/app_fr.arb](lib/l10n/app_fr.arb), [lib/l10n/app_es.arb](lib/l10n/app_es.arb), and [lib/l10n/app_de.arb](lib/l10n/app_de.arb). All four files must share the same key set (no missing, no extras).
- Run `flutter pub get` to regenerate `lib/l10n/app_localizations*.dart` (these files are not committed — they are regenerated deterministically).
- Consume strings via `AppLocalizations.of(context).<key>`. Import path is `package:cookmate/l10n/app_localizations.dart` (not `package:flutter_gen/...`; synthetic package is deprecated and `l10n.yaml` pins `output-dir: lib/l10n`).
- Key naming: screen-prefixed camelCase + role suffix. Example: `loginEmailLabel`, `settingsLogoutButton`, `homeTabChat`, `chatPlaceholder`.
- Language labels ("Français", "English", "Español", "Deutsch") are intentionally displayed in their own language across all locales — they live as a const map in [lib/features/l10n/presentation/language_picker_tile.dart](lib/features/l10n/presentation/language_picker_tile.dart), not in ARB.
- `debugPrint` messages stay in English (developer logs).

## Storage

- Credentials and any secret go through `flutter_secure_storage` (Keychain / Keystore). See [lib/features/auth/data/credentials_storage.dart](lib/features/auth/data/credentials_storage.dart).
- User preferences and any non-sensitive state go through `shared_preferences`. See [lib/features/l10n/data/locale_preference_storage.dart](lib/features/l10n/data/locale_preference_storage.dart).
- Never put non-secrets in secure storage (surdimensioned, slower) and never put secrets in `shared_preferences`.

## State management

- Use `AsyncNotifier` + `AsyncNotifierProvider` for any state that depends on async IO (like the existing auth and locale-preference notifiers).
- Inside `build()`: `ref.watch(...)` to establish a reactive dependency.
- Inside mutator methods (e.g. `login`, `setPreference`): `ref.read(...)` to avoid re-subscribing.
- When a mutator transitions to loading, use `AsyncValue.loading().copyWithPrevious(state)` so watchers keep the previous value visible via `valueOrNull` (prevents UI flicker during writes).
- When a mutator catches an error, set `AsyncValue.error(error, stack)` AND `rethrow` so imperative callers can surface the failure (e.g. a SnackBar).

## Async gaps in widgets

After any `await` in a widget method, either check `if (!context.mounted) return;` before touching `context` / `ref`, or capture the dependent objects (e.g. `ScaffoldMessenger.of(context)`) into locals BEFORE the await. Prefer the mounted guard when the context is still needed after the await.

## Build, analyze, run

- `flutter pub get` — resolve deps and regenerate `AppLocalizations`.
- `flutter analyze` — must be clean. Two info-level `deprecated_member_use` warnings on `RadioListTile.groupValue`/`onChanged` are known and deferred until Flutter's `RadioGroup` API stabilizes.
- `flutter run` — runs the app on an attached device or simulator.
- iOS `Podfile.lock` is tracked (required for reproducible iOS builds). Commit any changes that come from adding Flutter plugins.

## Testing

No automated tests at this stage. When introducing tests:
- Do not mock `flutter_secure_storage` or `shared_preferences` — use their provided in-memory test shims.
- Cover `LocalePreference.fromStorageValue` branches (null, `"system"`, valid/invalid codes) and the `localeResolutionCallback` EN fallback.
- Widget test `LanguagePickerTile` for subtitle rendering in both preference states.

## Git and PR conventions

- All committed artifacts (code, comments, docs, commit messages, PR titles/bodies) are in **English**, regardless of the conversation language.
- Commits and PR titles follow [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>` in lowercase imperative, no trailing period. Use `feat`, `fix`, `refactor`, `docs`, `chore`, `ci`, etc. Scope is usually the feature name (`l10n`, `auth`, `ios`).
- Branch names mirror the commit type: `feat/<slug>`, `fix/<slug>`, `docs/<slug>`, etc. Never commit directly on `main`.
- Design docs live in [docs/superpowers/specs/](docs/superpowers/specs/). Implementation plans live in [docs/superpowers/plans/](docs/superpowers/plans/). Both use `YYYY-MM-DD-<topic>-design.md` / `YYYY-MM-DD-<topic>.md` naming.

## Non-goals for the current bootstrap

These items are intentionally out of scope until dedicated plans land:

- Real Cookidoo HTTP authentication and API client.
- On-device LLM integration (chat tab is a placeholder).
- Automated tests (unit / widget / integration).
- CI pipeline, release signing, analytics, crash reporting.
- RTL languages, locale pluralization rules, translation of dynamic content.
