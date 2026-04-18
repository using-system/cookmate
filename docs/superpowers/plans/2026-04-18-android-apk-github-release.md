# Android APK on GitHub Release (Phase 1) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a signed Android APK in CI on every release-bumping push to `main`, and attach it as an asset of the GitHub Release so the maintainer can install or update the app from any Android device via the latest-release URL.

**Architecture:** Add a `build-android` job between the existing `version` and `release` jobs in `.github/workflows/release.yaml`. The new job decodes the keystore from secrets, builds the APK with the version derived from the computed tag, uploads it as a workflow artifact, and `release` downloads it and passes it through `softprops/action-gh-release`'s `files:` input. Signing is wired via a conditional Gradle config in `android/app/build.gradle.kts` that reads `android/key.properties` when present and falls back to debug otherwise.

**Tech Stack:**
- GitHub Actions (`subosito/flutter-action`, `actions/upload-artifact`, `actions/download-artifact`, `softprops/action-gh-release`)
- Flutter 3.41.7 (matches existing CI workflow)
- Gradle Kotlin DSL (`android/app/build.gradle.kts`)
- PKCS12 upload keystore (already provisioned at `~/.cookmate/upload-keystore.jks` and as 4 GitHub secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`)

**Spec:** [`docs/superpowers/specs/2026-04-18-android-apk-github-release-design.md`](../specs/2026-04-18-android-apk-github-release-design.md)

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `android/app/build.gradle.kts` | Modify | Conditional release signing config: load `key.properties` if present, define a `release` signing config from it, fall back to debug signing when the file is absent. |
| `.github/workflows/release.yaml` | Modify | Add `build-android` job; modify `release` job to depend on it, download the APK artifact, and attach it to the GitHub Release. |
| `android/key.properties` | NOT committed | Created at runtime by the workflow from secrets. Already covered by `.gitignore` (`**/android/key.properties`). |
| `android/upload-keystore.jks` | NOT committed | Decoded at runtime by the workflow from `ANDROID_KEYSTORE_BASE64`. Already covered by `.gitignore` (`*.jks`). |
| `pubspec.yaml` | Unchanged | Version is overridden at build time via `--build-name` / `--build-number`. |

---

## Task 1: Update Gradle signing config

**Files:**
- Modify: `android/app/build.gradle.kts` (full rewrite, current 45 lines)

The Flutter Android module root is `android/`, so `rootProject.file("key.properties")` resolves to `android/key.properties` and `rootProject.file(<storeFile>)` resolves relative to `android/` — which keeps the `key.properties` content simple (`storeFile=upload-keystore.jks`).

- [ ] **Step 1: Replace `android/app/build.gradle.kts` with the conditional signing version**

```kotlin
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { load(it) }
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

android {
    namespace = "com.cookmate.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.cookmate.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
```

- [ ] **Step 2: Run `flutter analyze`**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Run `flutter test`**

Run: `flutter test`
Expected: All tests pass (current baseline).

- [ ] **Step 4: Verify the debug-fallback path of the release buildType compiles locally**

Run: `flutter build apk --release`
Expected: build succeeds, `build/app/outputs/flutter-apk/app-release.apk` is produced. Since `android/key.properties` does not exist locally, this exercises the `else` branch (`signingConfigs.getByName("debug")`) and proves the Gradle file parses end-to-end. The release-signing path will be exercised in CI on the next push to `main`.

- [ ] **Step 5: Commit**

```bash
git add android/app/build.gradle.kts
git commit -m "build(android): wire release signing from key.properties with debug fallback"
```

---

## Task 2: Add `build-android` job and wire `release` to consume it

**Files:**
- Modify: `.github/workflows/release.yaml` (currently 49 lines, full rewrite)

Action SHAs already resolved:
- `actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1`
- `actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1`
- Reused from existing workflows: `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2`, `subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0`, `softprops/action-gh-release@b4309332981a82ec1c5618f44dd2e27cc8bfbfda # v3.0.0`.

- [ ] **Step 1: Replace `.github/workflows/release.yaml` with the extended version**

```yaml
name: Release

on:
  push:
    branches: [main]

concurrency:
  group: release-${{ github.ref }}
  cancel-in-progress: false

permissions:
  contents: read

jobs:
  version:
    name: Version
    runs-on: ubuntu-latest
    permissions:
      contents: write
    outputs:
      new_tag: ${{ steps.tag.outputs.new_tag }}
      new_version: ${{ steps.tag.outputs.new_version }}
    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
        with:
          fetch-depth: 0
      - name: Compute next tag
        id: tag
        uses: mathieudutour/github-tag-action@d28fa2ccfbd16e871a4bdf35e11b3ad1bd56c0c1 # v6.2
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          default_bump: false
          tag_prefix: v

  build-android:
    name: Build Android APK
    needs: version
    if: needs.version.outputs.new_tag != ''
    runs-on: ubuntu-latest
    env:
      TAG: ${{ needs.version.outputs.new_tag }}
    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
      - name: Setup Flutter
        uses: subosito/flutter-action@1a449444c387b1966244ae4d4f8c696479add0b2 # v2.23.0
        with:
          channel: stable
          flutter-version: 3.41.7
          cache: true
      - name: Decode keystore
        env:
          KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 --decode > android/upload-keystore.jks
      - name: Write key.properties
        env:
          STORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          KEY_ALIAS: ${{ secrets.ANDROID_KEY_ALIAS }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
        run: |
          {
            echo "storeFile=upload-keystore.jks"
            echo "storePassword=${STORE_PASSWORD}"
            echo "keyAlias=${KEY_ALIAS}"
            echo "keyPassword=${KEY_PASSWORD}"
          } > android/key.properties
      - name: Install dependencies
        run: flutter pub get
      - name: Build APK
        run: |
          BUILD_NAME="${TAG#v}"
          flutter build apk --release \
            --build-name="${BUILD_NAME}" \
            --build-number="${GITHUB_RUN_NUMBER}"
      - name: Rename APK
        run: |
          mv build/app/outputs/flutter-apk/app-release.apk \
             "build/app/outputs/flutter-apk/cookmate-${TAG}.apk"
      - name: Upload APK artifact
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: cookmate-apk
          path: build/app/outputs/flutter-apk/cookmate-*.apk
          retention-days: 7
          if-no-files-found: error

  release:
    name: Release
    needs: [version, build-android]
    if: needs.version.outputs.new_tag != ''
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Download APK artifact
        uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: cookmate-apk
          path: artifacts
      - name: Create GitHub Release
        uses: softprops/action-gh-release@b4309332981a82ec1c5618f44dd2e27cc8bfbfda # v3.0.0
        with:
          tag_name: ${{ needs.version.outputs.new_tag }}
          name: ${{ needs.version.outputs.new_tag }}
          generate_release_notes: true
          files: artifacts/cookmate-*.apk
```

- [ ] **Step 2: Validate the workflow YAML parses and has the expected job graph**

Run: `python3 -c "import yaml,sys; d=yaml.safe_load(open('.github/workflows/release.yaml')); print('jobs:', list(d['jobs'].keys())); print('release.needs:', d['jobs']['release']['needs'])"`
Expected:
```
jobs: ['version', 'build-android', 'release']
release.needs: ['version', 'build-android']
```

- [ ] **Step 3: Verify no Flutter regression introduced (the workflow change should not affect Dart, but CLAUDE.md requires both commands stay green before commit)**

Run: `flutter analyze && flutter test`
Expected: analyze passes, all tests pass.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release.yaml
git commit -m "ci(release): build and attach signed android apk to github release"
```

---

## Task 3: Push branch and open pull request

- [ ] **Step 1: Push the feature branch with upstream tracking**

Run: `git push -u origin feat/release-android-apk`
Expected: branch created on `origin`, tracking set.

- [ ] **Step 2: Open the PR**

Run:
```bash
gh pr create --base main --head feat/release-android-apk \
  --title "feat(release): build signed android apk and attach to github release" \
  --body "$(cat <<'EOF'
## Summary

Phase 1 of the two-phase mobile distribution plan (spec:
[`docs/superpowers/specs/2026-04-18-android-apk-github-release-design.md`](docs/superpowers/specs/2026-04-18-android-apk-github-release-design.md)).

- New `build-android` job builds a signed release APK on every push to
  `main` that bumps the semantic version. Keystore and credentials are
  reconstituted from repository secrets at build time.
- `release` job now waits for `build-android` and attaches
  `cookmate-vX.Y.Z.apk` as an asset of the GitHub Release.
- `android/app/build.gradle.kts` gains a conditional release signing
  config: it loads `android/key.properties` when present and falls back
  to debug signing otherwise, so local development keeps working without
  any setup.

The APK can be installed from any Android device by visiting
`https://github.com/using-system/cookmate/releases/latest` and tapping
the attached file.

Phase 2 (Firebase App Distribution) will land in a separate PR and will
reuse the APK produced here.

## Test plan

- [ ] CI workflow (`analyze`, `test`, `lint-pr`) is green on the PR.
- [ ] After merge, the `Release` workflow on `main` produces a new tag
      `vX.Y.Z`, the `build-android` job uploads
      `cookmate-vX.Y.Z.apk`, and the GitHub Release page lists the APK
      as a downloadable asset.
- [ ] The APK installs on a physical Android device and the version
      shown in Settings → Apps → Cookmate matches `X.Y.Z`.
- [ ] A subsequent qualifying commit produces a second APK that
      installs in-place over the previous one without requiring an
      uninstall (proves stable signing).
EOF
)"
```
Expected: PR URL printed.

- [ ] **Step 3: Wait for CI checks to complete and report status**

Run: `gh pr checks --watch`
Expected: `lint-pr`, `analyze`, `test` all pass. If any fail, fix and push before merging.

---

## Task 4: Post-merge validation (manual, after PR is squash-merged)

This step is a one-time manual validation against the running production
workflow. It cannot be automated from this branch because the workflow
needs a release-bumping commit on `main` to trigger.

- [ ] **Step 1: Confirm the `Release` workflow run on `main` succeeds end-to-end**

Run: `gh run list --workflow=release.yaml --branch=main --limit=1`
Then: `gh run view <run-id>`
Expected: all three jobs (`version`, `build-android`, `release`) report success.

- [ ] **Step 2: Confirm the new tag exists**

Run: `git fetch --tags && git tag --list 'v*' --sort=-v:refname | head -1`
Expected: a new `vX.Y.Z` tag is the most recent.

- [ ] **Step 3: Confirm the APK is attached to the latest GitHub Release**

Run: `gh release view --json assets --jq '.assets[].name'`
Expected: list includes `cookmate-vX.Y.Z.apk`.

- [ ] **Step 4: Install and verify on a physical Android device**

From an Android device browser, open
`https://github.com/using-system/cookmate/releases/latest`, download the
APK, and install it (allow installation from unknown sources if prompted).
Open Settings → Apps → Cookmate and confirm the version matches `X.Y.Z`.

- [ ] **Step 5: Verify in-place upgrade**

After a subsequent qualifying commit lands on `main` and produces another
release, download and install the new APK on the same device without
uninstalling the previous version. The system installer should show
`Update` (not `Install`), and the upgrade should complete without an
`INSTALL_FAILED_UPDATE_INCOMPATIBLE` error. This proves the stable
signing chain.
