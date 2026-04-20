import 'package:cookmate/features/skills/domain/skill_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillLoader', () {
    group('parseSkillMd', () {
      test('parses valid SKILL.md with intent and parameters', () {
        const md = '''---
name: share-recipe
description: Share a recipe with another app.
intent: share
parameters:
  - name: title
    type: string
    description: The recipe title.
  - name: content
    type: string
    description: The full formatted recipe text.
---

# Share recipe

## Instructions

When the user asks to share a recipe, call run_intent.
''';

        final skill = SkillLoader.parseSkillMd(md);
        expect(skill.name, 'share-recipe');
        expect(skill.description, 'Share a recipe with another app.');
        expect(skill.intent, 'share');
        expect(skill.parameters, hasLength(2));
        expect(skill.parameters[0].name, 'title');
        expect(skill.parameters[0].type, 'string');
        expect(skill.parameters[1].name, 'content');
        expect(skill.instructions, contains('When the user asks'));
      });

      test('parses SKILL.md without intent (text-only skill)', () {
        const md = '''---
name: fitness-coach
description: A fitness coach persona.
---

You are a fitness coach.
''';

        final skill = SkillLoader.parseSkillMd(md);
        expect(skill.name, 'fitness-coach');
        expect(skill.intent, isNull);
        expect(skill.parameters, isEmpty);
        expect(skill.instructions, contains('fitness coach'));
      });

      test('throws on missing frontmatter', () {
        const md = '# No frontmatter here';
        expect(
          () => SkillLoader.parseSkillMd(md),
          throwsFormatException,
        );
      });

      test('throws on missing name', () {
        const md = '''---
description: Something.
---

Instructions.
''';
        expect(
          () => SkillLoader.parseSkillMd(md),
          throwsFormatException,
        );
      });
    });
  });
}
