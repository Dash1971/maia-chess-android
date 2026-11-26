# Stable 2.6 dependency review — 26 November 2026

Preview testing is complete and Stable publication is authorized. This review
precedes source freeze; it does not substitute for exact-source CI or qualification.

## SDK, build tools and native components

| Component | Retained pin / decision |
| --- | --- |
| Flutter / Dart | 3.47.8 / 3.13.7. The current Dart TLS advisory affects earlier versions; existing pins include the fix. Retain the guarded reproducibility backport. |
| Gradle | 9.9.2; official distribution checksum matches. The reviewed November advisory ranges end at 9.9.1 or earlier. |
| AGP / Kotlin | 9.1.0 / 2.4.20. AGP notes and Kotlin release/advisory feeds reviewed. Do not adopt the new 2.5.0 release candidate during this promotion. |
| ONNX Runtime Android | CPU 1.24.3. Maven lists 1.32.0; defer a native runtime change to separate numerical, compatibility and reproduction qualification. |
| Stockfish / Maia | Stockfish 19 Light and the pinned Maia-3 79M model. Retain the tested numerical/inference behavior and model hash. |

63 exact-version OSV queries covering hosted Pub locks and the direct ONNX/AGP/
Kotlin coordinates returned no findings. Exact-source Stable CI separately
audits the complete resolved Maven graph, Gradle and release-test requirements.
This is not a source audit or proof of no native vulnerabilities.

ONNX GitHub release/advisory endpoints returned 404. Its official servicing
page, Android Maven metadata and exact-version OSV response were checked instead.
The missing GitHub coverage is not reported as clear. The Flutter storage release
index also returned 404; the official stable changelog and SDK security advisory
ranges were reviewed. No unavailable endpoint was treated as a passing feed.

## Available Pub updates

Fresh metadata and SHA-256-verified update archives match the same 23 versions
reviewed for Preview beta.13. Retain the lockfile during promotion; reasons follow.

| Package | Locked → available | Decision |
| --- | --- | --- |
| clock | 1.1.2 → 1.1.3 | Relative-date microsecond preservation; retain SDK-compatible lock. |
| crypto | 3.0.7 → 3.0.8 | HMAC addSlice-final digest fix and hashing speedups. App uses SHA256 streaming, not Hmac; current OSV is clear. Qualify hash-library update separately. |
| cupertino_icons | 1.0.9 → 2.0.0 | Major cupertino_ui migration requires icon/font compatibility qualification. |
| dartchess | 0.13.1 → 0.15.0 | 0.15 changes PGN embedded-command parsing/storage and 0.14 adds en-passant/Zobrist APIs; defer to separate chess/PGN migration qualification. |
| dynamic_color | 1.9.0 → 2.1.0 | 2.x material_ui migration and Linux portal support require theme/platform fallback qualification. |
| material_color_utilities | 0.13.0 → 0.13.1 | Hue sanitization/docs change; qualify palettes/readability together. |
| meta | 1.18.3 → 1.19.0 | Annotation stabilization only; retain SDK-pinned graph. |
| multistockfish | 0.6.1 → 0.7.0 | Native-thread/FFI and engine lifecycle migration with breaking APIs. Keep pinned0.6.1 and compatible native flavors for current cancellation scopes and reproducible NNUE verification; qualify threading/ABI and cache-patch support separately. No current advisory requires this migration for the Dart storage/lifecycle fixes. |
| multistockfish_chess | 0.6.0 → 0.7.0 | Native-thread/FFI and engine lifecycle migration with breaking APIs. Keep pinned0.6.1 and compatible native flavors for current cancellation scopes and reproducible NNUE verification; qualify threading/ABI and cache-patch support separately. No current advisory requires this migration for the Dart storage/lifecycle fixes. |
| multistockfish_light | 0.1.0 → 0.2.0 | Native-thread/FFI and engine lifecycle migration with breaking APIs. Keep pinned0.6.1 and compatible native flavors for current cancellation scopes and reproducible NNUE verification; qualify threading/ABI and cache-patch support separately. No current advisory requires this migration for the Dart storage/lifecycle fixes. |
| multistockfish_variant | 0.4.0 → 0.5.0 | Native-thread/FFI and engine lifecycle migration with breaking APIs. Keep pinned0.6.1 and compatible native flavors for current cancellation scopes and reproducible NNUE verification; qualify threading/ABI and cache-patch support separately. No current advisory requires this migration for the Dart storage/lifecycle fixes. |
| package_info_plus | 10.2.1 → 10.2.2 | Kotlin plugin application change; defer coordinated AGP/Kotlin compatibility update. |
| platform | 3.1.6 → 3.2.0 | New non-backwards-compatible platform/mocking API; defer owner dependency migration. |
| process | 5.0.5 → 5.0.6 | Windows executable-path fix/example update; no relevant Android security fix. |
| shared_preferences | 2.5.5 → 2.5.6 | Return-value docs/minimum SDK update; retain tested storage graph. |
| shared_preferences_android | 2.4.27 → 2.5.5 | 2.5 migrates to Pigeon JNI with subsequent R8/startup fixes. Retain the tested 2.4 Kotlin backend and saved-preference continuity; evaluate JNI migration separately. No current OSV advisory. |
| shared_preferences_foundation | 2.5.6 → 2.6.2 | Pigeon FFI/multi-engine migration on Apple platforms; Android-only release uses the unchanged Android backend. |
| stack_trace | 1.12.1 → 1.12.2 | V8 trace parsing change; retain SDK/test-compatible diagnostics graph. |
| test_api | 0.7.12 → 0.7.15 | New native compiler/runtime/backend exports; retain Flutter-pinned test graph. |
| vector_math | 2.4.0 → 2.4.4 | Newer-SDK analyzer adjustment and API documentation; retain the pinned Flutter-compatible framework lock. |
| vm_service | 15.3.0 → 15.4.0 | VM protocol/FFI metadata and null-RPC response fix; retain SDK/test service graph. |
| web | 1.1.1 → 1.1.2 | Dart-fix migration corrections; no Android runtime fix. |
| webdriver | 3.1.0 → 3.2.0 | Failed-session HTTP cleanup and typed-byte API; defer owning development-test graph migration. |

## Primary references

- [Flutter stable changelog](https://raw.githubusercontent.com/flutter/flutter/stable/CHANGELOG.md) and [Dart advisories](https://github.com/dart-lang/sdk/security/advisories).
- [Gradle advisories](https://github.com/gradle/gradle/security/advisories) and [9.9.2 notes](https://docs.gradle.org/9.9.2/release-notes.html).
- [AGP 9.1 notes](https://developer.android.com/build/releases/past-releases/agp-9-1-0-release-notes) and [Kotlin releases](https://github.com/JetBrains/kotlin/releases).
- [ONNX servicing](https://onnxruntime.ai/docs/reference/releases-servicing.html) and [Android Maven metadata](https://repo.maven.apache.org/maven2/com/microsoft/onnxruntime/onnxruntime-android/maven-metadata.xml).
- [Stockfish releases](https://github.com/official-stockfish/Stockfish/releases), [Maia source](https://github.com/CSSLab/maia3), [Pub package metadata](https://pub.dev/help/api) and [OSV](https://api.osv.dev/v1/querybatch).

Compact query/source hashes and per-package decisions are retained with release
evidence. No model, app dependency or toolchain pin changes in this promotion.
