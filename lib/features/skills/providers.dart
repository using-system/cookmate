import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/shared_preferences_provider.dart';
import 'data/skill_preferences_storage.dart';
import 'domain/skill.dart';
import 'domain/skill_loader.dart';
import 'domain/skill_registry.dart';

/// All skills loaded from assets, regardless of enabled state.
final allSkillsProvider = FutureProvider<List<Skill>>((ref) async {
  return SkillLoader.loadFromAssets(rootBundle);
});

final skillPreferencesStorageProvider =
    FutureProvider<SkillPreferencesStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SkillPreferencesStorage(prefs);
});

/// Only enabled skills, used for system prompt and tool registration.
final skillRegistryProvider = FutureProvider<SkillRegistry>((ref) async {
  final allSkills = await ref.watch(allSkillsProvider.future);
  final storage = await ref.watch(skillPreferencesStorageProvider.future);

  final enabledSkills =
      allSkills.where((s) => storage.isEnabled(s.name)).toList();

  return SkillRegistry(enabledSkills);
});
