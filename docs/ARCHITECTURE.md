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
| `lib/src/pgn_analysis.dart` | Portable PGN evaluation/NAG annotations, restoration and analysis-free exports. |
| `lib/src/chessnut.dart` / electronic-board parts | Connection ownership, board snapshots and game handoff. |

## Android bridges

All Kotlin files are under `android/app/src/main/kotlin/com/dash1971/maia_chess/`.

| File | Responsibility |
| --- | --- |
| [MainActivity.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/MainActivity.kt) | Activity lifecycle, MaiaEngine/ONNX inference, engine channel and document-method routing. |
| [ChessnutBridge.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/ChessnutBridge.kt) | Bluetooth discovery, permissions, connections, board I/O and events for supported boards. |
| [ElectronicBoardProtocol.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/ElectronicBoardProtocol.kt) | Board-family protocol parsing and channel support policy. |
| [PgnDocuments.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/PgnDocuments.kt) | PGN picker, scoped content-URI read/write and sharing. |
| [SamplingDocuments.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/SamplingDocuments.kt) | Sampling report/JSONL save and share requests. |
| [SamplingDocumentSnapshot.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/SamplingDocumentSnapshot.kt) | Temporary export snapshots surviving Activity recreation. |
| [SamplingShareFiles.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/SamplingShareFiles.kt) | Bounded temporary sampling share-file retention. |
| [SessionRecoveryPolicy.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/SessionRecoveryPolicy.kt) | Interpret Android process-exit reasons for recovery. |
| [SoundEffectBridge.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/SoundEffectBridge.kt) | SoundPool lifecycle and game sound-effect requests. |
| [DevDiagnostics.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/DevDiagnostics.kt) | Dev-only diagnostic method handling and local export. |
| [DevTraceStore.kt](../android/app/src/main/kotlin/com/dash1971/maia_chess/DevTraceStore.kt) | Dev-only bounded local trace storage. |

| Platform channel | Use |
| --- | --- |
| `maia_chess/engine` | Maia inference, PGN/sampling documents, recovery and diagnostics. |
| `maia_chess/chessnut` | Electronic-board commands. |
| `maia_chess/chessnut/events` | Electronic-board discovery, connection and position events. |
| `maia_chess/sound_effect` | Game sound effects. |

Stockfish runs through the pinned engine package. ONNX inference remains local.
Reject stale results at the owning controller/session; preserve lifecycle and
cancellation across asynchronous bridge calls. Dev diagnostic handlers remain
disabled outside Dev even though their source is present.

The [storage contract](session-storage.md) is authoritative before changing
saved games or recovery. [Native board protocol](ELECTRONIC_BOARD_NATIVE_PROTOCOL.md)
describes hardware boundaries; supported devices and release
status come from [channel status](BUILD_CHANNELS.md), not file names alone.

Tests live in `test/` (Dart/widget), `integration_test/` (installed app),
`android/native_test/` (native policies) and `tool/*_test.py` (release tooling).
Use [the testing guide](../tool/hardening/README.md) for commands. Controlled
transports and widget renders do not establish physical Bluetooth acceptance.
