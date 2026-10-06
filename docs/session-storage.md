# Saved-game history and compatibility contract

Recent Games shows when a game **started**, not when the app last saved or
analyzed it. Opening, resuming, completing, annotating, or analyzing a game keeps
its identity, played date, and chronological position. This contract addresses
[issue #81](https://github.com/Dash1971/maia-chess-android-preview/issues/81).
Track compatibility maintenance in
[issue #77](https://github.com/Dash1971/maia-chess-android-preview/issues/77).

## Separate history from recovery

Android uses app-private session files. The existing version-1 envelope retains
`id`, `updatedAt`, and `data`; it adds an optional `gameHistory` object:

```json
{
  "version": 1,
  "playedOn": "2026-10-05",
  "startedAt": "2026-10-04T15:15:00.000Z"
}
```

- `playedOn` is the calendar date at game creation, stored as `YYYY-MM-DD`.
  Render its components with the selected locale. Never convert it to the
  current timezone. Traveling or changing language must not change the day.
- `startedAt` is the exact UTC start instant for explicitly created games.
  Legacy games usually lack this information; leave it null.
- `updatedAt` is still the envelope's latest-save timestamp. It is neither the
  display date nor the Recent Games sort key.
- The payload's `savedAt` and clock snapshots retain their existing recovery
  meaning. Do not use historical metadata to calculate elapsed game time.
- The envelope ID identifies the game across its game/review representations.
  PGN content, date, engine rating, and filename modification time are not IDs.

Newest played dates sort first. Within a day, games with an exact start instant
sort first and use that instant newest-first; remaining ties use descending ID.
An ID tie-breaker is deterministic, not a claim about the historical order of
legacy games. Unknown dates sort last, deterministically by ID. Saving or
reviewing never affects any of these keys.

## Game boundaries

An explicit new game, including Continue from here, gets a new ID and a single
captured creation time shared by history and its PGN Date header. The source
game remains separate. Resuming keeps the old identity and date, even when play
spans midnight. Reset/discard retains the existing erase semantics: do not
autosave the discarded game again while creating its replacement.

Imported standalone analysis is not automatically a played game in Recent
Games. A new game started from an imported position uses its own creation date,
not the imported PGN's historical date.

## Upgrade and backup restore

`GameHistory` in `lib/src/session_history.dart` owns history decoding and legacy
inference. Screens consume the normalized result; do not add screen-specific
date migrations.

1. Metadata already present is authoritative, including an explicit unknown
   date. Later PGN edits cannot replace it.
2. For legacy game files without metadata, infer the day only from one valid
   original PGN `Date` header. For review checkpoints use `activeGame`, not the
   analysis session's PGN.
3. Freeze this inference before exposing the old payload or replacing it with
   an edited snapshot. Persist it on the next ordinary write/archive/open.
   Listing games is read-only; there is no bulk rewrite at launch.
4. Missing, partial, duplicate, malformed, or impossible dates become unknown.
   Show localized **Date unknown**. Do not substitute today's date, `updatedAt`,
   a filesystem timestamp, or an invented midnight start instant.
5. The old `activeSessionV1` preference migration remains supported. A durable
   checkpoint, including a tombstone, takes precedence over the old preference.
   Remove the preference only after the authoritative checkpoint is established.

There is no evidence-based retirement date for these adapters. Users can skip
releases or restore an old offline backup. Keeping a small tested reader can be
cheaper and safer than attempting to prove that all old data has disappeared.
Already overwritten PGN dates cannot be reconstructed reliably; do not promise
historical recovery where the original evidence no longer exists.

## Durability and future formats

Retain the existing serialized operations, detached save snapshots, flushed
pending writes, previous-generation recovery, and authoritative tombstones.
Returned game maps must not alias the cached checkpoint. New history metadata
must not weaken delete/reset or interrupted-write recovery.

An unsupported envelope, session schema, or history version is not corruption.
Check the primary, previous, and pending generations before overwriting or
deleting them. Refuse the operation instead of silently falling back and
destroying newer-format data. Missing schema in legacy file payloads remains
allowed; preference migration retains its existing schema-1 requirement.
Corrupt JSON can still recover from a valid previous generation. A directory
obstructing the pending path must fail writes without hiding the readable last
checkpoint; other unreadable-file errors must not be treated as missing saves.

These protections apply to this reader and later versions that retain them.
They cannot make already released older apps safe downgrade targets. Support
upgrades and restoration of supported old formats; do not promise arbitrary
downgrades or preservation of metadata by old app versions.

## Required regression coverage

| Contract | Checked-in tests |
| --- | --- |
| Stable ID/date/order across open, review, changed PGN, resume, completion, archive and restart | `test/recent_game_history_test.dart` |
| Local calendar date, UTC instant, same-day ties and unknowns; legacy missing/invalid/duplicate dates | `test/recent_game_history_test.dart` |
| Direct preference migration, repeated migration, backups/tombstones and unsupported future generations | `test/recent_game_history_test.dart`, `test/session_repository_test.dart` |
| Detached payloads, failed writes/opens, recovery and a 1,000-game archive | `test/recent_game_history_test.dart`, `test/storage_failure_test.dart` |
| New game, resume and Continue from here; storage transition/error handling | `test/game_start_history_test.dart` |
| Date rendering and unknown dates in all five languages | `test/recent_game_history_ui_test.dart`, `test/storage_localization_test.dart` |
| Existing reset, takeback, game/clock and navigation behavior | Full `flutter test` suite |

All tests above run in normal PR CI. When changing this contract, update its
fixtures and documentation together. Verify device lifecycle behavior separately
before release; host storage tests do not simulate Android process termination
or physical flash failures.
