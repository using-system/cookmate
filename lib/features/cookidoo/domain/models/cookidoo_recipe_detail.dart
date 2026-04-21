class IngredientGroup {
  const IngredientGroup({required this.title, required this.ingredients});

  final String title;
  final List<Ingredient> ingredients;

  factory IngredientGroup.fromJson(Map<String, dynamic> json) {
    final items = (json['recipeIngredients'] as List<dynamic>?)
            ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return IngredientGroup(
      title: json['title'] as String? ?? '',
      ingredients: items,
    );
  }
}

class Ingredient {
  const Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  final String name;
  final double quantity;
  final String unit;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['ingredientNotation'] as String? ?? '',
      quantity: (json['quantity']?['value'] as num?)?.toDouble() ?? 0,
      unit: json['unitNotation'] as String? ?? '',
    );
  }
}

class StepGroup {
  const StepGroup({required this.title, required this.steps});

  final String title;
  final List<RecipeStep> steps;

  factory StepGroup.fromJson(Map<String, dynamic> json) {
    final items = (json['recipeSteps'] as List<dynamic>?)
            ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return StepGroup(title: json['title'] as String? ?? '', steps: items);
  }
}

class RecipeStep {
  const RecipeStep({required this.title, required this.text});

  final String title;
  final String text;

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      title: json['title'] as String? ?? '',
      text: json['formattedText'] as String? ?? '',
    );
  }
}

class NutritionInfo {
  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  factory NutritionInfo.fromJson(List<dynamic> nutritionGroups) {
    double kcal = 0, protein = 0, fat = 0, carbs = 0;
    for (final group in nutritionGroups) {
      final recipeNutritions =
          group['recipeNutritions'] as List<dynamic>? ?? [];
      for (final rn in recipeNutritions) {
        final nutritions = rn['nutritions'] as List<dynamic>? ?? [];
        for (final n in nutritions) {
          final type = n['type'] as String? ?? '';
          final number = (n['number'] as num?)?.toDouble() ?? 0;
          switch (type) {
            case 'kcal':
              kcal = number;
            case 'protein':
              protein = number;
            case 'fat':
              fat = number;
            case 'carbohydrates':
              carbs = number;
          }
        }
      }
    }
    return NutritionInfo(
        calories: kcal, protein: protein, fat: fat, carbs: carbs);
  }
}

class CookidooRecipeDetail {
  const CookidooRecipeDetail({
    required this.id,
    required this.title,
    required this.rating,
    required this.totalTime,
    required this.imageUrl,
    required this.servingSize,
    required this.ingredientGroups,
    required this.stepGroups,
    this.nutrition,
    required this.thermomixVersions,
  });

  final String id;
  final String title;
  final double rating;
  final int totalTime;
  final String imageUrl;
  final String servingSize;
  final List<IngredientGroup> ingredientGroups;
  final List<StepGroup> stepGroups;
  final NutritionInfo? nutrition;
  final List<String> thermomixVersions;

  factory CookidooRecipeDetail.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as String? ??
        (json['descriptiveAssets'] as List<dynamic>?)
            ?.firstOrNull
            ?['square'] as String? ??
        '';
    final servingSize = json['servingSize'] as Map<String, dynamic>?;
    final servingQty =
        servingSize?['quantity']?['value']?.toString() ?? '';
    final servingUnit = servingSize?['unitNotation'] as String? ?? '';

    final nutritionGroups = json['nutritionGroups'] as List<dynamic>?;

    return CookidooRecipeDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      rating: (json['aggregateRating']?['ratingValue'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          0,
      totalTime: _parseTotalTime(json),
      imageUrl: image.replaceAll(
        '{transformation}',
        't_web_rdp_recipe_584x480_1_5x',
      ),
      servingSize: '$servingQty $servingUnit'.trim(),
      ingredientGroups: (json['recipeIngredientGroups'] as List<dynamic>?)
              ?.map(
                  (e) => IngredientGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      stepGroups: (json['recipeStepGroups'] as List<dynamic>?)
              ?.map((e) => StepGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nutrition: nutritionGroups != null && nutritionGroups.isNotEmpty
          ? NutritionInfo.fromJson(nutritionGroups)
          : null,
      thermomixVersions: (json['thermomixVersions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  static int _parseTotalTime(Map<String, dynamic> json) {
    final times = json['times'] as List<dynamic>?;
    if (times != null) {
      for (final t in times) {
        if (t['type'] == 'totalTime') {
          return (t['quantity']?['value'] as num?)?.toInt() ?? 0;
        }
      }
    }
    return json['totalTime'] as int? ?? 0;
  }
}
