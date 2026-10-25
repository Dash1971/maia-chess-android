# Reproducible Android builds

For the required publication sequence and combined qualification gate, start
with [the release procedure](docs/RELEASING.md). This document explains build
mechanics; a reproducible build alone is not publication approval.

Mobile Maia's Android release build is reproducible when the same source
revision, Flutter SDK, Java runtime, Android SDK, host operating-system family,
and locked Dart dependencies are used.

Build with:

```sh
FLUTTER_BIN=/path/to/flutter tool/build_android_release.sh
```

Official releases additionally provide the three signing environment
variables documented by `android/app/build.gradle.kts`. When those variables
are absent, the same command produces the unsigned APK required for independent
verification.

Release builds intentionally do not use Dart obfuscation. Obfuscation provides
no useful source secrecy for this AGPL-licensed application, makes crash traces
less useful, and uses randomized symbol mappings that prevent independent
builds from matching.

Flutter 3.47.5 does not forward its filesystem-root settings through the
Android Gradle task. The release script therefore adds the generated Dart
plugin registrant to the generated package configuration under the stable URI
`package:mobile_maia_generated/dart_plugin_registrant.dart`. This prevents an
absolute checkout path from being embedded in `libapp.so` and allows builds
made from different directories to match. The tracked dependency lockfile is
unchanged; only the generated `.dart_tool/package_config.json` is adjusted.
Flutter's release configuration pass runs first so test-only native plugins
are still excluded from the generated Android registrant.

The Android build disables linker build IDs for the three bundled Stockfish
libraries because the NDK otherwise gives byte-identical native code different
20-byte IDs. The release commit timestamp is also passed into their CMake task
inputs, preventing a stale native cache from retaining an older `__DATE__`
value.

The pinned `multistockfish_light` package downloads the Stockfish 19 Light NNUE
network during CMake configuration. Before every release build, Mobile Maia
applies a narrowly guarded patch to that exact package version and source line.
CMake must verify SHA-256
`61e7af4bb97d51eeeb25d322916f86513b5cd3a827ce189c98c6e31946f99e5b`
and fail the build if the download is incomplete or different. This prevents a
partial network response from being embedded into only one ABI's native
library.

Android NDK packages with the same revision contain host-specific compiler
builds. In particular, NDK 28.2.13676358 produces different native output on
macOS and Linux. Starting with Stable version 2.1.1, the canonical
unsigned release APK is therefore built on Linux by the manually dispatched
GitHub Actions Android job. A separate Linux host must rebuild the same source
commit and produce the same APK SHA-256 before signing. The developer signing
key remains offline: the verified Linux artifact is downloaded and signed
without rebuilding it.

Flutter 3.47.5 discovers resolution-aware asset directories with an unsorted
filesystem listing. That can serialize identical image variants in a different
order in `AssetManifest.bin`. The release script applies a narrowly guarded
backport to the pinned Flutter checkout before building: it sorts the discovered
variant paths, invalidates any previously compiled Flutter tool snapshot, and
refuses any unexpected Flutter revision or source shape.

## Verification

Follow [build storage and cleanup](docs/BUILD_WORKSPACE.md) on every build,
signing and test host. The build wrappers run a disk preflight on Mac and Linux.
Keep artifacts until the published download is verified, then clean task-owned
intermediates and bulk output while
retaining compact evidence. Cleanup is required before release-task completion.

For Stable version `2.1.1` and later, the GitHub Actions build and a
clean independent Linux build from the same revision must have identical
SHA-256 hashes. The workflow requires the expected full source SHA, refuses a
checkout mismatch, and retains the APK hash plus source, runner, Flutter, Java,
NDK, and Clang provenance. To verify a developer-signed APK, use
[`apksigcopier`](https://github.com/obfusk/apksigcopier) to extract its
signature, apply that signature to the independently built unsigned APK, and
compare the reconstructed APK byte-for-byte with the published APK.

## Gradle security pin

The wrapper uses Gradle **9.8.1** and verifies the official distribution SHA-256.
CI and the local release script run `python3 tool/verify_gradle_wrapper.py`
before using Gradle. This offline check prevents an accidental rollback to the
vulnerable 9.3.1 pin even when advisory indexes have not caught up. When changing
Gradle, update the wrapper and the reviewed version/checksum in that check
only after upstream security and build compatibility review.

Gradle 9.8.1 fixes GHSA-mvvg-497x-hmj8, GHSA-xwqc-3h47-hg64 and
GHSA-j5m7-59rp-24f5. See the
[upstream release notes](https://docs.gradle.org/9.8.1/release-notes.html).
This update retains Flutter 3.47.5, AGP 9.1.0, Kotlin 2.4.20 and Java 17;
no app dependency, engine, model or version is changed. Final-release
qualification must still use its exact source commit.

The current canonical F-Droid recipe invokes Flutter, which uses the source
repository's Gradle wrapper. It does not pin Gradle 9.3.1 independently, so this
wrapper update does not require changing the inherited recipe. Verify that
assumption again against live canonical metadata at publication; do not replace
historical release tags or change already-published artifacts.

## Flutter 3.47.8 security pin — 2026-10-25

Current builds use Flutter **3.47.8**, full revision `737ba8f885dc774b53b442759999a312c9461e4e`, with Dart **3.13.7**, to address [GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp). Earlier sections document the original 3.47.5 backport. Review of 3.47.8 confirms that the guarded asset-variant sorting backport and stable package-URI workaround are still required. The revision/source-shape guards remain strict and the old vulnerable SDK revision is rejected. Independent Linux equality and signature reconstruction remain required for releases; this pin update does not waive any qualification gate or authorize another channel’s publication.
