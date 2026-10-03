#!/usr/bin/env python3
"""Independent inference-free full-run outcome, PGN and statistics audit."""
import collections
import hashlib
import json
import math
from pathlib import Path
import chess
import chess.pgn
import numpy as np
from audit_game_snapshot import dart_material, digest, outcome, raw_key

HERE = Path(__file__).resolve().parent
STRENGTH = HERE.parent / 'strength'


def read_rows(path):
    return [json.loads(line) for line in path.read_text().splitlines()]


def elo(score):
    return 400 * math.log10(score / (1 - score))


def independently_score(rows, recorded):
    counts = collections.Counter(r['score_first'] for r in rows)
    score = (counts[1.] + counts[.5] / 2) / len(rows)
    assert (recorded['n'], recorded['wins'], recorded['draws'], recorded['losses']) == (len(rows), counts[1.], counts[.5], counts[0.])
    assert abs(score - recorded['score']) < 1e-12
    assert abs(elo(score) - recorded['elo_difference']) < 1e-10
    assert recorded['bootstrap_replicates'] == 200000
    assert recorded['bootstrap_seed'] == 7000000000
    rng = np.random.default_rng(7000000000)
    samples = np.zeros(200000)
    variances = []
    for white, name in [(True, 'p95_white'), (False, 'p95_black')]:
        subset = [r for r in rows if (r['white'] == 'p95') == white]
        assert len(subset) == 600
        c = collections.Counter(r['score_first'] for r in subset)
        probs = np.array([c[0.], c[.5], c[1.]]) / 600
        resampled_counts = rng.multinomial(600, probs, size=200000)
        samples += (resampled_counts[:, 2] + .5 * resampled_counts[:, 1]) / 1200
        mean = (c[1.] + c[.5] / 2) / 600
        variances.append((probs @ np.array([0., .25, 1.]) - mean ** 2) / 600)
        color = recorded['colors'][name]
        assert (color['wins'], color['draws'], color['losses']) == (c[1.], c[.5], c[0.])
        assert abs(color['score'] - mean) < 1e-12
        assert abs(color['elo_difference'] - elo(mean)) < 1e-10
    limits = np.quantile(samples, [.025, .975])
    assert np.max(np.abs(limits - recorded['score_95_ci'])) < 1e-12
    elo_limits = [elo(s) for s in limits]
    assert max(abs(a - b) for a, b in zip(elo_limits, recorded['elo_difference_95_ci'])) < 1e-10
    for shard in range(6):
        subset = [r for r in rows if r['shard'] == shard]
        c = collections.Counter(r['score_first'] for r in subset)
        rec = recorded['shards'][str(shard)]
        assert (rec['n'], rec['wins'], rec['draws'], rec['losses']) == (200, c[1.], c[.5], c[0.])
        assert abs(rec['score'] - (c[1.] + c[.5] / 2) / 200) < 1e-12
    caps = [r for r in rows if r['termination'] == 'max_plies']
    uncapped = [r for r in rows if r['termination'] != 'max_plies']
    uncapped_total = sum(r['score_first'] for r in uncapped)
    sens = recorded['cap_sensitivity']
    assert sens['cap_games'] == len(caps)
    assert abs(sens['caps_as_p95_win_score'] - (uncapped_total + len(caps)) / 1200) < 1e-12
    assert abs(sens['caps_as_p95_loss_score'] - uncapped_total / 1200) < 1e-12
    if uncapped:
        assert abs(sens['score_excluding_caps'] - uncapped_total / len(uncapped)) < 1e-12
    assert recorded['terminations'] == dict(collections.Counter(r['termination'] for r in rows))
    assert recorded['unique_movetexts'] == len({r['movetext_sha256'] for r in rows})
    assert abs(recorded['plies']['mean'] - sum(r['plies'] for r in rows) / 1200) < 1e-12
    return {'WDL': [counts[1.], counts[.5], counts[0.]], 'score': score,
            'relative_match_elo': elo(score), 'score95_ci': list(map(float, limits)),
            'relative_match_elo95_ci': elo_limits,
            'analytic_standard_error_crosscheck': math.sqrt(sum(variances) / 4),
            'bootstrap_replicates': 200000, 'bootstrap_seed': 7000000000,
            'method': 'Independent reconstruction of multinomial-equivalent game bootstrap within policy color, 50/50 color weight; percentile score CI and monotone logistic Elo transform.',
            'cap_games': len(caps), 'caps_worst_best_score': [sens['caps_as_p95_loss_score'], sens['caps_as_p95_win_score']]}


def verify_pgn(path, rows):
    lookup = {r['id']: r for r in rows}
    seen = set()
    with path.open() as stream:
        while game := chess.pgn.read_game(stream):
            assert not game.errors
            gid = game.headers['StudyGameId']
            assert gid not in seen and gid in lookup
            seen.add(gid)
            row = lookup[gid]
            assert [m.uci() for m in game.mainline_moves()] == row['moves_uci']
            for header, field in [('Result', 'result'), ('Termination', 'termination'), ('WhiteSeed', 'seed_white'), ('BlackSeed', 'seed_black'), ('Shard', 'shard')]:
                assert game.headers[header] == str(row[field])
            assert game.headers['White'] == 'Maia3-79m-' + row['white']
            assert game.headers['Black'] == 'Maia3-79m-' + row['black']
            assert game.headers['WhiteConditioningElo'] == game.headers['BlackConditioningElo'] == '1600'
            assert 'FEN' not in game.headers
    assert seen == set(lookup)
    return len(seen)


def check_final_row(board, row):
    assert board.fen() == row['final_fen']
    assert board.ply() == len(row['moves_uci']) == row['plies']
    assert hashlib.sha256(' '.join(row['moves_uci']).encode()).hexdigest() == row['movetext_sha256']
    white_score = {'1-0': 1., '0-1': 0., '1/2-1/2': .5}[row['result']]
    assert row['score_first'] == (white_score if row['white'] == 'p95' else 1 - white_score)


def primary():
    rows, hashes, all_seeds = [], {}, set()
    for shard in range(6):
        directory = STRENGTH / f'shard{shard}'
        data = read_rows(directory / 'games.jsonl')
        assert len(data) == 200 and sorted(r['number'] for r in data) == list(range(200))
        manifest = json.loads((directory / 'manifest.json').read_text())
        assert manifest['shard'] == shard and manifest['games'] == 200
        assert manifest['model_sha256'] == '3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010'
        assert manifest['profiles'] == {'p95': {'temperature': 1., 'top_p': .95}, 'full': {'temperature': 1., 'top_p': 1.}}
        assert manifest['self_elo'] == manifest['opponent_elo'] == 1600
        assert manifest['book'] is manifest['search'] is manifest['claim_draw'] is False
        for source, field in [('run_matches.py', 'runner'), ('mobile_policy.py', 'policy'), ('app_rules.py', 'app_rules'), ('PROTOCOL.md', 'protocol')]:
            assert manifest[field + '_sha256'] == digest(STRENGTH / source)
        for row in data:
            number = row['number']
            assert row['shard'] == shard and row['pair_index'] == 0
            assert row['id'] == f'p95-full-s{shard}-{number:04d}'
            assert (row['first'], row['second']) == ('p95', 'full')
            assert (row['white'], row['black']) == (('p95', 'full') if number % 2 == 0 else ('full', 'p95'))
            seed = 6000000000 + shard * 1000000 + number * 2
            assert (row['seed_white'], row['seed_black']) == (seed, seed + 1)
            assert not {seed, seed + 1}.intersection(all_seeds)
            all_seeds.update({seed, seed + 1})
            board = chess.Board()
            history = collections.Counter({raw_key(board): 1})
            for uci in row['moves_uci']:
                assert outcome(board, history) is None and board.ply() < 400
                move = chess.Move.from_uci(uci)
                assert move in board.legal_moves
                board.push(move)
                history[raw_key(board)] += 1
            final = outcome(board, history)
            if final is None:
                assert board.ply() == 400
                final = ('1/2-1/2', 'max_plies')
            assert final == (row['result'], row['termination'])
            check_final_row(board, row)
        verify_pgn(directory / 'games.pgn', data)
        hashes[str(shard)] = {filename: digest(directory / filename) for filename in ('manifest.json', 'games.jsonl', 'games.pgn')}
        rows.extend(data)
    assert len(rows) == len({r['id'] for r in rows}) == 1200
    assert len(all_seeds) == 2400 and sum(r['white'] == 'p95' for r in rows) == 600
    integrity = json.loads((STRENGTH / 'integrity.json').read_text())
    assert integrity['status'] == 'passed' and integrity['games'] == integrity['pgn_games'] == 1200
    assert integrity['distinct_rng_seeds'] == 2400
    assert integrity['caps'] == sum(r['termination'] == 'max_plies' for r in rows)
    result = independently_score(rows, json.loads((STRENGTH / 'results-primary.json').read_text()))
    return rows, {'status': 'passed', 'games': 1200, 'pgn_games': 1200,
                  'plies_replayed': sum(r['plies'] for r in rows), 'distinct_ids': 1200,
                  'distinct_seeds': 2400, 'p95_white': 600, 'p95_black': 600,
                  'legality_terminal_timing_result_score_fen_hash_pgn_mismatches': 0,
                  'summary': result, 'input_sha256': hashes}


def sensitivity(primary_rows):
    directory = STRENGTH / 'claim-sensitivity'
    results = STRENGTH / 'results-claim-sensitivity.json'
    if not all(p.exists() for p in [directory / 'games.jsonl', directory / 'games.pgn', directory / 'manifest.json', results]):
        return {'status': 'not_yet_ready'}
    rows = read_rows(directory / 'games.jsonl')
    lookup = {r['id']: r for r in rows}
    assert len(rows) == len(lookup) == 1200
    for original in primary_rows:
        row = lookup[original['id']]
        for field in ('shard', 'number', 'seed_white', 'seed_black', 'white', 'black', 'first', 'second'):
            assert row[field] == original[field]
        board = chess.Board()
        final = board.outcome(claim_draw=True)
        for uci in original['moves_uci']:
            if final is not None:
                break
            move = chess.Move.from_uci(uci)
            assert move in board.legal_moves
            board.push(move)
            final = board.outcome(claim_draw=True)
        assert row['moves_uci'] == original['moves_uci'][:board.ply()]
        assert row['truncated'] == (board.ply() < original['plies'])
        assert (row['app_result'], row['app_termination'], row['app_plies']) == (original['result'], original['termination'], original['plies'])
        if final is not None:
            assert row['result'] == final.result()
            assert row['termination'] == final.termination.name.lower()
        else:
            assert original['termination'] == row['termination'] == 'max_plies'
        check_final_row(board, row)
    verify_pgn(directory / 'games.pgn', rows)
    manifest = json.loads((directory / 'manifest.json').read_text())
    truncated = sum(r['truncated'] for r in rows)
    changed = sum(r['app_result'] != r['result'] for r in rows)
    removed = sum(r['app_plies'] - r['plies'] for r in rows)
    assert (manifest['truncated_games'], manifest['changed_results'], manifest['removed_plies']) == (truncated, changed, removed)
    summary = independently_score(rows, json.loads(results.read_text()))
    return {'status': 'passed', 'games': 1200, 'truncated_games': truncated,
            'changed_results': changed, 'removed_plies': removed, 'summary': summary,
            'input_sha256': {filename: digest(directory / filename) for filename in ('manifest.json', 'games.jsonl', 'games.pgn')},
            'results_sha256': digest(results)}


def main():
    rows, primary_report = primary()
    print('Independent primary replay and statistical reconstruction passed.', flush=True)
    report = {'status': 'passed', 'no_model_inference': True,
              'independent_dart_material_translation': True,
              'primary': primary_report, 'claim_sensitivity': sensitivity(rows),
              'audit_source_sha256': digest(Path(__file__)),
              'independent_rules_source_sha256': digest(HERE / 'audit_game_snapshot.py'),
              'recorded_result_sha256': digest(STRENGTH / 'results-primary.json'),
              'recorded_integrity_sha256': digest(STRENGTH / 'integrity.json'),
              'interpretation': 'Relative match strength conditional on the frozen implementation and protocol; no absolute human Elo calibration. Primary and sensitivity games are correlated and must not be pooled.'}
    (HERE / 'final-audit.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2), flush=True)


if __name__ == '__main__':
    main()
