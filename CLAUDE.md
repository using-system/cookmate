# Cookmate — Claude Code Guide

Cookmate is a Flutter mobile app (Android + iOS) — an AI chat assistant for Thermomix recipes, backed by Cookidoo and an on-device LLM.

## Internationalization — REQUIRED

Any UI-visible string MUST live in the ARB files under `lib/l10n/`, with the same key set mirrored across every supported locale. Never hardcode user-facing strings in widgets. Developer logs stay in English.

## Build, analyze, test

After any code change, both commands MUST be green locally before committing or pushing:

- `flutter analyze`
- `flutter test`

Tests mirror `lib/` under `test/` and are added or updated in the same change as the code.

## Git and PR conventions

- All committed artifacts (code, comments, docs, commit messages, PR titles/bodies) are in **English**, regardless of the conversation language.
- Commits, PR titles, and branch names follow [Conventional Commits](https://www.conventionalcommits.org/). Never commit directly on `main`.
