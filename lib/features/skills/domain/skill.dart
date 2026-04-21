/// A skill provides LLM instructions loaded from a SKILL.md asset file.
///
/// Skills tell the LLM *when* and *how* to use tools — they do not define
/// the tools themselves. Tool definitions live in `features/tools/`.
class Skill {
  const Skill({
    required this.name,
    required this.description,
    required this.instructions,
    this.tools = const [],
  });

  final String name;
  final String description;
  final String instructions;

  /// Tool handler names associated with this skill.
  /// When the skill is disabled, these tools are not registered.
  final List<String> tools;
}
