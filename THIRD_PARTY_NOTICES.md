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

The optional Maia score follows the upstream expected-score definition. Pinned
outcome-channel and website references are in [docs/MAIA_SCORE.md](docs/MAIA_SCORE.md).

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

## Lichess UI translations

- Project: <https://github.com/lichess-org/mobile>
- Pinned source: `99dd3e0e4859afc7de37290b3f1905045af92004`
- Source catalogs: `lib/l10n/app_{en,ja,zh,ko,es,de,fr,ru,hi,pt_BR}.arb`
- Copyright: Lichess contributors and community translators
- Licence: GNU General Public License v3.0 or later

Shared chess and UI terminology is adapted from these catalogs. The exact
reference strings and context adaptations are recorded in
`docs/lichess-terminology.json`; review and maintenance are documented in
`docs/LICHESS_TERMINOLOGY.md`. The adapted material remains subject to GPL-3.0;
Mobile Maia as a combined application is distributed under AGPL-3.0-only as
permitted by section 13 of AGPL-3.0.

## Dart crypto

- Project: <https://github.com/dart-lang/core/tree/main/pkgs/crypto>
- Copyright: The Dart project authors
- Licence: BSD 3-Clause (included in Flutter's generated package licences)
- Used for local sampling-export SHA-256 checksums; no network functionality.

Readable sampling reports embed the existing Cburnett pieces as WebP images.
The original artwork by Colin M. L. Burnett is also offered under CC BY-SA 3.0
(see <https://commons.wikimedia.org/wiki/File:Chess_plt45.svg> and the related
piece set). The report carries artist attribution, the conversion notice, and
links to the artwork and <https://creativecommons.org/licenses/by-sa/3.0/>.
No external image requests are made when opening a report.

## Material dynamic color

- Project: <https://github.com/material-foundation/flutter-packages/tree/main/packages/dynamic_color>
- Package: `dynamic_color` 1.9.0
- Copyright: The Material Flutter authors
- Licence: Apache License 2.0 (included in Flutter's generated package licences)
- Reads Android's system palette locally for the optional appearance setting.

## Board and piece artwork (Preview #177)

The offline catalogue uses byte-identical assets from flutter-chessground 10.1.1,
commit `0bd34fbe720097c4a51172e2c0d8f697637eda01`. Its renderer remains GPL-3.0;
only its asset declarations have been filtered. Asset-specific terms follow
[Lila COPYING.md at `995e7ccc4a719bf45923202a1e8d55121df78283`](https://github.com/lichess-org/lila/blob/995e7ccc4a719bf45923202a1e8d55121df78283/COPYING.md).
The exact source paths, Git blobs, SHA-256 hashes, exclusions and changes are
recorded in `docs/board-style-assets.json` in the app source.

| Artwork | Author | License |
| --- | --- | --- |
| boards | the lila authors and pirouetti | AGPL-3.0-or-later |
| cburnett | Colin M.L. Burnett | GPL-2.0-or-later |
| merida | Armando Hernandez Marroquin | GPL-2.0-or-later |
| pirouetti | pirouetti | AGPL-3.0-or-later |
| chessnut | Alexis Luengas | Apache-2.0 |
| kosal | the lila authors | AGPL-3.0-or-later |
| fantasy | Maurizio Monge | MIT |
| spatial | Maurizio Monge | MIT |
| celtic | Maurizio Monge | MIT |
| pixel | therealqtpi | AGPL-3.0-or-later |
| firi | James Faure | CC-BY-4.0 |
| rhosgfx | RhosGFX | CC0-1.0 |
| governor | the lila authors | AGPL-3.0-or-later |
| mpchess | Maxime Chupin | GPL-3.0-or-later |
| shapes | flugsio | CC-BY-SA-4.0 |
| kiwen-suwi | neverRare | CC-BY-4.0 |
| letter | usolando | AGPL-3.0-or-later |

Piece artwork was rasterized upstream from Lila SVGs into WebP in multiple
resolutions using the preserved `scripts/convert_svgs_to_webp.sh`; Mobile Maia
makes no image conversion or artwork changes. Board textures are unchanged.
The source for piece sets is `public/piece/<set>` and for boards
`public/images/board` in Lila; the renderer source supplies the exact packaged
files. Kosal and Governor use Lila's default AGPLv3+ grant for files without a
separate exception. Horsey **board** artwork is covered by the board grant;
the separately licensed Horsey **pieces** are excluded.

Complete license texts and upstream notices are bundled under
`third_party/chessground/notices/` and available through the app's license
information. Attribution links: [Chessnut](https://github.com/LexLuengas/chessnut-pieces),
[Maurizio Monge's art](https://github.com/maurimo/chess-art),
[Shapes](https://github.com/flugsio/chess_shapes),
[Firi](https://github.com/jfaure/Firi-pieceset),
[Mpchess](https://github.com/chupinmaxime),
[Kiwen-suwi](https://github.com/neverRare),
[RhosGFX](https://rhosgfx.itch.io/).
The CC BY / CC BY-SA / CC0 license names above link to the corresponding
bundled full terms; source and author links are preserved in Lila's bundled
COPYING notice. Restricted, noncommercial and unresolved sets are omitted
from both the selector and the distributed package asset declarations.

## Lichess mobile board editor interaction reference

- Source: https://github.com/lichess-org/mobile
- Revision: v0.30.1, `243b19b532c86101a389072becce60e51c71bbd0`
- Files: `lib/src/view/board_editor/board_editor_screen.dart` and
  `lib/src/model/board_editor/board_editor_controller.dart`
- Authors: Lichess contributors; license: GNU GPL v3.

Mobile Maia's editor layout and placement/drag/castling behavior are adapted from
this reference with its own standard-chess draft state, accessible touch tools,
local analysis/continuation and FEN flows. Variant/challenge/image recognition are
not copied as working features. The adapted component remains subject to GPL v3;
the combined application is distributed under AGPL-3.0-only as permitted by
section 13. The existing bundled GPL license text is available in license information.
