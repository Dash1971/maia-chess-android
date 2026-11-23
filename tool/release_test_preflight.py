#!/usr/bin/env python3
"""Check the operator environment before spending time building/testing APKs."""
import argparse
import importlib
import importlib.metadata
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys

from build_workspace import GIB, MARKER, REPO

DEPENDENCIES = {'chess.pgn': 'python-chess', 'yaml': 'PyYAML',
                'apksigcopier': 'apksigcopier', 'click': 'click', 'PIL.Image': 'Pillow'}


def owned_scratch(path):
    path = Path(path).absolute()
    if path.is_symlink() or path.resolve() != path or REPO in path.parents or path in REPO.parents or path == REPO:
        raise ValueError('Use the canonical task scratch outside the checkout.')
    marker = json.loads((path / MARKER).read_text())
    if marker.get('repo') != str(REPO) or marker.get('scratch') != str(path):
        raise ValueError('Scratch belongs to a different checkout/path.')
    return path


def dependencies():
    versions, errors = {}, []
    for module, distribution in DEPENDENCIES.items():
        try:
            imported = importlib.import_module(module)
            if module == 'apksigcopier' and not callable(getattr(imported, 'do_copy', None)):
                raise ImportError('apksigcopier.do_copy is unavailable')
            versions[distribution] = importlib.metadata.version(distribution)
        except (ImportError, importlib.metadata.PackageNotFoundError) as error:
            errors.append(f'{module}: {error}')
    return versions, errors


def capacity(path, growth_gib):
    free = shutil.disk_usage(path).free
    minimum = max(25 if platform.system() == 'Darwin' else 10, growth_gib + 10)
    if free < minimum * GIB:
        raise ValueError(f'Need {minimum:g} GiB free including growth/reserve; have {free / GIB:.1f}.')
    cpus = os.cpu_count() or 1
    load = os.getloadavg()[0] if hasattr(os, 'getloadavg') else None
    return {'freeBytes': free, 'expectedGrowthGiB': growth_gib, 'reserveGiB': 10,
            'cpuCount': cpus, 'loadAverage1m': load,
            'warnings': ['Host is heavily loaded; coordinate existing work or choose another suitable host. '
                         'Do not kill other tasks or relax test timeouts.']
            if load is not None and load > cpus * 2 else []}


def emulator_health(command, expected_avd, package=None):
    """Read-only checks. Never dismiss dialogs, wake devices, reset data or grant URIs."""
    name = command('emu', 'avd', 'name').decode().splitlines()[0].strip()
    if name != expected_avd:
        raise ValueError(f'Expected task AVD {expected_avd!r}; found {name!r}.')
    if command('shell', 'getprop', 'sys.boot_completed').strip() != b'1':
        raise ValueError('Emulator has not completed boot.')
    window = command('shell', 'dumpsys', 'window').decode(errors='replace')
    focus = '\n'.join(line.strip() for line in window.splitlines()
                      if 'mCurrentFocus=' in line or 'mFocusedApp=' in line)
    if 'Application Not Responding' in focus:
        raise ValueError('System ANR dialog holds focus: ' + focus)
    power = command('shell', 'dumpsys', 'power').decode(errors='replace')
    if 'mWakefulness=Awake' not in power:
        raise ValueError('Emulator is not awake; inspect its screen before testing.')
    current = next((line for line in focus.splitlines() if 'mCurrentFocus=' in line), '')
    if not current or 'mCurrentFocus=null' in current:
        raise ValueError('No focused emulator window; wait for a stable screen.')
    if package and package + '/' not in current:
        raise ValueError('Expected app does not have foreground focus: ' + focus)
    return {'avd': name, 'bootCompleted': True, 'awake': True, 'focus': focus}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scratch', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--check-dependencies', action='store_true', help='CI import/API smoke test only.')
    parser.add_argument('--expected-growth-gib', type=float, default=2)
    parser.add_argument('--adb', type=Path)
    parser.add_argument('--serial')
    parser.add_argument('--expected-avd')
    parser.add_argument('--foreground-package', help='Use after launching the app, before clipboard/UI checks.')
    args = parser.parse_args()
    if args.check_dependencies:
        versions, errors = dependencies()
        print(json.dumps({'passed': not errors, 'dependencies': versions, 'errors': errors}, indent=2))
        return 1 if errors else 0
    if not args.scratch or not args.output:
        parser.error('--scratch and --output are required for a host/device preflight.')
    destination, scratch_path = args.output.resolve(), args.scratch.resolve()
    if destination == scratch_path or scratch_path in destination.parents:
        parser.error('Keep the preflight evidence outside disposable scratch.')
    report = {'passed': False}
    try:
        scratch = owned_scratch(args.scratch)
        if args.expected_growth_gib < 0:
            raise ValueError('Expected growth cannot be negative.')
        report['capacity'] = capacity(scratch, args.expected_growth_gib)
        versions, errors = dependencies()
        report['dependencies'] = versions
        if errors:
            raise ValueError('Incomplete release-test environment: ' + '; '.join(errors))
        if any((args.adb, args.serial, args.expected_avd, args.foreground_package)):
            if not all((args.adb, args.serial, args.expected_avd)):
                raise ValueError('Emulator checks require --adb, --serial and --expected-avd together.')
            def command(*parts):
                return subprocess.check_output([str(args.adb), '-s', args.serial, *parts], timeout=20)
            report['emulator'] = emulator_health(command, args.expected_avd, args.foreground_package)
        report['passed'] = True
    except (ValueError, OSError, subprocess.SubprocessError) as error:
        report['error'] = str(error)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
