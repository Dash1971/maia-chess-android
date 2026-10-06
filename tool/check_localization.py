#!/usr/bin/env python3
"""Check catalog parity and translator contracts; generate the review CSV.

This complements Flutter's ICU parser and widget tests. It does not establish
linguistic quality or prove that every runtime error has been localized.
"""
from __future__ import annotations
import argparse
import csv
import json
import re
from pathlib import Path

LOCALES = ('en', 'ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt')
COLUMNS = ('English source', 'Japanese (provisional)', 'Simplified Chinese (provisional)',
           'Korean (provisional)', 'Spanish (provisional)', 'German (provisional)',
           'French (provisional)', 'Russian (provisional)', 'Hindi (provisional)',
           'Brazilian Portuguese (provisional)')
# Product/protocol names and deliberate technical terminology are not prose.
IDENTICAL_ALLOWED = {
    # Shared technical names, brands, or templates containing no English prose.
    'topP': {'ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt'},
    'topPValue': {'ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt'},
    'maiaOpponentRating': {'ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt'},
    'chessnutBattery': {'ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt'},
    'recentGameSummary': {'ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt'},
    'maiaProbabilitySemantics': {'ja', 'zh', 'ko', 'es', 'de', 'fr', 'ru', 'hi', 'pt'},
    # “experimental” shares its spelling in Spanish, Portuguese and English.
    'chessnutExperimental': {'es', 'pt'},
    # Native words/initials that share their spelling with English.
    'start': {'de'},
    'whiteShort': {'de'},
    'licence': {'fr'},
    'minutes': {'fr'},
    'positionNumber': {'fr'},
}
ARGUMENT = re.compile(r'\{([A-Za-z][A-Za-z0-9_]*)(?=\s*[,}])')


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'duplicate JSON key: {key}')
        result[key] = value
    return result


def catalogs(root):
    return {lang: json.loads((root / f'lib/l10n/app_{lang}.arb').read_text(),
                             object_pairs_hook=unique_object) for lang in LOCALES}


def check(root, *, check_csv=True):
    errors = []
    try:
        data = catalogs(root)
    except (OSError, ValueError) as error:
        return [str(error)]
    keys = {key for key in data['en'] if not key.startswith('@')}
    for lang, catalog in data.items():
        actual = {key for key in catalog if not key.startswith('@')}
        if actual != keys:
            errors.append(f'{lang}: missing={sorted(keys - actual)}, extra={sorted(actual - keys)}')
        if catalog.get('@@locale') != lang:
            errors.append(f'{lang}: wrong @@locale')
        for key in sorted(keys & actual):
            message = catalog[key]
            if not isinstance(message, str) or not message.strip():
                errors.append(f'{lang}.{key}: empty/non-string message')
                continue
            meta = data['en'].get('@' + key, {})
            if not isinstance(meta.get('description'), str) or not meta['description'].strip():
                errors.append(f'en.{key}: missing translator description')
            expected = set(meta.get('placeholders', {}))
            used = set(ARGUMENT.findall(message))
            if expected != used:
                errors.append(f'{lang}.{key}: placeholders {sorted(used)} != {sorted(expected)}')
            if lang != 'en' and message == data['en'][key] and lang not in IDENTICAL_ALLOWED.get(key, set()):
                errors.append(f'{lang}.{key}: untranslated English (or add a justified technical exception)')
    if check_csv:
        try:
            with (root / 'docs/l10n_review.csv').open(newline='') as source:
                rows = list(csv.DictReader(source))
            if len(rows) != len(keys) or {row['ID'] for row in rows} != keys:
                errors.append('review CSV must contain each message exactly once')
            for row in rows:
                for lang, column in zip(LOCALES, COLUMNS):
                    if row.get(column) != data[lang].get(row['ID']):
                        errors.append(f'CSV {lang}.{row["ID"]}: differs from ARB')
        except (OSError, KeyError) as error:
            errors.append(f'review CSV: {error}')
    # No temporary English-string lookup may reappear in production call sites.
    for file in (root / 'lib').rglob('*.dart'):
        if file.name.startswith('app_localizations'):
            continue
        if re.search(r'\bappText\s*\(', file.read_text()):
            errors.append(f'{file.relative_to(root)}: obsolete English-text lookup')
    return errors


def write_review(root):
    data = catalogs(root)
    path = root / 'docs/l10n_review.csv'
    previous = {}
    if path.exists():
        with path.open(newline='') as source:
            previous = {row['ID']: row for row in csv.DictReader(source)}
    fields = ['ID', 'Screen / context', *COLUMNS, 'Used in source',
              'Screenshot link', 'Reviewer suggestion', 'Review status']
    source_files = [(p, p.read_text().splitlines()) for p in (root / 'lib').rglob('*.dart')
                    if not p.name.startswith('app_localizations')]
    with path.open('w', newline='') as target:
        writer = csv.DictWriter(target, fieldnames=fields, lineterminator='\n')
        writer.writeheader()
        for key in data['en']:
            if key.startswith('@'):
                continue
            row = {field: previous.get(key, {}).get(field, '') for field in fields}
            row['ID'] = key
            row['Screen / context'] = data['en'].get('@' + key, {}).get('description', '')
            changed = any(row[column] != data[lang][key] for lang, column in zip(LOCALES, COLUMNS))
            for lang, column in zip(LOCALES, COLUMNS):
                row[column] = data[lang][key]
            usage = re.compile(r'\.' + re.escape(key) + r'\b')
            row['Used in source'] = '; '.join(f'{p.relative_to(root)}:{i}'
                for p, lines in source_files for i, line in enumerate(lines, 1) if usage.search(line))
            if changed or not row['Review status']:
                row['Review status'] = 'Needs native review'
            writer.writerow(row)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--write-review', action='store_true')
    args = parser.parse_args()
    if args.write_review:
        write_review(args.root)
    errors = check(args.root)
    for error in errors:
        print(error)
    if errors:
        return 1
    count = sum(not key.startswith('@') for key in catalogs(args.root)['en'])
    print(f'Localization contracts pass: {count} messages in {len(LOCALES)} catalogs.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
