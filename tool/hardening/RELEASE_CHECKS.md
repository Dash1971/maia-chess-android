# Repeatable release verification

These tools run on macOS or Linux. They accept paths and package/version
information as arguments; no developer home directory or private download is
required. Run them from the repository root. Python tooling does not add an
app dependency or change its offline behavior.

## Prepare the environment

Use the Flutter commit pinned in `.github/workflows/checks.yml`, JDK 17,
Android build-tools 36.0.0 and platform-tools. Set `ANDROID_HOME` and `JAVA_HOME`
for the machine running the checks. `--sdk-root` and `--build-tools-version`
can override SDK discovery explicitly. Python 3.10 or newer is recommended.

```sh
python3 -m venv /tmp/maia-release-venv
/tmp/maia-release-venv/bin/pip install -r tool/hardening/requirements.txt
/tmp/maia-release-venv/bin/python -m unittest discover -s tool -p '*_test.py'
```

The default target is `com.dash1971.maia_chess.preview`. Use
`--package com.dash1971.maia_chess` when verifying the stable app. Both APKs
in an upgrade test must have the same package ID: Preview-to-stable installation
is not an in-place upgrade and cannot establish stable-app data compatibility.

## Run regressions and build

Run the standard host suite, expanded chess/variation corpora and native suite
as described in [README.md](README.md). Native integration uses a dedicated
ARM64 AOSP emulator with only synthetic data. Wait for boot completion and
dismiss any emulator system error dialog before testing; never bypass OS
permissions or SELinux to make a test pass.

Materialize and verify the pinned Git LFS model before building. Save build
logs in the ignored `release-checks/` directory:

```sh
git lfs pull
python3 tool/verify_model.py
# Bash/zsh: preserve the build failure status when saving the log.
set -o pipefail
mkdir -p release-checks
tool/build_android_release.sh 2>&1 | tee release-checks/build.log
```

## Verify the APK

```sh
python3 tool/verify_release_apk.py \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  --output release-checks/apk.json
```

The command exits nonzero on failure and saves a JSON result with the reason.
It checks the package, release/debug flag, Internet permission, exact bundled
model hash/size, ZIP integrity and duplicate entries, ARM64 ELF architecture
and 16 KB alignment, required engine libraries, and accidental test/key/build
path inclusion. Large model/ZIP comparisons are streamed rather than loading
both APKs into memory.

Use `--version-name` and `--version-code` to require the intended release
identity. For a published signed APK, add `--require-signature`. That validates
its signature and records the public certificate; compare it with the trusted
publisher certificate separately. A valid signature alone does not identify
the publisher. Record the downloaded APK's hash against its release asset digest.

To verify that a published APK matches a clean unsigned rebuild:

```sh
python3 tool/verify_release_apk.py /path/to/published.apk \
  --require-signature \
  --compare build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  --output release-checks/reproducibility.json
```

Only signing metadata is excluded from that comparison. Every other payload
entry must match, including the set of entries. For an intentionally changed
build, allow only the exact entries expected to differ. For the duplicate
variation fix, for example:

```sh
python3 tool/verify_release_apk.py /path/to/corrected.apk \
  --compare /path/to/beta17.apk \
  --allow-change lib/arm64-v8a/libapp.so \
  --output release-checks/code-change.json
```

Do not broaden that list merely to turn a failing check green. Version,
resource or native dependency changes legitimately affect additional entries;
inspect and explain those differences. `--forbid-path` adds a build directory
that must not appear in the Dart binary, useful when checking an APK built on
a different machine.

## Verify a saved-game upgrade

Use two release APKs: the previous supported version and the candidate. They
can be signed or unsigned. The candidate's Android version code must be at
least the baseline's. Verify both APKs above before this check.

```sh
/tmp/maia-release-venv/bin/python tool/verify_release_upgrade.py \
  --baseline-apk /path/to/previous.apk \
  --candidate-apk /path/to/candidate.apk \
  --serial emulator-5554 \
  --allow-reset-test-app \
  --output release-checks/upgrade
```

`--allow-reset-test-app` explicitly authorizes uninstalling/resetting the chosen
package on that emulator. The script refuses physical devices, non-ARM64 or
non-root-capable emulator images, incomplete boot, and disabled SELinux. It
does not choose a device automatically. The AOSP emulator must already be
running; the script does not download SDKs or start/stop someone else's emulator.

Both APK copies are signed with a freshly generated temporary test key, then
the baseline is installed. A checked-in synthetic PGN and deterministic clock
history seed active and archived game records. After the in-place update, the
script checks:

- Active and archive files remain byte-identical before first launch, with the
  same app UID.
- Played moves, positions, historical/final clocks, result and game ID survive.
- Independent python-chess parsing preserves all distinct branches, individual
  comment blocks, starting comments and NAGs, with each complete line occurring
  once. It accepts both a legacy baseline with duplicates and a newer baseline
  that already removes them.
- The unopened archive remains byte-identical. While the app is stopped, the
  script copies that archived record into the active checkpoint and exercises
  the app's normal session restoration. It must produce the same game and PGN;
  another force-stop/restart must preserve them exactly. The Recent-games UI
  itself is covered by the separate Android integration suite.
- No fatal Android or unhandled Dart exception appears in the isolated logcat.

The default [fixture](fixtures/duplicate_takebacks.pgn) includes the move-12
duplicate continuation and the separate move-27 branch, with synthetic names,
notes, NAGs and generated clocks. It contains no original player/date metadata.
Use `--fixture another.pgn` for an additional single-game case. An unfinished
fixture is seeded with the human on the side to move and paused clocks so the
upgrade check does not depend on a random Maia reply. Its time preset is
unlimited to prevent normal clock advancement from changing the comparison.
For every fixture, the script waits for the restored game or result dialog's
accessibility label, then backgrounds the app to trigger a real checkpoint.
Naturally finished games need not save merely on opening. Timed clock
preservation is checked with
the completed fixture; running-clock behavior is covered by the host/native
regressions. Update this UI readiness check if the player-label wording changes.

Repeat with `--fixture tool/hardening/fixtures/incomplete_game.pgn` and a new
output directory to check the included unfinished-game case as well.
`--fixture tool/hardening/fixtures/checkmate.pgn` checks natural result restoration,
including conversion of a forced-result marker to the board's natural result.

Use a new or empty output directory for each run. `result.json`, before/after
records, restart data, logcat and a screenshot are retained; diagnostic capture
is attempted on failure too. The temporary key and test-signed APK copies are
deleted automatically. The stopped test app and synthetic records remain on
the emulator for inspection. This checks code/data compatibility; it does not
validate the production signing key or actual phone/Bluetooth behavior.

## CI and artifact retention

Every PR runs the host suite and verification-tool unit tests. The latter
deliberately feed the checkers corrupted/changed artifacts, missing notes,
altered clocks, duplicate lines and unsuitable emulator properties so a broken
checker cannot silently report success for those cases.

The existing **Checks** workflow has an optional `build_android` input. Select
the desired branch in GitHub Actions and run it with that input enabled, or:

```sh
gh workflow run checks.yml --ref YOUR_BRANCH -f build_android=true
```

That job builds the unsigned APK, runs packaging verification, and uploads the
build log/JSON diagnostics even after failure. The unsigned APK is uploaded
after success. Both artifact types expire after **14 days**. The ARM64 emulator
upgrade and native-engine checks remain explicit commands on a suitable host;
the ordinary Ubuntu CI job does not claim to run them.

Keep compact verification summaries, hashes, commands/seeds and sanitized
fixtures in Git. Keep APKs, full logs and screenshots in ignored local output
or expiring CI artifacts. Review custom-fixture diagnostics before uploading,
since they may contain the supplied game's metadata. Never upload test or
production private signing keys. After publication, repeat the source-to-APK
comparison against the actual merged commit and published download.
