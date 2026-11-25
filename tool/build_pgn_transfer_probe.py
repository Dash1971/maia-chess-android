#!/usr/bin/env python3
"""Build the synthetic share/clipboard receiver in fresh task output, never a production APK."""
import argparse
import json
import os
import re
from pathlib import Path
import subprocess
import zipfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk-root', required=True, type=Path)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--debug-keystore', required=True, type=Path)
    parser.add_argument('--android-api', type=int, default=36,
                        help='Installed Android platform API (36 or newer; default: 36).')
    parser.add_argument('--build-tools-version', default='36.0.0',
                        help='Exact installed build-tools version (default: 36.0.0).')
    args = parser.parse_args()
    if args.android_api < 36:
        parser.error('Use Android API 36 or newer for the target-36 probe.')
    if not re.fullmatch(r'[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.]+)?', args.build_tools_version):
        parser.error('Use an exact Android build-tools version, not a path.')
    sdk, out, key = args.sdk_root.resolve(), args.output.resolve(), args.debug_keystore.resolve()
    if not key.is_file() or key.is_relative_to(out):
        parser.error('Use the existing shared Android debug keystore outside task output.')
    if out.exists():
        parser.error('Use a fresh task-owned output directory; do not adopt existing output.')
    java_home = os.environ.get('JAVA_HOME', '').strip()
    if not java_home:
        parser.error('Set JAVA_HOME to the existing shared JDK installation.')
    java = Path(java_home).expanduser().resolve() / 'bin'
    source = Path(__file__).resolve().parent / 'hardening/android_release'
    platform = sdk / f'platforms/android-{args.android_api}/android.jar'
    tools = sdk / 'build-tools' / args.build_tools_version
    for p in [java / 'javac', platform, tools / 'aapt2', tools / 'd8', tools / 'zipalign', tools / 'apksigner']:
        if not p.is_file(): parser.error('Required shared tool is absent: ' + str(p))
    out.mkdir(parents=True)
    classes, dex = out / 'classes', out / 'dex'
    classes.mkdir(); dex.mkdir()
    def run(*args): subprocess.run([str(a) for a in args], check=True)
    run(java / 'javac', '-source', '8', '-target', '8', '-Xlint:-options', '-cp', platform,
        '-d', classes, source / 'ProbeActivity.java')
    run(tools / 'd8', '--lib', platform, '--output', dex,
        classes / 'org/mobilemaia/releaseprobe/ProbeActivity.class')
    run(tools / 'aapt2', 'link', '-I', platform, '--manifest', source / 'ProbeManifest.xml',
        '-o', out / 'unsigned.apk')
    with zipfile.ZipFile(out / 'unsigned.apk', 'a') as archive:
        archive.write(dex / 'classes.dex', 'classes.dex')
    run(tools / 'zipalign', '-p', '-f', '4', out / 'unsigned.apk', out / 'aligned.apk')
    run(tools / 'apksigner', 'sign', '--ks', key, '--ks-key-alias', 'androiddebugkey',
        '--ks-pass', 'pass:android', '--out', out / 'probe.apk', out / 'aligned.apk')
    run(tools / 'apksigner', 'verify', out / 'probe.apk')
    (out / 'fixture.json').write_text(json.dumps({
        'package': 'org.mobilemaia.releaseprobe', 'minSdk': 30, 'targetSdk': 36,
        'syntheticFixtureOnly': True, 'productionSigningKeyUsed': False,
        'debugKeystoreCopied': False, 'sharedToolsReused': True,
    }, indent=2) + '\n')


if __name__ == '__main__': main()
