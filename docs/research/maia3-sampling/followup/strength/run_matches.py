#!/usr/bin/env python3
"""Fixed-N p95/full comparison, app draw rules, independently seeded shards."""
import argparse
import collections
import hashlib
import json
import platform
import random
import sys
import time
from pathlib import Path

import chess
import chess.pgn
import numpy as np
import onnxruntime as ort

from app_rules import app_outcome, key
from mobile_policy import MODEL79, Policy, sha256

PROFILES = {
    'p95': {'temperature': 1.0, 'top_p': 0.95},
    'full': {'temperature': 1.0, 'top_p': 1.0},
}
ROOT = Path(__file__).resolve().parent


def make_pgn(row):
    game = chess.pgn.Game()
    game.headers.update({
        'Event': 'Mobile Maia 1600 Top-P 0.95 follow-up',
        'Site': 'local CPU', 'Date': '2026.10.03',
        'Round': str(row['number'] + 1),
        'White': f"Maia3-79m-{row['white']}",
        'Black': f"Maia3-79m-{row['black']}",
        'WhiteConditioningElo': '1600', 'BlackConditioningElo': '1600',
        'WhiteSeed': str(row['seed_white']),
        'BlackSeed': str(row['seed_black']),
        'StudyGameId': row['id'], 'Shard': str(row['shard']),
        'Result': row['result'], 'Termination': row['termination'],
    })
    node = game
    for uci in row['moves_uci']:
        node = node.add_variation(chess.Move.from_uci(uci))
    return game


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--shard', type=int, choices=list(range(6)), required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    seed = 6000000000 + args.shard * 1000000
    config = {
        'study': '20261003-p95-vs-full', 'shard': args.shard,
        'games': 200, 'total_study_games': 1200,
        'profiles': PROFILES, 'model': '79m', 'model_path': str(MODEL79),
        'model_sha256': sha256(MODEL79), 'seed': seed,
        'max_plies': 400, 'self_elo': 1600, 'opponent_elo': 1600,
        'draw_rules': 'actual app raw-FEN repetition / halfmove100 / natural terminal',
        'claim_draw': False, 'book': False, 'search': False,
        'opening': 'standard initial chess position; no forced moves',
        'history': 'current board repeated in eight slots',
        'threads': 1, 'provider': 'CPUExecutionProvider',
        'python': sys.version, 'numpy': np.__version__,
        'onnxruntime': ort.__version__, 'chess': chess.__version__,
        'platform': platform.platform(),
        'runner_sha256': sha256(__file__),
        'policy_sha256': sha256(ROOT / 'mobile_policy.py'),
        'app_rules_sha256': sha256(ROOT / 'app_rules.py'),
        'protocol_sha256': sha256(ROOT / 'PROTOCOL.md'),
    }
    manifest = args.output / 'manifest.json'
    if manifest.exists():
        assert json.loads(manifest.read_text()) == config, 'Manifest changed'
    else:
        manifest.write_text(json.dumps(config, indent=2) + '\n')
    data = args.output / 'games.jsonl'
    completed = {}
    if data.exists():
        for line in data.read_text().splitlines():
            row = json.loads(line)
            assert row['id'] not in completed, 'Duplicate durable game ID'
            completed[row['id']] = row
    policy = Policy(MODEL79, threads=1, cache_limit=15000)
    started = time.time()
    new = 0
    for number in range(200):
        gid = f'p95-full-s{args.shard}-{number:04d}'
        if gid in completed:
            continue
        white, black = ('p95', 'full') if number % 2 == 0 else ('full', 'p95')
        seed_white = seed + number * 2
        seed_black = seed_white + 1
        rngs = {chess.WHITE: random.Random(seed_white),
                chess.BLACK: random.Random(seed_black)}
        board = chess.Board()
        counts = collections.Counter({key(board): 1})
        begin = time.time()
        moves = []
        while app_outcome(board, counts) is None and board.ply() < 400:
            profile = PROFILES[white if board.turn == chess.WHITE else black]
            move = policy.move(board, profile['top_p'], profile['temperature'],
                               rngs[board.turn])
            assert move in board.legal_moves
            moves.append(move.uci())
            board.push(move)
            counts[key(board)] += 1
        result, termination = app_outcome(board, counts) or ('1/2-1/2', 'max_plies')
        score_white = {'1-0': 1.0, '1/2-1/2': 0.5, '0-1': 0.0}[result]
        row = {
            'id': gid, 'pair_index': 0, 'shard': args.shard, 'number': number,
            'first': 'p95', 'second': 'full', 'white': white, 'black': black,
            'seed_white': seed_white, 'seed_black': seed_black,
            'result': result,
            'score_first': score_white if white == 'p95' else 1 - score_white,
            'termination': termination, 'plies': len(moves), 'moves_uci': moves,
            'seconds': time.time() - begin, 'final_fen': board.fen(),
            'movetext_sha256': hashlib.sha256(' '.join(moves).encode()).hexdigest(),
        }
        # JSON is authoritative; final PGN rebuild removes interrupted orphan entries.
        with (args.output / 'games.pgn').open('a') as file:
            file.write(str(make_pgn(row)) + '\n\n')
            file.flush()
        with data.open('a') as file:
            file.write(json.dumps(row, separators=(',', ':')) + '\n')
            file.flush()
        completed[gid] = row
        new += 1
        if new % 15 == 0:
            elapsed = time.time() - started
            print(json.dumps({
                'shard': args.shard, 'completed': len(completed), 'target': 200,
                'new': new, 'elapsed_seconds': round(elapsed, 1),
                'games_per_hour': round(new * 3600 / elapsed, 1),
                'inference_calls': policy.calls, 'cache_hits': policy.hits,
            }), flush=True)
    assert len(completed) == 200
    with (args.output / 'games.pgn').open('w') as file:
        for row in sorted(completed.values(), key=lambda r: r['number']):
            file.write(str(make_pgn(row)) + '\n\n')
    print(json.dumps({'shard': args.shard, 'complete': len(completed),
                      'seconds_this_run': time.time() - started}), flush=True)


if __name__ == '__main__':
    main()
