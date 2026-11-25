# Stable 2.6 promotion preparation

Updated **25 November 2026** for **2.6.0 / version code 84**.
[Promotion #82](https://github.com/Dash1971/maia-chess-android/pull/82) is an unmerged
draft. Published Stable remains **2.5.1**. Final Preview testing and release approval remain pending. This update performs no application builds,
GitHub Actions, signing, tagging or publication.

## Candidate source and scope

- Retain the existing Stable 2.6 promotion and [its documentation corrections](https://github.com/Dash1971/maia-chess-android/commit/6e19382e26773fae44ec35ec4944fa22a429a6f7).
- Incorporate current Stable main `7a0f69c141c66e39be1183b3ad46f26158ff9299`, including merged shared release-driver improvements (#85) and the sampling documentation update (#86).
- Promote the app behavior shipped in [Preview beta.13](https://github.com/Dash1971/maia-chess-android-preview/releases/tag/v2.6.0-beta.13), frozen APK source `f1b3c4fa94b2e8aef7aa75a0143ea43406f6495d`. Saved-analysis implementation and fixes come from [Preview #267](https://github.com/Dash1971/maia-chess-android-preview/pull/267), feature source `834a4c85844a0b8e8fe8457464f5f89fc7c1bf53`.
- Completed White-perspective evaluations/mates and standard quality NAGs persist in PGN. Reopening restores graph/markings; explicit reanalysis replaces earlier scores and quality symbols on that line. Prose, clocks, variations and other positional annotations remain.
- The existing export menu offers Include analysis for Save/Share/Copy and Recent games collections. Stripping affects only the exported copy and runs in a background worker. There is no new dialog, setting, database, dependency or permission.
- Fully evaluated imports missing only their initial score restore the graph using one initial-position evaluation. Partial/malformed analysis remains readable without filling missing move scores. Existing generation/lifecycle checks reject stale work.
- Retain the previously promoted adaptive layouts, independent engine/move panes, endpoint holds, compact Recent games, Back/list-position behavior, 5 MiB transfer/duplicates/progress, explicit import destinations, Home-save race fix, recovery, timing defaults and score controls.

## Stable boundaries

Preserve the unflavored `com.dash1971.maia_chess` package, Mobile Maia name, blue
launcher, existing signing configuration, universal ABI set, exact 79M model and
pinned dependency lockfile. No Preview/Dev identity, 5M shortcut or development
signer is promoted. Stable native qualification still uses the full 79M numerical
references.

Grand Kingdom is **supported and has passed user acceptance testing**. Preserve
standard-position/untimed setup, assisted promotion, current-session motor guards
and phone recovery. Chessnut Air/Go are fully tested; Pro remains supported with
further hardware testing welcome. Pegasus stays withdrawn. Automatic diagnostics
remain Dev-only. Camera/image recognition, its model and entry points stay absent.

The release-driver improvements are already merged in Stable main (#85) and
Preview (#270/#271). Preserve shared helpers and each channel's gates. The
classification host fixture now takes the same four-argument Review callback as
the promoted feature; this API adjustment now applies to Stable too. No new shared
build/CI/cleanup behavior is introduced by the app promotion.

## Release material

[Release notes](release-notes/v2.6.0.md), the version-84 Fastlane changelog, English
store descriptions, Zapstore Markdown and README feature guidance must describe
the same candidate. In particular, completed PGN evaluations/markings survive
reopening; the older statement that all completed analysis is memory-only is
superseded. Unfinished per-position analysis is still not a persistent report cache.
Human timing defaults on for unset preferences, including upgrades; an explicitly
saved off value stays off.

Screenshot refresh is limited to Recent games, its import/collection-export menu
and the Analysis Board export menu with Include analysis. These are unmodified
captures from the published Preview beta.13 APK, with no visible Preview label.
[Provenance](screenshots/20261125_v0_shared_2_6_provenance.md) records the APK/source,
fixture data, device and image hashes. Home/About are excluded; other explicitly
identified Stable 2.5 examples remain. This is not Stable APK qualification.

The [user guide](USER_GUIDE.md) now holds detailed feature/install instructions;
README is a short overview. [Documentation preparation](verification/stable-26-documentation-2026-11-25.md)
records #87–#89, preserved links, extracted Zapstore/history guidance and cleanup.

## Verification and remaining gates

The promoted host suite passes 1,611 tests with one skipped; analyzer is clean.
All ten catalogs pass localization/terminology checks (474 messages). The Python
verification suite and new documentation link/fragment checks pass. Metadata and
committed-source guards are checked with the final preparation commit. Existing Preview beta.13
[qualification](https://github.com/Dash1971/maia-chess-android-preview/blob/main/docs/releases/preview-2.6.0-beta.13.md)
includes real engine/model, upgrade, PGN persistence and transfer evidence; it is
context for testing, not qualification of this Stable source.

Before publication, follow [RELEASING.md](RELEASING.md):

1. Obtain final testing approval; finish accurate metadata/media and freeze one full Stable source commit.
2. Perform the fresh upstream/dependency review and exact-source Stable CI, Android build and required native/model checks.
3. Independently reproduce with the current canonical F-Droid recipe and scans; require matching unsigned Linux APKs, then sign using the established Stable key.
4. Verify signed 2.5.1 upgrade and game/settings/data preservation, changed-feature/runtime checks and the combined qualification gate.
5. Publish and verify the immutable GitHub APK; complete Zapstore verification and separately track F-Droid detection, build/request and catalog publication.
6. Retain compact evidence and clean all task-owned bulk promptly; finish the documentation/status pass.

Earlier source reviews and host runs are retained in Git history and the linked
[PGN transfer](verification/pgn-import-entry-points-2026-11-23.md),
[collection scale](verification/pgn-collection-import-2026-11-22.md) and
[Grand Kingdom acceptance](ELECTRONIC_BOARD_GRAND_KINGDOM_26.md) records. Their older
candidate hashes, CI-skip statements and pending work describe those dated tasks;
they are not a current release qualification result or a reason to reopen passed
Grand Kingdom acceptance.
