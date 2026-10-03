"""Model/fixture/sampler parity and app rule parity before primary outcomes."""
import collections
import json
import re
import subprocess
from pathlib import Path
import chess
import numpy as np
from app_rules import app_outcome, key
from mobile_policy import Policy, MODEL79, distribution, sample, move_index, sha256

ROOT = Path(__file__).resolve().parent
WORKSPACE = ROOT.parents[1]
OLD = WORKSPACE / 'sampling-research-20261002/strength'
assert sha256(ROOT/'mobile_policy.py') == sha256(OLD/'portable/mobile_policy.py')
assert sha256(MODEL79) == '3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010'
fixture = WORKSPACE/'stable25-review/integration_test/fixtures/maia3_reference.dart'
policy = Policy(MODEL79, threads=1)
parity = []
for block in fixture.read_text().split('  Maia3ReferenceCase(')[1:]:
    name = re.search("name: '([^']+)'", block)[1]
    fen = re.search("fen: '([^']+)'", block)[1]
    selfelo = int(re.search(r'selfElo: (\d+)', block)[1])
    oppelo = int(re.search(r'opponentElo: (\d+)', block)[1])
    top = re.search("topMove: '([^']+)'", block)[1]
    board = chess.Board(fen)
    logits = policy.logits(board, selfelo, oppelo)
    expected = dict((m, float(v)) for m, v in re.findall(
        r"'([a-h][1-8][a-h][1-8][qrbn]?)': ([\d.]+)", block))
    errors = [abs(float(logits[move_index(chess.Move.from_uci(m),
                    board.turn == chess.BLACK)]) - v) for m, v in expected.items()]
    assert sample(board, logits, 0, 0).uci() == top
    assert max(errors) < 0.0001
    parity.append({'name': name, 'moves_checked': len(errors), 'max_abs_error': max(errors)})
b = chess.Board()
moves = list(b.legal_moves)
logits = np.full(4352, -100.0, np.float32)
for move, prob in zip(moves[:3], [.55, .30, .15]):
    logits[move_index(move)] = np.log(prob)
assert len(distribution(b, logits, .95, 1)[0]) == 3
assert len(distribution(b, logits, .6, 1)[0]) == 2
assert len(distribution(b, logits, 0, 1)[0]) == 1

cases = []
# Cover every prefix of six already completed prior games, never new primary outcomes.
for i, row in enumerate(map(json.loads, (OLD/'79m-app-draw/games.jsonl').read_text().splitlines()[:6])):
    b = chess.Board()
    counts = collections.Counter({key(b): 1})
    for n in range(len(row['moves_uci']) + 1):
        cases.append({'id': f'prior{i}-ply{n}', 'fen': chess.STARTING_FEN,
                      'moves_uci': row['moves_uci'][:n],
                      'expected': app_outcome(b, counts), 'raw_fen': b.fen(en_passant='fen')})
        if n < len(row['moves_uci']):
            b.push_uci(row['moves_uci'][n]); counts[key(b)] += 1
special = [
    ('fifty', '8/8/8/8/8/7k/R7/K7 w - - 100 75', []),
    ('mate-clock', '7k/6Q1/6K1/8/8/8/8/8 b - - 100 75', []),
    ('stalemate', '7k/5Q2/6K1/8/8/8/8/8 b - - 0 1', []),
    ('bishop-same', '8/8/8/8/2b5/7k/B7/K7 w - - 0 1', []),
    ('knights', '8/8/8/8/8/6nk/N7/K7 w - - 0 1', []),
    ('repeat', chess.STARTING_FEN, ['g1f3','g8f6','f3g1','f6g8']*2),
    ('prospective', chess.STARTING_FEN, ['g1f3','g8f6','f3g1','f6g8','g1f3','g8f6','f3g1']),
]
for name, fen, sequence in special:
    b = chess.Board(fen); counts = collections.Counter({key(b): 1})
    for move in sequence:
        b.push_uci(move); counts[key(b)] += 1
    cases.append({'id': name, 'fen': fen, 'moves_uci': sequence,
                  'expected': app_outcome(b, counts), 'raw_fen': b.fen(en_passant='fen')})
(ROOT/'draw-parity-input.json').write_text(json.dumps(cases, indent=2)+'\n')
command = [str(WORKSPACE/'pr48-flutter-sdk/bin/dart'),
           '--packages='+str(WORKSPACE/'stable25-review/.dart_tool/package_config.json'),
           str(ROOT/'check_dart_rules.dart'), str(ROOT/'draw-parity-input.json')]
completed = subprocess.run(command, capture_output=True, text=True, check=True)
dart = json.loads(completed.stdout)
assert len(cases) == len(dart)
for c, d in zip(cases, dart):
    assert d['id'] == c['id']
    assert d['outcome'] == (list(c['expected']) if c['expected'] else None), (c, d)
    assert d['game_over'] == bool(c['expected']), (c, d)
    assert d['raw_fen'] == c['raw_fen'], (c, d)
(ROOT/'draw-parity-output.json').write_text(json.dumps(dart, indent=2)+'\n')
report = {'status': 'passed', 'portable_helper_byte_identical': True,
          'policy_sha256': sha256(ROOT/'mobile_policy.py'),
          'model_sha256': sha256(MODEL79), 'reference_fixture_sha256': sha256(fixture),
          'official_logits_parity': parity, 'sampler_boundaries': 'passed',
          'dart_raw_fen_and_outcome_cases': len(cases),
          'dart_dependency_sha256': sha256(Path.home() / '.pub-cache/hosted/pub.dev/chess-0.8.1/lib/chess.dart'),
          'dart_command': command}
(ROOT/'preflight.json').write_text(json.dumps(report, indent=2)+'\n')
print(json.dumps(report, indent=2))
