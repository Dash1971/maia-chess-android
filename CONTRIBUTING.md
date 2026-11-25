# Contributing to Mobile Maia

Bug reports, documentation, translations and code contributions are welcome.
Report a bug in the repository for the channel you are using. Search existing
issues first; link an existing shared board discussion rather than creating a
second hardware history. Maintainers can cross-link reports affecting both.

Substantial features are discussed and tested in
[Preview](https://github.com/Dash1971/maia-chess-android-preview/issues) before
Stable promotion. This does not prevent focused fixes to Stable. Security issues
use [private reporting](SECURITY.md), not public bug reports.

## Set up and run

Use the Flutter version/revision in the checked-out `.fvmrc` and CI, JDK 17,
Android SDK 36, Python 3 and Git LFS. Reuse existing SDKs/caches. Before model
downloads or Android builds, follow [workspace and disk preflight](docs/BUILD_WORKSPACE.md).

```sh
GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/Dash1971/maia-chess-android.git
cd maia-chess-android
git lfs install
git lfs pull
flutter pub get --enforce-lockfile
```

A source ZIP contains LFS pointers, not usable model weights. Model checks and
provenance are documented in [MODEL_PROVENANCE.md](MODEL_PROVENANCE.md).

For a connected, authorized Android device, `flutter devices` followed by
`flutter run -d <device-id>` starts a debug build. Prefer the separate
[Preview Dev workflow](https://github.com/Dash1971/maia-chess-android-preview/blob/main/CONTRIBUTING.md)
for feature work so it does not overwrite a usual installation. Export important
games before using a development build with the same Android package.

## Checks

```sh
flutter gen-l10n
python3 tool/check_localization.py
python3 tool/check_lichess_terminology.py
flutter analyze
flutter test --reporter expanded
```

CI additionally checks generated localization drift, native policies and release
verification tools. Use [the testing guide](tool/hardening/README.md) and the
[shared operator setup](docs/RELEASE_TEST_SETUP.md) for those Python/native tests.
A debug run is not a release. APK publication follows this channel's
[release procedure](docs/RELEASING.md), including all reproduction and signing gates.

## Translations and pull requests

Edit language ARBs, not generated Dart. Follow [localization review](docs/l10n/L10N_REVIEW.md),
[native chess-player review](docs/l10n/NATIVE_REVIEW.md) and the pinned Lichess terminology.
Keep placeholders and ICU syntax; test changed layouts and request native review.

Before opening a PR:

- Explain the problem and resulting behavior; link the issue and changed docs.
- Run relevant checks and state their results and remaining hardware limits.
- Preserve offline behavior, games/preferences and channel identities.
- Assess a companion in the other repository for shared build/test/cleanup work.
- Keep keys, private photos, local paths, models and bulk output out of the PR.

Contributions use the [project licence](LICENSE). See [the docs index](docs/README.md)
for feature, architecture, release and historical references.
