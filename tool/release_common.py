"""Shared standard-library helpers for local/CI Android release checks."""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess


def require(condition, message):
    if not condition:
        raise ValueError(message)


def run(*args, timeout=120):
    result = subprocess.run([str(arg) for arg in args], stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=timeout, check=False)
    if result.returncode:
        raise RuntimeError(f'{Path(str(args[0])).name} failed ({result.returncode}): '
                           + result.stderr.decode(errors='replace')
                           + result.stdout.decode(errors='replace'))
    return result.stdout


def digest(stream):
    value = hashlib.sha256()
    for block in iter(lambda: stream.read(1024 * 1024), b''):
        value.update(block)
    return value.hexdigest()


def file_digest(path):
    with Path(path).open('rb') as stream:
        return digest(stream)


def sdk_tools(sdk_root, version):
    root = sdk_root or os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    require(root, 'Set ANDROID_HOME or pass --sdk-root.')
    tools = Path(root) / 'build-tools' / version
    for name in ('aapt2', 'apksigner', 'zipalign'):
        require((tools / name).is_file(), f'Missing {tools / name}; install Android build-tools {version}.')
    return Path(root), tools


def apk_identity(apk, build_tools):
    badging = run(build_tools / 'aapt2', 'dump', 'badging', apk).decode()
    package_line = next((line for line in badging.splitlines() if line.startswith('package:')), '')
    identity = dict(re.findall(r"(\w+)='([^']*)'", package_line))
    require(all(key in identity for key in ('name', 'versionCode', 'versionName')),
            f'Cannot read APK identity: {apk}')
    activity = re.search(r"launchable-activity: name='([^']+)'", badging)
    identity['activity'] = activity.group(1) if activity else None
    identity['debuggable'] = 'application-debuggable' in badging
    return identity


def write_report(path, report):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')


def sdk_arguments(parser):
    parser.add_argument('--sdk-root', type=Path, help='Defaults to ANDROID_HOME / ANDROID_SDK_ROOT.')
    parser.add_argument('--build-tools-version', default='36.0.0')
    parser.add_argument('--package', default='com.dash1971.maia_chess.preview')
