# Stable 2.6 promotion draft

Prepared 22 November 2026. This draft proposes **2.6.0 / version code 84**. It does not build or publish an APK, run GitHub Actions, or update F-Droid/Zapstore. Stable 2.5.1 remains the published release.

## Source and scope

- Original Stable base: `eac2e512e9a10cebc26f3c2f72675fae598a4908`. Updated against main at `af21c730f2b029b8068a1dc41c035ac9a4977207` after #81 merged on 22 November. The main merge changed no files in the promotion tree because its security changes were already included.
- Preview promotion baseline: `e162a61e995452b748e5f85d710c6f7dab2ab24a`, the beta.10 publication/documentation head. Preview's exact APK source is `89097ac739fb83f08b14cc9c119d27c538870257`; its release evidence is not qualification of this Stable draft.
- Promote the current app, localization, Android transport/document handling, and regression changes: adaptive layouts; independent engine/move panes; first/last holds; Recent games and Back behavior; matching 5 MiB PGN import/export and complete collection transfer; timing defaults; score visibility; interrupted-game/save recovery; same-open-Review analysis resume; Grand Kingdom assisted promotion and session-safe motor handling.
- Enable Grand Kingdom in Dart and native Stable/unflavored policies. Keep unknown channels closed and withdraw DGT Pegasus from every channel. Preserve explicit setup, session guards, promotion confirmation and phone fallback.
- Dev recording/export code remains gated by Dev in Dart and native code. Stable neither records nor exposes automatic Dev diagnostics.
- Do not restore camera/image recognition or add its model, camera entry points, runtime or permissions.

## Stable boundaries retained

Preserve the unflavored `com.dash1971.maia_chess` package, Mobile Maia name, blue launcher artwork, established signer configuration, universal ABI set, exact 79M asset/hash and existing dependency lockfile. No Dev 5M model/default flavor or development signer is added.

Keep Stable's release wrapper, source gate, dependency/audit job, canonical F-Droid reproduction/scans, combined qualification gate, legacy upgrade checks, explicit Zapstore Markdown, store publication procedure and store identities. Official Stable and Preview both use 79M. Stable Android qualification continues to require the full 79M numerical references.

The four mandatory workspace/cleanup helpers remain byte-identical to Preview. The Gradle 9.9.2 pin/checksum and verifier match current Preview and [Stable #81](https://github.com/Dash1971/maia-chess-android/pull/81), now merged into main. Those security files are no longer part of this promotion's diff against main. [#73](https://github.com/Dash1971/maia-chess-android/pull/73) is the older 9.9.1 pin. This promotion includes the later navigation behavior rather than independently applying the earlier, partial [#78](https://github.com/Dash1971/maia-chess-android/pull/78). No companion app promotion or publication is implied.

## Pre-build source review — 22 November 2026

Review against Stable and current Preview found no additional app-code omissions
or accidental behavior changes. Stable's 2.5.1 unsafe-position checks and their
native/real-engine regressions remain in place. The independent analysis/move
panes, endpoint holds, saved-game browsing position, selection cancellation,
PGN transfer and Grand Kingdom session/promotion safeguards match the
intended scope. Package, model, signing configuration and release gates remain
unchanged outside the documented promotion adaptations.

Corrected stale guide text that still blocked Grand Kingdom, treated historical
capture reports as a current release blocker, or described the manual editor as
Preview-only. Historical dated release records remain intact. No app code or
shared tooling changed during this review.

All four files in #81 match this draft byte for byte. That focused security PR
has now merged before this promotion; the updated promotion diff excludes its
files. Its existing test and dependency jobs passed; Android was skipped. This
promotion remains a draft and has not merged. Fresh Stable screenshots and
exact-source runtime/release qualification remain pending; this source review
does not replace them. Both the #81 merge and promotion update use CI-skip commit
messages. No builds, Actions or LFS downloads were run.

## Prepared metadata and screenshots

The draft includes [release notes](release-notes/v2.6.0.md), a version-84 Fastlane changelog, English store-description updates and matching Zapstore Markdown, plus README feature introductions. Download links continue to target the published release until publication.

Existing Stable 2.5 screenshots remain identified by their actual version. Fresh Stable 2.6 screenshots for changed Home, landscape/Analysis controls, Recent games, timing defaults and Grand Kingdom setup are pending: the instruction not to build prevents new actual-APK captures in this task. Preview host illustrations remain labeled as such; they are not substituted for Stable screenshots. Refresh affected README/Fastlane media before the final source freeze.

## Validation and publication boundary

The initial source review checked identity/model/build-gate preservation, Preview parity with explicit Stable adaptations, channel policies, metadata/catalog/terminology consistency and the reviewed security pin. The review follow-up also ran the host Flutter regressions and analyzer listed below. Kotlin compilation, Android/runtime tests and release qualification remain pending; no APK build or Actions run was performed.

Before publication, use [RELEASING.md](RELEASING.md): complete a fresh upstream/dependency review; confirm the canonical F-Droid recipe and version code; refresh changed screenshots; freeze the final source; run exact-source Stable CI/audit and independent Linux reproduction; verify full native/model/channel tests and signed Stable 2.5.1 upgrades/data retention; complete the combined gate and separately verify GitHub, F-Droid progress and Zapstore. Store publication and hardware/emulator evidence are distinct. Preview evidence remains useful context, not a replacement for these gates.

[Preview beta.10 qualification](https://github.com/Dash1971/maia-chess-android-preview/blob/main/docs/releases/preview-2.6.0-beta.10.md) and the [Grand Kingdom acceptance record](ELECTRONIC_BOARD_GRAND_KINGDOM_26.md) retain the existing test scope and hardware feedback. Their dated untested scenarios remain recorded; they do not remove Grand Kingdom from the authorized Stable 2.6 scope.

## Review follow-up and testing plan

The follow-up adds matching 5 MiB UTF-8 import/export limits and complete
collection import into Recent games. Single-game opening is unchanged. Whole
collections are validated off-thread and staged before a single commit; failure
must preserve the current game, recovery settings and existing records. Imported
names/dates/annotations are retained, including after reopening and saving.
PGN transfer does not copy app settings or live clock/motor session checkpoints.

Individual-game and aggregate export-size errors are distinct. Bluetooth,
permission and status messages are board-neutral in every language. The timing
notes explicitly cover upgrades without a saved preference; saved off remains
off. Selection-toolbar deletion and unfinished-game confirmation are intentional.

Pegasus has been removed from Stable and all Preview/Dev flavors. The
[support decision](decisions/2026-11-22-electronic-board-support.md) records the
unresolved initialization permission separately from the GPL protocol reference.
README tables show Air/Go fully tested, Pro supported but not fully tested,
Grand Kingdom supported and partially tested, and Pegasus unsupported. Protocol
attribution and the invitation for owners/manufacturers are included.

The [Preview companion #261](https://github.com/Dash1971/maia-chess-android-preview/pull/261) carries the same changes for beta.11 testing (1,507 host tests passed, one skipped; 130 explicit Preview-flavor focused tests passed). Stable
release approval remains pending that testing and its own exact-source release
qualification. This task performs no Android build, Actions run or LFS download.

## Host verification of the review follow-up

Stable: 1,507 host tests passed, one skipped; the additional Dev board-policy suite passed 41 tests. Flutter analyze reports no issues. Localization/terminology, source gates, metadata consistency and unchanged workflow structure checks pass. Native policy regressions are updated but not compiled: the current Mac host has no JDK. These checks do not qualify an Android release.
