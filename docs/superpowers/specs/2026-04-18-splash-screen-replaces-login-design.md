# Splash screen replaces Cookidoo login — Design

## Context and motivation

The app currently gates access behind a Cookidoo email/password login screen that stores credentials locally via `flutter_secure_storage`. Interacting with `cookidoo.fr` this way is not authorised, so the login flow and its credential storage must be removed entirely.

In place of the login screen, the app will show a branded splash screen for at least 5 seconds, then navigate straight into the chat tab. The repository description and the README are updated to reflect that the app no longer relies on a Cookidoo account.

## Scope

### In scope

- Remove every artefact related to Cookidoo login/password (UI, application state, data layer, domain, tests, dependency, i18n keys).
- Remove the "Log out" control and its i18n keys from the Settings page.
- Add a new splash feature with a 5-second minimum display, animated, themed with the active theme.
- Rewire `go_router` so the splash is the initial route and navigates to `/home/chat` when the delay elapses.
- Add i18n keys for the splash across the four supported locales.
- Declare the app logo as a Flutter asset.
- Update `pubspec.yaml` project description, the README intro, and the GitHub repository description.

### Out of scope

- Native splash (e.g. `flutter_native_splash`). May be revisited later if a white flash appears on startup.
- Any other Cookidoo integration work.
- Splash on subsequent app resumes — the splash only shows on cold start.

## Target architecture

### Routing

`lib/core/router.dart` becomes a plain `Provider<GoRouter>` with no auth refresh listener and no redirect:

- `initialLocation: '/splash'`
- Routes: `/splash` (new), `StatefulShellRoute` containing `/home/chat` and `/home/settings` (unchanged).
- `ref.onDispose` only calls `router.dispose()`.

### New feature: splash

Files:

- `lib/features/splash/presentation/splash_page.dart`

The splash page is a `StatefulWidget` (no Riverpod dependency) that:

1. Starts an `AnimationController` (900 ms, `Curves.easeOutCubic`) on `initState`.
2. Starts a `Timer(Duration(seconds: 5))` on `initState`.
3. When the timer fires, calls `context.go('/home/chat')` if the widget is still mounted.
4. Disposes the timer and the controller on `dispose`.

Layout:

- Scaffold with `backgroundColor: Theme.of(context).colorScheme.surface`.
- Centered `Column` with `mainAxisSize: MainAxisSize.min`:
  - Logo `Image.asset('assets/icon/cookmate.png')` at ~160×160, fading in and scaling from 0.8 → 1.0 during the first 60 % of the animation.
  - `SizedBox(height: 24)`
  - Title `CookMate` in `displaySmall`, colour `onSurface`.
  - `SizedBox(height: 12)`
  - Description via `l10n.splashDescription` in `bodyLarge`, colour `onSurfaceVariant`, centered, max 2 lines.
  - Title and description share a single fade-in `Opacity` driven by the animation between 40 % and 100 %.

Constants:

- `_animationDuration = Duration(milliseconds: 900)` and `_minimumDisplayDuration = Duration(seconds: 5)` at the top of the file.

### Removals

Code:

- Delete `lib/features/auth/` (entire folder, including `application/`, `data/`, `domain/`, `presentation/`, `providers.dart`).
- Delete `test/features/auth/`.
- Remove the `flutter_secure_storage` dependency from `pubspec.yaml`.
- Remove all imports of `features/auth/...` from the router and Settings.

Settings page (`lib/features/settings/presentation/settings_page.dart`):

- Remove the `ConsumerWidget` dependency on `authStateProvider`, the `ref.listen`, the logout button and its `isBusy` state.
- Downgrade it to a plain `StatelessWidget`; the picker tiles are `ConsumerWidget`s themselves and wire their own providers internally. Body becomes a `ListView` with `ThemePickerTile`, divider, `LanguagePickerTile`.

### Internationalisation

All four ARB files (`lib/l10n/app_fr.arb`, `app_en.arb`, `app_es.arb`, `app_de.arb`) change in lockstep.

Keys removed (from every locale): `loginTitle`, `loginSubtitle`, `loginEmailLabel`, `loginPasswordLabel`, `loginSubmitButton`, `loginFailureSnackbar`, `settingsLogoutButton`, `settingsLogoutFailureSnackbar`.

Keys added (with `@` metadata in `app_en.arb` only):

- `splashTitle`: `CookMate` (identical in every locale — proper noun).
- `splashDescription`:
  - fr: `Créez vos recettes Thermomix avec l'assistant CookMate.`
  - en: `Create your Thermomix recipes with the CookMate assistant.`
  - es: `Crea tus recetas Thermomix con el asistente CookMate.`
  - de: `Erstelle deine Thermomix-Rezepte mit dem CookMate-Assistenten.`

`appTitle` stays `Cookmate` across locales — unchanged.

### Assets

`pubspec.yaml` gains an `assets:` list under `flutter:`:

```yaml
flutter:
  generate: true
  uses-material-design: true
  assets:
    - assets/icon/cookmate.png
```

`flutter_launcher_icons` keeps using the same path.

### Documentation

`pubspec.yaml` `description` becomes: `Create your Thermomix recipes with the CookMate assistant.`

`README.md` intro is rewritten:

> CookMate is a Flutter mobile app (Android + iOS) that helps you create Thermomix recipes with an AI assistant.

Any remaining reference to "Cookidoo account" is removed from the README.

The GitHub repository description is updated via `gh repo edit` to match the new `pubspec.yaml` description. This is a user-visible change on GitHub, so confirmation is required before running the command.

## Data flow

1. App starts → `main.dart` → `CookmateApp` → `MaterialApp.router` with `routerProvider`.
2. Router resolves `initialLocation` `/splash` → renders `SplashPage`.
3. `SplashPage.initState` starts animation and timer.
4. 5 s later, timer fires → `context.go('/home/chat')`.
5. Router pushes `HomeShell` with `ChatPage` as first branch.
6. User can navigate to Settings via the bottom nav; no login is ever required.

## Testing

Delete `test/features/auth/` in full.

Add `test/features/splash/splash_page_test.dart`:

- Pumps `SplashPage` inside a `MaterialApp` wired with the four supported locales and `AppLocalizations.localizationsDelegates`, and with a minimal `MaterialApp.router` or equivalent so `context.go('/home/chat')` is observable.
- Case 1: renders the logo image, the title `CookMate`, and the localised description (fr by default in the test).
- Case 2: before 5 s have elapsed, the route is still `/splash`.
- Case 3: after advancing the clock by 5 s and pumping until idle, the router is at `/home/chat`.

`test/app_test.dart` is unchanged.

## Acceptance criteria

- `flutter analyze` is clean.
- `flutter test` is green.
- Cold-starting the app shows logo + title + description with a fade-in/scale animation and stays visible for at least 5 s before showing the chat tab.
- The chat and settings tabs are reachable and functional; no login is ever shown.
- No reference to Cookidoo, login, password, credentials, or `flutter_secure_storage` remains in `lib/`, `test/`, `pubspec.yaml`, `pubspec.lock`, or `README.md`.
- All four ARB files expose the same key set, and the splash copy appears correctly in each locale.

## Risks and mitigations

- **White flash before the Flutter splash paints on cold start.** Mitigation: if observed on device, add `flutter_native_splash` in a follow-up — out of scope here.
- **Tests that depend on `pumpAndSettle` while the 5 s timer is pending.** Mitigation: use `tester.pump(Duration(seconds: 5))` then `pumpAndSettle`, never a bare `pumpAndSettle`.
- **Router rebuild loop after removing the refresh notifier.** Mitigation: the new `routerProvider` returns a single `GoRouter` instance, no `refreshListenable`, disposed via `ref.onDispose`.
