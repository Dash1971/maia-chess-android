# Release hardening without physical devices

The ordinary CI suite includes the deterministic regressions and a checked-in
256-position chess oracle. Python is optional unless regenerating or expanding
the oracle. These tools do not add runtime dependencies or network access to
the app.

## Standard checks

Use the Flutter version and commit pinned in `.github/workflows/checks.yml`.

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test --reporter expanded
python3 -m unittest discover -s tool -p '*_test.py'
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

The 1,000-ply PGN stress test prints a host timing for import and round-trip.
Compare timings on the same host; it does not establish phone performance.

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

Keep release artifacts unsigned for review. Do not commit materialized model
binaries, SDKs, caches, emulator disks, or generated APKs. The checked-in LFS
pointer must remain a pointer.
