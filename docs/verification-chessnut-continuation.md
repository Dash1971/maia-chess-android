# Chessnut to on-screen continuation — 2.1 release preparation

2026-09-10. Base: `58d7b98` (Preview `v2.1.0-beta.15`).
Implementation: `613ddc290f2ff9e9e77d8819f4591ca95ed6ab33`.
[PR #6](https://github.com/Dash1971/maia-chess-android-preview/pull/6).

## Behavior

- Completed saved games do not reactivate Chessnut mode, pending physical-move
  acknowledgement, or the Home toggle. Final PGN results are recognized even
  when older records lack a separate forced-result field. Opening another
  completed game resets the result-dialog state.
- Unfinished board games retain Reconnect. A connection card also offers
  **Play in app**, including while reconnecting. The Bluetooth menu offers the
  same switch while connected, so the player can leave the board deliberately.
- Switching keeps the current app position, moves, variations, rating,
  orientation, unlimited time control, and archive identity. It saves the
  input-mode choice. Maia moves already committed on screen are not replayed.
- Obsolete inference, LED, board-position, connection and draw callbacks cannot
  undo the handoff. Disconnect is bounded and does not block input or saving.
- Actions have at least 48 logical pixels of height and stack at large text
  sizes. Both menus scroll on short screens, correcting an overflow exposed
  while testing the draw-offer case.

The widget-rendered preview below uses the app's color scheme and a synthetic
regression game, not a physical Chessnut board:

<img src="screenshots/20260910_v0_chessnut_phone_continuation.png" width="300" alt="Chessnut connection card with Reconnect and Play in app above the board">

## Completed verification

- **224 host tests pass**, including **20 new tests**. The original six
  continuation/restoration tests failed against the unmodified beta.15 code.
- Coverage includes finished and unfinished saves, saved phone choice,
  reconnect, connected handoff, missing/failed disconnect completion, late
  events, inference replacement, pending Maia acknowledgement, takebacks,
  delayed physical human moves, Maia retry, draw adjudication, and checkmate.
- Portrait and landscape layouts pass at normal and 200% text size; the new
  controls remain reachable and menus scroll without layout overflow.
- **Eight API 36 ARM64 Android integration tests pass** with real bundled Maia
  and Stockfish. New cases open completed and incomplete Recent games from
  real app-private storage, play on screen with real Maia, and verify that
  saving/reopening retains the archive identity and phone input choice.
  Electronic-board transport is simulated.
- **10,000 independent python-chess positions** pass the chess oracle. Existing
  sampling, engine-queue, storage/archive, analysis/variation, import and
  simulated BLE regressions all pass. **Two Python tooling tests pass.**
- **Static analysis is clean.**

Final release artifact hashes, smoke-test results and GitHub CI status are
recorded in the PR. Model weights, dependencies, package identity and production
signing configuration are unchanged. These checks use the Mac and emulator;
physical phone and Chessnut verification remain the user's hardware tests.
