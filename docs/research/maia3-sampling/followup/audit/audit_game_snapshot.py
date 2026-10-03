#!/usr/bin/env python3
"""Independent, inference-free audit of a frozen first-100 round-robin snapshot."""
import collections
import hashlib
import io
import json
from pathlib import Path
import chess
import chess.pgn

HERE = Path(__file__).resolve().parent
STRENGTH = HERE.parent / 'strength'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def raw_key(board):
    return ' '.join(board.fen(en_passant='fen').split()[:4])


def dart_material(board):
    # Direct translation of chess-0.8.1/lib/chess.dart:849-891, not app_rules.py.
    pieces = list(board.piece_map().items())
    if len(pieces) == 2:
        return True
    if len(pieces) == 3 and any(p.piece_type in (chess.BISHOP, chess.KNIGHT) for _, p in pieces):
        return True
    bishops = [sq for sq, p in pieces if p.piece_type == chess.BISHOP]
    return bool(bishops) and len(pieces) == len(bishops) + 2 and len({(chess.square_rank(sq) + chess.square_file(sq)) % 2 for sq in bishops}) == 1


def outcome(board, history):
    if board.is_checkmate():
        return ('0-1' if board.turn else '1-0', 'checkmate')
    if board.halfmove_clock >= 100:
        return ('1/2-1/2', 'fifty_moves_actual')
    if board.is_stalemate():
        return ('1/2-1/2', 'stalemate')
    if dart_material(board):
        return ('1/2-1/2', 'insufficient_material')
    if max(history.values()) >= 3:
        return ('1/2-1/2', 'threefold_repetition_actual')
    return None


def main():
    snapshot = HERE / 'first100-games.jsonl'
    manifests = {}
    pgn_lookup = {}
    if not snapshot.exists():
        rows = []
        for shard in range(6):
            directory = STRENGTH / f'shard{shard}'
            rows.extend(json.loads(line) for line in (directory / 'games.jsonl').read_text().splitlines())
        # Round-robin game number then worker; independent of outcome and length.
        rows = sorted(rows, key=lambda r: (r['number'], r['shard']))[:100]
        assert len(rows) == 100
        snapshot.write_text(''.join(json.dumps(r, separators=(',', ':')) + '\n' for r in rows))
    rows = [json.loads(line) for line in snapshot.read_text().splitlines()]
    for shard in range(6):
        directory = STRENGTH / f'shard{shard}'
        manifest = json.loads((directory / 'manifest.json').read_text())
        assert manifest['shard'] == shard
        assert manifest['model_sha256'] == '3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010'
        assert manifest['profiles'] == {'p95': {'temperature': 1., 'top_p': .95}, 'full': {'temperature': 1., 'top_p': 1.}}
        assert manifest['games'] == 200 and manifest['total_study_games'] == 1200
        assert manifest['self_elo'] == manifest['opponent_elo'] == 1600
        assert manifest['book'] is manifest['search'] is manifest['claim_draw'] is False
        for source, field in [('run_matches.py', 'runner'), ('mobile_policy.py', 'policy'), ('app_rules.py', 'app_rules'), ('PROTOCOL.md', 'protocol')]:
            assert manifest[field + '_sha256'] == digest(STRENGTH / source)
        manifests[str(shard)] = digest(directory / 'manifest.json')
        # A running worker may have one extra PGN before durable JSON completion.
        stream = io.StringIO((directory / 'games.pgn').read_text())
        while game := chess.pgn.read_game(stream):
            if game.headers.get('StudyGameId') in {r['id'] for r in rows}:
                assert not game.errors
                assert game.headers['StudyGameId'] not in pgn_lookup
                pgn_lookup[game.headers['StudyGameId']] = game
    ids, seeds, moves_checked = set(), set(), 0
    for row in rows:
        shard, number = row['shard'], row['number']
        assert row['id'] == f'p95-full-s{shard}-{number:04d}'
        assert row['id'] not in ids
        ids.add(row['id'])
        assert (row['first'], row['second']) == ('p95', 'full')
        assert (row['white'], row['black']) == (('p95', 'full') if number % 2 == 0 else ('full', 'p95'))
        expected_seed = 6000000000 + shard * 1000000 + 2 * number
        assert (row['seed_white'], row['seed_black']) == (expected_seed, expected_seed + 1)
        assert not seeds.intersection({expected_seed, expected_seed + 1})
        seeds.update({expected_seed, expected_seed + 1})
        board = chess.Board()
        history = collections.Counter({raw_key(board): 1})
        for uci in row['moves_uci']:
            assert outcome(board, history) is None and board.ply() < 400
            move = chess.Move.from_uci(uci)
            assert move in board.legal_moves
            board.push(move)
            history[raw_key(board)] += 1
            moves_checked += 1
        final = outcome(board, history)
        if final is None:
            assert board.ply() == 400
            final = ('1/2-1/2', 'max_plies')
        assert final == (row['result'], row['termination'])
        assert board.fen() == row['final_fen']
        assert board.ply() == len(row['moves_uci']) == row['plies']
        assert hashlib.sha256(' '.join(row['moves_uci']).encode()).hexdigest() == row['movetext_sha256']
        white_score = {'1-0': 1., '0-1': 0., '1/2-1/2': .5}[row['result']]
        assert row['score_first'] == (white_score if row['white'] == 'p95' else 1 - white_score)
        game = pgn_lookup[row['id']]
        assert [move.uci() for move in game.mainline_moves()] == row['moves_uci']
        for header, field in [('Result', 'result'), ('Termination', 'termination'), ('WhiteSeed', 'seed_white'), ('BlackSeed', 'seed_black'), ('Shard', 'shard')]:
            assert game.headers[header] == str(row[field])
        assert game.headers['White'] == 'Maia3-79m-' + row['white']
        assert game.headers['Black'] == 'Maia3-79m-' + row['black']
        assert game.headers['WhiteConditioningElo'] == game.headers['BlackConditioningElo'] == '1600'
        assert 'FEN' not in game.headers
    report = {
        'status': 'passed', 'games': len(rows), 'plies_replayed': moves_checked,
        'selection': 'First 100 durable games sorted by game number then shard; outcome-independent snapshot. Audit only, no interim strength estimate.',
        'per_shard': dict(collections.Counter(r['shard'] for r in rows)),
        'p95_white': sum(r['white'] == 'p95' for r in rows),
        'distinct_ids': len(ids), 'distinct_seeds': len(seeds),
        'legality_terminal_timing_result_score_fen_hash_pgn_mismatches': 0,
        'snapshot_sha256': digest(snapshot), 'manifest_sha256': manifests,
        'audit_source_sha256': digest(Path(__file__)),
        'no_model_inference': True, 'python_chess_version': chess.__version__,
        'dart_material_reference': 'chess-0.8.1/lib/chess.dart:849',
        'dart_dependency_sha256': digest(Path.home() / '.pub-cache/hosted/pub.dev/chess-0.8.1/lib/chess.dart'),
    }
    (HERE / 'first100-audit.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
