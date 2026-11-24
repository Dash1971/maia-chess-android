# Architecture map

The Flutter app is one Dart library: `lib/main.dart` includes `lib/src/` part
files. A part file is not an independent package. Keep UI, game ownership and
asynchronous engine/storage work consistent across those parts.

| Area | Responsibility |
| --- | --- |
| `lib/main.dart` | App setup, routes, preferences and shared declarations. |
| `lib/src/play.dart` | Live game, clocks, moves, engine turns and lifecycle. |
| `lib/src/analysis_board.dart` / `lib/src/review.dart` | Position/variation analysis and full-game review. |
| `lib/src/board_editor.dart` | Manual placement/FEN editing and confirmed continuation. |
| `lib/src/session_model.dart` / repository/store parts | Saved-game/checkpoint serialization and recovery. |
| `lib/src/chessnut.dart` / electronic-board parts | Connection ownership, board snapshots and game handoff. |
| `android/app/src/main/kotlin/com/dash1971/maia_chess/MainActivity.kt` | Android platform channels for Maia/ONNX, document actions and sound. |
| `android/app/src/main/kotlin/com/dash1971/maia_chess/ChessnutBridge.kt` | Bluetooth discovery, connection and device I/O. |
| `android/app/src/main/kotlin/com/dash1971/maia_chess/ElectronicBoardProtocol.kt` | Board-family protocol/policy helpers. |
| `android/app/src/main/kotlin/com/dash1971/maia_chess/PgnDocuments.kt` | Scoped Android PGN document I/O. |

Dart requests native Maia inference over a platform channel; ONNX runs locally.
Stockfish uses the pinned engine package. Bluetooth, PGN/sampling document
operations and game sounds cross their dedicated Android bridge paths. Keep
stale-result rejection and cancellation at the owning controller/session.

The [storage contract](session-storage.md) is authoritative before changing
saved games or recovery. [Native board protocol](ELECTRONIC_BOARD_NATIVE_PROTOCOL.md)
describes hardware boundaries; supported devices and release
status come from [channel status](BUILD_CHANNELS.md), not file names alone.

Tests live in `test/` (Dart/widget), `integration_test/` (installed app),
`android/native_test/` (native policies) and `tool/*_test.py` (release tooling).
Use [the testing guide](../tool/hardening/README.md) for commands. Controlled
transports and widget renders do not establish physical Bluetooth acceptance.
