# Release hardening without physical devices

The ordinary CI suite includes the deterministic regressions and a checked-in
256-position chess oracle. The Python development environment is required for
release-tool tests and for regenerating/expanding the oracles. These tools do
not add runtime dependencies or network access to the app.

## Standard checks

Use the Flutter version and commit pinned in `.github/workflows/checks.yml`.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test --reporter expanded
python3 -m venv /tmp/maia-release-venv
/tmp/maia-release-venv/bin/pip install -r tool/hardening/requirements.txt
/tmp/maia-release-venv/bin/python -m unittest discover -s tool -p '*_test.py'
```

The added tests cover Top-P sampling, malformed checkpoint metadata, PGN byte
and nesting limits, delayed board alerts, pause/resume guidance, failed native
Stockfish commands, lost Bluetooth command completions, and disconnect failure.
The queue stress test uses 1,000 seeded operations with cancellation, background
work, suspension, resumption, and simulated native errors. It checks that every
request settles and native execution remains serial.

## Independent chess oracle

```sh
python3 -m venv /tmp/maia-chess-oracle-venv
/tmp/maia-chess-oracle-venv/bin/pip install -r tool/hardening/requirements.txt
/tmp/maia-chess-oracle-venv/bin/python tool/hardening/generate_chess_corpus.py \
  --positions 3000 --seed 20260909 --output /tmp/maia-chess-oracle.json
MAIA_CHESS_CORPUS=/tmp/maia-chess-oracle.json \
  flutter test test/chess_oracle_test.dart --reporter expanded
```

The oracle compares legal moves, mate/stalemate status, selected move transitions,
board-frame move inference, and PGN import/export against python-chess. Fixed
positions exercise castling, pinned en passant, promotion, and terminal states;
the remainder follow seeded legal games. This is differential testing, not an
exhaustive proof of chess correctness or a test of Maia's rating calibration.
Use `--positions 256 --output test/fixtures/chess_oracle.json` to regenerate the
committed fixture with the default seed.

The corpus also supplies the complete 4,352-entry Maia move vocabulary, its
Black-perspective mapping, and board token occupancy derived with python-chess.
Regenerate older external corpora to include these fields. Sampling tests check
43,200 probability-space quantiles across temperatures, Top-P settings, colours,
promotion positions, and large additive shifts to logits.

Additional regressions cover Stockfish readiness failures and score perspective,
timeout draws against insufficient mating material, analysis restoration and
existing variations after pawn double moves, failed checkpoint writes, and a
1,000-game archive. These run as part of the standard suite.

`test/variation_navigation_test.dart` covers returning from imported and nested
variations, move highlighting, root alternatives, black-to-move starting FENs,
save/reopen, stale analysis replies, repeated branch exits with annotations,
and every main-line move of the reported 66-move game in both directions.
`test/pgn_import_routes_test.dart` drives shared, pasted, and file-picker PGNs
through their screens with the real background parser. This guards against
isolate closures accidentally capturing unsendable widget state.

`test/chessnut_continuation_test.dart` covers completed-game restoration and
switching from board input to the screen, including delayed connection/LED
callbacks, pending Maia moves, takebacks, draw decisions, retry, checkmate,
and persistence. `test/chessnut_continuation_layout_test.dart` checks both
connection actions and scrollable menus in portrait/landscape at normal and
200% text size. Android integration also opens real Recent games records,
continues a board game on screen with real Maia, and verifies that saving and
reopening preserve the archive identity and the new input choice.

The 1,000-ply PGN stress test prints a host timing for import and round-trip.
Compare timings on the same host; it does not establish phone performance.

## Variation preservation and action sequences

`test/takeback_review_regressions_test.dart` reproduces the consecutive
takebacks reported around move 12. It checks eight analysis visits and four
reopens, the full exported PGN, move history, clock history, and notes. It also
loads an older save containing three copies of the same line and verifies that
one complete line survives with the combined annotations.

`test/variation_tree_test.dart` covers every segmentation of a six-move
continuation, different child alternatives, comments and NAGs, equivalent
legacy FEN notation, and the boundary between played and undone moves. An
undone terminal continuation must never become part of the played main line.

`test/beta16_release_regressions_test.dart` combines seeded legal moves,
repeated takebacks, stale Maia replies, background/resume, reopening, and
analysis visits. After each step it checks played moves, board position and
clocks. It now also checks that exported root-to-leaf variation paths occur
once and that merely opening analysis does not change the exported PGN.

The independent variation oracle starts with python-chess games containing
legal forks, comments and NAGs, duplicates some branches as legacy saves did,
and mixes flat PGN branches with segmented takeback trees in Dart. It compares
all move paths and their annotations, unique leaf paths, the played main line,
and the final position against Python's expected values. Each tree undergoes
four export/merge cycles. The ordinary CI suite uses 32 checked-in games;
release hardening can run a larger corpus with a different seed:

```sh
/tmp/maia-chess-oracle-venv/bin/python tool/hardening/generate_variation_corpus.py \
  --cases 512 --seed 20260911 --output /tmp/maia-variation-oracle.json
MAIA_VARIATION_CORPUS=/tmp/maia-variation-oracle.json \
  flutter test test/variation_oracle_test.dart --reporter expanded
```

Use `--output test/fixtures/variation_oracle.json` with the default arguments
to regenerate the committed fixture. Both generators use the same optional
Python environment. The starting positions include castling, promotion, and
en passant for either side.

For future bugs, retain a reduced PGN or saved-record fixture and first show
that the relevant regression fails on the affected release. Test combinations
of features, including no-op visits and save/reload cycles, rather than only
testing each button in isolation. Keep fast deterministic cases in every PR's
CI; run expanded seeded corpora, native integration, and a clean release build
before publishing. A newly failing seed should become a permanent small case.

## Android native integration

Use JDK 17, the project's Android SDK/NDK versions, an ARM64 Android emulator,
and the real model asset verified by `python3 tool/verify_model.py`. Materialize
Git LFS assets before building. On Apple Silicon, the audit used an AOSP API 36
ARM64 image with hardware acceleration, two virtual CPU cores, and 3 GB RAM.

```sh
flutter devices
flutter test integration_test/review_android_test.dart \
  -d emulator-5554 --reporter expanded
tool/build_android_release.sh
```

Substitute the actual emulator ID. Integration tests exercise the real Maia
policy bridge, real Stockfish navigation and graph analysis, a reported game
replay, and checkmate UI handling. Test-only simulated transports cover Bluetooth
failures; the emulator does not establish actual GATT or LED behavior.
The reported move-16 variation is also exercised with the real engines, checking
that Back selects the highlighted main-line move and Forward follows that line.
The paste dialog also imports the reported PGN through a real isolate on Android.
The nested-takeback regression uses real Android storage and clipboard, opens
analysis with the real engines, and reopens the game after each visit. Its game
opponent is controlled so the exact takeback/replacement sequence is repeatable.

Check that the emulator has finished booting and no system crash/ANR dialog is
covering the app. Android can deny clipboard reads to an unfocused app; do not
disable permissions or SELinux to make a test pass. Run native suites serially
on an emulator containing only synthetic test data. Separately smoke-test the
release APK and update restoration, since debug integration alone does not
verify the artifact that will ship.

Keep release artifacts unsigned for review. Do not commit materialized model
binaries, SDKs, caches, emulator disks, or generated APKs. The checked-in LFS
pointer must remain a pointer.

## Portable APK and upgrade checks

[`RELEASE_CHECKS.md`](RELEASE_CHECKS.md) documents the repository tools for APK
packaging/signature/payload verification and an emulator saved-game upgrade.
They replace the one-off Mac scripts with configurable SDK/APK paths, a
sanitized checked-in PGN, JSON pass/fail results and failure diagnostics. The
manual CI release-build job also runs packaging verification and retains its
APK/log/report artifacts for 14 days.
