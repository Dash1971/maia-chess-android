# F-Droid readiness

This document records the reproducible inputs and remaining work for submitting
Mobile Maia to F-Droid. The Preview package is not part of the submission.

## Source and binary audit

- F-Droid's source scanner reports no problems for version code 38 when run
  against a clean checkout and a pinned Flutter 3.47.1 source library.
- Dependencies are resolved from `pubspec.lock` with
  `flutter pub get --enforce-lockfile`.
- The multistockfish Android libraries are compiled from bundled upstream C++
  source during the Gradle build; they are not opaque prebuilt libraries.
- The Maia-3 ONNX model's licence, source revisions, hashes, and byte-identical
  export procedure are documented in `MODEL_PROVENANCE.md`.
- F-Droid's APK scanner reports no non-free classes. It identifies the Gradle
  dependency-information entry in the APK signing block, which is not an app
  dependency or executable payload.

## Clean build

Version 1.7.2 (`versionCode 38`) builds from commit
`1645db478774ef04bb0a23e4f7f3efde638d8608` using Flutter 3.47.1 and Java 17.
The build recipe replaces the Git LFS model pointer from an immutable commit
URL and verifies SHA-256
`3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`
before compilation.

## Reproducibility status

The clean unsigned build and the developer-signed v1.7.2 APK contain the same
2,228 non-signature ZIP entries, but 12 native libraries differ:

- The three architecture-specific `libapp.so` files differ materially. The
  release uses Dart obfuscation, whose generated symbols are not reproducible
  across independent builds.
- The nine multistockfish libraries have identical sizes and differ only in
  their 20-byte linker build IDs.

Consequently v1.7.2 is suitable for a normal F-Droid build signed by F-Droid,
but it cannot yet use F-Droid's developer-signed reproducible-build path.
A future release must make the Dart and native linker outputs deterministic,
then be rebuilt and compared before adding `Binaries` and
`AllowedAPKSigningKeys` to the fdroiddata recipe.
