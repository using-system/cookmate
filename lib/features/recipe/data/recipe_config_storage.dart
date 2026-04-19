import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recipe_config.dart';
import '../domain/recipe_level.dart';
import '../domain/tm_version.dart';
import '../domain/unit_system.dart';

class RecipeConfigStorage {
  RecipeConfigStorage(this._prefs);

  static const _keyTmVersion = 'recipe_tm_version';
  static const _keyUnitSystem = 'recipe_unit_system';
  static const _keyPortions = 'recipe_portions';
  static const _keyLevel = 'recipe_level';
  static const _keyDietaryRestrictions = 'recipe_dietary_restrictions';

  final SharedPreferences _prefs;

  RecipeConfig read() {
    try {
      return RecipeConfig(
        tmVersion: TmVersion.fromStorageValue(_prefs.getString(_keyTmVersion)),
        unitSystem:
            UnitSystem.fromStorageValue(_prefs.getString(_keyUnitSystem)),
        portions: _prefs.getInt(_keyPortions) ?? RecipeConfig.defaultPortions,
        level: RecipeLevel.fromStorageValue(_prefs.getString(_keyLevel)),
        dietaryRestrictions: _prefs.getString(_keyDietaryRestrictions) ?? '',
      );
    } catch (error, stack) {
      debugPrint('Failed to read recipe config: $error\n$stack');
      return const RecipeConfig();
    }
  }

  Future<void> write(RecipeConfig config) async {
    if (!await _prefs.setString(_keyTmVersion, config.tmVersion.toStorageValue())) {
      throw Exception('Failed to persist recipe tmVersion.');
    }
    if (!await _prefs.setString(_keyUnitSystem, config.unitSystem.toStorageValue())) {
      throw Exception('Failed to persist recipe unitSystem.');
    }
    if (!await _prefs.setInt(_keyPortions, config.portions)) {
      throw Exception('Failed to persist recipe portions.');
    }
    if (!await _prefs.setString(_keyLevel, config.level.toStorageValue())) {
      throw Exception('Failed to persist recipe level.');
    }
    if (!await _prefs.setString(_keyDietaryRestrictions, config.dietaryRestrictions)) {
      throw Exception('Failed to persist recipe dietaryRestrictions.');
    }
  }
}
