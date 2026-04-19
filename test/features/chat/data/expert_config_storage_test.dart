import 'package:cookmate/features/chat/data/expert_config_storage.dart';
import 'package:cookmate/features/chat/domain/expert_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ExpertConfigStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = ExpertConfigStorage(prefs);
  });

  test('read returns defaults when nothing is stored', () {
    final config = storage.read();
    expect(config.maxTokens, ExpertConfig.defaultMaxTokens);
    expect(config.topK, ExpertConfig.defaultTopK);
    expect(config.topP, ExpertConfig.defaultTopP);
    expect(config.temperature, ExpertConfig.defaultTemperature);
  });

  test('write then read returns the written config', () async {
    const config = ExpertConfig(
      maxTokens: 16000,
      topK: 32,
      topP: 0.8,
      temperature: 1.5,
    );
    await storage.write(config);
    final result = storage.read();
    expect(result, config);
  });

  test('write overwrites previous values', () async {
    const first = ExpertConfig(maxTokens: 4000);
    const second = ExpertConfig(maxTokens: 30000);
    await storage.write(first);
    await storage.write(second);
    expect(storage.read().maxTokens, 30000);
  });

  test('read returns defaults for corrupted values', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'expert_max_tokens': 'not_an_int',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = ExpertConfigStorage(prefs);
    final config = s.read();
    expect(config.maxTokens, ExpertConfig.defaultMaxTokens);
  });
}
