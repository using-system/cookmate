# Configurable Skills System

## Overview

Make skills toggleable from the Settings UI. Each skill declares its associated tools in the SKILL.md frontmatter. When a skill is disabled, its instructions are excluded from the system prompt and its tools are not registered. The system prompt reverts to minimal — all skill-specific instructions come from the SKILL.md files themselves.

## Goals

- Users can enable/disable skills from Settings
- Skills declare their tool associations in frontmatter (`tools` field)
- Disabled skills = no instructions in system prompt + no tools registered
- System prompt stays generic — skill-specific behavior lives in SKILL.md
- Default state for new skills: disabled

## SKILL.md Frontmatter Extension

Add a `tools` field listing associated tool handler names:

```yaml
# share-recipe
---
name: share-recipe
description: Share a recipe with another app (WhatsApp, email, Telegram, etc.).
tools: [share_recipe]
---

# recipe-format (no tools)
---
name: recipe-format
description: Output format and Thermomix rules for recipes in the chat.
tools: []
---

# search-recipe
---
name: search-recipe
description: Search for Thermomix recipes on Cookidoo for inspiration.
tools: [search_recipes, get_recipe_detail]
---
```

## Domain Model

`Skill` gains a `tools` field:

```dart
class Skill {
  const Skill({
    required this.name,
    required this.description,
    required this.instructions,
    this.tools = const [],
  });

  final String name;
  final String description;
  final String instructions;
  final List<String> tools;
}
```

## Skill Preferences Storage

SharedPreferences key pattern: `skill_enabled_{name}` (bool).

Default value when key does not exist: `false` (disabled).

A dedicated storage class reads/writes these preferences:

```dart
class SkillPreferencesStorage {
  bool isEnabled(String skillName);
  Future<void> setEnabled(String skillName, bool enabled);
}
```

## Provider Chain

1. `allSkillsProvider` — loads ALL skills from assets (unchanged loader)
2. `skillPreferencesStorageProvider` — wraps SharedPreferences
3. `skillRegistryProvider` — filters skills by enabled preferences, builds registry with only enabled skills
4. `toolRegistryProvider` — collects tool names from enabled skills, registers only matching handlers

## Tool Registry Changes

Currently `toolRegistryProvider` hardcodes handler instances. New approach:

- A map of all available handlers keyed by tool name
- Filter to only include handlers whose tool name appears in an enabled skill's `tools` list

```dart
final toolRegistryProvider = Provider<ToolRegistry>((ref) {
  final enabledSkills = ref.watch(skillRegistryProvider).value?.skills ?? [];
  final enabledToolNames = enabledSkills.expand((s) => s.tools).toSet();

  final allHandlers = <String, ToolHandler>{
    'share_recipe': ShareHandler(),
    'search_recipes': SearchRecipesHandler(cookidooRepo),
    'get_recipe_detail': GetRecipeDetailHandler(cookidooRepo),
  };

  final activeHandlers = allHandlers.entries
      .where((e) => enabledToolNames.contains(e.key))
      .map((e) => e.value)
      .toList();

  return ToolRegistry(activeHandlers);
});
```

## Settings UI

New "Skills" section between Recipe and Cookidoo in the Settings page.

For each skill loaded from assets, display a `SwitchListTile`:
- Title: skill name
- Subtitle: skill description
- Value: read from SharedPreferences (`skill_enabled_{name}`, default false)
- On toggle: write to SharedPreferences

Uses a plain `StatefulWidget` (no Riverpod watch on async providers) to avoid the dialog rebuild crash seen with Cookidoo credentials. Reads SharedPreferences directly.

## System Prompt — Minimal

Revert to generic prompt. Skill-specific instructions come exclusively from enabled SKILL.md files:

```dart
return '''
CookMate: Thermomix recipe assistant. Answer any food or recipe related request (text, audio or image).
Config: ${config.tmVersion.name.toUpperCase()}, $language, ${config.unitSystem.name}, ${config.portions} servings, level ${config.level.name}, restrictions: $restrictions.
Display the recipe then 2-3 adaptation tips.
$skillInstructions''';
```

## i18n

New keys (4 locales):
- `settingsSectionSkills` — section header ("Skills")

## Files Changed

| Action | File |
|--------|------|
| Modify | `lib/features/skills/domain/skill.dart` — add `tools` field |
| Modify | `lib/features/skills/domain/skill_loader.dart` — parse `tools` from frontmatter |
| Modify | `lib/features/skills/domain/skill_registry.dart` — filter by enabled |
| Modify | `lib/features/skills/providers.dart` — add preferences storage, filter skills |
| Create | `lib/features/skills/data/skill_preferences_storage.dart` — SharedPreferences wrapper |
| Create | `lib/features/skills/presentation/skills_section.dart` — Settings UI widget |
| Modify | `lib/features/tools/providers.dart` — filter handlers by enabled skill tools |
| Modify | `lib/features/settings/presentation/settings_page.dart` — add Skills section |
| Modify | `lib/features/recipe/domain/system_prompt_builder.dart` — revert to minimal |
| Modify | `assets/skills/share-recipe/SKILL.md` — add `tools: [share_recipe]` |
| Modify | `assets/skills/recipe-format/SKILL.md` — add `tools: []` |
| Modify | `assets/skills/search-recipe/SKILL.md` — add `tools: [search_recipes, get_recipe_detail]` |
| Modify | `lib/l10n/app_en.arb` — add settingsSectionSkills |
| Modify | `lib/l10n/app_fr.arb` — add settingsSectionSkills |
| Modify | `lib/l10n/app_de.arb` — add settingsSectionSkills |
| Modify | `lib/l10n/app_es.arb` — add settingsSectionSkills |
