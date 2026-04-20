import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/recipe_config.dart';
import '../providers.dart';

class DietaryRestrictionsTile extends ConsumerWidget {
  const DietaryRestrictionsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configAsync = ref.watch(recipeConfigProvider);
    final current = configAsync.valueOrNull?.dietaryRestrictions ?? '';

    return ListTile(
      leading: const Icon(Icons.no_food_outlined),
      title: Text(l10n.settingsDietaryRestrictionsTitle),
      subtitle: Text(
        current.isEmpty ? l10n.settingsDietaryRestrictionsNone : current,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () async {
        final controller = TextEditingController(text: current);
        final result = await showDialog<String>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.settingsDietaryRestrictionsDialogTitle),
            content: TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l10n.settingsDietaryRestrictionsHint,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text),
                child: Text(l10n.ok),
              ),
            ],
          ),
        );
        controller.dispose();
        if (result != null && result != current) {
          try {
            final config = configAsync.valueOrNull ?? const RecipeConfig();
            await ref
                .read(recipeConfigProvider.notifier)
                .setConfig(config.copyWith(dietaryRestrictions: result));
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
