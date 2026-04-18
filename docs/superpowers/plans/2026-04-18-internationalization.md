# Internationalization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add FR + EN + ES + DE internationalization to Cookmate with system-locale default, an in-app manual override persisted across launches, and EN fallback for unsupported device locales.

**Architecture:** Use Flutter's official `gen_l10n` toolchain with ARB files under `lib/l10n/`. A new `features/l10n/` module owns a `LocalePreference` sealed type persisted via `shared_preferences`, exposed through Riverpod providers. `MaterialApp.router` consumes an `effectiveLocaleProvider` and a `localeResolutionCallback` that maps unsupported device locales to EN. A language picker `ListTile` in `SettingsPage` lets the user force a language.

**Tech Stack:** Flutter (Dart 3.11+), `flutter_localizations` (SDK), `gen_l10n`, `shared_preferences`, `flutter_riverpod`, `go_router`, Material 3.

**Spec:** `docs/superpowers/specs/2026-04-18-internationalization-design.md`.

**Note on testing:** The spec explicitly excludes automated tests at this stage (consistent with the bootstrap baseline). Each task ends with `flutter analyze` and a manual verification step rather than a test run. A test suite is out of scope and will be added alongside the broader test work in a later plan.

---

## File Structure

**New files:**
- `l10n.yaml` — gen_l10n configuration (repo root).
- `lib/l10n/app_en.arb` — source-of-truth translations (English).
- `lib/l10n/app_fr.arb` — French translations.
- `lib/l10n/app_es.arb` — Spanish translations.
- `lib/l10n/app_de.arb` — German translations.
- `lib/features/l10n/domain/locale_preference.dart` — `LocalePreference` sealed class + codec.
- `lib/features/l10n/data/locale_preference_storage.dart` — `shared_preferences` wrapper.
- `lib/features/l10n/providers.dart` — `localePreferenceStorageProvider`, `localePreferenceProvider`, `effectiveLocaleProvider`.
- `lib/features/l10n/presentation/language_picker_tile.dart` — Settings `ListTile` + dialog.

**Modified files:**
- `pubspec.yaml` — add `flutter_localizations`, `shared_preferences`, `generate: true`.
- `lib/app.dart` — wire `localizationsDelegates`, `supportedLocales`, `locale`, `onGenerateTitle`, `localeResolutionCallback`.
- `lib/features/auth/presentation/login_page.dart` — replace hardcoded FR strings.
- `lib/features/settings/presentation/settings_page.dart` — replace hardcoded FR strings, add language picker tile above logout button.
- `lib/features/home/presentation/home_shell.dart` — replace tab labels.
- `lib/features/chat/presentation/chat_page.dart` — replace hardcoded FR strings.

---

## Task 1: Add dependencies and gen_l10n bootstrap

**Files:**
- Modify: `pubspec.yaml`
- Create: `l10n.yaml`
- Create: `lib/l10n/app_en.arb`

- [ ] **Step 1: Update `pubspec.yaml`**

Add `flutter_localizations` (SDK) and `shared_preferences` to dependencies. Add `generate: true` under the `flutter:` section so Flutter runs `gen_l10n` automatically on `pub get`.

Replace the `dependencies:` block and the `flutter:` section as follows (leave everything else untouched):

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  flutter_secure_storage: ^9.2.2
  shared_preferences: ^2.3.0
```

```yaml
flutter:
  generate: true
  uses-material-design: true
```

- [ ] **Step 2: Create `l10n.yaml` at the repo root**

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

- [ ] **Step 3: Create `lib/l10n/app_en.arb` with every string (English, source of truth)**

```json
{
  "@@locale": "en",

  "appTitle": "Cookmate",
  "@appTitle": { "description": "Application display name. Same in all locales." },

  "loginTitle": "Cookmate",
  "@loginTitle": { "description": "Large title shown on the login screen." },

  "loginSubtitle": "Log in with your Cookidoo account.",
  "@loginSubtitle": { "description": "Short instruction under the login title." },

  "loginEmailLabel": "Cookidoo email",
  "@loginEmailLabel": { "description": "Label for the email input on the login screen." },

  "loginPasswordLabel": "Password",
  "@loginPasswordLabel": { "description": "Label for the password input on the login screen." },

  "loginSubmitButton": "Log in",
  "@loginSubmitButton": { "description": "Submit button on the login screen." },

  "loginFailureSnackbar": "Couldn't log in. Please try again in a moment.",
  "@loginFailureSnackbar": { "description": "Shown when saving credentials fails." },

  "chatTitle": "Chat",
  "@chatTitle": { "description": "AppBar title on the chat screen." },

  "chatPlaceholder": "Chat (coming soon)",
  "@chatPlaceholder": { "description": "Placeholder body shown on the chat screen." },

  "settingsTitle": "Settings",
  "@settingsTitle": { "description": "AppBar title on the settings screen." },

  "settingsLogoutButton": "Log out",
  "@settingsLogoutButton": { "description": "Logout button label on the settings screen." },

  "settingsLogoutFailureSnackbar": "Couldn't log out. Please try again in a moment.",
  "@settingsLogoutFailureSnackbar": { "description": "Shown when clearing credentials fails." },

  "settingsLanguageTitle": "Language",
  "@settingsLanguageTitle": { "description": "Title of the language setting tile." },

  "settingsLanguageFollowSystem": "Follow system ({language})",
  "@settingsLanguageFollowSystem": {
    "description": "Subtitle when the user has not overridden the language. Parameter is the current resolved language name in its own language.",
    "placeholders": { "language": { "type": "String", "example": "English" } }
  },

  "settingsLanguageDialogTitle": "Choose language",
  "@settingsLanguageDialogTitle": { "description": "Title of the language picker dialog." },

  "settingsLanguageOptionSystem": "Follow system",
  "@settingsLanguageOptionSystem": { "description": "Radio option meaning the app follows the device locale." },

  "settingsLanguageChangeFailureSnackbar": "Couldn't change language. Please try again.",
  "@settingsLanguageChangeFailureSnackbar": { "description": "Shown when persisting the new locale fails." },

  "homeTabChat": "Chat",
  "@homeTabChat": { "description": "Bottom navigation label for the chat tab." },

  "homeTabSettings": "Settings",
  "@homeTabSettings": { "description": "Bottom navigation label for the settings tab." }
}
```

- [ ] **Step 4: Install dependencies and trigger code generation**

Run: `flutter pub get`

Expected: `Got dependencies!` and gen_l10n creates `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart` (and per-locale files). No errors.

- [ ] **Step 5: Verify generated code is usable**

Run: `flutter analyze`

Expected: no new analyzer errors. The `AppLocalizations` import path will be `package:flutter_gen/gen_l10n/app_localizations.dart`.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock l10n.yaml lib/l10n/app_en.arb
git commit -m "feat(l10n): add gen_l10n bootstrap with english arb"
```

---

## Task 2: Add FR, ES, DE translations

**Files:**
- Create: `lib/l10n/app_fr.arb`
- Create: `lib/l10n/app_es.arb`
- Create: `lib/l10n/app_de.arb`

- [ ] **Step 1: Create `lib/l10n/app_fr.arb`**

Language name labels ("Français", "English", "Español", "Deutsch") are intentionally NOT translated — each language is displayed in its own language across all locales. These labels therefore live in the picker widget as constants, not in ARB.

```json
{
  "@@locale": "fr",
  "appTitle": "Cookmate",
  "loginTitle": "Cookmate",
  "loginSubtitle": "Connectez-vous avec votre compte Cookidoo.",
  "loginEmailLabel": "Email Cookidoo",
  "loginPasswordLabel": "Mot de passe",
  "loginSubmitButton": "Se connecter",
  "loginFailureSnackbar": "Impossible de se connecter. Réessayez dans un instant.",
  "chatTitle": "Chat",
  "chatPlaceholder": "Chat (à venir)",
  "settingsTitle": "Réglages",
  "settingsLogoutButton": "Se déconnecter",
  "settingsLogoutFailureSnackbar": "Impossible de se déconnecter. Réessayez dans un instant.",
  "settingsLanguageTitle": "Langue",
  "settingsLanguageFollowSystem": "Suivre le système ({language})",
  "settingsLanguageDialogTitle": "Choisir la langue",
  "settingsLanguageOptionSystem": "Suivre le système",
  "settingsLanguageChangeFailureSnackbar": "Impossible de changer la langue. Réessayez.",
  "homeTabChat": "Chat",
  "homeTabSettings": "Réglages"
}
```

- [ ] **Step 2: Create `lib/l10n/app_es.arb`**

```json
{
  "@@locale": "es",
  "appTitle": "Cookmate",
  "loginTitle": "Cookmate",
  "loginSubtitle": "Inicia sesión con tu cuenta Cookidoo.",
  "loginEmailLabel": "Correo Cookidoo",
  "loginPasswordLabel": "Contraseña",
  "loginSubmitButton": "Iniciar sesión",
  "loginFailureSnackbar": "No se pudo iniciar sesión. Inténtalo de nuevo en un momento.",
  "chatTitle": "Chat",
  "chatPlaceholder": "Chat (próximamente)",
  "settingsTitle": "Ajustes",
  "settingsLogoutButton": "Cerrar sesión",
  "settingsLogoutFailureSnackbar": "No se pudo cerrar sesión. Inténtalo de nuevo en un momento.",
  "settingsLanguageTitle": "Idioma",
  "settingsLanguageFollowSystem": "Seguir el sistema ({language})",
  "settingsLanguageDialogTitle": "Elegir idioma",
  "settingsLanguageOptionSystem": "Seguir el sistema",
  "settingsLanguageChangeFailureSnackbar": "No se pudo cambiar el idioma. Inténtalo de nuevo.",
  "homeTabChat": "Chat",
  "homeTabSettings": "Ajustes"
}
```

- [ ] **Step 3: Create `lib/l10n/app_de.arb`**

```json
{
  "@@locale": "de",
  "appTitle": "Cookmate",
  "loginTitle": "Cookmate",
  "loginSubtitle": "Melde dich mit deinem Cookidoo-Konto an.",
  "loginEmailLabel": "Cookidoo-E-Mail",
  "loginPasswordLabel": "Passwort",
  "loginSubmitButton": "Anmelden",
  "loginFailureSnackbar": "Anmeldung fehlgeschlagen. Bitte versuche es gleich noch einmal.",
  "chatTitle": "Chat",
  "chatPlaceholder": "Chat (demnächst)",
  "settingsTitle": "Einstellungen",
  "settingsLogoutButton": "Abmelden",
  "settingsLogoutFailureSnackbar": "Abmeldung fehlgeschlagen. Bitte versuche es gleich noch einmal.",
  "settingsLanguageTitle": "Sprache",
  "settingsLanguageFollowSystem": "System folgen ({language})",
  "settingsLanguageDialogTitle": "Sprache auswählen",
  "settingsLanguageOptionSystem": "System folgen",
  "settingsLanguageChangeFailureSnackbar": "Sprache konnte nicht geändert werden. Bitte versuche es erneut.",
  "homeTabChat": "Chat",
  "homeTabSettings": "Einstellungen"
}
```

- [ ] **Step 4: Regenerate and analyze**

Run: `flutter pub get` (gen_l10n runs automatically).
Run: `flutter analyze`

Expected: no errors. Generated `app_localizations_fr.dart`, `app_localizations_es.dart`, `app_localizations_de.dart` exist in `.dart_tool/flutter_gen/gen_l10n/`.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_fr.arb lib/l10n/app_es.arb lib/l10n/app_de.arb
git commit -m "feat(l10n): add french, spanish and german translations"
```

---

## Task 3: Wire localizations into MaterialApp

**Files:**
- Modify: `lib/app.dart`

This task enables the localization delegates and the system-locale + EN fallback behavior. The manual override comes in Task 7.

- [ ] **Step 1: Rewrite `lib/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

class CookmateApp extends ConsumerWidget {
  const CookmateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) {
          return const Locale('en');
        }
        for (final supported in supportedLocales) {
          if (supported.languageCode == deviceLocale.languageCode) {
            return supported;
          }
        }
        return const Locale('en');
      },
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze`

Expected: no errors. `AppLocalizations.of(context)` is a non-null getter because `nullable-getter: false` in `l10n.yaml`.

- [ ] **Step 3: Manual smoke test**

Run the app on any connected device or simulator: `flutter run`

Expected: the app still launches into the login screen with the existing French hardcoded strings (we have not replaced them yet). No visible regression.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat(l10n): wire localization delegates with en fallback"
```

---

## Task 4: Replace hardcoded strings with AppLocalizations

**Files:**
- Modify: `lib/features/auth/presentation/login_page.dart`
- Modify: `lib/features/home/presentation/home_shell.dart`
- Modify: `lib/features/chat/presentation/chat_page.dart`
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Update `login_page.dart`**

Replace the existing file with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(authStateProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider);
    final isBusy = auth.isLoading;

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        debugPrint('Login failed: ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginFailureSnackbar)),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.loginTitle,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.loginSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.loginEmailLabel,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.loginPasswordLabel,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _emailController,
                    _passwordController,
                  ]),
                  builder: (context, _) {
                    final canSubmit = !isBusy &&
                        _emailController.text.trim().isNotEmpty &&
                        _passwordController.text.isNotEmpty;
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: canSubmit ? _submit : null,
                        child: isBusy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.loginSubmitButton),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update `home_shell.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l10n.homeTabChat,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.homeTabSettings,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Update `chat_page.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatTitle)),
      body: Center(child: Text(l10n.chatPlaceholder)),
    );
  }
}
```

- [ ] **Step 4: Update `settings_page.dart` (strings only, picker comes in Task 8)**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider);
    final isBusy = auth.isLoading;

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        debugPrint('Logout failed: ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsLogoutFailureSnackbar)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Center(
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
    );
  }
}
```

- [ ] **Step 5: Analyze**

Run: `flutter analyze`

Expected: zero errors and zero warnings related to l10n.

- [ ] **Step 6: Manual smoke test**

Run: `flutter run`

Then, on the device:
- With device in French → login/settings/chat/tabs show French strings.
- Change device language to English (OS settings) → hot restart → strings switch to English.
- Repeat with Spanish and German.
- Change device language to Italian → app shows English (fallback).

- [ ] **Step 7: Commit**

```bash
git add lib/features/auth/presentation/login_page.dart lib/features/home/presentation/home_shell.dart lib/features/chat/presentation/chat_page.dart lib/features/settings/presentation/settings_page.dart
git commit -m "feat(l10n): localize existing ui strings"
```

---

## Task 5: LocalePreference domain + storage

**Files:**
- Create: `lib/features/l10n/domain/locale_preference.dart`
- Create: `lib/features/l10n/data/locale_preference_storage.dart`

- [ ] **Step 1: Create `locale_preference.dart`**

```dart
import 'package:flutter/widgets.dart';

sealed class LocalePreference {
  const LocalePreference();

  static const Set<String> supportedLanguageCodes = {'en', 'fr', 'es', 'de'};

  String toStorageValue();

  static LocalePreference fromStorageValue(String? raw) {
    if (raw == null || raw == 'system') {
      return const SystemLocalePreference();
    }
    if (supportedLanguageCodes.contains(raw)) {
      return ForcedLocalePreference(Locale(raw));
    }
    return const SystemLocalePreference();
  }
}

class SystemLocalePreference extends LocalePreference {
  const SystemLocalePreference();

  @override
  String toStorageValue() => 'system';
}

class ForcedLocalePreference extends LocalePreference {
  const ForcedLocalePreference(this.locale);

  final Locale locale;

  @override
  String toStorageValue() => locale.languageCode;
}
```

- [ ] **Step 2: Create `locale_preference_storage.dart`**

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/locale_preference.dart';

class LocalePreferenceStorage {
  LocalePreferenceStorage(this._prefs);

  static const _key = 'locale_preference';

  final SharedPreferences _prefs;

  LocalePreference read() {
    try {
      return LocalePreference.fromStorageValue(_prefs.getString(_key));
    } catch (error, stack) {
      debugPrint('Failed to read locale preference: $error\n$stack');
      return const SystemLocalePreference();
    }
  }

  Future<void> write(LocalePreference preference) async {
    await _prefs.setString(_key, preference.toStorageValue());
  }
}
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze`

Expected: zero errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/l10n/domain/locale_preference.dart lib/features/l10n/data/locale_preference_storage.dart
git commit -m "feat(l10n): add locale preference domain and storage"
```

---

## Task 6: Providers (preference + effective locale)

**Files:**
- Create: `lib/features/l10n/providers.dart`

- [ ] **Step 1: Create `providers.dart`**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/locale_preference_storage.dart';
import 'domain/locale_preference.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final localePreferenceStorageProvider =
    FutureProvider<LocalePreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LocalePreferenceStorage(prefs);
});

class LocalePreferenceNotifier extends AsyncNotifier<LocalePreference> {
  @override
  Future<LocalePreference> build() async {
    final storage = await ref.watch(localePreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(LocalePreference preference) async {
    final storage = await ref.read(localePreferenceStorageProvider.future);
    state = const AsyncValue.loading();
    try {
      await storage.write(preference);
      state = AsyncValue.data(preference);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}

final localePreferenceProvider =
    AsyncNotifierProvider<LocalePreferenceNotifier, LocalePreference>(
  LocalePreferenceNotifier.new,
);

final effectiveLocaleProvider = Provider<Locale?>((ref) {
  final preference = ref.watch(localePreferenceProvider);
  return preference.whenOrNull(
    data: (value) => switch (value) {
      SystemLocalePreference() => null,
      ForcedLocalePreference(:final locale) => locale,
    },
  );
});
```

- [ ] **Step 2: Analyze**

Run: `flutter analyze`

Expected: zero errors. The `switch` pattern-match on the sealed class is exhaustive.

- [ ] **Step 3: Commit**

```bash
git add lib/features/l10n/providers.dart
git commit -m "feat(l10n): add locale preference and effective locale providers"
```

---

## Task 7: Consume effectiveLocaleProvider in MaterialApp

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Add `locale:` to `MaterialApp.router`**

Replace the file with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'features/l10n/providers.dart';

class CookmateApp extends ConsumerWidget {
  const CookmateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(effectiveLocaleProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (deviceLocale == null) {
          return const Locale('en');
        }
        for (final supported in supportedLocales) {
          if (supported.languageCode == deviceLocale.languageCode) {
            return supported;
          }
        }
        return const Locale('en');
      },
      routerConfig: router,
    );
  }
}
```

Note: when `locale` is `null`, Flutter calls `localeResolutionCallback` with the device locale. When `locale` is non-null, the callback is still invoked with that locale; our implementation returns it as-is because it is already a supported `Locale`.

- [ ] **Step 2: Analyze**

Run: `flutter analyze`

Expected: zero errors.

- [ ] **Step 3: Manual smoke test**

Run: `flutter run`

Expected: app still behaves as before (system-locale-driven). The manual override UI comes in Task 8; this task only wires the provider to `MaterialApp`.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart
git commit -m "feat(l10n): consume effective locale in material app"
```

---

## Task 8: Language picker tile + integration in SettingsPage

**Files:**
- Create: `lib/features/l10n/presentation/language_picker_tile.dart`
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Create `language_picker_tile.dart`**

The language labels are displayed in their own language (see spec). That list is the single source of truth for both the subtitle and the dialog options.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/locale_preference.dart';
import '../providers.dart';

const Map<String, String> _languageNames = {
  'fr': 'Français',
  'en': 'English',
  'es': 'Español',
  'de': 'Deutsch',
};

class LanguagePickerTile extends ConsumerWidget {
  const LanguagePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferenceAsync = ref.watch(localePreferenceProvider);
    final preference =
        preferenceAsync.valueOrNull ?? const SystemLocalePreference();

    final subtitle = switch (preference) {
      SystemLocalePreference() => l10n.settingsLanguageFollowSystem(
          _languageNames[Localizations.localeOf(context).languageCode] ??
              Localizations.localeOf(context).languageCode,
        ),
      ForcedLocalePreference(:final locale) =>
        _languageNames[locale.languageCode] ?? locale.languageCode,
    };

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.settingsLanguageTitle),
      subtitle: Text(subtitle),
      onTap: () => _openDialog(context, ref, preference),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    LocalePreference current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<LocalePreference>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(l10n.settingsLanguageDialogTitle),
          children: [
            _OptionTile(
              label: l10n.settingsLanguageOptionSystem,
              value: const SystemLocalePreference(),
              groupValue: current,
            ),
            for (final entry in _languageNames.entries)
              _OptionTile(
                label: entry.value,
                value: ForcedLocalePreference(Locale(entry.key)),
                groupValue: current,
              ),
          ],
        );
      },
    );

    if (selected == null) return;
    if (_isSame(selected, current)) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(localePreferenceProvider.notifier)
          .setPreference(selected);
    } catch (error, stack) {
      debugPrint('Failed to change locale: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsLanguageChangeFailureSnackbar)),
      );
    }
  }

  bool _isSame(LocalePreference a, LocalePreference b) {
    return switch ((a, b)) {
      (SystemLocalePreference(), SystemLocalePreference()) => true,
      (ForcedLocalePreference(locale: final la),
            ForcedLocalePreference(locale: final lb)) =>
        la.languageCode == lb.languageCode,
      _ => false,
    };
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.value,
    required this.groupValue,
  });

  final String label;
  final LocalePreference value;
  final LocalePreference groupValue;

  @override
  Widget build(BuildContext context) {
    final selected = _equals(value, groupValue);
    return RadioListTile<LocalePreference>(
      title: Text(label),
      value: value,
      groupValue: selected ? value : null,
      onChanged: (_) => Navigator.of(context).pop(value),
    );
  }

  static bool _equals(LocalePreference a, LocalePreference b) {
    return switch ((a, b)) {
      (SystemLocalePreference(), SystemLocalePreference()) => true,
      (ForcedLocalePreference(locale: final la),
            ForcedLocalePreference(locale: final lb)) =>
        la.languageCode == lb.languageCode,
      _ => false,
    };
  }
}
```

- [ ] **Step 2: Integrate the tile into `settings_page.dart`**

Replace the file with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';
import '../../l10n/presentation/language_picker_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(authStateProvider);
    final isBusy = auth.isLoading;

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        debugPrint('Logout failed: ${next.error}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsLogoutFailureSnackbar)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
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
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze**

Run: `flutter analyze`

Expected: zero errors.

- [ ] **Step 4: Manual validation (happy paths)**

Run: `flutter run`. Log in so that the settings screen is reachable.

Verify each:
- Subtitle reads "Suivre le système (Français)" with a French device.
- Open dialog → pick English → app switches immediately; subtitle becomes "English"; all screens (login after logout, home tabs, chat) render in English.
- Pick Español → Deutsch → Follow system → each time the app updates without restart.
- Kill and relaunch the app with Settings → Language set to "Español". Verify the app opens in Spanish (preference persisted).
- Reset to "Follow system" → relaunch → app reflects device locale again.

- [ ] **Step 5: Manual validation (fallback)**

Set device locale to Italian. Ensure app language is "Follow system". Relaunch.

Expected: app displays in English across all screens; subtitle reads "Follow system (English)".

- [ ] **Step 6: Commit**

```bash
git add lib/features/l10n/presentation/language_picker_tile.dart lib/features/settings/presentation/settings_page.dart
git commit -m "feat(l10n): add language picker tile in settings"
```

---

## Self-Review Notes

- Every spec section maps to at least one task:
  - Architecture & file layout → Task 1 (config), Tasks 5-8 (feature module).
  - Data model → Task 5.
  - Providers → Task 6.
  - Locale resolution (EN fallback) → Task 3 (callback), Task 7 (consume override).
  - UI (Settings picker, inventory of strings) → Task 4 (existing strings), Task 8 (picker).
  - Error handling (read → default, write → SnackBar) → Task 5 (read defensive), Task 8 (SnackBar on write failure).
- No placeholders remain; every code step is fully written.
- Type consistency verified: `SystemLocalePreference` / `ForcedLocalePreference`, `LocalePreference.fromStorageValue`, `setPreference`, `effectiveLocaleProvider` are used with matching signatures across tasks.
