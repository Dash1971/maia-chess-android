# Beta.18 release audit and saved-game hardening

Audited on 2026-09-10 using Apple Silicon macOS, pinned Flutter 3.47.1 /
Dart 3.13.1, JDK 17, and a disposable AOSP API 36 ARM64 emulator. No physical
phone or Chessnut board was used.

## Published source and artifact

The published `v2.1.0-beta.18` tag resolves to
`d16b5f19852654482d61c113a973fc7632ef8809`. PR #14 was merged as
`5c193dce290f1af07dc8737da1eb9e3a6b7897bc`. Comparing the previous verified
PR head `d8aaec1f` with the release shows only the version bump and one
documentation link correction. App code and regression/release tooling match.
The release commit's [GitHub checks](https://github.com/Dash1971/maia-chess-android-preview/actions/runs/34475598636)
also passed.

Published asset: `20260910_v2_mobile_maia_preview_v2.1.0-beta.18.apk`,
393,511,711 bytes. SHA-256:
`4316e1e5136727b9ff541f1dcb221514651b314238621b8352bdcc62e79d7cf3`.
This matches GitHub's release asset digest. Android identifies it as
`com.dash1971.maia_chess.preview`, version name `2.1.0-beta.18`, code `2072`.
Its valid v2 signing certificate matches the documented Mobile Maia publisher:
`cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e`.

A clean rebuild of the tagged app code produced unsigned APK SHA-256
`6f33455582237e3edae5b4e8a1639c093f313c498bf51f8492f770dbace4ef9a`.
The portable APK checker compared all **2,484 payload entries** with the
published APK: **zero differences**, excluding signing metadata. Thus the
published payload corresponds to the merged source, including the takeback fix.

ZIP integrity, duplicate-entry rejection, exact model hash/size, ARM64 native
library architecture and 16 KB alignment, release/debug flag, and checks for
accidental test/key/build-path inclusion all passed. There is no Internet
permission. The bundled model remains SHA-256
`3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`.

## New findings and corrections

1. **Failed archive switches could change the active save ID.** `open()` set
   the repository's active ID before writing the selected checkpoint. A real
   write failure left the original active game on disk but the other game's
   ID in memory. Resuming and saving the original game could update the wrong
   record. The regression obstructs the pending checkpoint with a directory,
   attempts the switch, removes the obstruction, and saves the original game
   without reloading the live repository. Both saved IDs and PGNs must remain
   correct. It fails on beta.18. The fix changes the ID only after the write
   succeeds.
2. **Recent games accepted overlapping operations.** Two taps before storage
   completed could submit two different opens; Back could leave while the
   repository was still switching saves. This risks inconsistent navigation
   and save selection. A synchronous operation guard now blocks overlapping
   taps and Back until the operation finishes. File operations show a thin
   progress line; the delete confirmation itself does not animate progress.
3. **Open/delete failures escaped the screen's handlers.** Injected filesystem
   exceptions produced unhandled errors. The screen now explains the failure
   and permits retry. A failed deletion refreshes the list in case part of the
   batch already completed.

Four new targeted regressions fail on the unmodified beta.18 runtime and pass
after these corrections. There is no engine, dependency, model, permission,
version or storage-schema change. These are release-hardening fixes; the
published beta.18 APK itself does not include them.

## Regression results

- Original release: all **303 host tests**, **11 Python tooling tests**, and
  static analysis pass.
- Corrected runtime `34d4c7f28e974e7148546c8520d4077b63cb11ec`: all **309 host
  tests** pass; static analysis is clean. New coverage includes rapid taps,
  Back during an open, failed open/delete and retry, and the active-ID write
  failure above. The correction's [Linux CI run](https://github.com/Dash1971/maia-chess-android-preview/actions/runs/34482487994)
  independently passed the analyzer, all 309 host tests, and all 11 Python
  tooling tests.
- Two additional widget tests already pass on beta.18: nested **Make main
  line**, repeated **Promote variation**, deleting a separate alternative,
  and four JSON reopens. They compare every remaining move path and annotation,
  the complete PGN, the played main line, and the selected board position.
- A fresh independent python-chess corpus passes **25,000 positions**, seed
  `20260918`, checking legal moves, mate/stalemate, move transitions, Maia
  vocabulary/encoding, simulated board-frame inference, and PGN round trips.
- A fresh variation corpus passes **1,024 trees / 4,096 round trips**, also
  seed `20260918`. Every path, comment/NAG, main line and final position matches
  Python's expected values; complete branches occur once. This took 71.2 s on
  the host while the chess corpus also ran. The combined run took 3m30s.
- Full-suite host observations: the 1,000-ply import/round-trip took 440 ms on
  beta.18 and 434 ms with the correction; listing 1,000 archives took 704 ms
  and 686 ms respectively. These single concurrent-suite measurements are
  observations, not a physical-phone benchmark or a statistically established
  speed improvement.
- All **14 Android integration tests** pass with the correction, including
  real Maia and Stockfish, variation navigation, repeated takebacks/reviews,
  clipboard, Chessnut-to-phone continuation with a simulated transport,
  completed-result types, reset isolation, premoves/clocks, and the new
  app-private filesystem failure/retry through Recent games. Test execution
  took 2m42s after a 30.6 s debug build.

The Android harness first replaced the higher-version release app with its
debug test app on the disposable emulator. Final cleanup attempted to uninstall
the absent stable package and logged `DELETE_FAILED_INTERNAL_ERROR`; the suite
returned success after all 14 tests passed against the Preview package. Neither
event indicates an app test failure. OS permissions and SELinux stayed enabled.

## Corrected release artifact

A clean release build of `34d4c7f28e974e7148546c8520d4077b63cb11ec` passed
(127.3 s Gradle build). The unsigned APK is 393,503,519 bytes, SHA-256
`615a5ba2ad72dc98f8b7217a2b07bce5c54c3bfeba8e2968d85c44b3f4590556`.
Packaging checks pass. Among all 2,484 payload entries compared with published
beta.18, only `lib/arm64-v8a/libapp.so` changes. The model, native engines,
permissions, release identity and all other packaged content are unchanged.

A published-beta.18-to-corrected-release upgrade passes for both completed
and unfinished fixtures, including pre-launch file/UID preservation, active and archived
snapshot restoration, complete move/clock/annotation comparisons and restart.
Both APK copies use the portable harness's temporary test key. The clean build
and emulator artifacts remain local; this audit does not publish an APK.

## Published release upgrade tests

The portable upgrade checker passed separately from the published beta.17
release code to published beta.18 release code for all three checked-in cases:

- Completed 59-ply game with duplicate move-12 continuations, a separate move-27
  branch, comments, NAGs and timed clock history. Duplicate complete lines fell
  from two excess copies to zero.
- An unfinished game with variations, paused unlimited clocks and the human
  to move.
- A naturally checkmated game, including normalization of its forced-result
  marker to the board's natural result.

Each run checks pre-launch byte preservation and app UID across the in-place
update; moves, positions, historical/final clocks, result, game ID and all
distinct annotated lines after launch; archived-snapshot restoration; and
force-stop/restart. No fatal Android or unhandled Dart exception appeared in
these isolated upgrade logs.

The harness signs APK copies with a temporary test key. It verifies release
code/data compatibility, while publisher identity is checked independently
above. It does not establish production-key installation behavior. Archive
checks restore the archived snapshot through normal session restoration;
the Recent-games screen is covered separately by widget/native integration.

## Repeating the checks

Use the pinned toolchain and commands in
[`tool/hardening/README.md`](../tool/hardening/README.md) and
[`RELEASE_CHECKS.md`](../tool/hardening/RELEASE_CHECKS.md). Generate expanded
corpora with `--positions 25000 --seed 20260918` and
`--cases 1024 --seed 20260918`; pass their paths through `MAIA_CHESS_CORPUS` and
`MAIA_VARIATION_CORPUS`. Run `flutter test`, `flutter analyze`, Python unittest
discovery, and `integration_test/review_android_test.dart` on an ARM64 emulator.
Build via `tool/build_android_release.sh`; compare the published APK with
`tool/verify_release_apk.py --require-signature --compare REBUILD`. Run the
upgrade checker once for each completed/incomplete/checkmate fixture using a
new output directory and explicit disposable-emulator reset authorization.

Source/tests and this compact report belong in Git. Local APKs, corpus files,
logs, screenshots and JSON diagnostics are under ignored
`release-checks/beta18/`; GitHub CI retains its own logs under the linked run.
The manual Android build workflow's uploaded artifacts expire after 14 days.
No signing keys or original user PGNs are committed.

These checks substantially expand tested failure paths but do not prove the
absence of all bugs. Real BLE/LED behavior, device-specific memory and thermal
behavior, and physical-phone interaction/performance remain user device tests.
