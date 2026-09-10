# Mobile Maia Preview

> **Prerelease channel:** This repository contains experimental Mobile Maia
> builds. The Android package ID is separate from the stable app, so **Mobile
> Maia Preview** can be installed beside **Mobile Maia** without replacing it.
>
> Preview v1.7.0-beta.30 was promoted to the stable
> [Mobile Maia 2.0.0 release](https://github.com/Dash1971/maia-chess-android/releases/tag/v2.0.0).
> The Preview `main` branch now targets the Mobile Maia 2.1 development cycle.

An offline-first Android chess app for playing against Maia-3, reviewing games
with Maia and Stockfish, and exporting PGN.

Built around [Maia-3](https://github.com/CSSLab/maia3), the human-like chess
engine developed by the University of Toronto Computational Social Science Lab.

## Screenshots

<p align="center">
  <img src="docs/screenshots/20260906_v0_home_setup.jpg" width="30%" alt="Mobile Maia setup with side, rating, clock, Analysis Board, Recent games, and Open PGN controls">
  <img src="docs/screenshots/20260906_v0_live_game_navigation.jpg" width="30%" alt="Offline game against Maia with move navigation controls">
  <img src="docs/screenshots/20260906_v0_analysis_moves.jpg" width="30%" alt="Analysis Board with Stockfish and Maia arrows and a scrolling move list">
</p>

<p align="center">
  <img src="docs/screenshots/20260906_v0_recent_games.jpg" width="30%" alt="Recent games with a saved incomplete game">
  <img src="docs/screenshots/20260906_v0_review_graph.jpg" width="30%" alt="Computer analysis evaluation graph with colour-coded move classifications">
  <img src="docs/screenshots/20260906_v0_review_classifications.jpg" width="30%" alt="Computer analysis summary of move classifications for both players">
</p>

## User guide

### Analysis Board

Select **Analysis Board** from the home screen to explore a position without
starting a game. Stockfish continuously supplies the evaluation and blue
best-move arrow, while Maia supplies its orange human-move recommendation at
the configured analysis rating.

The bottom actions sheet can load FEN or PGN text, open a PGN file, clear the
move tree, open the graphical board editor, or start a Maia game from the
current position. **Continue from here** lets you choose White, Black, or a
random side and confirms which colour moves next. The top-right menu saves,
shares, or copies the complete PGN, or copies the current FEN.

The board editor follows Lichess's toggle interaction: select a piece and tap
an empty square to add it, or tap the same piece already on the board to remove
it. It also controls side to move and castling rights. The complete Lichess CC0
opening-name dataset is bundled for offline ECO codes, detailed variation
names, and transposition-aware matching.

Select any earlier move and play a different continuation to create an inline,
clickable PGN variation without deleting the existing line. Long-press a move
to delete its continuation; variation moves can also be collapsed, expanded,
promoted one level, or made the main line. Active games, reviews, complete
analysis trees, the selected position, board orientation, and clock state are
checkpointed locally and restored after Android process death, device restart,
or an app update.

Tap the back and forward arrows to move one position at a time. Hold the back
arrow to return to the game's starting position, or hold the forward arrow to
jump to the end of the main line.

<p align="center">
  <img src="docs/screenshots/20260906_v0_analysis_board.jpg" width="30%" alt="Analysis Board at the starting position with offline Stockfish and Maia suggestions">
  <img src="docs/screenshots/20260906_v0_analysis_actions.jpg" width="30%" alt="Analysis Board actions for loading, clearing, editing, and continuing a position">
  <img src="docs/screenshots/20260906_v0_analysis_export.jpg" width="30%" alt="Analysis Board menu for saving, sharing, and copying PGN or FEN">
</p>

<p align="center">
  <img src="docs/screenshots/20260906_v0_analysis_selected_move.jpg" width="30%" alt="Analysis Board with a selected move, engine lines, and move arrows">
  <img src="docs/screenshots/20260906_v0_analysis_variation.jpg" width="30%" alt="Analysis Board preserving an inline variation in the move tree">
  <img src="docs/screenshots/20260906_v0_analysis_castling.jpg" width="30%" alt="Analysis Board navigating a later move in the current line">
</p>

### Start a game

Choose White, Black, or a random side, set Maia's rating, and select a clock.
Mobile Maia works entirely offline: the Maia-3 model and Stockfish are bundled
with the app, and no account is required. Your side choice (including
**Random**), time-control preset, custom minutes and increment, Maia rating,
and advanced engine settings are stored locally and reused the next time the
app starts.

#### Experimental Chessnut Go support

Enable **Chessnut Go (experimental)** on the home screen, grant Android's
nearby-device permission, and select **Connect Chessnut Go**. Set up the
standard starting position before starting an unlimited game. Your physical
moves are entered directly into Mobile Maia; after Maia replies, the move's
from- and to-squares light on the board. Play the lit move before continuing.
The app sends each new indication once, then refreshes it at a conservative
interval until the physical position matches. LED writes are paced and stale
queued guidance is discarded so rapid board updates cannot overwhelm the BLE
link or overwrite the current indication.

Mobile Maia compares every sensed piece with the complete legal position.
Lifting a piece or moving only the rook during castling is treated as an
unfinished action, not a move. If a completed position is illegal or the board
is out of sync, the squares that need correction light up. Matching the
Chessnut Maia CLI, the board gives one short beep for check, two distinct beeps
for checkmate, and one beep for a complete-looking illegal move. Temporary
piece lifts remain silent, repeated board frames do not repeat the alert, and
**Board sounds** can be disabled from setup or the live Bluetooth panel.

**Take back move** removes the latest player/Maia turn, or the only available
move. The reverted moves remain in the exported PGN as a variation. Every
physical square that must be restored lights up, and play resumes only after
the complete board matches the reverted position. Restoration guidance is
retained across a reconnect or app restart.

The Bluetooth icon in a live game shows connection and battery status and
provides reconnect, sound, disconnect, and **Play in app** controls. If the
board loses power or disconnects, a compact card offers **Reconnect** and
**Play in app**. Reconnect rescans for the board without discarding the game,
then checks the complete physical position before play continues. Pending
Maia and takeback LEDs are restored after reconnecting.

**Play in app** immediately switches the current game to on-screen moves,
even while connecting or waiting to copy Maia's move onto the physical board.
The position, moves, variations, rating, orientation, and unlimited time control
are retained. The choice is saved, so reopening that game continues on screen
and the home-screen Chessnut toggle stays off. You can also choose it from the
Bluetooth menu before leaving a connected board.

Completed games opened from **Recent games** do not reactivate Chessnut or
request a connection. Unfinished board games retain their reconnect option
until you choose **Play in app**.

This preview targets Chessnut Go over Bluetooth. Timed e-board games, arbitrary
starting positions, USB connections, Analysis Board input, and other Chessnut
models are not yet supported. The integration remains fully offline and the app
continues to work normally without Bluetooth permission when Chessnut support
is not enabled.

The screen remains awake during every active game, whether moves are entered
on Chessnut Go or directly on the phone.

<p align="center">
  <img src="docs/screenshots/20260906_v0_home_setup.jpg" width="30%" alt="Choose a side, Maia rating, time control, or Analysis Board">
  <img src="docs/screenshots/20260906_v0_time_control_menu.jpg" width="30%" alt="Choose Unlimited, a preset clock, or a custom time control">
  <img src="docs/screenshots/20260906_v0_advanced_settings.jpg" width="30%" alt="Advanced Maia timing, sampling, analysis-rating, and diagnostics controls">
</p>

<p align="center">
  <img src="docs/screenshots/20260906_v0_sampling_help.jpg" width="38%" alt="In-app explanation of Maia Temperature and Top-P">
</p>

Advanced settings control human-like move timing, Temperature, Top-P, the
rating used for Maia's human-move suggestion during review, and full-game
analysis quality. **Thorough** remains the default (depth 16, up to 1.5 seconds
per position); **Balanced** uses depth 14 and one second; **Fast** uses depth 12
and half a second, trading some graph and classification consistency for speed.
The default review rating is 1600. **Copy diagnostics** is also available here
for troubleshooting.
The local report includes the app version, Android/device model, OS/firmware
build and security patch, CPU ABIs, memory page size, RAM/heap/storage figures,
Maia model-cache state, privacy-safe Bluetooth/GATT state, recent connection
transitions, first Maia inference timing, and Android's recent process-exit
reason when supported.
It never includes a device serial, Bluetooth address, board name, chess
position, or PGN, and nothing is uploaded automatically.

Diagnostics are pruned whenever they are written or copied. Mobile Maia retains
at most 14 days, 40 entries, 8,000 characters per entry, and 128,000 characters
in total; the oldest data is removed as soon as any limit is exceeded.

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
material row and move strip update throughout the game. Premoves can be entered
while Maia is thinking. The bottom toolbar opens the game menu, resigns, and
steps backward or forward through played moves. Historical positions are
read-only until you return to the live position. **Takeback** is in the game
menu; it restores the board and clock while retaining the abandoned line as a
variation when the PGN is copied.

In an endgame, **Offer draw** appears in the game menu. As on Lichess, selecting
it first opens a confirmation dialog. Mobile Maia defines an endgame with a
material-phase score: each queen counts 4, each rook 2, and each bishop or
knight 1 across both sides; kings and pawns count 0. Draw offers are available
at a score of 8 or lower. Maia accepts when Stockfish evaluates its position at
no more than a 0.30-pawn advantage, including equal and losing positions, and
declines when it is more than 0.30 ahead. A declined offer cannot be repeated
until the position changes. An accepted offer is saved as **Draw by agreement**
with a `1/2-1/2` PGN result.

<p align="center">
  <img src="docs/screenshots/20260906_v0_live_game_opening.jpg" width="30%" alt="Live game against Maia in an opening position">
  <img src="docs/screenshots/20260906_v0_maia_thinking.jpg" width="30%" alt="Live game while Maia is thinking and a premove can be entered">
  <img src="docs/screenshots/20260906_v0_live_game_navigation.jpg" width="30%" alt="Live game with menu, resign, previous-move, and next-move controls">
</p>

<p align="center">
  <img src="docs/screenshots/20260906_v0_game_result.jpg" width="38%" alt="Game conclusion dialog with Analysis Board and Rematch actions">
</p>

### Offline games and files

Games and analysis are checkpointed in app-private files, with a previous-good
backup for recovery. **Recent games** contains completed games and incomplete
games explicitly saved with Home. Incomplete games are labelled and become the
same completed record when finished. **Reset game** warns before permanently
removing the current game and starting again.

Recent games supports multi-select, select all, selected deletion, and delete
all. Android may erase app-private data when the app is uninstalled; use
**Save PGN file** or **Share PGN** to keep an independent copy.

<p align="center">
  <img src="docs/screenshots/20260906_v0_recent_games.jpg" width="38%" alt="Recent games showing an explicitly saved incomplete game">
</p>

**Open PGN file**, Android's Open with action, and shared PGN attachments import
a single game with its variations, comments, and annotations. Files are limited
to 2 MB and 20,000 moves across all branches. Save and share use Android's
system picker and temporary URI grants; no storage or Internet permission is
required. PGN import uses the first game in a multi-game document.

Training clocks pause while the app is backgrounded, while reviewing the
current game, or after a Maia error. Returning resumes the saved clock; Retry
restarts a failed Maia turn. Analysis stops scheduling engine work offscreen.
Selecting a position gets a short Stockfish search, then a longer refinement if
it remains selected. The analysis-quality preset affects only full-game graph
analysis; it is snapshotted when a run starts and does not change interactive
analysis, gameplay, or draw evaluation.

### Analysis Board and computer review

After a game, select **Analysis Board**. The board remains fixed at the top
while **Moves** and **Computer** switch the panel below it. Select any move to
jump directly to that position. The evaluation bar and blue arrows show
Stockfish's assessment and leading moves. Matching Lichess, the numeric score
stays at the end belonging to the advantaged side and follows the board when it
is flipped. Maia also suggests the most likely human move at the configured
rating. Agreement between Maia and Stockfish is shown by a two-tone arrow.

The Back arrow rewinds a variation into the parent line at the position where
it branched, keeping that move highlighted. Repeated Back presses continue
through nested variations to the main line; Forward then follows that line.

Open **Computer** and run computer analysis to add separate White and Black
accuracy percentages, a tap-to-navigate evaluation graph,
opening/middlegame/endgame separators, and colour-coded Brilliant, Good,
Interesting, Dubious, Mistake, and Blunder move classifications. Analysis can
be stopped safely from the progress screen. The current move's annotation also
appears on the board. Move the pieces from any reviewed position to explore a
branch; analysis is cached for responsive navigation and variations are
retained in exported PGN.

<p align="center">
  <img src="docs/screenshots/20260906_v0_analysis_moves.jpg" width="30%" alt="Clickable move list with offline opening identification and engine arrows">
  <img src="docs/screenshots/20260906_v0_analysis_progress.jpg" width="30%" alt="Cancellable full-game computer analysis progress">
  <img src="docs/screenshots/20260906_v0_review_accuracy.jpg" width="30%" alt="Computer analysis tab with player accuracy, game phases, and move counts">
</p>

<p align="center">
  <img src="docs/screenshots/20260906_v0_review_graph.jpg" width="38%" alt="Evaluation graph with clickable move-classification markers">
  <img src="docs/screenshots/20260906_v0_review_classifications.jpg" width="38%" alt="Per-side totals for Brilliant, Good, Interesting, Dubious, Mistake, and Blunder moves">
</p>

### About and licensing

The About screen shows the installed version and links to Maia-3, En Croissant,
Lichess Flutter Chessground, Lichess multistockfish, and the bundled licences.

<p align="center">
  <img src="docs/screenshots/20260906_v0_about.jpg" width="38%" alt="Mobile Maia 2.0 About screen with AGPL terms, source and licence links, and project credits">
</p>

## MVP features

- Bundled Maia-3 79M model; no account, server, or network connection required
- Offline Analysis Board with Stockfish evaluation and Maia move comparison
- Automatic restoration of active games, reviews, and analysis trees
- Recent Games for completed games and explicitly saved incomplete games
- Multi-select, select-all, selected deletion, and delete-all game management
- FEN/PGN loading, FEN/PGN copying, and graphical position editing
- Android Files, Open with, and share-sheet PGN import and export
- Play against Maia from the current analysis position
- Complete offline Lichess CC0 opening-name and ECO recognition
- Play as White, Black, or a random side
- Experimental Chessnut Go play with strict position matching, move and
  takeback LEDs, check/illegal-move sounds, battery status, and reconnect controls
- Unlimited play by default, Lichess-style clock presets, or custom time and increment
- Persistent side and time-control setup, including Random and custom clock values
- Easy (800), Medium (1500), Hard (2200), or custom Elo
- Optional human-like move timing with persistent advanced settings
- Premoves while Maia is thinking, with invalid premoves cancelled safely
- Takebacks that restore the previous playable position and clock state while preserving the abandoned line in PGN
- Adjustable Maia Temperature and Top-P from 0 to 1 (defaults 0.5 and 0.9)
- Lichess Chessground board with the default brown theme and Cburnett pieces
- Legal move handling, checkmate/draw detection, move list, and rematches
- Resignation and post-game Home/Rematch actions
- Endgame draw offers with confirmation, local Stockfish adjudication, and PGN recording
- Move-by-move Stockfish and Maia review, starting from the initial position
- Configurable Maia human-move suggestion (default 1600), two Stockfish choices, and two-tone agreement arrows
- Evaluation bar with Lichess-style numeric score and blue Stockfish best-move arrow
- Switchable clickable Moves and Computer graph views below a persistent board
- Optional full-game computer analysis graph with tap-to-navigate positions and game-phase separators
- Fast, Balanced, and Thorough full-game analysis presets (Thorough by default)
- Brilliant, Good, Interesting, Dubious, Mistake, and Blunder classifications on the graph, move list, and board
- Analysis variations and takebacks preserved as PGN recursive annotation variations
- Long-press variation editing: collapse/expand, promote, make main line, or delete from a move
- Hold analysis navigation arrows to jump to the start or end of the main line
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
   https://github.com/Dash1971/maia-chess-android-preview
   ```

3. Confirm that Obtainium detects **GitHub** as the source and enable
   **Include prereleases**.
4. Select **Add**, open **Mobile Maia Preview** in Obtainium, and select
   **Install**.
5. If Android asks, allow Obtainium to install unknown apps, then approve the
   Mobile Maia Preview APK installation.

After setup, use Obtainium's update check to download and install future Maia
Chess releases. Android may ask you to confirm each update.

## Build

Requirements: **Flutter 3.47.1** (pinned in `.fvmrc`), JDK 17, Android SDK 36,
Python 3, and Git LFS. Use the locked dependencies. A GitHub source ZIP contains
an LFS pointer rather than the 316 MB Maia model, so clone with Git LFS:

```sh
git clone https://github.com/Dash1971/maia-chess-android-preview.git
cd maia-chess-android-preview
git lfs install
git lfs pull
python3 tool/verify_model.py
flutter pub get --enforce-lockfile
flutter analyze
flutter test
tool/build_android_release.sh
```

The ARM64 release APK is written to
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
It packages the mobile ARM64 ABI instead of bundling unused CPU architectures.
Use this same script for official releases and independent rebuilds. It sets a
fixed source timestamp, prepares stable generated Dart source URIs, and leaves
obfuscation disabled. Gradle also verifies the model's exact size and SHA-256,
so a direct `flutter build` cannot silently package a placeholder or altered
model. The build downloads dependencies; installed release apps work offline.

To check reproducibility, build the **same commit** in two clean directories
with the same pinned toolchain and no signing variables, then compare the
unsigned APKs using `sha256sum`. Retain both hashes with the release notes;
the procedure is not itself evidence that a particular release reproduced.
The manual Checks workflow can build an unsigned APK; pull requests run the
Dart analyzer and regression tests.

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
Both Lichess projects are credited and linked in the app's About screen.

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

Mobile Maia Preview as a combined application is distributed under
AGPL-3.0-only. Individual third-party components retain their respective
copyright notices and licences, notably Maia-3 (AGPL-3.0),
Stockfish/multistockfish (GPL-3.0), dartchess (GPL-3.0), and adapted
En Croissant code (GPL-3.0). See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

This is an independent community project and is not an official Maia Chess,
University of Toronto CSSLab, Stockfish, Lichess, or En Croissant application.
