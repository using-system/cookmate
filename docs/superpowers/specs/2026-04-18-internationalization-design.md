# Internationalization (FR + EN + ES + DE) — Design

**Date:** 2026-04-18
**Status:** Approved

## Context

The Cookmate bootstrap (see `2026-04-18-bootstrap-cookmate-design.md`) ships with
all UI strings hardcoded in French. This spec introduces internationalization
(i18n) as a foundation that will scale with future features (real Cookidoo flow,
LLM chat). Four languages are in scope: French (FR), English (EN), Spanish (ES),
German (DE).

This work only covers the i18n *mechanism* and the translation of the currently
existing UI strings. It does not introduce any new feature.

## Goals

- Externalize every hardcoded UI string into localized resources.
- Ship translations for FR, EN, ES, DE.
- Follow the system locale by default; let the user force a specific language
  from the Settings page; persist that choice across launches.
- Fall back to EN when the system locale is not one of the four supported
  languages.
- Rely on the official Flutter i18n toolchain — no third-party i18n package.

## Non-Goals

- No translation of dynamic content (Cookidoo data, recipes, LLM answers).
- No pluralization or gender rules — current strings do not need them.
- No RTL support (Arabic, Hebrew, etc. are not targeted).
- No translation of `debugPrint` messages (developer logs stay in English).
- No automated tests (consistent with the current bootstrap baseline).
- No splash or loading screen during locale preference hydration.

## Tech Stack

- `flutter_localizations` (Flutter SDK) — delegates for Material, Cupertino,
  Widgets.
- `gen_l10n` with ARB files — code-generated, type-safe `AppLocalizations`.
- `shared_preferences` — new dependency for the locale preference (non-sensitive,
  kept separate from `flutter_secure_storage` which stores credentials).
- Riverpod — reuses the existing provider setup; no new state-management
  dependency.

## Architecture

New `l10n` feature module for the locale preference. Translation resources live
under `lib/l10n/` at the root of `lib/` (Flutter `gen_l10n` convention).

```
lib/
  l10n/
    app_en.arb                                # source of truth (EN)
    app_fr.arb
    app_es.arb
    app_de.arb
  features/
    l10n/
      data/locale_preference_storage.dart     # shared_preferences wrapper
      domain/locale_preference.dart           # sealed class LocalePreference
      providers.dart                          # localePreferenceProvider + effectiveLocaleProvider
      presentation/language_picker_tile.dart  # Settings ListTile + radio dialog
```

An `l10n.yaml` file at the repository root configures `gen_l10n`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

`MaterialApp.router` in `app.dart` receives:

- `localizationsDelegates: AppLocalizations.localizationsDelegates`
- `supportedLocales: AppLocalizations.supportedLocales`
- `locale: ref.watch(effectiveLocaleProvider)`
- `localeResolutionCallback` to map unsupported system locales to EN.

## Data Model

```dart
sealed class LocalePreference {
  const LocalePreference();
}

class SystemLocalePreference extends LocalePreference {
  const SystemLocalePreference();
}

class ForcedLocalePreference extends LocalePreference {
  final Locale locale;
  const ForcedLocalePreference(this.locale);
}
```

Persisted in `shared_preferences` under the key `locale_preference`:

- key absent or value `"system"` → `SystemLocalePreference`
- `"en"` / `"fr"` / `"es"` / `"de"` → `ForcedLocalePreference(Locale(code))`
- any other value → treated as absent (defensive against corrupted prefs)

## Providers

- `localePreferenceStorageProvider` — exposes the storage wrapper.
- `localePreferenceProvider` — an `AsyncNotifier<LocalePreference>` that:
  - reads the stored preference at startup,
  - exposes `Future<void> setPreference(LocalePreference pref)` which writes to
    `shared_preferences` and updates state,
  - defaults to `SystemLocalePreference` on read failure.
- `effectiveLocaleProvider` — derives the `Locale?` to pass to `MaterialApp`:
  - while `localePreferenceProvider` is loading → `null` (system locale, EN
    fallback),
  - `SystemLocalePreference` → `null`,
  - `ForcedLocalePreference(l)` → `l`.

Only `effectiveLocaleProvider` is consumed by `app.dart`; other features do
not depend on this module.

## Locale Resolution

`localeResolutionCallback` handles the system locale when no forced locale is
set:

1. If a `ForcedLocalePreference` is active, Flutter uses it directly.
2. Otherwise, the device locale is matched against `supportedLocales`:
   - exact match on language code (e.g. `fr_FR` → `fr`, `en_US` → `en`) wins,
   - unsupported variant of a supported language (e.g. `fr_CA`) falls back to
     the base language (`fr`),
   - no match at all (e.g. `it`, `pt`, `ja`) → **EN**.

## UI

### Settings page

A new `ListTile` is inserted in `SettingsPage`, above the existing "logout"
button:

- leading icon: `Icons.language`
- title: localized label "Language" (`settingsLanguageTitle`)
- subtitle: current effective language name:
  - `SystemLocalePreference` → "Follow system (<resolved language>)"
    (`settingsLanguageFollowSystem`, with a parameter for the resolved language).
    The resolved language name is derived from `Localizations.localeOf(context)`
    inside the tile, which reflects the post-`localeResolutionCallback` locale.
  - `ForcedLocalePreference(fr)` → "Français"
  - `ForcedLocalePreference(en)` → "English"
  - `ForcedLocalePreference(es)` → "Español"
  - `ForcedLocalePreference(de)` → "Deutsch"

Tapping the tile opens a dialog with `RadioListTile` entries:

- Follow system
- Français
- English
- Español
- Deutsch

By convention each language label is displayed in its *own* language across all
translations (i.e. "Français" stays "Français" in the EN, ES, DE bundles). Only
the "Follow system" label and the `settingsLanguageTitle` are translated.

Selecting an option calls `setPreference(...)`. On success, `effectiveLocale`
updates and `MaterialApp` rebuilds with the new locale immediately — no app
restart required.

### Strings to externalize (full inventory of the current bootstrap)

- App title: `Cookmate` (identical across all four languages, kept as a single
  ARB entry for consistency).
- `LoginPage`: screen title, email field label/placeholder, password field
  label/placeholder, "Log in" button label, generic login failure snackbar.
- `ChatPage`: "Chat" placeholder text.
- `SettingsPage`: screen title, "Log out" button label, generic logout failure
  snackbar, new "Language" tile (title + subtitle variants + dialog labels).
- `HomeShell`: bottom navigation tab labels ("Chat", "Settings").

Each string gets a descriptive key (e.g. `loginButtonLabel`,
`loginFailureSnackbar`, `homeTabChat`, `settingsTabSettings`). ARB `@key`
metadata includes a short description for translators.

## Error Handling

- Read failure on `shared_preferences` at startup → treated as
  `SystemLocalePreference`, exception sent to `debugPrint`. Non-blocking.
- Write failure when changing language → generic `SnackBar`
  ("Couldn't change language. Try again.") surfaced from the picker dialog
  caller; the in-memory preference is not updated. Same pattern already used
  for login/logout failures.

No retry logic, no telemetry sink.

## Follow-up Work (Not Part of This Spec)

- Automated tests for locale resolution and persistence (added together with
  the broader test suite introduced by later work).
- Translation of future dynamic content (recipes, LLM responses) once those
  features exist.
- Additional locales beyond FR / EN / ES / DE as demand arises.
- Integration with a translation management platform (Crowdin, Lokalise, etc.)
  if the string count grows significantly.
