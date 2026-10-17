# Electronic-board development snapshot

Preview 2.4 promotes only the Chessnut improvements. Grand Kingdom and DGT
remain Dev-only experiments in the shared source tree. Build-flavor restrictions
in Dart and Kotlin exclude them from Preview discovery, selection, reconnection
and command handling, including remembered devices. Do not remove these gates
without a separately reviewed promotion and physical-board acceptance.

Use [Preview releases](https://github.com/Dash1971/maia-chess-android-preview/releases)
for Chessnut testing and [Dev releases](https://github.com/Dash1971/maia-chess-android-preview-dev/releases)
for prototype board testing. See [channel status](BUILD_CHANNELS.md).

The three-second scan and in-game Chessnut reset below are included in Preview
2.4.0-beta.2. They are not in beta.1. See channel status for exact release evidence.

## What to try

- Enable Electronic board on the new-game screen and connect. Discovery collects
  recognized nearby boards for three seconds: one connects automatically, multiple
  boards open a chooser. A remembered board retains the quick connection path;
  Choose another board explicitly scans again. Bluetooth addresses are not shown
  or included in diagnostics.
- Chessnut keeps piece recognition, LED guidance, Unlimited games, takebacks and
  phone continuation. In a game, NEW GAME opens the normal reset confirmation;
  a second deliberate press within 2.5 seconds confirms it. Cancellation,
  backgrounding, disconnection and game changes disarm confirmation. Unfinished
  reset games are discarded; completed games remain in Recent Games. Chessnut
  resets stay on the play screen, retain the actual player color and current
  engine settings, and show the standard starting position. LED guidance updates
  while the pieces are replaced; no moves run until the board matches. The game
  then starts automatically (Maia moves first if the player is Black). Pending
  setup survives reconnects/restarts; Play in the app explicitly exits board setup.
- Pegasus is an occupancy-only protocol prototype. Confirm physical piece identity
  at setup; ambiguous captures/promotions need phone confirmation. **Locked
  firmware is not supported:** the manufacturer initialization key has not been
  included because the reference permission is not unrestricted/FOSS-compatible.
  An unrestricted initialization route is required before claiming support.
- Square Off Grand Kingdom is an experimental motor protocol prototype, not
  support for every Square Off model. Explicitly confirm standard setup. An engine
  move is sent once, without automatic retries. A following legal human move, or
  explicit verification of every piece against the screen, acknowledges completion.
  Generic OK is insufficient. Interrupted motor sessions, takebacks and engine
  promotions require phone continuation; arbitrary-position restoration and motor
  cancellation have no established safe protocol here.

## Development capture and diagnostics

Routine diagnostics retain bounded summaries, not Bluetooth addresses or raw
position notifications. Explicit developer capture/replay is separate; see
`tool/board_capture/capture.py --help` and `tool/board_capture/README.md`.
Capture files can reveal moves and positions; review them before sharing.

## Validation before promotion

Automated checks cover pure Kotlin discovery/framing/queue policies, Dart frame
reassembly and occupancy inference, reset timing/data preservation, connection
selection, stale sessions, lifecycle, phone continuation and all ten languages at
320×568 with 200% text. Native protocol checks run in normal PR CI through
`tool/test_board_native.sh`; the existing Flutter and Python suites remain gates.

Hardware acceptance is still required. Record board model, firmware, Android
version and APK version for each result. Test one/multiple nearby boards, denied
permissions, Bluetooth off/on, connection loss, reset double press/long hold,
castling, en passant, captures, promotions, Maia playing White, takebacks,
background/resume, saved-game restoration and continuing on the phone. Verify
LEDs physically and never infer motor completion from a successful write alone.

The owner approved only Chessnut promotion into Preview after reviewing Dev. Keep
issues #27, #38, #40 and #68 open until their relevant acceptance is complete.

See `ELECTRONIC_BOARD_NATIVE_PROTOCOL.md` for pinned upstream wire references,
licensing constraints and explicit protocol limitations.
