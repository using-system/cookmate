import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe_config.dart';
import '../domain/tm_version.dart';
import '../providers.dart';

class TmVersionPickerTile extends ConsumerWidget {
  const TmVersionPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configAsync = ref.watch(recipeConfigProvider);
    final current = configAsync.valueOrNull?.tmVersion ?? TmVersion.defaultValue;

    String label(TmVersion v) => switch (v) {
          TmVersion.tm5 => l10n.settingsTmVersionOptionTm5,
          TmVersion.tm6 => l10n.settingsTmVersionOptionTm6,
          TmVersion.tm7 => l10n.settingsTmVersionOptionTm7,
        };

    return ListTile(
      leading: const Icon(Icons.kitchen_outlined),
      title: Text(l10n.settingsTmVersionTitle),
      subtitle: Text(label(current)),
      onTap: () async {
        final picked = await showDialog<TmVersion>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text(l10n.settingsTmVersionDialogTitle),
            children: TmVersion.values.map((v) {
              return RadioListTile<TmVersion>(
                title: Text(label(v)),
                value: v,
                groupValue: current,
                onChanged: (val) => Navigator.of(ctx).pop(val),
              );
            }).toList(),
          ),
        );
        if (picked != null && picked != current) {
          try {
            final config = configAsync.valueOrNull ?? const RecipeConfig();
            await ref
                .read(recipeConfigProvider.notifier)
                .setConfig(config.copyWith(tmVersion: picked));
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settingsRecipeChangeFailureSnackbar)),
              );
            }
          }
        }
      },
    );
  }
}
