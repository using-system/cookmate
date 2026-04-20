# Skill System + Share Recipe Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an extensible skill system where skills are Markdown files, and ship the first `share-recipe` skill that opens the native share sheet via flutter_gemma function calling.

**Architecture:** Skills are `SKILL.md` asset files parsed at startup into a registry. The registry injects skill metadata into the system prompt and registers a generic `run_intent` tool with flutter_gemma. When the LLM emits a `FunctionCallResponse`, the registry routes it to an `IntentExecutor` that dispatches platform actions via `share_plus`.

**Tech Stack:** Flutter, flutter_gemma (function calling API), share_plus, yaml, Riverpod

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `lib/features/skills/domain/skill.dart` | `Skill` and `SkillParameter` data models |
| Create | `lib/features/skills/domain/skill_loader.dart` | Parse `SKILL.md` files from assets |
| Create | `lib/features/skills/domain/skill_registry.dart` | Central registry: system instructions, tools, routing |
| Create | `lib/features/skills/data/executors/intent_executor.dart` | Generic `run_intent` dispatcher (share, future intents) |
| Create | `lib/features/skills/providers.dart` | Riverpod providers for loader + registry |
| Create | `assets/skills/share-recipe/SKILL.md` | First skill definition |
| Create | `test/features/skills/domain/skill_test.dart` | Skill model tests |
| Create | `test/features/skills/domain/skill_loader_test.dart` | SKILL.md parsing tests |
| Create | `test/features/skills/domain/skill_registry_test.dart` | Registry logic tests |
| Modify | `pubspec.yaml` | Add `share_plus`, `yaml`, asset path |
| Modify | `lib/features/recipe/domain/system_prompt_builder.dart` | Accept optional skill instructions |
| Modify | `lib/features/chat/presentation/conversation_page.dart` | Wire tools + handle `FunctionCallResponse` |

---

### Task 1: Add dependencies and asset path

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add share_plus and yaml dependencies**

In `pubspec.yaml`, add under `dependencies:` (after `just_audio`):

```yaml
  share_plus: ^11.0.0
  yaml: ^3.1.0
```

- [ ] **Step 2: Add skills asset path**

In `pubspec.yaml`, under `flutter: > assets:`, add:

```yaml
    - assets/skills/share-recipe/
```

So the assets section becomes:

```yaml
  assets:
    - assets/icon/cookmate.png
    - assets/skills/share-recipe/
```

- [ ] **Step 3: Run pub get**

Run: `flutter pub get`
Expected: resolves without errors.

- [ ] **Step 4: Commit**

```
feat(skills): add share_plus and yaml dependencies
```

---

### Task 2: Create Skill and SkillParameter domain models

**Files:**
- Create: `test/features/skills/domain/skill_test.dart`
- Create: `lib/features/skills/domain/skill.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/skills/domain/skill_test.dart
import 'package:cookmate/features/skills/domain/skill.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillParameter', () {
    test('constructor sets all fields', () {
      const param = SkillParameter(
        name: 'title',
        type: 'string',
        description: 'The recipe title.',
      );
      expect(param.name, 'title');
      expect(param.type, 'string');
      expect(param.description, 'The recipe title.');
    });
  });

  group('Skill', () {
    test('constructor sets all fields', () {
      const skill = Skill(
        name: 'share-recipe',
        description: 'Share a recipe.',
        intent: 'share',
        parameters: [
          SkillParameter(
            name: 'title',
            type: 'string',
            description: 'The recipe title.',
          ),
        ],
        instructions: '# Share recipe\n\nCall run_intent.',
      );
      expect(skill.name, 'share-recipe');
      expect(skill.description, 'Share a recipe.');
      expect(skill.intent, 'share');
      expect(skill.parameters, hasLength(1));
      expect(skill.instructions, contains('Share recipe'));
    });

    test('skill without intent is valid (text-only skill)', () {
      const skill = Skill(
        name: 'fitness-coach',
        description: 'A fitness coach persona.',
        parameters: [],
        instructions: 'You are a fitness coach.',
      );
      expect(skill.intent, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/skills/domain/skill_test.dart`
Expected: FAIL — cannot find `skill.dart`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/skills/domain/skill.dart

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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/skills/domain/skill_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
feat(skills): add Skill and SkillParameter domain models
```

---

### Task 3: Create SkillLoader (parses SKILL.md from assets)

**Files:**
- Create: `test/features/skills/domain/skill_loader_test.dart`
- Create: `lib/features/skills/domain/skill_loader.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/skills/domain/skill_loader_test.dart
import 'package:cookmate/features/skills/domain/skill.dart';
import 'package:cookmate/features/skills/domain/skill_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkillLoader', () {
    group('parseSkillMd', () {
      test('parses valid SKILL.md with intent and parameters', () {
        const md = '''---
name: share-recipe
description: Share a recipe with another app.
intent: share
parameters:
  - name: title
    type: string
    description: The recipe title.
  - name: content
    type: string
    description: The full formatted recipe text.
---

# Share recipe

## Instructions

When the user asks to share a recipe, call run_intent.
''';

        final skill = SkillLoader.parseSkillMd(md);
        expect(skill.name, 'share-recipe');
        expect(skill.description, 'Share a recipe with another app.');
        expect(skill.intent, 'share');
        expect(skill.parameters, hasLength(2));
        expect(skill.parameters[0].name, 'title');
        expect(skill.parameters[0].type, 'string');
        expect(skill.parameters[1].name, 'content');
        expect(skill.instructions, contains('When the user asks'));
      });

      test('parses SKILL.md without intent (text-only skill)', () {
        const md = '''---
name: fitness-coach
description: A fitness coach persona.
---

You are a fitness coach.
''';

        final skill = SkillLoader.parseSkillMd(md);
        expect(skill.name, 'fitness-coach');
        expect(skill.intent, isNull);
        expect(skill.parameters, isEmpty);
        expect(skill.instructions, contains('fitness coach'));
      });

      test('throws on missing frontmatter', () {
        const md = '# No frontmatter here';
        expect(
          () => SkillLoader.parseSkillMd(md),
          throwsFormatException,
        );
      });

      test('throws on missing name', () {
        const md = '''---
description: Something.
---

Instructions.
''';
        expect(
          () => SkillLoader.parseSkillMd(md),
          throwsFormatException,
        );
      });
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/skills/domain/skill_loader_test.dart`
Expected: FAIL — cannot find `skill_loader.dart`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/skills/domain/skill_loader.dart
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import 'skill.dart';

class SkillLoader {
  /// Parse a raw SKILL.md string into a [Skill].
  static Skill parseSkillMd(String raw) {
    final fmMatch = RegExp(r'^---\n(.*?)\n---\n?', dotAll: true).firstMatch(raw);
    if (fmMatch == null) {
      throw const FormatException('SKILL.md missing frontmatter delimiters.');
    }

    final yamlStr = fmMatch.group(1)!;
    final yamlMap = loadYaml(yamlStr) as YamlMap;

    final name = yamlMap['name'] as String?;
    if (name == null) {
      throw const FormatException('SKILL.md frontmatter missing "name".');
    }

    final description = yamlMap['description'] as String? ?? '';
    final intent = yamlMap['intent'] as String?;

    final rawParams = yamlMap['parameters'] as YamlList?;
    final parameters = <SkillParameter>[];
    if (rawParams != null) {
      for (final p in rawParams) {
        final map = p as YamlMap;
        parameters.add(SkillParameter(
          name: map['name'] as String,
          type: map['type'] as String? ?? 'string',
          description: map['description'] as String? ?? '',
        ));
      }
    }

    final instructions = raw.substring(fmMatch.end).trim();

    return Skill(
      name: name,
      description: description,
      intent: intent,
      parameters: parameters,
      instructions: instructions,
    );
  }

  /// Load all SKILL.md files from assets/skills/*/SKILL.md.
  static Future<List<Skill>> loadFromAssets(AssetBundle bundle) async {
    final manifestJson = await bundle.loadString('AssetManifest.json');
    final manifest = Map<String, dynamic>.from(
      // ignore: avoid_dynamic_calls
      Uri.splitQueryString(manifestJson).isEmpty
          ? {}
          : (manifestJson.startsWith('{'))
              ? _parseJsonMap(manifestJson)
              : {},
    );

    final skillPaths = manifest.keys
        .where((key) => key.endsWith('SKILL.md'))
        .toList();

    final skills = <Skill>[];
    for (final path in skillPaths) {
      final raw = await bundle.loadString(path);
      skills.add(parseSkillMd(raw));
    }
    return skills;
  }

  static Map<String, dynamic> _parseJsonMap(String json) {
    // Minimal JSON map parser for AssetManifest.json.
    // Keys are asset paths, values are lists of variant paths.
    final result = <String, dynamic>{};
    final regex = RegExp(r'"([^"]+)":\s*\[([^\]]*)\]');
    for (final match in regex.allMatches(json)) {
      result[match.group(1)!] = match.group(2);
    }
    return result;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/skills/domain/skill_loader_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
feat(skills): add SkillLoader to parse SKILL.md files
```

---

### Task 4: Create SkillRegistry

**Files:**
- Create: `test/features/skills/domain/skill_registry_test.dart`
- Create: `lib/features/skills/domain/skill_registry.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/skills/domain/skill_registry_test.dart
import 'package:cookmate/features/skills/domain/skill.dart';
import 'package:cookmate/features/skills/domain/skill_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const shareSkill = Skill(
    name: 'share-recipe',
    description: 'Share a recipe with another app.',
    intent: 'share',
    parameters: [
      SkillParameter(name: 'title', type: 'string', description: 'The recipe title.'),
      SkillParameter(name: 'content', type: 'string', description: 'The recipe text.'),
    ],
    instructions: 'When the user asks to share, call run_intent with intent share.',
  );

  const textOnlySkill = Skill(
    name: 'fitness-coach',
    description: 'A fitness coach persona.',
    parameters: [],
    instructions: 'You are a fitness coach.',
  );

  group('SkillRegistry', () {
    test('buildSystemInstructions includes all skill descriptions and instructions', () {
      final registry = SkillRegistry([shareSkill, textOnlySkill]);
      final instructions = registry.buildSystemInstructions();
      expect(instructions, contains('share-recipe'));
      expect(instructions, contains('Share a recipe with another app.'));
      expect(instructions, contains('call run_intent'));
      expect(instructions, contains('fitness-coach'));
      expect(instructions, contains('fitness coach'));
    });

    test('buildTools creates run_intent tool with parameters from intent skills', () {
      final registry = SkillRegistry([shareSkill, textOnlySkill]);
      final tools = registry.buildTools();
      expect(tools, hasLength(1));
      expect(tools[0].name, 'run_intent');
      expect(tools[0].description, isNotEmpty);

      final props = (tools[0].parameters['properties'] as Map)['parameters'];
      expect(props, isNotNull);
    });

    test('buildTools returns empty list when no intent skills exist', () {
      final registry = SkillRegistry([textOnlySkill]);
      final tools = registry.buildTools();
      expect(tools, isEmpty);
    });

    test('findSkillByIntent returns correct skill', () {
      final registry = SkillRegistry([shareSkill, textOnlySkill]);
      expect(registry.findSkillByIntent('share'), shareSkill);
      expect(registry.findSkillByIntent('unknown'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/skills/domain/skill_registry_test.dart`
Expected: FAIL — cannot find `skill_registry.dart`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/skills/domain/skill_registry.dart
import 'package:flutter_gemma/core/tool.dart';

import 'skill.dart';

class SkillRegistry {
  SkillRegistry(this.skills);

  final List<Skill> skills;

  /// Build the system prompt block that describes all available skills.
  String buildSystemInstructions() {
    if (skills.isEmpty) return '';

    final buffer = StringBuffer()
      ..writeln()
      ..writeln('## Available Skills')
      ..writeln()
      ..writeln('The following skills are available. Use them when appropriate.')
      ..writeln();

    for (final skill in skills) {
      buffer
        ..writeln('### ${skill.name}')
        ..writeln(skill.description)
        ..writeln()
        ..writeln(skill.instructions)
        ..writeln();
    }

    return buffer.toString();
  }

  /// Build flutter_gemma [Tool] definitions from all intent-based skills.
  ///
  /// Registers a single `run_intent` tool whose `intent` enum contains all
  /// known intents, and whose `parameters` field accepts a free-form JSON
  /// string matching the skill's parameter schema.
  List<Tool> buildTools() {
    final intentSkills = skills.where((s) => s.intent != null).toList();
    if (intentSkills.isEmpty) return [];

    final intentEnum = intentSkills.map((s) => s.intent!).toList();

    return [
      Tool(
        name: 'run_intent',
        description:
            'Execute a native device action. '
            'Available intents: ${intentEnum.join(", ")}.',
        parameters: {
          'type': 'object',
          'properties': {
            'intent': {
              'type': 'string',
              'description': 'The native action to perform.',
              'enum': intentEnum,
            },
            'parameters': {
              'type': 'string',
              'description':
                  'A JSON string containing the parameters for the intent.',
            },
          },
          'required': ['intent', 'parameters'],
        },
      ),
    ];
  }

  /// Find a skill by its intent name.
  Skill? findSkillByIntent(String intent) {
    for (final skill in skills) {
      if (skill.intent == intent) return skill;
    }
    return null;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/skills/domain/skill_registry_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```
feat(skills): add SkillRegistry for tool building and prompt injection
```

---

### Task 5: Create IntentExecutor

**Files:**
- Create: `lib/features/skills/data/executors/intent_executor.dart`

- [ ] **Step 1: Write the implementation**

No unit test for this file — it wraps `share_plus` which requires a platform host. Tested manually in Task 8.

```dart
// lib/features/skills/data/executors/intent_executor.dart
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

class IntentExecutor {
  static Future<void> execute(
    String intent,
    String parametersJson,
    BuildContext context,
  ) async {
    final params = jsonDecode(parametersJson) as Map<String, dynamic>;

    switch (intent) {
      case 'share':
        final title = params['title'] as String? ?? '';
        final content = params['content'] as String? ?? '';
        final text = title.isNotEmpty ? '$title\n\n$content' : content;
        await SharePlus.instance.share(ShareParams(text: text));
      default:
        debugPrint('IntentExecutor: unknown intent "$intent"');
    }
  }
}
```

- [ ] **Step 2: Commit**

```
feat(skills): add IntentExecutor for native share dispatch
```

---

### Task 6: Create Riverpod providers

**Files:**
- Create: `lib/features/skills/providers.dart`

- [ ] **Step 1: Write the implementation**

```dart
// lib/features/skills/providers.dart
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/skill_loader.dart';
import 'domain/skill_registry.dart';

final skillRegistryProvider = FutureProvider<SkillRegistry>((ref) async {
  final skills = await SkillLoader.loadFromAssets(rootBundle);
  return SkillRegistry(skills);
});
```

- [ ] **Step 2: Commit**

```
feat(skills): add Riverpod skill registry provider
```

---

### Task 7: Create the share-recipe SKILL.md asset

**Files:**
- Create: `assets/skills/share-recipe/SKILL.md`

- [ ] **Step 1: Write the SKILL.md**

```markdown
---
name: share-recipe
description: Share a recipe with another app (WhatsApp, email, Telegram, etc.).
intent: share
parameters:
  - name: title
    type: string
    description: The recipe title.
  - name: content
    type: string
    description: The full formatted recipe text.
---

# Share recipe

## Instructions

When the user asks to share, send, or forward a recipe,
call the `run_intent` tool with the following exact parameters:

- intent: share
- parameters: A JSON string with the following fields:
  - title: the recipe title. String.
  - content: the full formatted recipe text, including ingredients and steps. String.

Always format the recipe clearly before sharing: title, ingredients list,
and numbered Thermomix steps with temperature, speed and duration.
```

- [ ] **Step 2: Commit**

```
feat(skills): add share-recipe SKILL.md definition
```

---

### Task 8: Integrate skills into the chat flow

**Files:**
- Modify: `lib/features/recipe/domain/system_prompt_builder.dart`
- Modify: `lib/features/chat/presentation/conversation_page.dart`

- [ ] **Step 1: Update system prompt builder to accept skill instructions**

In `lib/features/recipe/domain/system_prompt_builder.dart`, add an optional `skillInstructions` parameter:

Change the function signature from:

```dart
String buildSystemPrompt({
  required RecipeConfig config,
  required String language,
}) {
```

to:

```dart
String buildSystemPrompt({
  required RecipeConfig config,
  required String language,
  String skillInstructions = '',
}) {
```

Then append `$skillInstructions` at the very end of the template string, just before the closing `'''`:

```dart
## Format de réponse attendu
Pour l'instant contente toi d'afficher la recette directement dans le chat
$skillInstructions''';
```

- [ ] **Step 2: Wire skills into `_createChat()` in conversation_page.dart**

Add the import at the top of `conversation_page.dart`:

```dart
import '../../skills/providers.dart';
import '../../skills/data/executors/intent_executor.dart';
```

In `_createChat()`, after loading `recipeConfig`, load the skill registry:

```dart
final skillRegistry = await ref.read(skillRegistryProvider.future);
```

Update the `buildSystemPrompt` call to include skill instructions:

```dart
final systemPrompt = buildSystemPrompt(
  config: recipeConfig,
  language: languageName,
  skillInstructions: skillRegistry.buildSystemInstructions(),
);
```

Get the tools list:

```dart
final skillTools = skillRegistry.buildTools();
```

In each `createChat` call inside the `configs` loop, add the tools parameters:

```dart
_chat = await model.createChat(
  temperature: expertConfig.temperature,
  topK: expertConfig.topK,
  topP: expertConfig.topP,
  systemInstruction: systemPrompt,
  isThinking: reasoning,
  supportImage: cfg.supportImage,
  supportAudio: cfg.supportAudio,
  tools: skillTools,
  supportsFunctionCalls: skillTools.isNotEmpty,
  toolChoice: ToolChoice.auto,
);
```

Add the `ToolChoice` import at the top:

```dart
import 'package:flutter_gemma/core/tool.dart';
```

- [ ] **Step 3: Handle FunctionCallResponse in `_streamAiResponse()`**

In the `_streamAiResponse()` method, inside the `await for (final response in _chat!.generateChatResponseAsync())` loop, add handling for `FunctionCallResponse` after the existing `TextResponse` block:

```dart
} else if (response is FunctionCallResponse) {
  if (response.name == 'run_intent' && mounted) {
    final intent = response.args['intent'] as String? ?? '';
    final params = response.args['parameters'] as String? ?? '{}';
    await IntentExecutor.execute(intent, params, context);
  }
} else if (response is ParallelFunctionCallResponse) {
  if (!mounted) continue;
  for (final call in response.calls) {
    if (call.name == 'run_intent') {
      final intent = call.args['intent'] as String? ?? '';
      final params = call.args['parameters'] as String? ?? '{}';
      await IntentExecutor.execute(intent, params, context);
    }
  }
}
```

Add the import for the response types:

```dart
import 'package:flutter_gemma/core/model_response.dart';
```

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: all existing tests still pass.

- [ ] **Step 5: Commit**

```
feat(skills): integrate skill system into chat flow
```

---

### Task 9: Manual end-to-end test

- [ ] **Step 1: Build and launch the app**

Run: `flutter run`

- [ ] **Step 2: Test the share flow**

1. Open a conversation
2. Ask the LLM to create a recipe (e.g., "Donne moi une recette de gâteau au chocolat")
3. Wait for the recipe response
4. Ask "Partage cette recette"
5. Verify: the native share sheet opens with the formatted recipe text
6. Verify: selecting WhatsApp/email/Telegram sends the formatted text

- [ ] **Step 3: Test edge cases**

1. Ask "envoie cette recette par WhatsApp" — should also trigger share
2. Ask "quel temps fait-il ?" — should NOT trigger share (polite refusal as before)
3. Start a new conversation without a recipe and ask "partage la recette" — LLM should explain there's no recipe to share

---

### Task 10: Update SPEC.md

**Files:**
- Modify: `SPEC.md`

- [ ] **Step 1: Add skill system and new dependencies to SPEC.md**

Add a section documenting the skill system architecture and the new `share_plus` and `yaml` dependencies.

- [ ] **Step 2: Commit**

```
docs: update SPEC.md with skill system and new dependencies
```
