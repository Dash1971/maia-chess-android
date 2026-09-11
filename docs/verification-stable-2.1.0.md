# Mobile Maia 2.1.0 pre-publication verification

Checked on 2026-09-11 using Apple Silicon macOS, Flutter 3.47.1 / Dart 3.13.1,
JDK 17 and an AOSP API 36 ARM64 emulator. Physical phones and Chessnut boards
are outside this pass. No tag, signed APK or public release was created.

## Source and promotion

Stable main was `b5b42018cf408ff45fca7fa2450ae72bfeb10262` (merged PR #4).
The immutable release source is **`7ad1264f2df1a483a9fc083d7cd885568681df1b`**,
with source timestamp `1789084129`. Build the official APK and place the
`v2.1.0` tag at that exact commit, as required by the current F-Droid recipe.
The later main commit changes only `FDROID_READINESS.md` and
`fdroid/com.dash1971.maia_chess.yml`; runtime, tests and build inputs match.
The clean release build for this audit uses a separate checkout of the exact
release-source commit, rather than building current main with a substituted
timestamp.

All audited beta.19 fixes and PR #16 tests/tooling are carried over. Dart
runtime differences from the audited preview are branding and source links.
Android changes to the stable package `com.dash1971.maia_chess`, blue icon and
label. Version is `2.1.0+73`; the build is universal ARMv7/ARM64/x86_64. Locked
dependencies, model, native bridge and gameplay/analysis logic are unchanged
from the verified preview. There are no preview-package/source references left
in the app's Dart or Android main source.

The merged source's [Linux checks](https://github.com/Dash1971/maia-chess-android/actions/runs/34549356148)
passed before this audit. Local checks independently passed:

- **312 host tests**, 42 seconds; static analysis clean.
- **15 original Python release-checker tests**, expanded to **20 passing tests**
  with stable 2.0-format and clock-migration regressions during this audit.
- **30,000 independently generated chess positions** and **1,024 variation
  trees / 4,096 round trips**, seed `20260921`. Legal moves, transitions,
  terminal states, simulated board-frame inference, Maia encoding/vocabulary,
  PGN paths and annotations match python-chess. The combined run passed in
  5m02s while the universal release build also ran; variation checks took
  122.3 s. These are correctness tests, not mobile performance measurements.
- **14 Android integration tests** using real Maia and Stockfish under the
  stable package, 2m45s after an 86.6 s debug build. These include the reported
  game replay, move-16 branch exit, PGN import/clipboard, repeated takebacks,
  variation preservation, completed-result types, Chessnut-to-phone continuation
  with a simulated transport, reset isolation, premoves/clocks, and a real
  app-private filesystem failure/retry without mixing saved-game IDs.

The host stress run observed 439 ms for a 1,000-ply import/round-trip and
1,203 ms for listing 1,000 archives. These are host observations under concurrent
test load, not physical-phone latency or a performance improvement claim.

## Exact-source release build

The clean universal build passed in 137.2 seconds of Gradle execution. The
unsigned APK is **555,017,993 bytes**, SHA-256
**`39f60ea87f052100f99258c8a4f22eab3b771c222b2708383e09bb197017c897`**.
This independently matches the exact hash recorded for both earlier clean
builds in `FDROID_READINESS.md` and PR #4. The earlier files were no longer
available, so this is a comparison with their recorded digest, not a fresh
pairwise comparison of those files.

The verifier passes stable package identity, version `2.1.0` / code `73`,
release flags, no Internet permission, exact model, ZIP integrity and alignment,
required engines, all three requested ABIs, 16 KB-compatible ELF load segments
for all **24 native libraries**, and accidental test/key/build-path checks.
There are **2,500 payload entries**. The verified unsigned APK is retained as
`release-checks/stable210/Mobile-Maia-v2.1.0-unsigned.apk` for final signed-payload
comparison. Its model hash remains
`3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`.

## Published stable baseline

The published `Mobile-Maia-v2.0.0.apk` is 554,517,073 bytes, SHA-256
`0018428ba07427ddf13fecbb0bf2a0fe7aba0f076520ef3af2d88ccb21b6e1a2`, matching
GitHub's release digest. Its stable package/version code is
`com.dash1971.maia_chess` / `54`. Signature verification passes and its
certificate SHA-256 matches the trusted publisher:
`cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e`.
Model, ZIP integrity/alignment, release flags, no Internet permission, and all
three native ABI checks pass.

## Upgrade checker hardening

The first completed-game upgrade attempt stopped on the annotation comparison.
Its saved moves and numeric clocks were unchanged, but 2.1 added the expected
59 per-move clock comments. The original comparison incorrectly treated any
new comment as a preservation failure. Inspection also showed that 2.0 had
already discarded the synthetic fixture's PGN-only branches before upgrade:
that version stores live-game branches in separate `variations` records, which
the original fixture did not seed.

The checker now has explicit `--legacy-game-format` support. It seeds actual
2.0-format branch records, validates their SAN/base FEN/annotations before
upgrade, and compares them against the candidate's full exported PGN. The
baseline must retain the fixture's complete semantic content; losing it before
upgrade can no longer silently reduce coverage. The unfinished legacy fixture
keeps notes on branches because 2.0's live-game format does not retain
main-line comments/NAGs. This limitation is checked explicitly instead of
silently dropping unsupported fixture annotations.

New clock comments are accepted only on the played main line and only when
they exactly match the corresponding saved millisecond clock value. Existing
comments/NAGs, moves, clock history, final clocks and results must still survive.
Five new Python tests cover legacy nested branches, starting comments,
black-to-move FENs, duplicate lines, baseline loss, wrong clock tags and lost
notes, plus natural-result normalization. The checkmate case additionally
clears a redundant 2.0 forced-result marker: the checker permits that only in
legacy mode when python-chess confirms the same automatic terminal outcome
and PGN result. It rejects clearing a result on an unfinished board or changing
the winner. The initial failing diagnostics are retained locally. No app code or
candidate APK was changed to obtain the corrected comparison.

All three published-stable-2.0-to-exact-source-2.1 upgrade cases pass:

- Completed, timed 59-ply game: all three distinct complete lines survive;
  two duplicate copies become zero; all branch comments/NAGs remain; all
  **59** added clock annotations match saved history.
- Unfinished game: both complete paths and branch notes/NAGs survive, with
  paused unlimited clocks and unchanged game identity.
- Naturally checkmated game: the same winner, all four moves and clock
  snapshots survive; all **four** added clock annotations match; the redundant
  forced-result marker is correctly cleared.

Each case also passes file-byte and app-UID preservation before first candidate
launch, untouched archive preservation, archived-snapshot restoration,
force-stop/restart comparison, and isolated Android/Dart crash-log checks.
APK copies use a temporary test signing key that the harness deletes afterward.
The emulator and build daemon were stopped, both tracked model files restored
to their LFS pointers, and the exact-source checkout left clean after testing.

## Minor CI correction

Stable promotion dropped `retention-days: 14` from the unsigned APK upload,
although the verification guide still promises that retention period. This
check restores the setting. It affects future CI artifact retention only and
is not an app defect or a reason to rebuild the release. App source, version,
dependencies and release-source identity are unchanged by this audit PR.

## Repeating the checks and remaining publication steps

Follow [the hardening guide](../tool/hardening/README.md) and
[release checker instructions](../tool/hardening/RELEASE_CHECKS.md). Generate
expanded corpora with `--positions 30000 --seed 20260921` and
`--cases 1024 --seed 20260921`. Build from the exact release-source checkout
using `tool/build_android_release.sh`. For the universal package verifier,
pass `--allow-abi armeabi-v7a --allow-abi arm64-v8a --allow-abi x86_64`, and
require version name `2.1.0` and code `73`.

No signed 2.1.0 APK existed when this audit began. After signing, verify its
signature against the trusted certificate and compare all payload entries
against the audited unsigned APK. Once published, re-download the asset and
compare its hash with the locally verified signed file. Upgrade tests using
temporary signatures establish code/data compatibility, not production-key
installation behavior. Actual Bluetooth/LED behavior, other CPU architectures'
runtime behavior, phone memory/thermal behavior and physical interactions remain
device checks.

Compact results, commands and synthetic fixtures belong in Git. Large APKs,
corpora, complete logs, screenshots and JSON diagnostics remain under ignored
`release-checks/stable210/`. No model binary, private signing key or original
user PGN is committed. Passing these checks does not prove absence of all bugs.
