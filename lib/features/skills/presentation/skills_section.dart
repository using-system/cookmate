import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/skill.dart';
import '../domain/skill_loader.dart';

class SkillsSection extends StatefulWidget {
  const SkillsSection({super.key});

  @override
  State<SkillsSection> createState() => _SkillsSectionState();
}

class _SkillsSectionState extends State<SkillsSection> {
  List<Skill> _skills = [];
  SharedPreferences? _prefs;

  static String _key(String name) => 'skill_enabled_$name';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final skills = await SkillLoader.loadFromAssets(
      DefaultAssetBundle.of(context),
    );
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
            },
          ),
          const Divider(height: 1),
        ],
      ],
    );
  }
}
