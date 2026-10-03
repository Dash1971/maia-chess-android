#!/usr/bin/env python3
"""Independently verify prefix coverage, first claim endpoint, raw rows and PGNs."""
import argparse
import collections
import hashlib
import json
from pathlib import Path
import chess
import chess.pgn
from mobile_policy import sha256


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--primary', nargs='+', type=Path, required=True)
    parser.add_argument('--sensitivity', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    primary = {r['id']: r for path in args.primary
               for r in map(json.loads, path.read_text().splitlines())}
    rows = list(map(json.loads, (args.sensitivity/'games.jsonl').read_text().splitlines()))
    assert len(rows) == len(primary) == 1200
    lookup = {r['id']: r for r in rows}
    assert len(lookup) == 1200 and set(lookup) == set(primary)
    for row in rows:
        original = primary[row['id']]
        assert row['moves_uci'] == original['moves_uci'][:row['plies']]
        assert row['app_result'] == original['result']
        assert row['app_termination'] == original['termination']
        assert row['app_plies'] == original['plies']
        assert row['truncated'] == (row['plies'] < original['plies'])
        board = chess.Board()
        for uci in row['moves_uci']:
            assert not board.is_game_over(claim_draw=True)
            move = chess.Move.from_uci(uci)
            assert move in board.legal_moves
            board.push(move)
        outcome = board.outcome(claim_draw=True)
        if outcome:
            assert row['result'] == outcome.result()
            assert row['termination'] == outcome.termination.name.lower()
        else:
            assert board.ply() == 400 and row['termination'] == 'max_plies'
        assert board.fen() == row['final_fen']
        assert board.ply() == row['plies'] == len(row['moves_uci'])
        assert hashlib.sha256(' '.join(row['moves_uci']).encode()).hexdigest() == row['movetext_sha256']
        sw = {'1-0': 1., '0-1': 0., '1/2-1/2': .5}[row['result']]
        assert row['score_first'] == (sw if row['white'] == 'p95' else 1 - sw)
        for field in ('white', 'black', 'seed_white', 'seed_black', 'shard', 'number'):
            assert row[field] == original[field]
    seen = set()
    with (args.sensitivity/'games.pgn').open() as file:
        while game := chess.pgn.read_game(file):
            assert not game.errors
            gid = game.headers['StudyGameId']
            assert gid not in seen
            seen.add(gid)
            row = lookup[gid]
            assert [move.uci() for move in game.mainline_moves()] == row['moves_uci']
            for header, field in [('Result', 'result'), ('Termination', 'termination'),
                                  ('AppResult', 'app_result'), ('AppPlies', 'app_plies'),
                                  ('WhiteSeed', 'seed_white'), ('BlackSeed', 'seed_black')]:
                assert game.headers[header] == str(row[field])
    assert seen == set(primary)
    report = {'status': 'passed', 'games': 1200, 'illegal_moves': 0,
              'first_claim_endpoint_mismatches': 0, 'prefix_mismatches': 0,
              'pgn_json_mismatches': 0, 'truncated_games': sum(r['truncated'] for r in rows),
              'changed_results': sum(r['app_result'] != r['result'] for r in rows),
              'caps': sum(r['termination'] == 'max_plies' for r in rows),
              'terminations': dict(collections.Counter(r['termination'] for r in rows)),
              'verifier_sha256': sha256(__file__)}
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
