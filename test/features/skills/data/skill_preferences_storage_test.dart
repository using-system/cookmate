import 'package:cookmate/features/skills/data/skill_preferences_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SkillPreferencesStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = SkillPreferencesStorage(prefs);
  });

  test('isEnabled returns false by default', () {
    expect(storage.isEnabled('share_recipe'), isFalse);
    expect(storage.isEnabled('search_recipes'), isFalse);
  });

  test('setEnabled true + isEnabled returns true', () async {
    await storage.setEnabled('search_recipes', true);
    expect(storage.isEnabled('search_recipes'), isTrue);
  });

  test('setEnabled false + isEnabled returns false', () async {
    await storage.setEnabled('share_recipe', true);
    await storage.setEnabled('share_recipe', false);
    expect(storage.isEnabled('share_recipe'), isFalse);
  });

  test('skills are stored independently', () async {
    await storage.setEnabled('search_recipes', true);
    expect(storage.isEnabled('search_recipes'), isTrue);
    expect(storage.isEnabled('share_recipe'), isFalse);
  });

  test('roundtrip: enable then disable restores false', () async {
    await storage.setEnabled('get_recipe_detail', true);
    expect(storage.isEnabled('get_recipe_detail'), isTrue);
    await storage.setEnabled('get_recipe_detail', false);
    expect(storage.isEnabled('get_recipe_detail'), isFalse);
  });
}
