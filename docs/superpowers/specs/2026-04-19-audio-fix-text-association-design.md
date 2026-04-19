# Audio Fix & Text Association Design

## Problem

Two issues with the current audio implementation in the chat feature:

1. **Audio not processed by model**: The app records in M4A (default `RecordConfig()`) but `flutter_gemma` expects WAV at 16kHz mono. Additionally, `supportAudio: true` is never passed to `getActiveModel()` or `createChat()`, so the model silently ignores audio bytes.
2. **No text association**: When recording stops, audio is immediately sent to the model with a hardcoded prompt (`chatAudioPrompt`). Users cannot type a contextual message to accompany the audio.

## Solution

### Fix 1: Enable audio support in the model

**Changes in `_createChat()`:**

- Pass `supportAudio: true` to `getActiveModel()` and `createChat()`, using the same try/fallback pattern as vision (`_visionAvailable`).
- Add `_audioAvailable` boolean state to track whether the model supports audio.
- Hide the "Record audio" option in `_showAttachmentSheet()` when `_audioAvailable` is `false`.

**Changes in `_toggleRecording()`:**

- Record in WAV format at 16kHz mono instead of M4A:
  ```dart
  RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: 16000,
    numChannels: 1,
  )
  ```
- Change file extension from `.m4a` to `.wav`.

### Fix 2: Audio chip in composer with text association

**UX flow:**

1. User records audio via attachment sheet.
2. On stop, audio is **not sent**. It is stored in `_pendingAudioPath` and `_pendingAudioBytes`.
3. A chip appears above the text input field (via `composerBuilder` with `Composer(topWidget: ...)`) showing: mic icon, "Audio message" label, and a dismiss (×) button.
4. User types optional text, then taps Send.
5. `_handleSend` detects pending audio and sends text + audio together via `gemma.Message.withAudio(text: userText, audioBytes: ...)`.
6. If no text is typed, the default `chatAudioPrompt` is used as fallback.
7. The chip is cleared after sending.

**New state fields:**

- `String? _pendingAudioPath` — file path of pending audio attachment.
- `Uint8List? _pendingAudioBytes` — raw bytes of pending audio.
- `bool _audioAvailable` — whether the model supports audio input.

**Persistence:** The audio message is persisted via `chatRepository.addAudioMessage()` at send time, same as today. No changes to `ChatMessage` model or repository.

**Composer customization:** Use `composerBuilder` in `Builders` to return a `Composer` with `topWidget` set to the audio chip when `_pendingAudioPath != null`. Also set `sendButtonVisibilityMode` to `SendButtonVisibilityMode.always` when audio is pending, so the user can send audio-only without typing text.

## Files impacted

| File | Change |
|------|--------|
| `lib/features/chat/presentation/conversation_page.dart` | Main logic: model init, recording, sending, composer |
| `lib/l10n/app_en.arb` | Add `chatAudioAttached` key |
| `lib/l10n/app_fr.arb` | Add `chatAudioAttached` key |
| `lib/l10n/app_de.arb` | Add `chatAudioAttached` key |
| `lib/l10n/app_es.arb` | Add `chatAudioAttached` key |

## Out of scope

- Audio playback preview before sending (can be added later).
- Audio transcription display in the chat bubble.
- Changes to `ChatMessage` domain model or database schema.
