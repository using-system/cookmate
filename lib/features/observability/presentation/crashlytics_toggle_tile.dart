import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class CrashlyticsToggleTile extends ConsumerWidget {
  const CrashlyticsToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final crashlyticsAsync = ref.watch(crashlyticsPreferenceProvider);
    final enabled = crashlyticsAsync.valueOrNull ?? false;

    return SwitchListTile(
      secondary: const Icon(Icons.bug_report_outlined),
      title: Text(l10n.settingsCrashlyticsTitle),
      subtitle: Text(l10n.settingsCrashlyticsDescription),
      value: enabled,
      onChanged: (value) async {
        try {
          await ref
              .read(crashlyticsPreferenceProvider.notifier)
              .setPreference(value);
        } catch (error, stack) {
          debugPrint('Failed to change crashlytics: $error\n$stack');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(l10n.settingsCrashlyticsChangeFailureSnackbar),
              ),
            );
          }
        }
      },
    );
  }
}
