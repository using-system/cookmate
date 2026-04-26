# Connectivity Warning Before Model Download — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Warn users before starting the LLM model download when they are on mobile data or have no internet connection.

**Architecture:** A one-shot connectivity check using `connectivity_plus` in `ModelDownloadPage._startDownload()`, gating the download behind an informative dialog. No new services, providers, or streams.

**Tech Stack:** connectivity_plus, Flutter Material dialogs, ARB localization

---

### Task 1: Add connectivity_plus dependency

**Files:**
- Modify: `pubspec.yaml:56` (add dependency)

- [ ] **Step 1: Add the package**

In `pubspec.yaml`, add `connectivity_plus` after `firebase_performance`:

```yaml
  firebase_performance: ^0.10.0+12
  connectivity_plus: ^6.1.4
```

- [ ] **Step 2: Install**

Run: `flutter pub get`
Expected: resolves successfully, no version conflicts.

- [ ] **Step 3: Commit**

```
feat(chat): add connectivity_plus dependency
```

---

### Task 2: Add localization strings

**Files:**
- Modify: `lib/l10n/app_en.arb:464-465`
- Modify: `lib/l10n/app_es.arb:154-155`
- Modify: `lib/l10n/app_fr.arb:154-155`
- Modify: `lib/l10n/app_de.arb:154-155`

Five new keys are needed. Existing keys `cancel`, `ok` are reused.

- [ ] **Step 1: Add English strings**

In `lib/l10n/app_en.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "chatModelDownloadNoConnectionTitle": "No internet connection",
  "@chatModelDownloadNoConnectionTitle": { "description": "Dialog title when there is no internet connection before model download." },

  "chatModelDownloadNoConnectionBody": "Connect to the internet to download the AI model.",
  "@chatModelDownloadNoConnectionBody": { "description": "Dialog body when there is no internet connection before model download." },

  "chatModelDownloadMobileDataTitle": "Large download",
  "@chatModelDownloadMobileDataTitle": { "description": "Dialog title warning about large download on mobile data." },

  "chatModelDownloadMobileDataBody": "The AI model download is large. A WiFi connection is recommended.",
  "@chatModelDownloadMobileDataBody": { "description": "Dialog body warning about large download on mobile data." },

  "chatModelDownloadContinue": "Continue",
  "@chatModelDownloadContinue": { "description": "Button label to proceed with download on mobile data." }
```

- [ ] **Step 2: Add Spanish strings**

In `lib/l10n/app_es.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "chatModelDownloadNoConnectionTitle": "Sin conexión a internet",
  "chatModelDownloadNoConnectionBody": "Conéctate a internet para descargar el modelo de IA.",
  "chatModelDownloadMobileDataTitle": "Descarga grande",
  "chatModelDownloadMobileDataBody": "La descarga del modelo de IA es grande. Se recomienda usar una conexión WiFi.",
  "chatModelDownloadContinue": "Continuar"
```

- [ ] **Step 3: Add French strings**

In `lib/l10n/app_fr.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "chatModelDownloadNoConnectionTitle": "Pas de connexion internet",
  "chatModelDownloadNoConnectionBody": "Connectez-vous à internet pour télécharger le modèle IA.",
  "chatModelDownloadMobileDataTitle": "Téléchargement volumineux",
  "chatModelDownloadMobileDataBody": "Le téléchargement du modèle IA est volumineux. Une connexion WiFi est recommandée.",
  "chatModelDownloadContinue": "Continuer"
```

- [ ] **Step 4: Add German strings**

In `lib/l10n/app_de.arb`, before the closing `}`, add a comma after the last entry and insert:

```json
  "chatModelDownloadNoConnectionTitle": "Keine Internetverbindung",
  "chatModelDownloadNoConnectionBody": "Verbinde dich mit dem Internet, um das KI-Modell herunterzuladen.",
  "chatModelDownloadMobileDataTitle": "Großer Download",
  "chatModelDownloadMobileDataBody": "Der Download des KI-Modells ist groß. Eine WLAN-Verbindung wird empfohlen.",
  "chatModelDownloadContinue": "Weiter"
```

- [ ] **Step 5: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: completes without errors, generates updated `AppLocalizations`.

- [ ] **Step 6: Commit**

```
feat(l10n): add connectivity warning strings for model download
```

---

### Task 3: Add connectivity check and dialogs to ModelDownloadPage

**Files:**
- Modify: `lib/features/chat/presentation/model_download_page.dart`

- [ ] **Step 1: Add imports**

At the top of `model_download_page.dart`, add the `connectivity_plus` import:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';
```

- [ ] **Step 2: Add the connectivity check method**

Inside `_ModelDownloadPageState`, add a new method after `_startDownload()`:

```dart
  /// Returns true if the download should proceed, false otherwise.
  Future<bool> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();

    if (results.contains(ConnectivityResult.none)) {
      if (!mounted) return false;
      final l10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.chatModelDownloadNoConnectionTitle),
          content: Text(l10n.chatModelDownloadNoConnectionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return false;
    }

    if (!results.contains(ConnectivityResult.wifi)) {
      if (!mounted) return false;
      final l10n = AppLocalizations.of(context);
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.chatModelDownloadMobileDataTitle),
          content: Text(l10n.chatModelDownloadMobileDataBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.chatModelDownloadContinue),
            ),
          ],
        ),
      );
      return proceed ?? false;
    }

    return true;
  }
```

- [ ] **Step 3: Gate the download behind the connectivity check**

Modify `_startDownload()` to call `_checkConnectivity()` before downloading. Replace the current method body:

```dart
  Future<void> _startDownload() async {
    setState(() {
      _error = null;
      _progress = 0;
    });

    final shouldProceed = await _checkConnectivity();
    if (!shouldProceed) return;

    try {
      final model = await ref.read(chatModelPreferenceProvider.future);

      await FlutterGemma.installModel(
        modelType: model.modelType,
        fileType: model.fileType,
      ).fromNetwork(model.url).withProgress((progress) {
        if (mounted) {
          setState(() => _progress = progress);
        }
      }).install();

      final storage =
          await ref.read(chatModelPreferenceStorageProvider.future);
      await storage.writeInstalled(model);

      if (mounted) {
        widget.onComplete();
      }
    } catch (e, stack) {
      debugPrint('Model download failed: $e\n$stack');
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }
```

- [ ] **Step 4: Verify the build compiles**

Run: `flutter build apk --debug 2>&1 | tail -5`
Expected: `BUILD SUCCESSFUL`

- [ ] **Step 5: Commit**

```
feat(chat): add connectivity check before model download
```

---

### Task 4: Update SPEC.md

**Files:**
- Modify: `SPEC.md`

- [ ] **Step 1: Add connectivity_plus to the Networking section**

In `SPEC.md`, add a new section after **Cookidoo Integration** and before **Chat UI**:

```markdown
## Connectivity

- connectivity_plus (network type detection before model download)
```

- [ ] **Step 2: Commit**

```
docs: add connectivity_plus to SPEC.md
```
