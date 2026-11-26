# Continue from here on an electronic board

<a id="continue-from-here-on-an-electronic-board-182"></a>

Original feature: [Preview #182](https://github.com/Dash1971/maia-chess-android-preview/issues/182).

Current support policy, 22 November 2026: Pegasus has been withdrawn from all
channels; see the [decision](decisions/2026-11-22-electronic-board-support.md).
Custom-position continuation remains Chessnut-only; Grand Kingdom support is
for untimed games from the standard starting position.

Shipped in Stable 2.5.0 and later. The owner reported physical Chessnut continuation tests passed on 27 October 2026; see the [recorded acceptance](https://github.com/Dash1971/maia-chess-android/blob/7a0f69c141c66e39be1183b3ad46f26158ff9299/docs/BUILD_CHANNELS.md#stable-25-preparation).

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

This continuation flow currently supports Chessnut only, including Dev. Grand Kingdom is limited to untimed games from the standard starting position; it is not offered for custom-position continuation. Pegasus remains withdrawn from 2.6 source/Preview. Older published APKs retain their original policy.

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

The owner-reported physical acceptance covers the Chessnut continuation flow. Future changes still require the applicable release checks and affected hardware scenarios. This does not add arbitrary-position continuation for Grand Kingdom or revive Pegasus.

No new network service is required by continuation. Physical-board support and release status are recorded in [channel status](BUILD_CHANNELS.md).
