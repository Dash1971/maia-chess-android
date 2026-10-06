# Stable release procedure

This is the authoritative publication procedure for maintainers and coding
agents. Start here, including for a metadata-only release. Detailed test commands
live in [RELEASE_CHECKS.md](../tool/hardening/RELEASE_CHECKS.md); build mechanics
live in [REPRODUCIBLE_BUILDS.md](../REPRODUCIBLE_BUILDS.md). Avoid duplicating this
procedure in task-specific notes.

## 0. Review upstream dependencies and security

At each Stable promotion, inspect `flutter pub outdated`, Flutter/Dart and
Android build-tool releases, ONNX Runtime Android, Maia model/inference sources,
Stockfish, and the pinned chess/UI packages. Record checked versions, advisory
sources and upgrade/deferral decisions in a dated dependency review. A promotion
is not a reason to blindly update all locked versions: native engine or toolchain
changes need their own compatibility, performance and reproducibility evidence.

The `dependencies` job runs on pull requests, pushes and manual release runs.
It resolves the **release** Android Maven graph without building the APK, then
queries OSV for locked Pub packages, resolved Maven packages, declared AGP/Kotlin
plugins/Gradle core and direct pinned Python release/test tools. It retains the inventory
and timestamped results. A missing Flutter plugin manifest or plugins absent
from the resolved graph blocks the audit. Known active advisories, unresolved dependencies,
malformed responses or persistent network errors fail the job. Fix or review
findings; do not turn an unavailable advisory service into a clean result.

This checks published package advisories, not every vulnerability. Flutter/Dart
SDKs, bundled native engine internals, models and the complete build-tool
transitive graph still need the upstream review above. It is not a source audit,
native binary scan or proof of zero vulnerabilities. The check contacts OSV only
from development/CI; the app remains offline. Repeat on the exact frozen source
in the manual release run; an old promotion report is not release qualification.

Local reproduction (after locked `flutter pub get` and SDK configuration):

```sh
flutter build apk --release --config-only --no-pub
(cd android && ./gradlew -I ../tool/dependency_audit.init.gradle :app:writeReleaseDependencyAudit)
/path/to/release-tools/python tool/audit_dependencies.py \
  --maven release-checks/maven-dependencies.json \
  --output release-checks/dependency-audit.json
```

## 1. Prepare and freeze the source

Review the README, Fastlane title/description/screenshots, current version-code
changelog, and GitHub release text against what the app actually ships. Include
the metadata **before** freezing the source. Inspect the entire tracked tree for
unintended archives, credentials, and private material, including research files.
Never replace a published tag or APK; corrections need a new version/code.

Merge the release changes, record the full commit SHA, and run:

```sh
release_sha=$(git rev-parse HEAD)
python3 tool/check_release_source.py --ref "$release_sha"
gh workflow run checks.yml --repo Dash1971/maia-chess-android --ref main \
  -f build_android=true -f expected_source_sha="$release_sha"
```

Confirm that the resulting run checked out that SHA. A changed source commit,
including a documentation change, invalidates the previous build qualification:
the commit timestamp is a reproducible-build input. Do not create the release
tag to make an unqualified recipe build.

## 2. Test and independently reproduce the APK

Require `test`, `dependencies` and `android` jobs to pass in the manual release run. Record
the run ID and download its unsigned APK. Select additional device/upgrade tests
according to [RELEASE_CHECKS.md](../tool/hardening/RELEASE_CHECKS.md), documenting
what was tested and what was not. A narrowly scoped change may reduce additional
device testing; it does not waive source, build, signature, or metadata gates.

Fetch the current **canonical** metadata for `com.dash1971.maia_chess` from
`fdroid/fdroiddata`, recording that repository's full revision. Inspect the open
F-Droid update request and pipeline too: an older failed build block may remain
in a bot-owned branch even after a new tag appears. Record retained failed
version codes and any maintainer action needed. Never assume the new tag will
remove them. The repository's `fdroid/` file is only a review copy.

Derive the candidate from the last canonical build, changing only its version
name, version code, and source commit. Update CurrentVersion/CurrentVersionCode.
Pin the candidate to the frozen full SHA. Preserve build instructions, signing
keys, binary URL, and update settings. If the inherited recipe needs changing,
stop and resolve the canonical discrepancy rather than quietly qualifying a
local-only fix.

On an independent Linux host, use the official
`registry.gitlab.com/fdroid/fdroidserver:buildserver` image pinned by digest and
record the fdroidserver source SHA. Run the inherited recipe with source scanning
and `--scan-binary`, using `--stop` so an error exits unsuccessfully. Capture the
process exit code even on failure (use `pipefail` if piping through `tee`). Require
the expected output APK to exist, both scans to complete, and the independent
unsigned APK's SHA-256 to equal GitHub's actual unsigned APK hash.

Before a developer-signed APK exists, its Binaries download may be deferred in
temporary metadata. Keep the full candidate recipe with the original Binaries
field for qualification; defer only retrieval, never build/scanner instructions
or the later developer-binary comparison. Retain both metadata copies and their
diff. Build warnings need review; scan errors are failures.

## 3. Sign the verified artifact and run the combined gate

Keep the key/password on the existing signing host. Transfer the qualified Linux
APK and verify its hash there. Do not rebuild on macOS. With Android build-tools
36.0.0, preserve alignment explicitly:

```sh
apksigner sign --alignment-preserved true \
  --ks "$keystore" --ks-key-alias "$key_alias" --ks-pass "file:$password_file" \
  --v1-signing-enabled false --v2-signing-enabled true \
  --v3-signing-enabled true --v4-signing-enabled false \
  --out "$signed_apk" "$unsigned_apk"
```

For the existing PKCS12 key, omitting `--key-pass` lets apksigner reuse the
keystore password. Passing the same one-line password file twice makes it read
a nonexistent second line. Never put a password in command arguments or logs.
Do not change signature schemes or rotate the key without a separate reviewed
compatibility plan. Verify the existing certificate and 16 KB alignment.

Install the release-only Python tools in a temporary environment:

```sh
python3 -m venv /tmp/maia-release-gate
/tmp/maia-release-gate/bin/pip install -r tool/requirements-release.txt
cp tool/release-evidence.example.json /path/to/evidence/evidence.json
# Fill in the manifest using actual files and the inspected upstream state.
/tmp/maia-release-gate/bin/python tool/qualify_release.py \
  --evidence /path/to/evidence/evidence.json \
  --sdk-root /path/to/android-sdk --output /path/to/evidence/qualification.json
```

The gate requires GitHub CLI read access, the Git objects for the source SHA,
Android build-tools, Internet access for provenance checks, and the three actual
APKs. Paths are relative to the manifest. Use a new output filename for each run.
Missing, malformed, stale, mismatched, or failed evidence makes it exit nonzero.
It obtains CI status and verification artifacts directly from GitHub, fetches
canonical metadata at the pinned revision and checks it still matches the live
canonical app metadata, compares recipe instructions, checks
the exact-source F-Droid log/exit code, verifies the signed APK's package/version,
offline permissions, model, ABI/alignment, payloads and certificate, and requires
byte-identical signature reconstruction from the independent unsigned APK.
It also rejects a reused/lower version code, an existing tag pointing elsewhere,
or a different APK for an already-published version. Requalifying an unchanged
published release is allowed; replacing it is not.

The manifest's `review` is an explicit operator attestation, valid for 24 hours;
it is not automated proof of listing accuracy or upstream approval. `blocked`
or `unknown` upstream status may accompany a qualified GitHub release, but must
be disclosed. A passing gate never means F-Droid has published the app. Preserve
the manifest, referenced logs/metadata, hashes, and gate report together.

The gate trusts GitHub's configured workflow and operator-supplied independent
build evidence. It cannot prove that the second host was independent, authenticate
an edited local log, or monitor upstream changes after the gate finishes.
Recheck upstream before publishing if there has been a delay. Do not use
handwritten success reports as a substitute for actual checks.

## 4. Stage, publish, and verify the public download

Create a draft release targeted at the qualified SHA. Upload the signed APK as
`Mobile-Maia-v<version>.apk`, its SHA-256, sanitized qualification evidence, full
candidate recipe, and release notes. Compare GitHub's uploaded asset digest
against the verified signed APK. Inspect the draft's source target and contents.

Publish only after all gates pass. Prefer staging assets before making the tag
public, so the updater does not encounter a tag with no developer APK. Verify the
actual tag resolves to the qualified SHA and rerun the source check on that tag.
Download the public Binaries URL independently; verify its hash, allowed signer,
and F-Droid's `common.verify_apks` comparison against the independent unsigned
APK. Retain that post-publication report on the release too. If a post-publication
check fails, report it immediately; never silently replace the published APK.

Run the official `fdroid checkupdates --allow-dirty --auto <appid>` locally
against a copy of current canonical metadata, **without** `--commit` or
`--merge-request`. Inspect the generated version, source SHA and inherited build
instructions. This checks detection; it does not submit upstream changes.

Separately record: GitHub publication; local update detection; actual F-Droid
request/pipeline and merge; actual public F-Droid catalog version. Inspect any
retained older failed blocks before claiming the request will succeed. Contact
maintainers only with user authorization and authenticated access. If upstream
is blocked, attach the exact correction and evidence to GitHub and state the
remaining action clearly; do not claim automatic recovery or store publication.

## 5. Leave a reproducible record and clean up

Keep sanitized logs, the image/source revisions, recipe, hashes, test scope,
signature comparison, and post-publication results on the GitHub release and
link them from the release PR. Do not publish credentials or private host paths.
Remove only this release's temporary APKs, build directories, containers and
signing workspace after verifying the public download. Preserve shared tools,
keys and unrelated services. Record cleanup and remaining upstream limitations.

`AGENTS.md` and this gate guide future releases but do not prevent a repository
owner from publishing directly with GitHub APIs. No repository permissions or
release protections are changed by this tooling. If publication is later
automated, its publisher must require this gate before creating a public release.
