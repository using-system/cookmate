import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_theme.dart';
import '../providers.dart';

class ThemePickerTile extends ConsumerWidget {
  const ThemePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferenceAsync = ref.watch(themePreferenceProvider);
    final theme = preferenceAsync.valueOrNull ?? AppTheme.defaultTheme;

    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: Text(l10n.settingsThemeTitle),
      subtitle: Text(_themeLabel(l10n, theme)),
      onTap: () => _openDialog(context, ref, theme),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    AppTheme current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = await showDialog<AppTheme>(
      context: context,
      builder: (dialogContext) {
        return RadioGroup<AppTheme>(
          groupValue: current,
          onChanged: (value) {
            if (value != null) {
              Navigator.of(dialogContext).pop(value);
            }
          },
          child: SimpleDialog(
            title: Text(l10n.settingsThemeDialogTitle),
            children: [
              for (final theme in AppTheme.values)
                _OptionTile(label: _themeLabel(l10n, theme), value: theme),
            ],
          ),
        );
      },
    );

    if (!context.mounted) return;
    if (selected == null) return;
    if (selected == current) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(themePreferenceProvider.notifier)
          .setPreference(selected);
    } catch (error, stack) {
      debugPrint('Failed to change theme: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsThemeChangeFailureSnackbar)),
      );
    }
  }

  String _themeLabel(AppLocalizations l10n, AppTheme theme) {
    return switch (theme) {
      AppTheme.dark => l10n.settingsThemeOptionDark,
      AppTheme.standard => l10n.settingsThemeOptionStandard,
      AppTheme.pink => l10n.settingsThemeOptionPink,
      AppTheme.matrix => l10n.settingsThemeOptionMatrix,
    };
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.value});

  final String label;
  final AppTheme value;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<AppTheme>(
      title: Text(label),
      value: value,
    );
  }
}
