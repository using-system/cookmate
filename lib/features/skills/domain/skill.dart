class SkillParameter {
  const SkillParameter({
    required this.name,
    required this.type,
    required this.description,
  });

  final String name;
  final String type;
  final String description;
}

class Skill {
  const Skill({
    required this.name,
    required this.description,
    this.intent,
    required this.parameters,
    required this.instructions,
  });

  final String name;
  final String description;
  final String? intent;
  final List<SkillParameter> parameters;
  final String instructions;
}
