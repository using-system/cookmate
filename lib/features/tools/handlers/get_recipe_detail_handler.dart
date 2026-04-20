import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/core/tool.dart';

import '../../cookidoo/domain/cookidoo_repository.dart';
import '../../cookidoo/domain/models/cookidoo_exceptions.dart';
import '../tool_handler.dart';

class GetRecipeDetailHandler extends ToolHandler {
  GetRecipeDetailHandler(this._repository);

  final CookidooRepository _repository;

  @override
  Tool get definition => const Tool(
        name: 'get_recipe_detail',
        description:
            'Get the full details of a Cookidoo recipe by ID, including '
            'ingredients, steps, and nutrition information.',
        parameters: {
          'type': 'object',
          'properties': {
            'recipe_id': {
              'type': 'string',
              'description': 'The Cookidoo recipe ID (e.g. "r145192").',
            },
          },
          'required': ['recipe_id'],
        },
      );

  @override
  Future<void> execute(
      Map<String, dynamic> args, BuildContext context) async {
    final recipeId = args['recipe_id'] as String? ?? '';

    try {
      final detail = await _repository.getRecipeDetail(recipeId);
      final ingredients = detail.ingredientGroups
          .expand((g) => g.ingredients)
          .map((i) => '${i.quantity} ${i.unit} ${i.name}')
          .toList();
      final steps = detail.stepGroups
          .expand((g) => g.steps)
          .map((s) => '${s.title}: ${s.text}')
          .toList();

      debugPrint(
        'GetRecipeDetailHandler: ${detail.title}'
        '\nIngredients: ${jsonEncode(ingredients)}'
        '\nSteps: ${jsonEncode(steps)}',
      );
    } on CookidooAuthException {
      debugPrint(
        'GetRecipeDetailHandler: credentials not configured or invalid',
      );
    } on CookidooNotFoundException {
      debugPrint('GetRecipeDetailHandler: recipe $recipeId not found');
    } on CookidooNetworkException catch (e) {
      debugPrint('GetRecipeDetailHandler: network error — $e');
    }
  }
}
