#!/usr/bin/env python3
"""Reevaluate the pinned 489 diagnostic requests, or rederive cached summaries.

Never changes the published artifacts or selects replacement game positions.
"""
import argparse
import collections
import contextlib
import hashlib
import importlib.util
import json
import os
import platform
import shutil
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
PORTABLE = HERE.parent / 'strength' / 'portable'
PINNED_RAW = 'a088fbfc43d515c8e3ae39378febcb0098517fe4ee007ca52b0ca2f5f89d77ac'
PINNED_POSITIONS = 'dc6ac6d7ad3f5dec638ddf1d625ec18724966795a759d024562e0154a9d432c7'
PINNED_MODEL = '3454b03ae78baa64a87b345fdb1a457265d912caec531039b074f07eda0d8010'


def sha256(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def derive_summaries(output):
    """Run the preserved summarizers with their output root redirected.

    No Policy instance or chess engine is created. Dependencies still include
    the portable Python requirements because the original modules import them.
    The close-position module runs at import time; supplying an output-root
    __file__ makes its existing HERE expression target only the new directory.
    """
    sys.path.insert(0, str(HERE))
    with (output / 'summary-rederivation.log').open('w') as log:
        with contextlib.redirect_stdout(log):
            balanced = load_module('_diagnostic_balanced_reproduction', HERE / 'summarize_diagnostics.py')
            balanced.HERE = output
            balanced.main()
            close_source = (HERE / 'summarize_close_positions.py').read_text()
            namespace = {'__name__': '_diagnostic_close_reproduction',
                         '__file__': str(output / 'summarize_close_positions.py')}
            exec(compile(close_source, str(HERE / 'summarize_close_positions.py'), 'exec'), namespace)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', type=Path, default=HERE / 'raw.jsonl', help='pinned archived request/evaluation JSONL')
    parser.add_argument('--positions', type=Path, default=HERE / 'positions.json', help='pinned frozen cohort')
    parser.add_argument('--output', type=Path, required=True, help='a new, nonexistent output directory')
    parser.add_argument('--stockfish', type=Path, help='Stockfish executable; required for fresh evaluations')
    parser.add_argument('--limit', type=int, help='first N frozen position/depth requests; smoke tests only')
    parser.add_argument('--cached-only', action='store_true', help='rederive summaries from cached logits/evaluations; needs no model or engine')
    args = parser.parse_args()
    if args.limit is not None and not 1 <= args.limit <= 489:
        parser.error('--limit must be between 1 and 489')
    if args.cached_only and args.limit is not None:
        parser.error('--cached-only rederives the complete study; omit --limit')
    if sha256(args.input) != PINNED_RAW or sha256(args.positions) != PINNED_POSITIONS:
        parser.error('Input hashes differ from the frozen published cohort/request archive')
    raw = [json.loads(line) for line in args.input.read_text().splitlines()]
    positions = json.loads(args.positions.read_text())
    by_id = {p['id']: p for p in positions}
    keys = [(r['position']['id'], r['depth']) for r in raw]
    assert len(raw) == 489 and len(positions) == 453
    assert len(set(keys)) == 489 and len(by_id) == 453
    assert collections.Counter(r['depth'] for r in raw) == {10: 453, 14: 36}
    assert all(r['position'] == by_id[r['position']['id']] for r in raw)
    requests = raw[:args.limit] if args.limit else raw
    model = None
    if not args.cached_only:
        if not os.environ.get('MAIA79_MODEL'):
            parser.error('Set MAIA79_MODEL explicitly to the pinned 79M ONNX file')
        model = Path(os.environ['MAIA79_MODEL']).expanduser().resolve()
        if not model.is_file() or sha256(model) != PINNED_MODEL:
            parser.error('MAIA79_MODEL is missing or does not match the pinned 79M hash')
        if args.stockfish is None or not args.stockfish.is_file():
            parser.error('Supply --stockfish with a valid executable path')
    output = args.output.expanduser().resolve()
    if output == HERE or output.exists():
        parser.error('--output must be a new directory; existing artifacts are never replaced')
    output.mkdir(parents=True)
    shutil.copyfile(args.positions, output / 'positions.json')
    manifest = {'mode': 'cached-summary-rederivation' if args.cached_only else 'fresh-evaluation',
                'frozen_raw_sha256': PINNED_RAW, 'frozen_positions_sha256': PINNED_POSITIONS,
                'frozen_request_count': 489, 'requested_count': len(requests),
                'request_order': 'identical to archived raw.jsonl',
                'model_sha256': PINNED_MODEL, 'self_elo': 1600, 'opponent_elo': 1600,
                'script_sha256': sha256(__file__), 'python': sys.version,
                'platform': platform.platform(), 'portable_policy_sha256': sha256(PORTABLE / 'mobile_policy.py'),
                'summary_script_sha256': sha256(HERE / 'summarize_diagnostics.py'),
                'close_summary_script_sha256': sha256(HERE / 'summarize_close_positions.py')}
    started = time.time()
    if args.cached_only:
        shutil.copyfile(args.input, output / 'raw.jsonl')
        derive_summaries(output)
    else:
        import chess
        import chess.engine
        import numpy as np
        import onnxruntime as ort
        policy_module = load_module('_diagnostic_portable_policy', PORTABLE / 'mobile_policy.py')
        policy = policy_module.Policy(model=model, threads=1)
        stockfish = args.stockfish.resolve()
        engine = chess.engine.SimpleEngine.popen_uci(str(stockfish))
        manifest.update({'stockfish_executable': str(stockfish), 'stockfish_sha256': sha256(stockfish),
                         'engine_id': engine.id, 'threads': 1, 'hash_mb': 64,
                         'multipv': 'all legal moves', 'cp_mate_mapping': 10000,
                         'numpy': np.__version__, 'onnxruntime': ort.__version__, 'chess': chess.__version__})
        (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        completed = []
        try:
            engine.configure({'Threads': 1, 'Hash': 64})
            for request in requests:
                item, depth = request['position'], request['depth']
                board = chess.Board(item['fen'])
                legal = list(board.legal_moves)
                logits = policy.logits(board, self_elo=1600, opponent_elo=1600)
                began = time.time()
                infos = engine.analyse(board, chess.engine.Limit(depth=depth),
                                       multipv=len(legal), game=(item['id'], depth))
                evaluations = {}
                for info in infos:
                    move = info['pv'][0]
                    score = info['score'].pov(board.turn)
                    evaluations[move.uci()] = {'cp': score.score(mate_score=10000), 'mate': score.mate(),
                        'depth': info.get('depth'), 'seldepth': info.get('seldepth'),
                        'nodes': info.get('nodes'), 'time': info.get('time'),
                        'pv_uci': [m.uci() for m in info['pv']]}
                assert set(evaluations) == {m.uci() for m in legal}
                assert all(e['depth'] == depth for e in evaluations.values())
                record = {'position': item, 'depth': depth, 'seconds': time.time() - began,
                          'legal_logits': {m.uci(): float(logits[policy_module.move_index(m, board.turn == chess.BLACK)]) for m in legal},
                          'evaluations': evaluations}
                assert all(np.isfinite(x) for x in record['legal_logits'].values())
                with (output / 'raw.jsonl').open('a') as handle:
                    handle.write(json.dumps(record, separators=(',', ':')) + '\n')
                completed.append((item['id'], depth))
                print(json.dumps({'completed': len(completed), 'target': len(requests), 'position_id': item['id'], 'depth': depth}), flush=True)
        finally:
            engine.quit()
        assert completed == keys[:len(requests)]
        if len(requests) == 489:
            derive_summaries(output)
    manifest['completed'] = True
    manifest['seconds'] = time.time() - started
    manifest['full_study'] = len(requests) == 489
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps({'complete': True, 'output': str(output), 'requests': len(requests),
                      'full_study': len(requests) == 489, 'cached_only': args.cached_only}), flush=True)


if __name__ == '__main__':
    main()
