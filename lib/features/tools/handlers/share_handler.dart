import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/core/tool.dart';
import 'package:share_plus/share_plus.dart';

import '../tool_handler.dart';

class ShareHandler extends ToolHandler {
  @override
  Tool get definition => const Tool(
        name: 'share_recipe',
        description: 'Share a recipe with another app '
            '(WhatsApp, email, Telegram, etc.).',
        parameters: {
          'type': 'object',
          'properties': {
            'title': {
              'type': 'string',
              'description': 'The recipe title.',
            },
            'content': {
              'type': 'string',
              'description': 'The full recipe with all steps.',
            },
          },
          'required': ['title', 'content'],
        },
      );

  @override
  Future<Map<String, dynamic>?> execute(
      Map<String, dynamic> args, BuildContext context) async {
    final title = args['title'] as String? ?? '';
    final content = args['content'] as String? ?? '';
    final text = title.isNotEmpty ? '$title\n\n$content' : content;
    await SharePlus.instance.share(ShareParams(text: text));
    return null; // Fire-and-forget, no result to send back to LLM.
  }
}
