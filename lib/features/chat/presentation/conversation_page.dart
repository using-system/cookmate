import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_backend_preference.dart';
import '../domain/chat_message.dart';
import '../domain/chat_model_preference.dart';
import '../providers.dart';
import 'model_download_page.dart';
import 'widgets/chat_input_bar.dart';
import 'widgets/chat_list_widget.dart';

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final List<ChatMessage> _messages = [];
  InferenceChat? _chat;
  bool _isGenerating = false;
  bool _isThinking = false;
  String _thinkingContent = '';
  bool _modelReady = false;
  String? _chatError;

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

  Future<void> _loadMessages() async {
    final repo = await ref.read(chatRepositoryProvider.future);
    final messages = await repo.getMessages(widget.conversationId);
    if (mounted) {
      setState(() => _messages.addAll(messages));
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
      );

      // Replay stored history so InferenceChat has full context.
      for (final msg in _messages) {
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

  Future<void> _handleSend(String text) async {
    if (_isGenerating || _chat == null) return;

    setState(() => _isGenerating = true);

    try {
      // Add user message to display list.
      final userMsg = ChatMessage(
        id: '',
        conversationId: widget.conversationId,
        role: 'user',
        content: text,
        createdAt: DateTime.now(),
      );
      setState(() => _messages.add(userMsg));

      // Persist user message (fire-and-forget).
      ref.read(chatRepositoryProvider.future).then(
            (repo) => repo.addUserMessage(widget.conversationId, text),
          );

      // Send to InferenceChat.
      await _chat!.addQueryChunk(Message.text(text: text, isUser: true));

      // Add placeholder assistant message.
      final assistantMsg = ChatMessage(
        id: '',
        conversationId: widget.conversationId,
        role: 'assistant',
        content: '',
        createdAt: DateTime.now(),
      );
      setState(() => _messages.add(assistantMsg));

      // Stream the response.
      final buffer = StringBuffer();
      var lastUpdate = DateTime.now();
      const throttle = Duration(milliseconds: 50);
      var receivedText = false;

      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is ThinkingResponse) {
          setState(() {
            _isThinking = true;
            _thinkingContent += response.content;
          });
        } else if (response is TextResponse) {
          if (!receivedText) {
            receivedText = true;
            // Clear thinking as text starts.
            setState(() {
              _isThinking = false;
              _thinkingContent = '';
            });
          }
          buffer.write(response.token);
          final now = DateTime.now();
          if (mounted && now.difference(lastUpdate) >= throttle) {
            lastUpdate = now;
            setState(() {
              _messages.last = ChatMessage(
                id: assistantMsg.id,
                conversationId: assistantMsg.conversationId,
                role: 'assistant',
                content: buffer.toString(),
                createdAt: assistantMsg.createdAt,
              );
            });
          }
        }
      }

      // Final flush.
      final fullResponse = buffer.toString();
      if (mounted && fullResponse.isNotEmpty) {
        setState(() {
          _messages.last = ChatMessage(
            id: assistantMsg.id,
            conversationId: assistantMsg.conversationId,
            role: 'assistant',
            content: fullResponse,
            createdAt: assistantMsg.createdAt,
          );
        });

        // Persist assistant message (fire-and-forget).
        ref.read(chatRepositoryProvider.future).then(
              (repo) =>
                  repo.addAssistantMessage(widget.conversationId, fullResponse),
            );
      }

      // Clear thinking in case stream ended during thinking phase.
      if (mounted) {
        setState(() {
          _isThinking = false;
          _thinkingContent = '';
        });
      }

      // Auto-name if conversation still has the default title.
      if (mounted) {
        await _autoNameIfNeeded(text);
      }
    } catch (e, stack) {
      debugPrint('Send failed: $e\n$stack');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

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
            child: ChatListWidget(
              messages: _messages,
              isThinking: _isThinking,
              thinkingContent: _thinkingContent,
            ),
          ),
          ChatInputBar(
            onSubmit: _handleSend,
            enabled: !_isGenerating && _chat != null,
          ),
        ],
      ),
    );
  }
}
