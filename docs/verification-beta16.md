# Beta.16 post-merge verification

Verified on 2026-09-10 using Apple Silicon macOS, pinned Flutter 3.47.1,
JDK 17, and an AOSP API 36 ARM64 emulator.

## Merge and published artifact

The published release is `v2.1.0-beta.16`, commit
`ffc665c86c9ccfb6be0179e5d47a97d57b2b997b`.

- PRs #1, #2, #3, #4, #5, #6, and #12 all have merge commits in the release's
  ancestry. Each merge tree is identical to its corresponding final PR head.
- PR #12 includes the additional takeback-persistence fix `ab37f818`.
  The only change after the merge is the version bump to beta.16.
- The release tag's GitHub test check passed. Its Android job is manual-only;
  Android integration was independently executed locally for this review.
- The downloaded signed APK has SHA-256
  `065738b2e2c29d309a22e319daee5516714a34af576c696404d03a59f2bacdec`
  and is 393,511,711 bytes. This matches GitHub's asset digest.
- A clean rebuild from the release tag produced **identical contents for all
  2,484 ZIP entries**, including Dart/native code, Android bytecode, manifest,
  resources, and assets. The local build is unsigned, so whole-APK hashes differ.
- The signature verifies and its certificate matches the earlier published
  beta.13 APK. The package is `com.dash1971.maia_chess.preview`, version
  `2.1.0-beta.16`, version code 2070, minimum API 24, target API 36.
- No Internet permission is present. All eight native libraries are ARM64 and
  have 16 KB-compatible ELF load segments; ZIP alignment and CRC checks pass.
  There are no duplicate ZIP entries, bundled test PGNs/keystores, or this
  checkout's absolute path in `libapp.so`.
- The 316,034,244-byte Maia model matches SHA-256
  `3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010`.

## Confirmed compatibility defect and correction

Older analysis records can omit an en-passant target square when no legal
capture exists. For example, after `1. e4`, one library records `e3` in the FEN
and the other records `-`. These describe the same playable position.

Game PGN export compared these strings literally. A saved `1... c5 2. Nf3`
variation and its comments could therefore be omitted from the exported PGN.
Takeback used a similar comparison, leaving an older nested variation detached
from its abandoned parent. Both cases failed new regression tests on beta.16.
The export failure was also reproduced in the actual downloaded release APK
using a synthetic older-format saved game.

Played moves, results, clocks, and the variation's original session JSON remain
intact. This predates PR #12 and is not a merge or packaging error.

The correction compares canonical positions when the strings differ and checks
the exact parent ply during takeback. A legally available en-passant capture
still distinguishes positions. Invalid orphan FENs are ignored during matching
instead of causing a valid game export to fail. No data migration, dependency,
setting, engine, or permission change is required.

## Regression and hardening coverage

The unmodified release source passed all **286 unit/widget tests**, static
analysis, both Python tooling tests, all **11 Android integration tests**, and
a fresh **25,000-position** independent python-chess corpus (seed 20260913).
The corpus checks legal moves, resulting FENs, mate/stalemate, encoding, PGN
round trips, simulated Chessnut move inference, and the full 4,352-move
vocabulary and Black-side mirroring.

Seven additional host tests cover legacy export, nested takeback, preservation
of genuine en-passant rights, malformed orphan positions, and three seeded
40-turn traces combining play, repeated takebacks, stale engine replies,
backgrounding, and reopening. They assert played moves, board position, clock
history, mainline annotations, and validity of every exported branch.

The corrected code, runtime commit `4c1183faf5e09438bdc08437f0a0237a67f67b0d`,
passed the full **293-test host suite**, static analysis, and all **12 Android
integration tests**. The new Android regression checks the older-format
variation through real session-file restoration and the native clipboard
export path. The same 25,000-position corpus also passed again on the corrected
code.

The Flutter integration harness reinstalls the lower-version debug test app
over the release app in the isolated emulator. Its final cleanup can also log
an unsuccessful uninstall of the stable namespace, which is not installed;
the tested package is the Preview package. These harness messages did not
prevent the 12 tests from completing successfully.

## Published APK checks

An in-place signed upgrade from published beta.13 to beta.16 retained synthetic
active and archived game files byte for byte before launch. After launch, the
game's ID, played moves, final result, historical/final clocks, and JSON
variations were preserved. The legacy variation export defect described above
was reproduced without altering the APK.

The actual published APK also passed:

- Completed Chessnut-game restore without a reconnect request.
- Hold Back/Forward navigation with correct initial and final clocks.
- Android sharing of the supplied 131-ply PGN, including its branches.
- Restoring the move-16 `Qc3 Qf6` branch, rewinding to mainline ply 30, moving
  forward on the main line, and retaining ply 31 across force-stop/restart.
- Real Maia and Stockfish analysis after restart.

One previously documented UI limitation remains visible: restoring an analysis
position restores the board and selection, but the move list initially starts
at its top rather than scrolling to the selected move. This does not change
the saved position or the repaired variation-back behavior.

## Corrected release-mode verification

A clean ARM64 release build of `4c1183f` also passed an emulator smoke test.
The same older-format record that reproduced the omission in the published APK
now exports the Sicilian variation and its note. Its ID, played moves, result,
clock history, final clocks, and original JSON variations are preserved.
Independent python-chess parsing confirms the exported main line and branch.

The corrected unsigned APK is 393,503,519 bytes, SHA-256
`5ee4d549dbaf0876fc5747bde97563ec8f765cd3056b30b1cd1523c580ac8da4`.
Its only changed ZIP payload entry compared with the rebuilt beta.16 is
`lib/arm64-v8a/libapp.so`. A separate copy signed with the local Android test
key was installed; production keys were not used.

An initial manually injected fixture retained the previous emulator app UID's
SELinux label following debug/release reinstalls. Android rejected that file.
The fixture was relabelled to match its current app directory and the check
passed with SELinux still enforcing. No application change was needed for
this test-environment issue.

The source-to-APK comparison and upgrade check establish that the expected code
was merged and published. They do not establish that no other bugs exist.
Physical phones, battery behavior, Bluetooth radio delivery, and real Chessnut
boards remain the user's device tests. No merge, production signing, or release
publication was performed in this review.

## Reproduction

With the pinned Flutter toolchain and verified bundled model:

```sh
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
python3 -m unittest discover -s tool -p '*_test.py'
python3 tool/hardening/generate_chess_corpus.py --positions 25000 --seed 20260913 --output /tmp/maia-beta16-corpus.json
MAIA_CHESS_CORPUS=/tmp/maia-beta16-corpus.json flutter test --no-pub test/chess_oracle_test.dart --reporter expanded
flutter test --no-pub integration_test/review_android_test.dart -d emulator-5554 --reporter expanded
tool/build_android_release.sh
```

The corpus generator uses the optional python-chess development dependency.
