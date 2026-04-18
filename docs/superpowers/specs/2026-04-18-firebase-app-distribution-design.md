# Firebase App Distribution (Phase 2) — Design

**Date:** 2026-04-18
**Status:** Approved

## Context

Phase 1 (see
[`2026-04-18-android-apk-github-release-design.md`](2026-04-18-android-apk-github-release-design.md))
ships a signed Android APK as an asset of every GitHub Release. The APK is
installable from any Android device via the latest-release URL, which works
for the maintainer but assumes the tester knows when a new release is
available and manually visits the page.

Phase 2 adds **Firebase App Distribution** as a second delivery channel on
top of the same APK. Firebase pushes a native install prompt (web or email)
to a registered tester as soon as a new release is published. Testers still
download the same APK that Phase 1 ships — the two channels differ only in
how the tester discovers the new version.

## Goals

- Push every semver-bumping release to Firebase App Distribution as soon
  as the GitHub Release is created, with the same APK produced by Phase
  1's `build-android` job.
- Notify a tester group managed in the Firebase console (no need to edit
  the workflow to add or remove testers).
- Surface the GitHub Release auto-generated notes to testers inside
  Firebase so they see the changelog before installing.
- Keep all Firebase credentials out of the repository.

## Non-Goals

- No Flutter / app-side Firebase SDK integration (no `google-services.json`,
  no Gradle plugin, no Firebase dependency in `pubspec.yaml`). App
  Distribution is a CI-side channel only.
- No iOS distribution (Phase 3 candidate, separate spec).
- No Firebase Analytics / Crashlytics / Auth / anything requiring the app
  to embed the Firebase SDK.
- No manual redistribution of a past tag (`workflow_dispatch`). Only
  automatic distribution on the release-bumping push.
- No per-tester email lists baked into the workflow. Tester membership is
  managed in the Firebase console.
- No changes to the APK itself (same signed universal APK as Phase 1).

## Tech Stack

- **Firebase project:** `cookmate-d8571`, with an Android app registered
  against `applicationId = com.cookmate.app`. A GCP service account
  (`firebase-adminsdk-fbsvc@cookmate-d8571.iam.gserviceaccount.com`) with
  the **Firebase App Distribution Admin** role performs the uploads.
- **Tester group:** `testers` (managed in the Firebase console). The
  maintainer is the initial tester; more can be added without touching
  this repository.
- **GitHub Action:** `wzieba/Firebase-Distribution-Github-Action` — a
  JavaScript action that wraps `firebase-tools` CLI. Accepts the service
  account JSON inline via `serviceCredentialsFileContent`, so no
  base64/file roundtrip is needed. SHA-pinned like every other action
  in the repo.

## Architecture

### Job graph

```
version ──► build-android ──► release ──► distribute-firebase
   │              │             │               │
   │              │             │               └─ upload cookmate-vX.Y.Z.apk
   │              │             │                  to Firebase App Distribution
   │              │             │                  + releaseNotes from GH Release body
   │              │             │                  + notify group "testers"
   │              │             │
   │              │             └─ create GitHub Release vX.Y.Z
   │              │                attach APK as asset
   │              │                generate release body (what Phase 2 reads)
   │              │
   │              └─ build signed APK (artifact: cookmate-apk)
   │
   └─ compute new_tag from Conventional Commits
```

All four jobs share the same `if: needs.version.outputs.new_tag != ''`
guard. A push with no `feat:` / `fix:` commit produces no tag, no APK, no
GitHub Release, no Firebase distribution.

`distribute-firebase` explicitly depends on `release` (not just on
`build-android`) because it reads the auto-generated release body from
the freshly created GitHub Release.

### `distribute-firebase` job

1. `actions/checkout` — needed so `gh release view` resolves against the
   right repository context. Shallow clone is fine.
2. `actions/download-artifact@<pin>` — download the `cookmate-apk`
   artifact produced by Phase 1's `build-android` job.
3. Fetch release notes: `gh release view "${TAG}" --json body --jq .body`
   and expose as a step output.
4. `wzieba/Firebase-Distribution-Github-Action@<pin>` — upload the APK
   with inputs:
   - `appId: ${{ secrets.FIREBASE_APP_ID }}`
   - `serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}`
   - `groups: testers`
   - `file: artifacts/cookmate-${TAG}.apk`
   - `releaseNotes: <output of step 3>`

Firebase then sends an email / push notification to every member of the
`testers` group with a one-tap install link.

### Permissions

`distribute-firebase` needs `contents: read` to run `gh release view`
against the repository. The workflow default is already `contents: read`,
so the job does not need to declare anything extra. No other scope is
required — the Firebase upload is authenticated by the service account,
not by `GITHUB_TOKEN`.

## Secrets

Provisioned at the repository level on `using-system/cookmate` before
implementation:

- `FIREBASE_SERVICE_ACCOUNT_JSON` — full JSON of the Firebase Admin SDK
  service account with the "Firebase App Distribution Admin" role on
  `cookmate-d8571`. Passed inline to the action via
  `serviceCredentialsFileContent`.
- `FIREBASE_APP_ID` — the Android app identifier from Firebase project
  settings (format `1:<project-number>:android:<hash>`). Not sensitive,
  stored as a secret only for operational consistency.

The local `~/.cookmate/firebase-sa.json` file is the maintainer's
backup — never committed and never referenced at build time. If it is
lost, it can be regenerated from the Firebase console.

## Files Touched

| File | Change |
|---|---|
| `.github/workflows/release.yaml` | Add a `distribute-firebase` job after `release`, gated on the same new-tag condition. |
| `.gitignore` | Add `firebase-sa.json` as a defense-in-depth entry, even though the file is never placed in the repository. |
| Flutter / Gradle / `pubspec.yaml` | **Unchanged.** |

## Risks and Mitigations

- **Two channels publish the same version.** Every release-bumping push
  produces a GitHub Release **and** a Firebase distribution. That is the
  intent: two audiences, two discovery paths. Testers can ignore the
  GitHub Release and still get the APK automatically.
- **Distribution failures should not block the GitHub Release.** Because
  `distribute-firebase` runs after `release`, a Firebase outage fails
  only the distribution step — the GitHub Release and APK asset are
  already published, so the maintainer retains the manual channel. This
  is the intended fail-soft shape.
- **Public repository.** The Firebase project itself remains private; the
  `testers` group is an explicit invite list. A public repo does not leak
  distribution access.
- **Service account key rotation.** The JSON key is long-lived. If it
  leaks or needs rotation, generate a new key in Firebase console, update
  the `FIREBASE_SERVICE_ACCOUNT_JSON` secret, and disable the previous
  key from GCP IAM. No code change required.

## Validation

Infrastructure-only change; no Flutter test impact. Validation is manual,
performed once after merge:

1. Land a `feat:` or `fix:` commit on `main` and confirm the `Release`
   workflow run on `main` reports success on all four jobs.
2. Confirm the registered tester receives a Firebase App Distribution
   email / push notification naming the new `vX.Y.Z`.
3. Confirm the Firebase App Distribution UI shows the release with the
   GitHub-generated notes in the release-notes panel.
4. Tap the tester install link on a physical Android device and confirm
   the APK installs, matches the version, and matches the APK attached
   to the GitHub Release (same SHA-256).
