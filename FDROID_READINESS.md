# F-Droid readiness

This document records the reproducible inputs and remaining work for submitting
Mobile Maia to F-Droid. The Preview package is not part of the submission.

## Source and binary audit

- F-Droid's source scanner reports no problems when run against a clean
  checkout and a pinned Flutter 3.47.1 source library. The documented,
  AGPL-3.0-licensed Maia-3 ONNX model is explicitly listed in `scanignore`
  because it is a large binary model; its provenance and reproducibility are
  documented in `MODEL_PROVENANCE.md`.
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

Version 1.8.1 (`versionCode 46`) builds from commit
`15fe52d77ba69475b77f5f324953d211ba2dc448` using Flutter 3.47.1 and Java 17.
The build recipe replaces the Git LFS model pointer from an immutable commit
URL and verifies SHA-256
`3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`
before compilation.

## Reproducibility status

Version 1.8.1 deliberately disables Dart release obfuscation. Two independent
clean unsigned builds were byte-for-byte identical. Copying the signature from
the developer-signed release onto an independent unsigned build reconstructed
the published APK byte-for-byte.

The release therefore supports F-Droid's developer-signed reproducible-build
path using `Binaries` and `AllowedAPKSigningKeys`. The published APK SHA-256 is
`3b00cfa593c20fe0bd8ba2b2968c512c68d07ded51ec0d88cdd3cdddf0b8541c` and
the allowed signing-certificate SHA-256 is
`cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e`.

## Submission recipe

A review copy of the proposed fdroiddata recipe is maintained at
`fdroid/com.dash1971.maia_chess.yml`. The canonical copy for publication will
be the version reviewed and merged into F-Droid's fdroiddata repository.
