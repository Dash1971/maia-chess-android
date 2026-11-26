# Mobile Maia

**By Maia fans, for Maia fans.** Free, open-source Android chess with Maia-3 79M
and Stockfish running locally. No account, ads, subscriptions or Internet
connection is needed to play or analyze. Choose a Maia rating from 600 to 2600,
explore human move probabilities, and review complete games without daily limits.
The rating is a model input, not a guaranteed playing strength.

## Download and install

[<img src="https://f-droid.org/badge/get-it-on.svg" alt="Get it on F-Droid" height="80">](https://f-droid.org/packages/com.dash1971.maia_chess/)

- [F-Droid](https://f-droid.org/packages/com.dash1971.maia_chess/) — updates follow its separate reproducible-build process.
- [Latest Stable APK](https://github.com/Dash1971/maia-chess-android/releases/latest) — direct download.
- [Obtainium setup](docs/USER_GUIDE.md#install-and-update-with-obtainium) — updates from GitHub releases.
- [Zapstore](https://zapstore.dev/apps/com.dash1971.maia_chess) — developer-published Stable APK.
- [Verify your download and troubleshoot installation](docs/VERIFY_DOWNLOAD.md).

[Preview](https://github.com/Dash1971/maia-chess-android-preview) has a separate
gold icon and package and can be installed alongside Stable's blue-icon app.
[Play in a browser](https://mobilemaia.org/play/) using the smaller Maia-3 5M
model; the [browser guide](https://github.com/Dash1971/mobilemaia.org#readme)
explains installation and optional offline saving.

## Contents

[Features](#feature-guide) · [Mobile Maia 2.6](#mobile-maia-26) ·
[User guide](docs/USER_GUIDE.md) · [Electronic boards](#electronic-board-support) ·
[Contributing](#support-and-contributing) · [Build](#build) ·
[Credits](#credits-and-attributions) · [Documentation](docs/README.md)

## Feature guide

- Play Maia with configurable ratings, move variety, human timing, clocks, takebacks and multiple premoves.
- Compare Maia's human move probabilities with Stockfish's best moves and review complete games with evaluation graphs and move-quality markings.
- Edit positions, explore variations, and continue from a chosen position.
- Choose themes, boards, piece sets and playing aids in ten interface languages.
- Play on supported electronic boards; see [support and testing coverage](#electronic-board-support).

The [user guide](docs/USER_GUIDE.md) explains each workflow, defaults and limits,
with screenshots. [Privacy and permissions](PRIVACY.md) explains local storage,
Bluetooth and Android backup; [release notes](docs/release-notes/README.md)
record version-specific changes.

<a id="planned-mobile-maia-26"></a>

## Mobile Maia 2.6

[Stable 2.6.0](https://github.com/Dash1971/maia-chess-android/releases/tag/v2.6.0) is published on GitHub and Zapstore. F-Droid’s catalog update is pending as of November 26, 2026. It brings the features tested in Preview beta.13 to Stable.

- Grand Kingdom support, including assisted Maia promotion; passed user acceptance testing.
- Saved PGN evaluations and move markings, restored when reopening games.
- **Include analysis** in existing Save/Share/Copy menus and Recent games collection export, checked by default. Uncheck to omit scores and quality symbols from the exported copy while retaining comments, clocks and variations. Stored analysis stays unchanged.
- Larger landscape boards, adaptive wide layouts and independently scrollable moves.
- Compact Recent games with yyyy/MM/dd dates, centered results and gray Incomplete labels; Back cancels selection and preserves browsing position.
- Recent games imports complete PGN collections; Analysis Board opens the first game. Import and export both allow 5 MiB, with duplicate checking and progress for longer imports.
- Save/recovery fixes, unfinished analysis resume, and human timing enabled when unset while preserving an explicit off choice.

See the [release notes](docs/release-notes/v2.6.0.md),
[user guide](docs/USER_GUIDE.md) and [PGN analysis guide](docs/PGN_ANALYSIS.md).
Published downloads are listed on the [release page](https://github.com/Dash1971/maia-chess-android/releases/latest). Automatic Dev diagnostics and camera recognition are excluded;
Pegasus remains withdrawn.

## Why the 79M model?

We bundle Maia-3 79M for its human-move prediction accuracy, accepting the larger
download. See the [model provenance](MODEL_PROVENANCE.md),
[research](https://arxiv.org/html/2605.19091v1#S4.T1) and
[settings guide](https://github.com/Dash1971/mobile-maia-research/blob/main/guides/choosing-maia-settings/README.md).

## Community

Join the [Mobile Maia forum on Mute Chess](https://mutechess.org/forum/mobile-maia)
for settings, games and testing discussions. Use the appropriate GitHub issue
tracker for bugs and feature requests.

## Support and contributing

Start with [Contributing](CONTRIBUTING.md), [Security](SECURITY.md),
[Privacy](PRIVACY.md) and the [documentation index](docs/README.md).
Features are developed in Preview before Stable promotion. Include the app and
Android versions, device and reproduction steps in bug reports. Use private
vulnerability reporting for security issues.

## Build

Use the pins in [`.fvmrc`](.fvmrc), the locked dependencies and shared toolchains.
See [Contributing](CONTRIBUTING.md) for setup/debug runs, [reproducible builds](REPRODUCIBLE_BUILDS.md)
for APK comparison, and [the release procedure](docs/RELEASING.md) for mandatory
qualification and publication. A source ZIP contains LFS pointers, not weights.

## Re-export Maia-3

Follow the pinned [model provenance and re-export procedure](MODEL_PROVENANCE.md).
Re-export is separate from ordinary app builds.

## Electronic-board support

Mobile Maia 2.6 electronic-board support:

| Board | Support | Hardware testing | Notes |
| --- | --- | --- | --- |
| Chessnut Air | Supported | Fully tested | Piece recognition and LED guidance. |
| Chessnut Go | Supported | Fully tested | Piece recognition and LED guidance. |
| Chessnut Pro | Supported | Not fully tested | Uses the shared Chessnut protocol; further device testing is welcome. |
| Square Off Grand Kingdom | Supported | Passed user acceptance testing | Untimed games from the standard position; assisted Maia promotion. |
| DGT Pegasus | Not supported | — | Prototype withdrawn because initialization licensing and downstream redistribution permission remain unresolved. |

The [support decision](docs/decisions/2026-11-22-electronic-board-support.md)
records the Pegasus withdrawal. The uncertainty concerns initialization
permission, not the GPL-licensed MoveAPiece protocol code. Older Dev APKs may
contain the retired prototype; no published APK is changed by this source PR.

Board owners and manufacturers are welcome to
[contact us through an issue](https://github.com/Dash1971/maia-chess-android/issues/new)
to help test devices, document protocols, and expand supported models. The
[board testing guide](docs/ELECTRONIC_BOARD_DEV.md) describes the supported
workflows and the [Grand Kingdom acceptance record](docs/ELECTRONIC_BOARD_GRAND_KINGDOM_26.md)
records its passed user acceptance testing, source feedback and operating limits.

## Credits and attributions

Mobile Maia uses the
[Maia-3 project](https://github.com/CSSLab/maia3) and its 79M model. Maia-3 was
created by the University of Toronto Computational Social Science Lab to model
human chess move choices at different rating levels.

The board interface is provided by
[Lichess Flutter Chessground](https://github.com/lichess-org/flutter-chessground),
including the default Lichess brown theme and Cburnett pieces. Local Stockfish
support uses
[Lichess multistockfish](https://github.com/lichess-org/dart-multistockfish).
Opening names and ECO codes come from the CC0
[Lichess chess-openings dataset](https://github.com/lichess-org/chess-openings),
pinned to the source revision recorded in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). Analysis Board interactions
are also informed by the open-source
[Lichess Mobile analysis experience](https://github.com/lichess-org/mobile).
Mobile Maia is independently implemented and is not affiliated with Lichess.

Chessnut support uses Chessnut's
[published e-board API](https://github.com/chessnutech/Chessnut_eBoards) and
MIT-licensed [EasyLinkSDK](https://github.com/chessnutech/EasyLinkSDK), and was
cross-checked against Roberto Marabini's GPL-3.0
[chessnutair](https://github.com/rmarabini/chessnutair) reference
implementation. Mobile Maia's Bluetooth transport uses Android's native BLE
APIs. Protocol sources, copyright notices, licence terms, and adaptation
details are recorded in [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

Grand Kingdom protocol support references
[square-off-remote](https://github.com/greghope667/square-off-remote), the
GPL-3.0-or-later Grand Kingdom implementation by
[greghope667](https://github.com/greghope667). See our
[protocol notes](docs/ELECTRONIC_BOARD_NATIVE_PROTOCOL.md) for the pinned source
and implementation details.

Game Review's move-classification and sacrifice-detection heuristics are
adapted and translated to Dart from
[En Croissant](https://github.com/franciscoBSalgueiro/en-croissant), the
open-source chess GUI by Francisco Salgueiro and contributors. The pinned
upstream revision and licence details are recorded in
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

The double-press NEW GAME Chessnut e-board behavior was inspired by [MoveAPiece](https://github.com/egdels/moveapiece) by [egdels](https://github.com/egdels).

The **Max variety in opening** idea is credited to
[Maia3-tauri](https://github.com/outusuke/maia3-tauri) by outusuke. This is an
idea attribution; no Maia3-tauri source code is incorporated for this feature.

## Licensing

Copyright (c) 2026 Dash. Original application code in this repository is
licensed under the [GNU Affero General Public License v3.0 only](LICENSE)
(`AGPL-3.0-only`). Contributions are accepted under the same licence.

Mobile Maia as a combined application is distributed under AGPL-3.0-only.
Individual third-party components retain their respective copyright notices
and licences, notably Maia-3 (AGPL-3.0), Stockfish/multistockfish (GPL-3.0),
dartchess (GPL-3.0), and adapted En Croissant code (GPL-3.0). See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

This is an independent community project and is not an official Maia Chess,
University of Toronto CSSLab, Stockfish, Lichess, or En Croissant application.

<details>
<summary>Links to moved guide sections</summary>

<a id="mobile-maia-25"></a><a href="docs/release-notes/v2.5.0.md">Mobile Maia 2.5</a><br>

<a id="choose-a-game-or-analysis-workflow"></a><a href="docs/USER_GUIDE.md#choose-a-game-or-analysis-workflow">Choose a game or analysis workflow</a><br>

<a id="time-controls"></a><a href="docs/USER_GUIDE.md#time-controls">Time controls</a><br>

<a id="human-move-timing"></a><a href="docs/USER_GUIDE.md#human-move-timing">Human move timing</a><br>

<a id="interface-language"></a><a href="docs/USER_GUIDE.md#interface-language">Interface language</a><br>

<a id="appearance"></a><a href="docs/USER_GUIDE.md#appearance">Appearance</a><br>

<a id="board-designs-and-playing-aids"></a><a href="docs/USER_GUIDE.md#board-designs-and-playing-aids">Board designs and playing aids</a><br>

<a id="advanced-play-and-review-settings"></a><a href="docs/USER_GUIDE.md#advanced-play-and-review-settings">Advanced play and review settings</a><br>

<a id="maia-sampling-and-help"></a><a href="docs/USER_GUIDE.md#maia-sampling-and-help">Maia sampling and help</a><br>

<a id="max-variety-in-opening"></a><a href="docs/USER_GUIDE.md#max-variety-in-opening">Max variety in opening</a><br>

<a id="optional-move-history-input"></a><a href="docs/USER_GUIDE.md#optional-move-history-input">Optional move-history input</a><br>

<a id="save-maia-sampling-data"></a><a href="docs/USER_GUIDE.md#save-maia-sampling-data">Save Maia sampling data</a><br>

<a id="play-against-a-human-like-opponent"></a><a href="docs/USER_GUIDE.md#play-against-a-human-like-opponent">Play against a human-like opponent</a><br>

<a id="game-sounds-and-touch-feedback"></a><a href="docs/USER_GUIDE.md#game-sounds-and-touch-feedback">Game sounds and touch feedback</a><br>

<a id="multiple-premoves"></a><a href="docs/USER_GUIDE.md#multiple-premoves">Multiple premoves</a><br>

<a id="navigation-takebacks-resignation-and-draw-offers"></a><a href="docs/USER_GUIDE.md#navigation-takebacks-resignation-and-draw-offers">Navigation, takebacks, resignation, and draw offers</a><br>

<a id="game-completion-and-rematches"></a><a href="docs/USER_GUIDE.md#game-completion-and-rematches">Game completion and rematches</a><br>

<a id="chessnut-electronic-board-play"></a><a href="docs/USER_GUIDE.md#chessnut-electronic-board-play">Chessnut electronic-board play</a><br>

<a id="analysis-board"></a><a href="docs/USER_GUIDE.md#analysis-board">Analysis Board</a><br>

<a id="optional-maia-score"></a><a href="docs/USER_GUIDE.md#optional-maia-score">Optional Maia score</a><br>

<a id="move-list-opening-names-and-engine-lines"></a><a href="docs/USER_GUIDE.md#move-list-opening-names-and-engine-lines">Move list, opening names, and engine lines</a><br>

<a id="why-stockfish-19-light"></a><a href="docs/USER_GUIDE.md#why-stockfish-19-light">Why Stockfish 19 Light?</a><br>

<a id="load-edit-continue-and-clear-positions"></a><a href="docs/USER_GUIDE.md#load-edit-continue-and-clear-positions">Load, edit, continue, and clear positions</a><br>

<a id="save-and-share-analysis"></a><a href="docs/USER_GUIDE.md#save-and-share-analysis">Save and share analysis</a><br>

<a id="build-and-edit-variations"></a><a href="docs/USER_GUIDE.md#build-and-edit-variations">Build and edit variations</a><br>

<a id="full-game-computer-analysis"></a><a href="docs/USER_GUIDE.md#full-game-computer-analysis">Full-game computer analysis</a><br>

<a id="saved-evaluations-and-move-markings"></a><a href="docs/USER_GUIDE.md#saved-evaluations-and-move-markings">Saved evaluations and move markings</a><br>

<a id="accuracy-and-game-phases"></a><a href="docs/USER_GUIDE.md#accuracy-and-game-phases">Accuracy and game phases</a><br>

<a id="evaluation-graph-and-move-navigation"></a><a href="docs/USER_GUIDE.md#evaluation-graph-and-move-navigation">Evaluation graph and move navigation</a><br>

<a id="move-classifications"></a><a href="docs/USER_GUIDE.md#move-classifications">Move classifications</a><br>

<a id="recent-games-and-pgn-files"></a><a href="docs/USER_GUIDE.md#recent-games-and-pgn-files">Recent games and PGN files</a><br>

<a id="about-privacy-and-licences"></a><a href="docs/USER_GUIDE.md#about-privacy-and-licences">About, privacy, and licences</a><br>

<a id="availability-and-forks"></a><a href="docs/USER_GUIDE.md#availability-and-forks">Availability and forks</a><br>

<a id="will-mobile-maia-be-available-on-google-play-or-iphone"></a><a href="docs/USER_GUIDE.md#will-mobile-maia-be-available-on-google-play-or-iphone">Will Mobile Maia be available on Google Play or iPhone?</a><br>

<a id="what-about-forks-published-in-app-stores"></a><a href="docs/USER_GUIDE.md#what-about-forks-published-in-app-stores">What about forks published in app stores?</a><br>

<a id="install-and-update-with-f-droid"></a><a href="docs/USER_GUIDE.md#install-and-update-with-f-droid">Install and update with F-Droid</a><br>

<a id="install-and-update-with-obtainium"></a><a href="docs/USER_GUIDE.md#install-and-update-with-obtainium">Install and update with Obtainium</a><br>

<a id="install-and-update-with-zapstore"></a><a href="docs/USER_GUIDE.md#install-and-update-with-zapstore">Install and update with Zapstore</a><br>

</details>
