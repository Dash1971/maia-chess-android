# Electronic-board development cycle

Agreed direction, 2026-10-07: use the isolated Dev application first. Keep Stable
publication and existing Preview promotion separate. Deliver reviewable changes
in stages; one board need not wait for an unrelated board's hardware validation.

1. **Diagnostics and replay (#40, #68).** Explicit host capture, reviewed fixtures,
   bounded app failure reports, real recovery tests. This branch is this first stage.
2. **Shared discovery/connection flow.** A generic Connect board action. On first
   use, collect candidates for a short bounded discovery window, deduplicate them,
   connect if one compatible board is found and offer a chooser if several are found.
   No results: retry and concise troubleshooting. Remember a successful selection
   locally for fast subsequent connection; always allow Choose another board.
   Reconnect during a game targets that same board, never a different nearby board.
   Advertised names are hints; verify GATT/profile compatibility before initialization.
3. **Chessnut NEW GAME (#38).** Existing reset dialog plus two deliberate presses
   within 2.5 seconds; cancellation/lifecycle disarm; shared screen/hardware reset;
   LED-guided setup before any Maia opening move. Preserve the issue's unfinished
   game deletion and completed game retention semantics.
4. **DGT Pegasus adapter.** Occupancy-based detection, promotion choice and capture
   ambiguity require explicit handling; do not claim all DGT models. MoveAPiece is a
   protocol reference subject to source/licence review, not proof of Mobile Maia
   compatibility. Physical acceptance required.
5. **Square Off Grand Kingdom (#27).** Investigate protocol, firmware, licence and
   available tester. Motors require explicit safe cancellation/reconnect behavior;
   never blindly replay movement commands or assume Chessnut's sensing/LED features.

The boundary should express actual capabilities (piece identity vs occupancy,
LEDs, sound, battery, physical buttons, motors) without board-specific branches
spreading through game logic. Preserve phone continuation, saved games, the
Chessnut Unlimited rule, and existing local/offline operation.

Hardware coverage record: retain model, deliberately supplied firmware, Android
version and each tested scenario. Fake/replayed transports cannot certify BLE
pairing, physical moves, LEDs or motors. Keep unsupported models unavailable rather
than listing an aspirational family-wide compatibility claim.

Regression priorities: two boards, late discovery, duplicate advertisements,
permission denial, wrong GATT profile, transient/partial moves, disconnect during
input/setup/LED delivery, stale callbacks after reconnection, screen continuation,
background/resume, reset during inference and existing archive consistency.

Issue references:
- https://github.com/Dash1971/maia-chess-android-preview/issues/40
- https://github.com/Dash1971/maia-chess-android-preview/issues/68
- https://github.com/Dash1971/maia-chess-android-preview/issues/38
- https://github.com/Dash1971/maia-chess-android-preview/issues/27
