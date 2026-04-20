# Skill System + Share Recipe — Design Spec

## Summary

Introduce an extensible skill system inspired by [Google AI Edge Gallery skills](https://github.com/google-ai-edge/gallery/tree/main/skills). Skills are defined as Markdown files (`SKILL.md`) in `assets/skills/`. The app loads them at startup, injects their metadata into the system prompt, registers their tools via flutter_gemma function calling, and routes `FunctionCallResponse` events to generic executors.

The first skill is `share-recipe`: the user asks the LLM to share a recipe, the LLM calls `run_intent` with intent `share`, and the app opens the native share sheet via `share_plus`.

## Goals

- **Markdown-driven skills** — adding a skill = adding a `SKILL.md` file, no Dart code required (as long as it uses an existing executor)
- **Extensible executor model** — generic executors (`run_intent`, future `run_js`) handle the actual platform actions
- **Native function calling** — uses flutter_gemma's built-in `Tool` / `FunctionCallResponse` API (Gemma 4 support)
- **Clean integration** — plugs into the existing chat flow with minimal changes to `conversation_page.dart` and `system_prompt_builder.dart`

## Non-Goals

- Skill marketplace / dynamic downloading (future)
- JavaScript executor (`run_js`) — out of scope for this iteration
- Skill-specific UI (custom widgets rendered by skills)

## Skill Definition Format

Each skill lives in `assets/skills/<skill-name>/SKILL.md`:

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
  - content: the full formatted recipe text. String.

Always format the recipe clearly before sharing: title, ingredients list, and numbered steps.
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | yes | Kebab-case unique identifier |
| `description` | yes | One-line description (injected in system prompt for LLM discovery) |
| `intent` | yes* | The intent name for `run_intent`-based skills |
| `parameters` | yes* | List of `{name, type, description}` for the tool's JSON schema |

*Required for intent-based skills. Future skill types (e.g. text-only persona skills) may omit these.

## Architecture

### Directory Structure

```
assets/skills/
└── share-recipe/
    └── SKILL.md

lib/features/skills/
├── domain/
│   ├── skill.dart              # Skill model (parsed from SKILL.md)
│   ├── skill_parameter.dart    # Parameter model (name, type, description)
│   ├── skill_loader.dart       # Parses SKILL.md files from assets
│   └── skill_registry.dart     # Central registry: all loaded skills
├── data/
│   └── executors/
│       └── intent_executor.dart  # Generic run_intent dispatcher
└── providers.dart              # Riverpod providers
```

### Data Flow

```
App startup
  → SkillLoader reads all assets/skills/*/SKILL.md
  → Parses frontmatter + instructions
  → SkillRegistry holds all Skill objects

Chat creation (_createChat)
  → buildSystemPrompt() unchanged
  → SkillRegistry.buildSystemInstructions() appended to prompt
  → SkillRegistry.buildTools() → List<Tool> for flutter_gemma
  → createChat(tools: tools, supportsFunctionCalls: true, toolChoice: ToolChoice.auto)

Streaming response
  → TextResponse        → display as today
  → ThinkingResponse    → display as today
  → FunctionCallResponse → SkillRegistry.execute(name, args, context)
                           → IntentExecutor.execute(intent, params)
                           → share_plus Share.share()
```

### Skill Model

```dart
class Skill {
  final String name;
  final String description;
  final String? intent;
  final List<SkillParameter> parameters;
  final String instructions;  // raw markdown after frontmatter
}

class SkillParameter {
  final String name;
  final String type;  // "string", "number", "boolean"
  final String description;
}
```

### Skill Loader

- Reads `AssetManifest` to discover all `assets/skills/*/SKILL.md` files
- Parses YAML frontmatter (between `---` delimiters)
- Extracts instructions from the markdown body
- Returns `List<Skill>`

### Skill Registry

```dart
class SkillRegistry {
  final List<Skill> skills;

  /// Builds the skill discovery block appended to the system prompt.
  /// Contains skill names + descriptions so the LLM knows what's available.
  String buildSystemInstructions();

  /// Converts all skill parameters into flutter_gemma Tool definitions.
  /// Registers one tool: `run_intent` with the union of all intent schemas.
  List<Tool> buildTools();

  /// Routes a FunctionCallResponse to the appropriate executor.
  Future<void> execute(String toolName, Map<String, dynamic> args, BuildContext context);
}
```

### Intent Executor

One generic executor that dispatches based on the `intent` field:

```dart
class IntentExecutor {
  static Future<void> execute(String intent, Map<String, dynamic> params, BuildContext context) async {
    switch (intent) {
      case 'share':
        await Share.share(
          params['content'] as String,
          subject: params['title'] as String?,
        );
      // Future intents: send_email, open_url, etc.
      default:
        debugPrint('Unknown intent: $intent');
    }
  }
}
```

### System Prompt Integration

The skill instructions are appended after the existing recipe system prompt:

```
[existing CookMate system prompt]

## Available Skills

The following skills are available. Use them when appropriate.

### share-recipe
Share a recipe with another app (WhatsApp, email, Telegram, etc.).

[SKILL.md instructions section]
```

### Chat Integration Changes

In `conversation_page.dart`, `_createChat()`:
1. Get skills from `skillRegistryProvider`
2. Append `registry.buildSystemInstructions()` to system prompt
3. Pass `registry.buildTools()` to `createChat(tools: ...)`

In `_streamAiResponse()`:
4. Handle `FunctionCallResponse` in the stream loop alongside `TextResponse` and `ThinkingResponse`

## Dependencies

- `share_plus` — native share sheet (Android/iOS)
- `yaml` — parse SKILL.md frontmatter

## Localization

Skill instructions stay in English (they are LLM-facing, not user-facing). The LLM already handles responding in the user's language via the existing system prompt.

No new ARB keys needed for this iteration — the share sheet is OS-native UI.

## Testing Strategy

- Unit test: `SkillLoader` parses a sample SKILL.md correctly
- Unit test: `SkillRegistry` builds correct system instructions and tools
- Unit test: `IntentExecutor.execute('share', ...)` can be called without crash
- Manual test: ask the LLM "partage cette recette" → share sheet opens with formatted recipe
