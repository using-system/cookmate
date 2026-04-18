# On-Device Chat with Gemma 4

## Overview

Implement a local LLM-powered chat feature in CookMate using `flutter_gemma` for
on-device inference with Gemma 4 edge models, and `sqflite` for persistent
conversation history. The assistant acts as a Thermomix recipe helper with a
basic system prompt. No tools, RAG, vision, or function calling — text chat only.

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_gemma` | `^0.13.5` | On-device Gemma 4 inference (streaming, session management) |
| `sqflite` | `^2.3.0` | SQLite database for conversation/message history |
| `path` | `^1.9.0` | Resolve database file path |
| `uuid` | `^4.0.0` | Generate unique IDs for conversations and messages |

## Data Model

### SQLite Schema

**Table `conversations`**

| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | UUID |
| `title` | TEXT | Auto-generated from first exchange, or "New conversation" |
| `created_at` | INTEGER | Epoch milliseconds |
| `updated_at` | INTEGER | Epoch milliseconds |

**Table `messages`**

| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | UUID |
| `conversation_id` | TEXT FK | References conversations.id |
| `role` | TEXT | `user` or `assistant` |
| `content` | TEXT | Message text |
| `created_at` | INTEGER | Epoch milliseconds |

### Domain Models

```dart
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
}
```

## Feature Structure

```
lib/features/chat/
├── domain/
│   ├── conversation.dart
│   ├── chat_message.dart
│   └── chat_model_preference.dart    # Enum: gemma4E2B (default), gemma4E4B
├── data/
│   ├── chat_database.dart            # SQLite helper (open, create tables, CRUD)
│   ├── chat_repository.dart          # Repository over ChatDatabase
│   └── chat_model_preference_storage.dart  # SharedPreferences read/write
├── providers.dart                    # All Riverpod providers for chat
└── presentation/
    ├── chat_page.dart                # Conversation list (replaces placeholder)
    ├── conversation_page.dart        # Single conversation view (messages + input)
    ├── model_download_page.dart      # Download progress screen
    └── widgets/
        ├── message_bubble.dart       # User/assistant message bubble
        └── chat_input_bar.dart       # Text field + send button
```

## Navigation & Routing

### Routes

| Path | Screen | Description |
|------|--------|-------------|
| `/home/chat` | `ChatPage` | Conversation list (tab 1 in bottom nav) |
| `/home/chat/:conversationId` | `ConversationPage` | Messages for a single conversation |

Both nested under the existing `StatefulShellRoute` so the bottom nav persists.

### ChatPage (conversation list)

- AppBar with localized title
- FAB "+" to create a new conversation (creates DB row, navigates to it)
- ListView of conversations sorted by `updated_at` DESC
- Each item shows title + relative timestamp
- Swipe-to-delete with confirmation dialog
- Empty state when no conversations exist

### ConversationPage (chat view)

- AppBar showing conversation title (tappable to edit)
- Scrollable message list, auto-scrolls to bottom on new messages
- `ChatInputBar` pinned at bottom: TextField + send button
- Assistant responses stream token-by-token into a growing bubble
- Send button disabled while model is generating

### Auto-Naming

After the first user message and the model's complete first response, a separate
inference request generates a short title:

> "Summarize this conversation in 3-5 words as a title: [user message]"

The title updates in SQLite and the UI refreshes via the conversations provider.

## Model Management

### Download Flow

The Gemma 4 model files (~1.3 GB for E2B, ~2.5 GB for E4B) are not bundled.
They are downloaded at first use from HuggingFace via
`FlutterGemma.installModel().fromNetwork()`.

1. `ChatPage` checks `FlutterGemma.isModelInstalled()` on mount.
2. If not installed, navigates to `ModelDownloadPage` with a progress bar.
3. On completion, returns to `ChatPage`.
4. On failure, shows error message with retry button.

### Model Switching

When the user changes model in Settings (E2B ↔ E4B):
- The preference is persisted to SharedPreferences.
- If the new model is not installed, the download screen appears on next chat access.
- The `inferenceModelProvider` is invalidated to recreate with the new model.

## Riverpod Providers

```
chatDatabaseProvider            → FutureProvider<ChatDatabase>
chatRepositoryProvider          → FutureProvider<ChatRepository>
conversationsProvider           → AsyncNotifierProvider<ConversationsNotifier, List<Conversation>>
messagesProvider(convId)        → AsyncNotifierProvider.family<MessagesNotifier, List<ChatMessage>, String>
chatModelPreferenceProvider     → AsyncNotifierProvider<ChatModelPreferenceNotifier, ChatModelPreference>
chatBackendPreferenceProvider   → AsyncNotifierProvider<ChatBackendPreferenceNotifier, ChatBackendPreference>
```

Provider dependency chain:
`sharedPreferencesProvider` → `chatModelPreferenceStorageProvider` → `chatModelPreferenceProvider`

## Inference Configuration

| Parameter | Value |
|-----------|-------|
| `maxTokens` | 2048 |
| `temperature` | 0.8 |
| `topK` | 40 |
| `preferredBackend` | `PreferredBackend.gpu` |

### System Prompt

```
You are CookMate, a friendly kitchen assistant specialized in Thermomix recipes.
Help users create, adapt, and improve their Thermomix recipes.
Answer in the same language the user writes in.
Keep responses concise and practical.
```

Passed via `systemInstruction` in `InferenceModel.createChat()`.

## Settings Integration

A new `ModelPickerTile` is added to `SettingsPage`, following the exact same
pattern as `ThemePickerTile` and `LanguagePickerTile`:

- Shows current model name as subtitle
- Opens a dialog with two radio options
- Persists choice to SharedPreferences via `ChatModelPreferenceStorage`
- Default: `gemma4E2B`

## Internationalization

New ARB keys added to all 4 locales (en, fr, de, es). Existing `chatTitle` and
`chatPlaceholder` keys are removed and replaced.

| Key | EN |
|-----|----|
| `chatConversationsTitle` | Conversations |
| `chatNewConversation` | New conversation |
| `chatDeleteConversation` | Delete conversation |
| `chatDeleteConfirmation` | Delete this conversation? |
| `chatInputHint` | Type a message… |
| `chatEmptyState` | No conversations yet. Tap + to start! |
| `chatModelDownloadTitle` | Downloading AI model… |
| `chatModelDownloadProgress` | {progress}% complete |
| `chatModelDownloadError` | Download failed. Check your connection and try again. |
| `chatModelDownloadRetry` | Retry |
| `settingsModelTitle` | AI Model |
| `settingsModelDialogTitle` | Choose AI model |
| `settingsModelOptionE2B` | Gemma 4 E2B (lighter, faster) |
| `settingsModelOptionE4B` | Gemma 4 E4B (smarter, heavier) |
| `cancel` | Cancel |
| `delete` | Delete |

## Excluded From Scope

- No tools / function calling
- No vision or audio input (text only)
- No RAG or recipe knowledge base
- No export or sharing of conversations
- No search within history
- No visible thinking mode
- No message edit or regeneration
- No LoRA adapters
