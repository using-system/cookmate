import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_gemma/core/tool.dart';

import '../../cookidoo/domain/cookidoo_repository.dart';
import '../../cookidoo/domain/models/cookidoo_exceptions.dart';
import '../tool_handler.dart';

class SearchRecipesHandler extends ToolHandler {
  SearchRecipesHandler(this._repository);

  final CookidooRepository _repository;

  @override
  Tool get definition => const Tool(
        name: 'search_recipes',
        description:
            'Search for Thermomix recipes on Cookidoo. Returns a list of '
            'matching recipes with title, rating, and total time.',
        parameters: {
          'type': 'object',
          'properties': {
            'query': {
              'type': 'string',
              'description': 'The search query (e.g. "chicken curry").',
            },
            'limit': {
              'type': 'integer',
              'description':
                  'Maximum number of results to return. Default 5.',
            },
          },
          'required': ['query'],
        },
      );

  @override
  Future<void> execute(
      Map<String, dynamic> args, BuildContext context) async {
    final query = args['query'] as String? ?? '';
    final limit = args['limit'] as int? ?? 5;

    debugPrint('>>> SearchRecipesHandler.execute called: query="$query" limit=$limit');

    try {
      final results =
          await _repository.searchRecipes(query, limit: limit);
      final summaries = results
          .map((r) => {
                'id': r.id,
                'title': r.title,
                'rating': r.rating,
                'totalTimeMinutes': r.totalTime ~/ 60,
              })
          .toList();
      debugPrint(
        '>>> SearchRecipesHandler: ${results.length} results for "$query"'
        '\n${jsonEncode(summaries)}',
      );
    } on CookidooNetworkException catch (e) {
      debugPrint('>>> SearchRecipesHandler: network error — $e');
    } catch (e) {
      debugPrint('>>> SearchRecipesHandler: unexpected error — $e');
    }
  }
}
