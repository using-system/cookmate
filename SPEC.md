# Tech Stack

## Framework

- Flutter (Dart)
- Material 3

## State Management

- flutter_riverpod

## Navigation

- go_router

## Local Storage

- shared_preferences (key-value settings)
- sqflite (SQLite — chat history)

## On-Device AI

- flutter_gemma (Gemma 4 E2B / E4B inference, multimodal: vision + audio, function calling)

## Skill System

- Markdown-driven skills (`assets/skills/*/SKILL.md`) inject LLM instructions into the system prompt
- yaml (SKILL.md frontmatter parsing)

## Function Calling

- ToolHandler-based system: each tool = 1 handler file in `lib/features/tools/handlers/`
- ToolRegistry dispatches flutter_gemma `FunctionCallResponse` to matching handlers
- share_plus (native share sheet for Android/iOS)

## Cookidoo Integration

- http (REST client for Cookidoo recipe search and detail APIs)

## Chat UI

- flutter_chat_ui (Flyer Chat v2 — message list, composer, streaming)
- flutter_chat_core (message models, controller)
- flyer_chat_text_message (text bubble renderer)
- flyer_chat_text_stream_message (streaming AI response renderer)

## Media Input

- image_picker (camera capture + gallery selection)
- record (live audio recording)
- just_audio (audio playback in chat bubbles)

## Observability

- firebase_core (Firebase initialization)
- firebase_crashlytics (opt-in crash reporting)

## Internationalization

- flutter_localizations (ARB-based, 4 locales: en, fr, de, es)

## Build & CI

- GitHub Actions (CI + release workflows)
- Firebase App Distribution (signed APK)
- flutter_launcher_icons

## Testing

- flutter_test
- sqflite_common_ffi (SQLite test helper)

## Utilities

- path
- path_provider
- uuid
- cupertino_icons
