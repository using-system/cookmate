import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class PerformanceToggleTile extends ConsumerWidget {
  const PerformanceToggleTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final performanceAsync = ref.watch(performancePreferenceProvider);
    final enabled = performanceAsync.valueOrNull ?? true;

    return SwitchListTile(
      secondary: const Icon(Icons.speed),
      title: Text(l10n.settingsPerformanceTitle),
      subtitle: Text(l10n.settingsPerformanceDescription),
      value: enabled,
      onChanged: performanceAsync.isLoading ? null : (value) async {
        try {
          await ref
              .read(performancePreferenceProvider.notifier)
              .setPreference(value);
        } catch (error, stack) {
          debugPrint('Failed to change performance: $error\n$stack');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(l10n.settingsPerformanceChangeFailureSnackbar),
              ),
            );
          }
        }
      },
    );
  }
}
