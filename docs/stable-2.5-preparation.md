# Stable 2.5.0 promotion preparation

Prepared 2026-10-27. This is a **PR-only preparation**, not release qualification.
Do not merge, build, tag, sign or publish without the owner's next instruction.
The authoritative procedure remains [RELEASING.md](RELEASING.md).

## Source and acceptance

- Proposed version: **2.5.0**, Android code **82** (after Stable 2.4.0/code 81).
- Stable base: `5f6743eed5491d2e8413fe0dfd1f8ef612d0aa84`.
- Preview snapshot: `e1688ddb8e404716961824dfc9e51d992b238a16`.
- Tested Preview beta.10 release source: `96745a6e49c1b66962b2219ebb23e35a5a1ef1a4`.
  Later Preview commits update release documentation. The promoted application
  behavior matches that tested release, with Stable branding/source links
  restored; no new feature or dependency upgrade is
  introduced during the initial promotion. The subsequent owner-requested
  score-help change adds a localized link to the October 27 score-reliability
  research; it does not change score calculations or inference. The same change
  is proposed in [Preview #203](https://github.com/Dash1971/maia-chess-android-preview/pull/203)
  before either channel publishes.
- The owner reported that physical Chessnut testing passed. This is owner
  acceptance, not independently reproduced radio/LED hardware evidence.
- [Release notes](release-notes/v2.5.0.md), README and Fastlane descriptions cover
  the promoted features. README captures identify Preview provenance; they are
  not presented as screenshots of a newly built Stable APK.

## Preserved Stable boundaries

Application/Dart/native feature code, translations and new regression tests come
from Preview. Stable keeps its blue icon, unflavored Android application ID
`com.dash1971.maia_chess`, 79M model, existing signing identity and published-version
history. No Dev 5M model, Preview default flavor or prototype package is added.
Grand Kingdom and DGT remain blocked by the existing Dart/native channel policy.

Stable keeps its release-source/Fastlane guard, dependency job, F-Droid
qualification and Zapstore workflow. The native reference suite retains Stable's
full 79M checks; the new score/continuation integration tests accept only
unflavored/Stable execution here. The prototype connection widget tests retain their Stable skip
wrapper and run separately with the Dev test override; that override does not
create a Dev APK variant or weaken Stable board restrictions.

The new filtered Chessground package contains the reviewed unchanged 10.1.1
renderer and approved artwork/notices. Source and APK artwork guards are brought
across unchanged from Preview. Stable's advisory inventory permits only this
exact reviewed path/version/provenance and still queries upstream Chessground
advisories. Other non-hosted sources remain rejected.

## Upstreams and shared tooling

See the [dated dependency/security review](dependency-review-2.5.0.md). Retain
Preview's tested pins, including Flutter 3.47.8, Gradle 9.8.1, ONNX Runtime 1.24.3
and dynamic_color 1.9.0. Newer releases are assessed there; no mandatory new
security update was identified. The exact-source resolved Maven audit remains a
separate CI/release requirement.

Shared workspace/cleanup and reproducibility helpers remain identical to
Preview. The imported artwork/localization/APK guards already exist on Preview
main; no companion port is needed. The small advisory path exception changes
Stable's existing `audit_dependencies.py`, which does not exist in Preview;
Preview uses its own reviewed dependency-inventory process. Stable's stronger
legacy upgrade verification, package defaults and release wrappers are retained.
Both channels' existing app tests are represented by the imported tests and
Stable/Dev policy invocations; this preparation does not republish Preview.

## F-Droid and Zapstore preparation

The canonical F-Droid app metadata was checked on 2026-10-27. Its last app-file
commit was `baa962575580c521e22cd5177b2e18ac72da84b0` and its current version was
2.4.0/code 81. The local `fdroid/` file is a **review copy**, refreshed from
canonical metadata and extended with a proposed 2.5.0/code 82 stanza. Its
`v2.5.0` value is an intended future tag, not an existing or verified release.
The inherited build commands, signing-key allowlist, tag detection and version
parsing are unchanged. The recipe reads `.fvmrc`; no hardcoded older Flutter
version is inherited. Re-read canonical metadata before freezing/building source.

Fastlane has an 82 changelog, updated feature descriptions and screenshots.
Zapstore uses the same reviewed wording converted to explicit Markdown, preserving
its established npub, stable-tag filter and APK filename match. No store update
has been submitted and no 2.5 APK exists from this task.

## Checks before publication (not waived by this PR)

1. Finish final-source CI, including the resolved release dependency graph and
   advisory audit. Ordinary PR CI does not run the manual Android job.
2. After merge and explicit build authorization, freeze one full source commit;
   run the GitHub Linux release build and independent Linux reproduction using
   the current canonical F-Droid recipe. Run source/binary scans and require
   identical unsigned APKs.
3. Qualify the real 79M Stable APK, including native inference, Stockfish, themes,
   board preferences/editor, score display, analysis navigation, continuation,
   lifecycle and signed upgrade from published 2.4.0 with games/settings retained.
4. Pass the combined release evidence gate, then sign/tag/publish only with
   authorization. Verify actual GitHub and Zapstore downloads; track F-Droid
   detection, build and catalog publication separately.
5. Clean task-owned output on every host and retain compact verification evidence.

Preparation uses shared Flutter/Pub tools and a disposable Python test environment.
No model binaries, APKs or emulator data are downloaded/created. Test scratch is
removed before handoff; the unmerged PR source checkout and compact logs are
retained for review. Detailed preparation results are recorded in the PR.
