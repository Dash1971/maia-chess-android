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

Version 2.1.1 (`versionCode 74`) uses Flutter 3.47.1 and Java 17. The build
recipe replaces the Git LFS model pointer from the immutable release commit and
verifies SHA-256
`3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`
before compilation. The stable release remains a universal APK for ARMv7,
ARM64, and x86_64; its release verifier checks the exact ABI set and 16 KB ELF
alignment.

The immutable 2.1.1 release-source commit is
`a638f5c7552eebe69fed986f832520493ac8a16c`.

## Reproducibility status

Mobile Maia deliberately disables Dart release obfuscation. The 2.1.0 release
was reproducible across clean macOS builds, but its native output did not match
Linux. Investigation in GitHub PR #10 confirmed that NDK 28.2.13676358 contains
different macOS and Linux compiler builds even though the resolved NDK revision
is identical.

Version 2.1.1 corrects the release process rather than changing the NDK value.
Its canonical unsigned APK must be built on GitHub Actions Linux and match a
clean independent Linux rebuild byte-for-byte before signing. The exact Linux
artifact is then signed locally without rebuilding it. Build, independent
comparison, signing, publication, and public-download verification remain
pending until this preparation change is reviewed and merged.

The source also backports deterministic sorting for Flutter 3.47.1's
resolution-aware asset discovery. Without that sort, identical dependency files
can produce a differently ordered `AssetManifest.bin` across filesystems.

After those checks pass, the release will support F-Droid's developer-signed
reproducible-build path using `Binaries` and `AllowedAPKSigningKeys`. The allowed
signing-certificate SHA-256 remains
`cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e`.

## Submission recipe

A review copy of the proposed fdroiddata recipe is maintained at
`fdroid/com.dash1971.maia_chess.yml`. The canonical copy for publication will
be the version reviewed and merged into F-Droid's fdroiddata repository.
