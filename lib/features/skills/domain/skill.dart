/// A skill provides LLM instructions loaded from a SKILL.md asset file.
///
/// Skills tell the LLM *when* and *how* to use tools — they do not define
/// the tools themselves. Tool definitions live in `features/tools/`.
class Skill {
  const Skill({
    required this.name,
    required this.description,
    required this.instructions,
  });

  final String name;
  final String description;
  final String instructions;
}
