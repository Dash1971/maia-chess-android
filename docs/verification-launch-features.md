# Launch features and regression verification

Baseline: preview `main` at `8df2a52` (merged Chessnut phone-continuation PR).
Test environment: Apple Silicon macOS, pinned Flutter 3.47.1 / Dart, JDK 17,
AOSP API 36 ARM64 emulator. No phone or physical electronic board is required
for the automated checks below.

## Delivered issues

| Issue | Behavior | Regression coverage |
| --- | --- | --- |
| #7 | Tap history arrows for one ply; hold to reach the beginning/latest position. | Live and completed games, disabled boundaries, unchanged saved game/clock state; existing Analysis Board navigation suite retained. |
| #8 | Persistent premove enable switch, optional exact 100 ms charge, optional multiple premoves. Defaults retain single premoves without a fixed charge. | All four combinations in timed and unlimited games; both colours; 99/100/101 ms; increment and no increment; actual taps/drags on projected pieces; invalidation, cancellation, promotion, underpromotion, castling, recapture, en passant, mate, reset, history, takeback, restart, and Chessnut exclusion. |
| #9 | Completed-game clocks follow the selected ply; final clocks retain the actual ending values. | Increment, no increment, timeout, initial/final jumps, unknown/malformed snapshots, completed restore, native Recent Games; no clock is started for completed history. |
| #10 | Standard TimeControl and millisecond clk comments from recorded move snapshots across exports and persistence. | Header precision, custom control, Black-to-move FEN, correct mover/ply, restored annotations/NAGs/branches, takeback alignment, unavailable history, unlimited games, native clipboard and file persistence. |
| #11 | Completed games use New game and remain in Recent Games; unfinished games retain destructive Reset. | Cancel and confirm paths; checkmate, stalemate, resignation, agreement, timeout; native archive ID, PGN, result, clock history, variations and unrelated records retained. |

## Design and data decisions

- Queued moves are a visual plan; engine inputs and saved game positions always
  use the real game. At most one queued move executes after each Maia reply,
  only if legal in the actual resulting position.
- Multiple-premoves mode uses the existing blue/purple premove colour. The last
  queued use of a square chooses its source/destination tint; opacity does not
  accumulate. A horizontally scrollable ordered strip retains the full sequence
  and provides a 48 px cancel target. Space is reserved while this option is on
  so the board does not move or resize during a gesture.
- The queue is bounded at 64 entries; excess input gives an explanatory message.
  Updates in the same event-loop turn are coalesced. Premoves are ephemeral and
  are deliberately cleared on restore and other invalidating transitions.
- An enabled penalty replaces processing-time deduction with exactly 100 ms;
  the normal increment follows only a successfully committed move. Unlimited
  games bypass both charging and flag-fall logic.
- Missing or malformed clock-history entries remain unknown at their original
  indices. They display a dash and generate no clock annotation. Existing PGN
  TimeControl/clk data is retained rather than guessed or overwritten.
- A recursive annotation variation needs a played sibling move. If a takeback
  leaves no replacement move at that point, export describes the unplayed line
  in a comment. The complete editable tree remains in session JSON and becomes
  a normal PGN variation after a replacement is played. This prevents reopening
  a truncated game from silently replaying its abandoned continuation.

## Additional hardening

- Final clocks now capture elapsed time before resignation or an accepted draw,
  instead of reverting to the start-of-turn clock. A late resignation cannot
  replace a timeout or a result from a different game generation.
- Completed-game restore never starts a stopwatch. The existing timer is still
  used only for unfinished timed games.
- Restoring normal checkpoints reuses already parsed mainline annotations rather
  than parsing the entire variation tree again when that tree is in the JSON.
- A legacy takeback without its target clock snapshot retains both current
  clocks from before the side-to-move changes, avoiding a deduction from the
  wrong player.
- Takebacks retain existing move comments and NAGs in the abandoned branch but
  remove mainline-only clock tags, including after a save/reopen cycle.
- Timed clocks and game controls fit compact portrait and landscape layouts at
  enlarged text sizes; clock text scales down only when its available width
  requires it. The new queue does not cause board resizing during input.
- King-to-rook castling gestures are normalized to the game's standard UCI move
  for both single and multiple premoves.

## Verification results

| Check | Result |
| --- | --- |
| Static analysis | Passed, no issues. |
| Mac unit/widget regressions | The final full suite passed all 286 tests, including the added drag, legacy-takeback, and restored timed-takeback regressions; the affected-area suites also passed. |
| Android integration | All 11 tests passed, including real Maia and Stockfish. The subsequent legacy-clock fallback fix passed its affected-area host suite and release verification. |
| Independent chess oracle | All 20,000 positions and full move vocabulary/mirroring passed. |
| Python tooling | Both tests passed. |
| Layout checks | All four orientations/text-size configurations passed; PNGs inspected. |
| Bundled model | 316,034,244 bytes; SHA-256 `3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`. |
| Release APK | ARM64 release built and installed; signature, bundled model, offline permissions, saved-game restore, long-press clock boundaries, and completed-game archive preservation verified. |

The first expanded run found an existing settings test trying to tap a control
that had moved below the viewport. It now scrolls to that control; the targeted
settings suite and subsequent full regression run both passed. Layout failures
found while adding the new tests were fixed before the final runs.

The expanded corpus contains 20,000 positions from seed 20260912 and includes
castling, pinned en passant, promotions, terminal positions, and fifty-move
boundaries. Checks compare legal moves, resulting FENs, mate/stalemate, token
encodings, PGN round trips, and Chessnut position-to-move inference with
python-chess. The complete 4,352-move vocabulary and Black-side mirroring are
also compared. This supplements the repository's sampling, inference queue,
Stockfish recovery, storage recovery/stress, share/import, variation navigation,
and simulated Chessnut regression suites.

Reproduction commands (with the project's pinned Flutter and verified model):

```sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
python3 -m unittest discover -s tool -p '*_test.py'
python3 tool/hardening/generate_chess_corpus.py --positions 20000 --seed 20260912 --output /tmp/maia-launch-corpus.json
MAIA_CHESS_CORPUS=/tmp/maia-launch-corpus.json flutter test --no-pub test/chess_oracle_test.dart --reporter expanded
flutter test --no-pub integration_test/review_android_test.dart -d emulator-5554 --reporter expanded
tool/build_android_release.sh
```

The corpus generator requires the optional python-chess development dependency.
The app itself adds no new dependencies and no network requirement.

Pre-review Android runtime commit: `48f7a8d09415242b459ce33b9a3e4bb7814704b6`.
Review hardening commit: `ab37f818e7d2e748837b6edf8c12dde1cb6114a1`;
its static analysis, affected-area tests, and complete 286-test host suite passed.
Unsigned APK: 393,503,519
bytes, SHA-256 `99ccb2bff1185b1fd9e246371625070f4421c5f59dc6206887d233fcaab90517`. The emulator used a separate local test-signed
copy. Production signing keys were not used. The clean build passed and the
final legacy fix was rebuilt with the same locked, reproducible release
configuration. A restored game reached its first Android activity frame in
778 ms on this emulator; this single measurement is not a real-phone benchmark.

## Visual checks

![Multiple premoves](screenshots/20260910_v0_launch_premoves.png)

![Completed-game confirmation in the release APK](screenshots/20260910_v0_launch_new_game.png)

The premove screenshot is rendered from the actual game widget and board assets. Layout
checks cover 360×720 portrait, 320×568 at 2× text, and 800×360 landscape at 1× and
2× text. Actual tap targets, board size stability, queue cancellation, and Flutter
layout exceptions are asserted.

## Limits

These checks establish the tested software behavior; they do not establish that
there are no remaining bugs. Real-phone ergonomics, battery/performance across
devices, Bluetooth radio behavior, and physical Chessnut validation remain the
user's device checks. No production signing, release publication, or merge is
performed by this PR.
