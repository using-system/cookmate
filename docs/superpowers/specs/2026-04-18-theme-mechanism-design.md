# Theme Mechanism — Design

**Date:** 2026-04-18
**Status:** Approved

## Context

Cookmate currently exposes a single visual identity driven by
[lib/core/theme.dart](../../../lib/core/theme.dart): two `ThemeData`
builders (`buildLightTheme`, `buildDarkTheme`), both seeded from the same
green (`#2E7D32`), wired in `lib/app.dart` via `ThemeMode.system`. The user
cannot pick a theme.

This spec introduces a user-facing theme mechanism with four fixed
palettes. It mirrors the architecture of the existing locale preference
feature (`lib/features/l10n/`), which already solves the same problem for
language selection (sealed preference + `SharedPreferences` + Riverpod
`AsyncNotifier` + Settings tile).

## Goals

- Offer four distinct, user-selectable themes: **Dark** (default),
  **Standard** (current green), **Pink** (queer-friendly vibrant rose),
  **Matrix** (phosphor green on black, geek aesthetic).
- Persist the choice across launches.
- Apply the selected theme app-wide immediately on selection.
- Default to **Dark** on first launch (no `SharedPreferences` value yet).
- Localize every new UI string in all four supported locales
  (EN, FR, ES, DE).

## Non-Goals

- No auto light/dark switching based on the system: each theme is a
  single fixed palette. "Follow system" is not offered.
- No per-theme light/dark variants.
- No custom fonts (Matrix stays on the Material default font — monospace
  styling is out of scope for this iteration).
- No animated transition between themes (default `MaterialApp` rebuild is
  enough).
- No live preview inside the picker dialog — only theme names are shown.
- No migration of existing preferences (feature is new, nothing to
  migrate).

## Tech Stack

- `flutter/material.dart` — `ColorScheme.fromSeed` for three of the four
  themes, hand-rolled `ColorScheme` for Matrix.
- `shared_preferences` — already a dependency via the locale feature.
- `flutter_riverpod` — already used app-wide.
- `flutter_gen_l10n` via ARB files — already configured.

## Palettes

All themes use Material 3 (`useMaterial3: true`).

| Theme    | Brightness | Source                                       |
|----------|------------|----------------------------------------------|
| Dark     | dark       | `ColorScheme.fromSeed(seedColor: 0xFF6750A4, brightness: dark)` |
| Standard | light      | `ColorScheme.fromSeed(seedColor: 0xFF2E7D32)` (current app seed) |
| Pink     | light      | `ColorScheme.fromSeed(seedColor: 0xFFEC407A)` |
| Matrix   | dark       | Custom `ColorScheme` — see below             |

**Matrix custom scheme** (dark):

- `primary`:     `#00FF41` (phosphor green)
- `onPrimary`:   `#000000`
- `secondary`:   `#39FF14`
- `onSecondary`: `#000000`
- `surface`:     `#0A0F0A`
- `onSurface`:   `#39FF14`
- `error`:       `#FF5555`
- `onError`:     `#000000`

The Matrix theme sets `scaffoldBackgroundColor: Color(0xFF000000)`
explicitly so the background reads as pure black regardless of Material 3
surface tinting. (Material 3 has deprecated `ColorScheme.background` in
favor of `surface` variants; relying on `scaffoldBackgroundColor` keeps
the design forward-compatible.)

## Architecture

Four layers, mirroring `lib/features/l10n/`:

### Domain — `lib/features/theme/domain/theme_preference.dart`

```dart
enum AppTheme {
  dark,
  standard,
  pink,
  matrix;

  static const AppTheme defaultTheme = AppTheme.dark;

  String toStorageValue() => name;

  static AppTheme fromStorageValue(String? raw) {
    for (final theme in AppTheme.values) {
      if (theme.name == raw) return theme;
    }
    return defaultTheme;
  }
}
```

`dark` is declared first so `AppTheme.values.first == defaultTheme`.

### Data — `lib/features/theme/data/theme_preference_storage.dart`

Wraps `SharedPreferences` under the key `theme_preference`. On read
failure, logs via `debugPrint` (English) and returns `AppTheme.dark`.
Same shape as `LocalePreferenceStorage`.

### Providers — `lib/features/theme/providers.dart`

- Reuses the existing `sharedPreferencesProvider` from
  `lib/features/l10n/providers.dart` (exported or moved to a shared
  location — see *Refactor note* below).
- `themePreferenceStorageProvider`: `FutureProvider<ThemePreferenceStorage>`.
- `themePreferenceProvider`:
  `AsyncNotifierProvider<ThemePreferenceNotifier, AppTheme>`.
  Same shape as `LocalePreferenceNotifier`: `build()` reads from storage,
  `setPreference(AppTheme)` writes and updates state with the
  `AsyncValue.loading().copyWithPrevious` + `AsyncValue.data` pattern.
- `themeDataProvider`: `Provider<ThemeData>`. Watches
  `themePreferenceProvider`, returns the matching `ThemeData` from
  `buildThemeData`. While the preference is loading, returns
  `buildThemeData(AppTheme.dark)` so the first paint matches the
  declared default.

### Presentation — `lib/features/theme/presentation/theme_picker_tile.dart`

A `ConsumerWidget` that renders a `ListTile` with
`Icons.palette_outlined`, the title from `l10n.settingsThemeTitle`, and
the subtitle equal to the localized current theme name. Tapping opens a
`SimpleDialog` with a `RadioGroup<AppTheme>` — identical structure to
`LanguagePickerTile`. Error handling mirrors the language picker:
`debugPrint` on failure + `ScaffoldMessenger` snackbar using
`settingsThemeChangeFailureSnackbar`.

### Theme builders — `lib/core/theme.dart`

Rewritten. `buildLightTheme` and `buildDarkTheme` are removed. New API:

```dart
ThemeData buildThemeData(AppTheme theme) { … }
```

Internal private helpers build each palette. Matrix uses
`ThemeData(colorScheme: …, scaffoldBackgroundColor: …, useMaterial3: true)`.

### App wiring — `lib/app.dart`

`MaterialApp.router` loses `theme`, `darkTheme`, `themeMode`. It now reads
`themeDataProvider` and passes only `theme:`:

```dart
final themeData = ref.watch(themeDataProvider);
return MaterialApp.router(
  theme: themeData,
  // …
);
```

### Settings page

Adds a `ThemePickerTile` above the existing `LanguagePickerTile` in
[lib/features/settings/presentation/settings_page.dart](../../../lib/features/settings/presentation/settings_page.dart),
separated by a `Divider(height: 1)` for consistency with the existing
layout.

### Refactor note

`sharedPreferencesProvider` currently lives in
`lib/features/l10n/providers.dart`. Since a second feature now needs it,
move it to `lib/core/shared_preferences_provider.dart` and re-import from
both feature modules. This is the only non-new-feature change in scope,
and it is justified by the new dependency.

## i18n

Added to all four ARB files (`lib/l10n/app_{en,fr,es,de}.arb`):

| Key                                   | EN                                 | FR                                              | ES                                          | DE                                            |
|---------------------------------------|------------------------------------|-------------------------------------------------|---------------------------------------------|-----------------------------------------------|
| `settingsThemeTitle`                  | Theme                              | Thème                                           | Tema                                        | Design                                        |
| `settingsThemeDialogTitle`            | Choose theme                       | Choisir le thème                                | Elegir tema                                 | Design auswählen                              |
| `settingsThemeOptionDark`             | Dark                               | Sombre                                          | Oscuro                                      | Dunkel                                        |
| `settingsThemeOptionStandard`         | Standard                           | Standard                                        | Estándar                                    | Standard                                      |
| `settingsThemeOptionPink`             | Pink                               | Rose                                            | Rosa                                        | Pink                                          |
| `settingsThemeOptionMatrix`           | Matrix                             | Matrix                                          | Matrix                                      | Matrix                                        |
| `settingsThemeChangeFailureSnackbar`  | Couldn't change theme. Please try again. | Impossible de changer de thème. Veuillez réessayer. | No se pudo cambiar el tema. Inténtalo de nuevo. | Design konnte nicht geändert werden. Bitte erneut versuchen. |

Each key ships with an `@`-description in `app_en.arb` (template
locale). No placeholders, no plurals.

## Data flow

```
User taps ThemePickerTile
        │
        ▼
SimpleDialog with RadioGroup<AppTheme>
        │
 selects AppTheme.pink
        │
        ▼
ThemePreferenceNotifier.setPreference(pink)
        │
        ├── writes "pink" to SharedPreferences
        └── emits AsyncValue.data(pink)
                    │
                    ▼
        themeDataProvider rebuilds → buildThemeData(pink)
                    │
                    ▼
        CookmateApp rebuilds MaterialApp with new ThemeData
```

## Error handling

- **Read error** (corrupted prefs): caught in `ThemePreferenceStorage.read`,
  logged via `debugPrint`, falls back to `AppTheme.dark`.
- **Write error**: caught in `ThemePreferenceNotifier.setPreference`,
  rethrown after setting `AsyncValue.error`. The picker tile catches,
  logs, and shows `settingsThemeChangeFailureSnackbar`.
- **Invalid stored value**: treated as missing → `AppTheme.dark`.

## Testing

New tests under `test/features/theme/`, mirroring the existing layout
under `test/features/l10n/`:

- **`theme_preference_test.dart`** — `toStorageValue` / `fromStorageValue`
  round-trip for every enum value, plus fallback cases: `null`, `""`,
  `"unknown"` → `AppTheme.dark`.
- **`theme_preference_storage_test.dart`** — uses
  `SharedPreferences.setMockInitialValues`. Verifies `read` returns the
  right theme, `write` persists, read-after-write cycle, and corrupted
  value returns `AppTheme.dark`.
- **`theme_preference_notifier_test.dart`** — `ProviderContainer` with a
  mocked `themePreferenceStorageProvider`. Verifies initial state,
  `setPreference(matrix)` updates state and calls storage, storage
  failure surfaces as `AsyncValue.error`.
- **`theme_picker_tile_test.dart`** — widget test. Pumps with a
  `ProviderScope` override, taps the tile, selects an option in the
  dialog, asserts the subtitle updates and the notifier was called. Also
  covers the failure snackbar path.

`ThemeData` values themselves are not unit-tested: verifying Material 3
output adds no value.

`flutter analyze` and `flutter test` must be green before commit, per
[CLAUDE.md](../../../CLAUDE.md).

## Open questions

None. All design choices are locked via brainstorming.
