# PGN collection import host checks — 22 November 2026

Scope: Stable promotion #82 and Preview #261. Flutter 3.47.8 host tests on an Apple Silicon Mac, using the shared cached ARM64 test engine. No Android build, emulator, Actions or LFS downloads. These results are development checks, not Android release qualification or phone performance measurements.

## Scale fixture and measurements

The deterministic fixture has **10,000 distinct games and 5,240,000 UTF-8 bytes**, just below the shared 5 MiB limit. These are short, ten-ply games with player/date/result headers and comments, stressing the file count and byte limit. The measurements do not establish validation speed for long, heavily varied games. No full dataset is checked in; `test/pgn_collection_scale_test.dart` regenerates it in a task-owned temporary directory and deletes it on completion.

First focused runs on the same host:

| Operation | Stable | Preview |
| --- | ---: | ---: |
| Validate/parse all 10,000 games | 26.03 s | 26.66 s |
| Stage and commit 10,000 new records | 2.54 s | 2.57 s |
| Load/sort Recent games | 1.17 s | 1.24 s |
| Re-import: duplicate scan, zero extra records | 1.12 s | 1.16 s |
| Largest observed gap in a 10 ms event-loop heartbeat | 14 ms | 19 ms |

Validation runs in a worker while the dialog shows an indeterminate progress bar. Duplicate scanning and staged writes report determinate progress. The roughly 26-second validation is still a noticeable wait for this extreme collection; host timings cannot predict installed phone speed. Peak RSS for the host test process was about 275 MiB (Stable) and 242 MiB (Preview); these include the Flutter test runtime and are not app memory estimates.

Recent games retains the existing files and ordering. Its complete read/decode/sort work now runs in one background worker, avoiding one decoder isolate per file. No database, persistent index or cache is added. The scale regression verifies counts, repeated-import skipping, ordered progress and event-loop activity; timing values are observational rather than brittle CI deadlines.

## Correctness regressions

- Exact-content duplicates within the file, existing archives, active games and readable archive backups; repeat import after repository restart.
- Different headers (including extra metadata), comments, clocks and variations remain distinct. Only line endings and surrounding whitespace are ignored.
- All-duplicate imports add no records and leave checkpoint/archive bytes unchanged.
- Validation/write failures leave no partial import, preserve recovery settings and close progress feedback.
- Startup cleanup removes only abandoned import staging directories. Normal checkpoints, committed imports, unrelated directories and links remain untouched; a concurrent repository cannot clean a live import.
- Localized progress/completion feedback at 320 pixels and 200% text in all ten languages; Back cannot dismiss an active import, and determinate progress ends after commit.
- Existing collection, single-game, file/paste/share, date/name/annotation retention and export-limit regressions remain in place.

## Remaining device checks

Preview beta.11 should exercise real Android file providers, sharing, a large collection, cancel/failure paths available through the provider, app process termination during import, reopening Recent games and signed upgrade/data retention. Stable still requires its independent Linux/F-Droid and exact-source release gates. No physical board result is inferred from these storage tests.

Full host suites: **1,526 passed, one skipped per repository**. The focused import-hardening suite contains 18 regressions, including the final progress transition and localized summary checks. Official Preview-flavor import-hardening checks are included separately; host checks do not replace release qualification.
