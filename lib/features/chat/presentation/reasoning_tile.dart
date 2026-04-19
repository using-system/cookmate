import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class ReasoningTile extends ConsumerWidget {
  const ReasoningTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reasoningAsync = ref.watch(chatReasoningPreferenceProvider);
    final enabled = reasoningAsync.valueOrNull ?? true;

    return SwitchListTile(
      secondary: const Icon(Icons.psychology_outlined),
      title: Text(l10n.settingsReasoningTitle),
      subtitle: Text(
        enabled
            ? l10n.settingsReasoningSubtitleOn
            : l10n.settingsReasoningSubtitleOff,
      ),
      value: enabled,
      onChanged: (value) async {
        try {
          await ref
              .read(chatReasoningPreferenceProvider.notifier)
              .setPreference(value);
        } catch (error, stack) {
          debugPrint('Failed to change reasoning: $error\n$stack');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.settingsReasoningChangeFailureSnackbar),
              ),
            );
          }
        }
      },
    );
  }
}
