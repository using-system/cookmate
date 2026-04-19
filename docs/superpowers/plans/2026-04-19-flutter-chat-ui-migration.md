# Flutter Chat UI Migration + Multimodal Input

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the custom chat UI with `flutter_chat_ui` v2 (Flyer Chat), add image input (camera + gallery) and audio recording, while preserving the thinking/reflection display and conversation history.

**Architecture:** The `Chat` widget from `flutter_chat_ui` replaces all custom widgets (`ChatListWidget`, `ChatInputBar`, `MessageBubble`, `ThinkingBubble`). An `InMemoryChatController` bridges `ChatRepository` (SQLite persistence) with the UI. Thinking/reflection uses `Message.custom` with a `customMessageBuilder`. Image and audio inputs use `image_picker` and `record` packages, feeding bytes to `flutter_gemma`'s multimodal API (`Message.withImage`). The existing `ConversationPage` is rewritten; `ChatPage` (conversation list) is untouched.

**Tech Stack:** flutter_chat_ui ^2.11.1, flutter_chat_core ^2.9.0, flyer_chat_text_message, flyer_chat_text_stream_message, image_picker ^1.2.1, record ^6.2.0, uuid (already present), flutter_gemma ^0.13.5 (already present)

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `pubspec.yaml` | Add new dependencies |
| Modify | `SPEC.md` | Update tech stack documentation |
| Delete | `lib/features/chat/presentation/widgets/chat_input_bar.dart` | Replaced by Chat widget's built-in composer |
| Delete | `lib/features/chat/presentation/widgets/chat_list_widget.dart` | Replaced by Chat widget's message list |
| Delete | `lib/features/chat/presentation/widgets/message_bubble.dart` | Replaced by FlyerChatTextMessage |
| Delete | `lib/features/chat/presentation/widgets/thinking_bubble.dart` | Replaced by customMessageBuilder |
| Rewrite | `lib/features/chat/presentation/conversation_page.dart` | New Chat widget integration |
| Modify | `lib/features/chat/domain/chat_message.dart` | Add `type` and `mediaPath` fields |
| Modify | `lib/features/chat/data/chat_database.dart` | DB migration v2: add `type` and `media_path` columns |
| Modify | `lib/features/chat/data/chat_repository.dart` | Add methods for image/audio messages |
| Modify | `lib/l10n/app_en.arb` | New i18n keys for media actions |
| Modify | `lib/l10n/app_fr.arb` | French translations |
| Modify | `lib/l10n/app_de.arb` | German translations |
| Modify | `lib/l10n/app_es.arb` | Spanish translations |

---

### Task 1: Add dependencies

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add flutter_chat_ui and companion packages**

In `pubspec.yaml`, add under `dependencies:` (after the `uuid` line):

```yaml
  flutter_chat_ui: ^2.11.1
  flutter_chat_core: ^2.9.0
  flyer_chat_text_message: ^0.2.0
  flyer_chat_text_stream_message: ^0.2.0
  image_picker: ^1.2.1
  record: ^6.2.0
```

- [ ] **Step 2: Run pub get**

Run: `flutter pub get`
Expected: resolves without conflicts.

- [ ] **Step 3: Commit**

```
feat(chat): add flutter_chat_ui, image_picker, and record dependencies
```

---

### Task 2: Update SPEC.md

**Files:**
- Modify: `SPEC.md`

- [ ] **Step 1: Update SPEC.md to reflect new packages**

Replace the full content of `SPEC.md` with:

```markdown
# Tech Stack

## Framework

- Flutter (Dart)
- Material 3

## State Management

- flutter_riverpod

## Navigation

- go_router

## Local Storage

- shared_preferences (key-value settings)
- sqflite (SQLite — chat history)

## On-Device AI

- flutter_gemma (Gemma 4 E2B / E4B inference, multimodal: vision + audio)

## Chat UI

- flutter_chat_ui (Flyer Chat v2 — message list, composer, streaming)
- flutter_chat_core (message models, controller)
- flyer_chat_text_message (text bubble renderer)
- flyer_chat_text_stream_message (streaming AI response renderer)

## Media Input

- image_picker (camera capture + gallery selection)
- record (live audio recording)

## Internationalization

- flutter_localizations (ARB-based, 4 locales: en, fr, de, es)

## Build & CI

- GitHub Actions (CI + release workflows)
- Firebase App Distribution (signed APK)
- flutter_launcher_icons

## Testing

- flutter_test
- sqflite_common_ffi (SQLite test helper)

## Utilities

- path
- uuid
- cupertino_icons
```

- [ ] **Step 2: Commit**

```
docs: update SPEC.md with flutter_chat_ui and media input packages
```

---

### Task 3: Extend domain model for media messages

**Files:**
- Modify: `lib/features/chat/domain/chat_message.dart`

- [ ] **Step 1: Add type and mediaPath fields to ChatMessage**

Replace the full `ChatMessage` class with:

```dart
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.type = 'text',
    this.mediaPath,
  });

  final String id;
  final String conversationId;
  final String role;
  final String content;
  final DateTime createdAt;

  /// Message type: 'text', 'image', or 'audio'.
  final String type;

  /// Local file path for image or audio messages.
  final String? mediaPath;

  Map<String, Object?> toMap() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role,
        'content': content,
        'created_at': createdAt.millisecondsSinceEpoch,
        'type': type,
        'media_path': mediaPath,
      };

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
        id: map['id'] as String,
        conversationId: map['conversation_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        type: (map['type'] as String?) ?? 'text',
        mediaPath: map['media_path'] as String?,
      );
}
```

- [ ] **Step 2: Commit**

```
feat(chat): add type and mediaPath fields to ChatMessage
```

---

### Task 4: Database migration for media columns

**Files:**
- Modify: `lib/features/chat/data/chat_database.dart`

- [ ] **Step 1: Bump DB version and add migration**

In `chat_database.dart`, change the `openDatabase` call to version 2 and add an `onUpgrade` callback:

```dart
  static Future<ChatDatabase> open() async {
    final dbPath = join(await getDatabasesPath(), 'cookmate_chat.db');
    final db = await openDatabase(
      dbPath,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return ChatDatabase._(db);
  }
```

- [ ] **Step 2: Update _onCreate to include new columns**

Update the messages table in `_onCreate`:

```dart
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
        type TEXT NOT NULL DEFAULT 'text',
        media_path TEXT,
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');
  }
```

- [ ] **Step 3: Add _onUpgrade method**

Add after `_onCreate`:

```dart
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE messages ADD COLUMN type TEXT NOT NULL DEFAULT 'text'");
      await db.execute('ALTER TABLE messages ADD COLUMN media_path TEXT');
    }
  }
```

- [ ] **Step 4: Commit**

```
feat(chat): migrate database to v2 with type and media_path columns
```

---

### Task 5: Extend ChatRepository for media messages

**Files:**
- Modify: `lib/features/chat/data/chat_repository.dart`

- [ ] **Step 1: Add addImageMessage and addAudioMessage methods**

Add these methods to the `ChatRepository` class (after `addAssistantMessage`):

```dart
  Future<ChatMessage> addImageMessage(
      String conversationId, String caption, String mediaPath) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: 'user',
      content: caption,
      createdAt: DateTime.now(),
      type: 'image',
      mediaPath: mediaPath,
    );
    await _db.insertMessage(msg);
    return msg;
  }

  Future<ChatMessage> addAudioMessage(
      String conversationId, String mediaPath) async {
    final msg = ChatMessage(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: 'user',
      content: '',
      createdAt: DateTime.now(),
      type: 'audio',
      mediaPath: mediaPath,
    );
    await _db.insertMessage(msg);
    return msg;
  }
```

- [ ] **Step 2: Commit**

```
feat(chat): add image and audio message methods to ChatRepository
```

---

### Task 6: Add i18n keys for media actions

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_es.arb`

- [ ] **Step 1: Add keys to app_en.arb**

Add before the closing `}`:

```json
  "chatAttachPhoto": "Photo",
  "@chatAttachPhoto": { "description": "Label for the take photo action." },

  "chatAttachGallery": "Gallery",
  "@chatAttachGallery": { "description": "Label for the pick from gallery action." },

  "chatAttachAudio": "Record audio",
  "@chatAttachAudio": { "description": "Label for the record audio action." },

  "chatRecordingInProgress": "Recording\u2026",
  "@chatRecordingInProgress": { "description": "Shown while audio recording is active." },

  "chatImageCaption": "Image",
  "@chatImageCaption": { "description": "Default caption for an image message." },

  "chatAudioCaption": "Audio message",
  "@chatAudioCaption": { "description": "Default caption for an audio message." },

  "chatMediaPermissionDenied": "Permission denied. Please allow access in Settings.",
  "@chatMediaPermissionDenied": { "description": "Shown when camera or microphone permission is denied." }
```

- [ ] **Step 2: Add keys to app_fr.arb**

```json
  "chatAttachPhoto": "Photo",
  "chatAttachGallery": "Galerie",
  "chatAttachAudio": "Enregistrer audio",
  "chatRecordingInProgress": "Enregistrement\u2026",
  "chatImageCaption": "Image",
  "chatAudioCaption": "Message audio",
  "chatMediaPermissionDenied": "Permission refusée. Veuillez autoriser l'accès dans les Réglages."
```

- [ ] **Step 3: Add keys to app_de.arb**

```json
  "chatAttachPhoto": "Foto",
  "chatAttachGallery": "Galerie",
  "chatAttachAudio": "Audio aufnehmen",
  "chatRecordingInProgress": "Aufnahme\u2026",
  "chatImageCaption": "Bild",
  "chatAudioCaption": "Sprachnachricht",
  "chatMediaPermissionDenied": "Zugriff verweigert. Bitte in den Einstellungen erlauben."
```

- [ ] **Step 4: Add keys to app_es.arb**

```json
  "chatAttachPhoto": "Foto",
  "chatAttachGallery": "Galería",
  "chatAttachAudio": "Grabar audio",
  "chatRecordingInProgress": "Grabando\u2026",
  "chatImageCaption": "Imagen",
  "chatAudioCaption": "Mensaje de audio",
  "chatMediaPermissionDenied": "Permiso denegado. Por favor, permita el acceso en Ajustes."
```

- [ ] **Step 5: Commit**

```
feat(i18n): add media input strings for all 4 locales
```

---

### Task 7: Rewrite ConversationPage with flutter_chat_ui

This is the core task. It replaces the entire custom UI with `flutter_chat_ui`'s `Chat` widget, wires up `TextStreamController` for AI streaming, `customMessageBuilder` for thinking bubbles, and adds attachment buttons for image/audio.

**Files:**
- Rewrite: `lib/features/chat/presentation/conversation_page.dart`
- Delete: `lib/features/chat/presentation/widgets/chat_input_bar.dart`
- Delete: `lib/features/chat/presentation/widgets/chat_list_widget.dart`
- Delete: `lib/features/chat/presentation/widgets/message_bubble.dart`
- Delete: `lib/features/chat/presentation/widgets/thinking_bubble.dart`

- [ ] **Step 1: Delete the 4 custom widget files**

Delete these files:
- `lib/features/chat/presentation/widgets/chat_input_bar.dart`
- `lib/features/chat/presentation/widgets/chat_list_widget.dart`
- `lib/features/chat/presentation/widgets/message_bubble.dart`
- `lib/features/chat/presentation/widgets/thinking_bubble.dart`

- [ ] **Step 2: Rewrite conversation_page.dart**

Replace the entire file with:

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../domain/chat_backend_preference.dart';
import '../domain/chat_message.dart' as domain;
import '../domain/chat_model_preference.dart';
import '../providers.dart';
import 'model_download_page.dart';

const _userId = 'user';
const _aiId = 'assistant';
const _uuid = Uuid();

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final _chatController = InMemoryChatController();
  final _textStreamController = TextStreamController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  InferenceChat? _chat;
  bool _isGenerating = false;
  bool _modelReady = false;
  String? _chatError;
  bool _isRecording = false;

  static const _systemPrompt =
      'You are CookMate, a friendly kitchen assistant specialized in Thermomix recipes. '
      'Help users create, adapt, and improve their Thermomix recipes. '
      'Answer in the same language the user writes in. '
      'Keep responses concise and practical.';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initModel();
  }

  @override
  void dispose() {
    _chatController.dispose();
    _textStreamController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ── Model init ──

  Future<void> _initModel() async {
    final hasModel = FlutterGemma.hasActiveModel();
    final isCorrectModel =
        await ref.read(isPreferredModelInstalledProvider.future);
    final ready = hasModel && isCorrectModel;
    if (mounted) {
      setState(() => _modelReady = ready);
    }
    if (ready) {
      await _createChat();
    }
  }

  Future<void> _createChat() async {
    try {
      final pref = await ref.read(chatBackendPreferenceProvider.future);
      final backend = pref == ChatBackendPreference.gpu
          ? PreferredBackend.gpu
          : PreferredBackend.cpu;

      final model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: backend,
      );
      _chat = await model.createChat(
        temperature: 0.8,
        topK: 40,
        systemInstruction: _systemPrompt,
        isThinking: true,
        supportImage: true,
      );

      // Replay stored history so InferenceChat has full context.
      final repo = await ref.read(chatRepositoryProvider.future);
      final messages = await repo.getMessages(widget.conversationId);
      for (final msg in messages) {
        await _chat!.addQueryChunk(
          Message.text(text: msg.content, isUser: msg.role == 'user'),
        );
      }

      if (mounted) {
        setState(() => _chatError = null);
      }
    } catch (e, stack) {
      debugPrint('Failed to create chat: $e\n$stack');
      if (mounted) {
        setState(() => _chatError = e.toString());
      }
    }
  }

  // ── Load persisted messages into ChatController ──

  Future<void> _loadMessages() async {
    final repo = await ref.read(chatRepositoryProvider.future);
    final messages = await repo.getMessages(widget.conversationId);
    for (final msg in messages) {
      await _chatController.insertMessage(_domainToFlyer(msg));
    }
  }

  Message _domainToFlyer(domain.ChatMessage msg) {
    final authorId = msg.role == 'user' ? _userId : _aiId;
    switch (msg.type) {
      case 'image':
        return Message.image(
          id: msg.id.isEmpty ? _uuid.v4() : msg.id,
          authorId: authorId,
          createdAt: msg.createdAt,
          source: msg.mediaPath ?? '',
          text: msg.content,
        );
      case 'audio':
        return Message.audio(
          id: msg.id.isEmpty ? _uuid.v4() : msg.id,
          authorId: authorId,
          createdAt: msg.createdAt,
          source: msg.mediaPath ?? '',
        );
      default:
        return Message.text(
          id: msg.id.isEmpty ? _uuid.v4() : msg.id,
          authorId: authorId,
          createdAt: msg.createdAt,
          text: msg.content,
        );
    }
  }

  // ── Send text message ──

  Future<void> _handleSend(String text) async {
    if (_isGenerating || _chat == null) return;
    setState(() => _isGenerating = true);

    try {
      // Add user message to controller.
      final userMsg = TextMessage(
        id: _uuid.v4(),
        authorId: _userId,
        createdAt: DateTime.now().toUtc(),
        text: text,
      );
      await _chatController.insertMessage(userMsg);

      // Persist (fire-and-forget).
      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addUserMessage(widget.conversationId, text),
          );

      // Send to InferenceChat.
      await _chat!.addQueryChunk(Message.text(text: text, isUser: true));

      await _streamAiResponse();
      await _autoNameIfNeeded(text);
    } catch (e, stack) {
      debugPrint('Send failed: $e\n$stack');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── Send image message ──

  Future<void> _handleImageSend(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null || _chat == null) return;

    setState(() => _isGenerating = true);
    try {
      final l10n = AppLocalizations.of(context);
      final filePath = picked.path;

      // Add image to chat UI.
      final imgMsg = ImageMessage(
        id: _uuid.v4(),
        authorId: _userId,
        createdAt: DateTime.now().toUtc(),
        source: filePath,
        text: l10n.chatImageCaption,
      );
      await _chatController.insertMessage(imgMsg);

      // Persist.
      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addImageMessage(
                widget.conversationId, l10n.chatImageCaption, filePath),
          );

      // Send image bytes to Gemma for vision analysis.
      final bytes = await File(filePath).readAsBytes();
      await _chat!.addQueryChunk(
        Message.withImage(
          text: l10n.chatImageCaption,
          image: Uint8List.fromList(bytes),
          isUser: true,
        ),
      );

      await _streamAiResponse();
    } catch (e, stack) {
      debugPrint('Image send failed: $e\n$stack');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ── Record and send audio ──

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path == null || _chat == null) return;

      setState(() => _isGenerating = true);
      try {
        final l10n = AppLocalizations.of(context);

        // Add audio to chat UI.
        final audioMsg = AudioMessage(
          id: _uuid.v4(),
          authorId: _userId,
          createdAt: DateTime.now().toUtc(),
          source: path,
        );
        await _chatController.insertMessage(audioMsg);

        // Persist.
        ref.read(chatRepositoryProvider.future).then(
              (repo) => repo.addAudioMessage(widget.conversationId, path),
            );

        // Send audio bytes to Gemma.
        final bytes = await File(path).readAsBytes();
        await _chat!.addQueryChunk(
          Message.withAudio(
            text: l10n.chatAudioCaption,
            audio: Uint8List.fromList(bytes),
            isUser: true,
          ),
        );

        await _streamAiResponse();
      } catch (e, stack) {
        debugPrint('Audio send failed: $e\n$stack');
      } finally {
        if (mounted) setState(() => _isGenerating = false);
      }
    } else {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chatMediaPermissionDenied)),
          );
        }
        return;
      }
      await _audioRecorder.start(const RecordConfig(), path: '');
      setState(() => _isRecording = true);
    }
  }

  // ── Stream AI response (shared by text, image, audio sends) ──

  Future<void> _streamAiResponse() async {
    final streamId = _uuid.v4();
    final streamMsg = TextStreamMessage(
      id: _uuid.v4(),
      authorId: _aiId,
      createdAt: DateTime.now().toUtc(),
      streamId: streamId,
      status: MessageStatus.sending,
    );
    await _chatController.insertMessage(streamMsg);

    String? thinkingMsgId;
    final buffer = StringBuffer();

    await for (final response in _chat!.generateChatResponseAsync()) {
      if (response is ThinkingResponse) {
        if (thinkingMsgId == null) {
          // Insert a custom "thinking" message.
          thinkingMsgId = _uuid.v4();
          final thinkMsg = CustomMessage(
            id: thinkingMsgId,
            authorId: _aiId,
            createdAt: DateTime.now().toUtc(),
            metadata: {'type': 'thinking', 'content': response.content},
          );
          await _chatController.insertMessage(thinkMsg);
        } else {
          // Update the thinking message with accumulated content.
          final existing = _chatController.messages
              .whereType<CustomMessage>()
              .where((m) => m.id == thinkingMsgId)
              .firstOrNull;
          if (existing != null) {
            final prev = (existing.metadata?['content'] as String?) ?? '';
            await _chatController.updateMessage(
              existing,
              existing.copyWith(
                metadata: {
                  'type': 'thinking',
                  'content': prev + response.content,
                },
              ),
            );
          }
        }
      } else if (response is TextResponse) {
        // Remove thinking message when text starts arriving.
        if (thinkingMsgId != null) {
          final thinkMsg = _chatController.messages
              .whereType<CustomMessage>()
              .where((m) => m.id == thinkingMsgId)
              .firstOrNull;
          if (thinkMsg != null) {
            await _chatController.removeMessage(thinkMsg);
          }
          thinkingMsgId = null;
        }

        buffer.write(response.token);
        _textStreamController.append(streamId, buffer.toString());
      }
    }

    // Finalize stream.
    _textStreamController.end(streamId);
    await _chatController.updateMessage(
      streamMsg,
      streamMsg.copyWith(
        status: MessageStatus.sent,
        sentAt: DateTime.now().toUtc(),
      ),
    );

    // Persist final response.
    final fullResponse = buffer.toString();
    if (fullResponse.isNotEmpty) {
      ref.read(chatRepositoryProvider.future).then(
            (repo) =>
                repo.addAssistantMessage(widget.conversationId, fullResponse),
          );
    }
  }

  // ── Auto-name conversation ──

  Future<void> _autoNameIfNeeded(String firstUserMessage) async {
    final conversations =
        ref.read(conversationsProvider).valueOrNull ?? [];
    final conv = conversations
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    if (conv == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    if (conv.title != l10n.chatNewConversation) return;

    try {
      final pref = await ref.read(chatBackendPreferenceProvider.future);
      final backend = pref == ChatBackendPreference.gpu
          ? PreferredBackend.gpu
          : PreferredBackend.cpu;
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 64,
        preferredBackend: backend,
      );
      final session = await model.createSession(temperature: 0.3, topK: 1);
      await session.addQueryChunk(Message.text(
        text:
            'Summarize this conversation in 3-5 words as a title. Reply with ONLY the title, nothing else: $firstUserMessage',
        isUser: true,
      ));
      final title = await session.getResponse();
      await session.close();

      final cleaned =
          title.trim().replaceAll(RegExp('["\' ]+\$|^["\' ]+'), '');
      if (cleaned.isNotEmpty) {
        await ref
            .read(conversationsProvider.notifier)
            .rename(widget.conversationId, cleaned);
      }
    } catch (_) {
      // Title generation is best-effort; ignore failures.
    }
  }

  // ── AI info dialog ──

  Future<void> _showAiInfoDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final model = await ref.read(chatModelPreferenceProvider.future);
    final backend = await ref.read(chatBackendPreferenceProvider.future);

    if (!mounted) return;

    final modelLabel = switch (model) {
      ChatModelPreference.gemma4E2B => l10n.settingsModelOptionE2B,
      ChatModelPreference.gemma4E4B => l10n.settingsModelOptionE4B,
    };
    final backendLabel = switch (backend) {
      ChatBackendPreference.gpu => l10n.settingsBackendOptionGpu,
      ChatBackendPreference.cpu => l10n.settingsBackendOptionCpu,
    };

    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.chatAiInfoTitle),
        children: [
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(l10n.chatAiInfoModel),
            subtitle: Text(modelLabel),
          ),
          ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: Text(l10n.chatAiInfoAccelerator),
            subtitle: Text(backendLabel),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.chatAiInfoClose),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Attachment bottom sheet ──

  void _showAttachmentSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.chatAttachPhoto),
              onTap: () {
                Navigator.of(ctx).pop();
                _handleImageSend(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chatAttachGallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _handleImageSend(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: Text(l10n.chatAttachAudio),
              onTap: () {
                Navigator.of(ctx).pop();
                _toggleRecording();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──

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

    final l10n = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);
    final title = conversationsAsync.valueOrNull
            ?.where((c) => c.id == widget.conversationId)
            .firstOrNull
            ?.title ??
        '';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_isRecording)
            IconButton(
              icon: const Icon(Icons.stop_circle, color: Colors.red),
              onPressed: _toggleRecording,
              tooltip: l10n.chatRecordingInProgress,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAiInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_chatError != null)
            MaterialBanner(
              content: Text(
                l10n.chatModelErrorBanner(_chatError!),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                TextButton(
                  onPressed: _createChat,
                  child: Text(l10n.chatModelErrorRetry),
                ),
              ],
            ),
          Expanded(
            child: Chat(
              chatController: _chatController,
              currentUserId: _userId,
              theme: ChatTheme.fromThemeData(Theme.of(context)),
              builders: Builders(
                textStreamMessageBuilder: (context, message, index,
                    {required isSentByMe, groupStatus}) {
                  return FlyerChatTextStreamMessage(
                    message: message,
                    index: index,
                    textStreamController: _textStreamController,
                    mode: TextStreamMessageMode.animatedOpacity,
                  );
                },
                customMessageBuilder: (context, message, index,
                    {required isSentByMe, groupStatus}) {
                  final metadata = message.metadata ?? {};
                  if (metadata['type'] == 'thinking') {
                    return _ThinkingBubble(
                      content: (metadata['content'] as String?) ?? '',
                      label: l10n.chatThinkingLabel,
                    );
                  }
                  return const SizedBox.shrink();
                },
                composerBuilder: (context, {required sendButtonVisibilityMode}) {
                  return null;
                },
              ),
              onMessageSend: _handleSend,
              topBar: _isRecording
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fiber_manual_record,
                              color: Colors.red, size: 12),
                          const SizedBox(width: 8),
                          Text(l10n.chatRecordingInProgress),
                        ],
                      ),
                    )
                  : null,
              resolveUser: (userId) async {
                if (userId == _aiId) {
                  return User(id: _aiId, name: 'CookMate');
                }
                return User(id: userId, name: 'You');
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (!_isGenerating && _chat != null && !_isRecording)
          ? FloatingActionButton.small(
              onPressed: _showAttachmentSheet,
              child: const Icon(Icons.attach_file),
            )
          : null,
    );
  }
}

// ── Thinking bubble (replaces the old ThinkingBubble widget) ──

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.content, required this.label});

  final String content;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(150),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(180),
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              content,
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(150),
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Run the build to verify compilation**

Run: `flutter build apk --debug 2>&1 | tail -20`
Expected: BUILD SUCCESSFUL (or only warnings, no errors).

- [ ] **Step 4: Commit**

```
feat(chat): replace custom UI with flutter_chat_ui, add image and audio input
```

---

### Task 8: Clean up empty widgets directory

**Files:**
- Delete: `lib/features/chat/presentation/widgets/` (directory should be empty after Task 7)

- [ ] **Step 1: Remove the empty widgets directory**

Run: `rmdir lib/features/chat/presentation/widgets/`

If the directory is not empty (other files exist), leave it. Only remove if all 4 files were deleted in Task 7.

- [ ] **Step 2: Verify no broken imports**

Run: `flutter analyze 2>&1 | head -30`
Expected: No analysis issues (or only pre-existing ones).

- [ ] **Step 3: Commit**

```
chore(chat): remove empty widgets directory
```

---

### Task 9: Platform permissions for camera, microphone, and gallery

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Add Android permissions**

In `android/app/src/main/AndroidManifest.xml`, add inside `<manifest>` (before `<application>`):

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

Note: `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` are handled automatically by `image_picker` on modern Android.

- [ ] **Step 2: Add iOS permission descriptions**

In `ios/Runner/Info.plist`, add inside `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>CookMate needs camera access to take photos for recipe analysis.</string>
<key>NSMicrophoneUsageDescription</key>
<string>CookMate needs microphone access to record audio messages.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>CookMate needs photo library access to select images for recipe analysis.</string>
```

- [ ] **Step 3: Commit**

```
feat(platform): add camera, microphone, and photo library permissions
```

---

### Task 10: Final verification and adjustments

- [ ] **Step 1: Run full build**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Run existing tests**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 4: Fix any compilation or analysis issues found in steps 1-3**

If `composerBuilder` signature doesn't match the version installed, check `flutter_chat_ui` API and adjust. The Chat widget's composer can also be customized via `Composer` widget if needed — add an attachment icon button to the left of the text field.

If `TextStreamController` or `TextStreamMessage` classes have different names in the installed version, grep the package source:

Run: `find .dart_tool/package_config_subset -name "*.dart" | head` or check `flutter pub deps` output.

- [ ] **Step 5: Final commit**

```
fix(chat): resolve build and analysis issues from flutter_chat_ui migration
```
