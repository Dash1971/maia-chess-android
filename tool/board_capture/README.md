# Local Chessnut capture and replay

Developer tooling for issues #40 and #68. It is not imported, packaged or started
by Mobile Maia. Ordinary app diagnostics never activate this recorder. No app
permission, Internet access, background service or runtime dependency is added.

## Capture a focused session

Use Python 3.10+ on a computer with BLE. Create a disposable environment:

```sh
python3 -m venv tool/board_capture/.venv
tool/board_capture/.venv/bin/pip install -r tool/board_capture/requirements.txt
tool/board_capture/.venv/bin/python tool/board_capture/capture.py capture --seconds 120
```

Close Mobile Maia and other board clients first. This is a direct computer-to-board
connection, **not a passive recording of the Android app's connection**. Enable
Bluetooth and grant the terminal/Python Bluetooth permission on macOS; Linux needs
a working BlueZ adapter and permission to access it. Do not run the tool as root
or disable platform security to bypass permission errors.

Only Chessnut-named candidates are considered, and required GATT characteristics
are checked before initialization. Prefer having only the test board powered on.
If more than one candidate is present, the tool stops; `--board-index N` explicitly
selects a candidate from the next scan, whose order is not persistent. No other
board family is currently recognized or claimed supported.

The recorder subscribes only to the Chessnut data and confirmation characteristics,
then sends initialization `21 01 00` and battery query `29 01 00`. It sends no LED,
sound, reset or movement commands. Play/rearrange the physical pieces to reproduce
the issue. Stop with Ctrl+C; timeout, disconnect and limits also stop capture.
The connection closes on exit. A bounded partial capture remains after interruption.

Files are exclusively created with mode 0600 under the ignored `captures/`
directory. Limits: 600 seconds, 10,000 frames, 512 bytes/frame and 4 MiB/file.
A limit stops recording rather than silently dropping old evidence. Timestamps
are elapsed milliseconds, not wall-clock dates. TX entries record completed writes;
they do not assert that the board accepted the command semantically.

No device name, MAC/OS identifier, account, filesystem path or unrelated Bluetooth
traffic enters the file. Optional `--model go` and `--firmware 1.2.3` are deliberately
supplied metadata, **not inferred hardware/firmware claims**. Library exception
messages are not printed because they can contain identifiers. For connection
failures, check permissions, competing clients and required services locally.

## Review before exporting or committing

Raw bytes **do reveal board positions and game sequences**. Metadata validation
cannot decide whether those positions are private or whether an undocumented
packet embeds identifying information. Review every retained frame locally,
remove unnecessary frames and use a synthetic/minimized reproduction where possible.
Never commit raw captures or attach them automatically to an issue.

```sh
python3 tool/board_capture/capture.py review tool/board_capture/captures/CAPTURE.jsonl
# Only after inspecting and minimizing the raw bytes/board positions:
python3 tool/board_capture/capture.py review tool/board_capture/captures/CAPTURE.jsonl \
  --export test/fixtures/board_protocol/REVIEWED.jsonl --reviewed-board-state
```

Review accepts a strict schema and rejects unrecognized fields rather than
claiming arbitrary input was redacted. Exports never overwrite a file. Remove an
unneeded capture with `rm tool/board_capture/captures/CAPTURE.jsonl`; remove the
optional `.venv` when finished. Keep capture files out of release artifacts.

## Replay format and tests

JSONL starts with `{schema, board, model}` (optional numeric `firmware`). Each
following record has exactly `{t_ms, direction, characteristic, hex}`. Directions
are `rx` for `data`/`confirm` and `tx` for `write`; characteristic aliases replace
UUIDs. Frames are lowercase even-length hex, times nondecreasing. Version 1 supports
Chessnut only; future board adapters must explicitly define their own schema and
privacy rules instead of relabeling these bytes.

`test/fixtures/board_protocol/decode-recovery.jsonl` is **synthetic**, not a
hardware capture: starting position, injected unknown code 0xe, then e2e4.
It models the error shape reported in #68 without claiming its physical cause.
The Dart replay test uses relative times and the actual production decoder;
no sleeping, BLE hardware or optional Python dependencies are required.

```sh
python3 -m unittest tool/board_capture_test.py
flutter test test/chessnut_decode_recovery_test.dart test/chessnut_continuation_test.dart
```

These tests cover schema/privacy bounds, limits, deterministic replay, diagnostic
throttling, malformed values, both payload offsets and game-screen recovery.
They do not verify GATT firmware behavior, LEDs, motors or actual radio recovery.
Hardware acceptance remains necessary before closing the board-support rollout.

## Routine app diagnostics (#68)

A decode failure reports last-valid age, bounded failure count and native readiness
flags. Dev/Preview additionally include notification-relative byte offset, low/high
nibble (0/1) and **at most three bytes** surrounding the offending code. This excerpt
can reveal up to six squares; it is deliberately failure-only, local and bounded.
Stable/unknown Flutter flavors omit this excerpt. No complete board or FEN is logged.
Repeated failures report at most once per ten seconds; one subsequent valid position
reports recovery latency/count and whether a new connection attempt intervened.
Existing 40-entry/14-day/128,000-character retention applies. A parser error is not
reported as a GATT disconnect. Readiness is restored only if the fresh valid position
also has native `ready` and GATT-present flags; old connection callbacks are rejected.

Protocol references: Chessnut's published e-board API and EasyLinkSDK (see
`THIRD_PARTY_NOTICES.md`). MoveAPiece's `tools/chessnut-sniffer/` is the structural
inspiration requested in #40; this tool is independently implemented and copies no
MoveAPiece source. `bleak` is an optional MIT-licensed host dependency.
