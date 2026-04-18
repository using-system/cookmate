# Firebase App Distribution (Phase 2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Push every signed APK produced by Phase 1 to Firebase App Distribution as soon as its GitHub Release is created, notifying the `testers` tester group with the GitHub-generated release notes.

**Architecture:** Extend `.github/workflows/release.yaml` with a fourth job `distribute-firebase` that runs after `release`. It downloads the same APK artifact Phase 1's `build-android` uploaded, fetches the GitHub Release body via `gh release view`, and uploads both to Firebase using the Docker-based action `wzieba/Firebase-Distribution-Github-Action`. The Firebase project, service account, tester group, and the two required secrets (`FIREBASE_SERVICE_ACCOUNT_JSON`, `FIREBASE_APP_ID`) are already provisioned.

**Tech Stack:**
- GitHub Actions (`actions/checkout`, `actions/download-artifact`, `wzieba/Firebase-Distribution-Github-Action`)
- `gh` CLI (preinstalled on `ubuntu-latest`) for reading the GitHub Release body
- Firebase project `cookmate-d8571`, Android app `com.cookmate.app`, tester group `testers`

**Spec:** [`docs/superpowers/specs/2026-04-18-firebase-app-distribution-design.md`](../specs/2026-04-18-firebase-app-distribution-design.md)

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `.gitignore` | Modify | Add `firebase-sa.json` as a defense-in-depth entry next to the existing keystore entries. Even though the service account JSON lives outside the repo, this guards against an accidental `git add firebase-sa.json` if a maintainer ever copies the file into the working tree. |
| `.github/workflows/release.yaml` | Modify | Append a `distribute-firebase` job after `release`. |
| `docs/superpowers/specs/2026-04-18-firebase-app-distribution-design.md` | Unchanged | Already committed on this branch. |
| Flutter / Gradle / `pubspec.yaml` | Unchanged | No app-side Firebase SDK. |

---

## Task 1: Harden `.gitignore` against accidental service account commits

**Files:**
- Modify: `.gitignore` (insert next to the existing `*.jks` / `**/android/key.properties` lines around lines 60–62)

- [ ] **Step 1: Inspect the current state of the relevant `.gitignore` region**

Run: `grep -n -E 'key\.properties|\.jks|firebase' .gitignore`
Expected output:
```
61:**/android/key.properties
62:*.jks
```
(no `firebase` line yet)

- [ ] **Step 2: Append the new ignore line after `*.jks`**

Use the Edit tool (or equivalent) to replace:

```
**/android/key.properties
*.jks
```

with:

```
**/android/key.properties
*.jks
firebase-sa.json
```

- [ ] **Step 3: Verify the entry is present and git honours it**

Run: `grep -n -E 'firebase-sa\.json' .gitignore`
Expected: `63:firebase-sa.json`

Then:
Run: `touch firebase-sa.json && git check-ignore -v firebase-sa.json && rm firebase-sa.json`
Expected:
```
.gitignore:63:firebase-sa.json	firebase-sa.json
```
(the line number might differ by one; what matters is that `git check-ignore` confirms the match before we delete the probe file).

- [ ] **Step 4: Commit**

```bash
git add .gitignore
git commit -m "$(cat <<'EOF'
chore(repo): ignore firebase-sa.json alongside the signing keystore

Defense-in-depth entry so the Firebase service account JSON cannot be
accidentally staged if a maintainer ever copies it into the working
tree. The file normally lives at ~/.cookmate/firebase-sa.json, outside
the repository.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Add the `distribute-firebase` job

**Files:**
- Modify: `.github/workflows/release.yaml` (append a new job after the existing `release` job, approximately after line 108)

Action SHA already resolved:
- `wzieba/Firebase-Distribution-Github-Action@bd494989dd4bec0343f78adee87fe66e48279ad6 # v1.7.1`

Reused from existing workflow:
- `actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2`
- `actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1`

- [ ] **Step 1: Read the current tail of `release.yaml` to confirm insertion point**

Run: `tail -20 .github/workflows/release.yaml`
Expected (abridged):
```yaml
  release:
    name: Release
    needs: [version, build-android]
    ...
      - name: Create GitHub Release
        uses: softprops/action-gh-release@b4309332981a82ec1c5618f44dd2e27cc8bfbfda # v3.0.0
        with:
          tag_name: ${{ needs.version.outputs.new_tag }}
          name: ${{ needs.version.outputs.new_tag }}
          generate_release_notes: true
          files: artifacts/cookmate-*.apk
```

Confirm the file ends with the `files: artifacts/cookmate-*.apk` line (and a trailing newline).

- [ ] **Step 2: Append the `distribute-firebase` job at the end of `.github/workflows/release.yaml`**

Use the Edit tool to add the following block **after** the last line of the `release` job (after `files: artifacts/cookmate-*.apk`):

```yaml

  distribute-firebase:
    name: Distribute to Firebase App Distribution
    needs: [version, build-android, release]
    if: needs.version.outputs.new_tag != ''
    runs-on: ubuntu-latest
    env:
      TAG: ${{ needs.version.outputs.new_tag }}
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    steps:
      - name: Checkout
        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6.0.2
      - name: Download APK artifact
        uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: cookmate-apk
          path: artifacts
      - name: Fetch GitHub Release notes
        id: notes
        run: |
          {
            echo "body<<COOKMATE_RELEASE_NOTES_EOF"
            gh release view "$TAG" --json body --jq .body
            echo "COOKMATE_RELEASE_NOTES_EOF"
          } >> "$GITHUB_OUTPUT"
      - name: Upload APK to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@bd494989dd4bec0343f78adee87fe66e48279ad6 # v1.7.1
        with:
          appId: ${{ secrets.FIREBASE_APP_ID }}
          serviceCredentialsFileContent: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_JSON }}
          groups: testers
          file: artifacts/cookmate-${{ needs.version.outputs.new_tag }}.apk
          releaseNotes: ${{ steps.notes.outputs.body }}
```

Rationale for specific choices:

- `needs: [version, build-android, release]` because the step reads the GitHub Release body produced by `release`.
- `if:` guard mirrors the other three jobs so chore-only pushes skip the whole pipeline cleanly.
- `GH_TOKEN` is the canonical env var for `gh` CLI in Actions; setting it from `secrets.GITHUB_TOKEN` gives the job just enough scope to call `repos/<owner>/<repo>/releases`.
- The heredoc delimiter `COOKMATE_RELEASE_NOTES_EOF` is a unique sentinel that cannot collide with Markdown content in an auto-generated release body (GitHub's generator never emits that string).
- `groups: testers` matches the tester group created in the Firebase console.
- `file:` interpolates the tag directly into the APK name the Phase 1 job produced (`cookmate-vX.Y.Z.apk`).

- [ ] **Step 3: Validate the workflow YAML still parses and the job graph is extended, not broken**

Run:
```bash
ruby -ryaml -e "d = YAML.load_file('.github/workflows/release.yaml'); puts 'jobs: ' + d['jobs'].keys.inspect; puts 'distribute-firebase.needs: ' + d['jobs']['distribute-firebase']['needs'].inspect; puts 'distribute-firebase.if: ' + d['jobs']['distribute-firebase']['if'].to_s"
```
Expected:
```
jobs: ["version", "build-android", "release", "distribute-firebase"]
distribute-firebase.needs: ["version", "build-android", "release"]
distribute-firebase.if: needs.version.outputs.new_tag != ''
```

- [ ] **Step 4: Project-rule gate — confirm no Flutter regression**

`CLAUDE.md` mandates `flutter analyze` and `flutter test` are green before any commit. The workflow change doesn't touch Dart, but the rule is absolute.

Run: `flutter analyze && flutter test`
Expected: `No issues found!` and `All tests passed!` (29 tests as of the Phase 1 + RadioGroup-migration baseline).

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/release.yaml
git commit -m "$(cat <<'EOF'
feat(release): distribute signed apk to firebase app distribution

Add a distribute-firebase job that runs after the existing release job.
It downloads the cookmate-apk artifact produced by build-android, reads
the GitHub Release body via gh release view, and uploads the APK to the
Firebase App Distribution project cookmate-d8571 for the "testers"
group, passing the release body through as the tester-visible release
notes.

Authentication uses the wzieba/Firebase-Distribution-Github-Action
with the FIREBASE_SERVICE_ACCOUNT_JSON secret passed inline via
serviceCredentialsFileContent. The job inherits the workflow-level
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true opt-in and carries the same
new_tag gate as the other three jobs, so chore-only pushes skip it
cleanly alongside build-android and release.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Push the branch and open the pull request

- [ ] **Step 1: Push the feature branch with upstream tracking**

Run: `git push -u origin feat/firebase-app-distribution`
Expected: branch created on `origin`, upstream tracking set.

- [ ] **Step 2: Open the PR**

Run:
```bash
gh pr create --base main --head feat/firebase-app-distribution \
  --title "feat(release): distribute signed apk to firebase app distribution" \
  --body "$(cat <<'EOF'
## Summary

Phase 2 of the two-phase mobile distribution plan (spec:
[`docs/superpowers/specs/2026-04-18-firebase-app-distribution-design.md`](docs/superpowers/specs/2026-04-18-firebase-app-distribution-design.md)).

- New `distribute-firebase` job runs after the existing `release` job on
  every semver-bumping push to `main`. It downloads the same
  `cookmate-vX.Y.Z.apk` artifact that `build-android` produces, reads
  the freshly created GitHub Release body via `gh release view`, and
  uploads the APK to Firebase App Distribution with the release body
  as the tester-visible notes.
- Distribution targets the `testers` group on Firebase project
  `cookmate-d8571`. Tester membership is managed in the Firebase
  console — adding or removing a tester no longer requires a workflow
  edit.
- Authentication uses the Docker-based action
  `wzieba/Firebase-Distribution-Github-Action@v1.7.1` (SHA-pinned) with
  the service account JSON passed inline via
  `serviceCredentialsFileContent`.
- `.gitignore` gains a defense-in-depth `firebase-sa.json` entry next
  to `*.jks` and `key.properties`.
- No Flutter / Gradle / `pubspec.yaml` changes — Firebase App
  Distribution is a CI-side delivery channel only, the app itself does
  not embed the Firebase SDK.

## Test plan

- [ ] CI workflow (`analyze`, `test`, `lint-pr`) is green on the PR.
- [ ] After merge, the `Release` workflow on `main` produces a new
      `vX.Y.Z` tag, the four jobs (`version`, `build-android`,
      `release`, `distribute-firebase`) all succeed.
- [ ] The registered tester receives a Firebase App Distribution
      email / push notification for the new version.
- [ ] Firebase App Distribution UI shows the release with the GitHub
      Release notes in the release-notes panel.
- [ ] Installing the APK via the Firebase tester link produces the
      same APK (by SHA-256) as the one attached to the GitHub
      Release, and the version in Settings → Apps → Cookmate matches.
EOF
)"
```
Expected: PR URL printed.

- [ ] **Step 3: Wait for CI and report status**

Run: `gh pr checks --watch`
Expected: `lint-pr`, `analyze`, `test` all pass.

If any check fails, report the failing run ID and log snippet with status `BLOCKED`. Do not start fixing without controller guidance.

---

## Task 4: Post-merge validation (manual, after PR is squash-merged)

Like Phase 1, this runs against the live workflow on `main`. It cannot be automated from the feature branch because the trigger is a release-bumping push on `main`.

- [ ] **Step 1: Confirm the `Release` workflow run on `main` reports success on all four jobs**

Run:
```bash
RUN_ID=$(gh run list --workflow=release.yaml --branch=main --limit=1 --json databaseId --jq '.[0].databaseId')
gh run view "$RUN_ID" --json status,conclusion,jobs --jq '{status,conclusion,jobs:[.jobs[]|{name:.name,conclusion:.conclusion}]}'
```
Expected: all four jobs (`Version`, `Build Android APK`, `Release`, `Distribute to Firebase App Distribution`) show `"conclusion":"success"`.

- [ ] **Step 2: Confirm the Firebase release appears with the GitHub-generated notes**

Open the Firebase console → App Distribution → Releases. The new `vX.Y.Z` should be listed with the release notes body matching the GitHub Release. Alternatively, run:

```bash
gh release view --json tagName,body --jq '{tag:.tagName, notes:(.body|split("\n")[0:3])}'
```

and compare the first 3 lines against what the Firebase console displays.

- [ ] **Step 3: Confirm the tester receives the notification**

Check the maintainer's email / the Firebase tester web UI for an invite-to-install message for the new version.

- [ ] **Step 4: Install via Firebase tester link on a physical Android device**

From the notification email or the Firebase tester web UI on a phone, follow the install link. Grant "install unknown apps" if prompted (Firebase Tester app is the recommended companion but a web link works too).

- [ ] **Step 5: Verify the APK matches the GitHub Release APK**

On macOS:
```bash
GH_SHA=$(gh release download "$(gh release view --json tagName --jq .tagName)" -p 'cookmate-*.apk' --clobber -O /tmp/from-gh.apk && shasum -a 256 /tmp/from-gh.apk | cut -d' ' -f1)
echo "GitHub asset SHA-256: $GH_SHA"
```
Then, on the device, use a file manager or `adb shell sha256sum /data/app/.../base.apk` to compare (or trust Firebase, since it stores and redistributes the exact bytes that were uploaded — this check is paranoia-grade).

Expected: SHA-256 of the Firebase-delivered APK matches the GitHub Release asset.

- [ ] **Step 6: Verify the second release still notifies testers**

After the next qualifying commit lands on `main`, confirm the tester gets a second notification, the APK installs in-place without `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (same stable signing chain Phase 1 introduced), and the Firebase console shows the new version superseding the previous one.
