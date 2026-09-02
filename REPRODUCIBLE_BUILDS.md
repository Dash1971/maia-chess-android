# Reproducible Android builds

Mobile Maia's Android release build is reproducible when the same source
revision, Flutter SDK, Java runtime, Android SDK, and locked Dart dependencies
are used.

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

## Verification

For version `1.8.1`, two clean unsigned builds from the same revision
must have identical SHA-256 hashes. To verify a developer-signed APK, use
[`apksigcopier`](https://github.com/obfusk/apksigcopier) to extract its
signature, apply that signature to the independently built unsigned APK, and
compare the reconstructed APK byte-for-byte with the published APK.
