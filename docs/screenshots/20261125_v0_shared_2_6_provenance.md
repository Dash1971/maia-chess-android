# Shared 2.6 screenshots — 25 November 2026

These are unmodified Android screencaps from the **published Preview beta.13 APK**,
used for shared UI in the unmerged Stable 2.6 candidate. They are not captures
from a Stable 2.6 APK and do not qualify the Stable APK. No builds, Actions or LFS
downloads were used. Home/About are excluded because they visibly say Preview.

- Source/tag: `f1b3c4fa94b2e8aef7aa75a0143ea43406f6495d` / `v2.6.0-beta.13`.
- Package/version: `com.dash1971.maia_chess.preview`, `2.6.0-beta.13` / `2613`.
- [Public APK](https://github.com/Dash1971/maia-chess-android-preview/releases/download/v2.6.0-beta.13/Mobile-Maia-Preview-v2.6.0-beta.13.apk), 455584808 bytes.
- APK SHA-256: `6a62899a6829a0523ca93be4e2feac4ef24b3274bcb9dddd19dd90a9063c53ee`.
- Android 35 AOSP x86_64 task emulator, 720×1560, 280 dpi, default dark theme,
  English, 2 CPUs / 2 GiB. Final graphics backend: SwiftShader, Vulkan disabled.
  Launch supplied `--ez enable-impeller false` as an emulator rendering workaround;
  the installed APK and app source were not modified.
- Fourteen controlled saved-game fixture records exercise both player sides,
  multiple ratings, wins/losses/draws/incomplete games and dates. They are demo
  data seeded in the disposable app-private store, not actual played games or
  personal history. PGNs use legal short opening lines. They are screenshot
  fixtures, not hardware/engine acceptance evidence. Initial generic imported
  fixtures lacked player-side metadata and showed neutral results; those images
  were rejected. Final fixtures carry native player-side/rating metadata.
- Analysis export shows the normal initial position with actual live engine
  lines. Export menus show the default checked Include analysis control; no
  Android picker/share sheet was opened for these captures.
- Every selected image was decoded and visually inspected: no Preview/Dev
  branding, debug overlay, toast, loading state, private data or edited pixels.
  UI snapshots confirmed the checkbox is checked and the normal Win/Loss/Draw/
  Incomplete semantics. Shared screen code matches the promoted feature source;
  Stable branding, package, blue launcher and release configuration are retained.

## Images

| File | SHA-256 |
| --- | --- |
| [20261125_v0_shared_2_6_recent_games.png](20261125_v0_shared_2_6_recent_games.png) | `53be89da746707fa6d7d99e8bd2b6c1327b95549c5cbb30264de9b2cb841e423` |
| [20261125_v0_shared_2_6_recent_import.png](20261125_v0_shared_2_6_recent_import.png) | `6a6134f21273a59cc620d6a4231b5f1285be048727c8283612c6465326702406` |
| [20261125_v0_shared_2_6_recent_export.png](20261125_v0_shared_2_6_recent_export.png) | `70b9e13e265b943e55e29ef6e7a8c3b68e63043e8883ecdf3592227a1577ad5c` |
| [20261125_v0_shared_2_6_analysis_export.png](20261125_v0_shared_2_6_analysis_export.png) | `9fd435b7491f5dbf8bd082934e206a23a803914dc589a11e9618ec2cd2c3900d` |

## README, guide and store use

The detailed guide uses all four images. The store gallery replaces only images
3, 4 and 8 with Recent games, collection export and Analysis export respectively.
The other five store images remain the recorded Stable 2.5 examples: Home,
Analysis Board, board selector, piece selector and editor. Their provenance is
[retained separately](20261027_v1_stable_2_5_provenance.md); this refresh does not
claim they are new 2.6 captures. The README links to the guide instead of repeating
its screenshot gallery. No Home shortcut or broad UI redesign is added.

The earlier screenshot-emulator attempts stalled; one Android system process
failure was observed. Switching to the bounded lower-resolution software setup
produced the final captures. This is capture-host evidence, not a diagnosed app
bug or a release-test pass. Task APK/AVD copies and processes are removed after
retaining images and compact evidence; shared tools and other work are preserved.
