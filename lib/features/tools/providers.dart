import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cookidoo/providers.dart';
import '../skills/providers.dart';
import 'handlers/get_recipe_detail_handler.dart';
import 'handlers/search_recipes_handler.dart';
import 'handlers/share_handler.dart';
import 'tool_handler.dart';
import 'tool_registry.dart';

/// All tool handlers are registered here. Add new handlers to the list.
final toolRegistryProvider = Provider<ToolRegistry>(
  (ref) {
    final cookidooRepo = ref.watch(cookidooRepositoryProvider);

    // All available handlers keyed by tool name.
    final allHandlers = <String, ToolHandler>{
      'share_recipe': ShareHandler(),
      'search_recipes': SearchRecipesHandler(cookidooRepo),
      'get_recipe_detail': GetRecipeDetailHandler(cookidooRepo),
    };

    // Only register handlers whose tool name appears in an enabled skill.
    final enabledSkills =
        ref.watch(skillRegistryProvider).valueOrNull?.skills ?? [];
    final enabledToolNames =
        enabledSkills.expand((s) => s.tools).toSet();

    final activeHandlers = allHandlers.entries
        .where((e) => enabledToolNames.contains(e.key))
        .map((e) => e.value)
        .toList();

    return ToolRegistry(activeHandlers);
  },
);
