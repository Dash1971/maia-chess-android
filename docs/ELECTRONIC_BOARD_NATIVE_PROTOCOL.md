# Native electronic-board protocol evidence

## Current references

- [MoveAPiece](https://github.com/egdels/moveapiece/tree/560b862be18485ecebe98cfe2f26965e10315a2d), GPLv3: Chessnut frame handling. Wire facts were independently implemented; the separate Pegasus prototype has been removed.
- [square-off-remote](https://github.com/greghope667/square-off-remote/tree/c64fc4d99d70071707ebd1acd16442eb3d0a6083), GPL-3.0-or-later: `communicator.py` and `squareoff.py`, explicitly targeting Grand Kingdom.

Pegasus is not supported in any channel. The
[support decision](decisions/2026-11-22-electronic-board-support.md) records the
initialization-permission uncertainty and links the upstream inquiry. Its GPL
protocol-reference license is distinct from initialization permission. No
initialization key, Pegasus decoder, occupancy inference or LED adapter remains.

## Chessnut

The existing write/data/confirm UUIDs and commands are retained. Framed `01 24`
38-byte board reports preserve wire bytes for the Dart decoder; confirmation
`0f 01 02` represents NEW GAME. Known frames are bounded to 256 buffered bytes,
with a 1.5-second fragment expiration and reset at the end of a GATT session.
Legacy unframed 32-byte reports remain accepted. Dart owns physical-button
confirmation and debounce. Chessnut-specific sounds and LED commands remain
under the Chessnut transport.

## Grand Kingdom

Nordic UART service `6e400001-b5a3-f393-e0a9-e50e24dcca9e` uses write `...0002...`
and notify `...0003...`. Advertised model hints and expected characteristics
select Grand Kingdom; another product using the same UUID is not sufficient.

Outgoing commands are ASCII `x` + payload + `z`, with payload at most sixteen
characters. CONNECTED initializes communication. Explicit start writes RSTVAR
followed by GAMEWHITE/GAMEBLACK/LIVE. RSTVAR resets game variables; it is not a
physical setup or motor-cancellation command. Moves use exactly four UCI
coordinates. The full promotion move stays in chess/storage while only the
coordinate prefix is sent for motor movement; physical replacement requires
explicit confirmation.

The inbound reference strips whitespace and does not establish x/z delimiters.
The decoder accepts bounded fragments, exact coordinate moves and known control
messages; metadata never becomes a move. Native code does not automatically
start a game or resend movement. A pending motor operation requires a legal
subsequent physical move explicitly acknowledged by Dart, or explicit position
confirmation. An uncorrelated OK does not establish physical completion and
cannot confirm a promotion. There is no sourced motor-stop opcode.

Disconnect/timeout invalidates queued writes. Interrupted movement requires
phone continuation and fresh standard setup; arbitrary-position restoration and
automatic replay are not supported. See the
[Grand Kingdom acceptance record](ELECTRONIC_BOARD_GRAND_KINGDOM_26.md).

## Session and channel safeguards

Discovery holds at most 32 deduplicated candidates for three seconds and emits
opaque, scan-bound selection IDs. Addresses remain in private Android
preferences. Each connection has a new session token; stale deliveries cannot
change the current game. Motor writes require the exact live, ready Grand
Kingdom session. Unknown/retired native kinds are ignored before they can fall
back to the legacy Chessnut path. Both channels keep their existing Grand
Kingdom flavor boundaries; Dev no longer enables additional board families.

Dart and pure Kotlin regressions cover discovery, framing, session guards and
legacy phone recovery. Hardware, Android callbacks and physical motor/LED
behavior still require the normal device/release checks.
