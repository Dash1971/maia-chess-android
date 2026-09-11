# Duplicate takeback variations: fix and verification

Verified on 2026-09-10 against beta.17 (`0046e118`), with corrected runtime
commit `51e3fd730997c7d83361c381bd946de2cadac4d7`. Environment: Apple Silicon
macOS, pinned Flutter 3.47.1 / Dart 3.13.1, JDK 17, AOSP API 36 ARM64 emulator.

## Defect and correction

Two consecutive takebacks near move 12 leave an abandoned continuation stored
as `Qxe7 Qe2` with a terminal child `Qd7 Qe3`. PGN represents this as the single
line `Qxe7 Qe2 Qd7 Qe3`. Opening game analysis merged the parsed PGN tree with
the saved takeback tree, comparing only each segment's immediate move list.
Those equivalent representations therefore looked different. Returning from
analysis saved both copies; visiting again accumulated more duplicates.

The reported duplicate display is a bug. The original reproduction grew from
one to two to three branches without changing played moves. The supplied PGN
shows a Black move between the two White moves; it cannot establish whether a
screen gesture was a slip or a premove. A different sampled Maia reply after
replaying a position is not evidence of this variation-persistence defect.

The fix normalizes equivalent continuation representations before merging,
importing and exporting. It combines distinct comments, starting comments and
NAGs, retains genuine child alternatives, and compares both the attachment ply
and canonical starting position. Real en-passant rights remain significant.
The played main-line boundary is protected so an undone continuation is never
silently restored as a played move. Already-duplicated PGNs are normalized too.

This changes variation handling only. No engine, dependency, setting, model,
permission, version, or storage-schema change is required.

## Regression results

- The two new reproduction/recovery widget tests failed on unmodified beta.17
  and pass after the correction. The first drives two actual takeback actions,
  a replacement move and controlled Maia reply, eight analysis visits, and
  four background/dispose/reopen cycles. It checks the full PGN, played moves,
  positions, historical/final clocks, and notes after each visit. The second
  restores a completed PGN with three duplicate branches and distributed notes.
- All **303 host tests** pass. Existing three seeded 40-turn action traces now
  also open analysis every four turns and check that no-op visits preserve the
  entire exported PGN and all complete branch paths remain unique.
- Seven variation-tree cases cover all 32 segmentations of a six-move line,
  distinct nested alternatives, annotation merging, nonmutation, equivalent
  legacy FENs, real en-passant distinctions, and protected played-line lengths
  of zero, one and three plies.
- The independent python-chess variation corpus passes: **512 games, 2,048
  round trips**, seed 20260911. Every move path, comment/NAG, unique leaf path,
  main-line move and final position matches independently generated expected
  values. Flat and segmented representations are mixed on every cycle. The
  ordinary CI suite also runs a checked-in 32-game corpus with seed 20260910.
- Static analysis is clean; both Python model-tool tests pass.
- All **13 Android integration tests** pass, including real Maia and Stockfish,
  real storage and clipboard, imported variations, result/history restoration,
  and simulated-board continuation. The added case repeats the nested takeback
  sequence and three analysis/reopen visits with real analysis engines. Only
  its game opponent is controlled to make the replacement move deterministic.
- The isolated 1,000-ply import/round-trip test measured **331 ms on beta.17**
  and **329 ms on the correction** on this Mac. These single host measurements
  show no apparent regression; they are not a phone benchmark. Concurrent full
  suite timings are slower and are not directly comparable.

The Android harness replaced the higher-version release app with its debug
test app in the isolated emulator. Final cleanup logged an unsuccessful
uninstall of the absent stable namespace; all 13 tests completed successfully
against the Preview package. No test bypassed Android clipboard permissions
or SELinux.

## Release artifact and saved-game upgrade

A clean ARM64 release build succeeds. The unsigned APK is 393,503,519 bytes,
SHA-256 `3f7c2ae5147cc09124f355f86fe6a2ffeba90d59de5f2fccb315e718a67e7925`.
Against the verified beta.17 rebuild, only `lib/arm64-v8a/libapp.so` changes
among 2,484 ZIP payload entries. CRC and duplicate-entry checks pass, all eight
native libraries retain 16 KB alignment, and the Maia model hash is unchanged.
The APK has no Internet permission, debug flag, test fixtures, keystores or
local checkout path. The model in Git remains its original 134-byte LFS pointer.

The supplied 59-ply game was seeded into beta.17 release code in the emulator.
It retained three copies of the move-12 branch, reproducing the legacy state.
An in-place update to the corrected release code preserved the session file
byte for byte before launch. After launch:

- The move-12 duplicates became one complete continuation.
- Independent python-chess comparison confirmed every distinct branch and
  comment survived, including the separate move-27 variation.
- Game ID, all played moves/positions, result, and historical/final clocks
  remained identical.
- Force-stop/restart retained the corrected PGN; no native crash or unhandled
  Dart exception appeared in the smoke-test log.

Both release APK copies used the same local Android test key for this upgrade
check. Production signing keys were not used. This verifies release-mode
restoration across the code update, not the eventual production signature or
future merged release build. No merge or release publication was performed.

## Continuing release hardening

The commands and fixture-generation instructions are in
[`tool/hardening/README.md`](../tool/hardening/README.md). The durable change is
to test combinations of actions and preservation invariants, retain a failing
case for each reported bug, and compare structured output with an independent
implementation. Keep deterministic regressions in every PR's CI, then run the
expanded seeded corpus, native integration, clean release build and saved-game
update smoke test before publication. Verify the published APK against the
merged source separately. Physical-phone performance and real Chessnut BLE/LED
behavior remain device tests; these results do not prove the absence of all bugs.

## Portable release-tool follow-up

The APK and upgrade checks are now repository tools, documented in
[`RELEASE_CHECKS.md`](../tool/hardening/RELEASE_CHECKS.md). SDK locations, APKs,
emulator ID, package and expected versions are inputs. The upgrade script uses
sanitized completed/incomplete fixtures and a temporary test key, with no
private download or production signing configuration required.

Local verification of the portable tools passed:

- All eleven Python tooling tests, including negative checks for unexpected
  payload changes, incompatible ELF segments, unsuitable devices, lost notes,
  changed main lines, duplicate branches and altered clock history.
- Packaging verification of the corrected unsigned release; signed-versus-
  unsigned payload equivalence; and comparison with beta.17 allowing only the
  known Dart library change.
- Real emulator upgrades with the completed 59-ply duplicate-variation
  fixture, an unfinished four-ply game, and a checkmate fixture. Active/archive
  bytes survive the
  update; both active and archived-snapshot restoration preserve game data;
  the completed case removes two redundant copies; restart preserves PGN.

The completed cases check exact timed clock snapshots. The unfinished case is
untimed, avoiding normal live-clock advancement in the comparison. Every case
backgrounds the restored UI to trigger a real checkpoint; naturally finished
games need not rewrite a checkpoint merely on opening. Natural-result markers
are allowed to normalize during baseline setup while the PGN result must stay
unchanged. Archived records are snapshots,
so the tool verifies their bytes remain unchanged and then explicitly restores
a copy through the active checkpoint reader. Recent-games UI behavior remains
covered by the separate native integration suite.

The ordinary CI job now tests these tools. The optional Android build job runs
packaging verification and uploads diagnostics plus the successful unsigned
APK with 14-day retention. App runtime code is unchanged by this tooling work.
