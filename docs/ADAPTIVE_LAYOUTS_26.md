# Adaptive layouts for 2.6

Stable 2.6 draft: this behavior is promoted from Preview. The recorded tests,
renders and APK qualification below describe Preview, not a newly qualified
Stable build. Stable checks and changed screenshots remain pending.

Published in Preview 2.6.0-beta.4, based on the layouts reviewed on November 15, 2026, tracked in
[Preview #29](https://github.com/Dash1971/maia-chess-android-preview/issues/29).
[Release qualification](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/releases/preview-2.6.0-beta.4.md) records the actual signed
APK checks. Physical-device touch/tablet acceptance remains separate.

Wide gameplay windows put the board on the left and move the existing toolbar,
player information, clocks, history, and controls to the right. The board uses
the available height when the width also leaves a usable side panel. Short
panels scroll independently; reconnect and phone-fallback actions take priority
when a disconnected electronic board needs attention. Narrow landscape windows
that cannot fit both columns scroll a full-size board rather than reducing it
to the former 81-pixel fallback.

Analysis uses the same available-height principle, including the bottom safe
inset, and removes the 560-pixel board cap in wide windows. Its existing engine
lines, Maia probabilities, opening name, moves/graph tabs, evaluation bar, and
navigation remain available. The toolbar moves beside the board. The current
2.6 source keeps the analysis header fixed while the move list or graph scrolls
independently. Move navigation never collapses the engine header. Landscape tabs
share the bottom control strip to leave room for a usable move window. Squarer
tablets and resized windows reserve readable analysis width rather than
maximizing the board at its expense.
[Phone and tablet renders and scroll verification](ANALYSIS_SCROLL_26.md)
describe this follow-up; the beta.4 release evidence above covers the original
adaptive layout. Analysis, classification, inference, and saved-data formats
are unchanged.

Home uses a setup column and a second column for Analysis Board, Recent games,
and the content-sized Settings button. Short landscape setup cards reduce
spacing and omit the redundant Play Maia heading; controls retain their touch
targets. An expanded electronic-board setup can still scroll. Portrait Home
keeps its existing arrangement.

Settings uses categories beside the existing settings cards in wide windows.
Language, Appearance, Board, Game settings, Engine settings, Analysis settings,
Chessnut, and Diagnostics retain their actual controls and persistence paths.
Category selection uses a stable icon identity, so changing language does not
switch categories. The diagnostic/reset group contains the existing actions;
the Dev-only diagnostics gate is unchanged. Narrow windows retain the existing
scrolling settings page.

Recent games uses Date, Game, and Result columns with a 52-logical-pixel minimum
row height. Date and result widths are measured with the current font, text
scale, and localized labels so results fit on one line. Result values and their
header are centered. Unfinished games display the full localized Incomplete
label in a muted color, with its width reserved to avoid wrapping in the table.
Player names are centered between those columns, with matching minimum gaps.
Large text or constrained widths use the two-line list instead of squeezing
columns. Dates display the original played day as `yyyy/MM/dd`; an unknown date
keeps its localized label. Date formatting does not change the stored date or
game order, and result colors still describe the saved player's outcome.

A tap opens the game directly. Long-press or the Select games menu enables
checkbox selection; deletion and PGN export use the selection toolbar. There
are no per-row delete buttons. Android Back, including a committed predictive
gesture, cancels selection first; the next Back returns Home. Back remains
blocked during an open/delete/export operation. Returning from a saved game
retains the Recent games scroll position. Import and export limits are
unchanged.

## Reviewed designs

The review inputs are retained in the repository so the approved work does not
exist only in chat. These are illustrative HTML fragments for the conversation
viewer, not app screenshots or a second application:

- [Gameplay comparison](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/gameplay-comparison.html)
- [Home, Settings, Recent games, and initial Analysis comparison](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/screen-comparisons.html)
- [Final Analysis revision: board reaches the bottom inset](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/analysis-full-height.html)
- [Compact portrait Recent games](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/recent-games-portrait.html)

The final Analysis revision supersedes the board spacing in the earlier
four-screen comparison. Board artwork uses the already bundled Cburnett assets;
the repository's existing third-party notices continue to apply. These files
and the screenshots below are documentation and are not bundled app assets.

## Screens from the implemented widgets

These images come from host-side Flutter widget tests with deterministic game
and engine fixtures. They use the installed system font under the test's Roboto
family alias and the existing icon fonts; no font files are redistributed.
They demonstrate the implemented source, not an Android APK, device performance,
or physical touch comfort.

| Screen | Landscape phone | Tablet |
| --- | --- | --- |
| Gameplay | ![Phone gameplay](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/game-phone.png) | ![Tablet gameplay](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/game-tablet.png) |
| Home | ![Phone Home](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/home-phone.png) | ![Tablet Home](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/home-tablet.png) |
| Settings | ![Phone Settings](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/settings-phone.png) | ![Tablet Settings](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/settings-tablet.png) |
| Analysis | ![Phone Analysis](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/analysis-phone.png) | ![Tablet Analysis](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/analysis-tablet.png) |

![Implemented compact portrait Recent games](https://raw.githubusercontent.com/Dash1971/maia-chess-android-preview/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/design/adaptive-layouts-26/recent-portrait.png)

## Validation and remaining acceptance

Host tests exercise full-height phone/tablet boards, controller and queued
premove preservation across rotation, short landscape windows, large text,
actual Home/Settings controls, and compact-table tap/selection behavior. Existing
storage, played-date, result-color, localized-layout, probability, and PGN-export
regressions remain part of verification. Screenshot generation is optional via
`MAIA_LAYOUT_CAPTURES`, using the existing `MAIA_FONT_DIR` fixture convention.

The four new headings have no direct equivalent in the pinned Lichess mobile
catalog. Their native-language fallbacks and context are recorded in
[the terminology notes](LICHESS_TERMINOLOGY.md); the translation review remains
provisional where native review has not occurred.

The signed APK checks covered phone/tablet and constrained window sizes,
three-button Android system insets, rotation during drags/promotion/premoves,
restoration and disconnected-board phone handoff. Before declaring #29 fully
delivered, confirm gesture navigation and actual Android split-screen behavior,
comfortable finger input on a physical phone, and tablet-owner feedback.
Preview qualification does not establish those remaining acceptance outcomes.

The original feature PR did not build or publish an APK. Release #232 qualifies
and publishes the frozen beta.4 source, including Android emulator and signed
upgrade checks; its evidence records actual results and cleanup. No Stable companion applies: this is a Preview
2.6 product feature, and shared build, CI, verification-tool, and cleanup helpers
are unchanged.

## Published Android verification

The production-signed beta.4 APK was tested on phone, tablet, constrained and large-text emulator profiles, including system insets, rotation, tap/drag/promotion/premoves, Analysis controls/graph, Settings persistence and compact-history opening/selection/PGN export. See the release evidence for screenshots, geometry, source/APK hashes, initial System UI ANR diagnostics and the successful unchanged-source native rerun. These are emulator results; comfortable finger input and tablet feedback remain open under #29.

## Preview beta.7 Android qualification

[Published beta.7](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/releases/preview-2.6.0-beta.7.md) delivers #242/#243 and
records actual production-signed ARM64 APK checks for continuous Analysis
scrolling, graph/navigation, tablet/resized/large-text/short-window layouts
and Recent games columns/selection/delete/export flows. Earlier renders remain
host-test illustrations. Physical touch/tablet and actual OS split-screen
acceptance under #29 remain separate; Stable promotion is separate.

## Preview beta.8 Android qualification

[Published beta.8](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/releases/preview-2.6.0-beta.8.md) delivers #246 and records
actual production-signed ARM64 APK checks for coordinated deep reverse-drag
header restoration and first/last/repeated endpoint holds in portrait/landscape,
normal/large text, graph-tab requests, rotation and short-window access. The
header can collapse while navigating. Earlier illustrations remain host renders;
beta.7 evidence applies to its earlier source. Physical touch/tablet acceptance
under #29 and Stable promotion remain separate.

## Preview beta.9 Android qualification

[Published beta.9](https://github.com/Dash1971/maia-chess-android-preview/blob/e162a61e995452b748e5f85d710c6f7dab2ab24a/docs/releases/preview-2.6.0-beta.9.md) delivers #249. Actual production-signed ARM64 APK checks verify independent engine/move panes during scrolling, stepping and endpoint holds, normal/large text, graph requests, rotation and short-window control access. Normal-font profiles show all four engine rows; constrained large text retains independent header scrolling. Earlier illustrations are host renders. Physical touch/tablet acceptance under #29 and Stable promotion remain separate.
