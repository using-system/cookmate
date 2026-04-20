import 'package:cookmate/features/skills/domain/skill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillParameter', () {
    test('constructor sets all fields', () {
      const param = SkillParameter(
        name: 'title',
        type: 'string',
        description: 'The recipe title.',
      );
      expect(param.name, 'title');
      expect(param.type, 'string');
      expect(param.description, 'The recipe title.');
    });
  });

  group('Skill', () {
    test('constructor sets all fields', () {
      const skill = Skill(
        name: 'share-recipe',
        description: 'Share a recipe.',
        intent: 'share',
        parameters: [
          SkillParameter(
            name: 'title',
            type: 'string',
            description: 'The recipe title.',
          ),
        ],
        instructions: '# Share recipe\n\nCall run_intent.',
      );
      expect(skill.name, 'share-recipe');
      expect(skill.description, 'Share a recipe.');
      expect(skill.intent, 'share');
      expect(skill.parameters, hasLength(1));
      expect(skill.instructions, contains('Share recipe'));
    });

    test('skill without intent is valid (text-only skill)', () {
      const skill = Skill(
        name: 'fitness-coach',
        description: 'A fitness coach persona.',
        parameters: [],
        instructions: 'You are a fitness coach.',
      );
      expect(skill.intent, isNull);
    });
  });
}
