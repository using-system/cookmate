# Recipe Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Recipe" settings section (TM version, unit system, portions, level, dietary restrictions) persisted via SharedPreferences, displayed in Settings above AI, and shown in a tabbed info dialog in the conversation screen.

**Architecture:** New `recipe` feature module following the existing Clean Architecture pattern (domain → data → presentation). Riverpod AsyncNotifier for state, SharedPreferences for persistence. The conversation info dialog becomes a `DefaultTabController` with two tabs (Recipe / AI).

**Tech Stack:** Flutter, Riverpod, SharedPreferences, ARB l10n

---

### Task 1: Domain — Recipe enums and RecipeConfig model

**Files:**
- Create: `lib/features/recipe/domain/tm_version.dart`
- Create: `lib/features/recipe/domain/unit_system.dart`
- Create: `lib/features/recipe/domain/recipe_level.dart`
- Create: `lib/features/recipe/domain/recipe_config.dart`

- [ ] **Step 1: Create TmVersion enum**

```dart
// lib/features/recipe/domain/tm_version.dart
enum TmVersion {
  tm5,
  tm6,
  tm7;

  static const TmVersion defaultValue = TmVersion.tm6;

  String toStorageValue() => name;

  static TmVersion fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) return defaultValue;
    for (final v in TmVersion.values) {
      if (v.name == raw) return v;
    }
    return defaultValue;
  }
}
```

- [ ] **Step 2: Create UnitSystem enum**

```dart
// lib/features/recipe/domain/unit_system.dart
enum UnitSystem {
  metric,
  imperial;

  static const UnitSystem defaultValue = UnitSystem.metric;

  String toStorageValue() => name;

  static UnitSystem fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) return defaultValue;
    for (final v in UnitSystem.values) {
      if (v.name == raw) return v;
    }
    return defaultValue;
  }
}
```

- [ ] **Step 3: Create RecipeLevel enum**

```dart
// lib/features/recipe/domain/recipe_level.dart
enum RecipeLevel {
  beginner,
  intermediate,
  advanced,
  allLevels;

  static const RecipeLevel defaultValue = RecipeLevel.allLevels;

  String toStorageValue() => name;

  static RecipeLevel fromStorageValue(String? raw) {
    if (raw == null || raw.isEmpty) return defaultValue;
    for (final v in RecipeLevel.values) {
      if (v.name == raw) return v;
    }
    return defaultValue;
  }
}
```

- [ ] **Step 4: Create RecipeConfig model**

```dart
// lib/features/recipe/domain/recipe_config.dart
import 'recipe_level.dart';
import 'tm_version.dart';
import 'unit_system.dart';

class RecipeConfig {
  const RecipeConfig({
    this.tmVersion = TmVersion.defaultValue,
    this.unitSystem = UnitSystem.defaultValue,
    this.portions = defaultPortions,
    this.level = RecipeLevel.defaultValue,
    this.dietaryRestrictions = '',
  });

  static const int defaultPortions = 4;
  static const int minPortions = 4;
  static const int maxPortions = 8;

  final TmVersion tmVersion;
  final UnitSystem unitSystem;
  final int portions;
  final RecipeLevel level;
  final String dietaryRestrictions;

  RecipeConfig copyWith({
    TmVersion? tmVersion,
    UnitSystem? unitSystem,
    int? portions,
    RecipeLevel? level,
    String? dietaryRestrictions,
  }) {
    return RecipeConfig(
      tmVersion: tmVersion ?? this.tmVersion,
      unitSystem: unitSystem ?? this.unitSystem,
      portions: portions ?? this.portions,
      level: level ?? this.level,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeConfig &&
          other.tmVersion == tmVersion &&
          other.unitSystem == unitSystem &&
          other.portions == portions &&
          other.level == level &&
          other.dietaryRestrictions == dietaryRestrictions;

  @override
  int get hashCode =>
      Object.hash(tmVersion, unitSystem, portions, level, dietaryRestrictions);
}
```

- [ ] **Step 5: Commit**

```
feat(recipe): add recipe domain models
```

---

### Task 2: Data — RecipeConfigStorage

**Files:**
- Create: `lib/features/recipe/data/recipe_config_storage.dart`

- [ ] **Step 1: Create RecipeConfigStorage**

Follow the exact same pattern as `lib/features/chat/data/expert_config_storage.dart`.

```dart
// lib/features/recipe/data/recipe_config_storage.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recipe_config.dart';
import '../domain/recipe_level.dart';
import '../domain/tm_version.dart';
import '../domain/unit_system.dart';

class RecipeConfigStorage {
  RecipeConfigStorage(this._prefs);

  static const _keyTmVersion = 'recipe_tm_version';
  static const _keyUnitSystem = 'recipe_unit_system';
  static const _keyPortions = 'recipe_portions';
  static const _keyLevel = 'recipe_level';
  static const _keyDietaryRestrictions = 'recipe_dietary_restrictions';

  final SharedPreferences _prefs;

  RecipeConfig read() {
    try {
      return RecipeConfig(
        tmVersion: TmVersion.fromStorageValue(_prefs.getString(_keyTmVersion)),
        unitSystem:
            UnitSystem.fromStorageValue(_prefs.getString(_keyUnitSystem)),
        portions: _prefs.getInt(_keyPortions) ?? RecipeConfig.defaultPortions,
        level: RecipeLevel.fromStorageValue(_prefs.getString(_keyLevel)),
        dietaryRestrictions: _prefs.getString(_keyDietaryRestrictions) ?? '',
      );
    } catch (error, stack) {
      debugPrint('Failed to read recipe config: $error\n$stack');
      return const RecipeConfig();
    }
  }

  Future<void> write(RecipeConfig config) async {
    if (!await _prefs.setString(_keyTmVersion, config.tmVersion.toStorageValue())) {
      throw Exception('Failed to persist recipe tmVersion.');
    }
    if (!await _prefs.setString(_keyUnitSystem, config.unitSystem.toStorageValue())) {
      throw Exception('Failed to persist recipe unitSystem.');
    }
    if (!await _prefs.setInt(_keyPortions, config.portions)) {
      throw Exception('Failed to persist recipe portions.');
    }
    if (!await _prefs.setString(_keyLevel, config.level.toStorageValue())) {
      throw Exception('Failed to persist recipe level.');
    }
    if (!await _prefs.setString(_keyDietaryRestrictions, config.dietaryRestrictions)) {
      throw Exception('Failed to persist recipe dietaryRestrictions.');
    }
  }
}
```

- [ ] **Step 2: Commit**

```
feat(recipe): add recipe config storage
```

---

### Task 3: State — Riverpod providers

**Files:**
- Create: `lib/features/recipe/providers.dart`

- [ ] **Step 1: Create recipe providers**

Follow the exact same pattern as the expert config provider in `lib/features/chat/providers.dart:184-217`.

```dart
// lib/features/recipe/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/recipe_config_storage.dart';
import 'domain/recipe_config.dart';

final recipeConfigStorageProvider =
    FutureProvider<RecipeConfigStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return RecipeConfigStorage(prefs);
});

class RecipeConfigNotifier extends AsyncNotifier<RecipeConfig> {
  @override
  Future<RecipeConfig> build() async {
    final storage = await ref.watch(recipeConfigStorageProvider.future);
    return storage.read();
  }

  Future<void> setConfig(RecipeConfig config) async {
    final storage = await ref.read(recipeConfigStorageProvider.future);
    state = const AsyncValue<RecipeConfig>.loading().copyWithPrevious(state);
    try {
      await storage.write(config);
      state = AsyncValue.data(config);
    } catch (error, stack) {
      state = AsyncValue<RecipeConfig>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final recipeConfigProvider =
    AsyncNotifierProvider<RecipeConfigNotifier, RecipeConfig>(
  RecipeConfigNotifier.new,
);
```

- [ ] **Step 2: Commit**

```
feat(recipe): add recipe config Riverpod provider
```

---

### Task 4: L10n — Add all recipe-related strings to all 4 ARB files

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_es.arb`

- [ ] **Step 1: Add English strings to `app_en.arb`**

Add these entries before the closing `}`. Keys to add:

```json
  "settingsSectionRecipe": "Recipe",
  "@settingsSectionRecipe": { "description": "Section header for recipe-related settings." },

  "settingsTmVersionTitle": "TM Version",
  "@settingsTmVersionTitle": { "description": "Title of the Thermomix version setting tile." },

  "settingsTmVersionDialogTitle": "Choose Thermomix version",
  "@settingsTmVersionDialogTitle": { "description": "Title of the TM version picker dialog." },

  "settingsTmVersionOptionTm5": "TM5",
  "@settingsTmVersionOptionTm5": { "description": "Label for Thermomix 5." },

  "settingsTmVersionOptionTm6": "TM6",
  "@settingsTmVersionOptionTm6": { "description": "Label for Thermomix 6." },

  "settingsTmVersionOptionTm7": "TM7",
  "@settingsTmVersionOptionTm7": { "description": "Label for Thermomix 7." },

  "settingsUnitSystemTitle": "Unit system",
  "@settingsUnitSystemTitle": { "description": "Title of the unit system setting tile." },

  "settingsUnitSystemDialogTitle": "Choose unit system",
  "@settingsUnitSystemDialogTitle": { "description": "Title of the unit system picker dialog." },

  "settingsUnitSystemOptionMetric": "Metric (g, ml, °C)",
  "@settingsUnitSystemOptionMetric": { "description": "Label for metric units." },

  "settingsUnitSystemOptionImperial": "Imperial (oz, cups, °F)",
  "@settingsUnitSystemOptionImperial": { "description": "Label for imperial units." },

  "settingsPortionsTitle": "Portions",
  "@settingsPortionsTitle": { "description": "Title of the portions setting tile." },

  "settingsPortionsDialogTitle": "Choose number of portions",
  "@settingsPortionsDialogTitle": { "description": "Title of the portions picker dialog." },

  "settingsPortionsValue": "{count} portions",
  "@settingsPortionsValue": {
    "description": "Display value for number of portions.",
    "placeholders": { "count": { "type": "int", "example": "4" } }
  },

  "settingsLevelTitle": "Level",
  "@settingsLevelTitle": { "description": "Title of the recipe level setting tile." },

  "settingsLevelDialogTitle": "Choose recipe level",
  "@settingsLevelDialogTitle": { "description": "Title of the recipe level picker dialog." },

  "settingsLevelOptionBeginner": "Beginner",
  "@settingsLevelOptionBeginner": { "description": "Label for beginner level." },

  "settingsLevelOptionIntermediate": "Intermediate",
  "@settingsLevelOptionIntermediate": { "description": "Label for intermediate level." },

  "settingsLevelOptionAdvanced": "Advanced",
  "@settingsLevelOptionAdvanced": { "description": "Label for advanced level." },

  "settingsLevelOptionAllLevels": "All levels",
  "@settingsLevelOptionAllLevels": { "description": "Label for all-levels option." },

  "settingsDietaryRestrictionsTitle": "Dietary restrictions",
  "@settingsDietaryRestrictionsTitle": { "description": "Title of the dietary restrictions setting tile." },

  "settingsDietaryRestrictionsDialogTitle": "Dietary restrictions",
  "@settingsDietaryRestrictionsDialogTitle": { "description": "Title of the dietary restrictions dialog." },

  "settingsDietaryRestrictionsHint": "e.g. gluten-free, vegetarian, no nuts…",
  "@settingsDietaryRestrictionsHint": { "description": "Hint text for the dietary restrictions text field." },

  "settingsDietaryRestrictionsNone": "None",
  "@settingsDietaryRestrictionsNone": { "description": "Subtitle shown when no dietary restrictions are set." },

  "settingsRecipeChangeFailureSnackbar": "Couldn't save recipe settings. Please try again.",
  "@settingsRecipeChangeFailureSnackbar": { "description": "Shown when persisting recipe settings fails." },

  "chatInfoTabRecipe": "Recipe",
  "@chatInfoTabRecipe": { "description": "Tab label for recipe settings in the conversation info dialog." },

  "chatInfoTabAi": "AI",
  "@chatInfoTabAi": { "description": "Tab label for AI settings in the conversation info dialog." },

  "chatRecipeInfoTmVersion": "TM Version",
  "@chatRecipeInfoTmVersion": { "description": "Label for TM version in recipe info tab." },

  "chatRecipeInfoUnitSystem": "Unit system",
  "@chatRecipeInfoUnitSystem": { "description": "Label for unit system in recipe info tab." },

  "chatRecipeInfoPortions": "Portions",
  "@chatRecipeInfoPortions": { "description": "Label for portions in recipe info tab." },

  "chatRecipeInfoLevel": "Level",
  "@chatRecipeInfoLevel": { "description": "Label for level in recipe info tab." },

  "chatRecipeInfoDietaryRestrictions": "Dietary restrictions",
  "@chatRecipeInfoDietaryRestrictions": { "description": "Label for dietary restrictions in recipe info tab." }
```

- [ ] **Step 2: Add French strings to `app_fr.arb`**

```json
  "settingsSectionRecipe": "Recette",
  "settingsTmVersionTitle": "Version TM",
  "settingsTmVersionDialogTitle": "Choisir la version Thermomix",
  "settingsTmVersionOptionTm5": "TM5",
  "settingsTmVersionOptionTm6": "TM6",
  "settingsTmVersionOptionTm7": "TM7",
  "settingsUnitSystemTitle": "Système d'unités",
  "settingsUnitSystemDialogTitle": "Choisir le système d'unités",
  "settingsUnitSystemOptionMetric": "Métrique (g, ml, °C)",
  "settingsUnitSystemOptionImperial": "Impérial (oz, cups, °F)",
  "settingsPortionsTitle": "Portions",
  "settingsPortionsDialogTitle": "Choisir le nombre de portions",
  "settingsPortionsValue": "{count} portions",
  "settingsLevelTitle": "Niveau",
  "settingsLevelDialogTitle": "Choisir le niveau de recette",
  "settingsLevelOptionBeginner": "Débutant",
  "settingsLevelOptionIntermediate": "Intermédiaire",
  "settingsLevelOptionAdvanced": "Avancé",
  "settingsLevelOptionAllLevels": "Tous niveaux",
  "settingsDietaryRestrictionsTitle": "Restrictions alimentaires",
  "settingsDietaryRestrictionsDialogTitle": "Restrictions alimentaires",
  "settingsDietaryRestrictionsHint": "ex. sans gluten, végétarien, sans noix…",
  "settingsDietaryRestrictionsNone": "Aucune",
  "settingsRecipeChangeFailureSnackbar": "Impossible de sauvegarder les réglages recette. Réessayez.",
  "chatInfoTabRecipe": "Recette",
  "chatInfoTabAi": "IA",
  "chatRecipeInfoTmVersion": "Version TM",
  "chatRecipeInfoUnitSystem": "Système d'unités",
  "chatRecipeInfoPortions": "Portions",
  "chatRecipeInfoLevel": "Niveau",
  "chatRecipeInfoDietaryRestrictions": "Restrictions alimentaires"
```

- [ ] **Step 3: Add German strings to `app_de.arb`**

```json
  "settingsSectionRecipe": "Rezept",
  "settingsTmVersionTitle": "TM-Version",
  "settingsTmVersionDialogTitle": "Thermomix-Version auswählen",
  "settingsTmVersionOptionTm5": "TM5",
  "settingsTmVersionOptionTm6": "TM6",
  "settingsTmVersionOptionTm7": "TM7",
  "settingsUnitSystemTitle": "Einheitensystem",
  "settingsUnitSystemDialogTitle": "Einheitensystem auswählen",
  "settingsUnitSystemOptionMetric": "Metrisch (g, ml, °C)",
  "settingsUnitSystemOptionImperial": "Imperial (oz, cups, °F)",
  "settingsPortionsTitle": "Portionen",
  "settingsPortionsDialogTitle": "Anzahl der Portionen wählen",
  "settingsPortionsValue": "{count} Portionen",
  "settingsLevelTitle": "Niveau",
  "settingsLevelDialogTitle": "Rezeptniveau auswählen",
  "settingsLevelOptionBeginner": "Anfänger",
  "settingsLevelOptionIntermediate": "Fortgeschritten",
  "settingsLevelOptionAdvanced": "Profi",
  "settingsLevelOptionAllLevels": "Alle Niveaus",
  "settingsDietaryRestrictionsTitle": "Ernährungseinschränkungen",
  "settingsDietaryRestrictionsDialogTitle": "Ernährungseinschränkungen",
  "settingsDietaryRestrictionsHint": "z. B. glutenfrei, vegetarisch, ohne Nüsse…",
  "settingsDietaryRestrictionsNone": "Keine",
  "settingsRecipeChangeFailureSnackbar": "Rezepteinstellungen konnten nicht gespeichert werden. Bitte versuche es erneut.",
  "chatInfoTabRecipe": "Rezept",
  "chatInfoTabAi": "KI",
  "chatRecipeInfoTmVersion": "TM-Version",
  "chatRecipeInfoUnitSystem": "Einheitensystem",
  "chatRecipeInfoPortions": "Portionen",
  "chatRecipeInfoLevel": "Niveau",
  "chatRecipeInfoDietaryRestrictions": "Ernährungseinschränkungen"
```

- [ ] **Step 4: Add Spanish strings to `app_es.arb`**

```json
  "settingsSectionRecipe": "Receta",
  "settingsTmVersionTitle": "Versión TM",
  "settingsTmVersionDialogTitle": "Elegir versión Thermomix",
  "settingsTmVersionOptionTm5": "TM5",
  "settingsTmVersionOptionTm6": "TM6",
  "settingsTmVersionOptionTm7": "TM7",
  "settingsUnitSystemTitle": "Sistema de unidades",
  "settingsUnitSystemDialogTitle": "Elegir sistema de unidades",
  "settingsUnitSystemOptionMetric": "Métrico (g, ml, °C)",
  "settingsUnitSystemOptionImperial": "Imperial (oz, cups, °F)",
  "settingsPortionsTitle": "Porciones",
  "settingsPortionsDialogTitle": "Elegir número de porciones",
  "settingsPortionsValue": "{count} porciones",
  "settingsLevelTitle": "Nivel",
  "settingsLevelDialogTitle": "Elegir nivel de receta",
  "settingsLevelOptionBeginner": "Principiante",
  "settingsLevelOptionIntermediate": "Intermedio",
  "settingsLevelOptionAdvanced": "Avanzado",
  "settingsLevelOptionAllLevels": "Todos los niveles",
  "settingsDietaryRestrictionsTitle": "Restricciones dietéticas",
  "settingsDietaryRestrictionsDialogTitle": "Restricciones dietéticas",
  "settingsDietaryRestrictionsHint": "ej. sin gluten, vegetariano, sin frutos secos…",
  "settingsDietaryRestrictionsNone": "Ninguna",
  "settingsRecipeChangeFailureSnackbar": "No se pudieron guardar los ajustes de receta. Inténtalo de nuevo.",
  "chatInfoTabRecipe": "Receta",
  "chatInfoTabAi": "IA",
  "chatRecipeInfoTmVersion": "Versión TM",
  "chatRecipeInfoUnitSystem": "Sistema de unidades",
  "chatRecipeInfoPortions": "Porciones",
  "chatRecipeInfoLevel": "Nivel",
  "chatRecipeInfoDietaryRestrictions": "Restricciones dietéticas"
```

- [ ] **Step 5: Run l10n code generation**

Run: `flutter gen-l10n`
Expected: Success, generates updated `app_localizations*.dart` files.

- [ ] **Step 6: Commit**

```
feat(l10n): add recipe settings strings for all locales
```

---

### Task 5: Presentation — Recipe settings tiles for Settings page

**Files:**
- Create: `lib/features/recipe/presentation/tm_version_picker_tile.dart`
- Create: `lib/features/recipe/presentation/unit_system_picker_tile.dart`
- Create: `lib/features/recipe/presentation/portions_picker_tile.dart`
- Create: `lib/features/recipe/presentation/level_picker_tile.dart`
- Create: `lib/features/recipe/presentation/dietary_restrictions_tile.dart`

- [ ] **Step 1: Create TmVersionPickerTile**

Follow the pattern of `lib/features/chat/presentation/backend_picker_tile.dart` — a `ConsumerWidget` with a `ListTile` that opens a radio dialog.

```dart
// lib/features/recipe/presentation/tm_version_picker_tile.dart
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
```

- [ ] **Step 2: Create UnitSystemPickerTile**

```dart
// lib/features/recipe/presentation/unit_system_picker_tile.dart
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
```

- [ ] **Step 3: Create PortionsPickerTile**

```dart
// lib/features/recipe/presentation/portions_picker_tile.dart
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
```

- [ ] **Step 4: Create LevelPickerTile**

```dart
// lib/features/recipe/presentation/level_picker_tile.dart
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
```

- [ ] **Step 5: Create DietaryRestrictionsTile**

```dart
// lib/features/recipe/presentation/dietary_restrictions_tile.dart
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
```

- [ ] **Step 6: Commit**

```
feat(recipe): add recipe settings tiles
```

---

### Task 6: Wire recipe section into SettingsPage

**Files:**
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Add recipe section above AI section**

Add imports for the 5 new tiles, then insert a "Recipe" section header and the tiles before the existing AI section. The modified `children` list of the `ListView` becomes:

```dart
children: [
  // ── Recipe section ──
  Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(l10n.settingsSectionRecipe, style: sectionStyle),
  ),
  const TmVersionPickerTile(),
  const Divider(height: 1),
  const UnitSystemPickerTile(),
  const Divider(height: 1),
  const PortionsPickerTile(),
  const Divider(height: 1),
  const LevelPickerTile(),
  const Divider(height: 1),
  const DietaryRestrictionsTile(),
  const Divider(height: 1),
  // ── AI section (existing) ──
  Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(l10n.settingsSectionAi, style: sectionStyle),
  ),
  // ... rest unchanged
],
```

- [ ] **Step 2: Commit**

```
feat(settings): add recipe section to settings page
```

---

### Task 7: Update conversation info dialog to tabbed layout

**Files:**
- Modify: `lib/features/chat/presentation/conversation_page.dart:659-733`

- [ ] **Step 1: Update `_showAiInfoDialog` to use tabs**

Replace the `_showAiInfoDialog` method. It now reads both recipe config and AI settings, then shows a `Dialog` with `DefaultTabController`, `TabBar` (Recipe / AI), and `TabBarView`.

```dart
Future<void> _showAiInfoDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final model = await ref.read(chatModelPreferenceProvider.future);
  final backend = await ref.read(chatBackendPreferenceProvider.future);
  final reasoning = await ref.read(chatReasoningPreferenceProvider.future);
  final expertConfig = await ref.read(chatExpertConfigProvider.future);
  final recipeConfig = await ref.read(recipeConfigProvider.future);

  if (!mounted) return;

  final modelLabel = switch (model) {
    ChatModelPreference.gemma4E2B => l10n.settingsModelOptionE2B,
    ChatModelPreference.gemma4E4B => l10n.settingsModelOptionE4B,
  };
  final backendLabel = switch (backend) {
    ChatBackendPreference.gpu => l10n.settingsBackendOptionGpu,
    ChatBackendPreference.cpu => l10n.settingsBackendOptionCpu,
  };
  final reasoningLabel = reasoning
      ? l10n.settingsReasoningSubtitleOn
      : l10n.settingsReasoningSubtitleOff;

  final tmLabel = switch (recipeConfig.tmVersion) {
    TmVersion.tm5 => l10n.settingsTmVersionOptionTm5,
    TmVersion.tm6 => l10n.settingsTmVersionOptionTm6,
    TmVersion.tm7 => l10n.settingsTmVersionOptionTm7,
  };
  final unitLabel = switch (recipeConfig.unitSystem) {
    UnitSystem.metric => l10n.settingsUnitSystemOptionMetric,
    UnitSystem.imperial => l10n.settingsUnitSystemOptionImperial,
  };
  final levelLabel = switch (recipeConfig.level) {
    RecipeLevel.beginner => l10n.settingsLevelOptionBeginner,
    RecipeLevel.intermediate => l10n.settingsLevelOptionIntermediate,
    RecipeLevel.advanced => l10n.settingsLevelOptionAdvanced,
    RecipeLevel.allLevels => l10n.settingsLevelOptionAllLevels,
  };

  await showDialog<void>(
    context: context,
    builder: (ctx) => DefaultTabController(
      length: 2,
      child: Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              tabs: [
                Tab(text: l10n.chatInfoTabRecipe),
                Tab(text: l10n.chatInfoTabAi),
              ],
            ),
            SizedBox(
              height: 340,
              child: TabBarView(
                children: [
                  // ── Recipe tab ──
                  ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.kitchen_outlined),
                        title: Text(l10n.chatRecipeInfoTmVersion),
                        subtitle: Text(tmLabel),
                      ),
                      ListTile(
                        leading: const Icon(Icons.straighten_outlined),
                        title: Text(l10n.chatRecipeInfoUnitSystem),
                        subtitle: Text(unitLabel),
                      ),
                      ListTile(
                        leading: const Icon(Icons.group_outlined),
                        title: Text(l10n.chatRecipeInfoPortions),
                        subtitle: Text(
                            l10n.settingsPortionsValue(recipeConfig.portions)),
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.signal_cellular_alt_outlined),
                        title: Text(l10n.chatRecipeInfoLevel),
                        subtitle: Text(levelLabel),
                      ),
                      ListTile(
                        leading: const Icon(Icons.no_food_outlined),
                        title: Text(l10n.chatRecipeInfoDietaryRestrictions),
                        subtitle: Text(recipeConfig.dietaryRestrictions.isEmpty
                            ? l10n.settingsDietaryRestrictionsNone
                            : recipeConfig.dietaryRestrictions),
                      ),
                    ],
                  ),
                  // ── AI tab ──
                  ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.smart_toy_outlined),
                        title: Text(l10n.chatAiInfoModel),
                        subtitle: Text(modelLabel),
                      ),
                      ListTile(
                        leading: const Icon(Icons.memory_outlined),
                        title: Text(l10n.chatAiInfoAccelerator),
                        subtitle: Text(backendLabel),
                      ),
                      ListTile(
                        leading: const Icon(Icons.psychology_outlined),
                        title: Text(l10n.chatAiInfoReasoning),
                        subtitle: Text(reasoningLabel),
                      ),
                      ListTile(
                        leading: const Icon(Icons.tune_outlined),
                        title: Text(l10n.chatAiInfoMaxTokens),
                        subtitle: Text(expertConfig.maxTokens.toString()),
                      ),
                      ListTile(
                        leading: const Icon(Icons.thermostat_outlined),
                        title: Text(l10n.chatAiInfoTemperature),
                        subtitle: Text(
                            expertConfig.temperature.toStringAsFixed(2)),
                      ),
                      ListTile(
                        leading: const Icon(Icons.filter_list_outlined),
                        title: Text(l10n.chatAiInfoTopK),
                        subtitle: Text(expertConfig.topK.toString()),
                      ),
                      ListTile(
                        leading: const Icon(Icons.donut_small_outlined),
                        title: Text(l10n.chatAiInfoTopP),
                        subtitle: Text(
                            expertConfig.topP.toStringAsFixed(2)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.chatAiInfoClose),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

Add these imports at the top of `conversation_page.dart`:

```dart
import '../../recipe/domain/recipe_level.dart';
import '../../recipe/domain/tm_version.dart';
import '../../recipe/domain/unit_system.dart';
import '../../recipe/providers.dart';
```

- [ ] **Step 2: Commit**

```
feat(chat): add tabbed recipe/AI info dialog in conversation
```

---

### Task 8: Build verification

- [ ] **Step 1: Run Flutter build**

Run: `flutter build apk --debug`
Expected: BUILD SUCCESSFUL

- [ ] **Step 2: Fix any compilation errors if needed**

- [ ] **Step 3: Final commit if any fixes were needed**
