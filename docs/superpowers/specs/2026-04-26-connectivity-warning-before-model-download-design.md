# Connectivity Warning Before Model Download

## Problem

The LLM model download (1.5–3 GB) starts automatically without checking network
conditions. Users on mobile data may unknowingly consume a large amount of their
data plan. Users with no connection see a generic error only after the download
fails.

## Solution

Before starting the model download, check the device's connectivity state and
show an informative dialog when conditions are not ideal.

## Behavior

### WiFi connected

Download starts normally — no dialog shown.

### Mobile data (no WiFi)

An informative dialog is displayed:

- **Title:** Large download warning (localized)
- **Body:** The model download is large. A WiFi connection is recommended.
  (localized)
- **Actions:** "Cancel" (closes dialog, download does not start) / "Continue"
  (closes dialog, download starts)

The download does **not** start until the user taps "Continue".

### No connection

An informative dialog is displayed:

- **Title:** No connection (localized)
- **Body:** No internet connection. Connect to the internet to download the
  model. (localized)
- **Actions:** "OK" (closes dialog, download does not start)

The download does not start. The user can tap "Retry" (existing button from
error state) to re-trigger the connectivity check.

## Architecture

### Package

- `connectivity_plus` added to `pubspec.yaml`

### Implementation

All logic lives in `ModelDownloadPage._startDownload()`:

1. Call `Connectivity().checkConnectivity()` to get the current connectivity
   result.
2. If the result contains only `ConnectivityResult.none` → show "no connection"
   dialog, return early.
3. If the result does not contain `ConnectivityResult.wifi` (i.e., mobile data
   only) → show "large download" dialog. If user cancels, return early.
4. Otherwise (WiFi present) → proceed to download.

No new service or provider is needed — this is a single check at a single call
site.

### Localization

New ARB keys added to all four locale files (`en`, `es`, `fr`, `de`):

| Key | EN value |
|-----|----------|
| `chatModelDownloadNoConnectionTitle` | No internet connection |
| `chatModelDownloadNoConnectionBody` | Connect to the internet to download the AI model. |
| `chatModelDownloadMobileDataTitle` | Large download |
| `chatModelDownloadMobileDataBody` | The AI model download is large. A WiFi connection is recommended. |
| `chatModelDownloadContinue` | Continue |

Existing keys reused: `cancel`, `ok`.

### SPEC.md

Add `connectivity_plus` to the listed dependencies.

## What is NOT in scope

- No continuous connectivity monitoring (stream)
- No internet quality / reachability verification
- No display of downloaded or total file size
