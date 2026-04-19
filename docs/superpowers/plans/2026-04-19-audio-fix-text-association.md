# Audio Fix & Text Association Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix audio so it is actually processed by the on-device model, and let users attach text to an audio recording before sending.

**Architecture:** Two independent fixes in `conversation_page.dart`. Fix 1 enables `supportAudio` on the model and switches recording to WAV 16kHz mono. Fix 2 decouples recording from sending: audio is stored as pending state, shown as a chip above the composer, and sent together with optional user text on tap of Send.

**Tech Stack:** Flutter, flutter_gemma (0.13.5), flutter_chat_ui (2.11.1), record (6.2.0), ARB l10n

---

### Task 1: Add l10n keys for audio chip

**Files:**
- Modify: `lib/l10n/app_en.arb:191` (after `chatAudioCaption`)
- Modify: `lib/l10n/app_fr.arb:61` (after `chatAudioCaption`)
- Modify: `lib/l10n/app_de.arb:61` (after `chatAudioCaption`)
- Modify: `lib/l10n/app_es.arb:61` (after `chatAudioCaption`)

- [ ] **Step 1: Add `chatAudioAttached` key to `app_en.arb`**

Insert after the `chatAudioCaption` entry (line 191):

```json
  "chatAudioAttached": "Audio attached",
  "@chatAudioAttached": { "description": "Label shown in the composer chip when an audio recording is pending." },
```

- [ ] **Step 2: Add `chatAudioAttached` key to `app_fr.arb`**

Insert after `chatAudioCaption` (line 61):

```json
  "chatAudioAttached": "Audio joint",
```

- [ ] **Step 3: Add `chatAudioAttached` key to `app_de.arb`**

Insert after `chatAudioCaption` (line 61):

```json
  "chatAudioAttached": "Audio angehängt",
```

- [ ] **Step 4: Add `chatAudioAttached` key to `app_es.arb`**

Insert after `chatAudioCaption` (line 61):

```json
  "chatAudioAttached": "Audio adjunto",
```

- [ ] **Step 5: Run l10n code generation**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter gen-l10n`
Expected: Generates updated `app_localizations.dart` with `chatAudioAttached` getter.

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/
git commit -m "feat(l10n): add chatAudioAttached key for audio chip label"
```

---

### Task 2: Enable audio support in model initialization

**Files:**
- Modify: `lib/features/chat/presentation/conversation_page.dart:33-42` (state fields)
- Modify: `lib/features/chat/presentation/conversation_page.dart:127-202` (`_createChat`)
- Modify: `lib/features/chat/presentation/conversation_page.dart:547-584` (`_showAttachmentSheet`)

- [ ] **Step 1: Add `_audioAvailable` state field**

In `_ConversationPageState` (after line 41, the `_audioRecorder` field), add:

```dart
  bool _audioAvailable = false;
```

- [ ] **Step 2: Update `_createChat` to enable `supportAudio`**

Replace the entire `_createChat` method (lines 127-202) with this version that adds audio support with try/fallback, mirroring the vision pattern:

```dart
  Future<void> _createChat() async {
    try {
      final pref = await ref.read(chatBackendPreferenceProvider.future);
      final backend = pref == ChatBackendPreference.gpu
          ? PreferredBackend.gpu
          : PreferredBackend.cpu;

      // Close the previous chat session before replacing it, so the native
      // session doesn't leak resources or hold stale context.
      await _chat?.close();
      _chat = null;

      // Always close the existing model singleton before creating a new
      // one.  flutter_gemma caches the model by name and ignores parameter
      // changes (backend, maxTokens, supportImage).  Without this, switching
      // CPU↔GPU or toggling vision has no effect.
      final existingModel = FlutterGemmaPlugin.instance.initializedModel;
      await existingModel?.close();

      // Try with vision + audio first; fall back progressively if the
      // platform lacks support (e.g. iOS simulator for vision, or a model
      // that doesn't support audio).
      var vision = true;
      var audio = true;
      try {
        final model = await FlutterGemma.getActiveModel(
          maxTokens: 2048,
          preferredBackend: backend,
          supportImage: true,
          supportAudio: true,
        );
        _chat = await model.createChat(
          temperature: 0.8,
          topK: 40,
          systemInstruction: _systemPrompt,
          isThinking: true,
          supportImage: true,
          supportAudio: true,
        );
      } catch (_) {
        // Vision+audio failed — try vision only.
        audio = false;
        final staleModel = FlutterGemmaPlugin.instance.initializedModel;
        await staleModel?.close();

        try {
          final model = await FlutterGemma.getActiveModel(
            maxTokens: 2048,
            preferredBackend: backend,
            supportImage: true,
          );
          _chat = await model.createChat(
            temperature: 0.8,
            topK: 40,
            systemInstruction: _systemPrompt,
            isThinking: true,
            supportImage: true,
          );
        } catch (_) {
          // Vision also failed — fall back to text only.
          vision = false;
          final staleModel2 = FlutterGemmaPlugin.instance.initializedModel;
          await staleModel2?.close();

          final model = await FlutterGemma.getActiveModel(
            maxTokens: 2048,
            preferredBackend: backend,
          );
          _chat = await model.createChat(
            temperature: 0.8,
            topK: 40,
            systemInstruction: _systemPrompt,
            isThinking: true,
          );
        }
      }
      _visionAvailable = vision;
      _audioAvailable = audio;

      // Replay stored history so InferenceChat has full context.
      // Skip audio messages (empty content) to avoid replaying blank turns.
      final repo = await ref.read(chatRepositoryProvider.future);
      final messages = await repo.getMessages(widget.conversationId);
      for (final msg in messages) {
        if (msg.content.isEmpty) continue;
        await _chat!.addQueryChunk(
          gemma.Message.text(text: msg.content, isUser: msg.role == 'user'),
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
```

- [ ] **Step 3: Conditionally show audio option in attachment sheet**

In `_showAttachmentSheet` (lines 547-584), wrap the audio `ListTile` with an `if (_audioAvailable)` guard. Replace the audio ListTile block (lines 572-579) with:

```dart
            if (_audioAvailable)
              ListTile(
                leading: const Icon(Icons.mic),
                title: Text(l10n.chatAttachAudio),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _toggleRecording();
                },
              ),
```

- [ ] **Step 4: Verify the app builds**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter build apk --debug 2>&1 | tail -5`
Expected: BUILD SUCCESSFUL

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/presentation/conversation_page.dart
git commit -m "fix(chat): enable supportAudio in model initialization with fallback"
```

---

### Task 3: Switch audio recording to WAV 16kHz mono

**Files:**
- Modify: `lib/features/chat/presentation/conversation_page.dart:388-415` (`_toggleRecording`, start-recording branch)

- [ ] **Step 1: Update recording config and file extension**

In the else branch of `_toggleRecording` (the "Start recording" path, lines 388-414), replace:

```dart
      final path =
          '${audioDir.path}/cookmate_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder!.start(const RecordConfig(), path: path);
```

with:

```dart
      final path =
          '${audioDir.path}/cookmate_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
```

- [ ] **Step 2: Verify the app builds**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter build apk --debug 2>&1 | tail -5`
Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/presentation/conversation_page.dart
git commit -m "fix(chat): record audio as WAV 16kHz mono for flutter_gemma compatibility"
```

---

### Task 4: Decouple audio recording from sending (pending audio state)

**Files:**
- Modify: `lib/features/chat/presentation/conversation_page.dart:1` (add `dart:typed_data` import)
- Modify: `lib/features/chat/presentation/conversation_page.dart:33-42` (add state fields)
- Modify: `lib/features/chat/presentation/conversation_page.dart:335-415` (rewrite `_toggleRecording`)
- Modify: `lib/features/chat/presentation/conversation_page.dart:204-252` (update `_handleSend` / `_doSendText`)

- [ ] **Step 1: Add `dart:typed_data` import**

At the top of the file (after `import 'dart:io';`), add:

```dart
import 'dart:typed_data';
```

- [ ] **Step 2: Add pending audio state fields**

In `_ConversationPageState` (after the `_audioAvailable` field added in Task 2), add:

```dart
  String? _pendingAudioPath;
  Uint8List? _pendingAudioBytes;
```

- [ ] **Step 3: Add `_clearPendingAudio` helper**

After the pending audio fields, add:

```dart
  void _clearPendingAudio() {
    setState(() {
      _pendingAudioPath = null;
      _pendingAudioBytes = null;
    });
  }
```

- [ ] **Step 4: Rewrite `_toggleRecording` to store audio as pending**

Replace the entire `_toggleRecording` method with this version that stores audio as pending instead of sending immediately:

```dart
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording — store audio as pending, don't send yet.
      final path = await _audioRecorder?.stop();
      setState(() => _isRecording = false);

      if (path == null || !mounted) return;

      try {
        final audioBytes = await File(path).readAsBytes();
        setState(() {
          _pendingAudioPath = path;
          _pendingAudioBytes = audioBytes;
        });
      } catch (e, stack) {
        debugPrint('Failed to read recorded audio: $e\n$stack');
      }
    } else {
      // Start recording.
      _audioRecorder ??= AudioRecorder();
      final hasPermission = await _audioRecorder!.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)
                    .chatMediaPermissionDenied)),
          );
        }
        return;
      }
      if (!mounted) return;

      // Save to app documents dir (not temp) so persisted mediaPath survives
      // OS temp cleanup across app restarts.
      final docsDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${docsDir.path}/audio');
      if (!audioDir.existsSync()) audioDir.createSync(recursive: true);
      final path =
          '${audioDir.path}/cookmate_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder!.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      setState(() => _isRecording = true);
    }
  }
```

- [ ] **Step 5: Update `_handleSend` to handle pending audio**

Replace the `_handleSend` method and `_doSendText` method (lines 204-252) with a unified version that handles both text-only and text+audio:

```dart
  void _handleSend(String text) {
    if (_isGenerating || _chat == null) return;
    setState(() => _isGenerating = true);

    if (_pendingAudioBytes != null) {
      _doSendAudioWithText(text);
    } else {
      if (text.trim().isEmpty) {
        setState(() => _isGenerating = false);
        return;
      }
      _doSendText(text);
    }
  }

  Future<void> _doSendText(String text) async {
    try {
      final msgId = _uuid.v4();
      final now = DateTime.now();
      final userMsg = Message.text(
        id: msgId,
        authorId: 'user',
        createdAt: now,
        sentAt: now,
        text: text,
      );
      await _chatController.insertMessage(userMsg);

      // Persist user message (fire-and-forget).
      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addUserMessage(widget.conversationId, text),
          );

      // Send to InferenceChat.
      await _chat!.addQueryChunk(gemma.Message.text(text: text, isUser: true));

      // Stream the AI response.
      await _streamAiResponse();

      if (mounted) {
        final needsRename = await _autoNameIfNeeded(text);
        if (needsRename) {
          await _createChat();
        }
      }
    } catch (e, stack) {
      debugPrint('Send failed: $e\n$stack');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _doSendAudioWithText(String text) async {
    final audioPath = _pendingAudioPath!;
    final audioBytes = _pendingAudioBytes!;
    _clearPendingAudio();

    try {
      final msgId = _uuid.v4();
      final now = DateTime.now();

      final audioMsg = Message.audio(
        id: msgId,
        authorId: 'user',
        createdAt: now,
        sentAt: now,
        source: audioPath,
        duration: Duration.zero,
      );
      await _chatController.insertMessage(audioMsg);

      // Persist (fire-and-forget).
      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addAudioMessage(widget.conversationId, audioPath),
          );

      // Use user text if provided, otherwise fall back to default audio prompt.
      final l10n = AppLocalizations.of(context);
      final prompt = text.trim().isNotEmpty ? text.trim() : l10n.chatAudioPrompt;

      // Send to InferenceChat with audio.
      await _chat!.addQueryChunk(
        gemma.Message.withAudio(
          text: prompt,
          audioBytes: audioBytes,
          isUser: true,
        ),
      );

      await _streamAiResponse();

      if (mounted) {
        final needsRename = await _autoNameIfNeeded(
          text.trim().isNotEmpty ? text.trim() : l10n.chatAudioCaption,
        );
        if (needsRename) await _createChat();
      }
    } catch (e, stack) {
      debugPrint('Audio send failed: $e\n$stack');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
```

- [ ] **Step 6: Verify the app builds**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter build apk --debug 2>&1 | tail -5`
Expected: BUILD SUCCESSFUL

- [ ] **Step 7: Commit**

```bash
git add lib/features/chat/presentation/conversation_page.dart
git commit -m "feat(chat): decouple audio recording from sending with pending state"
```

---

### Task 5: Add audio chip in composer and wire up UI

**Files:**
- Modify: `lib/features/chat/presentation/conversation_page.dart:758-804` (Chat widget / builders)

- [ ] **Step 1: Add `composerBuilder` to `Builders` in the `Chat` widget**

In the `build` method, add a `composerBuilder` to the `Builders(...)` constructor (inside the `Chat` widget, after the `customMessageBuilder`). Replace the `builders: Builders(` block (lines 766-802) with:

```dart
              builders: Builders(
                composerBuilder: (context) => Composer(
                  topWidget: _pendingAudioPath != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mic,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l10n.chatAudioAttached,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _clearPendingAudio,
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                  sendButtonVisibilityMode: _pendingAudioPath != null
                      ? SendButtonVisibilityMode.always
                      : SendButtonVisibilityMode.disabled,
                  allowEmptyMessage: _pendingAudioPath != null,
                ),
                chatAnimatedListBuilder: (context, itemBuilder) =>
                    ChatAnimatedListReversed(itemBuilder: itemBuilder),
                textStreamMessageBuilder: (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  final state =
                      _streamStates[message.streamId] ??
                      const StreamStateLoading();
                  return FlyerChatTextStreamMessage(
                    message: message,
                    index: index,
                    streamState: state,
                    mode: TextStreamMessageMode.animatedOpacity,
                    showTime: false,
                  );
                },
                customMessageBuilder: (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  if (message.metadata?['type'] == 'thinking') {
                    return _ThinkingBubble(
                      content:
                          (message.metadata?['content'] as String?) ?? '',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
```

- [ ] **Step 2: Verify the app builds**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter build apk --debug 2>&1 | tail -5`
Expected: BUILD SUCCESSFUL

- [ ] **Step 3: Commit**

```bash
git add lib/features/chat/presentation/conversation_page.dart
git commit -m "feat(chat): add audio chip in composer with text association"
```

---

### Task 6: Final verification

- [ ] **Step 1: Run full build**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter build apk --debug 2>&1 | tail -10`
Expected: BUILD SUCCESSFUL

- [ ] **Step 2: Run analyzer**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter analyze 2>&1 | tail -10`
Expected: No issues found

- [ ] **Step 3: Verify all l10n keys present in all locales**

Run: `cd /Users/usingsystem/Repos/github/cookmate && grep -l "chatAudioAttached" lib/l10n/*.arb | wc -l`
Expected: 4 (en, fr, de, es)
