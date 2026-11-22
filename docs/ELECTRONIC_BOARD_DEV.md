# Electronic-board testing

See the [support table](../README.md#electronic-board-support) and the
[22 November support decision](decisions/2026-11-22-electronic-board-support.md).
The updated source supports Chessnut and Grand Kingdom. Pegasus is removed
from Stable, Preview and Dev because initialization licensing is unresolved.

## Connection and play

Enable Electronic board on the new-game screen and connect. Discovery collects
supported nearby boards for three seconds: one connects automatically; multiple
boards open a chooser. A remembered supported board keeps the quick connection
path. Choose another board explicitly scans again. Bluetooth addresses are not
shown or included in exported diagnostics.

Chessnut Air and Go are fully tested; Pro uses the same protocol and awaits
further hardware testing. Chessnut supplies piece recognition, LED guidance,
untimed games, takebacks and position continuation. Press NEW GAME twice within
2.5 seconds to confirm an in-game reset. It retains colors/settings and waits
for the pieces to match the starting position before play resumes. Cancel,
backgrounding, disconnection and game changes disarm the confirmation.

Grand Kingdom is supported and has passed user acceptance testing. Confirm standard
setup before play. Maia's motor move is sent once, without automatic retries.
A generic OK is not physical-move confirmation. Assisted promotion requires
stopped motors, replacement with the indicated piece and position confirmation.
Interrupted delivery, takebacks and midgame restoration use phone continuation;
arbitrary-position motor restoration is not supported. See the
[acceptance record](ELECTRONIC_BOARD_GRAND_KINGDOM_26.md) for current hardware
feedback, historical capture reports and operating limits.

## Diagnostics and additional device coverage

Stable/Preview diagnostics retain bounded summaries. The red-icon Dev app also
records bounded local traces for app events and Grand Kingdom moves/messages;
export is manual. No automatic upload is added. See the canonical
[Dev diagnostics guide](https://github.com/Dash1971/maia-chess-android-preview/blob/main/docs/DEV_DIAGNOSTICS.md).
The separate `tool/board_capture` recorder remains Chessnut-only.

Board owners and manufacturers are welcome to help test additional models and
clarify protocols and licensing. Useful reports include board/firmware, Android
and app versions, the move sequence and what happened physically. Relevant
scenarios include captures, castling, en passant, promotions, connection loss,
background/resume, reset and recovery. Automated transport/model tests do not
establish physical behavior on a board that has not been tested.
