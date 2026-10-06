#!/usr/bin/env python3
"""Check reviewed shared terminology against the offline Lichess reference.

This detects drift, not translation quality. Review new equivalent concepts and
upstream updates manually; never fetch or change translations during a build.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

from check_localization import LOCALES, catalogs, unique_object


def check(root: Path) -> list[str]:
    try:
        reference = json.loads(
            (root / 'docs/lichess-terminology.json').read_text(),
            object_pairs_hook=unique_object,
        )
        data = catalogs(root)
        if not re.fullmatch(r'[0-9a-f]{40}', reference['revision']):
            return ['Lichess reference must pin a full commit SHA']
        if set(reference['locale_mapping']) != set(LOCALES):
            return ['Lichess reference must cover every supported locale']
        if not reference['entries']:
            return ['Lichess reference is empty']
        errors = []
        for key, entry in reference['entries'].items():
            if not entry['upstream_key'] or set(entry['upstream']) != set(LOCALES):
                errors.append(f'{key}: missing upstream key or locale')
                continue
            if set(entry['adaptations']) - set(LOCALES):
                errors.append(f'{key}: unknown adaptation locale')
            for locale in LOCALES:
                expected = entry['upstream'][locale]
                adaptation = entry['adaptations'].get(locale)
                if adaptation is not None:
                    if not adaptation['reason'].strip():
                        errors.append(f'{locale}.{key}: adaptation needs a reason')
                    expected = adaptation['value']
                if not isinstance(expected, str) or not expected.strip():
                    errors.append(f'{locale}.{key}: missing translation or documented fallback')
                elif data[locale].get(key) != expected:
                    errors.append(f'{locale}.{key}: differs from reviewed Lichess terminology')
        return errors
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as error:
        return [f'Invalid terminology reference: {error}']


if __name__ == '__main__':
    problems = check(Path(__file__).resolve().parents[1])
    if problems:
        raise SystemExit('\n'.join(problems))
    print('Reviewed Lichess terminology matches all 10 catalogs.')
