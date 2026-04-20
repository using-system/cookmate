import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cookidoo/providers.dart';
import 'handlers/get_recipe_detail_handler.dart';
import 'handlers/search_recipes_handler.dart';
import 'handlers/share_handler.dart';
import 'tool_registry.dart';

/// All tool handlers are registered here. Add new handlers to the list.
final toolRegistryProvider = Provider<ToolRegistry>(
  (ref) {
    final cookidooRepo = ref.watch(cookidooRepositoryProvider);
    return ToolRegistry([
      ShareHandler(),
      SearchRecipesHandler(cookidooRepo),
      GetRecipeDetailHandler(cookidooRepo),
    ]);
  },
);
