import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe_config.dart';
import '../domain/recipe_level.dart';
import '../providers.dart';

class LevelPickerTile extends ConsumerWidget {
  const LevelPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configAsync = ref.watch(recipeConfigProvider);
    final current =
        configAsync.valueOrNull?.level ?? RecipeLevel.defaultValue;

    String label(RecipeLevel v) => switch (v) {
          RecipeLevel.beginner => l10n.settingsLevelOptionBeginner,
          RecipeLevel.intermediate => l10n.settingsLevelOptionIntermediate,
          RecipeLevel.advanced => l10n.settingsLevelOptionAdvanced,
          RecipeLevel.allLevels => l10n.settingsLevelOptionAllLevels,
        };

    return ListTile(
      leading: const Icon(Icons.signal_cellular_alt_outlined),
      title: Text(l10n.settingsLevelTitle),
      subtitle: Text(label(current)),
      onTap: () async {
        final picked = await showDialog<RecipeLevel>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text(l10n.settingsLevelDialogTitle),
            children: RecipeLevel.values.map((v) {
              return RadioListTile<RecipeLevel>(
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
                .setConfig(config.copyWith(level: picked));
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
