# F-Droid readiness

This document records the reproducible inputs and publication status for Mobile
Maia on F-Droid. The Preview package is not part of the submission.

## Source and binary audit

- F-Droid's source scanner reports no problems when run against a clean
  checkout and a pinned Flutter 3.47.1 source library. The documented,
  AGPL-3.0-licensed Maia-3 ONNX model's provenance and reproducibility are
  documented in `MODEL_PROVENANCE.md`.
- Dependencies are resolved from `pubspec.lock` with
  `flutter pub get --enforce-lockfile`.
- The multistockfish Android libraries are compiled from bundled upstream C++
  source during the Gradle build; they are not opaque prebuilt libraries. The
  Stockfish 16 NNUE download must match its complete pinned SHA-256 before CMake
  can compile any ABI.
- The Maia-3 ONNX model's licence, source revisions, hashes, and byte-identical
  export procedure are documented in `MODEL_PROVENANCE.md`.
- F-Droid's APK scanner reports none of the six Google Play Core references
  retained by Flutter's unused deferred-component embedding in the unminified
  2.1.1 APK. Version 2.1.2 removes that unreachable bridge with R8 while
  retaining JNI, plugin, saved-game, and runtime behavior under explicit host,
  ARM64, x86_64, upgrade, and exact-APK gates.

## Clean build

Version 2.1.2 (`versionCode 75`) uses Flutter 3.47.1 and Java 17. The build
recipe replaces the Git LFS model pointer from the immutable release commit and
verifies SHA-256
`3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`
before compilation. The stable release remains a universal APK for ARMv7,
ARM64, and x86_64; its release verifier checks the exact ABI set and 16 KB ELF
alignment.

The immutable 2.1.2 release-source commit is
`ebe11cf1c2e973fa50eb99391181c29d2f545937`.

## Reproducibility status

Mobile Maia deliberately disables Dart release obfuscation. The 2.1.0 release
was reproducible across clean macOS builds, but its native output did not match
Linux. Investigation in GitHub PR #10 confirmed that NDK 28.2.13676358 contains
different macOS and Linux compiler builds even though the resolved NDK revision
is identical.

Version 2.1.1 corrected the release process rather than changing the NDK value.
Version 2.1.2 kept that process: its canonical unsigned APK was built on GitHub
Actions Linux and matched a clean independent Linux rebuild byte-for-byte
before signing. The exact Linux artifact was then signed locally without
rebuilding it, published, downloaded again, and verified against the audited
release artifact.

The source also backports deterministic sorting for Flutter 3.47.1's
resolution-aware asset discovery. Without that sort, identical dependency files
can produce a differently ordered `AssetManifest.bin` across filesystems.

The release uses F-Droid's developer-signed reproducible-build path with
`Binaries` and `AllowedAPKSigningKeys`. The allowed signing-certificate SHA-256
remains
`cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e`.

F-Droid published Mobile Maia 2.1.2 (`versionCode 75`) in its official
repository on 2026-09-22. The
[official package page](https://f-droid.org/packages/com.dash1971.maia_chess/)
and [repository APK](https://f-droid.org/repo/com.dash1971.maia_chess_75.apk)
are publicly available.

## Submission recipe

A review copy of the fdroiddata recipe is maintained at
`fdroid/com.dash1971.maia_chess.yml`. The canonical published copy is the
version merged into F-Droid's fdroiddata repository.
