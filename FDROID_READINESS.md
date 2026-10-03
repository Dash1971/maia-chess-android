# F-Droid readiness

For future releases, follow [docs/RELEASING.md](docs/RELEASING.md). The records
below describe the 2.2.2 preparation checkpoint; they are not live upstream
status. Final 2.2.2 qualification and publication evidence is on its GitHub release.

This is a status record, not a publication approval. The Preview package is not
part of the Stable submission. Updating this repository's review recipe does
not update F-Droid's canonical metadata or publish an app.

## Recovery release: 2.2.2 (versionCode 79)

**Status at source preparation: not built, qualified, tagged, signed, or
published.** Subsequent qualification and publication results belong in the
[GitHub release](https://github.com/Dash1971/maia-chess-android/releases/tag/v2.2.2),
so recording results does not move the qualified source commit.
This maintenance release puts the current Fastlane listing, screenshots, and
version-specific changelog into the release source before it is frozen. It
also aligns Play, both analysis controls, and Continue from here to the
600–2600 Maia rating range, including migration of saved 500 defaults. Engines,
model weights, and dependencies are unchanged. The final source must be rebuilt
and qualified after this rating fix; earlier metadata-only candidate results
do not qualify it. See the [release-source notes](docs/release-notes/v2.2.2.md).

F-Droid imports source-hosted descriptions and graphics from the latest release
it knows about, as described in its
[metadata documentation](https://f-droid.org/docs/All_About_Descriptions_Graphics_and_Screenshots/#in-the-applications-source-repository).
Adding missing notes to `main` after tagging does not repair the immutable
release tree. Keep `v2.2.0`, `v2.2.1`, and their published APKs unchanged.

## Public status checked on 2026-10-03

| Surface | Observed state |
| --- | --- |
| GitHub / Obtainium | [2.2.1 / 78 published](https://github.com/Dash1971/maia-chess-android/releases/tag/v2.2.1) |
| Official F-Droid | [2.1.3 / 76 published](https://f-droid.org/packages/com.dash1971.maia_chess/) |
| F-Droid update request | [MR !50992](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/50992) targets 2.2.0 / 77; its pipeline failed |
| This proposal | 2.2.2 / 79; all release qualification remains pending |

The [failed source-scan job](https://gitlab.com/fdroid/checkupdates-bot-fdroiddata/-/jobs/16910123099/raw)
reported the research ZIP at
`docs/research/maia3-sampling/assets/mobile-maia-5m-reproduction-asset.zip`.
It did not reach compilation or developer-APK comparison. The 2.2.1 source
removes that archive, but neither 2.2.0 nor 2.2.1 contains its matching Fastlane
changelog; those notes were added later on `main`.

A subsequent F-Droid update-bot run can refresh an existing bot-owned request.
A failed older request does not by itself prove a manual submission is needed.
Inspect the refreshed metadata and pipeline, including any retained older build
blocks, before deciding whether maintainer intervention is necessary. Neither a
local successful build nor an updated request means the package is published.

## Evidence for the existing 2.2.1 APK

The immutable release-source commit is
`05ce04e0e970ee12110b384c95e992508ce1a6b2`.
Its [GitHub Actions run](https://github.com/Dash1971/maia-chess-android/actions/runs/37097998530)
passed Flutter analysis, 529 Flutter tests, 28 Python verification tests, and
the Android build/packaging job.

The 2026-10-03 audit downloaded the published signed APK and that run's unsigned
artifact. Every ZIP payload matched. Removing the APK signing block and its
zero alignment padding and restoring the ZIP directory offset reproduced the
unsigned artifact byte-for-byte. Recorded SHA-256 values:

- Published signed APK:
  `138c791434106a188a3f9eed1afff1d517e518ce76b0f5d2945b313b8939defa`
- CI unsigned APK:
  `65e3e47596200d14b4868287759d4fdb518786d083ecf32c4131c1852b312c04`
- Allowed signing certificate:
  `cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e`

Package identity, version 2.2.1 / 78, the model hash, all three intended ABIs,
alignment, signature, and absence of the Internet permission also passed APK
inspection. This establishes the published APK's relationship to the CI
artifact; it does not independently establish F-Droid build reproducibility.

[PR #33](https://github.com/Dash1971/maia-chess-android/pull/33) reports a separate
successful local run of the bot-generated 78 recipe on the official buildserver,
including source/APK scans and developer-binary comparison. The recovery audit
did not independently rerun or inspect that run's underlying reports. Retain
and link its sanitized evidence before treating that report as verified. None
of the 2.2.1 evidence qualifies the proposed 2.2.2 binary.

## Reproducible inputs and release gates

The source pins Flutter 3.47.5, Java 17, locked dependencies, Stockfish 19 Light,
and the Maia-3 79M model. Model provenance, licensing, and export instructions
are in [MODEL_PROVENANCE.md](MODEL_PROVENANCE.md). The model SHA-256 is
`3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`.
Stockfish libraries compile from source with a hash-checked NNUE download.

Release builds use Linux. Matching NDK revision numbers on macOS and Linux do
not guarantee identical compiler output. The build also applies guarded
Flutter asset ordering and plugin-path fixes; Dart obfuscation stays disabled.
See [REPRODUCIBLE_BUILDS.md](REPRODUCIBLE_BUILDS.md).

Before 2.2.2 can be published:

1. Merge the release-source changes, freeze one full commit SHA, and run
   `python3 tool/check_release_source.py --ref <full-sha>` against it. Confirm
   the README, Fastlane listing, and release notes describe the shipped app.
2. Pass the host regression suite and Linux Android build at that exact SHA.
   Rebuild independently with the unmodified recipe the F-Droid bot would
   inherit from canonical fdroiddata, using the official buildserver. Require
   source/APK scans and reproducibility checks, retaining sanitized evidence.
3. Check the exact candidate APK and supported Stable upgrade paths using
   [RELEASE_CHECKS.md](tool/hardening/RELEASE_CHECKS.md). Existing-release evidence
   does not replace candidate checks, even when gameplay code is unchanged.
4. Only after qualification, create `v2.2.2` at that same SHA and sign the
   qualified Linux artifact without rebuilding. Verify the tag and actual
   public download, its version, hash, allowed signer, and rebuild comparison.
5. Check the refreshed F-Droid request and pipeline, then its merge and actual
   public package/index. Record those separately from GitHub publication.

The repository-local `fdroid/com.dash1971.maia_chess.yml` is a **review copy**.
Its proposed 79 block refers to the not-yet-created `v2.2.2` tag; pre-tag
qualification must select the frozen candidate SHA in temporary metadata while
preserving the canonical bot-inherited build instructions. Do not create a tag
just to make this review copy build. A local-only recipe correction must be
resolved with the canonical recipe before publication.
