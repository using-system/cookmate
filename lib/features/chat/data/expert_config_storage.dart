import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/expert_config.dart';

class ExpertConfigStorage {
  ExpertConfigStorage(this._prefs);

  static const _keyMaxTokens = 'expert_max_tokens';
  static const _keyTopK = 'expert_top_k';
  static const _keyTopP = 'expert_top_p';
  static const _keyTemperature = 'expert_temperature';
  static const _keyTokenBuffer = 'expert_token_buffer';

  final SharedPreferences _prefs;

  ExpertConfig read() {
    try {
      return ExpertConfig(
        maxTokens: _prefs.getInt(_keyMaxTokens) ?? ExpertConfig.defaultMaxTokens,
        topK: _prefs.getInt(_keyTopK) ?? ExpertConfig.defaultTopK,
        topP: _prefs.getDouble(_keyTopP) ?? ExpertConfig.defaultTopP,
        temperature:
            _prefs.getDouble(_keyTemperature) ?? ExpertConfig.defaultTemperature,
        tokenBuffer:
            _prefs.getInt(_keyTokenBuffer) ?? ExpertConfig.defaultTokenBuffer,
      );
    } catch (error, stack) {
      debugPrint('Failed to read expert config: $error\n$stack');
      return const ExpertConfig();
    }
  }

  Future<void> write(ExpertConfig config) async {
    if (!await _prefs.setInt(_keyMaxTokens, config.maxTokens)) {
      throw Exception('Failed to persist expert config maxTokens.');
    }
    if (!await _prefs.setInt(_keyTopK, config.topK)) {
      throw Exception('Failed to persist expert config topK.');
    }
    if (!await _prefs.setDouble(_keyTopP, config.topP)) {
      throw Exception('Failed to persist expert config topP.');
    }
    if (!await _prefs.setDouble(_keyTemperature, config.temperature)) {
      throw Exception('Failed to persist expert config temperature.');
    }
    if (!await _prefs.setInt(_keyTokenBuffer, config.tokenBuffer)) {
      throw Exception('Failed to persist expert config tokenBuffer.');
    }
  }
}
