# Continue from here on an electronic board (#182)

Proposed for Stable 2.5 after Preview beta.10. The owner reported physical
Chessnut tests passed on 2026-10-27. Stable APK qualification remains pending;
see [promotion preparation](stable-2.5-preparation.md).

The existing continuation dialog keeps side, Maia rating and phone time-control
choices, and adds **Use electronic board** (off on each opening). Selecting it
connects through the existing Android transport and permission flow. A single
recognised board connects automatically; several candidates use a chooser.
A connected board, or discovery already in progress, is borrowed without
starting another scan. Failure offers Retry; switching the option off restores
the selected phone clock. Cancel preserves the analysis position and settings.

**Set up board** transfers the connection into a new untimed continuation game.
The full FEN and validated move-history prefix are retained. Piece placement
alone never determines castling rights, en-passant rights or the side to move.
Maia and user moves stay paused until a fresh, ready board matches the selected
position. Mismatched squares receive the existing LED guidance. The normal
starting position is not required. Disconnect/reconnect and background/foreground
changes preserve this setup wait. **Play in the app** is available during setup;
it continues the same position untimed, without requiring a physical board.

## Supported scope

This continuation flow currently supports Chessnut only, including Dev. Pegasus
and Grand Kingdom adapters do not have verified arbitrary-position setup and
motor-state recovery, so they are not offered here. Existing native/Dart channel
gates remain unchanged. This does not enable new board models in Preview/Stable.

## Ownership and storage

`BoardConnectionSession` keeps one underlying transport subscription/decoder.
Each game or continuation dialog has a lease. Acquiring ownership suspends the
covered game and invalidates its pending LED/input/inference work. Only the active
lease receives events or sends commands. The dialog transfers that same lease to
the new game. Status, identity, battery and the latest valid piece snapshot are
replayed in order; stale retired-session events are ignored.

Commands are ordered for handoff. A new native connection starts a fresh command
queue so a lost connection's LED acknowledgement cannot block new guidance.
Queued stale commands check both their owner and connection generation.

Canceling a borrowed connection restores the original owner; canceling a newly
opened connection disconnects it. Finishing a continuation does not silently
reactivate an old game owner. No lease or Bluetooth address is added to persistent
settings. Physical setup uses the existing `chessnutResetPending` checkpoint flag,
so a process restart preserves the paused position without a data migration.

## Verification and release acceptance

Automated tests cover ownership, snapshots, stale commands, stream recovery,
connection reuse, cancellation, retry, FEN/history/clock preservation, setup wait,
phone fallback, localization/layout, and existing board reset/reconnect behavior.
These use controlled transports, not physical Bluetooth hardware.

Publication requires the normal automated Preview Android/reproduction, signing,
upgrade and download gates. The requester explicitly authorized publishing this
Preview for physical testing. Physical Chessnut acceptance remains pending: connect from analysis, reuse a home connection,
place a custom position, verify mismatch LEDs, start for either side, disconnect
and reconnect during setup/play, cancel, and switch to phone play. Check an
existing saved game and ordinary home-board play as regressions.

No new dependency, permission, network service, asset or build helper is added.
No Stable build-tooling companion applies; this feature travels with a future
explicitly authorized Preview-to-Stable promotion.
