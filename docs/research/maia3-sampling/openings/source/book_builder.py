#!/usr/bin/env python3
"""Build rating-targeted Polyglot opening books from a PGN stream."""

from __future__ import annotations

import argparse
import io
import json
import os
import resource
import struct
import sys
import time
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterator, TextIO

import chess
import chess.pgn
import chess.polyglot


VERSION = "0.2.0"

PROMOTION_CODES = {
    chess.KNIGHT: 1,
    chess.BISHOP: 2,
    chess.ROOK: 3,
    chess.QUEEN: 4,
}


@dataclass(frozen=True)
class BuildConfig:
    ratings: tuple[int, ...]
    speeds: frozenset[str]
    speed_name: str
    output_dir: Path
    band_width: int = 50
    min_position_games: int = 25
    max_plies: int = 30
    max_elo_diff: int = 200
    month: str = "unknown"
    source_url: str = "unknown"
    source_bytes: int = 0
    partial_prefix: bool = True
    decoder: str = "unknown"


@dataclass
class BuildState:
    config: BuildConfig
    move_counts: dict[int, dict[tuple[int, int], int]] = field(init=False)
    position_games: dict[int, dict[int, int]] = field(init=False)
    position_min_ply: dict[int, dict[int, int]] = field(init=False)
    bucket_games: dict[int, int] = field(init=False)
    observations_by_ply: dict[int, dict[int, int]] = field(init=False)
    games_scanned: int = 0
    games_matched: int = 0
    started_at: float = field(default_factory=time.monotonic)

    def __post_init__(self) -> None:
        self.move_counts = {
            rating: defaultdict(int) for rating in self.config.ratings
        }
        self.position_games = {
            rating: defaultdict(int) for rating in self.config.ratings
        }
        self.position_min_ply = {rating: {} for rating in self.config.ratings}
        self.bucket_games = {rating: 0 for rating in self.config.ratings}
        self.observations_by_ply = {
            rating: defaultdict(int) for rating in self.config.ratings
        }


def encode_polyglot_move(board: chess.Board, move: chess.Move) -> int:
    """Encode a move using Polyglot's 16-bit move representation."""
    to_file = chess.square_file(move.to_square)
    to_rank = chess.square_rank(move.to_square)
    from_file = chess.square_file(move.from_square)
    from_rank = chess.square_rank(move.from_square)

    if board.is_castling(move):
        to_file = 7 if to_file > from_file else 0

    promotion = PROMOTION_CODES.get(move.promotion, 0)
    return (
        to_file
        | (to_rank << 3)
        | (from_file << 6)
        | (from_rank << 9)
        | (promotion << 12)
    )


def matching_ratings(config: BuildConfig, average_elo: int) -> list[int]:
    return [
        rating
        for rating in config.ratings
        if abs(rating - average_elo) <= config.band_width
    ]


def event_matches(event: str, speeds: frozenset[str]) -> bool:
    lowered = event.lower()
    return "rated" in lowered and any(speed in lowered for speed in speeds)


def iter_pgn_records(stream: TextIO) -> Iterator[str]:
    """Yield complete PGN records without parsing their movetext."""
    record: list[str] = []
    for line in stream:
        if line.startswith("[Event ") and record:
            yield "".join(record)
            record = []
        record.append(line)
    if record:
        yield "".join(record)


def lightweight_headers(record: str) -> dict[str, str]:
    """Read the few headers needed to reject a game before PGN parsing."""
    headers: dict[str, str] = {}
    for line in record.splitlines():
        if not line:
            break
        if not line.startswith("[") or " \"" not in line or not line.endswith('\"]'):
            continue
        name, value = line[1:-1].split(" \"", 1)
        headers[name] = value[:-1]
    return headers


def headers_match(config: BuildConfig, headers: dict[str, str]) -> list[int]:
    if not event_matches(headers.get("Event", ""), config.speeds):
        return []
    try:
        white_elo = int(headers.get("WhiteElo", "0"))
        black_elo = int(headers.get("BlackElo", "0"))
    except ValueError:
        return []
    if white_elo <= 0 or black_elo <= 0:
        return []
    if abs(white_elo - black_elo) > config.max_elo_diff:
        return []
    return matching_ratings(config, (white_elo + black_elo) // 2)


def collect_game(game: chess.pgn.Game, ratings: list[int], state: BuildState) -> None:
    config = state.config
    mainline = list(game.mainline_moves())
    if len(mainline) < 6:
        return
    state.games_matched += 1
    board = game.board()
    observations: list[tuple[int, int, int]] = []
    for ply, move in enumerate(mainline[: config.max_plies], start=1):
        key = chess.polyglot.zobrist_hash(board)
        observations.append((key, encode_polyglot_move(board, move), ply))
        board.push(move)

    positions_in_game: dict[int, int] = {}
    for key, _move, ply in observations:
        positions_in_game.setdefault(key, ply)
    for rating in ratings:
        state.bucket_games[rating] += 1
        for key, ply in positions_in_game.items():
            state.position_games[rating][key] += 1
            state.position_min_ply[rating].setdefault(key, ply)
            state.observations_by_ply[rating][ply] += 1
        for key, move, _ply in observations:
            state.move_counts[rating][(key, move)] += 1


def collect_stream(stream: TextIO, config: BuildConfig, state: BuildState | None = None) -> BuildState:
    state = state or BuildState(config)
    started = time.monotonic()
    last_print = started

    for record in iter_pgn_records(stream):
        state.games_scanned += 1
        ratings = headers_match(config, lightweight_headers(record))
        if not ratings:
            continue
        try:
            game = chess.pgn.read_game(io.StringIO(record))
        except (ValueError, UnicodeError):
            continue
        if game is None:
            continue
        collect_game(game, ratings, state)

        now = time.monotonic()
        if now - last_print >= 3:
            elapsed = max(now - started, 0.001)
            rate = state.games_scanned / elapsed
            print(
                f"Scanned {state.games_scanned:,}; matched "
                f"{state.games_matched:,}; {rate:,.0f} games/s",
                file=sys.stderr,
                flush=True,
            )
            last_print = now

    return state


def entries_for_rating(state: BuildState, rating: int) -> list[tuple[int, int, int]]:
    config = state.config
    eligible_keys = {
        key
        for key, games in state.position_games[rating].items()
        if games >= config.min_position_games
    }
    if not eligible_keys:
        return []

    per_key_max: dict[int, int] = defaultdict(int)
    for (key, _move), count in state.move_counts[rating].items():
        if key in eligible_keys:
            per_key_max[key] = max(per_key_max[key], count)

    entries = [
        (key, move, max(1, round(count / per_key_max[key] * 65535)))
        for (key, move), count in state.move_counts[rating].items()
        if key in eligible_keys
    ]
    # Key ordering is required by Polyglot. Weight-descending order within a
    # key also supports simple readers that use the first matching entry.
    entries.sort(key=lambda entry: (entry[0], -entry[2], entry[1]))
    return entries


def output_path(config: BuildConfig, rating: int) -> Path:
    return config.output_dir / (
        f"lichess_{rating}_{config.speed_name}_{config.month}.bin"
    )


def metadata_path(book_path: Path) -> Path:
    return book_path.with_suffix(".json")


def peak_rss_mib() -> float:
    maximum = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    if sys.platform == "darwin":
        maximum /= 1024
    return maximum / 1024


def ply_statistics(
    state: BuildState,
    rating: int,
    book_entries: list[tuple[int, int, int]],
) -> dict[str, dict[str, int]]:
    eligible_keys = {
        key
        for key, games in state.position_games[rating].items()
        if games >= state.config.min_position_games
    }
    positions: dict[int, int] = defaultdict(int)
    entries_by_ply: dict[int, int] = defaultdict(int)
    covered_observations: dict[int, int] = defaultdict(int)
    for key in eligible_keys:
        ply = state.position_min_ply[rating][key]
        positions[ply] += 1
        covered_observations[ply] += state.position_games[rating][key]
    for key, _move, _weight in book_entries:
        entries_by_ply[state.position_min_ply[rating][key]] += 1
    return {
        "book_entries": {
            str(ply): entries_by_ply[ply] for ply in sorted(entries_by_ply)
        },
        "covered_game_observations": {
            str(ply): covered_observations[ply]
            for ply in sorted(covered_observations)
        },
        "emitted_positions": {
            str(ply): positions[ply] for ply in sorted(positions)
        },
        "matched_game_observations": {
            str(ply): count
            for ply, count in sorted(state.observations_by_ply[rating].items())
        },
    }


def write_json_atomic(destination: Path, payload: dict[str, object]) -> None:
    temporary = destination.with_name(destination.name + ".tmp")
    try:
        with temporary.open("w", encoding="utf-8") as metadata:
            json.dump(payload, metadata, indent=2, sort_keys=True)
            metadata.write("\n")
        os.replace(temporary, destination)
    finally:
        temporary.unlink(missing_ok=True)


def write_rating_book(
    state: BuildState, rating: int, build_status: str = "complete"
) -> Path | None:
    entries = entries_for_rating(state, rating)
    if not entries:
        return None

    destination = output_path(state.config, rating)
    temporary = destination.with_name(destination.name + ".tmp")
    destination.parent.mkdir(parents=True, exist_ok=True)
    try:
        with temporary.open("wb") as book:
            for key, move, weight in entries:
                book.write(struct.pack(">QHHi", key, move, weight, 0))
        os.replace(temporary, destination)
    finally:
        temporary.unlink(missing_ok=True)

    config = state.config
    write_json_atomic(
        metadata_path(destination),
        {
            "artifact": destination.name,
            "build_status": build_status,
            "builder_version": VERSION,
            "parameters": {
                "band_width": config.band_width,
                "max_elo_diff": config.max_elo_diff,
                "max_plies": config.max_plies,
                "min_position_games": config.min_position_games,
                "rating": rating,
                "speed": config.speed_name,
                "speed_filters": sorted(config.speeds),
            },
            "source": {
                "bytes": config.source_bytes,
                "month": config.month,
                "partial_prefix": config.partial_prefix,
                "decoder": config.decoder,
                "url": config.source_url,
            },
            "statistics": {
                "book_entries": len(entries),
                "elapsed_seconds": round(time.monotonic() - state.started_at, 3),
                "games_in_rating_bucket": state.bucket_games[rating],
                "games_matched": state.games_matched,
                "games_scanned": state.games_scanned,
                "peak_rss_mib": round(peak_rss_mib(), 3),
                "ply": ply_statistics(state, rating, entries),
            },
        },
    )
    return destination


def write_books(state: BuildState, build_status: str = "complete") -> list[Path]:
    paths = []
    for rating in state.config.ratings:
        path = write_rating_book(state, rating, build_status)
        if path is not None:
            paths.append(path)
    return paths


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--ratings", required=True)
    parser.add_argument("--speeds", required=True)
    parser.add_argument("--speed-name", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--band-width", type=int, default=50)
    parser.add_argument("--min-position-games", type=int, default=25)
    parser.add_argument("--max-plies", type=int, default=30)
    parser.add_argument("--max-elo-diff", type=int, default=200)
    parser.add_argument("--month", required=True)
    parser.add_argument("--source-url", required=True)
    parser.add_argument("--source-bytes", type=int, required=True)
    parser.add_argument("--full-archive", action="store_true")
    parser.add_argument("--decoder", default="unknown")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    config = BuildConfig(
        ratings=tuple(int(value) for value in args.ratings.split(",")),
        speeds=frozenset(args.speeds.split(",")),
        speed_name=args.speed_name,
        output_dir=args.output_dir.expanduser(),
        band_width=args.band_width,
        min_position_games=args.min_position_games,
        max_plies=args.max_plies,
        max_elo_diff=args.max_elo_diff,
        month=args.month,
        source_url=args.source_url,
        source_bytes=args.source_bytes,
        partial_prefix=not args.full_archive,
        decoder=args.decoder,
    )
    for label, value in (
        ("band width", config.band_width),
        ("minimum position games", config.min_position_games),
        ("maximum plies", config.max_plies),
        ("maximum Elo difference", config.max_elo_diff),
        ("source bytes", config.source_bytes),
    ):
        if value <= 0:
            raise SystemExit(f"{label} must be positive")

    state = BuildState(config)
    interrupted = False
    try:
        collect_stream(sys.stdin, config, state)
    except KeyboardInterrupt:
        interrupted = True
        print("Interrupted; writing a partial book from collected games.", file=sys.stderr)

    paths = write_books(state, "interrupted" if interrupted else "complete")
    print(f"Scanned: {state.games_scanned:,} games")
    print(f"Matched: {state.games_matched:,} games")
    for path in paths:
        print(path)
    return 130 if interrupted else 0


if __name__ == "__main__":
    raise SystemExit(main())
