#!/usr/bin/env python3
"""Create one complete test environment in already-owned disposable scratch."""
import argparse
from pathlib import Path
import subprocess
import sys
import venv

from release_test_preflight import capacity, owned_scratch


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scratch', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    scratch = owned_scratch(args.scratch)
    capacity(scratch, 2)
    if args.output.resolve() == scratch or scratch in args.output.resolve().parents:
        parser.error('Keep setup evidence outside disposable scratch.')
    env = scratch / 'release-test-venv'
    if env.exists():
        parser.error('Environment already exists; run its preflight instead of replacing active work.')
    # pip --python installs into a pip-free target. pip and its public CA bundle
    # stay in the existing host installation, outside disposable scratch.
    subprocess.run([sys.executable, '-m', 'pip', '--version'], check=True)
    venv.EnvBuilder(with_pip=False).create(env)
    subprocess.run([sys.executable, '-m', 'pip', '--python', str(env), 'install',
                    '-r', str(Path(__file__).with_name('requirements-release-test.txt'))], check=True)
    python = env / ('Scripts/python.exe' if sys.platform == 'win32' else 'bin/python')
    return subprocess.call([str(python), str(Path(__file__).with_name('release_test_preflight.py')),
                            '--scratch', str(scratch), '--output', str(args.output)])


if __name__ == '__main__':
    sys.exit(main())
