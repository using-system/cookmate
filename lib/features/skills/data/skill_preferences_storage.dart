import 'package:shared_preferences/shared_preferences.dart';

class SkillPreferencesStorage {
  SkillPreferencesStorage(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String skillName) => 'skill_enabled_$skillName';

  bool isEnabled(String skillName) {
    return _prefs.getBool(_key(skillName)) ?? false;
  }

  Future<void> setEnabled(String skillName, bool enabled) async {
    await _prefs.setBool(_key(skillName), enabled);
  }
}
