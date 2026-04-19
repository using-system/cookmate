import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ThinkingBubble extends StatelessWidget {
  const ThinkingBubble({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
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
      ),
    );
  }
}
