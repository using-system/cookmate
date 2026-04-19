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
