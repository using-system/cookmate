import 'recipe_config.dart';

String buildSystemPrompt({
  required RecipeConfig config,
  required String language,
  String skillInstructions = '',
}) {
  final restrictions = config.dietaryRestrictions.isEmpty
      ? 'aucune'
      : config.dietaryRestrictions;

  return '''
CookMate: Thermomix recipe assistant. Answer any food or recipe related request (text, audio or image).
Config: ${config.tmVersion.name.toUpperCase()}, $language, ${config.unitSystem.name}, ${config.portions} servings, level ${config.level.name}, restrictions: $restrictions.
When a user asks for a recipe, ALWAYS use the search_recipes tool first. Base your answer on the search results. Never invent a recipe without searching first.
After receiving tool results, use them to write your recipe. Display the recipe then 2-3 adaptation tips.
$skillInstructions''';
}
