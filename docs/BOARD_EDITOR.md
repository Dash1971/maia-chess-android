# Board editor

**Status:** shipped in Stable 2.5.0 and later, and in Preview. This page describes the feature; dated qualification remains in the release records.

The existing editor is retained in Stable 2.6. Camera and screenshot recognition
are not included. The original Preview work is recorded in
[Preview #189](https://github.com/Dash1971/maia-chess-android-preview/issues/189).

The interaction/layout reference is Lichess mobile v0.30.1, commit
`243b19b532c86101a389072becce60e51c71bbd0`, files:
`lib/src/view/board_editor/board_editor_screen.dart` and
`lib/src/model/board_editor/board_editor_controller.dart`. The requester's three
reference images are attached to issue [#189](https://github.com/Dash1971/maia-chess-android-preview/issues/189). The renderer remains the filtered,
unchanged Chessground 10.1.1 supplied by [#190](https://github.com/Dash1971/maia-chess-android-preview/issues/190).

The portrait editor puts black and white graphical palettes above/below the board
and swaps their order on flip. Each has hand/move, six pieces and erase. Selected
piece taps repeatedly place/remove that exact piece, matching upstream; palette
pieces can also be dragged onto the board. A palette drag returns to hand mode.
Existing pieces can be dragged, moved by two taps, or discarded off-board. Erase
mode supports touch/pan deletion. Unpainted, labelled square semantics add an
accessible editing path without intercepting pointer dragging.

At 320 px, palettes wrap to two rows to preserve 44 px targets. Landscape uses a
large board beside the palettes/actions; the position controls are in a scrollable
sheet, not a permanent form squeezing the board. Four independent castling rights,
side to move, en-passant target and FEN counters remain editable. Counters and
metadata survive movement/flip and full-FEN round trips. As upstream, exported
castling rights are filtered to king/rook starting-square availability.

Board-only FEN loading preserves metadata. Full FEN loading updates all six fields
atomically. Malformed/variant FEN is rejected without replacing the draft. Missing
or duplicate kings remain editable, while Analysis and Continue validate through
Dartchess and the existing AnalysisSession validator. Only a valid Analysis result
replaces the parent analysis. Continue uses the existing side/rating/time-control
dialog and GamePage callback, leaving the editor/parent unchanged if cancelled.
No e-board adapter, connection owner or synchronization policy is replaced. For Chessnut connection and setup from a chosen position, see
[Continue from here on an electronic board](CONTINUATION_ELECTRONIC_BOARD.md).
[Physical-board editing (#39)](https://github.com/Dash1971/maia-chess-android-preview/issues/39)
was closed as not planned.

The menu contains Starting position, Load FEN, Continue from here and Clear board.
The toolbar has menu, flip, Analysis and position settings. Sharing uses Android's
plain-text chooser; copying works offline and is also the fallback when a native
share handler is unavailable. Neither action sends to a recipient automatically.
Variant, Challenge from position and camera/image recognition are absent.
Camera and screenshot import have been shelved after the
[offline model investigation](https://github.com/Dash1971/mobile-maia-research/blob/main/studies/offline-board-recognition-2026-11-13/REPORT.md).
Manual editing, FEN loading, Analysis and Continue from here retain their normal
position validation and selected board/piece designs and aid preferences.

New tool/share terms reuse the pinned Lichess terminology with explicit editor/FEN
adaptations. Remaining new labels are translated in all ten languages and still
need native-speaker review. The metadata sheet owns its controllers through the
route's reverse transition, preventing disposed-controller errors on dismissal.

Stable 2.6 keeps the manual editor and removes the disabled camera placeholder.
See the [release procedure](RELEASING.md) for Stable qualification; earlier
Preview evidence applies only to its recorded artifacts.
