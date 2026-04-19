import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe_config.dart';
import '../providers.dart';

class PortionsPickerTile extends ConsumerWidget {
  const PortionsPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configAsync = ref.watch(recipeConfigProvider);
    final current =
        configAsync.valueOrNull?.portions ?? RecipeConfig.defaultPortions;

    return ListTile(
      leading: const Icon(Icons.group_outlined),
      title: Text(l10n.settingsPortionsTitle),
      subtitle: Text(l10n.settingsPortionsValue(current)),
      onTap: () async {
        final picked = await showDialog<int>(
          context: context,
          builder: (ctx) {
            var selected = current;
            return StatefulBuilder(
              builder: (ctx, setDialogState) => AlertDialog(
                title: Text(l10n.settingsPortionsDialogTitle),
                content: Slider(
                  value: selected.toDouble(),
                  min: RecipeConfig.minPortions.toDouble(),
                  max: RecipeConfig.maxPortions.toDouble(),
                  divisions: RecipeConfig.maxPortions - RecipeConfig.minPortions,
                  label: selected.toString(),
                  onChanged: (val) =>
                      setDialogState(() => selected = val.round()),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l10n.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(selected),
                    child: Text(l10n.ok),
                  ),
                ],
              ),
            );
          },
        );
        if (picked != null && picked != current) {
          try {
            final config = configAsync.valueOrNull ?? const RecipeConfig();
            await ref
                .read(recipeConfigProvider.notifier)
                .setConfig(config.copyWith(portions: picked));
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
