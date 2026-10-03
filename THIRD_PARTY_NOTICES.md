# Third-party notices

## Chessnut e-board protocol

- Official API: <https://github.com/chessnutech/Chessnut_eBoards>
- Official EasyLinkSDK: <https://github.com/chessnutech/EasyLinkSDK>
- EasyLinkSDK copyright: Copyright (c) 2022 chessnutech
- EasyLinkSDK licence: MIT License
- Reference implementation: <https://github.com/rmarabini/chessnutair>
- Reference implementation copyright: Roberto Marabini and contributors
- Reference implementation licence: GNU General Public License v3.0

Mobile Maia's Chessnut Bluetooth protocol constants, board-position decoding,
and LED mapping follow Chessnut's published API and were cross-checked against
the GPL-3.0 chessnutair reference implementation. The buzzer command encoding
follows Chessnut's MIT-licensed EasyLinkSDK. The Android/Kotlin transport and
Dart game integration are new adaptations for Mobile Maia and are
distributed with the combined application under AGPL-3.0-only as permitted by
section 13 of AGPL-3.0.

The EasyLinkSDK licence notice follows:

> MIT License
>
> Copyright (c) 2022 chessnutech
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.

## En Croissant

- Project: <https://github.com/franciscoBSalgueiro/en-croissant>
- Upstream release: [`v0.15.0`](https://github.com/franciscoBSalgueiro/en-croissant/tree/v0.15.0)
- Annotated tag object: `3a3dbc5911dd0cd4997c30ea3e8932045e314830`
- Pinned source commit: `6f2d2628f0fbe11cb62a7dd2f9c102bb52907d53`
- Relevant source: [`src/utils/score.ts`](https://github.com/franciscoBSalgueiro/en-croissant/blob/v0.15.0/src/utils/score.ts) and [`src-tauri/src/chess.rs`](https://github.com/franciscoBSalgueiro/en-croissant/blob/v0.15.0/src-tauri/src/chess.rs)
- Copyright: Francisco Salgueiro and En Croissant contributors
- Licence: GNU General Public License v3.0

Mobile Maia's Game Review move-classification and sacrifice-detection
heuristics are adapted and translated to Dart from the linked En Croissant
source. Mobile Maia modifies the upstream implementation with
background-isolate execution, conservative annotation evidence checks in all analysis modes and
app-specific review integration. The independent test reference under
`tool/hardening/classification/reference` also includes the upstream scoring,
annotation and material-search functions. The
adapted code remains subject to GPL-3.0; Mobile Maia as a combined application
is distributed under AGPL-3.0-only as permitted by section 13 of AGPL-3.0.

## Maia-3

- Project: <https://github.com/CSSLab/maia3>
- Model: <https://huggingface.co/UofTCSSLab/Maia3-79M>
- Copyright: University of Toronto CSSLab contributors
- Licence: GNU Affero General Public License v3.0

`assets/models/maia3-79m.onnx` is a converted form of the released Maia-3 79M
checkpoint. The corresponding architecture, original checkpoint, inference
source, and licence are available from the link above. The conversion tool is
included in `tool/export_maia3_onnx.py`. Exact source revisions, checkpoint and
conversion hashes, and reproduction instructions are recorded in
`MODEL_PROVENANCE.md`.

## Stockfish and multistockfish

- Stockfish: <https://github.com/official-stockfish/Stockfish>
- multistockfish: <https://github.com/lichess-org/dart-multistockfish>
- Licence: GNU General Public License v3.0

The Android application uses Stockfish 19 Light through multistockfish 0.6.1
and its multistockfish_light 0.1.0 native package. Corresponding source and
build instructions are available in the linked repositories.

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

## Lichess game sounds

- Project: <https://github.com/lichess-org/mobile>
- Pinned source commit: `56eddc238fe485eb49beb6f3c4b483afd3624b93`
- Sound assets: `assets/sounds/standard/{move,capture,error,dong}.mp3`
- Copyright: Lichess Mobile contributors
- Licence: GNU General Public License v3.0 or later for Lichess Mobile

The four audio clips are unmodified files from the pinned Lichess Mobile
revision. Mobile Maia uses them for accepted moves, captures, rejected input,
and game completion. The event mapping and app-specific suppression rules are
recorded in [`docs/game-feedback-reference.md`](docs/game-feedback-reference.md).
Audio playback is implemented in Mobile Maia with Android's platform
`SoundPool` API; no third-party audio plugin is included.
Mobile Maia as a combined application remains distributed under
AGPL-3.0-only as permitted by section 13 of AGPL-3.0.

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
