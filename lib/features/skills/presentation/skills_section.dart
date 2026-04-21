import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/skill.dart';
import '../providers.dart';

class SkillsSection extends ConsumerStatefulWidget {
  const SkillsSection({super.key});

  @override
  ConsumerState<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends ConsumerState<SkillsSection> {
  List<Skill> _skills = [];
  SharedPreferences? _prefs;

  static String _key(String name) => 'skill_enabled_$name';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final skills = await ref.read(allSkillsProvider.future);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _skills = skills;
      _prefs = prefs;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_prefs == null) return const SizedBox.shrink();

    return Column(
      children: [
        for (final skill in _skills) ...[
          SwitchListTile(
            title: Text(skill.name),
            subtitle: Text(
              skill.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            value: _prefs!.getBool(_key(skill.name)) ?? false,
            onChanged: (enabled) async {
              await _prefs!.setBool(_key(skill.name), enabled);
              setState(() {});
              // Invalidate so the chat picks up the change.
              ref.invalidate(skillPreferencesStorageProvider);
              ref.invalidate(skillRegistryProvider);
            },
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}
