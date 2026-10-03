#!/usr/bin/env python3
"""Verify immutable evidence and recompute archived match statistics, without inference."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import types

HERE = Path(__file__).resolve().parent


def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def numbers(value, prefix=''):
    if isinstance(value, dict):
        return {p: n for key, item in value.items()
                if key != 'seconds' and not key.endswith('_seconds')
                for p, n in numbers(item, prefix + '/' + key).items()}
    if isinstance(value, list):
        return {p: n for i, item in enumerate(value)
                for p, n in numbers(item, prefix + '/' + str(i)).items()}
    if isinstance(value, (int, float)) and not isinstance(value, bool):
        return {prefix: value}
    return {}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path,
                        help='New directory outside this archive for regenerated statistics')
    parser.add_argument('--check-only', action='store_true')
    parser.add_argument('--hash-only-script', type=Path,
                        help='Run a copied cached opening analysis without importing ONNX Runtime')
    args, script_args = parser.parse_known_args()
    if args.hash_only_script:
        script = args.hash_only_script.resolve()
        assert script.name in {'conditional.py', 'analyze.py', 'diversity.py', 'validate_labels.py'}
        module = types.ModuleType('mobile_policy')
        module.sha256 = sha256
        sys.modules['mobile_policy'] = module
        sys.path.insert(0, str(script.parent))
        sys.argv = [str(script)] + script_args
        runpy.run_path(str(script), run_name='__main__')
        return
    if script_args:
        parser.error('Unknown arguments: ' + ' '.join(script_args))
    receipt = json.loads((HERE / 'archive-provenance.json').read_text())
    entries = receipt['files']
    for entry in entries:
        path = HERE / entry['path']
        assert path.stat().st_size == entry['bytes'], entry['path']
        assert sha256(path) == entry['sha256'], entry['path']
    report = {'status': 'passed', 'raw_files_verified': len(entries), 'inference_calls': 0}
    if args.check_only:
        print(json.dumps(report, indent=2))
        return
    if not args.output:
        parser.error('--output or --check-only is required')
    output = args.output.resolve()
    assert HERE not in output.parents and output != HERE, 'Use an output outside the archive'
    assert not output.exists(), 'Output must be a new directory'
    output.mkdir(parents=True)
    inputs = [HERE / 'strength' / f'shard{i}' / 'games.jsonl' for i in range(6)]
    comparisons = {}
    for name, sources in [('primary', inputs), ('claim-sensitivity', [
            HERE / 'strength/claim-sensitivity/games.jsonl'])]:
        target = output / f'results-{name}.json'
        command = [sys.executable, str(HERE / 'strength/analyze_results.py'),
                   *map(str, sources), '--output', str(target)]
        with (output / f'{name}.log').open('w') as log:
            subprocess.run(command, check=True, stdout=log, stderr=subprocess.STDOUT,
                           env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'})
        recorded = json.loads((HERE / 'strength' / target.name).read_text())
        regenerated = json.loads(target.read_text())
        original, actual = numbers(recorded), numbers(regenerated)
        assert original.keys() == actual.keys()
        maximum = max(abs(original[k] - actual[k]) for k in original)
        assert maximum <= 1e-12, (name, maximum)
        for key in ('first', 'second', 'method', 'terminations'):
            assert recorded[key] == regenerated[key]
        comparisons[name] = {'numeric_values': len(original),
                             'maximum_absolute_difference': maximum,
                             'source_sha256': sha256(HERE / 'strength/analyze_results.py')}
    report['statistics'] = comparisons
    (output / 'cached-reproduction.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
