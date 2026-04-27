import 'recipe_config.dart';

String buildSystemPrompt({
  required RecipeConfig config,
  required String language,
  String skillInstructions = '',
}) {
  // TODO: re-enable config when the model handles it reliably.
  // final restrictions = config.dietaryRestrictions.isEmpty
  //     ? 'aucune'
  //     : config.dietaryRestrictions;
  // Config: ${config.tmVersion.name.toUpperCase()}, $language, ${config.unitSystem.name}, ${config.portions} servings, level ${config.level.name}, restrictions: $restrictions.
  return '''
CookMate: Thermomix recipe assistant. Answer any food or recipe related request (text, audio or image).
$skillInstructions''';
}
