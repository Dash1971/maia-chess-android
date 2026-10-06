# Stable 2.3.0 upstream and dependency review — 2026-10-06

Preparation checkpoint, not final-source publication qualification. Promote the
features tested in Preview 2.3.0-beta.9 while retaining Stable's established
native engines/toolchain. The only added runtime dependency entries are the
Flutter SDK localization library and `intl` 0.20.3, both already used by Preview.

## Advisory check

At 2026-10-06 10:33 JST, the new audit queried [OSV](https://osv.dev/) for
**155 distinct package/version entries**: 59 locked Pub packages, 89 resolved
Android release Maven modules plus declared AGP/Kotlin plugins and Gradle core, and four
pinned Python release/test tools. No active advisory matches were returned.
One earlier preliminary request received HTTP 503 and correctly failed; the
completed audit includes bounded retries and does not silently skip failures.

Comparison with clean Linux CI exposed that the initial local 116-entry scan
had omitted Flutter plugins because local `pub get` had not finished writing its
plugin manifest. The completed local and CI graphs now both cover 155 entries.
The audit explicitly rejects a missing manifest or plugins absent from the
resolved release graph; the missing-manifest negative check passed. Use the
completed scan reported here, not the superseded partial snapshot.

- Pub lock SHA-256: `fa12b3dea734d731b33220c24133b38addef5e7dda4fb7311e118fc2eca8e650`
- Resolved Maven inventory SHA-256: `fb86342460cc72cf29eb98f688ce14eef17a725cf1632fa0d2ff289ce3d646c6`
- `flutter pub outdated --json` reported no current package affected by a Pub
  advisory. It did report newer versions, considered below.
- Android release dependency resolution completed locally without an APK/model
  build. Existing Gradle warnings concern the legacy Android DSL and Kotlin
  plugin migration ahead of AGP 10; they are not a reason to change toolchains
  during this already-tested feature promotion.

This is a package-advisory lookup, not proof of zero vulnerabilities. Native
binaries, Flutter/Dart SDK internals, model weights and the full build-tool
transitive graph are not covered by this inventory. GitHub CI retains its own
exact-source inventory/report artifact; the manual release run must repeat it
and pass `tool/qualify_release.py` before publication. Do not substitute this
preparation snapshot for that final run.

## Upstream decisions

| Component | Candidate | Upstream checked | Decision for this promotion |
| --- | --- | --- | --- |
| Flutter | 3.47.5, `6a19cca…` | Stable/tag 3.47.6 at `5fc346839b5d0eef006ed8404392afb4dfae428d` | Defer. The compared hotfix includes a Windows timer change and Dart/engine revisions. The reproducibility backport deliberately guards 3.47.5; a bump needs a separately tested backport and fresh Linux/F-Droid reproducibility evidence. No relevant public Flutter repository advisory was returned in the review. |
| Gradle / Android Gradle plugin / Kotlin | 9.3.1 / 9.1.0 / 2.4.20 | Gradle 9.8.0, AGP 9.4.1, Kotlin 2.4.20 | Keep the tested toolchain. Gradle's public high-severity advisories GHSA-mqwm-5m85-gmcv and GHSA-w78c-w6vf-rw82 are fixed from 9.3.0, below the pinned 9.3.1. Upgrading AGP also intersects Flutter's legacy-DSL compatibility; qualify separately. |
| ONNX Runtime Android | 1.24.3 | 1.30.0 on Maven Central and GitHub | Consider next as a dedicated native-runtime upgrade. Upstream includes model/input-validation and memory-hardening changes; do not dismiss them. This app loads a fixed hash-verified bundled model, not arbitrary external models. No OSV match was returned for the installed Android artifact, but native advisory coverage may be incomplete. Validate inference parity, supported ABIs, Android 16 behavior, performance and APK reproducibility before upgrading. |
| Maia-3 source/model | Source `1e13597c42d4858b7cfd7cfdae01e297263364b2`; bundled 79M | Upstream source HEAD is the same revision | Keep existing model and provenance. No new model is introduced. |
| Stockfish / multistockfish | Stockfish 19 Light; multistockfish 0.6.1; light wrapper 0.1.0 | Stockfish `sf_19`; wrapper versions unchanged upstream | Keep tested engine and guarded NNUE hash. |
| chessground | 10.1.1 | 10.3.0 (10.2.0 also available) | Defer. 10.2 adds custom shapes; 10.3 changes dependencies to dartchess 0.14.0. Existing 10.1.1 already includes the multitouch fix. No required security update identified. |
| dartchess | 0.13.1 | 0.14.0 | Defer. New hashing and en-passant reporting APIs are not required for the promoted features. Retest rules, FEN/PGN and variations together with any future Chessground update. |
| intl | 0.20.3 | 0.20.3 | Retain Preview's localization dependency. |
| package_info_plus | 10.2.1 | 10.2.2 | Defer the Kotlin build-plugin fix to the next dependency qualification; current Android graph resolves successfully. |
| shared_preferences | 2.5.5 | 2.5.6; Android 2.4.28 vs installed 2.4.27 | Defer. Root update documents return-value semantics and changes minimum SDK requirements; no security advisory match was returned for the installed versions. Preserve the tested storage stack for promotion. |
| GitHub Actions | checkout 7.0.1, setup-java 6.0.1, upload-artifact 7.0.1 | Matching latest releases in their official repositories | Keep the existing immutable SHA pins. |
| chess | 0.8.1 | 0.8.1 | Unchanged. |

Other reported updates are clock, cupertino_icons, material_color_utilities,
meta, platform, process, shared_preferences_foundation, stack_trace, test_api,
vector_math and webdriver. Some are constrained by the pinned SDK or involve
major versions. None was flagged as currently affected by Pub advisories;
retain the tested lockfile rather than performing an indiscriminate upgrade.

Upstream sources checked:

- [Checkout releases](https://github.com/actions/checkout/releases), [setup-java releases](https://github.com/actions/setup-java/releases), [upload-artifact releases](https://github.com/actions/upload-artifact/releases)

- [Gradle advisories](https://github.com/gradle/gradle/security/advisories), [AGP versions](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/maven-metadata.xml), [Kotlin releases](https://github.com/JetBrains/kotlin/releases)
- [Flutter comparison](https://github.com/flutter/flutter/compare/6a19cca56475dbfba1478ee68d7bd0c2ef891da1...5fc346839b5d0eef006ed8404392afb4dfae428d), [Flutter advisories](https://github.com/flutter/flutter/security/advisories)
- [ONNX Runtime 1.30.0 release/security notes](https://github.com/microsoft/onnxruntime/releases/tag/v1.30.0), [Android Maven versions](https://repo.maven.apache.org/maven2/com/microsoft/onnxruntime/onnxruntime-android/maven-metadata.xml), [ONNX Runtime advisories](https://github.com/microsoft/onnxruntime/security/advisories)
- [Maia-3 source](https://github.com/CSSLab/maia3), [79M model](https://huggingface.co/UofTCSSLab/Maia3-79M), [Stockfish 19](https://github.com/official-stockfish/Stockfish/releases/tag/sf_19)
- [Chessground](https://pub.dev/packages/chessground/changelog), [dartchess](https://pub.dev/packages/dartchess/changelog), [package_info_plus](https://pub.dev/packages/package_info_plus/changelog), [shared_preferences](https://pub.dev/packages/shared_preferences/changelog)

Version-specific package archive changelogs were also read from Pub's API;
its live versions can be newer than cached web changelog pages.

## Continuing protection

The new `dependencies` CI job runs on each PR, main push and manual release run.
It refuses missing plugin manifests, omitted plugin projects, unresolved graphs,
unknown package sources, dynamic versions,
malformed/incomplete OSV responses and persistent network failures. It follows
pagination and ignores only explicitly withdrawn advisories. No blanket ignore
list is introduced. The publication gate now requires this job in addition to
`test` and `android`. Read release-guide section 0 for the exact scope and the
manual upstream review that remains necessary at each promotion.
