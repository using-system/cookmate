import 'package:flutter/material.dart';

import '../../../chat/domain/chat_message.dart';
import 'message_bubble.dart';
import 'thinking_bubble.dart';

class ChatListWidget extends StatelessWidget {
  const ChatListWidget({
    super.key,
    required this.messages,
    required this.isThinking,
    required this.thinkingContent,
  });

  final List<ChatMessage> messages;
  final bool isThinking;
  final String thinkingContent;

  @override
  Widget build(BuildContext context) {
    final extraItems = isThinking ? 1 : 0;
    final totalItems = messages.length + extraItems;

    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        if (index == 0 && isThinking) {
          return ThinkingBubble(content: thinkingContent);
        }

        final messageIndex = messages.length - 1 - (index - extraItems);
        final msg = messages[messageIndex];
        return MessageBubble(
          content: msg.content,
          isUser: msg.role == 'user',
        );
      },
    );
  }
}
