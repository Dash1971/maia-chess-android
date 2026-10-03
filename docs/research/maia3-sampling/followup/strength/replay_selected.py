#!/usr/bin/env python3
"""Predeclared exact seeded replay: local games 0 and 1 in every shard."""
import argparse
import collections
import json
import random
import time
from pathlib import Path
import chess
from app_rules import app_outcome, key
from mobile_policy import Policy, MODEL79, sha256
from run_matches import PROFILES


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('directories', nargs='+', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    policy = Policy(MODEL79, threads=1, cache_limit=15000)
    results = []
    begin = time.time()
    for directory in args.directories:
        rows = [json.loads(line) for line in (directory/'games.jsonl').read_text().splitlines()]
        for row in sorted([r for r in rows if r['number'] in [0, 1]], key=lambda r: r['number']):
            board = chess.Board()
            counts = collections.Counter({key(board): 1})
            rngs = {chess.WHITE: random.Random(row['seed_white']),
                    chess.BLACK: random.Random(row['seed_black'])}
            actual = []
            while app_outcome(board, counts) is None and board.ply() < 400:
                profile = PROFILES[row['white'] if board.turn == chess.WHITE else row['black']]
                move = policy.move(board, profile['top_p'], profile['temperature'], rngs[board.turn])
                assert move in board.legal_moves
                actual.append(move.uci()); board.push(move); counts[key(board)] += 1
            assert actual == row['moves_uci'], row['id']
            assert app_outcome(board, counts) == (row['result'], row['termination'])
            results.append({'id': row['id'], 'plies': len(actual), 'result': row['result'],
                            'exact_move_sequence_match': True})
    assert len(results) == 12
    report = {'status': 'passed', 'games_replayed': len(results), 'games': results,
              'seconds': time.time() - begin, 'inference_calls': policy.calls,
              'cache_hits': policy.hits, 'model_sha256': sha256(MODEL79),
              'policy_sha256': sha256(Path(__file__).with_name('mobile_policy.py')),
              'replay_script_sha256': sha256(__file__)}
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
