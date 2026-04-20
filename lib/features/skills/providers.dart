import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/skill_loader.dart';
import 'domain/skill_registry.dart';

final skillRegistryProvider = FutureProvider<SkillRegistry>((ref) async {
  final skills = await SkillLoader.loadFromAssets(rootBundle);
  return SkillRegistry(skills);
});
