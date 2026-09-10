#!/usr/bin/env python3
"""Verify an ARM64 offline release APK; optionally compare two APK payloads."""
import argparse
from pathlib import Path
import struct
import zipfile

from release_common import (apk_identity, digest, file_digest, require, run,
                            sdk_arguments, sdk_tools, write_report)
from verify_model import MODEL_SHA256, MODEL_SIZE

REPO = Path(__file__).resolve().parents[1]
MODEL_ENTRY = 'assets/flutter_assets/assets/models/maia3-79m.onnx'


def payload_names(names):
    # v1 signing entries differ between otherwise equivalent signed/unsigned
    # APKs. The v2/v3 signing block is outside the ZIP entry payload already.
    return {name for name in names if not (
        name.upper().startswith('META-INF/') and
        (name.upper() == 'META-INF/MANIFEST.MF' or
         name.upper().endswith(('.SF', '.RSA', '.DSA', '.EC'))))}


def elf_alignment(data):
    require(len(data) >= 64 and data[:6] == b'\x7fELF\x02\x01', 'Not a little-endian ELF64 library.')
    require(struct.unpack_from('<H', data, 18)[0] == 183, 'Native library is not ARM64.')
    offset = struct.unpack_from('<Q', data, 32)[0]
    size, count = struct.unpack_from('<HH', data, 54)
    require(size >= 56 and offset + size * count <= len(data), 'Truncated ELF program headers.')
    alignments = []
    for index in range(count):
        header = offset + index * size
        if struct.unpack_from('<I', data, header)[0] != 1:
            continue
        file_offset, virtual_address = struct.unpack_from('<QQ', data, header + 8)
        alignment = struct.unpack_from('<Q', data, header + 48)[0]
        require(alignment >= 16384 and alignment & (alignment - 1) == 0 and
                file_offset % 16384 == virtual_address % 16384,
                'ELF load segment is not 16 KB compatible.')
        alignments.append(alignment)
    require(alignments, 'ELF has no load segments.')
    return alignments


def compare_payloads(candidate, baseline, allowed):
    current = payload_names(candidate.namelist())
    previous = payload_names(baseline.namelist())
    changed = set(current ^ previous)
    for name in current & previous:
        with candidate.open(name) as left, baseline.open(name) as right:
            if digest(left) != digest(right):
                changed.add(name)
    require(not (changed - set(allowed)),
            'Unexpected APK payload changes: ' + ', '.join(sorted(changed - set(allowed))))
    return sorted(changed)


def verify(args):
    _, tools = sdk_tools(args.sdk_root, args.build_tools_version)
    identity = apk_identity(args.apk, tools)
    require(identity['name'] == args.package, 'Unexpected APK package: ' + identity['name'])
    require(not identity['debuggable'], 'APK is debuggable; use a release build.')
    if args.version_name is not None:
        require(identity['versionName'] == args.version_name, 'Unexpected version name.')
    if args.version_code is not None:
        require(int(identity['versionCode']) == args.version_code, 'Unexpected version code.')
    permissions = run(tools / 'aapt2', 'dump', 'permissions', args.apk).decode()
    require('android.permission.INTERNET' not in permissions, 'Release APK requests Internet access.')
    run(tools / 'zipalign', '-c', '-P', '16', '4', args.apk)
    report = {'apk_sha256': file_digest(args.apk), 'bytes': args.apk.stat().st_size,
              'identity': identity, 'no_internet_permission': True, 'zip_alignment': 'passed',
              'signature': 'not requested'}
    if args.require_signature:
        report['signature'] = run(tools / 'apksigner', 'verify', '--verbose', '--print-certs', args.apk).decode()
    with zipfile.ZipFile(args.apk) as apk:
        names = apk.namelist()
        require(len(names) == len(set(names)), 'APK has duplicate ZIP entries.')
        require(apk.testzip() is None, 'APK ZIP checksum failure.')
        require(not any(name.lower().endswith(('.keystore', '.jks', '.p12', '.pfx', '.pgn')) or
                        'variation_oracle' in name or '/test/fixtures/' in name for name in names),
                'APK contains a key or test fixture.')
        require(apk.getinfo(MODEL_ENTRY).file_size == MODEL_SIZE, 'Wrong bundled model size.')
        with apk.open(MODEL_ENTRY) as model:
            report['model_sha256'] = digest(model)
        require(report['model_sha256'] == MODEL_SHA256, 'Bundled model hash mismatch.')
        libraries = {}
        for name in names:
            if not name.endswith('.so'):
                continue
            require(name.startswith('lib/arm64-v8a/'), 'Unexpected native ABI: ' + name)
            data = apk.read(name)
            libraries[name] = elf_alignment(data)
            if name.endswith('/libapp.so'):
                for path in [str(REPO), '/Users/', '/home/runner/work/', *args.forbid_path]:
                    require(path.encode() not in data, 'Dart binary contains a forbidden checkout path.')
        require({'lib/arm64-v8a/' + name for name in (
            'libapp.so', 'libflutter.so', 'libonnxruntime.so', 'libmultistockfish_chess.so')}
            <= libraries.keys(), 'A required native engine/library is missing.')
        report['elf_load_alignments'] = libraries
        report['payload_entries'] = len(payload_names(names))
        if args.compare:
            with zipfile.ZipFile(args.compare) as baseline:
                require(len(baseline.namelist()) == len(set(baseline.namelist())),
                        'Comparison APK has duplicate ZIP entries.')
                require(baseline.testzip() is None, 'Comparison APK ZIP checksum failure.')
                report['changed_payload_entries'] = compare_payloads(apk, baseline, args.allow_change)
            report['comparison_sha256'] = file_digest(args.compare)
    return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    sdk_arguments(parser)
    parser.add_argument('--version-name')
    parser.add_argument('--version-code', type=int)
    parser.add_argument('--require-signature', action='store_true')
    parser.add_argument('--compare', type=Path, help='Default comparison allows no changed payload entries.')
    parser.add_argument('--allow-change', action='append', default=[], help='Exact ZIP entry allowed to change; repeatable.')
    parser.add_argument('--forbid-path', action='append', default=[], help='Additional build path forbidden in libapp.so.')
    parser.add_argument('--output', type=Path, required=True, help='JSON result, including failure reason.')
    args = parser.parse_args()
    if args.allow_change and not args.compare:
        parser.error('--allow-change requires --compare')
    try:
        report = {'status': 'passed', **verify(args)}
    except Exception as error:
        report = {'status': 'failed', 'error': str(error)}
    write_report(args.output, report)
    print(f"APK verification {report['status']}: {args.output}")
    if report['status'] != 'passed':
        parser.exit(1, report['error'] + '\n')


if __name__ == '__main__':
    main()
