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

## Verification

Two clean unsigned builds from the same revision must have identical SHA-256
hashes. To verify a developer-signed APK, use
[`apksigcopier`](https://github.com/obfusk/apksigcopier) to extract its
signature, apply that signature to the independently built unsigned APK, and
compare the reconstructed APK byte-for-byte with the published APK.
