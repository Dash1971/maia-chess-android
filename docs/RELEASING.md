# Stable release procedure

This is the authoritative publication procedure for maintainers and coding
agents. Start here, including for a metadata-only release. Detailed test commands
live in [RELEASE_CHECKS.md](../tool/hardening/RELEASE_CHECKS.md); build mechanics
live in [REPRODUCIBLE_BUILDS.md](../REPRODUCIBLE_BUILDS.md). Avoid duplicating this
procedure in task-specific notes.

A user request to publish a Stable release includes GitHub publication, the
Zapstore update, and checking F-Droid automatic-update progress, unless the user
explicitly limits the scope. The release operator owns these steps and their
follow-up; do not wait for the user to remind you about an app store. Requests
only to build, prepare, or review a PR do not authorize publication. F-Droid's
build and catalog schedule remains outside our control: distinguish pending
upstream work from a completed store update.

## At a glance

- Check disk space on all build/test hosts.
- Review upstream security advisories and available updates; record decisions.
- Prepare release notes, README feature introductions, screenshots and store
  metadata, then freeze the exact source commit.
- Run GitHub tests/security checks and build the unsigned APK on GitHub Ubuntu.
- Independently build on Linux using the canonical F-Droid recipe and scans.
- Require both unsigned APKs to match exactly, then sign the verified Linux APK.
- Run Android emulator checks on an Apple Silicon Mac or another suitable host:
  real Maia/Stockfish, gameplay/analysis, saving/restoring, changed features and
  signed upgrade/data preservation. Record the scope; physical board acceptance
  remains separate. A Mac test build does not replace the qualified Linux APK.
- Pass the combined release/F-Droid reproducibility gate and publish on GitHub.
- Verify the actual public APK; check F-Droid update detection and track its
  build/catalog publication separately.
- Publish the same verified APK to Zapstore and verify its listing/download.
- Clean task-owned bulk output promptly after the applicable download checks.
- Finish the post-release documentation pass before closing the release task.

Ordinary PR CI runs code, chess/game, storage, layout, translation, native-policy
and verification-tool regressions. The manual Android job builds and checks
packaging; it does not run the ARM64 emulator integration or signed-upgrade
checks. The detailed gates below remain authoritative.

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

Before Gradle executes, CI also runs `tool/verify_gradle_wrapper.py` to enforce
our reviewed distribution and checksum. The October 2026 Gradle advisories
were initially absent from OSV's exact-version result; a green advisory query
must never override a known upstream advisory. Keep this offline guard when
promoting Preview and update its pin only with a qualified toolchain change.

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
changelog, and GitHub release text against what the app actually ships. Add a
plain-language introduction for each new user-facing feature, explaining where
to find it and how to use it. Include the metadata **before** freezing the source. Inspect each README and Fastlane
screenshot when a promotion changes labels, control grouping, defaults or
branding. Refresh affected images from the current UI, update their captions
and capture provenance, and check that the feature text uses the same labels.
Do not retain an old Settings image merely because the underlying feature still
exists. Keep accurate older game examples explicitly identified as such.

Inspect the entire tracked tree for
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

### Publish the verified Stable APK to Zapstore

Zapstore is a separate developer-published channel. The committed
[`zapstore.yaml`](../zapstore.yaml) selects Stable GitHub tags and their one
universal `Mobile-Maia-v<version>.apk` asset; it does **not** watch GitHub or
publish updates by itself. The F-Droid bot does not publish to Zapstore either.

**Description format:** F-Droid's `full_description.txt` contains HTML; the
Zapstore Android client renders Markdown. Its website can render HTML, so a
successful website check alone can miss literal `<b>`, `<ul>` and `<li>` tags
on Android. Keep an explicit Markdown `description` in `zapstore.yaml`; YAML
metadata takes precedence over the publisher's automatic Fastlane import.
Preserve the same wording, with Markdown bold headings, blank lines and bullets.
Using the Python environment from section 3, run:

```sh
python tool/check_zapstore_metadata.py
# When the Fastlane copy changes, generate the matching Markdown to review
# and place under description: | in zapstore.yaml:
python tool/check_zapstore_metadata.py --print-description
```

CI runs this check and its regression cases using the existing release-tools
environment. It rejects missing descriptions, HTML (including escaped tags)
and drift from the F-Droid wording. New HTML constructs require a reviewed
conversion. Check the published app-metadata event's actual content as well
as its rendering: paragraphs, bold headings and list spacing must remain clear
in the Android Markdown renderer. Record whether the Android store client was
actually tested; do not describe a website-only check as Android validation.

A correction only to an existing store listing is not a new APK release.
For such a correction, publish only the replacement app-metadata event with
the established identity, after verifying the current event and intended diff.
Preserve its other metadata and the existing release/asset events; verify the
accepted content and unchanged APK references afterward. Do not overwrite a
release, rebuild, move its tag, or rerun the full APK-release process just to
repair listing text. Record the correction and evidence on GitHub.

#### Publisher, identity and qualified input

Use the qualified public GitHub APK as the release source. A second APK upload
to Zapstore's CDN is **not** a publication requirement. Keep the same immutable
GitHub release, tag and APK throughout this step; a store-delivery failure does
not justify rebuilding or replacing them.

The reviewed publisher is **zsp 2.0.0**, source commit
`28bc992f0663d6bae6c40dfd1eb462c56f45cb7b`. Pin and record the executable's hash,
architecture and version; verify `--version` and command help before use.
Review a later publisher before changing this pin. The v2 release provides a
Mac ARM64 binary but no Intel Mac binary; an Intel signing host can compile the
pinned source with Go 1.27.3 (declared by that source) and Clang. Reuse shared
tools and caches, prevent an unbudgeted toolchain download, keep tool
source/output under task ownership, and obey the disk budget.
This tool preparation never rebuilds the application APK. Pinned references:
[zsp release](https://github.com/zapstore/zsp/releases/tag/v2.0.0),
[configuration and CLI specification](https://github.com/zapstore/zsp/blob/28bc992f0663d6bae6c40dfd1eb462c56f45cb7b/SPEC.md),
[public-source APK upload guard](https://github.com/zapstore/zsp/blob/28bc992f0663d6bae6c40dfd1eb462c56f45cb7b/internal/release/publish.go#L301).

Check these established Stable identities directly; do not infer the actual
signer from a YAML field or a previous command's exit status:

| Identity | Required value |
| --- | --- |
| Android package | `com.dash1971.maia_chess` |
| Nostr public key, hex | `6d422f13061d8252cddb028c50aa93d347c74775da8e4b724c1d2a2d8f03fac8` |
| Nostr public key, npub | `npub1d4pz7ycxrkp99nwmq2x9p25n6druw3m4m28ykujvr54zmrcrltyqwnjah2` |
| Android certificate SHA-256 | `cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e` |

On the existing signing host, derive only the public key from the configured
signer and compare it with this table. Keep the Nostr private key, Android
keystore and passwords on that host, outside disposable bulk. Supply signing
through the established local runner or remote signer; never put secrets in
source, GitHub Actions secrets, command arguments, logs or release evidence.
In v2, YAML `pubkey` is accepted but ignored; `SIGN_WITH` and the active NIP-C1
proof determine authorization. Query the live kind-30509 proof for the APK
certificate: verify its event signature, Android-key proof signature, owner or
authorized delegate, expiry and non-revoked state. Reuse a valid proof; ordinary
publication does not require creating or renewing it. Do not rotate identities
or introduce a delegate to work around a failed check.

#### Task config, notes and media

Copy the qualified source's `zapstore.yaml` into the task's owned bulk directory.
Preserve its approved Markdown and app metadata. Set the exact already-verified
public APK URL with this **mapping**, substituting the qualified version:

```yaml
release_source:
  asset_url: https://github.com/Dash1971/maia-chess-android/releases/download/v<VERSION>/Mobile-Maia-v<VERSION>.apk
release_notes: ./release-notes.md
icon: ./media/icon.png
images:
  - ./media/1.png
  - ./media/2.png
  # Continue with the actual approved images, in display order.
```

The `asset_url` mapping selects a static public download. A bare GitHub APK URL
can instead be detected as a forge repository URL. Remove redundant
`release_filter` and `match` entries from this task copy: the exact URL and
`--apk-hash` bind the candidate. Keep the approved release notes and all named
media inside the task config's directory, using fixed copies from the qualified
source. Do not leave screenshots to a later `main` checkout or Fastlane lookup.
This task copy does not change the committed config, frozen source or APK.

Use a conservative **500 KiB (512,000-byte) per-image delivery budget** for the
current service. This is our working budget, not a permanent server guarantee:
record an actual rejection and current policy rather than guessing from a
large APK's size. Optimize losslessly first. If needed, prepare a listing-only
lossless WebP derivative and verify identical decoded RGBA pixels and dimensions
against the qualified PNG. Retain source/output hashes, byte counts and that
comparison; keep the original repository screenshot and APK unchanged. Use
`--no-compress` when publishing these reviewed files: v2 otherwise re-encodes
raster images. A generic upload error is not enough to choose a file to alter;
identify the failed media's hash, size and MIME type first.

#### Mandatory media gate and failure recovery

App metadata is independently replaceable: publishing it can break the existing
listing even when the new release fails or remains pending. A release failure
must never leave the current listing pointing at unavailable screenshots.

Before any command that can replace app metadata:

1. Save the current signed app event, its ordered icon/image URLs, and the
   current release/asset IDs. Prepare a reviewed metadata-only recovery event
   preserving the description and all unrelated tags. Keep this compact
   recovery evidence outside disposable bulk.
2. Upload new media before publishing references to it. GET **every exact public
   icon/screenshot URL**, follow redirects, require HTTP 200 and successfully
   decode the complete image with nonzero dimensions. Verify served image
   hashes against the reviewed delivery files. Check website thumbnail URLs
   separately (currently `?class=thumbsm`). An upload receipt, HEAD, hash in a
   URL, publisher exit status or `pending` result cannot pass this gate.
3. If the publisher cannot expose and verify uploaded URLs before replacing
   metadata, do not use that combined path with unverified new images. Retain
   the previous verified image URLs until a separate verified upload is ready.
   Preserve the approved current description. Do not repeatedly publish a full
   release to repair media.
4. Immediately read back the accepted signed app event and repeat GET/decode
   checks for **all actual icon/image references**. Inspect the rendered website
   and confirm every screenshot displays; placeholders are a failure. Save URL,
   status, decoded dimensions, bytes/hash, event IDs and a rendered capture.
5. On any media failure, restore the previously verified image references
   immediately with a newer app-metadata-only event under the established
   identity. Re-read current state before signing; abort on an unexpected
   concurrent edit. Preserve current description, unrelated tags and existing
   release/asset events. Verify the restoration by signed relay readback,
   complete image GET/decode checks and the rendered listing. Do not leave a
   broken live listing while awaiting release indexing or a documentation PR.

Read the relay's full `OK` response text. An `OK` boolean of true with a
`pending:` message means buffered, not publicly stored. A metadata-only recovery
can also be buffered behind pending releases. If signed readback still returns
the broken app, investigate the relay's listing admission rules. In the October
27 recovery, replaying the **exact existing signed and stored release event**
(same event ID and bytes, no new signature or modified fields) allowed the
recovery app event to be promoted against that admitted release. Verify the
stored release/asset set remains identical afterward. This is a targeted
recovery trigger, not permission to create duplicate release events, delete
pending releases or overwrite a published release.

Recover the listing before reporting a pending store handoff. Report temporary
use of older screenshots explicitly and replace them only after the new media
passes this same gate. Pending release events and listing health are separate
checks. Never mark media verified because the version, icon or description alone
loads. No APK rebuild, tag replacement or full release qualification is needed
for this scoped listing repair.

#### Check, publish and verify

Set `version`, `version_code`, `release_sha` and `apk_sha256` from the completed
qualification and public GitHub download checks. `release_sha` must be the full
frozen commit, and `apk_sha256` the **signed** APK hash. Record its size and
approved certificate too. On the signing host, set the public infrastructure
variables `RELAYS=wss://relay.zapstore.dev` and
`BLOSSOM_URL=https://cdn.zapstore.dev`. Set `TMPDIR` to an existing directory
inside owned bulk so temporary APK downloads remain covered by cleanup.
With `zsp` resolving to the pinned executable and `config` to the task copy:

```sh
zsp check --json --apk-hash "$apk_sha256" "$config"
zsp publish --json -q --no-compress --apk-hash "$apk_sha256" \
  --commit "$release_sha" "$config"
```

The first command is read-only preflight; inspect the actual package, version,
code, signed hash, certificate, live proof, authorized public key and existing
published version before proceeding. Stop on a mismatch. The second command
signs and sends public events. Stable publication authorization covers it;
do not ask again unless the user excluded Zapstore or a new decision falls
outside that scope. Do not add `--overwrite-release` merely to get past a
version guard. Omit `--app-created-at-release` so a corrected app-metadata event
receives a fresh timestamp. Check the final selected APK again if the source
or publishing invocation changes.

The public-source path publishes the verified GitHub URL without uploading a
duplicate APK. A publisher may still upload icons/screenshots. Treat JSON
`pending` as pending and preserve its event ID/status. Perform a bounded
read-only relay/listing check, then record the owner, next action and follow-up
time if it remains pending. Do not publish a duplicate or retry indefinitely
while waiting for indexing. Pending alone does not require retaining bulk;
retain compact evidence and clean after the applicable public-download checks.
Exit 0, a local cache marker or relay acceptance alone is not store publication.
Legacy zsp 0.4.17 committed
its source cache before blob uploads; after a failed upload it could silently
skip a retry with exit 0. If investigating that failure, back up and invalidate
only the confirmed false repository cache entry after checking actual upstream
state; never delete unrelated caches or overwrite a release blindly. Record
partial app-metadata publication separately from release/asset publication.

Before recording `ZAPSTORE PUBLISHED`, retain all of the following:

- The actual relay, publishing public key and app/release/asset event IDs;
  valid signatures, package/version/code, full source commit, signed APK hash,
  size and certificate, and the release's references to its app and asset.
- The asset's **actual advertised download URL** and any redirects. Download it
  and verify the qualified hash, size and Android signer. The public GitHub URL
  is a supported delivery path; no duplicate CDN copy is required. If a CDN URL
  is advertised or used by the client, check its actual GET behavior separately
  and distinguish a cached copy from a redirect to GitHub. Do not claim automatic
  CDN caching. HEAD can differ from the service's GET redirect fallback.
- The client-rendered [Mobile Maia listing](https://zapstore.dev/apps/com.dash1971.maia_chess)
  showing the intended release and working media/download; inspect the published
  Markdown content too. Raw page HTML does not establish this client-side state.
  Record whether an Android store client was tested or only the website.

Keep GitHub, Zapstore and F-Droid outcomes separate. On failure, retain the exact
stage, safe diagnostic context and next action; keep the immutable GitHub release
intact. The [2026-10-27 incident](incidents/2026-10-27-zapstore-delivery.md) explains
the older assumptions and cache failure; the workflow above is self-contained
and does not require researching historical releases.

No Zapstore auto-publisher is currently deployed. A future local post-release
job must run only after the qualified GitHub release and its public APK have
passed the checks above, use the existing local Nostr signing boundary, avoid
duplicate version publication, verify relay, listing and actual download
results, and alert on failure. Do not make a GitHub tag or `zapstore.yaml` change alone a trigger
that can publish an unqualified APK.

## 5. Leave a reproducible record and clean up

Follow [build storage and cleanup](BUILD_WORKSPACE.md) on every build, test and
signing host. Clean disposable bulk output promptly after the public-download
checks and retention of the required qualification evidence; do not wait for
a follow-up documentation PR or pending F-Droid catalog publication. Keep
artifacts still needed by an active operation, with an owner, concrete reason
and expiry. Pending store publication alone does not justify retaining bulk.
Record the cleanup
report with the distribution evidence. Shared tooling changes follow
[the counterpart-review rule](SHARED_BUILD_PROCESS.md).

Create or update a distribution status comment on the release PR, linked from
the GitHub release. Record the exact version and source SHA, a UTC check time,
and evidence links for each row below. Update that same record as pending
channels progress; a successful GitHub upload is not the end of distribution.

| Channel/check | Required evidence and status |
| --- | --- |
| GitHub | Public tag/source, APK hash/signer and post-publication verification. |
| Zapstore | App/release/asset event IDs, publishing identity/proof, APK hash/signer, verified advertised download URL/redirects and visible listing version; `PUBLISHED` only after verification. |
| F-Droid detection | Detected version/code/source and inherited recipe. This is not store publication. |
| F-Droid request/build | Current request/pipeline links and state, or explicitly not yet observed. |
| F-Droid catalog | Actual public catalog version/code; `PENDING` until this release is available. |

For every pending or blocked row, record the next action and who owns it. The
release operator owns checking progress and reporting failures. When an
available follow-up mechanism is needed for delayed upstream work, arrange it
and record it; never claim monitoring is active unless it was actually set up.
If follow-up cannot be arranged, explicitly report that limitation and the
remaining work. Keep upstream contacts within the authorization rules in
section 4. Do not mark all stores updated based on detection or build success.

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

## 6. Finish the post-release documentation pass

After publication, check the README, release notes and user-facing documentation
against the shipped version. Update the current version/download links, link the
published release notes, complete introductions for new features, and refresh any
remaining screenshots affected by the release. Reconcile roadmap items where
appropriate, without presenting pending store publication as completed. Record
the documentation changes, or that no further changes were needed, in the
release PR before closing the release task.

Prepare feature descriptions and affected release/store screenshots before the
source freeze in section 1. This final pass updates current documentation; it
never moves the published tag, changes the published APK, or retroactively alters
metadata inside that tag. Documentation-only follow-up commits do not require
rebuilding the unchanged published release. Keep the release's exact source SHA
clear, and never defer bulk cleanup until this documentation work merges.
