import 'package:flutter_gemma/core/tool.dart';

import 'skill.dart';

class SkillRegistry {
  SkillRegistry(this.skills);

  final List<Skill> skills;

  String buildSystemInstructions() {
    if (skills.isEmpty) return '';

    final buffer = StringBuffer()
      ..writeln()
      ..writeln('## Available Skills')
      ..writeln()
      ..writeln('The following skills are available. Use them when appropriate.')
      ..writeln();

    for (final skill in skills) {
      buffer
        ..writeln('### ${skill.name}')
        ..writeln(skill.description)
        ..writeln()
        ..writeln(skill.instructions)
        ..writeln();
    }

    return buffer.toString();
  }

  List<Tool> buildTools() {
    final intentSkills = skills.where((s) => s.intent != null).toList();
    if (intentSkills.isEmpty) return [];

    final intentEnum = intentSkills.map((s) => s.intent!).toList();

    return [
      Tool(
        name: 'run_intent',
        description:
            'Execute a native device action. '
            'Available intents: ${intentEnum.join(", ")}.',
        parameters: {
          'type': 'object',
          'properties': {
            'intent': {
              'type': 'string',
              'description': 'The native action to perform.',
              'enum': intentEnum,
            },
            'parameters': {
              'type': 'string',
              'description':
                  'A JSON string containing the parameters for the intent.',
            },
          },
          'required': ['intent', 'parameters'],
        },
      ),
    ];
  }

  Skill? findSkillByIntent(String intent) {
    for (final skill in skills) {
      if (skill.intent == intent) return skill;
    }
    return null;
  }
}
