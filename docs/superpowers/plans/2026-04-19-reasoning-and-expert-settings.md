# Reasoning & Expert AI Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add two new AI settings items — a "Reasoning" toggle and an "Expert" dialog with generation config sliders (maxTokens, topK, topP, temperature) — and wire them into the model creation pipeline.

**Architecture:** Follow the existing storage → domain → provider → tile pattern. Reasoning is a standalone boolean preference. Expert groups 4 generation parameters into a single `ExpertConfig` domain class with one storage and one provider. Both are consumed in `conversation_page.dart` when creating the chat session, replacing the current hardcoded values. Model singleton is invalidated by closing the existing model before re-creating with new params.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, flutter_gemma

---

### Task 1: Add i18n keys to all ARB files

**Files:**
- Modify: `lib/l10n/app_en.arb:116` (after backend failure snackbar)
- Modify: `lib/l10n/app_fr.arb:38` (after backend failure snackbar)
- Modify: `lib/l10n/app_de.arb:38` (after backend failure snackbar)
- Modify: `lib/l10n/app_es.arb:38` (after backend failure snackbar)

- [ ] **Step 1: Add keys to app_en.arb**

Insert after the `settingsBackendChangeFailureSnackbar` entry:

```json
  "settingsReasoningTitle": "Reasoning",
  "@settingsReasoningTitle": { "description": "Title of the reasoning toggle setting tile." },

  "settingsReasoningSubtitleOn": "Enabled",
  "@settingsReasoningSubtitleOn": { "description": "Subtitle when reasoning is enabled." },

  "settingsReasoningSubtitleOff": "Disabled",
  "@settingsReasoningSubtitleOff": { "description": "Subtitle when reasoning is disabled." },

  "settingsExpertTitle": "Expert",
  "@settingsExpertTitle": { "description": "Title of the expert generation config setting tile." },

  "settingsExpertDialogTitle": "Generation parameters",
  "@settingsExpertDialogTitle": { "description": "Title of the expert settings dialog." },

  "settingsExpertMaxTokens": "Max tokens",
  "@settingsExpertMaxTokens": { "description": "Label for the max tokens slider." },

  "settingsExpertTopK": "Top-K",
  "@settingsExpertTopK": { "description": "Label for the Top-K slider." },

  "settingsExpertTopP": "Top-P",
  "@settingsExpertTopP": { "description": "Label for the Top-P slider." },

  "settingsExpertTemperature": "Temperature",
  "@settingsExpertTemperature": { "description": "Label for the temperature slider." },

  "settingsExpertChangeFailureSnackbar": "Couldn't save expert settings. Please try again.",
  "@settingsExpertChangeFailureSnackbar": { "description": "Shown when persisting expert config fails." },

  "settingsReasoningChangeFailureSnackbar": "Couldn't change reasoning setting. Please try again.",
  "@settingsReasoningChangeFailureSnackbar": { "description": "Shown when persisting reasoning preference fails." },
```

- [ ] **Step 2: Add keys to app_fr.arb**

Insert after the `settingsBackendChangeFailureSnackbar` entry:

```json
  "settingsReasoningTitle": "Raisonnement",
  "settingsReasoningSubtitleOn": "Activé",
  "settingsReasoningSubtitleOff": "Désactivé",
  "settingsExpertTitle": "Expert",
  "settingsExpertDialogTitle": "Paramètres de génération",
  "settingsExpertMaxTokens": "Tokens max",
  "settingsExpertTopK": "Top-K",
  "settingsExpertTopP": "Top-P",
  "settingsExpertTemperature": "Température",
  "settingsExpertChangeFailureSnackbar": "Impossible de sauvegarder les réglages expert. Réessayez.",
  "settingsReasoningChangeFailureSnackbar": "Impossible de changer le raisonnement. Réessayez.",
```

- [ ] **Step 3: Add keys to app_de.arb**

Insert after the `settingsBackendChangeFailureSnackbar` entry:

```json
  "settingsReasoningTitle": "Reasoning",
  "settingsReasoningSubtitleOn": "Aktiviert",
  "settingsReasoningSubtitleOff": "Deaktiviert",
  "settingsExpertTitle": "Expert",
  "settingsExpertDialogTitle": "Generierungsparameter",
  "settingsExpertMaxTokens": "Max. Tokens",
  "settingsExpertTopK": "Top-K",
  "settingsExpertTopP": "Top-P",
  "settingsExpertTemperature": "Temperatur",
  "settingsExpertChangeFailureSnackbar": "Experteinstellungen konnten nicht gespeichert werden. Bitte versuche es erneut.",
  "settingsReasoningChangeFailureSnackbar": "Reasoning konnte nicht geändert werden. Bitte versuche es erneut.",
```

- [ ] **Step 4: Add keys to app_es.arb**

Insert after the `settingsBackendChangeFailureSnackbar` entry:

```json
  "settingsReasoningTitle": "Razonamiento",
  "settingsReasoningSubtitleOn": "Activado",
  "settingsReasoningSubtitleOff": "Desactivado",
  "settingsExpertTitle": "Experto",
  "settingsExpertDialogTitle": "Parámetros de generación",
  "settingsExpertMaxTokens": "Tokens máx.",
  "settingsExpertTopK": "Top-K",
  "settingsExpertTopP": "Top-P",
  "settingsExpertTemperature": "Temperatura",
  "settingsExpertChangeFailureSnackbar": "No se pudieron guardar los ajustes expertos. Inténtalo de nuevo.",
  "settingsReasoningChangeFailureSnackbar": "No se pudo cambiar el razonamiento. Inténtalo de nuevo.",
```

- [ ] **Step 5: Run code generation**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter gen-l10n`
Expected: Generates updated `app_localizations*.dart` files with new getters.

- [ ] **Step 6: Commit**

```
feat(l10n): add reasoning and expert settings i18n keys
```

---

### Task 2: Create ExpertConfig domain class

**Files:**
- Create: `lib/features/chat/domain/expert_config.dart`
- Test: `test/features/chat/domain/expert_config_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/chat/domain/expert_config_test.dart`:

```dart
import 'package:cookmate/features/chat/domain/expert_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpertConfig', () {
    test('default values match spec', () {
      const config = ExpertConfig();

      expect(config.maxTokens, 8000);
      expect(config.topK, 64);
      expect(config.topP, 0.95);
      expect(config.temperature, 1.0);
    });

    test('copyWith replaces only specified fields', () {
      const config = ExpertConfig();
      final modified = config.copyWith(maxTokens: 4000, temperature: 0.5);

      expect(modified.maxTokens, 4000);
      expect(modified.topK, 64);
      expect(modified.topP, 0.95);
      expect(modified.temperature, 0.5);
    });

    test('equality works for identical values', () {
      const a = ExpertConfig();
      const b = ExpertConfig();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality fails for different values', () {
      const a = ExpertConfig();
      final b = a.copyWith(topK: 10);
      expect(a, isNot(equals(b)));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/domain/expert_config_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/chat/domain/expert_config.dart`:

```dart
class ExpertConfig {
  const ExpertConfig({
    this.maxTokens = defaultMaxTokens,
    this.topK = defaultTopK,
    this.topP = defaultTopP,
    this.temperature = defaultTemperature,
  });

  static const int defaultMaxTokens = 8000;
  static const int defaultTopK = 64;
  static const double defaultTopP = 0.95;
  static const double defaultTemperature = 1.0;

  final int maxTokens;
  final int topK;
  final double topP;
  final double temperature;

  ExpertConfig copyWith({
    int? maxTokens,
    int? topK,
    double? topP,
    double? temperature,
  }) {
    return ExpertConfig(
      maxTokens: maxTokens ?? this.maxTokens,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      temperature: temperature ?? this.temperature,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpertConfig &&
          other.maxTokens == maxTokens &&
          other.topK == topK &&
          other.topP == topP &&
          other.temperature == temperature;

  @override
  int get hashCode => Object.hash(maxTokens, topK, topP, temperature);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/domain/expert_config_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```
feat(chat): add ExpertConfig domain class
```

---

### Task 3: Create ReasoningPreferenceStorage

**Files:**
- Create: `lib/features/chat/data/reasoning_preference_storage.dart`
- Test: `test/features/chat/data/reasoning_preference_storage_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/chat/data/reasoning_preference_storage_test.dart`:

```dart
import 'package:cookmate/features/chat/data/reasoning_preference_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReasoningPreferenceStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    storage = ReasoningPreferenceStorage(prefs);
  });

  test('read returns true when nothing is stored', () {
    expect(storage.read(), true);
  });

  test('write then read returns the written value', () async {
    await storage.write(false);
    expect(storage.read(), false);
  });

  test('write overwrites a previous value', () async {
    await storage.write(false);
    await storage.write(true);
    expect(storage.read(), true);
  });

  test('read returns true when stored value is corrupted', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chat_reasoning_preference': 'not_a_bool',
    });
    final prefs = await SharedPreferences.getInstance();
    final s = ReasoningPreferenceStorage(prefs);

    expect(s.read(), true);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/data/reasoning_preference_storage_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/chat/data/reasoning_preference_storage.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReasoningPreferenceStorage {
  ReasoningPreferenceStorage(this._prefs);

  static const _key = 'chat_reasoning_preference';

  final SharedPreferences _prefs;

  bool read() {
    try {
      return _prefs.getBool(_key) ?? true;
    } catch (error, stack) {
      debugPrint('Failed to read reasoning preference: $error\n$stack');
      return true;
    }
  }

  Future<void> write(bool enabled) async {
    final didWrite = await _prefs.setBool(_key, enabled);
    if (!didWrite) {
      throw Exception('Failed to persist reasoning preference.');
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/data/reasoning_preference_storage_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```
feat(chat): add ReasoningPreferenceStorage
```

---

### Task 4: Create ExpertConfigStorage

**Files:**
- Create: `lib/features/chat/data/expert_config_storage.dart`
- Test: `test/features/chat/data/expert_config_storage_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/chat/data/expert_config_storage_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/data/expert_config_storage_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/chat/data/expert_config_storage.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/expert_config.dart';

class ExpertConfigStorage {
  ExpertConfigStorage(this._prefs);

  static const _keyMaxTokens = 'expert_max_tokens';
  static const _keyTopK = 'expert_top_k';
  static const _keyTopP = 'expert_top_p';
  static const _keyTemperature = 'expert_temperature';

  final SharedPreferences _prefs;

  ExpertConfig read() {
    try {
      return ExpertConfig(
        maxTokens: _prefs.getInt(_keyMaxTokens) ?? ExpertConfig.defaultMaxTokens,
        topK: _prefs.getInt(_keyTopK) ?? ExpertConfig.defaultTopK,
        topP: _prefs.getDouble(_keyTopP) ?? ExpertConfig.defaultTopP,
        temperature:
            _prefs.getDouble(_keyTemperature) ?? ExpertConfig.defaultTemperature,
      );
    } catch (error, stack) {
      debugPrint('Failed to read expert config: $error\n$stack');
      return const ExpertConfig();
    }
  }

  Future<void> write(ExpertConfig config) async {
    await _prefs.setInt(_keyMaxTokens, config.maxTokens);
    await _prefs.setInt(_keyTopK, config.topK);
    await _prefs.setDouble(_keyTopP, config.topP);
    await _prefs.setDouble(_keyTemperature, config.temperature);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/data/expert_config_storage_test.dart`
Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```
feat(chat): add ExpertConfigStorage
```

---

### Task 5: Add Riverpod providers for reasoning and expert config

**Files:**
- Modify: `lib/features/chat/providers.dart:142` (append after backend preference section)
- Modify: `test/features/chat/providers_test.dart:138` (append new test groups)

- [ ] **Step 1: Write the failing tests**

Append to `test/features/chat/providers_test.dart` before the closing `}` of `main()`:

```dart
  group('chatReasoningPreferenceProvider', () {
    test('builds with true when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final value =
          await container.read(chatReasoningPreferenceProvider.future);

      expect(value, true);
    });

    test('builds with stored value when one exists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'chat_reasoning_preference': false,
      });
      final container = createContainer();

      final value =
          await container.read(chatReasoningPreferenceProvider.future);

      expect(value, false);
    });

    test('setPreference updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(chatReasoningPreferenceProvider.future);

      await container
          .read(chatReasoningPreferenceProvider.notifier)
          .setPreference(false);

      expect(
        container.read(chatReasoningPreferenceProvider).valueOrNull,
        false,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('chat_reasoning_preference'), false);
    });
  });

  group('chatExpertConfigProvider', () {
    test('builds with defaults when nothing is stored', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();

      final value =
          await container.read(chatExpertConfigProvider.future);

      expect(value, const ExpertConfig());
    });

    test('builds with stored values when they exist', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'expert_max_tokens': 16000,
        'expert_top_k': 32,
        'expert_top_p': 0.8,
        'expert_temperature': 1.5,
      });
      final container = createContainer();

      final value =
          await container.read(chatExpertConfigProvider.future);

      expect(value.maxTokens, 16000);
      expect(value.topK, 32);
      expect(value.topP, 0.8);
      expect(value.temperature, 1.5);
    });

    test('setConfig updates state and persists', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = createContainer();
      await container.read(chatExpertConfigProvider.future);

      const newConfig = ExpertConfig(maxTokens: 4000, temperature: 0.5);
      await container
          .read(chatExpertConfigProvider.notifier)
          .setConfig(newConfig);

      expect(
        container.read(chatExpertConfigProvider).valueOrNull,
        newConfig,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('expert_max_tokens'), 4000);
      expect(prefs.getDouble('expert_temperature'), 0.5);
    });
  });
```

Also add these imports at the top of the test file:

```dart
import 'package:cookmate/features/chat/domain/expert_config.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/providers_test.dart`
Expected: FAIL — `chatReasoningPreferenceProvider` and `chatExpertConfigProvider` not found.

- [ ] **Step 3: Add providers to providers.dart**

Add imports at the top of `lib/features/chat/providers.dart`:

```dart
import 'data/expert_config_storage.dart';
import 'data/reasoning_preference_storage.dart';
import 'domain/expert_config.dart';
```

Append after the `chatBackendPreferenceProvider` declaration (after line 142):

```dart
// ── Reasoning preference ──

final chatReasoningPreferenceStorageProvider =
    FutureProvider<ReasoningPreferenceStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ReasoningPreferenceStorage(prefs);
});

class ChatReasoningPreferenceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final storage =
        await ref.watch(chatReasoningPreferenceStorageProvider.future);
    return storage.read();
  }

  Future<void> setPreference(bool enabled) async {
    final storage =
        await ref.read(chatReasoningPreferenceStorageProvider.future);
    state = const AsyncValue<bool>.loading().copyWithPrevious(state);
    try {
      await storage.write(enabled);
      state = AsyncValue.data(enabled);
    } catch (error, stack) {
      state =
          AsyncValue<bool>.error(error, stack).copyWithPrevious(state);
      rethrow;
    }
  }
}

final chatReasoningPreferenceProvider =
    AsyncNotifierProvider<ChatReasoningPreferenceNotifier, bool>(
  ChatReasoningPreferenceNotifier.new,
);

// ── Expert config ──

final chatExpertConfigStorageProvider =
    FutureProvider<ExpertConfigStorage>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return ExpertConfigStorage(prefs);
});

class ChatExpertConfigNotifier extends AsyncNotifier<ExpertConfig> {
  @override
  Future<ExpertConfig> build() async {
    final storage =
        await ref.watch(chatExpertConfigStorageProvider.future);
    return storage.read();
  }

  Future<void> setConfig(ExpertConfig config) async {
    final storage =
        await ref.read(chatExpertConfigStorageProvider.future);
    state = const AsyncValue<ExpertConfig>.loading().copyWithPrevious(state);
    try {
      await storage.write(config);
      state = AsyncValue.data(config);
    } catch (error, stack) {
      state = AsyncValue<ExpertConfig>.error(error, stack)
          .copyWithPrevious(state);
      rethrow;
    }
  }
}

final chatExpertConfigProvider =
    AsyncNotifierProvider<ChatExpertConfigNotifier, ExpertConfig>(
  ChatExpertConfigNotifier.new,
);
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/providers_test.dart`
Expected: All tests PASS (existing + 6 new).

- [ ] **Step 5: Commit**

```
feat(chat): add reasoning and expert config providers
```

---

### Task 6: Create ReasoningTile widget

**Files:**
- Create: `lib/features/chat/presentation/reasoning_tile.dart`
- Test: `test/features/chat/presentation/reasoning_tile_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/chat/presentation/reasoning_tile_test.dart`:

```dart
import 'package:cookmate/features/chat/presentation/reasoning_tile.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold));
  return AppLocalizations.of(context);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows enabled subtitle when reasoning is on by default',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ReasoningTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsReasoningTitle), findsOneWidget);
    expect(find.text(l10n.settingsReasoningSubtitleOn), findsOneWidget);
  });

  testWidgets('toggling switch persists false', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ReasoningTile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('chat_reasoning_preference'), false);
  });

  testWidgets('shows disabled subtitle when stored as false', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'chat_reasoning_preference': false,
    });

    await tester.pumpWidget(_wrap(const ReasoningTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsReasoningSubtitleOff), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/presentation/reasoning_tile_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/chat/presentation/reasoning_tile.dart`:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class ReasoningTile extends ConsumerWidget {
  const ReasoningTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reasoningAsync = ref.watch(chatReasoningPreferenceProvider);
    final enabled = reasoningAsync.valueOrNull ?? true;

    return SwitchListTile(
      secondary: const Icon(Icons.psychology_outlined),
      title: Text(l10n.settingsReasoningTitle),
      subtitle: Text(
        enabled
            ? l10n.settingsReasoningSubtitleOn
            : l10n.settingsReasoningSubtitleOff,
      ),
      value: enabled,
      onChanged: (value) async {
        try {
          await ref
              .read(chatReasoningPreferenceProvider.notifier)
              .setPreference(value);
        } catch (error, stack) {
          debugPrint('Failed to change reasoning: $error\n$stack');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.settingsReasoningChangeFailureSnackbar),
              ),
            );
          }
        }
      },
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/presentation/reasoning_tile_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```
feat(chat): add ReasoningTile widget
```

---

### Task 7: Create ExpertPickerTile widget

**Files:**
- Create: `lib/features/chat/presentation/expert_picker_tile.dart`
- Test: `test/features/chat/presentation/expert_picker_tile_test.dart`

- [ ] **Step 1: Write the failing widget test**

Create `test/features/chat/presentation/expert_picker_tile_test.dart`:

```dart
import 'package:cookmate/features/chat/presentation/expert_picker_tile.dart';
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

AppLocalizations _l10n(WidgetTester tester) {
  final context = tester.element(find.byType(Scaffold));
  return AppLocalizations.of(context);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows default summary in subtitle', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ExpertPickerTile()));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsExpertTitle), findsOneWidget);
    expect(find.textContaining('8000'), findsOneWidget);
    expect(find.textContaining('1.00'), findsOneWidget);
  });

  testWidgets('tapping opens dialog with sliders', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(_wrap(const ExpertPickerTile()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    final l10n = _l10n(tester);
    expect(find.text(l10n.settingsExpertDialogTitle), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(4));
  });

  testWidgets('shows stored values in subtitle', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'expert_max_tokens': 16000,
      'expert_top_k': 32,
      'expert_top_p': 0.8,
      'expert_temperature': 1.50,
    });

    await tester.pumpWidget(_wrap(const ExpertPickerTile()));
    await tester.pumpAndSettle();

    expect(find.textContaining('16000'), findsOneWidget);
    expect(find.textContaining('1.50'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/presentation/expert_picker_tile_test.dart`
Expected: FAIL — file not found.

- [ ] **Step 3: Write minimal implementation**

Create `lib/features/chat/presentation/expert_picker_tile.dart`:

```dart
import 'package:cookmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/expert_config.dart';
import '../providers.dart';

class ExpertPickerTile extends ConsumerWidget {
  const ExpertPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configAsync = ref.watch(chatExpertConfigProvider);
    final config = configAsync.valueOrNull ?? const ExpertConfig();

    return ListTile(
      leading: const Icon(Icons.tune_outlined),
      title: Text(l10n.settingsExpertTitle),
      subtitle: Text(
        'Tokens: ${config.maxTokens} · '
        'Temp: ${config.temperature.toStringAsFixed(2)}',
      ),
      onTap: () => _openDialog(context, ref, config),
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    WidgetRef ref,
    ExpertConfig current,
  ) async {
    final result = await showDialog<ExpertConfig>(
      context: context,
      builder: (dialogContext) => _ExpertDialog(initial: current),
    );

    if (!context.mounted) return;
    if (result == null || result == current) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(chatExpertConfigProvider.notifier)
          .setConfig(result);
    } catch (error, stack) {
      debugPrint('Failed to save expert config: $error\n$stack');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.settingsExpertChangeFailureSnackbar)),
      );
    }
  }
}

class _ExpertDialog extends StatefulWidget {
  const _ExpertDialog({required this.initial});

  final ExpertConfig initial;

  @override
  State<_ExpertDialog> createState() => _ExpertDialogState();
}

class _ExpertDialogState extends State<_ExpertDialog> {
  late int _maxTokens;
  late int _topK;
  late double _topP;
  late double _temperature;

  @override
  void initState() {
    super.initState();
    _maxTokens = widget.initial.maxTokens;
    _topK = widget.initial.topK;
    _topP = widget.initial.topP;
    _temperature = widget.initial.temperature;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.settingsExpertDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SliderRow(
              label: l10n.settingsExpertMaxTokens,
              value: _maxTokens.toDouble(),
              min: 4000,
              max: 30000,
              divisions: 26,
              displayValue: _maxTokens.toString(),
              onChanged: (v) => setState(() => _maxTokens = v.round()),
            ),
            _SliderRow(
              label: l10n.settingsExpertTopK,
              value: _topK.toDouble(),
              min: 5,
              max: 94,
              divisions: 89,
              displayValue: _topK.toString(),
              onChanged: (v) => setState(() => _topK = v.round()),
            ),
            _SliderRow(
              label: l10n.settingsExpertTopP,
              value: _topP,
              min: 0,
              max: 1,
              divisions: 100,
              displayValue: _topP.toStringAsFixed(2),
              onChanged: (v) =>
                  setState(() => _topP = double.parse(v.toStringAsFixed(2))),
            ),
            _SliderRow(
              label: l10n.settingsExpertTemperature,
              value: _temperature,
              min: 0,
              max: 2,
              divisions: 200,
              displayValue: _temperature.toStringAsFixed(2),
              onChanged: (v) => setState(
                  () => _temperature = double.parse(v.toStringAsFixed(2))),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            ExpertConfig(
              maxTokens: _maxTokens,
              topK: _topK,
              topP: _topP,
              temperature: _temperature,
            ),
          ),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(displayValue, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test test/features/chat/presentation/expert_picker_tile_test.dart`
Expected: All 3 tests PASS.

- [ ] **Step 5: Commit**

```
feat(chat): add ExpertPickerTile widget
```

---

### Task 8: Wire new tiles into settings page

**Files:**
- Modify: `lib/features/settings/presentation/settings_page.dart`

- [ ] **Step 1: Add imports**

Add to the top of `settings_page.dart`:

```dart
import '../../chat/presentation/reasoning_tile.dart';
import '../../chat/presentation/expert_picker_tile.dart';
```

- [ ] **Step 2: Add the new tiles after BackendPickerTile**

Replace the block between `const BackendPickerTile(),` and the General section padding with:

```dart
          const BackendPickerTile(),
          const Divider(height: 1),
          const ReasoningTile(),
          const Divider(height: 1),
          const ExpertPickerTile(),
          const Divider(height: 1),
```

- [ ] **Step 3: Run all tests**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```
feat(settings): add reasoning and expert tiles to AI section
```

---

### Task 9: Wire new settings into conversation_page.dart model creation

**Files:**
- Modify: `lib/features/chat/presentation/conversation_page.dart:143-177`

- [ ] **Step 1: Add provider reads in _createChat()**

In `_createChat()`, after reading `chatBackendPreferenceProvider` (line 145), add reads for the new providers:

```dart
      final reasoning =
          await ref.read(chatReasoningPreferenceProvider.future);
      final expertConfig =
          await ref.read(chatExpertConfigProvider.future);
```

- [ ] **Step 2: Replace hardcoded values in getActiveModel and createChat**

Replace the `getActiveModel` call:

```dart
          final model = await FlutterGemma.getActiveModel(
            maxTokens: expertConfig.maxTokens,
            preferredBackend: backend,
            supportImage: cfg.supportImage,
            supportAudio: cfg.supportAudio,
          );
```

Replace the `createChat` call:

```dart
          _chat = await model.createChat(
            temperature: expertConfig.temperature,
            topK: expertConfig.topK,
            topP: expertConfig.topP,
            systemInstruction: _systemPrompt,
            isThinking: reasoning,
            supportImage: cfg.supportImage,
            supportAudio: cfg.supportAudio,
          );
```

- [ ] **Step 3: Run all tests**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```
feat(chat): wire reasoning and expert config into model creation
```

---

### Task 10: Final verification

- [ ] **Step 1: Run full test suite**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run flutter analyze**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter analyze`
Expected: No issues found.

- [ ] **Step 3: Verify the app builds**

Run: `cd /Users/usingsystem/Repos/github/cookmate && flutter build apk --debug`
Expected: BUILD SUCCESSFUL.
