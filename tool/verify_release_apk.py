#!/usr/bin/env python3
"""Verify an offline release APK; optionally compare two APK payloads."""
import argparse
from pathlib import Path
import struct
import zipfile

from release_common import (apk_identity, digest, file_digest, require, run,
                            sdk_arguments, sdk_tools, write_report)
from verify_model import MODEL_SHA256, MODEL_SIZE

REPO = Path(__file__).resolve().parents[1]
MODEL_ENTRY = 'assets/flutter_assets/assets/models/maia3-79m.onnx'
ABI_ELF = {
    'armeabi-v7a': (1, 40),
    'arm64-v8a': (2, 183),
    'x86_64': (2, 62),
}


def payload_names(names):
    # v1 signing entries differ between otherwise equivalent signed/unsigned
    # APKs. The v2/v3 signing block is outside the ZIP entry payload already.
    return {name for name in names if not (
        name.upper().startswith('META-INF/') and
        (name.upper() == 'META-INF/MANIFEST.MF' or
         name.upper().endswith(('.SF', '.RSA', '.DSA', '.EC'))))}


def elf_alignment(data, abi='arm64-v8a'):
    require(abi in ABI_ELF, 'Unsupported native ABI: ' + abi)
    elf_class, machine = ABI_ELF[abi]
    require(len(data) >= 52 and data[:4] == b'\x7fELF' and data[4] == elf_class and
            data[5] == 1, f'Native library is not little-endian {abi} ELF.')
    require(struct.unpack_from('<H', data, 18)[0] == machine,
            'Native library architecture does not match ' + abi + '.')
    if elf_class == 2:
        require(len(data) >= 64, 'Truncated ELF64 header.')
        offset = struct.unpack_from('<Q', data, 32)[0]
        size, count = struct.unpack_from('<HH', data, 54)
        minimum_size = 56
    else:
        offset = struct.unpack_from('<I', data, 28)[0]
        size, count = struct.unpack_from('<HH', data, 42)
        minimum_size = 32
    require(size >= minimum_size and offset + size * count <= len(data),
            'Truncated ELF program headers.')
    alignments = []
    for index in range(count):
        header = offset + index * size
        if struct.unpack_from('<I', data, header)[0] != 1:
            continue
        if elf_class == 2:
            file_offset, virtual_address = struct.unpack_from('<QQ', data, header + 8)
            alignment = struct.unpack_from('<Q', data, header + 48)[0]
        else:
            file_offset, virtual_address = struct.unpack_from('<II', data, header + 4)
            alignment = struct.unpack_from('<I', data, header + 28)[0]
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
        observed_abis = set()
        for name in names:
            if not name.endswith('.so'):
                continue
            parts = name.split('/')
            require(len(parts) == 3 and parts[0] == 'lib',
                    'Unexpected native library path: ' + name)
            abi = parts[1]
            require(abi in args.allow_abi, 'Unexpected native ABI: ' + abi)
            observed_abis.add(abi)
            data = apk.read(name)
            libraries[name] = elf_alignment(data, abi)
            if name.endswith('/libapp.so'):
                for path in [str(REPO), '/Users/', '/home/runner/work/', *args.forbid_path]:
                    require(path.encode() not in data, 'Dart binary contains a forbidden checkout path.')
        require(observed_abis == set(args.allow_abi),
                'Native ABI set does not match request: ' + ', '.join(sorted(observed_abis)))
        required = {'libapp.so', 'libflutter.so', 'libonnxruntime.so',
                    'libmultistockfish_chess.so'}
        for abi in args.allow_abi:
            require({'lib/' + abi + '/' + name for name in required} <= libraries.keys(),
                    'A required native engine/library is missing for ' + abi + '.')
        report['elf_load_alignments'] = libraries
        report['native_abis'] = sorted(observed_abis)
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
    parser.add_argument('--allow-abi', action='append', choices=sorted(ABI_ELF),
                        default=[], help='Expected native ABI; repeat for universal APKs.')
    parser.add_argument('--require-signature', action='store_true')
    parser.add_argument('--compare', type=Path, help='Default comparison allows no changed payload entries.')
    parser.add_argument('--allow-change', action='append', default=[], help='Exact ZIP entry allowed to change; repeatable.')
    parser.add_argument('--forbid-path', action='append', default=[], help='Additional build path forbidden in libapp.so.')
    parser.add_argument('--output', type=Path, required=True, help='JSON result, including failure reason.')
    args = parser.parse_args()
    if not args.allow_abi:
        args.allow_abi = ['arm64-v8a']
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
