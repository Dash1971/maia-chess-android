# Upstream and dependency review — 2026-10-17

## Follow-up: Gradle blocker resolved in Preview beta.14

[PR #149](https://github.com/Dash1971/maia-chess-android-preview/pull/149)
updates Gradle to 9.8.1, pins the official checksum and adds an offline CI/build
guard. Published [Preview 2.4.0-beta.14](https://github.com/Dash1971/maia-chess-android-preview/releases/tag/v2.4.0-beta.14)
includes that fix; exact-source CI and independent Linux APK reproduction passed.
The [Stable companion's inherited F-Droid recipe](https://github.com/Dash1971/maia-chess-android/pull/53#issuecomment-6228113567)
also passed source/binary scans and reproduced its CI APK exactly, without a
Gradle-specific recipe change. Stable publication still requires owner acceptance
and qualification of its final source. See [the channel record](BUILD_CHANNELS.md).

The original review and JSON below remain a dated snapshot of the older source,
not a claim that the current Preview still uses Gradle 9.3.1.

## Original review decision

**Stable release was not cleared at the reviewed source.** Its Gradle 9.3.1
pin was affected by three upstream security advisories and required a qualified
build-tool update. The original board-promotion draft recorded upgrade decisions;
it did not itself upgrade dependencies, change engines/models or authorize
publication.

Reviewed Preview source: `156a908bacde7f3bcb8615eb4be7a2821fd01b94`.
[Machine-readable evidence](dependency-audit-2026-10-17.json) records package
queries, input hashes, upstream advisory IDs and the separate overall decision.

## Required: secure the build toolchain

Gradle published these high-severity advisories on October 7. Each explicitly
includes 9.3.1 in its affected range and lists **9.8.1 / 8.14.6** as patched
open-source releases:

- [GHSA-mvvg-497x-hmj8](https://github.com/gradle/gradle/security/advisories/GHSA-mvvg-497x-hmj8): unauthenticated worker/daemon communication can deserialize hostile data.
- [GHSA-xwqc-3h47-hg64](https://github.com/gradle/gradle/security/advisories/GHSA-xwqc-3h47-hg64): client/daemon communication deserializes data before authentication.
- [GHSA-j5m7-59rp-24f5](https://github.com/gradle/gradle/security/advisories/GHSA-j5m7-59rp-24f5): certain repository connection failures can cause resolution from a later repository, enabling artifact substitution under the described conditions.

These concern build hosts and dependency resolution, not a demonstrated
vulnerability in gameplay on a phone. This review found no evidence of compromise.
The first two require access to the build host's local communication channel;
shared/multi-user build machines deserve particular attention.

**Recommendation:** qualify open-source Gradle 9.8.1 with a compatible
Flutter/AGP/Kotlin combination in a separate toolchain PR. Do not blindly change
the wrapper or downgrade to 8.14.6 under AGP 9.1.0. Patch releases on other lines
mentioned as part of Gradle's Security Subscription are not our FOSS solution.
Update wrapper integrity hashes, Docker/build documentation, CI pins and
F-Droid recipe assumptions together. Check reproducibility on Linux and the
final Stable source before publication.

## Upstream versions and decisions

Available versions are a dated snapshot, not a requirement to upgrade everything.

| Component | Current | Upstream reviewed | Decision |
| --- | --- | --- | --- |
| Flutter / Dart | 3.47.5 / 3.13.4 | [Flutter stable changelog](https://github.com/flutter/flutter/blob/stable/CHANGELOG.md): 3.47.7 | Consider with toolchain qualification. The intervening notes primarily address Windows/iOS/accessibility; no Android release blocker identified from those notes. Preserve coordinated F-Droid SDK pins. |
| Gradle | 9.3.1 | [9.8.1](https://github.com/gradle/gradle/releases/tag/v9.8.1) | Required security qualification above. |
| Android Gradle Plugin | 9.1.0 | [Google Maven metadata](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/maven-metadata.xml): stable 9.4.1 | Choose a supported combination with Gradle/Flutter; do not assume the newest versions work together. |
| Kotlin Gradle plugin | 2.4.20 | [2.4.21](https://github.com/JetBrains/kotlin/releases/tag/v2.4.21) | Consider in that same compatibility matrix. |
| ONNX Runtime Android | 1.24.3 | [1.31.0](https://github.com/microsoft/onnxruntime/releases/tag/v1.31.0), Maven publication checked | Separate runtime qualification; not a late blind upgrade. Require 79M inference/probability comparisons, memory, speed, ABI and offline/privacy checks. Upstream notes mention default telemetry for supported native builds: verify Android AAR applicability rather than assume either presence or absence. |
| Stockfish / multistockfish | 19 Light / 0.6.1 | [Stockfish 19](https://github.com/official-stockfish/Stockfish/releases/tag/sf_19), [wrapper 0.6.1](https://pub.dev/packages/multistockfish/changelog) | Retain. Later development snapshots are not a reason to change the release engine. |
| Maia3 / model | Existing pinned 79M assets | [Upstream HEAD reviewed](https://github.com/CSSLab/maia3/commit/1e13597c42d4858b7cfd7cfdae01e297263364b2) | No model replacement proposed. Preserve asset hashes/provenance and sampling regressions. |
| chessground | 10.1.1 | [10.3.0](https://pub.dev/packages/chessground/changelog) | Defer API/features update; changes include CustomShape and removal of Material dependency with dartchess update. Recheck touch, animation and premoves if upgraded. |
| dartchess | 0.13.1 | [0.14.0](https://pub.dev/packages/dartchess/changelog) | Defer; includes hashing/en-passant API changes. |
| package_info_plus | 10.2.1 | [10.2.2](https://pub.dev/packages/package_info_plus/changelog) | Consider alongside AGP/Kotlin; patch includes conditional KGP handling for AGP built-in Kotlin. |
| shared_preferences / Android implementation | 2.5.5 / 2.4.27 | [2.5.6](https://pub.dev/packages/shared_preferences/changelog) / [2.4.28](https://pub.dev/packages/shared_preferences_android/changelog) | No urgent app fix identified; avoid unnecessary storage dependency churn before release. |
| cupertino_icons | 1.0.9 | [2.0.0](https://pub.dev/packages/cupertino_icons/changelog) | Defer major update. |

Other transitive Pub updates were inventoried with `flutter pub outdated --json`;
no blanket dependency refresh is proposed. "No urgent fix identified" is limited
to reviewed release notes and advisory sources, not a guarantee of no bugs.

## Automated security coverage and its limit

The canonical Stable dependency auditor queried OSV for **154 distinct exact
package versions**, with no reported advisories/errors at
`2026-10-17T00:46:45.466251+00:00`. Inputs included all locked hosted Pub packages,
a fresh `previewReleaseRuntimeClasspath` Maven resolution (including release
Android plugins), direct ONNX/AGP/Kotlin/Gradle pins and pinned Python hardening
tools. The init script used Stable's release-graph checks adapted to Preview's
configuration name.

**That automatic result is insufficient:** OSV returned no advisory for the
Gradle pin while Gradle's own published advisories explicitly mark it affected.
Manual upstream review caught this coverage/indexing gap. The evidence therefore
records `needs_security_upgrade` as the overall result, not a security pass.
The query does not fully cover transitive build-tool dependencies, Flutter/Dart
SDK internals, native source internals or a future Stable dependency graph.

Stable already has a `dependencies` CI job and requires manual SDK/native/model
review in its [authoritative release guide](https://github.com/Dash1971/maia-chess-android/blob/main/docs/RELEASING.md).
Preserve both when promoting Preview. Do not substitute Preview's lighter
workflow or treat a green dependency job as overriding a known advisory.

## Before Stable promotion/publication

1. Resolve the Gradle advisories with a tested FOSS toolchain update. Repeat the
   exact-version advisory queries and upstream review on the resulting pins.
2. Preserve Stable's package identity, signing continuity and authoritative
   release/security/store tooling. Carry the new Stable/unflavored board tests
   into that workflow; keep DGT and Grand Kingdom blocked outside Dev.
3. Run final-source Android packaging, real upgrade/data-retention and saved
   Chessnut restore checks. Host mocks cannot establish physical BLE reliability.
4. Follow the Stable guide for independent Linux reproducibility, canonical
   F-Droid build metadata/auto-update compatibility, fastlane text and version
   consistency. A successful GitHub release is not proof of F-Droid publication.
5. Perform the guide's Zapstore update/verification as well as GitHub and F-Droid
   follow-up. Record the exact source and distribution status separately.

This is a draft preparation review. No Stable greenlight is implied.
