#!/usr/bin/env python3
"""Verify this Preview feature's exact offline artwork allowlist and optional APK."""
import argparse
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def require(condition, message):
    # Do not use assert for a release gate: python -O removes assertions.
    if not condition:
        raise ValueError(message)


def file_sha256(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def check(apk=None, *, root=ROOT):
    manifest = json.loads((root / 'docs/board-style-assets.json').read_text())
    package = root / 'third_party/chessground'
    expected = {}
    seen = set()
    for entry in manifest['files']:
        path = entry['path']
        require(path not in seen, 'Duplicate manifest path: ' + path)
        seen.add(path)
        data = (package / path).read_bytes()
        require(hashlib.sha256(data).hexdigest() == entry['sha256'], 'Source hash mismatch: ' + path)
        require(hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest() == entry['upstream_git_blob'], 'Upstream blob mismatch: ' + path)
        if path.startswith('assets/'):
            expected[path] = entry['sha256']
    actual = {p.relative_to(package).as_posix() for p in (package / 'assets').rglob('*') if p.is_file()}
    require(actual == set(expected), 'Asset allowlist mismatch: ' + str(sorted(actual ^ set(expected))))
    included = {p.name for p in (package / 'assets/piece_sets').iterdir()}
    require(included == set(manifest['approved_piece_sets']), 'Piece set allowlist mismatch: ' + str(sorted(included)))
    pubspec = (package / 'pubspec.yaml').read_text()
    for name in included:
        require('    - assets/piece_sets/' + name + '/' in pubspec, 'Missing piece declaration: ' + name)
    for name in manifest['excluded_piece_sets']:
        require('assets/piece_sets/' + name + '/' not in pubspec, 'Excluded piece declaration: ' + name)
    for file, digest in manifest['notice_files'].items():
        require(file_sha256(package / 'notices' / file) == digest, 'Notice hash mismatch: ' + file)
    report = {'asset_files': len(expected), 'approved_piece_sets': len(included),
              'excluded_piece_sets': len(manifest['excluded_piece_sets']),
              'source_asset_bytes': sum((package / path).stat().st_size for path in expected)}
    if apk:
        prefix = 'assets/flutter_assets/packages/chessground/'
        with zipfile.ZipFile(apk) as archive:
            names = archive.namelist()
            require(len(names) == len(set(names)), 'APK has duplicate ZIP entries')
            entries = {p.filename[len(prefix):]: p for p in archive.infolist() if p.filename.startswith(prefix) and not p.is_dir()}
            require(set(entries) == set(expected), 'APK assets differ from allowlist: ' + str(sorted(set(entries) ^ set(expected))))
            for path, entry in entries.items():
                require(hashlib.sha256(archive.read(entry)).hexdigest() == expected[path], 'APK asset hash mismatch: ' + path)
            for file, digest in manifest['notice_files'].items():
                notice = 'assets/flutter_assets/third_party/chessground/notices/' + file
                require(notice in names, 'APK missing licence notice: ' + file)
                require(hashlib.sha256(archive.read(notice)).hexdigest() == digest, 'APK notice hash mismatch: ' + file)
            report.update(apk_bytes=Path(apk).stat().st_size,
                          apk_asset_bytes=sum(p.file_size for p in entries.values()),
                          apk_compressed_asset_bytes=sum(p.compress_size for p in entries.values()),
                          apk_sha256=file_sha256(apk))
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', type=Path)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    result = check(args.apk)
    text = json.dumps(result, indent=2) + '\n'
    if args.output:
        args.output.write_text(text)
    print(text, end='')
