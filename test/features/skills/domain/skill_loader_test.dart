import 'package:cookmate/features/skills/domain/skill_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillLoader', () {
    group('parseSkillMd', () {
      test('parses valid SKILL.md', () {
        const md = '''---
name: share-recipe
description: Share a recipe with another app.
---

# Share recipe

## Instructions

When the user asks to share a recipe, call the share_recipe tool.
''';

        final skill = SkillLoader.parseSkillMd(md);
        expect(skill.name, 'share-recipe');
        expect(skill.description, 'Share a recipe with another app.');
        expect(skill.instructions, contains('When the user asks'));
      });

      test('ignores extra frontmatter fields', () {
        const md = '''---
name: share-recipe
description: Share a recipe.
some_future_field: ignored
---

Instructions here.
''';

        final skill = SkillLoader.parseSkillMd(md);
        expect(skill.name, 'share-recipe');
        expect(skill.instructions, contains('Instructions here'));
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
