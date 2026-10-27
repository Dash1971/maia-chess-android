# Stable 2.5 screenshot provenance

Captured 27 October 2026 from the actual Stable Android app. These images refresh
the README and eight English Fastlane phone screenshots before source freeze.

- App source: `b8afa6873dfdfb48f089058c8fadb201b9cb9a9b`. The subsequent refresh changes documentation and images only.
- Package: `com.dash1971.maia_chess`; About shows `2.5.0`.
- Artifact: local Flutter debug APK, SHA-256 `feab2ff00a974de736cb330cc024bfe271c87142743680a5cb93c9da2400fb44`. This records screenshot provenance, not signed-release qualification.
- Device: task-owned Android 16 ARM64 emulator `maia-stable250` (`emulator-5554`), 900×1920 px, density 350, font scale 1.0.
- Capture: ADB `screencap -p`, unaltered pixels. Every image was opened and visually inspected.
- Home, appearance and board controls show new-install defaults unless the caption says otherwise. Optional Maia 2600 and score display are enabled in analysis examples; both are off by default.
- Analysis, editor and continuation use controlled PGN `1. e4 e5 2. Nf3 Nc6 3. Bb5 a6`, selected after `2. Nf3`. Engine output comes from the real bundled Maia 79M and Stockfish.
- Light and pure-black examples enable Android system colors. Dark uses the original default palette. Score display is off in appearance examples.
- Continue on phone uses Black and a 12+4 custom clock. Board mode shows the emulator’s actual connection-unavailable error; no successful physical connection is claimed.
- Engine help includes “Visual guide and research”; score help includes “How reliable is Maia’s score?”. No external URL was opened during capture.

These images do not claim publication on any store. Older gameplay examples in
the README retain their explicit older-illustration captions.

## Files

| Image | SHA-256 |
| --- | --- |
| [20261027_v1_stable_2_5_about.png](20261027_v1_stable_2_5_about.png) | `9bd6cb6bdcb17338f9df96670fa50a940bf054df1e3bee5f8d8d7a417e2882ff` |
| [20261027_v1_stable_2_5_analysis_score.png](20261027_v1_stable_2_5_analysis_score.png) | `2d857042ce2b60494c6b1e51930f40a9e48ecc9e146f5fd857cc561fbbf1806f` |
| [20261027_v1_stable_2_5_analysis_settings.png](20261027_v1_stable_2_5_analysis_settings.png) | `4c10fe17b13307519f7f81b23175e9d604851f32a98f4334fdf840525688636c` |
| [20261027_v1_stable_2_5_appearance_black.png](20261027_v1_stable_2_5_appearance_black.png) | `1638528aa53a9773c65febb66ddb73bf52b455f5c6c3978938d5624c578a7bc2` |
| [20261027_v1_stable_2_5_appearance_dark.png](20261027_v1_stable_2_5_appearance_dark.png) | `5014a945b2ea4d3052e7e265bd6b9a1113ea6f3d7e596994b7b9ac0f287d4ef1` |
| [20261027_v1_stable_2_5_appearance_light.png](20261027_v1_stable_2_5_appearance_light.png) | `db4d881b21e5d0b148341f6489c08b4634c40757f3c02effb27a01895391e23c` |
| [20261027_v1_stable_2_5_appearance_settings.png](20261027_v1_stable_2_5_appearance_settings.png) | `983a064cf85f24dff91f1a9fb3a465391c882238146f9363177b599e54e3951a` |
| [20261027_v1_stable_2_5_board_options.png](20261027_v1_stable_2_5_board_options.png) | `539d5dc063b25a405083097b3bfba3cfc4586f624f58cf42e0b2ee4a90216e57` |
| [20261027_v1_stable_2_5_boards.png](20261027_v1_stable_2_5_boards.png) | `34c307f92d92f1befd13ed7e014a5e3f688abf3aa80d37deb3a4fb5593bcc691` |
| [20261027_v1_stable_2_5_continue_board.png](20261027_v1_stable_2_5_continue_board.png) | `3ff1c323daa7667ca0220a8e8e0acaecaed1632650be15bb3c20d3aa457520cd` |
| [20261027_v1_stable_2_5_continue_phone.png](20261027_v1_stable_2_5_continue_phone.png) | `c473f4cc8a076851cedec4c1182b9f4f8c103167ed0e1a73030ab0fd9eb4764a` |
| [20261027_v1_stable_2_5_editor.png](20261027_v1_stable_2_5_editor.png) | `4833808034a30394069fcbbcb41954f0e8c81603f9973cf0bd678bfa899d0850` |
| [20261027_v1_stable_2_5_editor_settings.png](20261027_v1_stable_2_5_editor_settings.png) | `78bf98a0a0db2e2a18a159eeb1231706940dd5cbb47f70a347ea7d77260914d1` |
| [20261027_v1_stable_2_5_engine.png](20261027_v1_stable_2_5_engine.png) | `c4f9d3a63aa28b152054b9bfc0ea7e59a902732e756509210336d48f807e0472` |
| [20261027_v1_stable_2_5_engine_help.png](20261027_v1_stable_2_5_engine_help.png) | `d751f42b17d82dac7cff73886eac6a3985b77b45b91130702b250891d8edac93` |
| [20261027_v1_stable_2_5_home.png](20261027_v1_stable_2_5_home.png) | `69da03526c30d48e684d06dca4655223922473d59d813cee86ea6f28df8f04ef` |
| [20261027_v1_stable_2_5_pieces.png](20261027_v1_stable_2_5_pieces.png) | `ceb1e78f7c8e48014244bd763102d9d22da64cb079f78501b077b56c1d28c8d2` |
| [20261027_v1_stable_2_5_score_help.png](20261027_v1_stable_2_5_score_help.png) | `7e176e93c967f6fb4816ed4a5d6cd32f5e6a9221a343056bdd63c9bd2a13571a` |

## Fastlane order

The copies in `fastlane/metadata/android/en-US/images/phoneScreenshots/` match:

1. `home`
2. `analysis_score`
3. `appearance_light`
4. `appearance_black`
5. `boards`
6. `pieces`
7. `editor`
8. `continue_phone`
