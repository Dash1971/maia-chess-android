# Third-party notices

## En Croissant

- Project: <https://github.com/franciscoBSalgueiro/en-croissant>
- Upstream release: [`v0.15.0`](https://github.com/franciscoBSalgueiro/en-croissant/tree/v0.15.0)
- Pinned source commit: `3a3dbc5911dd0cd4997c30ea3e8932045e314830`
- Relevant source: [`src/utils/score.ts`](https://github.com/franciscoBSalgueiro/en-croissant/blob/v0.15.0/src/utils/score.ts) and [`src-tauri/src/chess.rs`](https://github.com/franciscoBSalgueiro/en-croissant/blob/v0.15.0/src-tauri/src/chess.rs)
- Copyright: Francisco Salgueiro and En Croissant contributors
- Licence: GNU General Public License v3.0

Mobile Maia's Game Review move-classification and sacrifice-detection
heuristics are adapted and translated to Dart from the linked En Croissant
source. Mobile Maia modifies the upstream implementation with bounded search,
background-isolate execution, and app-specific review integration. The
adapted code remains subject to GPL-3.0; Mobile Maia as a combined application
is distributed under AGPL-3.0-only as permitted by section 13 of AGPL-3.0.

## Maia-3

- Project: <https://github.com/CSSLab/maia3>
- Model: <https://huggingface.co/UofTCSSLab/Maia3-79M>
- Copyright: University of Toronto CSSLab contributors
- Licence: GNU Affero General Public License v3.0

`assets/models/maia3-79m.onnx` is a converted form of the released Maia-3 79M
checkpoint. The corresponding architecture, original checkpoint, inference
source, and licence are available from the links above. The conversion tool is
included in `tool/export_maia3_onnx.py`. Exact source revisions, checkpoint and
conversion hashes, and reproduction instructions are recorded in
`MODEL_PROVENANCE.md`.

## Stockfish and multistockfish

- Stockfish: <https://github.com/official-stockfish/Stockfish>
- multistockfish: <https://github.com/lichess-org/dart-multistockfish>
- Licence: GNU General Public License v3.0

The Android application uses the Stockfish 16 engine provided by multistockfish.
Corresponding source and build instructions are available in the linked
repositories.

## Flutter Chessground

- Project: <https://github.com/lichess-org/flutter-chessground>
- Copyright: Lichess contributors
- Licence: GNU General Public License v3.0

The game board uses Lichess's default brown colour scheme and Cburnett pieces.

## Lichess icon font

- Project: <https://github.com/lichess-org/mobile>
- Pinned source commit: `a98315df95ca7dade9afe3bc826072ee159a60a0`
- Font source: `assets/fonts/LichessIcons.ttf`
- Copyright: Lichess contributors and the original FlutterIcon/Fontello icon authors
- Licences: GNU General Public License v3.0 for Lichess Mobile; component icons
  include Font Awesome and Entypo glyphs under the SIL Open Font License

`assets/fonts/LichessIcons.ttf` is the unmodified upstream font. Mobile Maia
uses its Font Awesome chess-piece glyphs for the Lichess-style material
difference display. The upstream generated icon declaration records the
component authors and licence links.

## dartchess

- Project: <https://github.com/lichess-org/dartchess>
- Copyright: Lichess contributors
- Licence: GNU General Public License v3.0

Mobile Maia uses dartchess directly for chess positions, move generation, and
game-tree operations.

## Lichess chess opening names

- Project: <https://github.com/lichess-org/chess-openings>
- Pinned source commit: `4b8622759e7ae6f93f011cc6c83a3823401ab45e`
- Licence: CC0 1.0 Universal / public domain dedication

`assets/openings/lichess_openings.tsv` is generated from the project's ECO
A–E source files. The bundled CC0 legal text is retained beside the dataset.

## ONNX Runtime

- Project: <https://github.com/microsoft/onnxruntime>
- Licence: MIT

## chess.dart

- Project: <https://github.com/davecom/chess.dart>
- Copyright: David Kopec and contributors
- Licence: MIT; based on chess.js under the BSD licence

## Flutter

- Project: <https://github.com/flutter/flutter>
- Licence: BSD 3-Clause
