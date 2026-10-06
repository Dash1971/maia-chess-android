# Recent Games history verification

Change tracked in [#81](https://github.com/Dash1971/maia-chess-android-preview/issues/81).
Base: Preview `a78737d2bffcbdc450327195b0bb1954fc06de2f` (2.3.0-beta.3).
Validated on macOS with the repository's pinned Flutter 3.47.5.
The saved-data rules are in [session-storage.md](session-storage.md).

## Recorded results

- Full Flutter suite: **657 passed**, about 45 seconds on this host.
- Flutter analyzer: **no issues**.
- Python tool suite: **40 passed**.
- History/date tests under Honolulu and Kiritimati: **36 passed in each**.
- Localization contracts: **299 messages in each of five catalogs**; generated
  code/review CSV synchronized. Whitespace checks passed.

The full suite includes 31 new repository history cases, seven game-start/error
widget cases and five locale-specific date-label cases. Existing tests were
updated where the intended date source or future-schema policy changed.

## Original failure and fix

The old repository uses the envelope's latest-save `updatedAt` both for the
Recent Games label and order. Opening a completed game enters review, which
saves its recovery state. Re-saving an older game therefore changes its visible
date and moves it above newer games, including after restart. Its PGN Date can
remain correct throughout.

The regressions deliberately give old games a newer `updatedAt`, reopen them,
change the review PGN, save, archive, and restart. The original date, ID and
order must survive while legitimate saved data changes. New games explicitly
record their creation date and UTC instant; legacy games only recover the
original calendar day when it is valid and unambiguous.

## Reproduce the checks

```sh
flutter pub get --enforce-lockfile
flutter gen-l10n
python3 tool/check_localization.py
flutter analyze
flutter test --reporter expanded
python3 -m unittest discover -s tool -p '*_test.py'

TZ=Pacific/Honolulu flutter test test/recent_game_history_test.dart test/recent_game_history_ui_test.dart
TZ=Pacific/Kiritimati flutter test test/recent_game_history_test.dart test/recent_game_history_ui_test.dart
```

Use the Python dependencies in `tool/hardening/requirements.txt`. These tests
need no phone, electronic board, native engine process, or model download.
This local run reused an existing SDK/package cache and used `--no-pub` for
Flutter analysis/tests; CI resolves the pinned lockfile in a fresh Linux job.

## Coverage and interpretation

- Repository sequences cover immutable history, same-day/unknown ordering,
  preference migration, edited PGNs, future schemas, backup/pending preflight,
  interrupted writes, detached payloads, and deletion/tombstones.
- Widget tests cover new-game/Continue from here dates, resume/reset behavior,
  future-format warnings and blocked destructive actions, plus delayed storage
  with backgrounding and a covering route.
- Date-label tests run in English, Japanese, Simplified Chinese, Korean and
  Spanish. Running them on both sides of the date line checks that an old
  calendar date is not converted through the viewer's timezone.
- The existing full suite also exercises clocks, reset, takebacks, variation
  navigation, analysis classification, Chessnut continuation and localization.
  This is regression evidence, not physical-board or real-engine certification.
- The existing 1,000-game archive test validates listing, reopen, deletion and
  restart. A focused host run listed 1,000 entries in 343 ms. This is a host
  observation, not an Android latency promise or a timing-based test assertion.

No engine inference, analysis-depth, model, Android native, release-signing or
F-Droid changes are included. No APK was built or published for this PR.

## Device acceptance before release

On the Dev package, open an old completed game, analyze/add a variation, return
to Recent Games and restart the app: the old date and order should remain.
Resume an incomplete game and verify its clock/moves save without changing its
original date. Try Reset and Continue from here and confirm their existing
erase/source-preservation behavior. Background during a new-game transition.
Check a locale/timezone change and the localized unknown-date label.

Host lifecycle tests control Dart callbacks and real temporary session files;
they do not emulate Android process death or physical filesystem failures.
