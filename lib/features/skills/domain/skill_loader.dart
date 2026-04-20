import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import 'skill.dart';

/// Known skill asset paths. Add new skills here when adding a SKILL.md
/// to assets/skills/.
const _skillAssetPaths = [
  'assets/skills/share-recipe/SKILL.md',
  'assets/skills/recipe-format/SKILL.md',
];

class SkillLoader {
  /// Parse a raw SKILL.md string into a [Skill].
  static Skill parseSkillMd(String raw) {
    final fmMatch =
        RegExp(r'^---\r?\n(.*?)\r?\n---\r?\n?', dotAll: true).firstMatch(raw);
    if (fmMatch == null) {
      throw const FormatException('SKILL.md missing frontmatter delimiters.');
    }

    final yamlStr = fmMatch.group(1)!;
    final yamlMap = loadYaml(yamlStr) as YamlMap;

    final name = yamlMap['name'] as String?;
    if (name == null) {
      throw const FormatException('SKILL.md frontmatter missing "name".');
    }

    final description = yamlMap['description'] as String? ?? '';
    final instructions = raw.substring(fmMatch.end).trim();

    return Skill(
      name: name,
      description: description,
      instructions: instructions,
    );
  }

  /// Load all skills from known asset paths.
  static Future<List<Skill>> loadFromAssets(AssetBundle bundle) async {
    final skills = <Skill>[];
    for (final path in _skillAssetPaths) {
      try {
        final raw = await bundle.loadString(path);
        skills.add(parseSkillMd(raw));
      } on FlutterError {
        // Asset not found — skill may have been removed from pubspec.
      } catch (e) {
        debugPrint('SkillLoader: failed to load $path: $e');
      }
    }
    return skills;
  }
}
