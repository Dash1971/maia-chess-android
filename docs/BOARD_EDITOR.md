# Preview board editor (#189)

The interaction/layout reference is Lichess mobile v0.30.1, commit
`243b19b532c86101a389072becce60e51c71bbd0`, files:
`lib/src/view/board_editor/board_editor_screen.dart` and
`lib/src/model/board_editor/board_editor_controller.dart`. The requester's three
reference images are attached to issue #189. The renderer remains the filtered,
unchanged Chessground 10.1.1 supplied by #190.

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
No e-board adapter, connection owner or synchronization policy is replaced. The
inspected base has no separate transport in BoardEditorPage; existing continuation
connection setup remains the same flow and is not a delivery of #182. Issue #39
was closed as not planned; this change does not reintroduce physical-board editing.

The menu contains Starting position, Load FEN, Continue from here and Clear board.
The toolbar has menu, flip, Analysis and position settings. Sharing uses Android's
plain-text chooser; copying works offline and is also the fallback when a native
share handler is unavailable. Neither action sends to a recipient automatically.
Variant and Challenge from position are absent. The camera entry is disabled with
an explicit unavailable label; recognition remains a dependency of #179, not a
working feature in this PR. All UI uses the selected board/piece designs and
applicable aid preferences. No renderer, model, version or channel gate changes.

New tool/share terms reuse the pinned Lichess terminology with explicit editor/FEN
adaptations. Remaining new labels are translated in all ten languages and still
need native-speaker review. The metadata sheet owns its controllers through the
route's reverse transition, preventing disposed-controller errors on dismissal.

This is a Preview feature. No shared build/CI/cleanup helper is changed, and no
Stable tooling port or feature promotion is included. Full Preview release gates
remain separate from draft PR widget/native verification.
