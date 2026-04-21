import 'package:cookmate/features/recipe/data/recipe_config_storage.dart';
import 'package:cookmate/features/recipe/domain/recipe_config.dart';
import 'package:cookmate/features/recipe/domain/recipe_level.dart';
import 'package:cookmate/features/recipe/domain/tm_version.dart';
import 'package:cookmate/features/recipe/domain/unit_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecipeConfigStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = RecipeConfigStorage(prefs);
  });

  test('read returns default config when prefs are empty', () {
    final config = storage.read();
    expect(config.tmVersion, TmVersion.defaultValue);
    expect(config.unitSystem, UnitSystem.defaultValue);
    expect(config.portions, RecipeConfig.defaultPortions);
    expect(config.level, RecipeLevel.defaultValue);
    expect(config.dietaryRestrictions, '');
  });

  test('write then read roundtrip preserves all fields', () async {
    const config = RecipeConfig(
      tmVersion: TmVersion.tm5,
      unitSystem: UnitSystem.imperial,
      portions: 6,
      level: RecipeLevel.advanced,
      dietaryRestrictions: 'vegan, gluten-free',
    );
    await storage.write(config);
    final result = storage.read();
    expect(result, equals(config));
  });

  test('write overwrites previous values', () async {
    const first = RecipeConfig(tmVersion: TmVersion.tm5, portions: 4);
    const second = RecipeConfig(tmVersion: TmVersion.tm7, portions: 8);
    await storage.write(first);
    await storage.write(second);
    final result = storage.read();
    expect(result.tmVersion, TmVersion.tm7);
    expect(result.portions, 8);
  });

  test('read returns default config when stored enum value is unrecognised', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'recipe_tm_version': 'tm99',
      'recipe_unit_system': 'unknown',
      'recipe_level': 'expert',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = RecipeConfigStorage(prefs);
    final config = s.read();
    expect(config.tmVersion, TmVersion.defaultValue);
    expect(config.unitSystem, UnitSystem.defaultValue);
    expect(config.level, RecipeLevel.defaultValue);
  });

  test('read returns empty string for dietaryRestrictions when not stored', () {
    final config = storage.read();
    expect(config.dietaryRestrictions, '');
  });

  test('write then read preserves empty dietaryRestrictions', () async {
    const config = RecipeConfig(dietaryRestrictions: '');
    await storage.write(config);
    expect(storage.read().dietaryRestrictions, '');
  });
}
