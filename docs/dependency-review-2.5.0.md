# Stable 2.5.0 preparation: upstream and security review

Reviewed **2026-10-27 JST** (fresh package/advisory queries began
`2026-10-26T23:36:20Z`). Decision: retain the proposed pins. No newly identified
applicable advisory requires a dependency upgrade in this preparation PR.
**This is not release qualification or permission to publish.**

## Source and coverage

Reviewed Stable base `5f6743eed5491d2e8413fe0dfd1f8ef612d0aa84` and promoted
Preview source `e1688ddb8e404716961824dfc9e51d992b238a16`. Their Android
Gradle/AGP/Kotlin and ONNX pins match. The Pub lock changes only from hosted
Chessground 10.1.1 to its filtered local 10.1.1 package, and adds dynamic_color
1.9.0. Other locked package versions are unchanged.

The October 26 Preview beta.10 review and its `flutter pub outdated --json`
inventory supplied context. This review freshly queried pub.dev metadata for
**all 60 hosted Pub locks**, checked available versions, retraction/discontinuation
status, and repeated **63 exact-version OSV queries**: those 60 packages plus
ONNX Runtime Android 1.24.3, AGP 9.1.0 and Kotlin Gradle plugin 2.4.20. All 63
responses completed without reported findings; no locked hosted package was
retracted or discontinued. A separate OSV query for the upstream version of
vendored Chessground 10.1.1 also returned no finding. Sources:
[pub.dev package API](https://pub.dev/api/packages/dartchess),
[OSV query API](https://google.github.io/osv.dev/api/).

This read-only preparation did **not** run a new dependency solver, resolve the
Stable Maven runtime graph, install tools, or build an APK. Fresh metadata checks
do not establish that every latest version fits the pinned Flutter SDK. The
exact-source Stable `dependencies` CI job must still resolve the release graph
and audit its Maven/Pub/Gradle/plugin/Python inventory. Repeat that job and the
manual upstream review on the frozen release source, as required by
[RELEASING.md](RELEASING.md#0-review-upstream-dependencies-and-security).

## Toolchain, native engines and models

| Component / proposed pin | Current upstream and decision |
| --- | --- |
| Flutter **3.47.8**, full revision `737ba8f885dc774b53b442759999a312c9461e4e`; Dart **3.13.7** | Retain. The official Flutter `stable` branch and `3.47.8` tag both resolve to this revision; the [Dart stable changelog](https://github.com/dart-lang/sdk/blob/stable/CHANGELOG.md) starts at 3.13.7. [GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp) names these patched stable versions for the compromised eMudhra intermediate-certificate issue. The public Flutter release API's historic prereleases are not a reliable latest-stable signal. |
| Gradle **9.8.1**, reviewed wrapper checksum | Retain the wrapper guard and checksum. [9.8.2 notes](https://docs.gradle.org/9.8.2/release-notes.html) say its new fix addresses a false virtual-platform warning; the security fixes were in 9.8.1. The three October advisories below are already patched. A warning fix does not justify changing the qualified toolchain during feature promotion. |
| AGP **9.1.0**, Kotlin plugin **2.4.20**, Java target **17** | [Google Maven metadata](https://dl.google.com/dl/android/maven2/com/android/tools/build/gradle/maven-metadata.xml) offers stable AGP 9.4.1; [Kotlin 2.4.21](https://github.com/JetBrains/kotlin/releases/tag/v2.4.21) is available. Defer coordinated compatibility updates. AGP 9.5 RC/9.6 alpha and Kotlin 2.5 beta are not promotion candidates. Retain the existing SDK/NDK/JDK/build-tools recipe; verify actual provenance during later release qualification. [Platform-tools notes](https://developer.android.com/tools/releases/platform-tools) currently list 37.0.1; this is host tooling, not the APK build-tools pin. |
| ONNX Runtime Android **1.24.3** | **1.31.1** was published October 26 at 19:29 UTC and is in [Maven Central metadata](https://repo.maven.apache.org/maven2/com/microsoft/onnxruntime/onnxruntime-android/maven-metadata.xml). Its [patch notes](https://github.com/microsoft/onnxruntime/releases/tag/v1.31.1) address an OpenVINO/Python build regression and WASM Debug tests, with no required Android change identified. Defer the larger jump from 1.24.3. [1.31.0 notes](https://github.com/microsoft/onnxruntime/releases/tag/v1.31.0) describe model/package APIs, kernel/runtime changes and native telemetry defaults: require Android AAR privacy applicability, ABI, 79M numerical output, memory and speed checks before upgrading. |
| Stockfish **19 Light**, multistockfish **0.6.1**, multistockfish_light **0.1.0** | Retain the stable engine, wrapper and NNUE guards. [Stockfish releases](https://github.com/official-stockfish/Stockfish/releases) still identify `sf_19` as the latest stable engine; October 25's `ff3a6c50` snapshot is a prerelease. [Wrapper changelog](https://pub.dev/packages/multistockfish/changelog) and fresh package metadata show no newer stable wrapper requirement. |
| Maia3 source **`1e13597c42d4858b7cfd7cfdae01e297263364b2`** | [CSSLab upstream HEAD](https://github.com/CSSLab/maia3/commit/1e13597c42d4858b7cfd7cfdae01e297263364b2) remains unchanged, with no published release or public advisory. Fresh [79M repository metadata](https://huggingface.co/api/models/UofTCSSLab/Maia3-79M?blobs=true) still identifies revision `a107d6ceb7b298cb04ae1da4edffe2939858b894` and checkpoint SHA-256 `3fc6181d5db789b45a15305732148757ae74efa3e0028e81ba335b462dac45c2`. Retain the conversion and [model provenance](../MODEL_PROVENANCE.md). Stable 79M ONNX SHA-256 remains `3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`; Dev 5M remains `ddae2aa893b5ca7ec94d24178871f1c337d09fd72ff38abe8d76b8ecf08cb942`. Model metadata was read; model binaries were not downloaded or re-exported. |

The Flutter Linux/macOS/Windows release JSON URLs under
`storage.googleapis.com/flutter_infra_release/flutter/releases/` returned HTTP
404 during this review, including a repeat Linux request. The
[official archive](https://docs.flutter.dev/install/archive), official
[stable branch](https://github.com/flutter/flutter/tree/stable),
[3.47.8 tag](https://github.com/flutter/flutter/tree/3.47.8), Dart changelog and
security advisory provide the independent version/patch evidence above. The
endpoint failure is recorded, not treated as a successful JSON check.

## Chess, UI and other Pub updates

| Package / proposed lock | Latest reviewed / decision |
| --- | --- |
| Local Chessground **10.1.1** | [10.3.0](https://pub.dev/packages/chessground/changelog): removes Material dependency and updates dartchess; 10.2.0 adds CustomShape. Defer renderer/interaction migration. Preserve the byte-identical 10.1.1 renderer, source revision `0bd34fbe720097c4a51172e2c0d8f697637eda01`, explicit artwork allowlist, notices and source/APK hash guards in [PATCHES.md](../third_party/chessground/PATCHES.md). The path dependency is outside normal hosted-lock inventory coverage. |
| dartchess **0.13.1**; chess **0.8.1** | [dartchess 0.14.0](https://pub.dev/packages/dartchess/changelog) changes hashing/en-passant APIs; qualify game/position behavior separately. chess remains at the published 0.8.1 version. |
| dynamic_color **1.9.0** | [2.1.0](https://pub.dev/packages/dynamic_color/changelog): 2.x migrates to material_ui and adds Linux portal support. Keep the pinned Flutter Material implementation and qualify themes/platform fallbacks before migration. |
| crypto **3.0.7** | [3.0.8](https://pub.dev/packages/crypto/changelog) fixes HMAC chunk completion and improves hash performance. The app's inspected use is SHA-256 streaming/direct hashing, with no Hmac call. Retain pending focused hashing qualification; no exact-pin advisory found. |
| package_info_plus **10.2.1** | [10.2.2](https://pub.dev/packages/package_info_plus/changelog): Kotlin plugin application adjustment; defer with AGP/Kotlin qualification. |
| shared_preferences **2.5.5** / Android **2.4.27** / Foundation **2.5.6** | [2.5.6](https://pub.dev/packages/shared_preferences/changelog) / [2.5.3](https://pub.dev/packages/shared_preferences_android/changelog) / [2.6.0](https://pub.dev/packages/shared_preferences_foundation/changelog). Defer storage/backend churn. Android 2.5.x introduces the newer JNI backend; its later R8 fix does not imply the pre-JNI 2.4.27 lock needs that fix. Foundation's FFI migration is Apple-specific. |
| cupertino_icons **1.0.9** | [2.0.0](https://pub.dev/packages/cupertino_icons/changelog): major cupertino_ui migration; qualify fonts/icons separately. |
| vector_math **2.4.0** | **[2.4.4](https://pub.dev/packages/vector_math/changelog)** was published October 26 at 22:12 UTC. It fixes a newer-Dart analyzer error in TransformFilter; 2.4.1–2.4.3 document geometry APIs. Defer the SDK-owned dependency update. Fresh archive SHA-256 matched pub.dev metadata: `fa49e1674cb84acb900141714e6c6e1f9ae099827c24d141430ff6819db4e1bc` (182,469 bytes, read in memory). |

The fresh metadata comparison found **19 hosted-package updates**, the same set
as the prior review, with vector_math now at 2.4.4 instead of 2.4.3. The other
updates remain: clock 1.1.2→1.1.3, material_color_utilities 0.13.0→0.13.1,
meta 1.18.3→1.19.0, platform 3.1.6→3.2.0, process 5.0.5→5.0.6,
stack_trace 1.12.1→1.12.2, test_api 0.7.12→0.7.15, vm_service 15.3.0→15.4.0,
web 1.1.1→1.1.2 and webdriver 3.1.0→3.2.0. Retain the SDK/test graph: these
concern date precision, palette sanitization, annotations, platform/mocking APIs,
Windows paths, trace parsing, compiler/VM test APIs, web migrations and test-session
cleanup. No mandatory Android security upgrade was identified. Fresh exact-version
metadata SHA-256 values for all 19 previously inspected update archives still
match that review; the new vector_math archive was separately inspected above.
Unchanged direct pins include intl 0.20.3 and flutter_lints 6.0.0.

## Known advisories and remaining gates

The eMudhra advisory is addressed by the pinned patched SDK. Gradle 9.8.1 is
outside the affected ranges of
[GHSA-mvvg-497x-hmj8](https://github.com/gradle/gradle/security/advisories/GHSA-mvvg-497x-hmj8),
[GHSA-xwqc-3h47-hg64](https://github.com/gradle/gradle/security/advisories/GHSA-xwqc-3h47-hg64)
and
[GHSA-j5m7-59rp-24f5](https://github.com/gradle/gradle/security/advisories/GHSA-j5m7-59rp-24f5).
Fresh public advisory feeds for Flutter, Dart, Gradle, Kotlin, ONNX Runtime,
Stockfish, Maia3 and the Lichess Chessground/dartchess/multistockfish repositories
revealed no additional applicable finding. An empty public feed or OSV result is
not proof that native code, models, SDK internals or the complete build-tool graph
have no vulnerabilities. Known upstream advisories take precedence over a green
OSV result.

No dependency change or shared build/verification/cleanup helper change is
proposed by this review, so no new Preview tooling port applies. Stable and
Preview retain their own identities and release gates. Before any separately
authorized publication, require final-source Stable CI (including
`dependencies`), native/model/asset and upgrade checks, the canonical F-Droid
recipe review and independent Linux reproduction, and the remaining gates in
the authoritative release guide. Prior Preview APK or advisory evidence cannot
qualify the new Stable source. This review created no bulk toolchains, build
intermediates, model copies or emulator data requiring cleanup.


## Prepublication refresh — 2026-10-27

Fresh checks completed for 60 hosted Pub package metadata entries, 65 exact-pin
OSV queries (including vendored Chessground, Gradle and Android plugins/runtime)
and public upstream advisory feeds. No new applicable security blocker was found.
`shared_preferences_foundation` 2.6.1 was published after the initial review; its
changelog fixes web compilation for apps importing the Apple backend. Retain the
Android release pins. The final-source CI dependency job remains required.
Canonical F-Droid metadata at `06e1c87cd8ce671815c8fbbb40ee5498a66481d9`
contains successful 2.4.0/code81 as the last build. Request !53062 and pipeline
2959726434 passed; no open82 request or retained failed77/78 block was observed.
The public catalog still suggests81. These are prepublication observations;
publication/detection/build/catalog status will be recorded separately.
