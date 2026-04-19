import 'dart:io';

import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide Message;
import 'package:flutter_gemma/core/message.dart' as gemma;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../domain/chat_backend_preference.dart';
import '../domain/chat_message.dart' as domain;
import '../domain/chat_model_preference.dart';
import '../providers.dart';
import 'model_download_page.dart';

const _uuid = Uuid();

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final InMemoryChatController _chatController = InMemoryChatController();
  final Map<String, StreamState> _streamStates = {};
  InferenceChat? _chat;
  bool _isGenerating = false;
  bool _modelReady = false;
  String? _chatError;
  bool _isRecording = false;
  AudioRecorder? _audioRecorder;

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
    // Close the native Gemma session so the next conversation gets a fresh one.
    // Without this, createSession() returns the cached singleton and the new
    // conversation inherits the previous conversation's context.
    _chat?.close();
    _chatController.dispose();
    _audioRecorder?.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final repo = await ref.read(chatRepositoryProvider.future);
    final messages = await repo.getMessages(widget.conversationId);
    if (!mounted) return;
    for (final msg in messages) {
      final flyerMsg = _domainToFlyer(msg);
      await _chatController.insertMessage(flyerMsg);
    }
  }

  Message _domainToFlyer(domain.ChatMessage msg) {
    final id = msg.id.isEmpty ? _uuid.v4() : msg.id;
    final authorId = msg.role == 'user' ? 'user' : 'assistant';
    final createdAt = msg.createdAt;

    switch (msg.type) {
      case 'image':
        return Message.image(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          sentAt: createdAt,
          source: msg.mediaPath ?? '',
          text: msg.content.isNotEmpty ? msg.content : null,
        );
      case 'audio':
        return Message.audio(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          sentAt: createdAt,
          source: msg.mediaPath ?? '',
          duration: Duration.zero,
        );
      default:
        return Message.text(
          id: id,
          authorId: authorId,
          createdAt: createdAt,
          sentAt: createdAt,
          text: msg.content,
        );
    }
  }

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

  bool _visionAvailable = false;

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

      // Try with vision first; fall back without if the platform lacks
      // LlmVisionInferenceCalculator (e.g. iOS simulator).
      // On physical iOS devices vision works fine.
      var vision = true;
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
        vision = false;
        // Vision failed — close the model again and retry without it.
        final staleModel = FlutterGemmaPlugin.instance.initializedModel;
        await staleModel?.close();

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
      _visionAvailable = vision;

      // Replay stored history so InferenceChat has full context.
      final repo = await ref.read(chatRepositoryProvider.future);
      final messages = await repo.getMessages(widget.conversationId);
      for (final msg in messages) {
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

  void _handleSend(String text) {
    if (_isGenerating || _chat == null) return;
    setState(() => _isGenerating = true);
    _doSendText(text);
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

      // Auto-name if conversation still has the default title.
      // _autoNameIfNeeded calls getActiveModel(maxTokens: 64) which
      // reinitializes the native engine and invalidates our session.
      // We must recreate _chat afterwards.
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

  Future<void> _handleImageSend(ImageSource source) async {
    if (!_visionAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).chatVisionUnavailable)),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked == null || !mounted) return;
    if (_isGenerating || _chat == null) return;

    setState(() => _isGenerating = true);

    try {
      final filePath = picked.path;
      final imageBytes = await File(filePath).readAsBytes();
      final msgId = _uuid.v4();
      final now = DateTime.now();

      final imageMsg = Message.image(
        id: msgId,
        authorId: 'user',
        createdAt: now,
        sentAt: now,
        source: filePath,
      );
      await _chatController.insertMessage(imageMsg);

      final l10n = AppLocalizations.of(context);

      // Persist (fire-and-forget).
      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addImageMessage(
                widget.conversationId, l10n.chatImageCaption, filePath),
          );

      // Send to InferenceChat with image.
      await _chat!.addQueryChunk(
        gemma.Message.withImage(
          text: l10n.chatImagePrompt,
          imageBytes: imageBytes,
          isUser: true,
        ),
      );

      await _streamAiResponse();

      if (mounted) {
        final needsRename = await _autoNameIfNeeded(l10n.chatImageCaption);
        if (needsRename) await _createChat();
      }
    } catch (e, stack) {
      debugPrint('Image send failed: $e\n$stack');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording.
      final path = await _audioRecorder?.stop();
      setState(() => _isRecording = false);

      if (path == null || !mounted || _isGenerating || _chat == null) return;

      setState(() => _isGenerating = true);

      try {
        final audioBytes = await File(path).readAsBytes();
        final msgId = _uuid.v4();
        final now = DateTime.now();

        final audioMsg = Message.audio(
          id: msgId,
          authorId: 'user',
          createdAt: now,
          sentAt: now,
          source: path,
          duration: Duration.zero,
        );
        await _chatController.insertMessage(audioMsg);

        // Persist (fire-and-forget).
        ref.read(chatRepositoryProvider.future).then(
              (repo) => repo.addAudioMessage(widget.conversationId, path),
            );

        // Send to InferenceChat with audio.
        final l10n = AppLocalizations.of(context);
        await _chat!.addQueryChunk(
          gemma.Message.withAudio(
            text: l10n.chatAudioPrompt,
            audioBytes: audioBytes,
            isUser: true,
          ),
        );

        await _streamAiResponse();

        if (mounted) {
          final needsRename = await _autoNameIfNeeded(l10n.chatAudioCaption);
          if (needsRename) await _createChat();
        }
      } catch (e, stack) {
        debugPrint('Audio send failed: $e\n$stack');
      } finally {
        if (mounted) {
          setState(() => _isGenerating = false);
        }
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
          '${audioDir.path}/cookmate_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder!.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _streamAiResponse() async {
    final streamId = _uuid.v4();
    final streamMsgId = _uuid.v4();
    final now = DateTime.now();

    final streamMsg = Message.textStream(
      id: streamMsgId,
      authorId: 'assistant',
      createdAt: now,
      streamId: streamId,
    );

    _streamStates[streamId] = const StreamStateLoading();
    await _chatController.insertMessage(streamMsg);
    if (mounted) setState(() {});

    final buffer = StringBuffer();
    String? thinkingMsgId;
    var lastUpdate = DateTime.now();
    const throttle = Duration(milliseconds: 50);

    try {
      await for (final response in _chat!.generateChatResponseAsync()) {
        if (!mounted) break;

        if (response is ThinkingResponse) {
          if (thinkingMsgId == null) {
            thinkingMsgId = _uuid.v4();
            final thinkingMsg = Message.custom(
              id: thinkingMsgId,
              authorId: 'assistant',
              createdAt: now,
              metadata: {'type': 'thinking', 'content': response.content},
            );
            await _chatController.insertMessage(thinkingMsg);
          } else {
            // Update existing thinking message.
            final existingMsg = _chatController.messages
                .where((m) => m.id == thinkingMsgId)
                .firstOrNull;
            if (existingMsg != null && existingMsg is CustomMessage) {
              final existingContent =
                  (existingMsg.metadata?['content'] as String?) ?? '';
              final updatedMsg = Message.custom(
                id: thinkingMsgId,
                authorId: 'assistant',
                createdAt: now,
                metadata: {
                  'type': 'thinking',
                  'content': existingContent + response.content,
                },
              );
              await _chatController.updateMessage(existingMsg, updatedMsg);
            }
          }
        } else if (response is TextResponse) {
          // Remove thinking message if present.
          if (thinkingMsgId != null) {
            final thinkingMsg = _chatController.messages
                .where((m) => m.id == thinkingMsgId)
                .firstOrNull;
            if (thinkingMsg != null) {
              await _chatController.removeMessage(thinkingMsg);
            }
            thinkingMsgId = null;
          }

          buffer.write(response.token);
          final elapsed = DateTime.now().difference(lastUpdate);
          if (mounted && elapsed >= throttle) {
            lastUpdate = DateTime.now();
            _streamStates[streamId] =
                StreamStateStreaming(buffer.toString());
            setState(() {});
          }
        }
      }
    } catch (e, stack) {
      debugPrint('Stream error: $e\n$stack');
      if (mounted) {
        _streamStates[streamId] =
            StreamStateError(e, accumulatedText: buffer.toString());
        setState(() {});
      }
    }

    // Clean up thinking message if stream ended during thinking phase.
    if (thinkingMsgId != null && mounted) {
      final thinkingMsg = _chatController.messages
          .where((m) => m.id == thinkingMsgId)
          .firstOrNull;
      if (thinkingMsg != null) {
        await _chatController.removeMessage(thinkingMsg);
      }
    }

    // Final flush.
    final fullResponse = buffer.toString();
    if (mounted && fullResponse.isNotEmpty) {
      _streamStates[streamId] = StreamStateCompleted(fullResponse);

      // Update message status to sent.
      final currentMsg = _chatController.messages
          .where((m) => m.id == streamMsgId)
          .firstOrNull;
      if (currentMsg != null) {
        final updatedMsg = Message.textStream(
          id: streamMsgId,
          authorId: 'assistant',
          createdAt: now,
          sentAt: DateTime.now(),
          streamId: streamId,
        );
        await _chatController.updateMessage(currentMsg, updatedMsg);
      }

      setState(() {});

      // Persist assistant message (fire-and-forget).
      ref.read(chatRepositoryProvider.future).then(
            (repo) =>
                repo.addAssistantMessage(widget.conversationId, fullResponse),
          );
    }

    // Clean up stream state to avoid unbounded memory growth.
    _streamStates.remove(streamId);
  }

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

  /// Returns `true` if it called [FlutterGemma.getActiveModel] (which
  /// reinitializes the native engine and invalidates existing sessions).
  Future<bool> _autoNameIfNeeded(String firstUserMessage) async {
    final conversations =
        ref.read(conversationsProvider).valueOrNull ?? [];
    final conv = conversations
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    if (conv == null || !mounted) return false;

    final l10n = AppLocalizations.of(context);
    if (conv.title != l10n.chatNewConversation) return false;

    var calledGetActiveModel = false;
    try {
      final pref = await ref.read(chatBackendPreferenceProvider.future);
      final backend = pref == ChatBackendPreference.gpu
          ? PreferredBackend.gpu
          : PreferredBackend.cpu;
      calledGetActiveModel = true;
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 64,
        preferredBackend: backend,
      );
      final session = await model.createSession(temperature: 0.3, topK: 1);
      await session.addQueryChunk(gemma.Message.text(
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
    return calledGetActiveModel;
  }

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

  Future<User?> _resolveUser(String id) async {
    if (id == 'assistant') {
      return const User(id: 'assistant', name: 'CookMate');
    }
    final l10n = AppLocalizations.of(context);
    return User(id: 'user', name: l10n.chatUserDisplayName);
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
          if (_isRecording)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    color: Theme.of(context).colorScheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.chatRecordingInProgress,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Chat(
              chatController: _chatController,
              currentUserId: 'user',
              resolveUser: _resolveUser,
              theme: ChatTheme.fromThemeData(Theme.of(context)),
              onMessageSend: _handleSend,
              onAttachmentTap: _showAttachmentSheet,
              builders: Builders(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
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
            l10n.chatThinkingLabel,
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
