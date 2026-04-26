# Reset All Settings — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Reset all settings" action that wipes all local data and closes the app.

**Architecture:** A new list tile in the Settings Actions section triggers a confirmation dialog. On confirm, SharedPreferences are cleared, the downloaded model is uninstalled, the SQLite database is deleted, and the app closes via `SystemNavigator.pop()`.

**Tech Stack:** SharedPreferences, sqflite (deleteDatabase), flutter_gemma (uninstallModel), Flutter services (SystemNavigator)

---

### Task 1: Add localization strings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_es.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_it.arb`

Three new keys. Existing key `cancel` is reused.

- [ ] **Step 1: Add English strings**

In `lib/l10n/app_en.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "settingsResetAll": "Reset all settings",
  "@settingsResetAll": { "description": "Label for the reset all settings action in settings." },

  "settingsResetAllConfirmation": "Reset all settings? The app will close and all data will be deleted. This cannot be undone.",
  "@settingsResetAllConfirmation": { "description": "Confirmation prompt before resetting all settings." },

  "settingsResetAllButton": "Reset",
  "@settingsResetAllButton": { "description": "Button label to confirm reset all settings." }
```

- [ ] **Step 2: Add Spanish strings**

In `lib/l10n/app_es.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "settingsResetAll": "Restablecer todos los ajustes",
  "settingsResetAllConfirmation": "¿Restablecer todos los ajustes? La aplicación se cerrará y todos los datos serán eliminados. Esta acción no se puede deshacer.",
  "settingsResetAllButton": "Restablecer"
```

- [ ] **Step 3: Add French strings**

In `lib/l10n/app_fr.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "settingsResetAll": "Réinitialiser tous les réglages",
  "settingsResetAllConfirmation": "Réinitialiser tous les réglages ? L'application se fermera et toutes les données seront supprimées. Cette action est irréversible.",
  "settingsResetAllButton": "Réinitialiser"
```

- [ ] **Step 4: Add German strings**

In `lib/l10n/app_de.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "settingsResetAll": "Alle Einstellungen zurücksetzen",
  "settingsResetAllConfirmation": "Alle Einstellungen zurücksetzen? Die App wird geschlossen und alle Daten werden gelöscht. Dies kann nicht rückgängig gemacht werden.",
  "settingsResetAllButton": "Zurücksetzen"
```

- [ ] **Step 5: Add Italian strings**

In `lib/l10n/app_it.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "settingsResetAll": "Ripristina tutte le impostazioni",
  "settingsResetAllConfirmation": "Ripristinare tutte le impostazioni? L'app si chiuderà e tutti i dati verranno eliminati. Questa azione non può essere annullata.",
  "settingsResetAllButton": "Ripristina"
```

- [ ] **Step 6: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: completes without errors.

- [ ] **Step 7: Commit**

```
feat(l10n): add reset all settings strings
```

---

### Task 2: Add reset action to settings page

**Files:**
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Add imports**

At the top of `settings_page.dart`, add these imports:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
```

- [ ] **Step 2: Add the reset tile in the build method**

In the `build` method, after the existing "Delete all conversations" `ListTile` (line 89-101) and before `const Divider(height: 1)` at line 102, insert a new tile:

```dart
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.restore,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.settingsResetAll,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            onTap: () => _confirmResetAll(context, ref),
          ),
```

- [ ] **Step 3: Add the _confirmResetAll method**

Add a new method after `_confirmDeleteAll` (after line 134), before the closing `}` of the class:

```dart
  Future<void> _confirmResetAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsResetAll),
        content: Text(l10n.settingsResetAllConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.settingsResetAllButton,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // 1. Read installed model before clearing preferences.
    final prefs = await SharedPreferences.getInstance();
    final installedModelName = prefs.getString('chat_model_installed');

    // 2. Clear all shared preferences.
    await prefs.clear();

    // 3. Uninstall downloaded model if one exists.
    if (installedModelName != null) {
      for (final model in ChatModelPreference.values) {
        if (model.name == installedModelName) {
          try {
            await FlutterGemma.uninstallModel(model.fileName);
          } catch (_) {
            // Best-effort — model file may already be gone.
          }
          break;
        }
      }
    }

    // 4. Delete SQLite database.
    final dbPath = join(await getDatabasesPath(), 'cookmate_chat.db');
    await deleteDatabase(dbPath);

    // 5. Close the app.
    await SystemNavigator.pop();
  }
```

- [ ] **Step 4: Add the missing import for ChatModelPreference**

Add this import at the top of the file:

```dart
import '../../chat/domain/chat_model_preference.dart';
```

- [ ] **Step 5: Verify the build compiles**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 6: Commit**

```
feat(settings): add reset all settings action
```
