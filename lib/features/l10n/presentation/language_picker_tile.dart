import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/locale_preference.dart';
import '../providers.dart';

const Map<String, String> _languageNames = {
  'fr': 'Français',
  'en': 'English',
  'es': 'Español',
  'de': 'Deutsch',
};

class LanguagePickerTile extends ConsumerWidget {
  const LanguagePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final preferenceAsync = ref.watch(localePreferenceProvider);
    final preference =
        preferenceAsync.valueOrNull ?? const SystemLocalePreference();

    final resolvedLanguageCode = Localizations.localeOf(context).languageCode;
    final subtitle = switch (preference) {
      SystemLocalePreference() => l10n.settingsLanguageFollowSystem(
          _languageNames[resolvedLanguageCode] ?? resolvedLanguageCode,
        ),
      ForcedLocalePreference(:final locale) =>
        _languageNames[locale.languageCode] ?? locale.languageCode,
    };

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.settingsLanguageTitle),
      subtitle: Text(subtitle),
      onTap: () => _openDialog(context, ref, preference),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    LocalePreference current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final selected = await showDialog<LocalePreference>(
      context: context,
      builder: (dialogContext) {
        return SimpleDialog(
          title: Text(l10n.settingsLanguageDialogTitle),
          children: [
            _OptionTile(
              label: l10n.settingsLanguageOptionSystem,
              value: const SystemLocalePreference(),
              groupValue: current,
            ),
            for (final entry in _languageNames.entries)
              _OptionTile(
                label: entry.value,
                value: ForcedLocalePreference(Locale(entry.key)),
                groupValue: current,
              ),
          ],
        );
      },
    );

    if (selected == null) return;
    if (selected == current) return;

    try {
      await ref
          .read(localePreferenceProvider.notifier)
          .setPreference(selected);
    } catch (error, stack) {
      debugPrint('Failed to change locale: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsLanguageChangeFailureSnackbar)),
      );
    }
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.value,
    required this.groupValue,
  });

  final String label;
  final LocalePreference value;
  final LocalePreference groupValue;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<LocalePreference>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (_) => Navigator.of(context).pop(value),
    );
  }
}
