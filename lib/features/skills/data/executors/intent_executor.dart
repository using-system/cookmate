import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

class IntentExecutor {
  static Future<void> execute(
    String intent,
    String parametersJson,
    BuildContext context,
  ) async {
    final params = jsonDecode(parametersJson) as Map<String, dynamic>;

    switch (intent) {
      case 'share':
        final title = params['title'] as String? ?? '';
        final content = params['content'] as String? ?? '';
        final text = title.isNotEmpty ? '$title\n\n$content' : content;
        await SharePlus.instance.share(ShareParams(text: text));
      default:
        debugPrint('IntentExecutor: unknown intent "$intent"');
    }
  }
}
