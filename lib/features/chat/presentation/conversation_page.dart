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
  bool _isFirstExchange = true;
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

  PreferredBackend _resolveBackend() {
    final pref = ref.read(chatBackendPreferenceProvider).valueOrNull ??
        ChatBackendPreference.defaultBackend;
    return pref == ChatBackendPreference.gpu
        ? PreferredBackend.gpu
        : PreferredBackend.cpu;
  }

  Future<void> _createChat() async {
    try {
      final backend = _resolveBackend();
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 2048,
        preferredBackend: backend,
      );
      _chat = await model.createChat(
        temperature: 0.8,
        topK: 40,
        systemInstruction: _systemPrompt,
      );
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
    if (_isGenerating) return;

    // Always show the user message immediately.
    setState(() {
      _isGenerating = true;
      _streamingContent = '';
    });

    await ref
        .read(messagesProvider(widget.conversationId).notifier)
        .addUserMessage(text);
    _scrollToBottom();

    if (_chat == null) {
      // Model not loaded — save user message but can't generate a response.
      if (mounted) {
        setState(() => _isGenerating = false);
      }
      return;
    }

    try {
      await _chat!.addQueryChunk(Message.text(text: text, isUser: true));

      final buffer = StringBuffer();
      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          buffer.write(response.token);
          if (mounted) {
            setState(() => _streamingContent = buffer.toString());
            _scrollToBottom();
          }
        }
      }

      final fullResponse = buffer.toString();
      if (fullResponse.isNotEmpty) {
        await ref
            .read(messagesProvider(widget.conversationId).notifier)
            .addAssistantMessage(fullResponse);
      }

      if (_isFirstExchange) {
        _isFirstExchange = false;
        _autoName(text);
      }
    } catch (e, stack) {
      debugPrint('Inference failed: $e\n$stack');
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _streamingContent = '';
        });
      }
    }
  }

  Future<void> _autoName(String firstUserMessage) async {
    try {
      final backend = _resolveBackend();
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 64,
        preferredBackend: backend,
      );
      final session = await model.createSession(temperature: 0.3, topK: 1);
      await session.addQueryChunk(Message.text(
        text:
            'Summarize this conversation in 3-5 words as a title: $firstUserMessage',
        isUser: true,
      ));
      final title = await session.getResponse();
      await session.close();

      final cleaned = title.trim().replaceAll(RegExp('["\' ]+\$|^["\' ]+'), '');
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
          if (_chatError != null)
            MaterialBanner(
              content: Text('Model error: $_chatError'),
              actions: [
                TextButton(
                  onPressed: _createChat,
                  child: const Text('RETRY'),
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
            enabled: !_isGenerating,
          ),
        ],
      ),
    );
  }
}
