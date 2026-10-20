"""Disk preflight and narrowly scoped release cleanup (standard library only)."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess


REPO = Path(__file__).resolve().parents[1]
GIB = 1024 ** 3
GENERATED = (
    'build', '.dart_tool', '.flutter-plugins-dependencies', 'android/.gradle',
    'android/.cxx', 'android/app/.cxx', 'android/build',
)
MARKER = '.maia-release-scratch.json'
KEY_SUFFIXES = {'.jks', '.keystore', '.p12', '.pfx', '.pem', '.key'}
KEY_NAMES = {'key.properties', 'keystore.properties', 'signing.properties',
             'mobile_maia_android_signing_password', '.env'}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])


def preflight(repo):
    mac = platform.system() == 'Darwin'
    minimum = 25 if mac else 10
    free = shutil.disk_usage(repo).free / GIB
    require(free >= minimum,
            f'Only {free:.1f} GiB free; this host needs at least {minimum} GiB '
            'before starting a build. Clean completed task output first.')
    print(f'Build preflight: {free:.1f} GiB free (minimum {minimum} GiB).')


def init_scratch(repo, scratch):
    # A new, empty directory establishes ownership; existing output cannot be
    # retroactively claimed by dropping a marker into it.
    scratch = scratch.absolute()
    require(not scratch.is_symlink(), 'Scratch must not be a symlink.')
    require('.git' not in scratch.parts, 'Scratch must be outside Git metadata.')
    resolved = scratch.resolve()
    require(repo != resolved and repo not in resolved.parents and
            resolved not in repo.parents, 'Scratch must be outside the source checkout.')
    require(resolved == scratch, 'Scratch parents must not be symlinks; use the resolved path.')
    scratch.mkdir(parents=True, exist_ok=False)
    marker = {'repo': str(repo), 'scratch': str(scratch.resolve()),
              'source_commit': git(repo, 'rev-parse', 'HEAD').decode().strip()}
    (scratch / MARKER).write_text(json.dumps(marker, indent=2) + '\n')
    print(f'Task-owned scratch: {scratch}')


def check_tree(path):
    require(not path.is_symlink(), f'Refusing symlink: {path}')
    entries = [path]
    if path.is_dir():
        # rglob does not follow directory symlinks. shutil.rmtree unlinks them,
        # too, so normal virtualenv links never lead cleanup into a shared SDK.
        entries.extend(path.rglob('*'))
    for entry in entries:
        require(entry.name != '.git', f'Refusing nested Git checkout: {entry}')
        require(entry.suffix.lower() not in KEY_SUFFIXES and
                entry.name not in KEY_NAMES and not entry.name.startswith('.env.'),
                f'Possible signing key or secret must be moved to safe storage: {entry}')


def cleanup_plan(repo, scratch=None):
    require(git(repo, 'rev-parse', '--show-toplevel').decode().strip() == str(repo),
            'Expected the application Git root.')
    # Never remove tracked files, even if somebody changes the ignore rules.
    tracked = git(repo, 'ls-files', '-z', '--', *GENERATED)
    require(not tracked, 'A generated cleanup path contains tracked files.')
    targets = [repo / relative for relative in GENERATED
               if os.path.lexists(repo / relative)]
    if scratch is not None:
        scratch = scratch.absolute()
        require(not scratch.is_symlink(), 'Scratch must not be a symlink.')
        marker = json.loads((scratch / MARKER).read_text())
        require(marker.get('repo') == str(repo) and
                marker.get('scratch') == str(scratch.resolve()),
                'Scratch ownership marker does not match this checkout and path.')
        require(repo != scratch.resolve() and repo not in scratch.resolve().parents,
                'Scratch cleanup must be outside the source checkout.')
        require(scratch.resolve() not in repo.parents,
                'Scratch cannot contain the source checkout.')
        targets.append(scratch)
    for target in targets:
        require(target.resolve() == target,
                f'Refusing path with symlink or non-canonical parent: {target}')
        check_tree(target)
    return targets


def clean(repo, args):
    targets = cleanup_plan(repo, args.scratch)
    report = {'checkout': str(repo),
              'source_commit': git(repo, 'rev-parse', 'HEAD').decode().strip(),
              'mode': 'apply' if args.apply else 'dry-run',
              'targets': [str(path) for path in targets]}
    if args.apply:
        require(args.builds_stopped, 'Stop task builds/emulators, then pass --builds-stopped.')
        require(args.publication_verified or args.abandoned,
                'Verify the published download, or explicitly abandon the build first.')
        require(args.evidence is not None and args.report is not None,
                '--apply requires --evidence and --report outside cleanup targets.')
        for output in (args.evidence, args.report):
            resolved = output.resolve()
            require(all(resolved != path and path not in resolved.parents for path in targets),
                    'Evidence and cleanup report must be outside cleanup targets.')
        evidence = args.evidence.read_bytes()
        require(bool(evidence.strip()), 'Verification evidence must not be empty.')
        require(args.evidence.resolve() != args.report.resolve(),
                'Cleanup report must not overwrite verification evidence.')
        require(not args.report.exists(), 'Cleanup report already exists; use a new path.')
        require(not args.report.is_symlink(), 'Cleanup report must not be a symlink.')
        report.update(reason='published' if args.publication_verified else 'abandoned',
                      evidence=str(args.evidence.resolve()),
                      evidence_sha256=hashlib.sha256(evidence).hexdigest(),
                      free_bytes_before=shutil.disk_usage(repo).free, removed=[])
        args.report.parent.mkdir(parents=True, exist_ok=True)
        # Write the plan before deletion and update after each completed removal.
        args.report.write_text(json.dumps(report, indent=2) + '\n')
        for path in targets:
            check_tree(path)
            if path.is_dir():
                shutil.rmtree(path)
            else:
                path.unlink()
            report['removed'].append(str(path))
            report['free_bytes_after'] = shutil.disk_usage(repo).free
            args.report.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('preflight')
    init = commands.add_parser('init', help='Create a new task-owned bulk output directory.')
    init.add_argument('--scratch', required=True, type=Path)
    cleanup = commands.add_parser('clean', help='Preview cleanup; deletion requires --apply.')
    cleanup.add_argument('--scratch', type=Path)
    cleanup.add_argument('--apply', action='store_true')
    cleanup.add_argument('--builds-stopped', action='store_true')
    reason = cleanup.add_mutually_exclusive_group()
    reason.add_argument('--publication-verified', action='store_true')
    reason.add_argument('--abandoned', action='store_true')
    cleanup.add_argument('--evidence', type=Path)
    cleanup.add_argument('--report', type=Path)
    args = parser.parse_args()
    try:
        if args.command == 'preflight':
            preflight(REPO)
        elif args.command == 'init':
            init_scratch(REPO, args.scratch)
        else:
            clean(REPO, args)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
