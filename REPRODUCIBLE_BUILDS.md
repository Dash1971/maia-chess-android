# Reproducible Android builds

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

Flutter 3.47.1 does not forward its filesystem-root settings through the
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

Android NDK packages with the same revision contain host-specific compiler
builds. In particular, NDK 28.2.13676358 produces different native output on
macOS and Linux. Starting with version 2.1.1, the canonical unsigned release APK
is therefore built on Linux by the manually dispatched GitHub Actions Android
job. A separate Linux host must rebuild the same source commit and produce the
same APK SHA-256 before signing. The developer signing key remains offline: the
verified Linux artifact is downloaded and signed without rebuilding it.

Flutter 3.47.1 discovers resolution-aware asset directories with an unsorted
filesystem listing. That can serialize identical image variants in a different
order in `AssetManifest.bin`. The release script applies a narrowly guarded
backport to the pinned Flutter checkout before building: it sorts the discovered
variant paths and refuses any unexpected Flutter revision or source shape.

## Verification

For version `2.1.1` and later, the GitHub Actions build and a clean independent
Linux build from the same revision must have identical SHA-256 hashes. The
workflow requires the expected full source SHA, refuses a checkout mismatch,
and retains the APK hash plus source, runner, Flutter, Java, NDK, and Clang
provenance. To verify a developer-signed APK, use
[`apksigcopier`](https://github.com/obfusk/apksigcopier) to extract its
signature, apply that signature to the independently built unsigned APK, and
compare the reconstructed APK byte-for-byte with the published APK.
