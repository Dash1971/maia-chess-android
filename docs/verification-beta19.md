# Beta.19 release verification

Audited on 2026-09-11 using Apple Silicon macOS, pinned Flutter 3.47.1 /
Dart 3.13.1, JDK 17 and a disposable AOSP API 36 ARM64 emulator. No physical
phone or Chessnut board was used. This pass found no new app defect in the
reviewed paths; the changes are tests, release-checker hardening and documentation.

## Merge and published artifact

The published `v2.1.0-beta.19` tag resolves to
`030f5eabd1d3c10260289ce8a7651489e37813a3`. PR #15 merged as
`aa118b074112b217f1ff66ea86ced6fca3170504`. Comparing its verified head
`3ae7675b2adb3f0dc58e70c277b841e0c72ed822` with the release shows only the
`pubspec.yaml` version bump. All prior app fixes and tests are included.
The release's [GitHub checks](https://github.com/Dash1971/maia-chess-android-preview/actions/runs/34485967785)
passed.

Published asset: `20260910_v3_mobile_maia_preview_v2.1.0-beta.19.apk`,
393,511,711 bytes, SHA-256
`848bdcff10b6213c6c7456c5a624ca6709b3b8d22049670d240d5087b09d1cc6`.
This matches GitHub's release asset digest. Android identity is
`com.dash1971.maia_chess.preview`, version `2.1.0-beta.19`, code `2073`.
The valid v2 signature matches the trusted publisher certificate SHA-256
`cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e`.

Packaging verification passes: ZIP integrity and duplicate-entry checks,
release/debug flag, no Internet permission, exact model hash/size, eight ARM64
native libraries with 16 KB-compatible alignment, and accidental test/key/build
path checks. The model remains SHA-256
`3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`.

A clean release rebuild passed (101.1 s Gradle build), using the release
commit's source timestamp `1789048675`. Its unsigned APK SHA-256 is
`2c5dc46dedefcc077e47177676c4055ab3cee128237cdabea0aab71be69e0d73`.
Comparison against the published APK passes for all **2,484 payload entries**
with **zero differences**, excluding signing metadata. The published binary
therefore matches the verified merged source. The emulator and build daemon
were stopped after verification; the tracked model was restored to its LFS pointer.

## Regression coverage

- All **309 existing host tests** pass on the published source. With three
  additional Recent-games recovery tests, the full suite passes **312 tests**
  in 40 seconds. Static analysis is clean.
- The new widget tests cover competing delete callbacks before a confirmation
  frame; Cancel and Back followed by a successful open; partial batch deletion
  that refreshes selection and retries only remaining games; and opening
  another record after the first becomes unavailable. They exercise the merged
  runtime unchanged and run in ordinary PR CI.
- A fresh python-chess corpus passes **25,000 positions**, seed `20260919`,
  comparing legal moves, mate/stalemate, move transitions, board-frame inference,
  Maia move vocabulary/encoding and PGN round trips.
- A fresh variation corpus passes **1,024 trees / 4,096 round trips**, seed
  `20260919`. All move paths, annotations, played main lines and final positions
  match the independent oracle; complete branches occur once. The variation
  check took 75.5 s and the combined expanded run took 2m59s.
- The full host runs observed 478–1,035 ms for a 1,000-ply import/round-trip and
  736–2,030 ms for listing 1,000 archives. These are concurrent-suite host
  observations, not a phone benchmark or evidence of a runtime speed change.
- All **14 Python verification-tool tests** pass, including three new polling
  recovery/failure tests.
- All **14 Android integration tests** pass with real Maia and Stockfish:
  variation navigation, full game replay, PGN import/clipboard, repeated
  takebacks and analysis, Chessnut-to-phone continuation using a simulated
  transport, completed-result types, reset isolation, premoves/clocks, and
  actual app-private storage failure/retry without mixing save IDs. Test
  execution took 2m42s after a 40.6 s debug build.

The native harness replaced the higher-version release with its debug app on
the disposable emulator. Final cleanup attempted to uninstall the absent
stable-package namespace and logged `DELETE_FAILED_INTERNAL_ERROR`; all 14
Preview tests passed and the process exited successfully. These setup/cleanup
messages are not app test failures. OS permissions and SELinux stayed enabled.

## Published release upgrades and checker correction

Published beta.18-to-beta.19 upgrades pass for the completed, unfinished and
naturally checkmated fixtures. Checks preserve pre-launch files and app UID;
moves, positions, clock history/final clocks, result, saved-game ID, branches
and annotations; the unopened archive; archived-snapshot restoration; and
force-stop/restart PGN. No fatal Android or unhandled Dart exception appears
in the successful isolated upgrade logs.

The first unfinished-game attempt failed while reading the **baseline**
checkpoint, before beta.19 was installed: JSON decoding received an unreadable
response. The baseline checkpoint was valid afterward. The repository replaces
`active.json` through two renames, so an external reader can encounter a brief
gap; the original checker aborted on the first unreadable poll. The observation
supports a polling race but does not establish the exact bytes of that failed
read, which the old checker did not record.

The checker now retries read/decode failures within the existing deadline and
records each retry. It still requires a changed, nonempty update timestamp,
then applies all original data-preservation checks. Persistent unreadable data,
no new checkpoint, or an invalid envelope fails. Tests use a fake clock to
verify transient recovery, persistent failure and envelope validation. The
unfinished-game rerun passes; the checkmate run records one transient decode
retry and then passes every preservation comparison. No app persistence code
was changed to obtain these results.

Upgrade APK copies use a temporary test key, deleted afterward. These checks
establish release-code/data compatibility on the emulator, not production-key
installation behavior. Publisher identity is verified separately above. Archive
restoration uses normal session restoration; Recent-games interaction is tested
separately in widget/native tests.

## Repeating and retaining the checks

Follow [the hardening guide](../tool/hardening/README.md) and
[portable release checks](../tool/hardening/RELEASE_CHECKS.md). Generate corpora
with `--positions 25000 --seed 20260919` and
`--cases 1024 --seed 20260919`, then set `MAIA_CHESS_CORPUS` and
`MAIA_VARIATION_CORPUS` for their Dart tests. Run the upgrade tool once per
checked-in fixture with a new output directory and a disposable emulator.

Source, deterministic tests, sanitized fixtures and this summary belong in
Git. APKs, generated corpora, full logs, screenshots and JSON diagnostics remain
under ignored `release-checks/beta19/`, including the initial failed checker
attempt. CI retains its own logs. No original user PGN or signing key is committed.

This pass does not prove the absence of all bugs. Actual BLE/LED behavior,
physical-phone interaction, memory pressure and thermal performance remain
user device tests. It does not require another APK: app code, model, dependencies,
permissions, storage schema and version are unchanged.
