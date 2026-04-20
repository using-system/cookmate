import 'package:cookmate/features/skills/domain/skill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Skill', () {
    test('constructor sets all fields', () {
      const skill = Skill(
        name: 'share-recipe',
        description: 'Share a recipe.',
        instructions: '# Share recipe\n\nCall share_recipe tool.',
      );
      expect(skill.name, 'share-recipe');
      expect(skill.description, 'Share a recipe.');
      expect(skill.instructions, contains('Share recipe'));
    });
  });
}
