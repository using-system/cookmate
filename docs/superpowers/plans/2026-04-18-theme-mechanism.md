# Theme Mechanism Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a user-selectable theme mechanism with four fixed palettes (Dark default, Standard, Pink, Matrix), persisted via `SharedPreferences` and selectable from the Settings page.

**Architecture:** Mirror the existing locale preference feature under `lib/features/l10n/`. New module `lib/features/theme/` with domain enum, storage, Riverpod providers, and a picker tile. The `MaterialApp.router` switches from `theme` + `darkTheme` + `themeMode` to a single `theme:` value fed by a `themeDataProvider`.

**Tech Stack:** Flutter (Material 3), `flutter_riverpod`, `shared_preferences`, `flutter_gen_l10n` (ARB).

**Spec:** [docs/superpowers/specs/2026-04-18-theme-mechanism-design.md](../specs/2026-04-18-theme-mechanism-design.md)

---

## Pre-flight

- [ ] **Step 0a: Confirm working branch**

Run: `git branch --show-current`
Expected: `feat/theme-mechanism` (already created by the brainstorming step; the spec commit lives here).

- [ ] **Step 0b: Baseline green**

Run in order:
- `flutter pub get`
- `flutter analyze`
- `flutter test`

Expected: both analyze and test exit 0. If not, stop and investigate before starting Task 1.

---

## Task 1: Lift `sharedPreferencesProvider` to core

Two features (`l10n`, theme) now need the same `SharedPreferences` provider. Move it out of `features/l10n/providers.dart` into a shared location. Pure refactor — no behavior change.

**Files:**
- Create: `lib/core/shared_preferences_provider.dart`
- Modify: `lib/features/l10n/providers.dart`

- [ ] **Step 1.1: Create the shared provider file**

Write `lib/core/shared_preferences_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});
```

- [ ] **Step 1.2: Update `lib/features/l10n/providers.dart`**

Remove the local `sharedPreferencesProvider` definition and the now-unused `shared_preferences` import. Keep the rest of the file intact. Add an import for the new file.

Full new header of `lib/features/l10n/providers.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/locale_preference_storage.dart';
import 'domain/locale_preference.dart';

final localePreferenceStorageProvider =
    FutureProvider<LocalePreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LocalePreferenceStorage(prefs);
});
```

The rest of the file (`LocalePreferenceNotifier`, `localePreferenceProvider`, `effectiveLocaleProvider`) stays unchanged.

- [ ] **Step 1.3: Verify no regression**

Run:
- `flutter analyze` → 0 issues
- `flutter test` → all tests pass (the existing locale tests cover this refactor)

- [ ] **Step 1.4: Commit**

```bash
git add lib/core/shared_preferences_provider.dart lib/features/l10n/providers.dart
git commit -m "refactor(core): lift sharedPreferencesProvider out of l10n feature

Prepares for a second feature (theme picker) that needs the same provider."
```

---

## Task 2: Domain — `AppTheme` enum

Create the enum that represents the four themes, with string serialization and a default fallback.

**Files:**
- Create: `lib/features/theme/domain/app_theme.dart`
- Test: `test/features/theme/domain/app_theme_test.dart`

- [ ] **Step 2.1: Write the failing tests**

Write `test/features/theme/domain/app_theme_test.dart`:

```dart
import 'package:cookmate/features/theme/domain/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme.defaultTheme', () {
    test('is AppTheme.dark', () {
      expect(AppTheme.defaultTheme, AppTheme.dark);
    });

    test('is the first value declared on the enum', () {
      expect(AppTheme.values.first, AppTheme.defaultTheme);
    });
  });

  group('AppTheme.toStorageValue', () {
    test('serializes every variant to its enum name', () {
      for (final theme in AppTheme.values) {
        expect(theme.toStorageValue(), theme.name);
      }
    });
  });

  group('AppTheme.fromStorageValue', () {
    test('parses every known enum name back to its value', () {
      for (final theme in AppTheme.values) {
        expect(AppTheme.fromStorageValue(theme.name), theme);
      }
    });

    test('returns defaultTheme when raw is null', () {
      expect(AppTheme.fromStorageValue(null), AppTheme.defaultTheme);
    });

    test('returns defaultTheme when raw is empty', () {
      expect(AppTheme.fromStorageValue(''), AppTheme.defaultTheme);
    });

    test('returns defaultTheme when raw is unknown', () {
      expect(AppTheme.fromStorageValue('rainbow'), AppTheme.defaultTheme);
    });
  });
}
```

- [ ] **Step 2.2: Run the tests to verify they fail**

Run: `flutter test test/features/theme/domain/app_theme_test.dart`
Expected: compilation error (`Target of URI doesn't exist`) — the source file does not exist yet.

- [ ] **Step 2.3: Implement `AppTheme`**

Write `lib/features/theme/domain/app_theme.dart`:

```dart
enum AppTheme {
  dark,
  standard,
  pink,
  matrix;

  static const AppTheme defaultTheme = AppTheme.dark;

  String toStorageValue() => name;

  static AppTheme fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return defaultTheme;
    }
    for (final theme in AppTheme.values) {
      if (theme.name == raw) {
        return theme;
      }
    }
    return defaultTheme;
  }
}
```

- [ ] **Step 2.4: Run the tests to verify they pass**

Run: `flutter test test/features/theme/domain/app_theme_test.dart`
Expected: all tests pass (8 test cases including the loop assertions).

- [ ] **Step 2.5: Full suite sanity**

Run: `flutter analyze` + `flutter test`
Expected: 0 issues, all tests pass.

- [ ] **Step 2.6: Commit**

```bash
git add lib/features/theme/domain/app_theme.dart test/features/theme/domain/app_theme_test.dart
git commit -m "feat(theme): add AppTheme enum with storage serialization

Dark is the declared default. Unknown or missing stored values fall back
to Dark."
```

---

## Task 3: Data — `ThemePreferenceStorage`

Wrap `SharedPreferences` under the key `theme_preference`.

**Files:**
- Create: `lib/features/theme/data/theme_preference_storage.dart`
- Test: `test/features/theme/data/theme_preference_storage_test.dart`

- [ ] **Step 3.1: Write the failing tests**

Write `test/features/theme/data/theme_preference_storage_test.dart`:

```dart
import 'package:cookmate/features/theme/data/theme_preference_storage.dart';
import 'package:cookmate/features/theme/domain/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemePreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = ThemePreferenceStorage(prefs);
  });

  test('read returns AppTheme.dark when nothing is stored', () {
    expect(storage.read(), AppTheme.dark);
  });

  test('read returns the stored theme for every known value', () async {
    for (final theme in AppTheme.values) {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_preference': theme.name,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = ThemePreferenceStorage(prefs);

      expect(storage.read(), theme);
    }
  });

  test('read returns AppTheme.dark when stored value is unknown', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_preference': 'rainbow',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = ThemePreferenceStorage(prefs);

    expect(storage.read(), AppTheme.dark);
  });

  test('write then read returns the written theme', () async {
    await storage.write(AppTheme.matrix);

    expect(storage.read(), AppTheme.matrix);
  });

  test('write overwrites a previous value', () async {
    await storage.write(AppTheme.pink);
    await storage.write(AppTheme.standard);

    expect(storage.read(), AppTheme.standard);
  });
}
```

- [ ] **Step 3.2: Run the tests to verify they fail**

Run: `flutter test test/features/theme/data/theme_preference_storage_test.dart`
Expected: compilation error — the storage class does not exist.

- [ ] **Step 3.3: Implement the storage**

Write `lib/features/theme/data/theme_preference_storage.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_theme.dart';

class ThemePreferenceStorage {
  ThemePreferenceStorage(this._prefs);

  static const _key = 'theme_preference';

  final SharedPreferences _prefs;

  AppTheme read() {
    try {
      return AppTheme.fromStorageValue(_prefs.getString(_key));
    } catch (error, stack) {
      debugPrint('Failed to read theme preference: $error\n$stack');
      return AppTheme.defaultTheme;
    }
  }

  Future<void> write(AppTheme theme) async {
    await _prefs.setString(_key, theme.toStorageValue());
  }
}
```

- [ ] **Step 3.4: Run the tests to verify they pass**

Run: `flutter test test/features/theme/data/theme_preference_storage_test.dart`
Expected: all 5 tests pass.

- [ ] **Step 3.5: Commit**

```bash
git add lib/features/theme/data/theme_preference_storage.dart test/features/theme/data/theme_preference_storage_test.dart
git commit -m "feat(theme): persist AppTheme choice in SharedPreferences"
```

---

## Task 4: Theme builders — refactor `lib/core/theme.dart`

Replace `buildLightTheme` / `buildDarkTheme` with a single `buildThemeData(AppTheme)` that returns the palette-specific `ThemeData`.

**Files:**
- Modify: `lib/core/theme.dart` (full rewrite)
- Test: `test/core/theme_test.dart` (new)

- [ ] **Step 4.1: Write the failing tests**

Write `test/core/theme_test.dart`:

```dart
import 'package:cookmate/core/theme.dart';
import 'package:cookmate/features/theme/domain/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildThemeData', () {
    test('returns a Material 3 ThemeData for every AppTheme', () {
      for (final theme in AppTheme.values) {
        final data = buildThemeData(theme);

        expect(data.useMaterial3, isTrue, reason: 'theme=$theme');
      }
    });

    test('Dark is dark', () {
      expect(buildThemeData(AppTheme.dark).brightness, Brightness.dark);
    });

    test('Standard is light', () {
      expect(buildThemeData(AppTheme.standard).brightness, Brightness.light);
    });

    test('Pink is light', () {
      expect(buildThemeData(AppTheme.pink).brightness, Brightness.light);
    });

    test('Matrix is dark with pure black scaffold and phosphor primary', () {
      final data = buildThemeData(AppTheme.matrix);

      expect(data.brightness, Brightness.dark);
      expect(data.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(data.colorScheme.primary, const Color(0xFF00FF41));
    });
  });
}
```

- [ ] **Step 4.2: Run the tests to verify they fail**

Run: `flutter test test/core/theme_test.dart`
Expected: compilation error — `buildThemeData` does not exist (only `buildLightTheme` / `buildDarkTheme` do).

- [ ] **Step 4.3: Rewrite `lib/core/theme.dart`**

Full replacement of `lib/core/theme.dart`:

```dart
import 'package:flutter/material.dart';

import '../features/theme/domain/app_theme.dart';

ThemeData buildThemeData(AppTheme theme) {
  switch (theme) {
    case AppTheme.dark:
      return _buildDark();
    case AppTheme.standard:
      return _buildStandard();
    case AppTheme.pink:
      return _buildPink();
    case AppTheme.matrix:
      return _buildMatrix();
  }
}

ThemeData _buildDark() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

ThemeData _buildStandard() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      useMaterial3: true,
    );

ThemeData _buildPink() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEC407A)),
      useMaterial3: true,
    );

ThemeData _buildMatrix() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF00FF41),
    onPrimary: Color(0xFF000000),
    secondary: Color(0xFF39FF14),
    onSecondary: Color(0xFF000000),
    surface: Color(0xFF0A0F0A),
    onSurface: Color(0xFF39FF14),
    error: Color(0xFFFF5555),
    onError: Color(0xFF000000),
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF000000),
    useMaterial3: true,
  );
}
```

- [ ] **Step 4.4: Run the tests to verify they pass**

Run: `flutter test test/core/theme_test.dart`
Expected: all 5 test cases pass.

- [ ] **Step 4.5: Verify nothing else broke yet**

Run: `flutter analyze`
Expected: two errors on `lib/app.dart` referencing the removed `buildLightTheme` / `buildDarkTheme`. Leave them — Task 7 fixes app wiring.

Run: `flutter test`
Expected: `lib/app.dart` compilation error blocks the suite. **This is fine — proceed.** We will restore green at the end of Task 7.

- [ ] **Step 4.6: Commit**

```bash
git add lib/core/theme.dart test/core/theme_test.dart
git commit -m "feat(theme): introduce buildThemeData with four fixed palettes

Replaces buildLightTheme/buildDarkTheme. Next commits wire the app.
Build is intentionally red until the app wiring task lands."
```

---

## Task 5: Providers — theme preference + derived theme data

Two Riverpod providers: an `AsyncNotifierProvider<ThemePreferenceNotifier, AppTheme>` that owns persistence, and a synchronous `Provider<ThemeData>` that maps the current `AppTheme` to its `ThemeData`.

**Files:**
- Create: `lib/features/theme/providers.dart`
- Test: `test/features/theme/providers_test.dart`

- [ ] **Step 5.1: Write the failing tests**

Write `test/features/theme/providers_test.dart`:

```dart
import 'package:cookmate/core/theme.dart';
import 'package:cookmate/features/theme/domain/app_theme.dart';
import 'package:cookmate/features/theme/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer _container() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('themePreferenceProvider', () {
    test('builds with AppTheme.dark when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = _container();

      final value = await container.read(themePreferenceProvider.future);

      expect(value, AppTheme.dark);
    });

    test('builds with the stored theme when one exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_preference': 'matrix',
      });
      final container = _container();

      final value = await container.read(themePreferenceProvider.future);

      expect(value, AppTheme.matrix);
    });

    test('setPreference updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = _container();
      await container.read(themePreferenceProvider.future);

      await container
          .read(themePreferenceProvider.notifier)
          .setPreference(AppTheme.pink);

      expect(
        container.read(themePreferenceProvider).valueOrNull,
        AppTheme.pink,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme_preference'), 'pink');
    });
  });

  group('themeDataProvider', () {
    test('returns the default theme while preference is loading', () {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = _container();

      final data = container.read(themeDataProvider);

      expect(data.brightness, Brightness.dark);
      expect(
        data.colorScheme.primary,
        buildThemeData(AppTheme.defaultTheme).colorScheme.primary,
      );
    });

    test('returns the stored theme once loaded', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_preference': 'standard',
      });
      final container = _container();
      await container.read(themePreferenceProvider.future);

      final data = container.read(themeDataProvider);

      expect(data.brightness, Brightness.light);
      expect(
        data.colorScheme.primary,
        buildThemeData(AppTheme.standard).colorScheme.primary,
      );
    });

    test('rebuilds when preference changes', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = _container();
      await container.read(themePreferenceProvider.future);

      await container
          .read(themePreferenceProvider.notifier)
          .setPreference(AppTheme.matrix);

      final data = container.read(themeDataProvider);
      expect(data.scaffoldBackgroundColor, const Color(0xFF000000));
      expect(data.colorScheme.primary, const Color(0xFF00FF41));
    });
  });
}
```

- [ ] **Step 5.2: Run the tests to verify they fail**

Run: `flutter test test/features/theme/providers_test.dart`
Expected: compilation error — `lib/features/theme/providers.dart` does not exist.

- [ ] **Step 5.3: Implement the providers**

Write `lib/features/theme/providers.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import '../../core/theme.dart';
import 'data/theme_preference_storage.dart';
import 'domain/app_theme.dart';

final themePreferenceStorageProvider =
    FutureProvider<ThemePreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ThemePreferenceStorage(prefs);
});

class ThemePreferenceNotifier extends AsyncNotifier<AppTheme> {
  @override
  Future<AppTheme> build() async {
    final storage = await ref.watch(themePreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(AppTheme theme) async {
    final storage = await ref.read(themePreferenceStorageProvider.future);
    state = const AsyncValue<AppTheme>.loading().copyWithPrevious(state);
    try {
      await storage.write(theme);
      state = AsyncValue.data(theme);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      rethrow;
    }
  }
}

final themePreferenceProvider =
    AsyncNotifierProvider<ThemePreferenceNotifier, AppTheme>(
  ThemePreferenceNotifier.new,
);

final themeDataProvider = Provider<ThemeData>((ref) {
  final theme =
      ref.watch(themePreferenceProvider).valueOrNull ?? AppTheme.defaultTheme;
  return buildThemeData(theme);
});
```

- [ ] **Step 5.4: Run the tests to verify they pass**

Run: `flutter test test/features/theme/providers_test.dart`
Expected: all 6 tests pass.

- [ ] **Step 5.5: Commit**

```bash
git add lib/features/theme/providers.dart test/features/theme/providers_test.dart
git commit -m "feat(theme): add themePreferenceProvider and themeDataProvider"
```

---

## Task 6: i18n — add theme strings

Add seven new keys to every ARB file, keeping `app_en.arb` as the template with `@`-descriptions.

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_de.arb`

- [ ] **Step 6.1: Update `lib/l10n/app_en.arb`**

Insert the following keys immediately before the `homeTabChat` block (keeping the trailing comma on the previous entry). The block to insert:

```json
  "settingsThemeTitle": "Theme",
  "@settingsThemeTitle": { "description": "Title of the theme setting tile." },

  "settingsThemeDialogTitle": "Choose theme",
  "@settingsThemeDialogTitle": { "description": "Title of the theme picker dialog." },

  "settingsThemeOptionDark": "Dark",
  "@settingsThemeOptionDark": { "description": "Label for the Dark theme option in the picker." },

  "settingsThemeOptionStandard": "Standard",
  "@settingsThemeOptionStandard": { "description": "Label for the Standard theme option in the picker." },

  "settingsThemeOptionPink": "Pink",
  "@settingsThemeOptionPink": { "description": "Label for the Pink theme option in the picker." },

  "settingsThemeOptionMatrix": "Matrix",
  "@settingsThemeOptionMatrix": { "description": "Label for the Matrix theme option in the picker. Proper name — keep identical in all locales." },

  "settingsThemeChangeFailureSnackbar": "Couldn't change theme. Please try again.",
  "@settingsThemeChangeFailureSnackbar": { "description": "Shown when persisting the new theme fails." },
```

- [ ] **Step 6.2: Update `lib/l10n/app_fr.arb`**

Insert immediately before `"homeTabChat"`:

```json
  "settingsThemeTitle": "Thème",
  "settingsThemeDialogTitle": "Choisir le thème",
  "settingsThemeOptionDark": "Sombre",
  "settingsThemeOptionStandard": "Standard",
  "settingsThemeOptionPink": "Rose",
  "settingsThemeOptionMatrix": "Matrix",
  "settingsThemeChangeFailureSnackbar": "Impossible de changer de thème. Veuillez réessayer.",
```

- [ ] **Step 6.3: Update `lib/l10n/app_es.arb`**

Insert immediately before `"homeTabChat"`:

```json
  "settingsThemeTitle": "Tema",
  "settingsThemeDialogTitle": "Elegir tema",
  "settingsThemeOptionDark": "Oscuro",
  "settingsThemeOptionStandard": "Estándar",
  "settingsThemeOptionPink": "Rosa",
  "settingsThemeOptionMatrix": "Matrix",
  "settingsThemeChangeFailureSnackbar": "No se pudo cambiar el tema. Inténtalo de nuevo.",
```

- [ ] **Step 6.4: Update `lib/l10n/app_de.arb`**

Insert immediately before `"homeTabChat"`:

```json
  "settingsThemeTitle": "Design",
  "settingsThemeDialogTitle": "Design auswählen",
  "settingsThemeOptionDark": "Dunkel",
  "settingsThemeOptionStandard": "Standard",
  "settingsThemeOptionPink": "Pink",
  "settingsThemeOptionMatrix": "Matrix",
  "settingsThemeChangeFailureSnackbar": "Design konnte nicht geändert werden. Bitte erneut versuchen.",
```

- [ ] **Step 6.5: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: exits 0. The generated files under `lib/l10n/app_localizations*.dart` now expose the seven new getters.

Note: the project uses `generate: true` in `pubspec.yaml`, which also runs `gen-l10n` on `flutter pub get`. Running `flutter gen-l10n` explicitly here is faster and avoids re-resolving packages.

- [ ] **Step 6.6: Sanity check generated output**

Run: `flutter analyze`
Expected: still the two `lib/app.dart` errors from Task 4, nothing new. The ARB additions should compile cleanly.

- [ ] **Step 6.7: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_es.arb lib/l10n/app_de.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_fr.dart lib/l10n/app_localizations_es.dart lib/l10n/app_localizations_de.dart
git commit -m "feat(i18n): add theme picker strings in en/fr/es/de"
```

---

## Task 7: App wiring — switch `MaterialApp` to `themeDataProvider`

Replace the three theme-related props on `MaterialApp.router` with a single `theme:` fed by the provider. This finally restores green.

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 7.1: Rewrite `CookmateApp.build`**

Replace the body of `lib/app.dart`'s `CookmateApp.build` with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(effectiveLocaleProvider);
    final themeData = ref.watch(themeDataProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: themeData,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLocale,
      routerConfig: router,
    );
  }
```

Update imports at the top of the file: drop `import 'core/theme.dart';`, add `import 'features/theme/providers.dart';`. The `resolveLocale` function and its visibility annotation stay unchanged.

- [ ] **Step 7.2: Verify analyze is clean**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 7.3: Verify full suite is green**

Run: `flutter test`
Expected: all tests pass, including the existing `test/app_test.dart` (it only covers `resolveLocale` which is untouched).

- [ ] **Step 7.4: Commit**

```bash
git add lib/app.dart
git commit -m "feat(theme): feed MaterialApp from themeDataProvider

Drops themeMode / darkTheme in favor of a single theme driven by the
user-selected AppTheme."
```

---

## Task 8: Presentation — `ThemePickerTile`

A settings tile that mirrors `LanguagePickerTile`: a `ListTile` that opens a `SimpleDialog` with a `RadioGroup<AppTheme>`.

**Files:**
- Create: `lib/features/theme/presentation/theme_picker_tile.dart`
- Test: `test/features/theme/presentation/theme_picker_tile_test.dart`

- [ ] **Step 8.1: Write the failing tests**

Write `test/features/theme/presentation/theme_picker_tile_test.dart`:

```dart
import 'package:cookmate/features/theme/presentation/theme_picker_tile.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  return AppLocalizations.of(tester.element(find.byType(Scaffold)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the Dark option label as subtitle on first launch',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ThemePickerTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsThemeTitle), findsOneWidget);
    expect(find.text(l10n.settingsThemeOptionDark), findsOneWidget);
  });

  testWidgets('shows the stored theme label as subtitle', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'theme_preference': 'matrix',
    });

    await tester.pumpWidget(_wrap(const ThemePickerTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsThemeOptionMatrix), findsOneWidget);
  });

  testWidgets('tapping a dialog option updates the subtitle', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ThemePickerTile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    await tester.tap(find.text(l10n.settingsThemeOptionPink));
    await tester.pumpAndSettle();

    expect(find.text(l10n.settingsThemeOptionPink), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_preference'), 'pink');
  });
}
```

- [ ] **Step 8.2: Run the tests to verify they fail**

Run: `flutter test test/features/theme/presentation/theme_picker_tile_test.dart`
Expected: compilation error — `ThemePickerTile` does not exist.

- [ ] **Step 8.3: Implement `ThemePickerTile`**

Write `lib/features/theme/presentation/theme_picker_tile.dart`:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_theme.dart';
import '../providers.dart';

class ThemePickerTile extends ConsumerWidget {
  const ThemePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferenceAsync = ref.watch(themePreferenceProvider);
    final theme = preferenceAsync.valueOrNull ?? AppTheme.defaultTheme;

    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l10n.settingsThemeTitle),
      subtitle: Text(_themeLabel(l10n, theme)),
      onTap: () => _openDialog(context, ref, theme),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    AppTheme current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<AppTheme>(
      context: context,
      builder: (dialogContext) {
        return RadioGroup<AppTheme>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              Navigator.of(dialogContext).pop(value);
            }
          },
          child: SimpleDialog(
            title: Text(l10n.settingsThemeDialogTitle),
            children: [
              for (final theme in AppTheme.values)
                _OptionTile(label: _themeLabel(l10n, theme), value: theme),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (selected == null) return;
    if (selected == current) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(themePreferenceProvider.notifier)
          .setPreference(selected);
    } catch (error, stack) {
      debugPrint('Failed to change theme: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsThemeChangeFailureSnackbar)),
      );
    }
  }

  String _themeLabel(AppLocalizations l10n, AppTheme theme) {
    return switch (theme) {
      AppTheme.dark => l10n.settingsThemeOptionDark,
      AppTheme.standard => l10n.settingsThemeOptionStandard,
      AppTheme.pink => l10n.settingsThemeOptionPink,
      AppTheme.matrix => l10n.settingsThemeOptionMatrix,
    };
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.value});

  final String label;
  final AppTheme value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<AppTheme>(
      title: Text(label),
      value: value,
    );
  }
}
```

- [ ] **Step 8.4: Run the tests to verify they pass**

Run: `flutter test test/features/theme/presentation/theme_picker_tile_test.dart`
Expected: all 3 widget tests pass.

- [ ] **Step 8.5: Full suite stays green**

Run: `flutter analyze` + `flutter test`
Expected: 0 analyze issues, all tests pass.

- [ ] **Step 8.6: Commit**

```bash
git add lib/features/theme/presentation/theme_picker_tile.dart test/features/theme/presentation/theme_picker_tile_test.dart
git commit -m "feat(theme): add ThemePickerTile for settings page"
```

---

## Task 9: Settings page — insert the tile

Place `ThemePickerTile` above `LanguagePickerTile` with a divider, matching the visual rhythm of the existing layout.

**Files:**
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 9.1: Update the settings page**

In [lib/features/settings/presentation/settings_page.dart](../../../lib/features/settings/presentation/settings_page.dart):

1. Add import near the existing relative imports:

```dart
import '../../theme/presentation/theme_picker_tile.dart';
```

2. Replace the `children:` list of the `ListView` with:

```dart
        children: [
          const ThemePickerTile(),
          const Divider(height: 1),
          const LanguagePickerTile(),
          const Divider(height: 1),
          const SizedBox(height: 24),
          Center(
            child: FilledButton.tonal(
              onPressed: isBusy
                  ? null
                  : () => ref.read(authStateProvider.notifier).logout(),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.settingsLogoutButton),
            ),
          ),
        ],
```

- [ ] **Step 9.2: Verify the full suite is still green**

Run: `flutter analyze` + `flutter test`
Expected: 0 analyze issues, all tests pass.

- [ ] **Step 9.3: Smoke-test the app manually**

Run: `flutter run` on a connected device or simulator.

Manual checklist — verify each item and note the outcome before committing:
- [ ] First launch (after `adb shell pm clear` on Android, or fresh install) shows the Dark theme.
- [ ] Settings → Theme opens a dialog with four options in order: Dark, Standard, Pink, Matrix.
- [ ] Selecting Pink immediately repaints the app with a pink primary.
- [ ] Selecting Matrix immediately repaints to pure black scaffold + phosphor green accents.
- [ ] Restart the app: the last selection persists.
- [ ] Switch language to French, then open Theme dialog → the option labels are localized (Sombre, Standard, Rose, Matrix).

If any item fails, do **not** commit. Fix and re-run Step 9.2 + 9.3.

- [ ] **Step 9.4: Commit**

```bash
git add lib/features/settings/presentation/settings_page.dart
git commit -m "feat(settings): expose the theme picker on the settings page"
```

---

## Task 10: Open PR

- [ ] **Step 10.1: Push and open the PR**

Invoke the `ai-dev-extensions:github-create-update-pr` skill to push the branch and open the PR. PR title:

```
feat(theme): add user-selectable theme with four palettes
```

PR body summary:
- Four fixed themes (Dark default, Standard, Pink, Matrix).
- Preference persisted via `SharedPreferences` under `theme_preference`.
- Settings page exposes a new tile matching the language picker pattern.
- New strings localized in en/fr/es/de.
- Mirror of the existing locale preference architecture.

---

## Done — sanity checklist before handoff

- [ ] `flutter analyze` exits 0.
- [ ] `flutter test` exits 0.
- [ ] Manual smoke test from Step 9.3 passed.
- [ ] CI on the PR is green (the `github-create-update-pr` skill blocks on this).
