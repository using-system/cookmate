# Splash screen replaces Cookidoo login — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove every trace of the Cookidoo email/password login and replace it with a 5-second branded splash screen that opens straight into the chat tab.

**Architecture:** `/splash` becomes the initial route of `go_router`. A new `SplashPage` widget runs a fade-in/scale animation and navigates to `/home/chat` once a 5 s timer elapses. The `features/auth/` module, its tests, the `flutter_secure_storage` dependency, the login/logout i18n keys, and the logout button in Settings are all deleted.

**Tech Stack:** Flutter, `flutter_riverpod`, `go_router`, ARB-based i18n (`flutter gen-l10n`), `flutter_test`.

**Branch:** `feat/splash-screen` (already created; one commit for the spec is already on it).

**Working directory:** `/Users/usingsystem/Repos/github/cookmate`.

**Quality gates after every task:** `flutter analyze` clean **and** `flutter test` green.

**Commit convention:** Conventional Commits (invoke `ai-dev-extensions:git-commit` before each commit). Never commit on `main`.

---

## File map

**Create:**
- `lib/features/splash/presentation/splash_page.dart` — `SplashPage` widget, owns the animation and the 5 s timer.
- `test/features/splash/presentation/splash_page_test.dart` — widget tests (render + timing + navigation).

**Modify:**
- `lib/l10n/app_en.arb`, `app_fr.arb`, `app_es.arb`, `app_de.arb` — add `splashTitle`, `splashDescription`; remove `login*` and `settingsLogout*` keys.
- `pubspec.yaml` — declare `assets/icon/cookmate.png` in `flutter.assets`; drop `flutter_secure_storage` dependency; update `description`.
- `lib/core/router.dart` — initial route `/splash`, add splash route, drop auth import/redirect/refresh-listener.
- `lib/features/settings/presentation/settings_page.dart` — remove logout button and its auth wiring.
- `README.md` — rewrite intro, drop Cookidoo mentions.

**Delete:**
- `lib/features/auth/` (whole directory).
- `test/features/auth/` (whole directory).

---

## Task 1: Add splash i18n keys (additive)

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_de.arb`

- [ ] **Step 1.1: Add keys to `app_en.arb`**

Append these entries inside the top-level JSON object in `lib/l10n/app_en.arb` (just before the closing `}`), keeping valid JSON (add a comma to the current last entry):

```json
  "splashTitle": "CookMate",
  "@splashTitle": { "description": "Title displayed on the splash screen. Proper noun — keep identical in all locales." },

  "splashDescription": "Create your Thermomix recipes with the CookMate assistant.",
  "@splashDescription": { "description": "Short tagline displayed below the title on the splash screen." }
```

- [ ] **Step 1.2: Add keys to `app_fr.arb`**

Append to `lib/l10n/app_fr.arb`:

```json
  "splashTitle": "CookMate",
  "splashDescription": "Créez vos recettes Thermomix avec l'assistant CookMate."
```

(Add a comma on the previous last entry.)

- [ ] **Step 1.3: Add keys to `app_es.arb`**

Append to `lib/l10n/app_es.arb`:

```json
  "splashTitle": "CookMate",
  "splashDescription": "Crea tus recetas Thermomix con el asistente CookMate."
```

- [ ] **Step 1.4: Add keys to `app_de.arb`**

Append to `lib/l10n/app_de.arb`:

```json
  "splashTitle": "CookMate",
  "splashDescription": "Erstelle deine Thermomix-Rezepte mit dem CookMate-Assistenten."
```

- [ ] **Step 1.5: Regenerate and verify**

Run: `flutter gen-l10n`
Expected: exits 0 with no error. (`lib/l10n/app_localizations*.dart` is regenerated; these files are gitignored.)

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass (no behavioural change).

- [ ] **Step 1.6: Commit**

Invoke the `ai-dev-extensions:git-commit` skill, then:

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_es.arb lib/l10n/app_de.arb
git commit -m "$(cat <<'EOF'
feat(l10n): add splash title and description keys

Adds splashTitle and splashDescription across the four supported locales
ahead of the new splash screen that replaces the Cookidoo login.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Declare the logo as a Flutter asset

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 2.1: Declare asset**

In `pubspec.yaml`, inside the `flutter:` block (currently lines around `generate: true` / `uses-material-design: true`), add an `assets:` entry:

```yaml
flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/icon/cookmate.png
```

- [ ] **Step 2.2: Verify**

Run: `flutter pub get`
Expected: exits 0.

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2.3: Commit**

Invoke `ai-dev-extensions:git-commit`, then:

```bash
git add pubspec.yaml
git commit -m "$(cat <<'EOF'
chore(assets): declare cookmate logo as a flutter asset

Required so the upcoming splash screen can Image.asset the logo at
runtime. Same file is still consumed by flutter_launcher_icons.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Add the splash page (TDD)

**Files:**
- Create: `test/features/splash/presentation/splash_page_test.dart`
- Create: `lib/features/splash/presentation/splash_page.dart`

- [ ] **Step 3.1: Write the failing test**

Create `test/features/splash/presentation/splash_page_test.dart` with exactly:

```dart
import 'package:cookmate/features/splash/presentation/splash_page.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
      GoRoute(
        path: '/home/chat',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('chat-home'))),
      ),
    ],
  );
}

Widget _wrap(GoRouter router, {Locale locale = const Locale('en')}) {
  return MaterialApp.router(
    routerConfig: router,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

String _currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders logo, title, and description', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_wrap(router));
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('CookMate'), findsOneWidget);
    expect(
      find.text('Create your Thermomix recipes with the CookMate assistant.'),
      findsOneWidget,
    );
  });

  testWidgets('stays on splash before 5 seconds elapse', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_wrap(router));
    await tester.pump(const Duration(seconds: 4));

    expect(_currentPath(router), '/splash');
    expect(find.text('chat-home'), findsNothing);
  });

  testWidgets('navigates to /home/chat after 5 seconds', (tester) async {
    final router = _buildRouter();
    await tester.pumpWidget(_wrap(router));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(_currentPath(router), '/home/chat');
    expect(find.text('chat-home'), findsOneWidget);
  });
}
```

- [ ] **Step 3.2: Run test — must fail**

Run: `flutter test test/features/splash/presentation/splash_page_test.dart`
Expected: FAIL with a message like "Target of URI doesn't exist: 'package:cookmate/features/splash/presentation/splash_page.dart'".

- [ ] **Step 3.3: Implement the widget**

Create `lib/features/splash/presentation/splash_page.dart` with exactly:

```dart
import 'dart:async';

import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _animationDuration = Duration(milliseconds: 900);
const _minimumDisplayDuration = Duration(seconds: 5);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration)
      ..forward();
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    );
    _textOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );
    _timer = Timer(_minimumDisplayDuration, () {
      if (mounted) context.go('/home/chat');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Image.asset(
                        'assets/icon/cookmate.png',
                        width: 160,
                        height: 160,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedBuilder(
                  animation: _textOpacity,
                  builder: (_, __) => Opacity(
                    opacity: _textOpacity.value,
                    child: Column(
                      children: [
                        Text(
                          l10n.splashTitle,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.splashDescription,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
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

- [ ] **Step 3.4: Run tests — must pass**

Run: `flutter test test/features/splash/presentation/splash_page_test.dart`
Expected: 3 tests pass.

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 3.5: Commit**

Invoke `ai-dev-extensions:git-commit`, then:

```bash
git add lib/features/splash test/features/splash
git commit -m "$(cat <<'EOF'
feat(splash): add splash page with animated branding

Introduces SplashPage, shown for at least 5 s on cold start with a
fade-in + scale animation on the logo, followed by the title and the
localised tagline. Navigates to /home/chat when the timer elapses.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Wire the splash into the router, drop auth gating

**Files:**
- Modify: `lib/core/router.dart`

- [ ] **Step 4.1: Replace router implementation**

Overwrite `lib/core/router.dart` with exactly:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/presentation/chat_page.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/splash/presentation/splash_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
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

  ref.onDispose(router.dispose);
  return router;
});
```

- [ ] **Step 4.2: Verify — analyze is still green**

Run: `flutter analyze`
Expected: `No issues found!` (Settings still imports auth for the logout button — that's removed in Task 5.)

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 4.3: Commit**

Invoke `ai-dev-extensions:git-commit`, then:

```bash
git add lib/core/router.dart
git commit -m "$(cat <<'EOF'
feat(router): use splash as initial route and drop auth redirect

The Cookidoo login flow is being removed, so the router no longer
watches an auth provider. The new /splash route is the initial
destination and its widget handles navigation to /home/chat.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: Remove the logout button from Settings

**Files:**
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 5.1: Rewrite the settings page**

Overwrite `lib/features/settings/presentation/settings_page.dart` with exactly:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../l10n/presentation/language_picker_tile.dart';
import '../../theme/presentation/theme_picker_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: const [
          ThemePickerTile(),
          Divider(height: 1),
          LanguagePickerTile(),
          Divider(height: 1),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5.2: Verify**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass (the auth-based credentials storage test still runs because `lib/features/auth/` is still present; it gets deleted in Task 6).

- [ ] **Step 5.3: Commit**

Invoke `ai-dev-extensions:git-commit`, then:

```bash
git add lib/features/settings/presentation/settings_page.dart
git commit -m "$(cat <<'EOF'
refactor(settings): remove logout action

There is no session to end now that the Cookidoo login is gone, so the
Settings screen drops the logout button and its auth-state wiring and
becomes a pure stateless widget.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: Delete the auth feature and its tests

**Files:**
- Delete: `lib/features/auth/` (directory)
- Delete: `test/features/auth/` (directory)

- [ ] **Step 6.1: Remove the directories**

Run: `git rm -r lib/features/auth test/features/auth`
Expected: files removed and staged for deletion.

- [ ] **Step 6.2: Verify**

Run: `flutter analyze`
Expected: `No issues found!` (Nothing imports `features/auth/` anymore after Tasks 4 and 5.)

Run: `flutter test`
Expected: all remaining tests pass; the auth tests are gone.

- [ ] **Step 6.3: Commit**

Invoke `ai-dev-extensions:git-commit`, then:

```bash
git commit -m "$(cat <<'EOF'
chore(auth): remove cookidoo credentials module

The login flow, credentials storage, auth repository, auth notifier and
their tests are all obsolete now that the app ships without a Cookidoo
sign-in.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: Remove login/logout i18n keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_de.arb`

- [ ] **Step 7.1: Remove keys from every ARB**

From each of the four ARB files, delete these keys (and, in `app_en.arb`, their `@`-metadata siblings): `loginTitle`, `loginSubtitle`, `loginEmailLabel`, `loginPasswordLabel`, `loginSubmitButton`, `loginFailureSnackbar`, `settingsLogoutButton`, `settingsLogoutFailureSnackbar`.

Leave every other key untouched. Keep the files valid JSON (trailing commas adjusted appropriately).

- [ ] **Step 7.2: Regenerate and verify**

Run: `flutter gen-l10n`
Expected: exits 0.

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 7.3: Commit**

Invoke `ai-dev-extensions:git-commit`, then:

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_es.arb lib/l10n/app_de.arb
git commit -m "$(cat <<'EOF'
chore(l10n): remove cookidoo login and logout strings

All login* and settingsLogout* keys are unused now that the feature is
gone. The four locales stay in lockstep.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: Drop the `flutter_secure_storage` dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 8.1: Remove the dependency line**

In `pubspec.yaml`, delete the line:

```yaml
  flutter_secure_storage: ^9.2.2
```

from the `dependencies:` block. Leave surrounding dependencies intact.

- [ ] **Step 8.2: Refresh the lockfile**

Run: `flutter pub get`
Expected: exits 0 and removes `flutter_secure_storage` entries from `pubspec.lock`.

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 8.3: Commit**

Invoke `ai-dev-extensions:git-commit`, then:

```bash
git add pubspec.yaml pubspec.lock
git commit -m "$(cat <<'EOF'
chore(deps): drop flutter_secure_storage

The only consumer was the removed Cookidoo credentials storage.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Update README and pubspec description

**Files:**
- Modify: `pubspec.yaml`
- Modify: `README.md`

- [ ] **Step 9.1: Update `pubspec.yaml` description**

Replace the `description:` line near the top of `pubspec.yaml` with:

```yaml
description: "Create your Thermomix recipes with the CookMate assistant."
```

- [ ] **Step 9.2: Update `README.md` intro**

In `README.md`, replace lines 1–7 (from `# Cookmate` through the current intro paragraph, up to but not including `## Development prerequisites`) with:

```markdown
# CookMate

Create your Thermomix recipes with the CookMate assistant.

CookMate is a Flutter mobile app (Android + iOS) — an AI chat assistant
that helps you discover and craft recipes for your Thermomix, powered by
an on-device Gemma model.

```

Then scan the rest of `README.md` and remove any other mention of the Cookidoo account (e.g. if any remains after the intro change).

- [ ] **Step 9.3: Verify**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 9.4: Commit**

Invoke `ai-dev-extensions:git-commit`, then:

```bash
git add pubspec.yaml README.md
git commit -m "$(cat <<'EOF'
docs: update README and pubspec description for new scope

Reflects that CookMate no longer relies on a Cookidoo account and
centres the pitch on the on-device Thermomix assistant.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: Update the GitHub repository description

**Files:** none on disk — this is a remote GitHub setting.

- [ ] **Step 10.1: Confirm with the user before running**

Ask the user to confirm the command below (it is a user-visible public change). If they decline, stop here.

- [ ] **Step 10.2: Update the description**

Run:

```bash
gh repo edit using-system/cookmate --description "Create your Thermomix recipes with the CookMate assistant."
```

Expected: `gh` prints the updated repo description.

- [ ] **Step 10.3: Verify**

Run: `gh repo view using-system/cookmate --json description -q .description`
Expected output: `Create your Thermomix recipes with the CookMate assistant.`

---

## Final verification (end of plan)

- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → all tests pass
- [ ] `git log --oneline main..HEAD` shows one commit per task (roughly 9 new commits after the spec commit)
- [ ] Cold run on a device/emulator (`flutter run`) shows splash for ≥5 s, then lands on the chat tab; settings tab shows theme + language only; no login screen exists
- [ ] `grep -r -i "cookidoo\|flutter_secure_storage\|login" lib test pubspec.yaml pubspec.lock README.md` returns **no matches** (other than the repository's package-lock hashes unrelated to the removed package)

---

## Spec coverage self-review

Each requirement from `docs/superpowers/specs/2026-04-18-splash-screen-replaces-login-design.md` is addressed by a task:

- Remove `features/auth/` + tests → Task 6
- Remove login/logout i18n keys → Task 7
- Remove `flutter_secure_storage` → Task 8
- Remove logout button in Settings → Task 5
- Add splash widget with animation + 5 s timer + theme surface background → Task 3
- Splash as router `initialLocation`, drop auth redirect → Task 4
- New `splashTitle`/`splashDescription` across four locales → Task 1
- Declare logo as Flutter asset → Task 2
- Update `pubspec.yaml` description and README → Task 9
- Update GitHub repo description → Task 10
- Tests: delete auth tests → Task 6, add splash tests → Task 3
- Acceptance: analyze+test green, no Cookidoo references → Final verification

No placeholder steps remain. Types and paths are consistent across tasks (`SplashPage`, `/splash`, `/home/chat`, `splashTitle`, `splashDescription`, `assets/icon/cookmate.png`).
