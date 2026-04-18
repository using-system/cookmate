# On-Device Chat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an on-device LLM chat feature powered by Gemma 4 via `flutter_gemma`, with persistent conversation history in SQLite.

**Architecture:** Feature-based structure under `lib/features/chat/` following existing patterns (domain/data/presentation layers). Riverpod `AsyncNotifier` for state, `sqflite` for persistence, `flutter_gemma` for inference. New sub-route `/home/chat/:conversationId` nested under the existing shell.

**Tech Stack:** Flutter, flutter_gemma ^0.13.5, sqflite ^2.3.0, path ^1.9.0, uuid ^4.0.0, flutter_riverpod ^2.5.1, go_router ^14.2.0

---

## File Structure

### New files

| File | Responsibility |
|------|---------------|
| `lib/features/chat/domain/conversation.dart` | Conversation data class |
| `lib/features/chat/domain/chat_message.dart` | ChatMessage data class |
| `lib/features/chat/domain/chat_model_preference.dart` | Enum for model selection (E2B/E4B) |
| `lib/features/chat/data/chat_database.dart` | SQLite helper (open DB, create tables, CRUD) |
| `lib/features/chat/data/chat_repository.dart` | Repository over ChatDatabase |
| `lib/features/chat/data/chat_model_preference_storage.dart` | SharedPreferences for model preference |
| `lib/features/chat/providers.dart` | All Riverpod providers for chat feature |
| `lib/features/chat/presentation/chat_page.dart` | Conversation list (replaces placeholder) |
| `lib/features/chat/presentation/conversation_page.dart` | Single conversation view |
| `lib/features/chat/presentation/model_download_page.dart` | Model download progress screen |
| `lib/features/chat/presentation/widgets/message_bubble.dart` | Message bubble widget |
| `lib/features/chat/presentation/widgets/chat_input_bar.dart` | Text input + send button |
| `lib/features/chat/presentation/model_picker_tile.dart` | Settings tile for model selection |
| `test/features/chat/domain/conversation_test.dart` | Conversation model tests |
| `test/features/chat/domain/chat_message_test.dart` | ChatMessage model tests |
| `test/features/chat/domain/chat_model_preference_test.dart` | Model preference enum tests |
| `test/features/chat/data/chat_database_test.dart` | Database CRUD tests |
| `test/features/chat/data/chat_repository_test.dart` | Repository tests |
| `test/features/chat/data/chat_model_preference_storage_test.dart` | Model storage tests |
| `test/features/chat/providers_test.dart` | Provider tests |

### Modified files

| File | Change |
|------|--------|
| `pubspec.yaml` | Add flutter_gemma, sqflite, path, uuid dependencies |
| `lib/l10n/app_en.arb` | Add new keys, remove chatTitle/chatPlaceholder |
| `lib/l10n/app_fr.arb` | Add new keys, remove chatTitle/chatPlaceholder |
| `lib/l10n/app_de.arb` | Add new keys, remove chatTitle/chatPlaceholder |
| `lib/l10n/app_es.arb` | Add new keys, remove chatTitle/chatPlaceholder |
| `lib/core/router.dart` | Add `/home/chat/:conversationId` sub-route, import ConversationPage |
| `lib/features/settings/presentation/settings_page.dart` | Add ModelPickerTile |
| `lib/features/home/presentation/home_shell.dart` | No changes needed |

---

## Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml:30-38`

- [ ] **Step 1: Add new dependencies to pubspec.yaml**

Add these lines after the existing `shared_preferences` dependency:

```yaml
  flutter_gemma: ^0.13.5
  sqflite: ^2.3.0
  path: ^1.9.0
  uuid: ^4.0.0
```

The full dependencies section becomes:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_riverpod: ^2.5.1
  go_router: ^14.2.0
  shared_preferences: ^2.3.0
  flutter_gemma: ^0.13.5
  sqflite: ^2.3.0
  path: ^1.9.0
  uuid: ^4.0.0
```

- [ ] **Step 2: Run pub get**

Run: `flutter pub get`
Expected: All packages resolve successfully, no errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build(chat): add flutter_gemma, sqflite, path, and uuid dependencies"
```

---

## Task 2: Add i18n keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_es.arb`

- [ ] **Step 1: Update app_en.arb**

Replace the full file with (removes `chatTitle`/`chatPlaceholder`, adds new keys):

```json
{
  "@@locale": "en",

  "appTitle": "Cookmate",
  "@appTitle": { "description": "Application display name. Same in all locales." },

  "chatConversationsTitle": "Conversations",
  "@chatConversationsTitle": { "description": "AppBar title on the conversations list screen." },

  "chatNewConversation": "New conversation",
  "@chatNewConversation": { "description": "Default title for a newly created conversation." },

  "chatDeleteConversation": "Delete conversation",
  "@chatDeleteConversation": { "description": "Label for the delete conversation action." },

  "chatDeleteConfirmation": "Delete this conversation?",
  "@chatDeleteConfirmation": { "description": "Confirmation prompt before deleting a conversation." },

  "chatInputHint": "Type a message\u2026",
  "@chatInputHint": { "description": "Hint text in the message input field." },

  "chatEmptyState": "No conversations yet. Tap + to start!",
  "@chatEmptyState": { "description": "Shown when the conversation list is empty." },

  "chatModelDownloadTitle": "Downloading AI model\u2026",
  "@chatModelDownloadTitle": { "description": "Title shown during model download." },

  "chatModelDownloadProgress": "{progress}% complete",
  "@chatModelDownloadProgress": {
    "description": "Download progress indicator.",
    "placeholders": { "progress": { "type": "int", "example": "42" } }
  },

  "chatModelDownloadError": "Download failed. Check your connection and try again.",
  "@chatModelDownloadError": { "description": "Error shown when model download fails." },

  "chatModelDownloadRetry": "Retry",
  "@chatModelDownloadRetry": { "description": "Retry button label on download error." },

  "settingsTitle": "Settings",
  "@settingsTitle": { "description": "AppBar title on the settings screen." },

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

  "settingsModelTitle": "AI Model",
  "@settingsModelTitle": { "description": "Title of the model selection setting tile." },

  "settingsModelDialogTitle": "Choose AI model",
  "@settingsModelDialogTitle": { "description": "Title of the model picker dialog." },

  "settingsModelOptionE2B": "Gemma 4 E2B (lighter, faster)",
  "@settingsModelOptionE2B": { "description": "Label for the Gemma 4 E2B model option." },

  "settingsModelOptionE4B": "Gemma 4 E4B (smarter, heavier)",
  "@settingsModelOptionE4B": { "description": "Label for the Gemma 4 E4B model option." },

  "settingsModelChangeFailureSnackbar": "Couldn't change model. Please try again.",
  "@settingsModelChangeFailureSnackbar": { "description": "Shown when persisting the model preference fails." },

  "cancel": "Cancel",
  "@cancel": { "description": "Generic cancel button label." },

  "delete": "Delete",
  "@delete": { "description": "Generic delete button label." },

  "homeTabChat": "Chat",
  "@homeTabChat": { "description": "Bottom navigation label for the chat tab." },

  "homeTabSettings": "Settings",
  "@homeTabSettings": { "description": "Bottom navigation label for the settings tab." },

  "splashTitle": "CookMate",
  "@splashTitle": { "description": "Title displayed on the splash screen. Proper noun — keep identical in all locales." },

  "splashDescription": "Create your Thermomix recipes with the CookMate assistant.",
  "@splashDescription": { "description": "Short tagline displayed below the title on the splash screen." }
}
```

- [ ] **Step 2: Update app_fr.arb**

Replace the full file:

```json
{
  "@@locale": "fr",
  "appTitle": "Cookmate",
  "chatConversationsTitle": "Conversations",
  "chatNewConversation": "Nouvelle conversation",
  "chatDeleteConversation": "Supprimer la conversation",
  "chatDeleteConfirmation": "Supprimer cette conversation ?",
  "chatInputHint": "Écrivez un message\u2026",
  "chatEmptyState": "Aucune conversation. Appuyez sur + pour commencer !",
  "chatModelDownloadTitle": "Téléchargement du modèle IA\u2026",
  "chatModelDownloadProgress": "{progress} % terminé",
  "chatModelDownloadError": "Échec du téléchargement. Vérifiez votre connexion et réessayez.",
  "chatModelDownloadRetry": "Réessayer",
  "settingsTitle": "Réglages",
  "settingsLanguageTitle": "Langue",
  "settingsLanguageFollowSystem": "Suivre le système ({language})",
  "settingsLanguageDialogTitle": "Choisir la langue",
  "settingsLanguageOptionSystem": "Suivre le système",
  "settingsLanguageChangeFailureSnackbar": "Impossible de changer la langue. Réessayez.",
  "settingsThemeTitle": "Thème",
  "settingsThemeDialogTitle": "Choisir le thème",
  "settingsThemeOptionDark": "Sombre",
  "settingsThemeOptionStandard": "Standard",
  "settingsThemeOptionPink": "Rose",
  "settingsThemeOptionMatrix": "Matrix",
  "settingsThemeChangeFailureSnackbar": "Impossible de changer de thème. Réessayez.",
  "settingsModelTitle": "Modèle IA",
  "settingsModelDialogTitle": "Choisir le modèle IA",
  "settingsModelOptionE2B": "Gemma 4 E2B (léger, rapide)",
  "settingsModelOptionE4B": "Gemma 4 E4B (plus précis, plus lourd)",
  "settingsModelChangeFailureSnackbar": "Impossible de changer de modèle. Réessayez.",
  "cancel": "Annuler",
  "delete": "Supprimer",
  "homeTabChat": "Chat",
  "homeTabSettings": "Réglages",
  "splashTitle": "CookMate",
  "splashDescription": "Créez vos recettes Thermomix avec l'assistant CookMate."
}
```

- [ ] **Step 3: Update app_de.arb**

Replace the full file:

```json
{
  "@@locale": "de",
  "appTitle": "Cookmate",
  "chatConversationsTitle": "Unterhaltungen",
  "chatNewConversation": "Neue Unterhaltung",
  "chatDeleteConversation": "Unterhaltung löschen",
  "chatDeleteConfirmation": "Diese Unterhaltung löschen?",
  "chatInputHint": "Nachricht eingeben\u2026",
  "chatEmptyState": "Noch keine Unterhaltungen. Tippe auf +, um zu starten!",
  "chatModelDownloadTitle": "KI-Modell wird heruntergeladen\u2026",
  "chatModelDownloadProgress": "{progress} % abgeschlossen",
  "chatModelDownloadError": "Download fehlgeschlagen. Überprüfe die Verbindung und versuche es erneut.",
  "chatModelDownloadRetry": "Erneut versuchen",
  "settingsTitle": "Einstellungen",
  "settingsLanguageTitle": "Sprache",
  "settingsLanguageFollowSystem": "System folgen ({language})",
  "settingsLanguageDialogTitle": "Sprache auswählen",
  "settingsLanguageOptionSystem": "System folgen",
  "settingsLanguageChangeFailureSnackbar": "Sprache konnte nicht geändert werden. Bitte versuche es erneut.",
  "settingsThemeTitle": "Design",
  "settingsThemeDialogTitle": "Design auswählen",
  "settingsThemeOptionDark": "Dunkel",
  "settingsThemeOptionStandard": "Standard",
  "settingsThemeOptionPink": "Pink",
  "settingsThemeOptionMatrix": "Matrix",
  "settingsThemeChangeFailureSnackbar": "Design konnte nicht geändert werden. Bitte versuche es erneut.",
  "settingsModelTitle": "KI-Modell",
  "settingsModelDialogTitle": "KI-Modell auswählen",
  "settingsModelOptionE2B": "Gemma 4 E2B (leichter, schneller)",
  "settingsModelOptionE4B": "Gemma 4 E4B (intelligenter, schwerer)",
  "settingsModelChangeFailureSnackbar": "Modell konnte nicht geändert werden. Bitte versuche es erneut.",
  "cancel": "Abbrechen",
  "delete": "Löschen",
  "homeTabChat": "Chat",
  "homeTabSettings": "Einstellungen",
  "splashTitle": "CookMate",
  "splashDescription": "Erstelle deine Thermomix-Rezepte mit dem CookMate-Assistenten."
}
```

- [ ] **Step 4: Update app_es.arb**

Replace the full file:

```json
{
  "@@locale": "es",
  "appTitle": "Cookmate",
  "chatConversationsTitle": "Conversaciones",
  "chatNewConversation": "Nueva conversación",
  "chatDeleteConversation": "Eliminar conversación",
  "chatDeleteConfirmation": "¿Eliminar esta conversación?",
  "chatInputHint": "Escribe un mensaje\u2026",
  "chatEmptyState": "Sin conversaciones aún. ¡Pulsa + para empezar!",
  "chatModelDownloadTitle": "Descargando modelo de IA\u2026",
  "chatModelDownloadProgress": "{progress}% completado",
  "chatModelDownloadError": "Error de descarga. Comprueba tu conexión e inténtalo de nuevo.",
  "chatModelDownloadRetry": "Reintentar",
  "settingsTitle": "Ajustes",
  "settingsLanguageTitle": "Idioma",
  "settingsLanguageFollowSystem": "Seguir el sistema ({language})",
  "settingsLanguageDialogTitle": "Elegir idioma",
  "settingsLanguageOptionSystem": "Seguir el sistema",
  "settingsLanguageChangeFailureSnackbar": "No se pudo cambiar el idioma. Inténtalo de nuevo.",
  "settingsThemeTitle": "Tema",
  "settingsThemeDialogTitle": "Elegir tema",
  "settingsThemeOptionDark": "Oscuro",
  "settingsThemeOptionStandard": "Estándar",
  "settingsThemeOptionPink": "Rosa",
  "settingsThemeOptionMatrix": "Matrix",
  "settingsThemeChangeFailureSnackbar": "No se pudo cambiar el tema. Inténtalo de nuevo.",
  "settingsModelTitle": "Modelo IA",
  "settingsModelDialogTitle": "Elegir modelo IA",
  "settingsModelOptionE2B": "Gemma 4 E2B (más ligero, más rápido)",
  "settingsModelOptionE4B": "Gemma 4 E4B (más inteligente, más pesado)",
  "settingsModelChangeFailureSnackbar": "No se pudo cambiar el modelo. Inténtalo de nuevo.",
  "cancel": "Cancelar",
  "delete": "Eliminar",
  "homeTabChat": "Chat",
  "homeTabSettings": "Ajustes",
  "splashTitle": "CookMate",
  "splashDescription": "Crea tus recetas Thermomix con el asistente CookMate."
}
```

- [ ] **Step 5: Run flutter gen-l10n to verify**

Run: `flutter gen-l10n`
Expected: No errors, all keys match across locales.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_de.arb lib/l10n/app_es.arb
git commit -m "feat(l10n): add chat and model picker i18n keys for all locales"
```

---

## Task 3: ChatModelPreference domain + storage (TDD)

**Files:**
- Create: `lib/features/chat/domain/chat_model_preference.dart`
- Create: `lib/features/chat/data/chat_model_preference_storage.dart`
- Create: `test/features/chat/domain/chat_model_preference_test.dart`
- Create: `test/features/chat/data/chat_model_preference_storage_test.dart`

- [ ] **Step 1: Write the failing test for ChatModelPreference**

Create `test/features/chat/domain/chat_model_preference_test.dart`:

```dart
import 'package:cookmate/features/chat/domain/chat_model_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatModelPreference.defaultModel', () {
    test('is gemma4E2B', () {
      expect(ChatModelPreference.defaultModel, ChatModelPreference.gemma4E2B);
    });

    test('is the first value declared on the enum', () {
      expect(ChatModelPreference.values.first, ChatModelPreference.defaultModel);
    });
  });

  group('ChatModelPreference.toStorageValue', () {
    test('serializes every variant to its enum name', () {
      for (final model in ChatModelPreference.values) {
        expect(model.toStorageValue(), model.name);
      }
    });
  });

  group('ChatModelPreference.fromStorageValue', () {
    test('parses every known enum name back to its value', () {
      for (final model in ChatModelPreference.values) {
        expect(ChatModelPreference.fromStorageValue(model.name), model);
      }
    });

    test('returns defaultModel when raw is null', () {
      expect(ChatModelPreference.fromStorageValue(null), ChatModelPreference.defaultModel);
    });

    test('returns defaultModel when raw is empty', () {
      expect(ChatModelPreference.fromStorageValue(''), ChatModelPreference.defaultModel);
    });

    test('returns defaultModel when raw is unknown', () {
      expect(ChatModelPreference.fromStorageValue('gemma99'), ChatModelPreference.defaultModel);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/chat/domain/chat_model_preference_test.dart`
Expected: Compilation error — `ChatModelPreference` does not exist.

- [ ] **Step 3: Implement ChatModelPreference**

Create `lib/features/chat/domain/chat_model_preference.dart`:

```dart
enum ChatModelPreference {
  gemma4E2B,
  gemma4E4B;

  static const ChatModelPreference defaultModel = ChatModelPreference.gemma4E2B;

  String toStorageValue() => name;

  static ChatModelPreference fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return defaultModel;
    }
    for (final model in ChatModelPreference.values) {
      if (model.name == raw) {
        return model;
      }
    }
    return defaultModel;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/chat/domain/chat_model_preference_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Write the failing test for ChatModelPreferenceStorage**

Create `test/features/chat/data/chat_model_preference_storage_test.dart`:

```dart
import 'package:cookmate/features/chat/data/chat_model_preference_storage.dart';
import 'package:cookmate/features/chat/domain/chat_model_preference.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatModelPreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = ChatModelPreferenceStorage(prefs);
  });

  test('read returns gemma4E2B when nothing is stored', () {
    expect(storage.read(), ChatModelPreference.gemma4E2B);
  });

  test('read returns the stored model for every known value', () async {
    for (final model in ChatModelPreference.values) {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_model_preference': model.name,
      });
      final prefs = await SharedPreferences.getInstance();
      final s = ChatModelPreferenceStorage(prefs);

      expect(s.read(), model);
    }
  });

  test('read returns gemma4E2B when stored value is unknown', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chat_model_preference': 'gemma99',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = ChatModelPreferenceStorage(prefs);

    expect(s.read(), ChatModelPreference.gemma4E2B);
  });

  test('write then read returns the written model', () async {
    await storage.write(ChatModelPreference.gemma4E4B);

    expect(storage.read(), ChatModelPreference.gemma4E4B);
  });

  test('write overwrites a previous value', () async {
    await storage.write(ChatModelPreference.gemma4E4B);
    await storage.write(ChatModelPreference.gemma4E2B);

    expect(storage.read(), ChatModelPreference.gemma4E2B);
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/chat/data/chat_model_preference_storage_test.dart`
Expected: Compilation error — `ChatModelPreferenceStorage` does not exist.

- [ ] **Step 7: Implement ChatModelPreferenceStorage**

Create `lib/features/chat/data/chat_model_preference_storage.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/chat_model_preference.dart';

class ChatModelPreferenceStorage {
  ChatModelPreferenceStorage(this._prefs);

  static const _key = 'chat_model_preference';

  final SharedPreferences _prefs;

  ChatModelPreference read() {
    try {
      return ChatModelPreference.fromStorageValue(_prefs.getString(_key));
    } catch (error, stack) {
      debugPrint('Failed to read chat model preference: $error\n$stack');
      return ChatModelPreference.defaultModel;
    }
  }

  Future<void> write(ChatModelPreference model) async {
    final didWrite = await _prefs.setString(_key, model.toStorageValue());
    if (!didWrite) {
      throw Exception('Failed to persist chat model preference.');
    }
  }
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/features/chat/data/chat_model_preference_storage_test.dart`
Expected: All tests PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/features/chat/domain/chat_model_preference.dart \
  lib/features/chat/data/chat_model_preference_storage.dart \
  test/features/chat/domain/chat_model_preference_test.dart \
  test/features/chat/data/chat_model_preference_storage_test.dart
git commit -m "feat(chat): add ChatModelPreference enum and storage"
```

---

## Task 4: Conversation and ChatMessage domain models (TDD)

**Files:**
- Create: `lib/features/chat/domain/conversation.dart`
- Create: `lib/features/chat/domain/chat_message.dart`
- Create: `test/features/chat/domain/conversation_test.dart`
- Create: `test/features/chat/domain/chat_message_test.dart`

- [ ] **Step 1: Write the failing test for Conversation**

Create `test/features/chat/domain/conversation_test.dart`:

```dart
import 'package:cookmate/features/chat/domain/conversation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 4, 18, 12, 0, 0);

  group('Conversation', () {
    test('stores all fields', () {
      final conv = Conversation(
        id: 'abc-123',
        title: 'My recipe',
        createdAt: now,
        updatedAt: now,
      );

      expect(conv.id, 'abc-123');
      expect(conv.title, 'My recipe');
      expect(conv.createdAt, now);
      expect(conv.updatedAt, now);
    });

    test('toMap serializes to SQLite-compatible map', () {
      final conv = Conversation(
        id: 'abc-123',
        title: 'My recipe',
        createdAt: now,
        updatedAt: now,
      );

      final map = conv.toMap();
      expect(map['id'], 'abc-123');
      expect(map['title'], 'My recipe');
      expect(map['created_at'], now.millisecondsSinceEpoch);
      expect(map['updated_at'], now.millisecondsSinceEpoch);
    });

    test('fromMap deserializes from SQLite row', () {
      final map = {
        'id': 'abc-123',
        'title': 'My recipe',
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final conv = Conversation.fromMap(map);
      expect(conv.id, 'abc-123');
      expect(conv.title, 'My recipe');
      expect(conv.createdAt, now);
      expect(conv.updatedAt, now);
    });

    test('copyWith creates a modified copy', () {
      final conv = Conversation(
        id: 'abc-123',
        title: 'Old title',
        createdAt: now,
        updatedAt: now,
      );

      final updated = conv.copyWith(title: 'New title');
      expect(updated.title, 'New title');
      expect(updated.id, conv.id);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/chat/domain/conversation_test.dart`
Expected: Compilation error — `Conversation` does not exist.

- [ ] **Step 3: Implement Conversation**

Create `lib/features/chat/domain/conversation.dart`:

```dart
class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory Conversation.fromMap(Map<String, Object?> map) => Conversation(
        id: map['id'] as String,
        title: map['title'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      );

  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
  }) =>
      Conversation(
        id: id,
        title: title ?? this.title,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/chat/domain/conversation_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Write the failing test for ChatMessage**

Create `test/features/chat/domain/chat_message_test.dart`:

```dart
import 'package:cookmate/features/chat/domain/chat_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 4, 18, 12, 0, 0);

  group('ChatMessage', () {
    test('stores all fields', () {
      final msg = ChatMessage(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: 'user',
        content: 'Hello',
        createdAt: now,
      );

      expect(msg.id, 'msg-1');
      expect(msg.conversationId, 'conv-1');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.createdAt, now);
    });

    test('toMap serializes to SQLite-compatible map', () {
      final msg = ChatMessage(
        id: 'msg-1',
        conversationId: 'conv-1',
        role: 'assistant',
        content: 'Hi there',
        createdAt: now,
      );

      final map = msg.toMap();
      expect(map['id'], 'msg-1');
      expect(map['conversation_id'], 'conv-1');
      expect(map['role'], 'assistant');
      expect(map['content'], 'Hi there');
      expect(map['created_at'], now.millisecondsSinceEpoch);
    });

    test('fromMap deserializes from SQLite row', () {
      final map = {
        'id': 'msg-1',
        'conversation_id': 'conv-1',
        'role': 'user',
        'content': 'Hello',
        'created_at': now.millisecondsSinceEpoch,
      };

      final msg = ChatMessage.fromMap(map);
      expect(msg.id, 'msg-1');
      expect(msg.conversationId, 'conv-1');
      expect(msg.role, 'user');
      expect(msg.content, 'Hello');
      expect(msg.createdAt, now);
    });
  });
}
```

- [ ] **Step 6: Run test to verify it fails**

Run: `flutter test test/features/chat/domain/chat_message_test.dart`
Expected: Compilation error — `ChatMessage` does not exist.

- [ ] **Step 7: Implement ChatMessage**

Create `lib/features/chat/domain/chat_message.dart`:

```dart
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
```

- [ ] **Step 8: Run test to verify it passes**

Run: `flutter test test/features/chat/domain/chat_message_test.dart`
Expected: All tests PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/features/chat/domain/conversation.dart \
  lib/features/chat/domain/chat_message.dart \
  test/features/chat/domain/conversation_test.dart \
  test/features/chat/domain/chat_message_test.dart
git commit -m "feat(chat): add Conversation and ChatMessage domain models"
```

---

## Task 5: ChatDatabase SQLite helper (TDD)

**Files:**
- Create: `lib/features/chat/data/chat_database.dart`
- Create: `test/features/chat/data/chat_database_test.dart`

- [ ] **Step 1: Write the failing test for ChatDatabase**

Create `test/features/chat/data/chat_database_test.dart`:

```dart
import 'package:cookmate/features/chat/data/chat_database.dart';
import 'package:cookmate/features/chat/domain/chat_message.dart';
import 'package:cookmate/features/chat/domain/conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ChatDatabase chatDb;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    chatDb = ChatDatabase.forTesting(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('conversations', () {
    test('insertConversation and getConversations', () async {
      final now = DateTime.now();
      final conv = Conversation(
        id: 'c1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      await chatDb.insertConversation(conv);
      final list = await chatDb.getConversations();

      expect(list.length, 1);
      expect(list.first.id, 'c1');
      expect(list.first.title, 'Test');
    });

    test('getConversations returns ordered by updated_at DESC', () async {
      final old = DateTime(2026, 1, 1);
      final recent = DateTime(2026, 4, 18);

      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Old',
        createdAt: old,
        updatedAt: old,
      ));
      await chatDb.insertConversation(Conversation(
        id: 'c2',
        title: 'Recent',
        createdAt: recent,
        updatedAt: recent,
      ));

      final list = await chatDb.getConversations();
      expect(list.first.id, 'c2');
      expect(list.last.id, 'c1');
    });

    test('updateConversationTitle updates title', () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Old',
        createdAt: now,
        updatedAt: now,
      ));

      await chatDb.updateConversationTitle('c1', 'New title');
      final list = await chatDb.getConversations();

      expect(list.first.title, 'New title');
    });

    test('deleteConversation removes conversation and its messages', () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Doomed',
        createdAt: now,
        updatedAt: now,
      ));
      await chatDb.insertMessage(ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: 'user',
        content: 'Hello',
        createdAt: now,
      ));

      await chatDb.deleteConversation('c1');

      expect(await chatDb.getConversations(), isEmpty);
      expect(await chatDb.getMessages('c1'), isEmpty);
    });
  });

  group('messages', () {
    test('insertMessage and getMessages', () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Conv',
        createdAt: now,
        updatedAt: now,
      ));
      final msg = ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: 'user',
        content: 'Hello',
        createdAt: now,
      );

      await chatDb.insertMessage(msg);
      final list = await chatDb.getMessages('c1');

      expect(list.length, 1);
      expect(list.first.content, 'Hello');
    });

    test('getMessages returns ordered by created_at ASC', () async {
      final now = DateTime.now();
      await chatDb.insertConversation(Conversation(
        id: 'c1',
        title: 'Conv',
        createdAt: now,
        updatedAt: now,
      ));

      await chatDb.insertMessage(ChatMessage(
        id: 'm2',
        conversationId: 'c1',
        role: 'assistant',
        content: 'Second',
        createdAt: now.add(const Duration(seconds: 1)),
      ));
      await chatDb.insertMessage(ChatMessage(
        id: 'm1',
        conversationId: 'c1',
        role: 'user',
        content: 'First',
        createdAt: now,
      ));

      final list = await chatDb.getMessages('c1');
      expect(list.first.content, 'First');
      expect(list.last.content, 'Second');
    });
  });
}
```

- [ ] **Step 2: Add sqflite_common_ffi dev dependency for tests**

Add to `pubspec.yaml` under `dev_dependencies`:

```yaml
  sqflite_common_ffi: ^2.3.0
```

Run: `flutter pub get`

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/chat/data/chat_database_test.dart`
Expected: Compilation error — `ChatDatabase` does not exist.

- [ ] **Step 4: Implement ChatDatabase**

Create `lib/features/chat/data/chat_database.dart`:

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/chat_message.dart';
import '../domain/conversation.dart';

class ChatDatabase {
  ChatDatabase._(this._db);

  final Database _db;

  static Future<ChatDatabase> open() async {
    final dbPath = join(await getDatabasesPath(), 'cookmate_chat.db');
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return ChatDatabase._(db);
  }

  factory ChatDatabase.forTesting(Database db) => ChatDatabase._(db);

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Conversation>> getConversations() async {
    final rows = await _db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
    return rows.map(Conversation.fromMap).toList();
  }

  Future<void> insertConversation(Conversation conversation) async {
    await _db.insert('conversations', conversation.toMap());
  }

  Future<void> updateConversationTitle(String id, String title) async {
    await _db.update(
      'conversations',
      {'title': title, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteConversation(String id) async {
    await _db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ChatMessage>> getMessages(String conversationId) async {
    final rows = await _db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> insertMessage(ChatMessage message) async {
    await _db.insert('messages', message.toMap());
    await _db.update(
      'conversations',
      {'updated_at': message.createdAt.millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [message.conversationId],
    );
  }

  Future<void> close() async {
    await _db.close();
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/chat/data/chat_database_test.dart`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/data/chat_database.dart \
  test/features/chat/data/chat_database_test.dart \
  pubspec.yaml pubspec.lock
git commit -m "feat(chat): add ChatDatabase SQLite helper with CRUD operations"
```

---

## Task 6: ChatRepository (TDD)

**Files:**
- Create: `lib/features/chat/data/chat_repository.dart`
- Create: `test/features/chat/data/chat_repository_test.dart`

- [ ] **Step 1: Write the failing test for ChatRepository**

Create `test/features/chat/data/chat_repository_test.dart`:

```dart
import 'package:cookmate/features/chat/data/chat_database.dart';
import 'package:cookmate/features/chat/data/chat_repository.dart';
import 'package:cookmate/features/chat/domain/conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

void main() {
  late ChatRepository repository;
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE conversations (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
          )
        ''');
      },
    );
    final chatDb = ChatDatabase.forTesting(db);
    repository = ChatRepository(chatDb);
  });

  tearDown(() async {
    await db.close();
  });

  test('createConversation returns a new conversation with default title', () async {
    final conv = await repository.createConversation('New conversation');

    expect(conv.title, 'New conversation');
    expect(conv.id, isNotEmpty);

    final list = await repository.getConversations();
    expect(list.length, 1);
  });

  test('addUserMessage inserts a message with role user', () async {
    final conv = await repository.createConversation('Test');
    await repository.addUserMessage(conv.id, 'Hello');

    final messages = await repository.getMessages(conv.id);
    expect(messages.length, 1);
    expect(messages.first.role, 'user');
    expect(messages.first.content, 'Hello');
  });

  test('addAssistantMessage inserts a message with role assistant', () async {
    final conv = await repository.createConversation('Test');
    await repository.addAssistantMessage(conv.id, 'Hi there');

    final messages = await repository.getMessages(conv.id);
    expect(messages.length, 1);
    expect(messages.first.role, 'assistant');
    expect(messages.first.content, 'Hi there');
  });

  test('deleteConversation removes conversation', () async {
    final conv = await repository.createConversation('Doomed');
    await repository.deleteConversation(conv.id);

    expect(await repository.getConversations(), isEmpty);
  });

  test('renameConversation updates the title', () async {
    final conv = await repository.createConversation('Old');
    await repository.renameConversation(conv.id, 'New');

    final list = await repository.getConversations();
    expect(list.first.title, 'New');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/chat/data/chat_repository_test.dart`
Expected: Compilation error — `ChatRepository` does not exist.

- [ ] **Step 3: Implement ChatRepository**

Create `lib/features/chat/data/chat_repository.dart`:

```dart
import 'package:uuid/uuid.dart';

import '../domain/chat_message.dart';
import '../domain/conversation.dart';
import 'chat_database.dart';

class ChatRepository {
  ChatRepository(this._db);

  final ChatDatabase _db;
  final _uuid = const Uuid();

  Future<List<Conversation>> getConversations() => _db.getConversations();

  Future<Conversation> createConversation(String defaultTitle) async {
    final now = DateTime.now();
    final conv = Conversation(
      id: _uuid.v4(),
      title: defaultTitle,
      createdAt: now,
      updatedAt: now,
    );
    await _db.insertConversation(conv);
    return conv;
  }

  Future<void> renameConversation(String id, String title) =>
      _db.updateConversationTitle(id, title);

  Future<void> deleteConversation(String id) => _db.deleteConversation(id);

  Future<List<ChatMessage>> getMessages(String conversationId) =>
      _db.getMessages(conversationId);

  Future<ChatMessage> addUserMessage(
      String conversationId, String content) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: 'user',
      content: content,
      createdAt: DateTime.now(),
    );
    await _db.insertMessage(msg);
    return msg;
  }

  Future<ChatMessage> addAssistantMessage(
      String conversationId, String content) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: 'assistant',
      content: content,
      createdAt: DateTime.now(),
    );
    await _db.insertMessage(msg);
    return msg;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/chat/data/chat_repository_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/data/chat_repository.dart \
  test/features/chat/data/chat_repository_test.dart
git commit -m "feat(chat): add ChatRepository with conversation and message operations"
```

---

## Task 7: Riverpod providers (TDD)

**Files:**
- Create: `lib/features/chat/providers.dart`
- Create: `test/features/chat/providers_test.dart`

- [ ] **Step 1: Write the failing test for model preference provider**

Create `test/features/chat/providers_test.dart`:

```dart
import 'package:cookmate/features/chat/domain/chat_model_preference.dart';
import 'package:cookmate/features/chat/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('chatModelPreferenceProvider', () {
    test('builds with gemma4E2B when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final value =
          await container.read(chatModelPreferenceProvider.future);

      expect(value, ChatModelPreference.gemma4E2B);
    });

    test('builds with the stored model when one exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_model_preference': 'gemma4E4B',
      });
      final container = createContainer();

      final value =
          await container.read(chatModelPreferenceProvider.future);

      expect(value, ChatModelPreference.gemma4E4B);
    });

    test('setPreference updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(chatModelPreferenceProvider.future);

      await container
          .read(chatModelPreferenceProvider.notifier)
          .setPreference(ChatModelPreference.gemma4E4B);

      expect(
        container.read(chatModelPreferenceProvider).valueOrNull,
        ChatModelPreference.gemma4E4B,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chat_model_preference'), 'gemma4E4B');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/chat/providers_test.dart`
Expected: Compilation error — providers do not exist.

- [ ] **Step 3: Implement providers**

Create `lib/features/chat/providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/chat_database.dart';
import 'data/chat_model_preference_storage.dart';
import 'data/chat_repository.dart';
import 'domain/chat_model_preference.dart';
import 'domain/conversation.dart';
import 'domain/chat_message.dart';

// ── Database & Repository ──

final chatDatabaseProvider = FutureProvider<ChatDatabase>((ref) async {
  final db = await ChatDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final chatRepositoryProvider = FutureProvider<ChatRepository>((ref) async {
  final db = await ref.watch(chatDatabaseProvider.future);
  return ChatRepository(db);
});

// ── Conversations list ──

final conversationsProvider =
    AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>(
  ConversationsNotifier.new,
);

class ConversationsNotifier extends AsyncNotifier<List<Conversation>> {
  @override
  Future<List<Conversation>> build() async {
    final repo = await ref.watch(chatRepositoryProvider.future);
    return repo.getConversations();
  }

  Future<Conversation> create(String defaultTitle) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    final conv = await repo.createConversation(defaultTitle);
    ref.invalidateSelf();
    return conv;
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.deleteConversation(id);
    ref.invalidateSelf();
  }

  Future<void> rename(String id, String title) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.renameConversation(id, title);
    ref.invalidateSelf();
  }
}

// ── Messages for a conversation ──

final messagesProvider = AsyncNotifierProvider.family<MessagesNotifier,
    List<ChatMessage>, String>(
  MessagesNotifier.new,
);

class MessagesNotifier
    extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  @override
  Future<List<ChatMessage>> build(String arg) async {
    final repo = await ref.watch(chatRepositoryProvider.future);
    return repo.getMessages(arg);
  }

  Future<void> addUserMessage(String content) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.addUserMessage(arg, content);
    ref.invalidateSelf();
  }

  Future<void> addAssistantMessage(String content) async {
    final repo = await ref.read(chatRepositoryProvider.future);
    await repo.addAssistantMessage(arg, content);
    ref.invalidateSelf();
  }
}

// ── Model preference ──

final chatModelPreferenceStorageProvider =
    FutureProvider<ChatModelPreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ChatModelPreferenceStorage(prefs);
});

class ChatModelPreferenceNotifier extends AsyncNotifier<ChatModelPreference> {
  @override
  Future<ChatModelPreference> build() async {
    final storage =
        await ref.watch(chatModelPreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(ChatModelPreference model) async {
    final storage =
        await ref.read(chatModelPreferenceStorageProvider.future);
    state = const AsyncValue<ChatModelPreference>.loading()
        .copyWithPrevious(state);
    try {
      await storage.write(model);
      state = AsyncValue.data(model);
    } catch (error, stack) {
      state = AsyncValue<ChatModelPreference>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final chatModelPreferenceProvider =
    AsyncNotifierProvider<ChatModelPreferenceNotifier, ChatModelPreference>(
  ChatModelPreferenceNotifier.new,
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/chat/providers_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/providers.dart \
  test/features/chat/providers_test.dart
git commit -m "feat(chat): add Riverpod providers for conversations, messages, and model preference"
```

---

## Task 8: ModelPickerTile + Settings integration

**Files:**
- Create: `lib/features/chat/presentation/model_picker_tile.dart`
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Create ModelPickerTile**

Create `lib/features/chat/presentation/model_picker_tile.dart`:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_model_preference.dart';
import '../providers.dart';

class ModelPickerTile extends ConsumerWidget {
  const ModelPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferenceAsync = ref.watch(chatModelPreferenceProvider);
    final model =
        preferenceAsync.valueOrNull ?? ChatModelPreference.defaultModel;

    return ListTile(
      leading: const Icon(Icons.smart_toy_outlined),
      title: Text(l10n.settingsModelTitle),
      subtitle: Text(_modelLabel(l10n, model)),
      onTap: () => _openDialog(context, ref, model),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    ChatModelPreference current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<ChatModelPreference>(
      context: context,
      builder: (dialogContext) {
        return RadioGroup<ChatModelPreference>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              Navigator.of(dialogContext).pop(value);
            }
          },
          child: SimpleDialog(
            title: Text(l10n.settingsModelDialogTitle),
            children: [
              for (final model in ChatModelPreference.values)
                _OptionTile(label: _modelLabel(l10n, model), value: model),
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
          .read(chatModelPreferenceProvider.notifier)
          .setPreference(selected);
    } catch (error, stack) {
      debugPrint('Failed to change model: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsModelChangeFailureSnackbar)),
      );
    }
  }

  String _modelLabel(AppLocalizations l10n, ChatModelPreference model) {
    return switch (model) {
      ChatModelPreference.gemma4E2B => l10n.settingsModelOptionE2B,
      ChatModelPreference.gemma4E4B => l10n.settingsModelOptionE4B,
    };
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.value});

  final String label;
  final ChatModelPreference value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ChatModelPreference>(
      title: Text(label),
      value: value,
    );
  }
}
```

- [ ] **Step 2: Add ModelPickerTile to SettingsPage**

Modify `lib/features/settings/presentation/settings_page.dart` to become:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../chat/presentation/model_picker_tile.dart';
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
          ModelPickerTile(),
          Divider(height: 1),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify build compiles**

Run: `flutter build apk --debug 2>&1 | tail -5` (or `flutter analyze`)
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/presentation/model_picker_tile.dart \
  lib/features/settings/presentation/settings_page.dart
git commit -m "feat(settings): add AI model picker tile"
```

---

## Task 9: Message bubble and chat input bar widgets

**Files:**
- Create: `lib/features/chat/presentation/widgets/message_bubble.dart`
- Create: `lib/features/chat/presentation/widgets/chat_input_bar.dart`

- [ ] **Step 1: Create MessageBubble widget**

Create `lib/features/chat/presentation/widgets/message_bubble.dart`:

```dart
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.content,
    required this.isUser,
  });

  final String content;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Create ChatInputBar widget**

Create `lib/features/chat/presentation/widgets/chat_input_bar.dart`:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSubmit,
    this.enabled = true,
  });

  final ValueChanged<String> onSubmit;
  final bool enabled;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSubmit(),
                decoration: InputDecoration(
                  hintText: l10n.chatInputHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: widget.enabled ? _handleSubmit : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/presentation/widgets/message_bubble.dart \
  lib/features/chat/presentation/widgets/chat_input_bar.dart
git commit -m "feat(chat): add MessageBubble and ChatInputBar widgets"
```

---

## Task 10: Model download page

**Files:**
- Create: `lib/features/chat/presentation/model_download_page.dart`

- [ ] **Step 1: Create ModelDownloadPage**

Create `lib/features/chat/presentation/model_download_page.dart`:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_model_preference.dart';
import '../providers.dart';

const _modelUrls = {
  ChatModelPreference.gemma4E2B:
      'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.task',
  ChatModelPreference.gemma4E4B:
      'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.task',
};

class ModelDownloadPage extends ConsumerStatefulWidget {
  const ModelDownloadPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<ModelDownloadPage> createState() => _ModelDownloadPageState();
}

class _ModelDownloadPageState extends ConsumerState<ModelDownloadPage> {
  int _progress = 0;
  String? _error;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });

    try {
      final model = ref.read(chatModelPreferenceProvider).valueOrNull ??
          ChatModelPreference.defaultModel;
      final url = _modelUrls[model]!;

      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(url)
          .withProgress((progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      }).install();

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smart_toy_outlined, size: 64),
              const SizedBox(height: 24),
              Text(
                l10n.chatModelDownloadTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  l10n.chatModelDownloadError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _startDownload,
                  child: Text(l10n.chatModelDownloadRetry),
                ),
              ] else ...[
                LinearProgressIndicator(value: _progress / 100),
                const SizedBox(height: 8),
                Text(l10n.chatModelDownloadProgress(_progress)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/chat/presentation/model_download_page.dart
git commit -m "feat(chat): add model download page with progress indicator"
```

---

## Task 11: ChatPage — conversation list

**Files:**
- Modify: `lib/features/chat/presentation/chat_page.dart`

- [ ] **Step 1: Replace ChatPage placeholder with conversation list**

Replace the entire content of `lib/features/chat/presentation/chat_page.dart`:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatConversationsTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final conv = await ref
              .read(conversationsProvider.notifier)
              .create(l10n.chatNewConversation);
          if (context.mounted) {
            context.go('/home/chat/${conv.id}');
          }
        },
        child: const Icon(Icons.add),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(child: Text(l10n.chatEmptyState));
          }
          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return Dismissible(
                key: ValueKey(conv.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Theme.of(context).colorScheme.error,
                  child: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(l10n.chatDeleteConversation),
                      content: Text(l10n.chatDeleteConfirmation),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  ref.read(conversationsProvider.notifier).delete(conv.id);
                },
                child: ListTile(
                  title: Text(
                    conv.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatDate(conv.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => context.go('/home/chat/${conv.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
```

- [ ] **Step 2: Verify build**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/presentation/chat_page.dart
git commit -m "feat(chat): replace placeholder with conversation list"
```

---

## Task 12: ConversationPage — chat view with streaming

**Files:**
- Create: `lib/features/chat/presentation/conversation_page.dart`

- [ ] **Step 1: Create ConversationPage**

Create `lib/features/chat/presentation/conversation_page.dart`:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_model_preference.dart';
import '../providers.dart';
import 'model_download_page.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/message_bubble.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _scrollController = ScrollController();
  InferenceChat? _chat;
  bool _isGenerating = false;
  String _streamingContent = '';
  bool _modelReady = false;
  bool _isFirstExchange = true;

  static const _systemPrompt =
      'You are CookMate, a friendly kitchen assistant specialized in Thermomix recipes. '
      'Help users create, adapt, and improve their Thermomix recipes. '
      'Answer in the same language the user writes in. '
      'Keep responses concise and practical.';

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    final installed = await FlutterGemma.isModelInstalled('gemmaIt');
    if (mounted) {
      setState(() => _modelReady = installed);
    }
    if (installed) {
      await _createChat();
    }
  }

  Future<void> _createChat() async {
    final model = await FlutterGemma.getActiveModel(
      maxTokens: 2048,
      preferredBackend: PreferredBackend.gpu,
    );
    _chat = await model.createChat(
      temperature: 0.8,
      topK: 40,
      systemInstruction: _systemPrompt,
    );
  }

  Future<void> _handleSend(String text) async {
    if (_chat == null || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _streamingContent = '';
    });

    await ref
        .read(messagesProvider(widget.conversationId).notifier)
        .addUserMessage(text);
    _scrollToBottom();

    await _chat!.addQueryChunk(Message.text(text: text, isUser: true));

    final buffer = StringBuffer();
    await for (final token in _chat!.generateChatResponseAsync()) {
      buffer.write(token);
      if (mounted) {
        setState(() => _streamingContent = buffer.toString());
        _scrollToBottom();
      }
    }

    final fullResponse = buffer.toString();
    await ref
        .read(messagesProvider(widget.conversationId).notifier)
        .addAssistantMessage(fullResponse);

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _streamingContent = '';
      });
    }

    if (_isFirstExchange) {
      _isFirstExchange = false;
      _autoName(text);
    }
  }

  Future<void> _autoName(String firstUserMessage) async {
    try {
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 64,
        preferredBackend: PreferredBackend.gpu,
      );
      final session = await model.createSession(temperature: 0.3, topK: 1);
      await session.addQueryChunk(Message.text(
        text:
            'Summarize this conversation in 3-5 words as a title: $firstUserMessage',
        isUser: true,
      ));
      final title = await session.getResponse();
      session.close();

      final cleaned = title.trim().replaceAll(RegExp(r'^["\']+|["\']+$'), '');
      if (cleaned.isNotEmpty) {
        await ref
            .read(conversationsProvider.notifier)
            .rename(widget.conversationId, cleaned);
      }
    } catch (_) {
      // Title generation is best-effort; ignore failures.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_modelReady) {
      return ModelDownloadPage(
        onComplete: () {
          setState(() => _modelReady = true);
          _createChat();
        },
      );
    }

    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final conversationsAsync = ref.watch(conversationsProvider);
    final title = conversationsAsync.valueOrNull
            ?.where((c) => c.id == widget.conversationId)
            .firstOrNull
            ?.title ??
        '';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (messages) {
                final totalItems =
                    messages.length + (_isGenerating ? 1 : 0);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: totalItems,
                  itemBuilder: (context, index) {
                    if (index < messages.length) {
                      final msg = messages[index];
                      return MessageBubble(
                        content: msg.content,
                        isUser: msg.role == 'user',
                      );
                    }
                    return MessageBubble(
                      content: _streamingContent,
                      isUser: false,
                    );
                  },
                );
              },
            ),
          ),
          ChatInputBar(
            onSubmit: _handleSend,
            enabled: !_isGenerating,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify build**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/presentation/conversation_page.dart
git commit -m "feat(chat): add conversation page with streaming LLM responses"
```

---

## Task 13: Update router with conversation sub-route

**Files:**
- Modify: `lib/core/router.dart`

- [ ] **Step 1: Add conversation sub-route**

Replace the entire content of `lib/core/router.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/chat/presentation/chat_page.dart';
import '../features/chat/presentation/conversation_page.dart';
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
                routes: [
                  GoRoute(
                    path: ':conversationId',
                    builder: (context, state) => ConversationPage(
                      conversationId:
                          state.pathParameters['conversationId']!,
                    ),
                  ),
                ],
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

- [ ] **Step 2: Verify build**

Run: `flutter analyze`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/core/router.dart
git commit -m "feat(chat): add conversation sub-route to router"
```

---

## Task 14: Run full test suite and verify

- [ ] **Step 1: Run all tests**

Run: `flutter test`
Expected: All tests PASS. No regressions.

- [ ] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Verify l10n generation**

Run: `flutter gen-l10n`
Expected: No errors.

- [ ] **Step 4: Final commit if any generated files changed**

If `app_localizations.dart` or related generated files changed:

```bash
git add lib/l10n/
git commit -m "chore(l10n): regenerate localization files"
```
