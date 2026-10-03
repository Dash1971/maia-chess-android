#!/usr/bin/env python3
"""One predeclared p95/full contrast: equally color-weighted game bootstrap."""
import argparse
import collections
import json
import math
from pathlib import Path
import numpy as np
from scipy.stats import binomtest
from mobile_policy import sha256


def elo(score):
    if score <= 0:
        return float('-inf')
    if score >= 1:
        return float('inf')
    return 400 * math.log10(score / (1 - score))


def basic(rows):
    scores = np.array([row['score_first'] for row in rows])
    return {'n': len(rows), 'wins': int((scores == 1).sum()),
            'draws': int((scores == .5).sum()), 'losses': int((scores == 0).sum()),
            'score': float(scores.mean()), 'elo_difference': elo(float(scores.mean()))}


def summarize(rows, bootstraps=200000, seed=7000000000):
    assert len(rows) == 1200
    assert len({r['id'] for r in rows}) == 1200
    assert all((r['first'], r['second']) == ('p95', 'full') for r in rows)
    result = basic(rows)
    rng = np.random.default_rng(seed)
    resampled = []
    colors = {}
    for white in (True, False):
        group = [r for r in rows if (r['white'] == 'p95') == white]
        assert len(group) == 600
        sub = np.array([r['score_first'] for r in group])
        counts = np.array([(sub == score).sum() for score in (0, .5, 1)])
        draws = rng.multinomial(len(group), counts / counts.sum(), size=bootstraps)
        resampled.append((draws[:, 1] * .5 + draws[:, 2]) / len(group))
        colors['p95_white' if white else 'p95_black'] = basic(group)
    samples = (resampled[0] + resampled[1]) * .5
    low, high = np.quantile(samples, [.025, .975])
    result.update({
        'first': 'p95', 'second': 'full',
        'score_95_ci': [float(low), float(high)],
        'elo_difference_95_ci': [elo(float(low)), elo(float(high))],
        'bootstrap_replicates': bootstraps, 'bootstrap_seed': seed,
        'method': 'Resample game scores within first-profile color (multinomial equivalent of independent game bootstrap); equally weight colors; percentile 95% score CI; monotone 400*log10(s/(1-s)) transform. One predeclared contrast. Relative match Elo, not calibrated human Elo.',
        'two_sided_decisive_binomial_p': float(binomtest(
            result['wins'], result['wins'] + result['losses'], .5).pvalue)
            if result['wins'] + result['losses'] else 1.0,
        'colors': colors,
        'shards': {str(shard): basic([r for r in rows if r['shard'] == shard])
                   for shard in range(6)},
        'terminations': dict(collections.Counter(r['termination'] for r in rows)),
        'unique_movetexts': len({r['movetext_sha256'] for r in rows}),
        'plies': {'mean': float(np.mean([r['plies'] for r in rows])),
                  'median': float(np.median([r['plies'] for r in rows])),
                  'minimum': min(r['plies'] for r in rows),
                  'maximum': max(r['plies'] for r in rows)},
        'total_game_seconds': sum(r['seconds'] for r in rows),
    })
    caps = [r for r in rows if r['termination'] == 'max_plies']
    uncapped = [r for r in rows if r['termination'] != 'max_plies']
    result['cap_sensitivity'] = {
        'cap_games': len(caps),
        'score_excluding_caps': basic(uncapped)['score'] if uncapped else None,
        'caps_as_p95_win_score': (sum(r['score_first'] for r in uncapped) + len(caps)) / len(rows),
        'caps_as_p95_loss_score': sum(r['score_first'] for r in uncapped) / len(rows),
    }
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('inputs', nargs='+', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    rows = [json.loads(line) for path in args.inputs for line in path.read_text().splitlines()]
    report = summarize(rows)
    report['inputs'] = [{'path': str(p), 'sha256': sha256(p)} for p in args.inputs]
    report['analysis_sha256'] = sha256(__file__)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
