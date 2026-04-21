# Firebase Crashlytics Integration

## Summary

Add Firebase Crashlytics to CookMate with a user-facing toggle in a new "Observability" settings section. Crash reporting is opt-in (disabled by default) and can be toggled at runtime. The Observability section is designed to be extensible for future additions (analytics, performance monitoring, etc.).

## Context

- Firebase is already configured at the native level (google-services.json / GoogleService-Info.plist present in the Firebase project)
- The `firebase_crashlytics` Flutter plugin needs to be added along with `firebase_core`
- The settings page currently has 6 sections: Recipe, Skills, Cookidoo, AI, General, Actions
- The new Observability section goes between General and Actions

## Architecture

### New feature module

```
lib/features/observability/
  ├── data/
  │   └── observability_storage.dart        # SharedPreferences wrapper
  ├── domain/
  │   └── crashlytics_preference.dart       # Boolean preference type
  ├── presentation/
  │   ├── observability_section.dart         # Section widget for settings page
  │   └── crashlytics_toggle_tile.dart       # SwitchListTile for Crashlytics
  └── providers.dart                         # Riverpod AsyncNotifier + provider
```

### Dependencies (pubspec.yaml)

- `firebase_core` — Firebase initialization
- `firebase_crashlytics` — Crash reporting SDK

### Android build changes

- Add `com.google.firebase.crashlytics` Gradle plugin to `android/app/build.gradle`
- Add classpath dependency in `android/build.gradle` if not already present

### SharedPreferences key

- `observability_crashlytics_enabled` — `bool`, default `false`

### Data flow

1. App startup (`main.dart`):
   - Initialize `Firebase.initializeApp()`
   - Read crashlytics preference from SharedPreferences
   - Call `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value)`
   - Set `FlutterError.onError` to `FirebaseCrashlytics.instance.recordFlutterFatalError`
   - Wrap runApp zone with `FirebaseCrashlytics.instance.recordError` for async errors
2. Settings toggle:
   - User flips switch → notifier updates SharedPreferences + calls `setCrashlyticsCollectionEnabled(newValue)` immediately

### Provider pattern

Follows the existing Riverpod AsyncNotifier pattern:

- `CrashlyticsPreferenceNotifier extends AsyncNotifier<bool>` — reads/writes preference and syncs with Crashlytics SDK
- `crashlyticsPreferenceProvider` — exposes the notifier
- Storage class `ObservabilityStorage` wraps SharedPreferences access

### Settings page changes

In `settings_page.dart`, insert the Observability section between the General and Actions sections. The section contains a single toggle tile for now but is structured identically to other sections for easy extension.

### Internationalization (ARB keys)

Add to all 4 locale ARB files (`app_en.arb`, `app_fr.arb`, `app_de.arb`, `app_es.arb`):

| Key | EN | FR | DE | ES |
|-----|----|----|----|----|
| `settingsSectionObservability` | Observability | Observabilité | Beobachtbarkeit | Observabilidad |
| `settingsCrashlyticsTitle` | Crash reporting | Rapport de plantage | Absturzbericht | Informe de fallos |
| `settingsCrashlyticsDescription` | Send anonymous crash reports to help improve the app | Envoyer des rapports de plantage anonymes pour améliorer l'application | Anonyme Absturzberichte senden, um die App zu verbessern | Enviar informes de fallos anónimos para mejorar la aplicación |

### SPEC.md update

Add Firebase Crashlytics to the tech stack section.

## Testing

- Verify toggle default is off
- Verify toggling on/off persists across app restarts
- Verify `setCrashlyticsCollectionEnabled` is called with correct value on toggle and on startup
- Force a crash in debug mode to verify crash reports arrive in Firebase Console when enabled
