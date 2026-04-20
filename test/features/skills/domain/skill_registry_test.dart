import 'package:cookmate/features/skills/domain/skill.dart';
import 'package:cookmate/features/skills/domain/skill_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const shareSkill = Skill(
    name: 'share-recipe',
    description: 'Share a recipe with another app.',
    instructions: 'When the user asks to share, call the share_recipe tool.',
  );

  const coachSkill = Skill(
    name: 'fitness-coach',
    description: 'A fitness coach persona.',
    instructions: 'You are a fitness coach.',
  );

  group('SkillRegistry', () {
    test('buildSystemInstructions includes all skills', () {
      final registry = SkillRegistry([shareSkill, coachSkill]);
      final instructions = registry.buildSystemInstructions();
      expect(instructions, contains('share-recipe'));
      expect(instructions, contains('Share a recipe with another app.'));
      expect(instructions, contains('share_recipe tool'));
      expect(instructions, contains('fitness-coach'));
      expect(instructions, contains('fitness coach'));
    });

    test('buildSystemInstructions returns empty for no skills', () {
      final registry = SkillRegistry([]);
      expect(registry.buildSystemInstructions(), isEmpty);
    });
  });
}
