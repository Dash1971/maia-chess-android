# Multilingual UI verification — 2026-10-04

Scope: PR #78 on `feature/japanese-dev`. This expands the Dev translation slice to 296 messages in each of English, Japanese, Simplified Chinese, Korean and Spanish. It is a UI localization change, not an engine/model upgrade or a release qualification.

## Automated checks

- Pinned Flutter 3.47.5: `flutter analyze --no-pub` passes with no issues.
- Full `flutter test --no-pub --reporter expanded`: **614 tests pass**, approximately 47 seconds on the review Mac. The earlier editorial PR had 575 tests; this expansion adds 39 more covering play, analysis, storage and async language preferences.
- Python release/tool suite: **40 tests pass**, including nine localization-guard tests. The guard suite is lightweight and adds no Android build to ordinary PR CI.
- `flutter gen-l10n` and `python3 tool/check_localization.py`: all five catalogs agree on 296 IDs, every placeholder is retained, and the review CSV matches the ARBs. Generated Dart and lockfile drift are checked in CI.
- Final ARM64 Dev debug APK compiles successfully, including the Kotlin PGN share-title change. Existing pinned SDK/JDK/Gradle and both hash-verified model assets were used; release signing credentials were not needed.

Commands for reproduction are in [the localization guide](L10N_REVIEW.md). CI runs the same analyzer, Flutter tests and Python tool checks. The full suite includes existing game, clock, engine/classification, variation, storage and simulated electronic-board regressions.

## Bugs caught and corrected during the pass

- Malformed, failed or racing language-preference reads/writes could throw or lose the user's latest selection. Writes are serialized; invalid values are removed in isolation; errors have a localized recovery message.
- English lookup strings and saved presentation text could silently retain English. UI call sites now use generated IDs and render stable status codes in the active locale, preserving legacy saved-game compatibility.
- Result and About dialogs could retain text from the language in which they opened. They now rebuild translated content on a locale change.
- Locale number formatting initially grouped Elo values. Ratings and move numbers now stay ungrouped; Spanish decimals and clock fractions use commas without changing stored engine/clock values.
- New date formatting initially depended on locale symbols unavailable in standalone test/embedded pages. Recent Games uses Material's locale-aware compact-date formatter.
- The Spanish board editor overflowed at 200% text. Piece-color and reset/clear controls wrap; the page scrolls. The diagnostic recovery screen also scrolls safely.
- Temperature help described tactical risk rather than probability concentration. All five catalogs now explain its actual effect, and Top-P help specifies sorting moves by probability before accumulating the threshold.

## Android visual checks

Used the existing API 36 ARM64 emulator at 1080×2400, 420 dpi. Installed an isolated temporary debug package with a test-only suffix so existing Preview/Dev apps and their game data were not replaced. The suffix change is not committed.

- Switched among all four translations through the actual language menu; checked Home and Settings with Android's real fonts. Japanese, Chinese and Korean glyphs rendered; buttons and labels remained usable.
- Opened Spanish analysis with native Stockfish and Maia running: localized evaluation decimals, move-probability labels, menus and navigation semantics were present; SAN remained canonical.
- Opened the Spanish board editor at system font scale 2.0, scrolled to the final controls, and checked the wrapped controls visually.
- Force-stopped/reopened the isolated app; its Spanish selection and analysis session restored.
- No Flutter error or Android runtime-crash log entries were observed during this smoke pass.

The [Home/Settings contact sheet](images/localization-home-settings.jpg) is from a fresh test app with no personal game data. The final small navigation wording and About refresh adjustments were covered by the final host tests and rebuilt APK. These screenshots are visual evidence for the sampled screens, not proof of every translated layout or a performance benchmark.

## Release acceptance still needed

Native-speaking chess players should review wording in context using [the synchronized review sheet](l10n_review.csv). Physical-device TalkBack and layout checks remain useful. This work does not claim native-speaker certification, physical Chessnut testing, a signed release, or universal-ABI/reproducibility qualification. Opening-dataset names, notation, protocols, diagnostic logs and original license text deliberately remain canonical as documented in the localization guide.

The temporary test installation and emulator session were removed/stopped after review. Downloaded model working copies were restored to their tracked LFS pointers, and temporary build output was removed. Shared SDK, Gradle caches and other applications were preserved.
