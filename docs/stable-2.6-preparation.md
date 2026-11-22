# Stable 2.6 promotion draft

Prepared 22 November 2026. This draft proposes **2.6.0 / version code 84**. It does not build or publish an APK, run GitHub Actions, or update F-Droid/Zapstore. Stable 2.5.1 remains the published release.

## Source and scope

- Stable base: `eac2e512e9a10cebc26f3c2f72675fae598a4908`.
- Current Preview source: `e162a61e995452b748e5f85d710c6f7dab2ab24a`, the beta.10 publication/documentation head. Preview's exact APK source is `89097ac739fb83f08b14cc9c119d27c538870257`; its release evidence is not qualification of this Stable draft.
- Promote the current app, localization, Android transport/document handling, and regression changes: adaptive layouts; independent engine/move panes; first/last holds; Recent games and Back behavior; 5 MiB bulk PGN export / 2 MiB import; timing defaults; score visibility; interrupted-game/save recovery; same-open-Review analysis resume; Grand Kingdom assisted promotion and session-safe motor handling.
- Enable Grand Kingdom in Dart and native Stable/unflavored policies. Keep unknown channels closed and DGT Pegasus Dev-only. Preserve explicit setup, session guards, promotion confirmation and phone fallback.
- Dev recording/export code remains gated by Dev in Dart and native code. Stable neither records nor exposes automatic Dev diagnostics.
- Do not restore camera/image recognition or add its model, camera entry points, runtime or permissions.

## Stable boundaries retained

Preserve the unflavored `com.dash1971.maia_chess` package, Mobile Maia name, blue launcher artwork, established signer configuration, universal ABI set, exact 79M asset/hash and existing dependency lockfile. No Dev 5M model/default flavor or development signer is added.

Keep Stable's release wrapper, source gate, dependency/audit job, canonical F-Droid reproduction/scans, combined qualification gate, legacy upgrade checks, explicit Zapstore Markdown, store publication procedure and store identities. Official Stable and Preview both use 79M. Stable Android qualification continues to require the full 79M numerical references.

The four mandatory workspace/cleanup helpers remain byte-identical to Preview. The Gradle 9.9.2 pin/checksum and verifier match current Preview and include the scope of [Stable #81](https://github.com/Dash1971/maia-chess-android/pull/81), which remains a separate open PR. [#73](https://github.com/Dash1971/maia-chess-android/pull/73) is the older 9.9.1 pin. This promotion includes the later navigation behavior rather than independently applying the earlier, partial [#78](https://github.com/Dash1971/maia-chess-android/pull/78). No companion app promotion or publication is implied.

## Pre-build source review — 22 November 2026

Review against Stable and current Preview found no additional app-code omissions
or accidental behavior changes. Stable's 2.5.1 unsafe-position checks and their
native/real-engine regressions remain in place. The independent analysis/move
panes, endpoint holds, saved-game browsing position, selection cancellation,
separate PGN limits and Grand Kingdom session/promotion safeguards match the
intended scope. Package, model, signing configuration and release gates remain
unchanged outside the documented promotion adaptations.

Corrected stale guide text that still blocked Grand Kingdom, treated historical
capture reports as a current release blocker, or described the manual editor as
Preview-only. Historical dated release records remain intact. No app code or
shared tooling changed during this review.

All four files in #81 match this draft byte for byte. Merge that focused security
PR before merging this promotion, then verify the updated promotion diff. Its
existing test and dependency jobs passed; Android was skipped. Neither PR has
been merged as part of this review. Fresh Stable screenshots and exact-source
runtime/release qualification remain pending; this source review does not replace
them. No builds, Actions or LFS downloads were run.

## Prepared metadata and screenshots

The draft includes [release notes](release-notes/v2.6.0.md), a version-84 Fastlane changelog, English store-description updates and matching Zapstore Markdown, plus README feature introductions. Download links continue to target the published release until publication.

Existing Stable 2.5 screenshots remain identified by their actual version. Fresh Stable 2.6 screenshots for changed Home, landscape/Analysis controls, Recent games, timing defaults and Grand Kingdom setup are pending: the instruction not to build prevents new actual-APK captures in this task. Preview host illustrations remain labeled as such; they are not substituted for Stable screenshots. Refresh affected README/Fastlane media before the final source freeze.

## Validation and publication boundary

Source-only checks in this task cover identity/model/build-gate preservation, Preview source parity with explicit Stable adaptations, matching channel policies, metadata/catalog/terminology consistency and the reviewed security pin. No Flutter tests, Kotlin compilation, APK build or Actions run is performed. Full app and native behavior tests are prepared for later execution, not claimed as passed on Stable.

Before publication, use [RELEASING.md](RELEASING.md): complete a fresh upstream/dependency review; confirm the canonical F-Droid recipe and version code; refresh changed screenshots; freeze the final source; run exact-source Stable CI/audit and independent Linux reproduction; verify full native/model/channel tests and signed Stable 2.5.1 upgrades/data retention; complete the combined gate and separately verify GitHub, F-Droid progress and Zapstore. Store publication and hardware/emulator evidence are distinct. Preview evidence remains useful context, not a replacement for these gates.

[Preview beta.10 qualification](https://github.com/Dash1971/maia-chess-android-preview/blob/main/docs/releases/preview-2.6.0-beta.10.md) and the [Grand Kingdom acceptance record](ELECTRONIC_BOARD_GRAND_KINGDOM_26.md) retain the existing test scope and hardware feedback. Their dated untested scenarios remain recorded; they do not remove Grand Kingdom from the authorized Stable 2.6 scope.
