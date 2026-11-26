# Build channels and promotion status

This checkout is Stable **2.6.0 / code 84**. Channels have separate packages
and publication records; use the release links for the actual published versions.

| Channel | Published release | Package / model | Source policy |
| --- | --- | --- | --- |
| Stable | [Published Stable releases](https://github.com/Dash1971/maia-chess-android/releases/latest) | `com.dash1971.maia_chess`, blue icon, 79M | 2.6.0 / code 84; full Stable release procedure. |
| Preview | [Current Preview and Dev status](https://github.com/Dash1971/maia-chess-android-preview/blob/main/docs/BUILD_CHANNELS.md) | Gold icon; 79M | Preview owns its current version, testing scope and release history. |
| Dev | [Dev releases](https://github.com/Dash1971/maia-chess-android-preview-dev/releases) | `com.dash1971.maia_chess.preview.dev`, red icon, 5M | Canonical Preview source, separate Dev procedure; automatic detailed diagnostics remain Dev-only. |

## Current source policy

Chessnut and Grand Kingdom are the only supported board families. Pegasus is
removed from every channel because initialization permission and downstream
redistribution remain unresolved. The [decision](decisions/2026-11-22-electronic-board-support.md)
distinguishes that concern from the GPL-licensed protocol reference. See the
[README table](../README.md#electronic-board-support) for hardware testing status.
Old Dev saves recover on the phone without reconnecting to the retired board.

Grand Kingdom is supported across Stable 2.6, Preview and Dev and has passed
user acceptance testing; see the
[acceptance record](ELECTRONIC_BOARD_GRAND_KINGDOM_26.md). Both source repositories use the same Dart and native policy for these channels, including
unflavored Stable. Unknown packaging channels remain closed. Shared Chessnut behavior, motor session guards and
channel restriction tests remain in place. Only Dev records automatic local
traces; Stable/Preview routine diagnostics remain bounded summaries.

The packages install side by side with separate app data. PGN collection
transfer now uses matching 5 MiB import/export limits and imports every game
into Recent games. It transfers games/annotations, not app settings or live
clock/motor session checkpoints. Recent games import saves every game, including single-game files; Analysis
Board opens only the first game. Android Open with/shared attachments retain
their existing routing.

## Release instructions

- [Stable release procedure](https://github.com/Dash1971/maia-chess-android/blob/main/docs/RELEASING.md): exact-source qualification, canonical F-Droid reproduction, signed upgrade checks and separate GitHub/F-Droid/Zapstore delivery status.
- [Preview/Dev release procedure](https://github.com/Dash1971/maia-chess-android-preview/blob/main/docs/RELEASING.md): preserve each channel's model, identity, native/upgrade checks and release gates.

Source promotion does not publish an APK. Stable publication requires its own
exact-source CI, independent Linux/F-Droid reproduction, signed-upgrade and
store checks. Earlier published APKs and tags are immutable.

## Saved analysis in Mobile Maia 2.6

Mobile Maia 2.6 includes PGN evaluations/markings, graph restoration,
initial-score-only recovery for compatible imports, and Include analysis in
existing export menus. It uses existing game records and preserves Stable's
identity, universal ABIs and 79M model. See [feature behavior](PGN_ANALYSIS.md)
and the dated [preparation record](stable-2.6-preparation.md).

## Historical channel records

[Dated channel and publication records](history/channel-publication-records.md)
retain the earlier sources, results and limits. Current Preview records belong in
[Preview's release directory](https://github.com/Dash1971/maia-chess-android-preview/tree/main/docs/releases).
Historical statements about retired board gates do not override current support.

<details>
<summary>Links to archived sections</summary>

<a id="opening-variety-promoted-in-stable-24"></a><a href="history/channel-publication-records.md#opening-variety-promoted-in-stable-24">Opening variety promoted in Stable 2.4</a><br>

<a id="beta14-baseline-for-stable-24"></a><a href="history/channel-publication-records.md#beta14-baseline-for-stable-24">Beta.14 baseline for Stable 2.4</a><br>

<a id="stable-24-promotion-boundary"></a><a href="history/channel-publication-records.md#stable-24-promotion-boundary">Stable 2.4 promotion boundary</a><br>

<a id="dev-limitations"></a><a href="history/channel-publication-records.md#dev-limitations">Dev limitations</a><br>

<a id="preview-240-beta1-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta1-publication-record">Preview 2.4.0-beta.1 publication record</a><br>

<a id="preview-240-beta2-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta2-publication-record">Preview 2.4.0-beta.2 publication record</a><br>

<a id="preview-240-beta3-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta3-publication-record">Preview 2.4.0-beta.3 publication record</a><br>

<a id="preview-240-beta4-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta4-publication-record">Preview 2.4.0-beta.4 publication record</a><br>

<a id="preview-240-beta5-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta5-publication-record">Preview 2.4.0-beta.5 publication record</a><br>

<a id="preview-240-beta6-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta6-publication-record">Preview 2.4.0-beta.6 publication record</a><br>

<a id="preview-240-beta7-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta7-publication-record">Preview 2.4.0-beta.7 publication record</a><br>

<a id="preview-240-beta8-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta8-publication-record">Preview 2.4.0-beta.8 publication record</a><br>

<a id="preview-240-beta9-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta9-publication-record">Preview 2.4.0-beta.9 publication record</a><br>

<a id="preview-240-beta10-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta10-publication-record">Preview 2.4.0-beta.10 publication record</a><br>

<a id="preview-240-beta11-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta11-publication-record">Preview 2.4.0-beta.11 publication record</a><br>

<a id="preview-240-beta12-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta12-publication-record">Preview 2.4.0-beta.12 publication record</a><br>

<a id="preview-240-beta13-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta13-publication-record">Preview 2.4.0-beta.13 publication record</a><br>

<a id="preview-240-beta14-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta14-publication-record">Preview 2.4.0-beta.14 publication record</a><br>

<a id="preview-240-beta15-publication-record"></a><a href="history/channel-publication-records.md#preview-240-beta15-publication-record">Preview 2.4.0-beta.15 publication record</a><br>

</details>
