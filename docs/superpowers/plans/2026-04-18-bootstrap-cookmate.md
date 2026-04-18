# Bootstrap Cookmate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bootstrap a runnable Flutter app (Android + iOS) with a Cookidoo-credentials login screen and a logged-in shell containing two empty tabs (Chat / Settings with logout).

**Architecture:** Feature-based folder layout under `lib/`, Riverpod for state, `go_router` with an auth-redirect guard, `flutter_secure_storage` for persisting Cookidoo credentials. No remote authentication, no tests, no AI integration in this plan — see [the design doc](../specs/2026-04-18-bootstrap-cookmate-design.md).

**Tech Stack:** Flutter (stable), Dart 3+, `flutter_riverpod`, `go_router`, `flutter_secure_storage`, Material 3.

---

## Prerequisites

Flutter SDK is **not** currently installed on the target machine. Before starting Task 1:

- [ ] **Install Flutter via Homebrew Cask**

Run:
```bash
brew install --cask flutter
```

Then verify:
```bash
flutter --version
flutter doctor
```

Resolve any blocking issues `flutter doctor` reports for Android toolchain and Xcode (required to build for both platforms). CocoaPods must be installed for iOS:
```bash
sudo gem install cocoapods
```

---

## File Structure

The Flutter project is created in-place at the repo root (the repo already contains `LICENSE`, `README.md`, and a `.gitignore`).

```
cookmate/
  pubspec.yaml                                          # deps + app metadata
  lib/
    main.dart                                           # runApp(ProviderScope)
    app.dart                                            # MaterialApp.router
    core/
      theme.dart                                        # light + dark Material 3 themes
      router.dart                                       # GoRouter + auth guard
    features/
      auth/
        domain/cookidoo_credentials.dart                # value object
        data/credentials_storage.dart                   # FlutterSecureStorage wrapper
        data/auth_repository.dart                       # save/load/clear
        application/auth_notifier.dart                  # AsyncNotifier<bool>
        providers.dart                                  # all auth providers
        presentation/login_page.dart                    # form
      home/
        presentation/home_shell.dart                    # Scaffold + BottomNavigationBar
      chat/
        presentation/chat_page.dart                     # placeholder
      settings/
        presentation/settings_page.dart                 # logout button
  android/app/src/main/AndroidManifest.xml              # android:label
  android/app/build.gradle.kts                          # applicationId
  ios/Runner/Info.plist                                 # CFBundleDisplayName / CFBundleName
  ios/Runner.xcodeproj/project.pbxproj                  # PRODUCT_BUNDLE_IDENTIFIER
```

---

## Task 1: Initialize the Flutter project in-place

**Files:**
- Create: every standard Flutter scaffold file under `cookmate/` (managed by `flutter create`)
- Modify: existing `.gitignore`, `README.md`, `LICENSE` are preserved by `flutter create` (it skips files that already exist)

- [ ] **Step 1: Generate the Flutter project**

Run from the repo root:
```bash
flutter create \
  --org com.cookmate \
  --project-name cookmate \
  --platforms android,ios \
  --description "AI-powered mobile assistant for your Thermomix." \
  .
```

Expected: Flutter scaffolds `lib/`, `android/`, `ios/`, `pubspec.yaml`, etc. without overwriting `README.md` or `LICENSE`.

- [ ] **Step 2: Verify the scaffold builds**

Run:
```bash
flutter pub get
flutter analyze
```

Expected: `pub get` succeeds; `analyze` reports `No issues found!`.

- [ ] **Step 3: Smoke-run the default counter app on a simulator**

Start an iOS simulator (e.g. `open -a Simulator`) or an Android emulator, then:
```bash
flutter devices
flutter run
```

Expected: The default counter app launches and the "+" button increments. Stop with `q`.

- [ ] **Step 4: Commit the scaffold**

```bash
git add -A
git commit -m "chore: scaffold flutter project with flutter create"
```

---

## Task 2: Add runtime dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add the three runtime dependencies**

Open `pubspec.yaml` and replace the `dependencies:` block so it looks like this (keep the rest of the file as generated, including `dev_dependencies` and `flutter:` sections):

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  flutter_secure_storage: ^9.2.2
```

- [ ] **Step 2: Resolve dependencies**

Run:
```bash
flutter pub get
```

Expected: pub resolves without conflicts.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build(deps): add riverpod, go_router, flutter_secure_storage"
```

---

## Task 3: Theme

**Files:**
- Create: `lib/core/theme.dart`

- [ ] **Step 1: Create the theme module**

Create `lib/core/theme.dart`:
```dart
import 'package:flutter/material.dart';

const _seed = Color(0xFF2E7D32);

ThemeData buildLightTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _seed),
      useMaterial3: true,
    );

ThemeData buildDarkTheme() => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seed,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
```

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/core/theme.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/theme.dart
git commit -m "feat(core): add material 3 light and dark themes"
```

---

## Task 4: Cookidoo credentials value object

**Files:**
- Create: `lib/features/auth/domain/cookidoo_credentials.dart`

- [ ] **Step 1: Create the value object**

Create `lib/features/auth/domain/cookidoo_credentials.dart`:
```dart
class CookidooCredentials {
  const CookidooCredentials({required this.email, required this.password});

  final String email;
  final String password;
}
```

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/features/auth/domain/cookidoo_credentials.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/domain/cookidoo_credentials.dart
git commit -m "feat(auth): add CookidooCredentials value object"
```

---

## Task 5: Secure credentials storage wrapper

**Files:**
- Create: `lib/features/auth/data/credentials_storage.dart`

- [ ] **Step 1: Implement the storage wrapper**

Create `lib/features/auth/data/credentials_storage.dart`:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/cookidoo_credentials.dart';

class CredentialsStorage {
  CredentialsStorage(this._storage);

  static const _emailKey = 'cookidoo_email';
  static const _passwordKey = 'cookidoo_password';

  final FlutterSecureStorage _storage;

  Future<CookidooCredentials?> read() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null || password == null) return null;
    return CookidooCredentials(email: email, password: password);
  }

  Future<void> write(CookidooCredentials credentials) async {
    await _storage.write(key: _emailKey, value: credentials.email);
    await _storage.write(key: _passwordKey, value: credentials.password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
```

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/features/auth/data/credentials_storage.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/credentials_storage.dart
git commit -m "feat(auth): add secure credentials storage wrapper"
```

---

## Task 6: Auth repository

**Files:**
- Create: `lib/features/auth/data/auth_repository.dart`

- [ ] **Step 1: Implement the repository**

Create `lib/features/auth/data/auth_repository.dart`:
```dart
import '../domain/cookidoo_credentials.dart';
import 'credentials_storage.dart';

class AuthRepository {
  AuthRepository(this._storage);

  final CredentialsStorage _storage;

  Future<CookidooCredentials?> loadCredentials() => _storage.read();

  Future<void> saveCredentials(CookidooCredentials credentials) =>
      _storage.write(credentials);

  Future<void> clearCredentials() => _storage.clear();
}
```

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/features/auth/data/auth_repository.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/data/auth_repository.dart
git commit -m "feat(auth): add auth repository over credentials storage"
```

---

## Task 7: Auth notifier and providers

**Files:**
- Create: `lib/features/auth/application/auth_notifier.dart`
- Create: `lib/features/auth/providers.dart`

- [ ] **Step 1: Create the AsyncNotifier**

Create `lib/features/auth/application/auth_notifier.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/cookidoo_credentials.dart';
import '../providers.dart';

class AuthNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final repository = ref.read(authRepositoryProvider);
    final credentials = await repository.loadCredentials();
    return credentials != null;
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.saveCredentials(
        CookidooCredentials(email: email, password: password),
      );
      return true;
    });
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      await repository.clearCredentials();
      return false;
    });
  }
}
```

- [ ] **Step 2: Create the providers module**

Create `lib/features/auth/providers.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'application/auth_notifier.dart';
import 'data/auth_repository.dart';
import 'data/credentials_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final credentialsStorageProvider = Provider<CredentialsStorage>((ref) {
  return CredentialsStorage(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(credentialsStorageProvider));
});

final authStateProvider = AsyncNotifierProvider<AuthNotifier, bool>(
  AuthNotifier.new,
);
```

- [ ] **Step 3: Static-check**

Run:
```bash
flutter analyze lib/features/auth
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/application/auth_notifier.dart lib/features/auth/providers.dart
git commit -m "feat(auth): add auth notifier and riverpod providers"
```

---

## Task 8: Chat page (placeholder)

**Files:**
- Create: `lib/features/chat/presentation/chat_page.dart`

- [ ] **Step 1: Implement the placeholder**

Create `lib/features/chat/presentation/chat_page.dart`:
```dart
import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(child: Text('Chat (à venir)')),
    );
  }
}
```

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/features/chat
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/presentation/chat_page.dart
git commit -m "feat(chat): add empty chat page placeholder"
```

---

## Task 9: Settings page (logout)

**Files:**
- Create: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Implement the page**

Create `lib/features/settings/presentation/settings_page.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final isBusy = auth.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages')),
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
              : const Text('Se déconnecter'),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/features/settings
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/settings_page.dart
git commit -m "feat(settings): add settings page with logout button"
```

---

## Task 10: Home shell with bottom navigation

**Files:**
- Create: `lib/features/home/presentation/home_shell.dart`

- [ ] **Step 1: Implement the shell**

Create `lib/features/home/presentation/home_shell.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Réglages',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/features/home
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/presentation/home_shell.dart
git commit -m "feat(home): add home shell with bottom navigation"
```

---

## Task 11: Login page

**Files:**
- Create: `lib/features/auth/presentation/login_page.dart`

- [ ] **Step 1: Implement the form**

Create `lib/features/auth/presentation/login_page.dart`:
```dart
import 'package:flutter/material.dart';
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
    final auth = ref.watch(authStateProvider);
    final isBusy = auth.isLoading;

    ref.listen(authStateProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : ${next.error}')),
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
                  'Cookmate',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connectez-vous avec votre compte Cookidoo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Cookidoo',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Mot de passe',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
                            : const Text('Se connecter'),
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

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/features/auth/presentation/login_page.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/login_page.dart
git commit -m "feat(auth): add cookidoo credentials login page"
```

---

## Task 12: Router with auth guard

**Files:**
- Create: `lib/core/router.dart`

- [ ] **Step 1: Implement the router and refresh listener**

Create `lib/core/router.dart`:
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/providers.dart';
import '../features/chat/presentation/chat_page.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/settings/presentation/settings_page.dart';

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (auth.isLoading) return null;

      final isAuthenticated = auth.valueOrNull ?? false;
      final goingToLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !goingToLogin) return '/login';
      if (isAuthenticated && goingToLogin) return '/home/chat';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/chat',
                builder: (context, state) => const ChatPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
```

- [ ] **Step 2: Static-check**

Run:
```bash
flutter analyze lib/core/router.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/core/router.dart
git commit -m "feat(core): add go_router with auth redirect guard"
```

---

## Task 13: Wire app.dart and main.dart

**Files:**
- Create: `lib/app.dart`
- Modify: `lib/main.dart` (replace generated content)

- [ ] **Step 1: Create the root widget**

Create `lib/app.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

class CookmateApp extends ConsumerWidget {
  const CookmateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Cookmate',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 2: Replace main.dart**

Open `lib/main.dart` and replace its entire contents with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(const ProviderScope(child: CookmateApp()));
}
```

- [ ] **Step 3: Static-check the whole project**

Run:
```bash
flutter analyze
```

Expected: `No issues found!`.

- [ ] **Step 4: Commit**

```bash
git add lib/app.dart lib/main.dart
git commit -m "feat(app): wire ProviderScope, theme, and router into MaterialApp"
```

---

## Task 14: Set the app display name and bundle identifier

**Goal:** End up with display name `Cookmate` and bundle id `com.cookmate.app` on both platforms. `flutter create` produced the bundle id `com.cookmate.cookmate`; we override it here. The Kotlin source package (`com.cookmate.cookmate.MainActivity`) is left as-is — it does not need to match `applicationId`.

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/build.gradle.kts` (or `build.gradle` on older Flutter versions)
- Modify: `ios/Runner/Info.plist`
- Modify: `ios/Runner.xcodeproj/project.pbxproj`

- [ ] **Step 1: Update Android display name**

Open `android/app/src/main/AndroidManifest.xml`. Inside the `<application` opening tag, change `android:label="cookmate"` to:
```xml
android:label="Cookmate"
```

- [ ] **Step 2: Update Android applicationId and namespace**

Open `android/app/build.gradle.kts`. Inside the `android { ... defaultConfig { ... } }` block, change:
```kotlin
applicationId = "com.cookmate.cookmate"
```
to:
```kotlin
applicationId = "com.cookmate.app"
```

Then, still in `android { ... }`, change:
```kotlin
namespace = "com.cookmate.cookmate"
```
to:
```kotlin
namespace = "com.cookmate.app"
```

If the file is named `build.gradle` (Groovy DSL) instead of `build.gradle.kts`, apply the same renames using Groovy syntax (`applicationId "com.cookmate.app"`, `namespace "com.cookmate.app"`).

- [ ] **Step 3: Update iOS display name**

Open `ios/Runner/Info.plist`. Locate `CFBundleName` and set it to:
```xml
<key>CFBundleName</key>
<string>Cookmate</string>
```
If a `CFBundleDisplayName` key exists, set it to `Cookmate` as well; if it does not, add it next to `CFBundleName`:
```xml
<key>CFBundleDisplayName</key>
<string>Cookmate</string>
```
(Edit existing values in place — do not duplicate keys.)

- [ ] **Step 4: Update iOS bundle identifier**

Open `ios/Runner.xcodeproj/project.pbxproj`. There are three occurrences of `PRODUCT_BUNDLE_IDENTIFIER` (Debug, Release, Profile configurations) — replace **every** occurrence of:
```
PRODUCT_BUNDLE_IDENTIFIER = com.cookmate.cookmate;
```
with:
```
PRODUCT_BUNDLE_IDENTIFIER = com.cookmate.app;
```

Verify with:
```bash
grep -n PRODUCT_BUNDLE_IDENTIFIER ios/Runner.xcodeproj/project.pbxproj
```
Expected: every line shows `com.cookmate.app` (the `RunnerTests` target may have a `.RunnerTests` suffix — leave any such suffixed lines alone).

- [ ] **Step 5: Verify the project still builds**

Run:
```bash
flutter analyze
flutter build apk --debug
```

Expected: both succeed. (The APK build confirms the Android manifest and Gradle config are valid; we do not need to install it.)

- [ ] **Step 6: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml android/app/build.gradle.kts ios/Runner/Info.plist ios/Runner.xcodeproj/project.pbxproj
git commit -m "chore(app): set display name to Cookmate and bundle id to com.cookmate.app"
```

---

## Task 15: Update the README with prerequisites

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Rewrite the README**

Replace the entire contents of `README.md` with:
```markdown
# Cookmate

AI-powered mobile assistant for your Thermomix.

Cookmate is a Flutter mobile app (Android + iOS) that will become a fully autonomous
chat assistant for Thermomix recipes, backed by your Cookidoo account and an
on-device Gemma model. This repository currently contains the bootstrap shell
(login with Cookidoo credentials, empty Chat and Settings tabs).

## Development prerequisites

Install the following on your macOS machine:

- [Flutter SDK](https://docs.flutter.dev/get-started/install/macos) (stable channel)
  ```bash
  brew install --cask flutter
  ```
- [Android Studio](https://developer.android.com/studio) (provides Android SDK + emulator)
  ```bash
  brew install --cask android-studio
  ```
- [Xcode](https://apps.apple.com/app/xcode/id497799835) from the App Store, then:
  ```bash
  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  sudo gem install cocoapods
  ```

Validate the setup:

```bash
flutter doctor
```

All checks must be green before running the app.

## Run in development

```bash
git clone https://github.com/using-system/cookmate.git
cd cookmate
flutter pub get
flutter run
```

Pick your target device when prompted (`flutter devices` lists what is available).

## Install on a device (non-developer path)

Cookmate is not yet published on the App Store or Google Play. Until a release is
available, the only way to install the app on a physical phone is to build it from
source:

- **iPhone:** connect the device over USB, trust the computer, then run
  `flutter run --release -d <your-iphone>`. You need a free Apple ID signed into
  Xcode to sign the build for personal use.
- **Android:** enable Developer Options and USB debugging on the phone, connect it,
  then run `flutter run --release -d <your-android>` or
  `flutter build apk --release` and sideload the resulting APK from
  `build/app/outputs/flutter-apk/app-release.apk`.

Store-based installation instructions will be added here once the app is published.
```

- [ ] **Step 2: Verify the README renders**

Open `README.md` in an editor or preview and confirm there are no broken markdown
sections.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs(readme): document dev prerequisites and install paths"
```

---

## Task 16: End-to-end manual verification

**Files:** none

- [ ] **Step 1: Run on iOS Simulator**

Start the simulator (`open -a Simulator`) then:
```bash
flutter run -d iPhone
```

Verify in the running app:
1. App opens on the **Login** page (title "Cookmate", two fields, disabled "Se connecter" button).
2. Typing an email and a password enables the button.
3. Tapping "Se connecter" navigates to the **Chat** tab.
4. The bottom bar switches between **Chat** ("Chat (à venir)") and **Réglages** (logout button).
5. Tapping "Se déconnecter" returns to the Login page.
6. Stop the app (`q`), then re-run `flutter run -d iPhone`. The app should land directly on **Chat** because the credentials are still in the keychain. Logout once more so the next run starts fresh.

- [ ] **Step 2: Run on Android Emulator**

Start an Android emulator (`flutter emulators --launch <id>`) then:
```bash
flutter run -d emulator-5554
```

Repeat the same six checks as above.

- [ ] **Step 3: Final commit (only if any fix was required)**

If steps 1 or 2 surfaced issues that required code changes, commit them:
```bash
git add -A
git commit -m "fix(app): resolve issues found during manual verification"
```

If no fix was needed, skip this step.

- [ ] **Step 4: Push the branch**

```bash
git push -u origin feat/bootstrap-cookmate
```

---

## Done

The app is bootstrapped. Next milestones (out of scope for this plan, see the design doc):
- Real Cookidoo authentication and API client.
- On-device Gemma chat assistant in the Chat tab.
- Test suite (unit + widget + integration).
- CI pipeline.
