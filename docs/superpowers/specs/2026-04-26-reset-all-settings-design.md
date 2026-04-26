# Reset All Settings

## Problem

Users have no way to fully reset the app to its initial state. The only
destructive action available is "Delete all conversations", which leaves
preferences, downloaded models, and credentials intact.

## Solution

Add a "Reset all settings" action in the Settings Actions section that wipes
all local data and closes the app.

## UI

New list tile in Settings > Actions, below "Delete all conversations":

- Icon: `Icons.restore`, red color
- Label: "Reset all settings" (localized)
- Tap shows a confirmation dialog:
  - Body: "Reset all settings? The app will close and all data will be deleted.
    This cannot be undone." (localized)
  - Actions: "Cancel" (existing key) / "Reset" (localized, red/destructive)

## Logic

Executed sequentially after user confirms:

1. **Clear SharedPreferences** — `SharedPreferences.getInstance()` then
   `prefs.clear()`. Removes all key-value settings (theme, locale, model
   preference, backend, reasoning, expert config, skills, Cookidoo credentials,
   observability toggles).
2. **Uninstall downloaded model** — Read installed model from
   `chatModelPreferenceStorageProvider`. If a model is installed, call
   `FlutterGemma.uninstallModel(fileName)`.
3. **Delete SQLite database** — Call `deleteDatabase(path)` using the same
   database path from `ChatDatabase` (`cookmate_chat.db`).
4. **Close the app** — `SystemNavigator.pop()`.

All logic lives directly in `settings_page.dart` — no new service needed.

## Localization

New keys in all 5 locale files (en, es, fr, de, it):

| Key | EN value |
|-----|----------|
| `settingsResetAll` | Reset all settings |
| `settingsResetAllConfirmation` | Reset all settings? The app will close and all data will be deleted. This cannot be undone. |
| `settingsResetAllButton` | Reset |

Existing key reused: `cancel`.

## What is NOT in scope

- No selective reset (everything is wiped)
- No redirect to splash screen (app closes)
- No dedicated service or provider
