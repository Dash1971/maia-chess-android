# Mobile Maia

Mobile Maia is a free and open-source Android app for playing against
[Maia-3](https://github.com/CSSLab/maia3), reviewing games with Maia and
Stockfish, and exploring the difference between the best computer move and the
move a human is actually likely to play. Everything runs locally on the phone.

Maia-3 is the latest generation of the human-like chess model developed by the
University of Toronto Computational Social Science Lab. Published as part of
the [Chessformer paper at ICLR 2026](https://openreview.net/forum?id=2ltBRzEHyd),
its largest model achieved 57.1% human move-matching accuracy—a new state of the
art in the paper's evaluation.

That may not sound extraordinary until you consider how many reasonable moves
there can be in a chess position. Maia is not trying to calculate the
objectively best move. It is trying to predict what a person will actually
play. That difference is the reason Mobile Maia exists.

### A patient, human-like sparring partner

Choose a Maia rating from 500 to 2500 and play as White, Black, or a random
side. The aim is not to imitate a weakened superhuman engine that plays
perfectly and then drops a piece for no human reason. It is to provide a
level-appropriate opponent whose choices resemble human choices.

Maia will never rage quit, cheat, send abuse in chat, or become impatient while
you think. If you want to spend ten minutes working through a position, it will
still be there when you are ready.

### Complete game review on your phone

[Free Chess.com accounts have a daily Game Review limit](https://support.chess.com/en/articles/8584089-how-does-game-review-work).
If you have used that allowance, or played anonymously on Lichess without a
server-side computer report, Mobile Maia provides another route: copy the PGN,
paste it into the app, and run the review locally.

The review includes separate White and Black accuracy scores, a
tap-to-navigate evaluation graph, opening, middlegame, and endgame sections,
and move classifications including Brilliant, Good, Interesting, Dubious,
Mistake, and Blunder. You can step through Stockfish's preferred lines and
export the reviewed game as annotated PGN.

There is no review quota because there is no server to ration. Stockfish runs
on the phone.

### Analysis that asks what a human will play

Mobile Maia answers two different questions on the same board:

- What is the best move according to Stockfish?
- What is the move a human at this rating is most likely to play?

Blue arrows show Stockfish's leading choices and the orange arrow shows Maia's
likely human move at the selected rating. When they agree, the app combines
them into a two-tone arrow.

This is especially useful in opening preparation. An engine can tell you that
an idea is refuted by perfect play, but your real opponent will not have an
evaluation bar. Maia helps you explore the replies that players at your level
are actually likely to find—and the positions in which a natural move may lead
them into trouble.

Maia does not replace Stockfish. It makes Stockfish's answer more useful by
placing it beside a model of human behaviour.

### Built in the spirit of Lichess

Mobile Maia follows Lichess in both design and philosophy: simple, clean,
useful, and free of commercial clutter. There are no accounts, ads,
subscriptions, coins, streaks, leagues, or other gamification. The app is 100%
free and open-source software under AGPL-3.0-only.

The Maia-3 79M model, Stockfish, and Lichess's opening-name data are bundled
with the app. Games and analysis stay on the device, and everything continues
to work without an internet connection.

The tradeoff is size: the APK is about 525 MiB. That is the cost of making the
app genuinely local rather than putting a mobile interface in front of
somebody else's server.

Mobile Maia is an independent community project, not an official Maia Chess,
University of Toronto CSSLab, Stockfish, or Lichess app.

## Latest release — v1.8.1

[Mobile Maia v1.8.1](https://github.com/Dash1971/maia-chess-android/releases/tag/v1.8.1)
is a bug-fix update to the 1.8 Game Review release:

- Maia's selected playing strength is now remembered across app restarts.
- Analysis Board and Game Review move-list rendering is hardened around the
  exact Dart AOT path identified in a rare, one-off Android native crash.
- Mainline rendering is bounded to available move data if restored analysis
  state is incomplete or mismatched.

The crash could not be reproduced, so this is targeted hardening rather than a
claim that every possible native crash has been eliminated. See the
[complete release notes and APK](https://github.com/Dash1971/maia-chess-android/releases/tag/v1.8.1).

## Preview channel — active development

Active development continues in the separate
[Mobile Maia Preview repository](https://github.com/Dash1971/maia-chess-android-preview).
Preview builds use a yellow/gold app icon and a separate Android package, so
they can be installed beside the stable blue Mobile Maia app without replacing
it.

The [current Preview release, v1.7.0-beta.27](https://github.com/Dash1971/maia-chess-android-preview/releases/tag/v1.7.0-beta.27)
is testing:

- Lichess-app-style tap and drag across live play, Analysis Board, and Game
  Review, including touch magnification, finger offset, and the drop shadow,
  while keeping the board fixed during a drag.
- Reliable **Play from here** from custom positions with either side to move.
- Lower-overhead clocks and Maia inference, plus safer model loading and engine
  lifecycle handling.
- More reliable nested analysis variations, graph navigation, and PGN export,
  with the option to stop a full-game analysis in progress.

Preview releases are prerelease software and may change before promotion to
the stable app. Follow the Preview repository to see and test work in progress.

## Screenshots

<p align="center">
  <img src="docs/screenshots/20260902_v0_setup.jpg" width="30%" alt="Mobile Maia setup with side, remembered rating, clock, and Analysis Board controls">
  <img src="docs/screenshots/20260902_v0_analysis_variation.jpg" width="30%" alt="Analysis Board with Stockfish and Maia arrows and an inline PGN variation">
  <img src="docs/screenshots/20260902_v0_review_graph.jpg" width="30%" alt="Game Review evaluation graph with colour-coded move classifications">
</p>

<p align="center">
  <img src="docs/screenshots/20260902_v0_review_moves.jpg" width="30%" alt="Clickable Game Review move list with Stockfish and Maia analysis arrows">
  <img src="docs/screenshots/20260902_v0_review_classifications.jpg" width="30%" alt="Game Review summary of Brilliant, Good, Interesting, Dubious, Mistake, and Blunder moves">
  <img src="docs/screenshots/20260902_v0_completed_game.jpg" width="30%" alt="Completed offline game with PGN export, Game Review, and rematch actions">
</p>

## User guide

### Analysis Board

Select **Analysis Board** from the home screen to explore a position without
starting a game. Stockfish continuously supplies the evaluation and blue
best-move arrow, while Maia supplies its orange human-move recommendation at
the configured analysis rating.

The actions menu can load FEN or PGN text, copy the current FEN or complete PGN,
open the graphical board editor, or start a Maia game from the current position
as White, Black, or a random side. The board editor follows Lichess's toggle
interaction: select a piece and tap an empty square to add it, or tap the same
piece already on the board to remove it. It also controls side to move and
castling rights. The complete Lichess CC0 opening-name dataset is bundled for
offline ECO codes, detailed variation names, and transposition-aware matching.

Select any earlier move and play a different continuation to create an inline,
clickable PGN variation without deleting the existing line. Long-press a move
to delete its continuation; variation moves can also be collapsed, expanded,
promoted one level, or made the main line. Active games,
reviews, complete analysis trees, the selected position, board orientation,
and clock state are checkpointed locally and restored after Android process
death, device restart, or an app update.

<p align="center">
  <img src="docs/screenshots/20260902_v0_analysis_variation.jpg" width="38%" alt="Analysis Board preserving a clickable inline variation">
  <img src="docs/screenshots/20260902_v0_analysis_two_choices.jpg" width="38%" alt="Analysis Board showing Stockfish's first and second choices and Maia agreement">
</p>

### Start a game

Choose White, Black, or a random side, set Maia's rating, and select a clock.
Mobile Maia works entirely offline: the Maia-3 model and Stockfish are bundled
with the app, and no account is required. The selected Maia rating is stored
locally and reused the next time the app starts.

<p align="center">
  <img src="docs/screenshots/20260902_v0_setup.jpg" width="30%" alt="Choose a side, Maia rating, time control, or Analysis Board">
  <img src="docs/screenshots/20260902_v0_advanced_settings.jpg" width="30%" alt="Advanced Maia timing, sampling, and analysis-rating controls">
  <img src="docs/screenshots/20260902_v0_sampling_help.jpg" width="30%" alt="In-app explanation of Maia Temperature and Top-P">
</p>

Advanced settings control human-like move timing, Temperature, Top-P, and the
rating used for Maia's human-move suggestion during review. The default review
rating is 1600. **Copy diagnostics** is also available here if a reproducible
screen error needs investigation.

#### Temperature and Top-P

Maia-3 predicts a probability distribution over the legal moves in each
position. **Temperature** and **Top-P** control how Mobile Maia selects a move
from that distribution; they do not change the model's weights or make Maia
search like Stockfish.

- **Temperature 0** is deterministic: Maia always chooses its
  highest-probability move. Raising Temperature allows progressively more
  variety and gives lower-probability moves a greater chance of being played.
- **Top-P 1.0** keeps the complete legal-move distribution. Lower values keep
  only the most probable moves up to the selected cumulative-probability
  threshold before Maia samples one of them.
- **Mobile Maia's defaults—Temperature 0.5 and Top-P 0.9—**provide human-like
  variety while reducing low-probability outliers. For the most reproducible
  top-choice policy, use Temperature 0 and Top-P 1.0.

These settings are not extra Elo controls. They can change the character and
consistency of play at a given rating, but there is no reliable conversion such
as “lowering Temperature adds 200 Elo.” Keep them fixed while judging which
Maia rating gives you the training experience you want.

For a deeper explanation, see the
[Maia3 local-stack sampling guide](https://github.com/Dash1971/maia3-local-stack#temperature-and-topp).

### Play and take back

Tap or drag pieces to play. The status card shows whose turn it is, while the
material row and move list update throughout the game. Premoves can be entered
while Maia is thinking. A takeback restores the board and clock; the abandoned
line is retained as a variation when the PGN is copied.

<p align="center">
  <img src="docs/screenshots/gameplay.jpg" width="38%" alt="Game board, material balance, move list, and takeback control">
  <img src="docs/screenshots/20260902_v0_completed_game.jpg" width="38%" alt="Completed game with PGN, Game Review, and rematch actions">
</p>

### Game Review

After a game, select **Game Review**. The board remains fixed at the
top while **Moves** and **Graph** switch the panel below it. Select any move to
jump directly to that position. The evaluation bar and blue arrow show
Stockfish's assessment and two leading moves. Maia also suggests the most
likely human move at the configured rating. Agreement between Maia and
Stockfish is shown by a two-tone arrow.

Full-game analysis adds separate White and Black accuracy percentages and a
tap-to-navigate evaluation graph, opening/middlegame/endgame separators, and
colour-coded Brilliant, Good, Interesting, Dubious, Mistake, and Blunder move
classifications. The current move's annotation also appears on the board. Move
the pieces from any reviewed position to explore a branch; analysis is cached
for responsive navigation and variations are retained in exported PGN.

<p align="center">
  <img src="docs/screenshots/20260902_v0_review_moves.jpg" width="30%" alt="Clickable main-line moves with offline Lichess opening identification and engine arrows">
  <img src="docs/screenshots/20260902_v0_review_dubious_move.jpg" width="30%" alt="Colour-coded move classification shown on the board and in notation">
  <img src="docs/screenshots/20260902_v0_review_graph.jpg" width="30%" alt="Stockfish review graph with clickable classification markers">
</p>

<p align="center">
  <img src="docs/screenshots/20260902_v0_review_accuracy.jpg" width="38%" alt="White and Black accuracy above the opening and middlegame graph">
  <img src="docs/screenshots/20260902_v0_review_classifications.jpg" width="38%" alt="Per-side totals for Brilliant, Good, Interesting, Dubious, Mistake, and Blunder moves">
</p>

### About and licensing

The About screen shows the installed version, AGPL-3.0-only terms, warranty
notice, complete source and licence links, and credits for Maia-3, Lichess,
and En Croissant components and adapted code.

<p align="center">
  <img src="docs/screenshots/20260902_v0_about_licensing.jpg" width="38%" alt="Mobile Maia About screen with AGPL terms, source and licence links, and Maia and Lichess credits">
</p>

## MVP features

- Bundled Maia-3 79M model; no account, server, or network connection required
- Offline Analysis Board with Stockfish evaluation and Maia move comparison
- Automatic restoration of active games, reviews, and analysis trees
- FEN/PGN loading, FEN/PGN copying, and graphical position editing
- Play against Maia from the current analysis position
- Complete offline Lichess CC0 opening-name and ECO recognition
- Play as White, Black, or a random side
- Unlimited play by default, Lichess-style clock presets, or custom time and increment
- Easy (800), Medium (1500), Hard (2200), or custom Elo
- Optional human-like move timing with persistent advanced settings
- Premoves while Maia is thinking, with invalid premoves cancelled safely
- Takebacks that restore the previous playable position and clock state while preserving the abandoned line in PGN
- Adjustable Maia Temperature and Top-P from 0 to 1 (defaults 0.5 and 0.9)
- Lichess Chessground board with the default brown theme and Cburnett pieces
- Legal move handling, checkmate/draw detection, move list, and rematches
- Resignation and post-game Home/Rematch actions
- Move-by-move Stockfish and Maia review, starting from the initial position
- Configurable Maia human-move suggestion (default 1600), two Stockfish choices, and two-tone agreement arrows
- Evaluation bar with Lichess-style numeric score and blue Stockfish best-move arrow
- Switchable clickable Moves and Computer graph views below a persistent board
- Optional full-game computer analysis graph with tap-to-navigate positions and game-phase separators
- Brilliant, Good, Interesting, Dubious, Mistake, and Blunder classifications on the graph, move list, and board
- Analysis variations and takebacks preserved as PGN recursive annotation variations
- Long-press variation editing: collapse/expand, promote, make main line, or delete from a move
- Flip-board control during analysis
- Lichess-style material imbalance display, including bishop-versus-knight trades
- Tagged PGN export with players, event, date, result, and termination

## Install and update with Obtainium

[Obtainium](https://github.com/ImranR98/Obtainium) installs Android apps directly
from their official release pages and can notify you when updates are available.

1. Install Obtainium from its
   [official releases page](https://github.com/ImranR98/Obtainium/releases/latest).
2. Open Obtainium, select **Add App**, and paste this URL into **App Source URL**:

   ```text
   https://github.com/Dash1971/maia-chess-android
   ```

3. Confirm that Obtainium detects **GitHub** as the source. Leave
   **Include prereleases** disabled to receive stable versions only.
4. Select **Add**, open **Mobile Maia** in Obtainium, and select
   **Install**.
5. If Android asks, allow Obtainium to install unknown apps, then approve the
   Mobile Maia APK installation.

After setup, use Obtainium's update check to download and install future Maia
Chess releases. Android may ask you to confirm each update.

## Build

Requirements: Flutter 3.47+, JDK 17, and Android SDK 36.

```sh
flutter pub get
flutter analyze
flutter test
tool/build_android_release.sh
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Release
builds intentionally keep readable Dart symbols: Mobile Maia is open source,
readable crash traces are more useful than obfuscation, and deterministic
symbols allow independent reproducibility checks. See
[`REPRODUCIBLE_BUILDS.md`](REPRODUCIBLE_BUILDS.md).

Official releases are signed with the dedicated Mobile Maia app-signing key.
The build reads `MOBILE_MAIA_KEYSTORE`, `MOBILE_MAIA_STORE_PASSWORD`, and
`MOBILE_MAIA_KEY_PASSWORD` from the environment; no signing secrets belong in
this repository. When those variables are absent, Gradle produces an unsigned
release suitable for independent F-Droid rebuilding.

The official signing certificate SHA-256 digest is:

```text
cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e
```

## Re-export Maia-3

The checked-in ONNX model was exported from the official Maia-3 79M checkpoint.
The exporter verifies ONNX Runtime outputs against PyTorch before succeeding.

```sh
python -m pip install /path/to/maia3 onnx onnxruntime
python tool/export_maia3_onnx.py --model maia3-79m --output assets/models/maia3-79m.onnx
```

## Credits

Mobile Maia uses the
[Maia-3 project](https://github.com/CSSLab/maia3) and its 79M model. Maia-3 was
created by the University of Toronto Computational Social Science Lab to model
human chess move choices at different rating levels. The app includes an About
screen linking directly to the upstream project and source code.

The board interface is provided by
[Lichess Flutter Chessground](https://github.com/lichess-org/flutter-chessground),
including the default Lichess brown theme and Cburnett pieces. Local Stockfish
support uses
[Lichess multistockfish](https://github.com/lichess-org/dart-multistockfish).
Opening names and ECO codes come from the CC0
[Lichess chess-openings dataset](https://github.com/lichess-org/chess-openings),
pinned to the source revision recorded in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). The Analysis Board's move
tree, navigation, variation actions, fixed analysis panel, board editor, and
last-move presentation are also informed by the open-source
[Lichess Mobile analysis experience](https://github.com/lichess-org/mobile).
Mobile Maia is independently implemented and is not affiliated with Lichess.

Game Review's move-classification and sacrifice-detection heuristics are
adapted and translated to Dart from
[En Croissant](https://github.com/franciscoBSalgueiro/en-croissant), the
open-source chess GUI by Francisco Salgueiro and contributors. Mobile Maia
retains the upstream classification rules while adding bounded search,
background-isolate execution, and its own review integration. The pinned
upstream revision and licence details are recorded in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Licensing

Copyright (c) 2026 Dash. Original application code in this repository is
licensed under the [GNU Affero General Public License v3.0 only](LICENSE)
(`AGPL-3.0-only`). Contributions are accepted under the same licence.

Mobile Maia as a combined application is distributed under AGPL-3.0-only.
Individual third-party components retain their respective
copyright notices and licences, notably Maia-3 (AGPL-3.0),
Stockfish/multistockfish (GPL-3.0), dartchess (GPL-3.0), and adapted
En Croissant code (GPL-3.0). See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

This is an independent community project and is not an official Maia Chess,
University of Toronto CSSLab, Stockfish, Lichess, or En Croissant application.
