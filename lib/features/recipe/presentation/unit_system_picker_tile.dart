import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe_config.dart';
import '../domain/unit_system.dart';
import '../providers.dart';

class UnitSystemPickerTile extends ConsumerWidget {
  const UnitSystemPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configAsync = ref.watch(recipeConfigProvider);
    final current =
        configAsync.valueOrNull?.unitSystem ?? UnitSystem.defaultValue;

    String label(UnitSystem v) => switch (v) {
          UnitSystem.metric => l10n.settingsUnitSystemOptionMetric,
          UnitSystem.imperial => l10n.settingsUnitSystemOptionImperial,
        };

    return ListTile(
      leading: const Icon(Icons.straighten_outlined),
      title: Text(l10n.settingsUnitSystemTitle),
      subtitle: Text(label(current)),
      onTap: () async {
        final picked = await showDialog<UnitSystem>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: Text(l10n.settingsUnitSystemDialogTitle),
            children: UnitSystem.values.map((v) {
              return RadioListTile<UnitSystem>(
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
                .setConfig(config.copyWith(unitSystem: picked));
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
