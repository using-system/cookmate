import 'package:cookmate/features/skills/domain/skill.dart';
import 'package:cookmate/features/skills/domain/skill_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const shareSkill = Skill(
    name: 'share-recipe',
    description: 'Share a recipe with another app.',
    intent: 'share',
    parameters: [
      SkillParameter(name: 'title', type: 'string', description: 'The recipe title.'),
      SkillParameter(name: 'content', type: 'string', description: 'The recipe text.'),
    ],
    instructions: 'When the user asks to share, call run_intent with intent share.',
  );

  const textOnlySkill = Skill(
    name: 'fitness-coach',
    description: 'A fitness coach persona.',
    parameters: [],
    instructions: 'You are a fitness coach.',
  );

  group('SkillRegistry', () {
    test('buildSystemInstructions includes all skill descriptions and instructions', () {
      final registry = SkillRegistry([shareSkill, textOnlySkill]);
      final instructions = registry.buildSystemInstructions();
      expect(instructions, contains('share-recipe'));
      expect(instructions, contains('Share a recipe with another app.'));
      expect(instructions, contains('call run_intent'));
      expect(instructions, contains('fitness-coach'));
      expect(instructions, contains('fitness coach'));
    });

    test('buildTools creates run_intent tool with parameters from intent skills', () {
      final registry = SkillRegistry([shareSkill, textOnlySkill]);
      final tools = registry.buildTools();
      expect(tools, hasLength(1));
      expect(tools[0].name, 'run_intent');
      expect(tools[0].description, isNotEmpty);

      final props = (tools[0].parameters['properties'] as Map)['parameters'];
      expect(props, isNotNull);
    });

    test('buildTools returns empty list when no intent skills exist', () {
      final registry = SkillRegistry([textOnlySkill]);
      final tools = registry.buildTools();
      expect(tools, isEmpty);
    });

    test('findSkillByIntent returns correct skill', () {
      final registry = SkillRegistry([shareSkill, textOnlySkill]);
      expect(registry.findSkillByIntent('share'), shareSkill);
      expect(registry.findSkillByIntent('unknown'), isNull);
    });
  });
}
