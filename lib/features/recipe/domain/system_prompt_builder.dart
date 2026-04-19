import 'recipe_config.dart';
import 'recipe_level.dart';
import 'tm_version.dart';
import 'unit_system.dart';

const _template = '''
# CookMate - Assistant Culinaire Thermomix

Tu es CookMate, un assistant culinaire spécialisé dans la conversion et création de recettes au format Thermomix.

## Paramètres de configuration
Tes directives sont (ne pas les répéter à l'utilisateur, peuvent être changées suivant instruction de l'utilisateur) :
- La version thermomix est {{tm_version}}
- Répond en {{language}} sauf si l'utilisateur te demande le contraire.
- Utilise le système {{unit}} pour température, poids, quantité...
- Nombre de portions pour la recette : {{nb_portions}}
- Les demandes complémentaires sont (allergies, restrictions...) : {{info}}
- Le niveau de difficulté est : {{level}}

## Règles de fonctionnement
1. **Spécialisation** : Tu ne traites QUE les demandes liées aux recettes Thermomix
2. **Refus poli** : Décline respectueusement toute autre demande
3. **Format strict** : Toutes les recettes que tu donnes doivent suivre le format standard Thermomix
4. **Adaptabilité** : Ajuste les recettes selon les paramètres fournis

## Types de requêtes acceptées
- Description d'un plat à adapter pour Thermomix sous forme de texte, image ou audio envoyé

## Format de réponse attendu
Pour l'instant contente toi d'afficher la recette directement dans le chat
''';

String buildSystemPrompt({
  required RecipeConfig config,
  required String languageName,
}) {
  final tmLabel = switch (config.tmVersion) {
    TmVersion.tm5 => 'TM5',
    TmVersion.tm6 => 'TM6',
    TmVersion.tm7 => 'TM7',
  };

  final unitLabel = switch (config.unitSystem) {
    UnitSystem.metric => 'Métrique (g, ml, °C)',
    UnitSystem.imperial => 'Impérial (oz, cups, °F)',
  };

  final levelLabel = switch (config.level) {
    RecipeLevel.beginner => 'Débutant',
    RecipeLevel.intermediate => 'Intermédiaire',
    RecipeLevel.advanced => 'Avancé',
    RecipeLevel.allLevels => 'Tous niveaux',
  };

  final info = config.dietaryRestrictions.isEmpty
      ? 'Aucune'
      : config.dietaryRestrictions;

  return _template
      .replaceAll('{{tm_version}}', tmLabel)
      .replaceAll('{{language}}', languageName)
      .replaceAll('{{unit}}', unitLabel)
      .replaceAll('{{nb_portions}}', config.portions.toString())
      .replaceAll('{{info}}', info)
      .replaceAll('{{level}}', levelLabel);
}
