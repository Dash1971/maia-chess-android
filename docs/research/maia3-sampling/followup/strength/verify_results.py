#!/usr/bin/env python3
"""Replay all raw games and PGNs, including exact seeds and app terminal timing."""
import argparse
import collections
import hashlib
import json
from pathlib import Path
import chess
import chess.pgn
from app_rules import key, app_outcome
from mobile_policy import sha256


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('directories', nargs='+', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    rows = []
    pgn_ids = set()
    source_hashes = []
    for directory in args.directories:
        manifest = json.loads((directory/'manifest.json').read_text())
        data = [json.loads(line) for line in (directory/'games.jsonl').read_text().splitlines()]
        assert len(data) == manifest['games'] == 200
        assert sorted(r['number'] for r in data) == list(range(200))
        assert all(r['shard'] == manifest['shard'] for r in data)
        assert manifest['model_sha256'] == '3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010'
        assert manifest['profiles'] == {'p95': {'temperature': 1.0, 'top_p': .95},
                                        'full': {'temperature': 1.0, 'top_p': 1.0}}
        for filename, label in [('run_matches.py', 'runner'), ('mobile_policy.py', 'policy'),
                                ('app_rules.py', 'app_rules'), ('PROTOCOL.md', 'protocol')]:
            assert manifest[label+'_sha256'] == sha256(Path(__file__).with_name(filename))
        lookup = {r['id']: r for r in data}
        assert len(lookup) == 200
        for row in data:
            assert row['id'] == f"p95-full-s{row['shard']}-{row['number']:04d}"
            assert row['first'] == 'p95' and row['second'] == 'full'
            expected_colors = ('p95', 'full') if row['number'] % 2 == 0 else ('full', 'p95')
            assert (row['white'], row['black']) == expected_colors
            seed = 6000000000 + row['shard'] * 1000000 + 2 * row['number']
            assert row['seed_white'] == seed and row['seed_black'] == seed + 1
            board = chess.Board()
            counts = collections.Counter({key(board): 1})
            for uci in row['moves_uci']:
                assert app_outcome(board, counts) is None, ('post-terminal move', row['id'])
                assert board.ply() < 400
                move = chess.Move.from_uci(uci)
                assert move in board.legal_moves, ('illegal move', row['id'], uci)
                board.push(move); counts[key(board)] += 1
            outcome = app_outcome(board, counts)
            if outcome is None:
                assert board.ply() == 400
                outcome = ('1/2-1/2', 'max_plies')
            assert outcome == (row['result'], row['termination'])
            assert board.fen() == row['final_fen']
            assert board.ply() == row['plies'] == len(row['moves_uci'])
            digest = hashlib.sha256(' '.join(row['moves_uci']).encode()).hexdigest()
            assert digest == row['movetext_sha256']
            score_white = {'1-0': 1., '1/2-1/2': .5, '0-1': 0.}[row['result']]
            assert row['score_first'] == (score_white if row['white'] == 'p95' else 1 - score_white)
        games = []
        with (directory/'games.pgn').open() as file:
            while game := chess.pgn.read_game(file):
                assert not game.errors
                games.append(game)
        assert len(games) == 200
        for game in games:
            gid = game.headers['StudyGameId']
            assert gid not in pgn_ids
            pgn_ids.add(gid)
            row = lookup[gid]
            assert [m.uci() for m in game.mainline_moves()] == row['moves_uci']
            for header, field in [('Result', 'result'), ('Termination', 'termination'),
                                  ('WhiteSeed', 'seed_white'), ('BlackSeed', 'seed_black'),
                                  ('Shard', 'shard')]:
                assert game.headers[header] == str(row[field])
            assert game.headers['White'] == 'Maia3-79m-'+row['white']
            assert game.headers['Black'] == 'Maia3-79m-'+row['black']
            assert game.headers['WhiteConditioningElo'] == game.headers['BlackConditioningElo'] == '1600'
            assert game.headers.get('FEN') is None
        rows.extend(data)
        source_hashes.append({'directory': str(directory),
                              'manifest_sha256': sha256(directory/'manifest.json'),
                              'jsonl_sha256': sha256(directory/'games.jsonl'),
                              'pgn_sha256': sha256(directory/'games.pgn')})
    assert len(rows) == len({r['id'] for r in rows}) == 1200
    assert len({r['shard'] for r in rows}) == 6
    assert sum(r['white'] == 'p95' for r in rows) == 600
    assert sum(r['black'] == 'p95' for r in rows) == 600
    all_seeds = [r[c] for r in rows for c in ('seed_white', 'seed_black')]
    assert len(set(all_seeds)) == 2400
    report = {
        'status': 'passed', 'games': 1200, 'pgn_games': len(pgn_ids),
        'distinct_game_ids': 1200, 'distinct_rng_seeds': 2400,
        'p95_white': 600, 'p95_black': 600, 'illegal_moves': 0,
        'moves_after_terminal': 0, 'result_termination_score_fen_hash_mismatches': 0,
        'pgn_json_mismatches': 0, 'manifest_source_mismatches': 0,
        'unique_complete_movetexts': len({r['movetext_sha256'] for r in rows}),
        'caps': sum(r['termination'] == 'max_plies' for r in rows),
        'terminations': dict(collections.Counter(r['termination'] for r in rows)),
        'source_hashes': source_hashes, 'verifier_sha256': sha256(__file__),
    }
    args.output.write_text(json.dumps(report, indent=2)+'\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
