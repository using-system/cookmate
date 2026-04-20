import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import 'skill.dart';

class SkillLoader {
  /// Parse a raw SKILL.md string into a [Skill].
  static Skill parseSkillMd(String raw) {
    final fmMatch =
        RegExp(r'^---\n(.*?)\n---\n?', dotAll: true).firstMatch(raw);
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

  /// Load all SKILL.md files from assets/skills/*/SKILL.md.
  static Future<List<Skill>> loadFromAssets(AssetBundle bundle) async {
    final manifestJson = await bundle.loadString('AssetManifest.json');
    final manifest = Map<String, dynamic>.from(
      Uri.splitQueryString(manifestJson).isEmpty
          ? {}
          : (manifestJson.startsWith('{'))
              ? _parseJsonMap(manifestJson)
              : {},
    );

    final skillPaths =
        manifest.keys.where((key) => key.endsWith('SKILL.md')).toList();

    final skills = <Skill>[];
    for (final path in skillPaths) {
      final raw = await bundle.loadString(path);
      skills.add(parseSkillMd(raw));
    }
    return skills;
  }

  static Map<String, dynamic> _parseJsonMap(String json) {
    final result = <String, dynamic>{};
    final regex = RegExp(r'"([^"]+)":\s*\[([^\]]*)\]');
    for (final match in regex.allMatches(json)) {
      result[match.group(1)!] = match.group(2);
    }
    return result;
  }
}
