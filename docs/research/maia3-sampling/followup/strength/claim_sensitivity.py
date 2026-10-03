#!/usr/bin/env python3
"""Truncate app-rule games at earliest prospective standard claim endpoint."""
import argparse
import collections
import hashlib
import json
from pathlib import Path
import chess
from run_matches import make_pgn
from mobile_policy import sha256


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('inputs', nargs='+', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    rows = [json.loads(line) for path in args.inputs for line in path.read_text().splitlines()]
    assert len(rows) == len({r['id'] for r in rows}) == 1200
    args.output.mkdir(parents=True, exist_ok=True)
    updated = []
    for row in rows:
        board = chess.Board()
        outcome = board.outcome(claim_draw=True)
        moves = []
        for uci in row['moves_uci']:
            if outcome is not None:
                break
            board.push_uci(uci); moves.append(uci)
            outcome = board.outcome(claim_draw=True)
        new = dict(row)
        new.update({'app_result': row['result'], 'app_termination': row['termination'],
                    'app_plies': row['plies'], 'truncated': len(moves) < row['plies'],
                    'moves_uci': moves, 'plies': len(moves), 'final_fen': board.fen(),
                    'result': outcome.result() if outcome else row['result'],
                    'termination': outcome.termination.name.lower() if outcome else row['termination'],
                    'movetext_sha256': hashlib.sha256(' '.join(moves).encode()).hexdigest()})
        score_white = {'1-0': 1., '1/2-1/2': .5, '0-1': 0.}[new['result']]
        new['score_first'] = score_white if new['white'] == 'p95' else 1 - score_white
        if outcome is None:
            # An app raw-FEN endpoint is also expected to be a standard terminal.
            assert new['termination'] == 'max_plies' and new['plies'] == 400
        updated.append(new)
    with (args.output/'games.jsonl').open('w') as file:
        for row in updated:
            file.write(json.dumps(row, separators=(',', ':'))+'\n')
    with (args.output/'games.pgn').open('w') as file:
        for row in updated:
            game = make_pgn(row)
            game.headers['Event'] = 'Mobile Maia p95 follow-up standard-claim sensitivity'
            game.headers['AppResult'] = row['app_result']
            game.headers['AppPlies'] = str(row['app_plies'])
            file.write(str(game)+'\n\n')
    manifest = {'study': 'paired claim-draw endpoint sensitivity; same sampled prefixes',
                'games': len(updated), 'claim_draw': True, 'new_inference': False,
                'input_files': [{'path': str(p), 'sha256': sha256(p)} for p in args.inputs],
                'truncated_games': sum(r['truncated'] for r in updated),
                'changed_results': sum(r['app_result'] != r['result'] for r in updated),
                'removed_plies': sum(r['app_plies'] - r['plies'] for r in updated),
                'terminations': dict(collections.Counter(r['termination'] for r in updated)),
                'runner_sha256': sha256(__file__)}
    (args.output/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print(json.dumps(manifest, indent=2))


if __name__ == '__main__':
    main()
