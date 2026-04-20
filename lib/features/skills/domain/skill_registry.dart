import 'skill.dart';

/// Central registry for LLM skill instructions.
///
/// Skills provide context and instructions that are appended to the system
/// prompt. They tell the LLM *when* and *how* to use available tools.
/// The tools themselves are managed independently by `features/tools/`.
class SkillRegistry {
  SkillRegistry(this.skills);

  final List<Skill> skills;

  /// Build the system prompt block that describes all available skills.
  String buildSystemInstructions() {
    if (skills.isEmpty) return '';

    final buffer = StringBuffer();

    for (final skill in skills) {
      buffer
        ..writeln('[${skill.name}] ${skill.description}')
        ..writeln(skill.instructions);
    }

    return buffer.toString();
  }
}
