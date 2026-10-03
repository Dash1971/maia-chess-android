"""Package only completed, reviewable study artifacts; no environment or model binaries."""
import argparse
import collections
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parent
RUN_COUNTS = {
    '79m-pair0': 600, '79m-pair1': 600, '79m-pair2': 600,
    '5m': 600, '79m-temp-only': 300, '79m-topp-only': 300,
    '79m-app-draw': 1800, '5m-app-draw': 600,
    '79m-single-knob-app-draw': 600,
}


def completed():
    for name, n in RUN_COUNTS.items():
        path = ROOT / 'strength' / name / 'games.jsonl'
        rows = [json.loads(line) for line in path.read_text().splitlines() if line]
        assert len(rows) == n, (name, len(rows), n)
        assert len({r['id'] for r in rows}) == n, (name, 'duplicate IDs')
    rollouts = json.loads((ROOT / 'openings/rollouts.json').read_text())
    counts = collections.Counter(r['setting'] for r in rollouts)
    assert counts == {'argmax': 1, 'app_default': 2000, 'full': 2000}, counts
    assert (ROOT / 'openings/run.json').is_file(), 'Missing completed rollout manifest'
    assert '<!--' not in (ROOT / 'REPORT.md').read_text(), 'Unfilled report placeholders'
    assert (ROOT / 'strength/results-79m.json').is_file(), 'Missing primary analysis'
    followup = ROOT / 'followup'
    rows = [json.loads(line) for i in range(6)
            for line in (followup / 'strength' / f'shard{i}/games.jsonl').read_text().splitlines()]
    assert len(rows) == len({r['id'] for r in rows}) == 1200
    assert collections.Counter(r['shard'] for r in rows) == {i: 200 for i in range(6)}
    assert collections.Counter(r['white'] for r in rows) == {'p95': 600, 'full': 600}
    claims = [json.loads(line) for line in
              (followup / 'strength/claim-sensitivity/games.jsonl').read_text().splitlines()]
    assert len(claims) == 1200 and {r['id'] for r in claims} == {r['id'] for r in rows}
    assert len(json.loads((followup / 'openings/rollouts95.json').read_text())) == 2000
    provenance = json.loads((followup / 'archive-provenance.json').read_text())
    for entry in provenance['files']:
        path = followup / entry['path']
        assert path.stat().st_size == entry['bytes'], entry['path']
        assert hashlib.sha256(path.read_bytes()).hexdigest() == entry['sha256'], entry['path']


def selected_files():
    files = set()
    def add(pattern):
        files.update(p for p in ROOT.glob(pattern) if p.is_file())

    for pattern in ('*.md', '*.py', 'first-move-probabilities.json',
                    'opening-validation.json', 'publication-validation.json', 'publication-integrity.json',
                    'MEASUREMENT-SHA256SUMS',
                    'figures/*.png', 'figures/*.svg', 'figures/*.pdf'):
        add(pattern)
    for pattern in ('strength/*.py', 'strength/*.json', 'strength/*.diff', 'strength/requirements.lock',
                    'strength/portable/*.py', 'strength/portable/*.md',
                    'strength/portable/requirements.lock', 'strength/portable/reference/*'):
        add(pattern)
    for name in RUN_COUNTS:
        for filename in ('games.jsonl', 'games.pgn', 'manifest.json', 'continuation-summary.json'):
            add(f'strength/{name}/{filename}')
    for pattern in ('openings/*.py', 'openings/*.json', 'openings/requirements-lock.txt',
                    'openings/source/lichess_*.json', 'openings/source/lichess_openings.tsv',
                    'openings/source/selection.json', 'openings/source/api-schema-meta.json',
                    'openings/source/book_builder.py', 'openings/source/api.yaml',
                    'openings/source/lichess.rs', 'openings/source/tree-*.json'):
        add(pattern)
    for pattern in ('diagnostics/*.py', 'diagnostics/*.md', 'diagnostics/*.json',
                    'diagnostics/raw.jsonl', 'diagnostics/metrics.csv', 'diagnostics/reproduction-smoke/*.json',
                    'diagnostics/reproduction-smoke/*.jsonl',
                    'diagnostics/reproduction-cached/*.json',
                    'sources/literature/issue14.json',
                    'sources/literature/pr13.json'):
        add(pattern)
    # Preserve only the explicit finalized follow-up evidence and publication conveniences.
    provenance = json.loads((ROOT / 'followup/archive-provenance.json').read_text())
    for entry in provenance['files']:
        files.add(ROOT / 'followup' / entry['path'])
    for filename in ('README.md', 'reproduce.py', 'requirements-cached.txt',
                     'archive-provenance.json', 'RAW-SHA256SUMS',
                     'cached-statistics-reproduction.json', 'strength/check_dart_rules.dart'):
        add('followup/' + filename)
    # These are superseded interim outputs or timing-only experiments, not final evidence.
    excluded = {'diagnostics/summary.json', 'diagnostics/metrics.json',
                'diagnostics/balanced-summary-output.json', 'strength/batch-throughput.json',
                'strength/results-argmax-baseline.json', 'strength/results-temp-only.json',
                'strength/results-5m-methodcheck.json'}
    return sorted((p for p in files if p.relative_to(ROOT).as_posix() not in excluded),
                  key=lambda p: p.relative_to(ROOT).as_posix())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=ROOT / 'mobile-maia-sampling-research.zip')
    parser.add_argument('--check-only', action='store_true')
    args = parser.parse_args()
    completed()
    paths = selected_files()
    sums = []
    for path in paths:
        sums.append(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.relative_to(ROOT).as_posix()}')
    manifest = '\n'.join(sums) + '\n'
    if not args.check_only:
        with zipfile.ZipFile(args.output, 'w', compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
            for path in paths:
                archive.write(path, path.relative_to(ROOT))
            archive.writestr('SHA256SUMS', manifest)
        (ROOT / 'publication-sha256.txt').write_text(
            f'{hashlib.sha256(args.output.read_bytes()).hexdigest()}  {args.output.name}\n')
    print(json.dumps({'files': len(paths), 'uncompressed_bytes': sum(p.stat().st_size for p in paths),
                      'output': str(args.output), 'check_only': args.check_only,
                      'archive_bytes': args.output.stat().st_size if args.output.exists() else None}, indent=2))


if __name__ == '__main__':
    main()
