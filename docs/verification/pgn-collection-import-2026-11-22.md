# PGN collection import host checks — 22 November 2026

Scope: Stable promotion #82 and Preview #261. Flutter 3.47.8 host tests on an Apple Silicon Mac, using the shared cached ARM64 test engine. No Android build, emulator, Actions or LFS downloads. These results are development checks, not Android release qualification or phone performance measurements.

## Scale fixture and measurements

The deterministic fixture has **10,000 distinct games and 5,240,000 UTF-8 bytes**, just below the shared 5 MiB limit. These are short, ten-ply games with player/date/result headers and comments, stressing the file count and byte limit. The measurements do not establish validation speed for long, heavily varied games. No full dataset is checked in; `test/pgn_collection_scale_test.dart` regenerates it in a task-owned temporary directory and deletes it on completion.

Initial exact-text comparison, before the export/re-import correction (historical measurements on the same host):

| Operation | Stable | Preview |
| --- | ---: | ---: |
| Validate/parse all 10,000 games | 26.03 s | 26.66 s |
| Stage and commit 10,000 new records | 2.54 s | 2.57 s |
| Load/sort Recent games | 1.17 s | 1.24 s |
| Re-import: duplicate scan, zero extra records | 1.12 s | 1.16 s |
| Largest observed gap in a 10 ms event-loop heartbeat | 14 ms | 19 ms |

Those earlier runs validated in a worker with an indeterminate bar; the parsing-progress follow-up now reports validated input as described below. Duplicate scanning and staged writes report determinate progress. The roughly 26-second validation is still a noticeable wait for this extreme collection; host timings cannot predict installed phone speed. Peak RSS for the host test process was about 275 MiB (Stable) and 242 MiB (Preview); these include the Flutter test runtime and are not app memory estimates.

Recent games retains the existing files and ordering. Its complete read/decode/sort work now runs in one background worker, avoiding one decoder isolate per file. No database, persistent index or cache is added. The scale regression verifies counts, repeated-import skipping, ordered progress and event-loop activity; timing values are observational rather than brittle CI deadlines.

## Correctness regressions

- Matching supported PGN content within the file, existing archives, active games and readable archive backups; repeat import after repository restart and after export serialization.
- Different headers (including extra metadata), comments, clocks and variations remain distinct. Supported PGN formatting is normalized with the exporter; lossy serialization falls back to original-text comparison.
- All-duplicate imports add no records and leave checkpoint/archive bytes unchanged.
- Validation/write failures leave no partial import, preserve recovery settings and close progress feedback.
- Startup cleanup removes only abandoned import staging directories. Normal checkpoints, committed imports, unrelated directories and links remain untouched; a concurrent repository cannot clean a live import.
- Localized progress/completion feedback at 320 pixels and 200% text in all ten languages; Back cannot dismiss an active import, and determinate progress ends after commit.
- Existing collection, single-game, file/paste/share, date/name/annotation retention and export-limit regressions remain in place.

## Remaining device checks

Preview beta.11 should exercise real Android file providers, sharing, a large collection, cancel/failure paths available through the provider, app process termination during import, reopening Recent games and signed upgrade/data retention. Stable still requires its independent Linux/F-Droid and exact-source release gates. No physical board result is inferred from these storage tests.

Before the export/re-import correction, full host suites passed **1,526 tests, one skipped per repository**. The focused import-hardening suite contains 18 regressions, including the final progress transition and localized summary checks. Official Preview-flavor import-hardening checks are included separately; host checks do not replace release qualification.

## Export/re-import regression

The original exact-text comparison reproduced three failures: raw imported games, app-generated games and formatted/raw duplicates in the same incoming collection. The two app-generated games both produced duplicate records after export/re-import. The correction compares supported content using the exporter’s serializer without rewriting saved games or replaying all existing moves. It preserves original-text comparison for information the serializer would discard.

Ten dedicated regressions cover the round trip, active/archived records, within-file formatting copies, edited comments/clock annotations/variations/metadata, escaped headers/Unicode, semicolon comments, repeated tags, conflicting results, escape lines and malformed legacy PGNs. The original failing regressions pass after the fix. Source, channel identity and release qualification boundaries remain unchanged.

### Loaded-host diagnostic after the correction

A combined full-suite run hit the existing four-minute scale timeout while the Mac was also running nine unrelated CPU-heavy Stockfish jobs. An isolated diagnostic of the same 10,000-game assertions passed in 2 minutes 33 seconds: parsing 106.15 s, import 21.95 s, Recent games 7.08 s, repeat import 11.73 s. The parser slowed before duplicate comparison began. These loaded-host numbers are not directly comparable with the earlier quiet-host measurements above, and do not establish phone performance. The large test and remaining suite are checked separately under this load.

Final round-trip verification: **85 focused Stable import/export checks passed; ten official Preview-flavor round-trip regressions passed; the remaining full Stable host suite passed 1,535 tests with one skipped**. The separately run instrumented 10,000-game test passed the same assertions and unchanged four-minute limit. The earlier combined timeout remains recorded rather than counted as a passing default full-suite invocation. Both analyzers are clean.

## Parsing-progress follow-up

Validation now sends source-position updates after each complete game validates, with throttling and an explicit end-of-stream handoff. A continuous two-phase bar covers validation and storage without resetting. Dialog/dimming are delayed 300 ms, while the existing busy/Back guard remains immediate. Deterministic regressions cover quick single/collection imports and quick errors, the delay boundary, parsing/storage percentages, input/Back handling, errors, source disposal, invalid/oversized input, and no late progress callbacks. All ten localized compact/large-text feedback checks remain in place. The 10,000-game test now also checks monotonic intermediate parsing progress.

Latest progress/delay validation: **95 focused PGN tests passed in Stable and 95 in the official Preview flavor; both analyzers are clean**. Ten new checks cover real parser updates/errors and deterministic quick/slow dialog behavior. The updated standalone scale test passed in 2 min 40 s on this host: parse 105.17 s, import 31.14 s, Recent games 6.12 s, repeat import 10.63 s, with 2,345 parsing reports. The existing four-minute test limit and assertions were retained. Timings remain observations under host load, not phone estimates; device and exact-source release checks remain pending.
