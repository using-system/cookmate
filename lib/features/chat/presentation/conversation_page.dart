import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/chat_backend_preference.dart';
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
  String? _chatError;

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
      );

      // Replay stored history so InferenceChat has full context.
      final messages =
          await ref.read(messagesProvider(widget.conversationId).future);
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

  Future<void> _handleSend(String text) async {
    if (_isGenerating || _chat == null) return;

    setState(() {
      _isGenerating = true;
      _streamingContent = '';
    });

    try {
      // Persist user message to DB.
      await ref
          .read(messagesProvider(widget.conversationId).notifier)
          .addUserMessage(text);
      _scrollToBottom();

      // Send to InferenceChat and stream the response.
      await _chat!.addQueryChunk(Message.text(text: text, isUser: true));

      final buffer = StringBuffer();
      var lastUpdate = DateTime.now();
      const throttle = Duration(milliseconds: 50);

      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
          final now = DateTime.now();
          if (mounted && now.difference(lastUpdate) >= throttle) {
            lastUpdate = now;
            setState(() => _streamingContent = buffer.toString());
            _scrollToBottom();
          }
        }
      }

      // Final flush.
      if (mounted) {
        setState(() => _streamingContent = buffer.toString());
        _scrollToBottom();
      }

      // Persist assistant response to DB.
      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        await ref
            .read(messagesProvider(widget.conversationId).notifier)
            .addAssistantMessage(fullResponse);
      }

      // Auto-name if conversation still has the default title.
      if (mounted) {
        await _autoNameIfNeeded(text);
      }
    } catch (e, stack) {
      debugPrint('Send failed: $e\n$stack');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _streamingContent = '';
        });
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

    // Use a separate short-lived session to avoid polluting the chat context.
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

  bool _scrollScheduled = false;

  void _scrollToBottom() {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
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

    final l10n = AppLocalizations.of(context);
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
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('$error')),
              data: (messages) {
                final totalItems =
                    messages.length + (_isGenerating ? 1 : 0);
                if (totalItems == 0) {
                  return const SizedBox.shrink();
                }
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
            enabled: !_isGenerating && _chat != null,
          ),
        ],
      ),
    );
  }
}
