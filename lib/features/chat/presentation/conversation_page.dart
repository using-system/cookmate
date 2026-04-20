import 'dart:async';
import 'dart:io';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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

import 'package:flutter_gemma/core/model_response.dart';
import 'package:flutter_gemma/core/tool.dart';
import '../../skills/providers.dart';
import '../../tools/providers.dart';
import '../domain/chat_backend_preference.dart';
import '../domain/title_generator.dart';
import '../domain/chat_message.dart' as domain;
import '../domain/chat_model_preference.dart';
import '../providers.dart';
import '../../recipe/domain/recipe_level.dart';
import '../../recipe/domain/system_prompt_builder.dart';
import '../../recipe/domain/tm_version.dart';
import '../../recipe/domain/unit_system.dart';
import '../../recipe/providers.dart';
import 'model_download_page.dart';
import 'stream_state_store.dart';

const _uuid = Uuid();

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final InMemoryChatController _chatController = InMemoryChatController();
  final StreamStateStore _streamStates = StreamStateStore();
  InferenceChat? _chat;
  bool _isGenerating = false;
  bool _modelReady = false;
  String? _chatError;
  bool _isRecording = false;
  AudioRecorder? _audioRecorder;
  String? _pendingAudioPath;
  String? _pendingImagePath;

  static const _languageNames = {
    'fr': 'Français',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
  };

  void _clearPendingAudio() {
    final path = _pendingAudioPath;
    if (path != null) {
      File(path).delete().catchError((_) => File(path));
    }
    setState(() {
      _pendingAudioPath = null;
    });
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImagePath = null;
    });
  }

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
    _streamStates.dispose();
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

  Future<void> _createChat() async {
    try {
      final pref = await ref.read(chatBackendPreferenceProvider.future);
      final reasoning =
          await ref.read(chatReasoningPreferenceProvider.future);
      final expertConfig =
          await ref.read(chatExpertConfigProvider.future);
      final recipeConfig =
          await ref.read(recipeConfigProvider.future);
      final skillRegistry = await ref.read(skillRegistryProvider.future);
      final toolRegistry = ref.read(toolRegistryProvider);
      final backend = pref == ChatBackendPreference.gpu
          ? PreferredBackend.gpu
          : PreferredBackend.cpu;

      final languageCode = mounted
          ? Localizations.localeOf(context).languageCode
          : 'en';
      final languageName = _languageNames[languageCode] ?? languageCode;
      final systemPrompt = buildSystemPrompt(
        config: recipeConfig,
        language: languageName,
        skillInstructions: skillRegistry.buildSystemInstructions(),
      );
      final tools = toolRegistry.tools;

      await _chat?.close();
      _chat = null;

      final existingModel = FlutterGemmaPlugin.instance.initializedModel;
      await existingModel?.close();

      // Try with vision + audio, then vision only, then text only.
      final configs = [
        (supportImage: true, supportAudio: true),
        (supportImage: true, supportAudio: false),
        (supportImage: false, supportAudio: false),
      ];
      for (final cfg in configs) {
        try {
          final model = await FlutterGemma.getActiveModel(
            maxTokens: expertConfig.maxTokens,
            preferredBackend: backend,
            supportImage: cfg.supportImage,
            supportAudio: cfg.supportAudio,
          );
          _chat = await model.createChat(
            temperature: expertConfig.temperature,
            topK: expertConfig.topK,
            topP: expertConfig.topP,
            systemInstruction: systemPrompt,
            isThinking: reasoning,
            supportImage: cfg.supportImage,
            supportAudio: cfg.supportAudio,
            tools: tools,
            supportsFunctionCalls: toolRegistry.hasTools,
            toolChoice: ToolChoice.auto,
          );
          break;
        } catch (_) {
          final staleModel = FlutterGemmaPlugin.instance.initializedModel;
          await staleModel?.close();
        }
      }

      if (mounted) {
        setState(() => _chatError = null);
      }

      final repo = await ref.read(chatRepositoryProvider.future);
      final messages = await repo.getMessages(widget.conversationId);
      for (final msg in messages) {
        if (msg.content.isEmpty) continue;
        await _chat!.addQueryChunk(
          gemma.Message.text(text: msg.content, isUser: msg.role == 'user'),
        );
      }
    } catch (e, stack) {
      debugPrint('Failed to create chat: $e\n$stack');
      if (mounted) {
        setState(() => _chatError = e.toString());
      }
    }
  }

  void _handleSend(String text) {
    if (_isGenerating) return;
    if (_chat == null) {
      final message = _chatError != null
          ? _chatError!
          : AppLocalizations.of(context).chatModelLoading;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      if (_chatError != null) {
        _createChat();
      }
      return;
    }
    setState(() => _isGenerating = true);

    if (_pendingAudioPath != null) {
      _doSendAudioWithText(text);
    } else if (_pendingImagePath != null) {
      _doSendImageWithText(text);
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
      _autoNameIfNeeded(text);

      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addUserMessage(widget.conversationId, text),
            onError: (e, s) => debugPrint('Persist failed: $e\n$s'),
          );

      await _chat!.addQueryChunk(gemma.Message.text(text: text, isUser: true));

      await _streamAiResponse();
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

    try {
      final audioBytes = await File(audioPath).readAsBytes();
      final msgId = _uuid.v4();
      final now = DateTime.now();

      final audioMsg = Message.audio(
        id: msgId,
        authorId: 'user',
        createdAt: now,
        sentAt: now,
        source: audioPath,
        duration: Duration.zero,
        text: text.trim().isNotEmpty ? text.trim() : null,
      );
      await _chatController.insertMessage(audioMsg);

      final l10n = AppLocalizations.of(context);
      _autoNameIfNeeded(
        text.trim().isNotEmpty ? text.trim() : l10n.chatAudioCaption,
      );

      // Clear the composer chip now that the message is visible in chat.
      setState(() => _pendingAudioPath = null);

      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addAudioMessage(widget.conversationId, audioPath),
            onError: (e, s) => debugPrint('Persist failed: $e\n$s'),
          );

      final prompt = text.trim().isNotEmpty ? text.trim() : l10n.chatAudioPrompt;

      await _chat!.addQueryChunk(
        gemma.Message.withAudio(
          text: prompt,
          audioBytes: audioBytes,
          isUser: true,
        ),
      );

      await _streamAiResponse();
    } catch (e, stack) {
      debugPrint('Audio send failed: $e\n$stack');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _handleImagePick(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).chatMediaPermissionDenied)),
        );
      }
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => _pendingImagePath = picked!.path);
  }

  Future<void> _doSendImageWithText(String text) async {
    final imagePath = _pendingImagePath!;

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final msgId = _uuid.v4();
      final now = DateTime.now();

      final imageMsg = Message.image(
        id: msgId,
        authorId: 'user',
        createdAt: now,
        sentAt: now,
        source: imagePath,
        text: text.trim().isNotEmpty ? text.trim() : null,
      );
      await _chatController.insertMessage(imageMsg);

      final l10n = AppLocalizations.of(context);
      _autoNameIfNeeded(
        text.trim().isNotEmpty ? text.trim() : l10n.chatImageCaption,
      );

      setState(() => _pendingImagePath = null);

      // Persist (fire-and-forget).
      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addImageMessage(
                widget.conversationId, l10n.chatImageCaption, imagePath),
            onError: (e, s) => debugPrint('Persist failed: $e\n$s'),
          );

      final prompt = text.trim().isNotEmpty ? text.trim() : l10n.chatImagePrompt;

      // Send to InferenceChat with image.
      await _chat!.addQueryChunk(
        gemma.Message.withImage(
          text: prompt,
          imageBytes: imageBytes,
          isUser: true,
        ),
      );

      await _streamAiResponse();
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
      final path = await _audioRecorder?.stop();
      setState(() => _isRecording = false);

      if (path == null || !mounted) return;

      setState(() => _pendingAudioPath = path);
    } else {
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

    _streamStates.set(streamId, const StreamStateLoading());
    await _chatController.insertMessage(streamMsg);

    final buffer = StringBuffer();
    String? thinkingMsgId;
    var lastUpdate = DateTime.now();
    const throttle = Duration(milliseconds: 50);

    // Repetition guard: break out of degenerate loops.
    String? _lastToken;
    int _repeatCount = 0;
    const _maxRepeat = 12;

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

          // Repetition guard.
          if (response.token == _lastToken) {
            _repeatCount++;
            if (_repeatCount >= _maxRepeat) {
              debugPrint('InferenceChat: repetition loop detected '
                  '("${response.token}" x $_repeatCount), stopping stream.');
              break;
            }
          } else {
            _lastToken = response.token;
            _repeatCount = 1;
          }

          buffer.write(response.token);
          final elapsed = DateTime.now().difference(lastUpdate);
          if (mounted && elapsed >= throttle) {
            lastUpdate = DateTime.now();
            _streamStates.set(
                streamId, StreamStateStreaming(buffer.toString()));
          }
        } else if (response is FunctionCallResponse) {
          if (mounted) {
            final toolReg = ref.read(toolRegistryProvider);
            await toolReg.handle(response, context);
          }
        } else if (response is ParallelFunctionCallResponse) {
          if (!mounted) continue;
          final toolReg = ref.read(toolRegistryProvider);
          for (final call in response.calls) {
            await toolReg.handle(call, context);
          }
        }
      }
    } catch (e, stack) {
      debugPrint('Stream error: $e\n$stack');
      if (mounted) {
        _streamStates.set(streamId,
            StreamStateError(e, accumulatedText: buffer.toString()));
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
      _streamStates.set(streamId, StreamStateCompleted(fullResponse));

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

      // Persist assistant message and refresh conversation order.
      ref.read(chatRepositoryProvider.future).then(
            (repo) =>
                repo.addAssistantMessage(widget.conversationId, fullResponse),
            onError: (e, s) => debugPrint('Persist failed: $e\n$s'),
          ).then((_) => ref.invalidate(conversationsProvider));
    }

    // Keep the final StreamState (completed/error) so the builder doesn't
    // fall back to StreamStateLoading on rebuilds.  The map is bounded by
    // the number of messages in the conversation which is already in memory.
  }

  void _showAttachmentSheet() {
    if (_isGenerating || _isRecording) return;
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(l10n.chatAttachPhoto),
              onTap: () {
                Navigator.of(ctx).pop();
                _handleImagePick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chatAttachGallery),
              onTap: () {
                Navigator.of(ctx).pop();
                _handleImagePick(ImageSource.gallery);
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

  void _autoNameIfNeeded(String firstUserMessage) {
    final conversations =
        ref.read(conversationsProvider).valueOrNull ?? [];
    final conv = conversations
        .where((c) => c.id == widget.conversationId)
        .firstOrNull;
    if (conv == null || !mounted) return;

    final l10n = AppLocalizations.of(context);
    if (conv.title != l10n.chatNewConversation) return;

    final title = generateTitle(firstUserMessage);
    if (title == null) return;

    ref
        .read(conversationsProvider.notifier)
        .rename(widget.conversationId, title);
  }

  Future<void> _showRenameDialog(BuildContext context, String currentTitle) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatRenameConversation),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.chatRenameHint),
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (newTitle != null && newTitle.isNotEmpty && newTitle != currentTitle) {
      await ref
          .read(conversationsProvider.notifier)
          .rename(widget.conversationId, newTitle);
    }
  }

  Future<void> _showAiInfoDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final model = await ref.read(chatModelPreferenceProvider.future);
    final backend = await ref.read(chatBackendPreferenceProvider.future);
    final reasoning = await ref.read(chatReasoningPreferenceProvider.future);
    final expertConfig = await ref.read(chatExpertConfigProvider.future);
    final recipeConfig = await ref.read(recipeConfigProvider.future);

    if (!mounted) return;

    final modelLabel = switch (model) {
      ChatModelPreference.gemma4E2B => l10n.settingsModelOptionE2B,
      ChatModelPreference.gemma4E4B => l10n.settingsModelOptionE4B,
    };
    final backendLabel = switch (backend) {
      ChatBackendPreference.gpu => l10n.settingsBackendOptionGpu,
      ChatBackendPreference.cpu => l10n.settingsBackendOptionCpu,
    };
    final reasoningLabel = reasoning
        ? l10n.settingsReasoningSubtitleOn
        : l10n.settingsReasoningSubtitleOff;

    final languageCode = Localizations.localeOf(context).languageCode;
    final languageLabel = _languageNames[languageCode] ?? languageCode;

    final tmLabel = switch (recipeConfig.tmVersion) {
      TmVersion.tm5 => l10n.settingsTmVersionOptionTm5,
      TmVersion.tm6 => l10n.settingsTmVersionOptionTm6,
      TmVersion.tm7 => l10n.settingsTmVersionOptionTm7,
    };
    final unitLabel = switch (recipeConfig.unitSystem) {
      UnitSystem.metric => l10n.settingsUnitSystemOptionMetric,
      UnitSystem.imperial => l10n.settingsUnitSystemOptionImperial,
    };
    final levelLabel = switch (recipeConfig.level) {
      RecipeLevel.beginner => l10n.settingsLevelOptionBeginner,
      RecipeLevel.intermediate => l10n.settingsLevelOptionIntermediate,
      RecipeLevel.advanced => l10n.settingsLevelOptionAdvanced,
      RecipeLevel.allLevels => l10n.settingsLevelOptionAllLevels,
    };

    await showDialog<void>(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                tabs: [
                  Tab(text: l10n.chatInfoTabRecipe),
                  Tab(text: l10n.chatInfoTabAi),
                ],
              ),
              SizedBox(
                height: 340,
                child: TabBarView(
                  children: [
                    ListView(
                      shrinkWrap: true,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.kitchen_outlined),
                          title: Text(l10n.chatRecipeInfoTmVersion),
                          subtitle: Text(tmLabel),
                        ),
                        ListTile(
                          leading: const Icon(Icons.straighten_outlined),
                          title: Text(l10n.chatRecipeInfoUnitSystem),
                          subtitle: Text(unitLabel),
                        ),
                        ListTile(
                          leading: const Icon(Icons.group_outlined),
                          title: Text(l10n.chatRecipeInfoPortions),
                          subtitle: Text(
                              l10n.settingsPortionsValue(recipeConfig.portions)),
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.signal_cellular_alt_outlined),
                          title: Text(l10n.chatRecipeInfoLevel),
                          subtitle: Text(levelLabel),
                        ),
                        ListTile(
                          leading: const Icon(Icons.no_food_outlined),
                          title: Text(l10n.chatRecipeInfoDietaryRestrictions),
                          subtitle: Text(recipeConfig.dietaryRestrictions.isEmpty
                              ? l10n.settingsDietaryRestrictionsNone
                              : recipeConfig.dietaryRestrictions),
                        ),
                        ListTile(
                          leading: const Icon(Icons.language),
                          title: Text(l10n.chatRecipeInfoLanguage),
                          subtitle: Text(languageLabel),
                        ),
                      ],
                    ),
                    ListView(
                      shrinkWrap: true,
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
                        ListTile(
                          leading: const Icon(Icons.psychology_outlined),
                          title: Text(l10n.chatAiInfoReasoning),
                          subtitle: Text(reasoningLabel),
                        ),
                        ListTile(
                          leading: const Icon(Icons.tune_outlined),
                          title: Text(l10n.chatAiInfoMaxTokens),
                          subtitle: Text(expertConfig.maxTokens.toString()),
                        ),
                        ListTile(
                          leading: const Icon(Icons.thermostat_outlined),
                          title: Text(l10n.chatAiInfoTemperature),
                          subtitle: Text(
                              expertConfig.temperature.toStringAsFixed(2)),
                        ),
                        ListTile(
                          leading: const Icon(Icons.filter_list_outlined),
                          title: Text(l10n.chatAiInfoTopK),
                          subtitle: Text(expertConfig.topK.toString()),
                        ),
                        ListTile(
                          leading: const Icon(Icons.donut_small_outlined),
                          title: Text(l10n.chatAiInfoTopP),
                          subtitle: Text(
                              expertConfig.topP.toStringAsFixed(2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ),
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
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showRenameDialog(context, title),
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
                composerBuilder: (context) {
                  final hasPending =
                      _pendingAudioPath != null || _pendingImagePath != null;
                  Widget? topWidget;
                  if (_pendingImagePath != null) {
                    topWidget = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_pendingImagePath!),
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              cacheWidth: 96,
                              cacheHeight: 96,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.chatImageAttached,
                              style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _clearPendingImage,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  } else if (_pendingAudioPath != null) {
                    topWidget = Container(
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
                          IconButton(
                            onPressed: _clearPendingAudio,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }
                  return Composer(
                    topWidget: topWidget,
                    sendButtonVisibilityMode: hasPending
                        ? SendButtonVisibilityMode.always
                        : SendButtonVisibilityMode.disabled,
                    allowEmptyMessage: hasPending,
                  );
                },
                imageMessageBuilder: (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  return _ImageBubble(
                    source: message.source,
                    text: message.text,
                    isSentByMe: isSentByMe,
                  );
                },
                audioMessageBuilder: (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  return _AudioBubble(
                    source: message.source,
                    text: message.text,
                    isSentByMe: isSentByMe,
                  );
                },
                chatAnimatedListBuilder: (context, itemBuilder) =>
                    ChatAnimatedListReversed(itemBuilder: itemBuilder),
                textStreamMessageBuilder: (
                  context,
                  message,
                  index, {
                  required bool isSentByMe,
                  MessageGroupStatus? groupStatus,
                }) {
                  return ValueListenableBuilder<StreamState>(
                    valueListenable: _streamStates.of(message.streamId),
                    builder: (context, state, _) {
                      return FlyerChatTextStreamMessage(
                        message: message,
                        index: index,
                        streamState: state,
                        mode: TextStreamMessageMode.animatedOpacity,
                        showTime: false,
                      );
                    },
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

class _ImageBubble extends StatelessWidget {
  const _ImageBubble({
    required this.source,
    this.text,
    required this.isSentByMe,
  });

  final String source;
  final String? text;
  final bool isSentByMe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSentByMe
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showFullScreen(context),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: Image.file(
                File(source),
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 600,
                errorBuilder: (_, e, s) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(Icons.broken_image, size: 48),
                ),
              ),
            ),
          ),
          if (text != null && text!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                text!,
                style: TextStyle(
                  color: isSentByMe
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(source)),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioBubble extends StatefulWidget {
  const _AudioBubble({
    required this.source,
    this.text,
    required this.isSentByMe,
  });

  final String source;
  final String? text;
  final bool isSentByMe;

  @override
  State<_AudioBubble> createState() => _AudioBubbleState();
}

class _AudioBubbleState extends State<_AudioBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  StreamSubscription<PlayerState>? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _playerSubscription = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_player.processingState == ProcessingState.completed ||
          _player.processingState == ProcessingState.idle) {
        await _player.setFilePath(widget.source);
      }
      await _player.play();
      setState(() => _isPlaying = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isSentByMe
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _togglePlayback,
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: widget.isSentByMe
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.graphic_eq,
                color: widget.isSentByMe
                    ? colorScheme.onPrimaryContainer.withAlpha(150)
                    : colorScheme.onSurfaceVariant.withAlpha(150),
              ),
            ],
          ),
          if (widget.text != null && widget.text!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.text!,
              style: TextStyle(
                color: widget.isSentByMe
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ],
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
