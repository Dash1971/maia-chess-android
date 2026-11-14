# Engine arrows and classification badges

This page documents **existing Mobile Maia behavior** and compares it with the
existing Mute Chess behavior. The documentation PR does not change either app's
arrows, models, classifications, settings or tests. No application release or
service restart is needed for these documentation changes.

The Mobile reference is commit
[`be6b97c`](https://github.com/Dash1971/maia-chess-android/commit/be6b97cd5ec0c1386233fbd824183c4fbb9c6efd):
[engine selection and agreements](https://github.com/Dash1971/maia-chess-android/blob/be6b97cd5ec0c1386233fbd824183c4fbb9c6efd/lib/src/review.dart#L1838),
[the board overlay painter](https://github.com/Dash1971/maia-chess-android/blob/be6b97cd5ec0c1386233fbd824183c4fbb9c6efd/lib/src/review_widgets.dart#L928),
and the vendored Flutter Chessground board/shape painters.

## What each color means

| Source | Shaft | Arrowhead |
| --- | --- | --- |
| Stockfish best | Blue `#3d9be9` | Blue |
| Stockfish second | Light blue `#8ac8f5` | Light blue |
| Primary Maia | Orange `#e89b3c` | Orange |
| Second Maia | Red `#e85d68` | Red |
| Stockfish and one Maia share a move | Corresponding Stockfish blue | Agreeing Maia color |
| Both Maias agree without Stockfish | Split orange/red | Split orange/red |
| Stockfish and both Maias agree | Corresponding Stockfish blue | Split orange/red |

Each Maia contributes its one top move. Stockfish contributes up to two unique PV
roots. A shared UCI is drawn once with combined colors. Distinct promotion
choices remain distinct UCIs even when their visible endpoints coincide. Arrow
colors identify engine sources, not the quality of a move.

## Paint order and overlap

Mobile Maia draws ordinary arrows inside Chessground first:

1. Independent Stockfish best.
2. Independent Stockfish second.
3. Independent primary Maia.
4. Independent second Maia.

It then draws agreement arrows in a separate overlay, in Maia-channel insertion
order. Agreement arrows therefore sit above ordinary arrows that share or cross
their paths. Both ordinary and agreement arrows are above pieces.

This does **not** mean all Stockfish arrows are uppermost. An independent Maia
arrow can cover the shaft or part of the head of an independent Stockfish arrow.

Mobile uses a quarter-square shaft for both Stockfish choices. It draws straight
arrows for knight moves too. The start is about a third of a square from the source
center; the head reaches the destination center, with head length 0.48 square and
half-angle pi/5. Board orientation mirrors the square mapping.

## Classification badges

`ReviewBoardOverlayPainter` draws agreement arrows, then the classified-square
translucent tint, then the badge circle and white symbol. Badges are above arrows.

| Classification | Symbol | Color |
| --- | --- | --- |
| Brilliant | !! | Cyan `#15aabf` |
| Good | ! | Teal `#12b886` |
| Interesting | !? | Lime `#82c91e` |
| Dubious | ?! | Yellow `#fab005` |
| Mistake | ? | Orange `#fd7e14` |
| Blunder | ?? | Red `#fa5252` |

These colors describe the selected move's classification and match its summary.
They are independent of the arrow source colors.

## Mute Chess's existing differences

Mute currently emits its best Stockfish arrow, second Stockfish arrow, then
remaining Maia moves. Combined Stockfish/Maia arrows appear in the corresponding
Stockfish slot; they do **not** have Mobile's separate later agreement overlay.
Thus a separate Maia arrow can obscure a combined Stockfish/Maia arrow. Native
Chessground also retains unchanged SVG siblings and appends changed ones, so
subsequent paint order can depend on update history. These differences are being
documented, not changed.

Mute retains Lichess's evaluation-based tapering of an independent second
Stockfish shaft; Mobile keeps fixed-width shafts. Mute also retains native
Lichess SVG badge artwork/stacking and its existing source-visibility/custom-color
preferences. Mobile uses its own badge circle/text and classified-square tint.

Three useful examples:

- SF and Maia 2600 choose Qh6, while Maia 1600 chooses Qh7: Mobile draws the
  blue/red agreement over the longer orange arrow; Mute's later orange arrow can
  cover the agreement shaft.
- SF and Maia 2600 choose Qh6, while Maia 1600 chooses Qh5: Mobile draws blue over
  the shorter orange shaft and part of its head. Mute draws orange above the
  shared section. Neither arrangement makes every shaft fully visible.
- SF chooses Rd5/Rd6 and the second Maia independently chooses Rd7: both apps
  draw the independent Maia arrow later, obscuring the blue shafts.

## Illustrated reference

The [complete current-behavior comparison](https://github.com/Dash1971/mute-chess/blob/af135a72145d6e96a7a63555076635966050427c/docs/arrow-behavior.md) contains the
source pins, fresh-board captures, retained-DOM observations and legal input
fixtures. It covers all 32 canonical engine-source combinations, both orientations,
longer/shorter/shared paths, crossings, promotions, castling, small boards and all
six badge colors. The name `agreement-18` in historical filenames identifies a
source-combination row, not an actual agreement in that position.

![Existing overlap policies compared](arrow-behavior/comparison.png)

These are actual board-renderer/surface-path captures with controlled engine
inputs, not full-device navigation screenshots or live model predictions. Every
candidate is legal from the displayed position; knight and promotion examples
show the correct source pieces. Badge examples have a valid preceding d3–d4 move
and deliberately injected labels to demonstrate all six colors and layers. They
do not claim that pawn move deserves any particular classification.

For the headless Flutter images, the existing board and overlay painter were
used with a temporary explicit Roboto font family for badge text; otherwise the
test runner substitutes Ahem rectangles. No geometry, color or ordering was
changed, and that font override is absent from the PR and application source.
Temporary capture code and test cases are not added to this documentation PR.

[Mobile documentation issue #75](https://github.com/Dash1971/maia-chess-android/issues/75) ·
[Mute behavior discussion #328](https://github.com/Dash1971/mute-chess/issues/328)
