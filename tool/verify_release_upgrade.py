#!/usr/bin/env python3
"""Test saved-game restoration across two release APKs on a disposable AOSP emulator.

Requires tool/hardening/requirements.txt. APK copies use a temporary test key;
production keys are never accepted. The selected emulator's app data is reset.
"""
import argparse
from collections import Counter
import io
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import tempfile
import time
import xml.etree.ElementTree as ET

import chess.pgn

from release_common import (apk_identity, file_digest, require, run,
                            sdk_arguments, sdk_tools, write_report)

FIXTURE = Path(__file__).resolve().parent / 'hardening/fixtures/duplicate_takebacks.pgn'
PRESERVED = ('uciMoves', 'positions', 'clockHistory', 'whiteMillis', 'blackMillis', 'forcedResult')


class CommentBuilder(chess.pgn.GameBuilder):
    """Retain separate PGN comment blocks instead of joining them into one string."""
    def begin_game(self):
        super().begin_game()
        self.pending_comments = []

    def visit_comment(self, comment):
        node = self.variation_stack[-1]
        if self.in_variation or (node.parent is None and node.is_end()):
            node.comment_parts = [*getattr(node, 'comment_parts', []), comment.strip()]
        else:
            self.pending_comments.append(comment.strip())
        super().visit_comment(comment)

    def visit_move(self, board, move):
        super().visit_move(board, move)
        self.variation_stack[-1].starting_parts = self.pending_comments
        self.pending_comments = []


def parse_pgn(pgn):
    stream = io.StringIO(pgn)
    game = chess.pgn.read_game(stream, Visitor=CommentBuilder)
    require(game is not None and not game.errors, 'Fixture/export is not a legal PGN.')
    require(chess.pgn.read_game(stream) is None, 'Expected a single PGN game.')
    return game


def semantics(pgn):
    game = parse_pgn(pgn)
    notes, leaves = {}, []

    def walk(node, path=()):
        entry = notes.setdefault(path, {'comments': set(), 'starting': set(), 'nags': set()})
        entry['comments'].update(getattr(node, 'comment_parts', []))
        entry['starting'].update(getattr(node, 'starting_parts', []))
        entry['nags'].update(node.nags)
        if not node.variations:
            leaves.append(path)
        for child in node.variations:
            walk(child, (*path, child.move.uci()))

    walk(game)
    return notes, Counter(leaves)


def check_restored(before, after):
    require(after['id'] == before['id'], 'Saved game ID changed.')
    for key in PRESERVED:
        require(after['data'].get(key) == before['data'].get(key), f'Saved {key} changed.')
    for record in (before, after):
        game = parse_pgn(record['data']['pgn'])
        require([move.uci() for move in game.mainline_moves()] == record['data']['uciMoves'],
                'PGN played main line differs from the saved moves.')
        require(game.board().fen(en_passant='fen') == record['data']['positions'][0],
                'PGN starting position differs from the saved position.')
    old_notes, old_paths = semantics(before['data']['pgn'])
    notes, paths = semantics(after['data']['pgn'])
    require(notes == old_notes and paths.keys() == old_paths.keys(),
            'A variation, comment or NAG changed or disappeared.')
    require(all(count == 1 for count in paths.values()), 'Duplicate complete variations remain.')
    require(parse_pgn(before['data']['pgn']).headers['Result'] ==
            parse_pgn(after['data']['pgn']).headers['Result'], 'PGN result changed.')
    return {'distinct_complete_lines': len(paths),
            'duplicate_lines_before': sum(old_paths.values()) - len(old_paths),
            'duplicate_lines_after': 0}


def seed_record(pgn):
    game = parse_pgn(pgn)
    board = game.board()
    positions, moves, history = [board.fen(en_passant='fen')], [], [[900000, 900000]]
    for index, node in enumerate(game.mainline()):
        side = 0 if board.turn else 1
        moves.append(node.move.uci())
        board.push(node.move)
        positions.append(board.fen(en_passant='fen'))
        clocks = history[-1].copy()
        clocks[side] = max(1000, clocks[side] - 137 - index * 11)
        history.append(clocks)
    result = game.headers.get('Result', '*')
    data = {'schema': 1, 'type': 'game', 'recentState': 'completed' if result != '*' else 'incomplete',
            'pgn': pgn, 'positions': positions, 'uciMoves': moves, 'clockHistory': history,
            'whiteMillis': history[-1][0], 'blackMillis': history[-1][1],
            'playerIsWhite': board.turn, 'timePreset': 'custom' if result != '*' else 'unlimited', 'customMinutes': 15,
            'customIncrement': 10, 'elo': 700, 'clockPaused': True}
    if result != '*':
        data['forcedResult'] = result
    return {'version': 1, 'id': 'release-upgrade-fixture',
            'updatedAt': '2000-01-01T00:00:00Z', 'data': data}


def emulator_preflight(shell, allow_reset):
    require(allow_reset, 'Pass --allow-reset-test-app only for a disposable emulator app installation.')
    require(shell('getprop', 'ro.kernel.qemu').strip() == b'1', 'Refusing to modify a physical device.')
    require(shell('getprop', 'ro.debuggable').strip() == b'1', 'Use a root-capable AOSP emulator image.')
    require(shell('getprop', 'ro.product.cpu.abi').strip() == b'arm64-v8a', 'Use an ARM64 emulator.')
    require(shell('getprop', 'sys.boot_completed').strip() == b'1', 'Wait for emulator boot completion.')
    require(shell('getenforce').strip() == b'Enforcing', 'Keep emulator SELinux enforcing.')


def restored_ui_ready(xml, elo, completed):
    labels = [node.get('content-desc', '') + node.get('text', '')
              for node in ET.fromstring(xml).iter('node')]
    return any(f'Maia3 {elo}elo' in label for label in labels) or (
        completed and 'Analysis Board' in labels)


def check_baseline(fixture, before):
    # Natural endings can replace the seed's forced-result marker with null.
    # The chess result must still match; subsequent upgrade comparisons check
    # the baseline app's actual saved representation, including this marker.
    for field in PRESERVED:
        if field != 'forcedResult':
            require(before['data'].get(field) == fixture['data'].get(field),
                    'Baseline did not retain fixture field: ' + field)
    require(parse_pgn(before['data']['pgn']).headers['Result'] ==
            parse_pgn(fixture['data']['pgn']).headers['Result'], 'Baseline changed the game result.')


def verify(args, report):
    def stage(name):
        report['stage'] = name
        print(name, flush=True)

    stage('Checking APKs and emulator')
    sdk, tools = sdk_tools(args.sdk_root, args.build_tools_version)
    adb = sdk / 'platform-tools/adb'
    require(adb.is_file(), 'Android platform-tools/adb is missing.')
    require(re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+', args.package),
            'Invalid Android package name.')
    identities = [apk_identity(apk, tools) for apk in (args.baseline_apk, args.candidate_apk)]
    for identity in identities:
        require(identity['name'] == args.package and not identity['debuggable'],
                'Both inputs must be release APKs of the requested package.')
        require(identity['activity'], 'APK has no launchable activity.')
    require(int(identities[1]['versionCode']) >= int(identities[0]['versionCode']),
            'Candidate version code is lower than baseline; do not bypass Android upgrade rules.')
    fixture = seed_record(args.fixture.read_text(encoding='utf-8'))
    report.update(baseline_sha256=file_digest(args.baseline_apk),
                  candidate_sha256=file_digest(args.candidate_apk), identities=identities,
                  fixture_sha256=file_digest(args.fixture), signing='temporary local test key')

    def command(*parts, timeout=60):
        return run(adb, '-s', args.serial, *parts, timeout=timeout)

    def shell(*parts):
        return command('shell', shlex.join(parts))

    emulator_preflight(shell, args.allow_reset_test_app)
    appdir = '/data/user/0/' + args.package
    sessions = appdir + '/files/sessions'
    targets = ('active.json', 'games/' + fixture['id'] + '.json')

    def read_raw(name='active.json'):
        return command('exec-out', 'cat', sessions + '/' + name)

    def wait_saved(previous):
        deadline = time.monotonic() + args.timeout
        # Neither live nor naturally finished games must rewrite a checkpoint
        # merely on opening. Background the real restored UI to request a save.
        while time.monotonic() < deadline:
            shell('uiautomator', 'dump', '/sdcard/maia-release-check.xml')
            xml = command('exec-out', 'cat', '/sdcard/maia-release-check.xml')
            if restored_ui_ready(xml, fixture['data']['elo'],
                                 fixture['data']['recentState'] == 'completed'):
                (args.output / 'restored-ui.xml').write_bytes(xml)
                (args.output / 'restored-screen.png').write_bytes(command('exec-out', 'screencap', '-p'))
                shell('input', 'keyevent', 'KEYCODE_HOME')
                break
        else:
            raise ValueError('Restored game UI did not appear before timeout.')
        while time.monotonic() < deadline:
            current = json.loads(read_raw())
            if current.get('updatedAt') != previous:
                return current
            time.sleep(.2)
        raise ValueError('App did not persist the restored game before timeout.')

    def launch(identity):
        output = shell('am', 'start', '-W', '-n', args.package + '/' + identity['activity']).decode()
        require('Status: ok' in output, 'Android launch failed: ' + output)
        return output

    java_home = os.environ.get('JAVA_HOME')
    keytool = str(Path(java_home) / 'bin/keytool') if java_home else shutil.which('keytool')
    require(keytool and Path(keytool).is_file(), 'Set JAVA_HOME to JDK 17 or put keytool on PATH.')
    touched = False
    try:
        # No production signing configuration or passwords are read. These
        # temporary signatures test code/data compatibility, not release trust.
        with tempfile.TemporaryDirectory(prefix='maia-upgrade-') as temp:
            stage('Signing temporary APK copies')
            folder = Path(temp)
            key = folder / 'test.keystore'
            run(keytool, '-genkeypair', '-keystore', key, '-storepass', 'android',
                '-keypass', 'android', '-alias', 'release-test', '-keyalg', 'RSA',
                '-keysize', '2048', '-validity', '2', '-dname', 'CN=Disposable release test', '-noprompt')
            signed = []
            for index, apk in enumerate((args.baseline_apk, args.candidate_apk)):
                output = folder / f'{index}.apk'
                run(tools / 'apksigner', 'sign', '--ks', key, '--ks-key-alias', 'release-test',
                    '--ks-pass', 'pass:android', '--key-pass', 'pass:android', '--out', output, apk)
                run(tools / 'apksigner', 'verify', output)
                signed.append(output)
            command('root')
            command('wait-for-device')
            require(shell('id', '-u').strip() == b'0', 'Emulator did not grant adb root.')
            touched = True
            stage('Installing baseline and restoring fixture')
            if ('package:' + args.package) in shell('pm', 'list', 'packages', args.package).decode().splitlines():
                command('uninstall', args.package)
            command('install', '--no-incremental', signed[0], timeout=180)
            launch(identities[0])
            shell('am', 'force-stop', args.package)
            uid = shell('stat', '-c', '%u', appdir).decode().strip()
            context = shell('ls', '-Zd', appdir).decode().split()[0]
            shell('mkdir', '-p', sessions + '/games')
            seed = args.output / 'seed.json'
            write_report(seed, fixture)
            for target in targets:
                command('push', seed, sessions + '/' + target)
            shell('chown', '-R', uid + ':' + uid, sessions)
            shell('chcon', '-R', context, sessions)
            launch(identities[0])
            before = wait_saved(fixture['updatedAt'])
            write_report(args.output / 'before.json', before)
            check_baseline(fixture, before)
            shell('am', 'force-stop', args.package)
            raw = {name: read_raw(name) for name in targets}
            stage('Installing candidate and comparing saved game')
            command('install', '--no-incremental', '-r', signed[1], timeout=180)
            require(all(read_raw(name) == data for name, data in raw.items()),
                    'Android update changed saved files before launch.')
            require(shell('stat', '-c', '%u', appdir).decode().strip() == uid, 'App UID changed during update.')
            command('logcat', '-c')
            report['candidate_launch'] = launch(identities[1])
            after = wait_saved(before['updatedAt'])
            write_report(args.output / 'after.json', after)
            report.update(check_restored(before, after))
            # Archives are snapshots, not live mirrors of the active game.
            # Preserve the original bytes, then exercise restoration of that
            # archived snapshot through the app's normal checkpoint reader.
            archive_raw = read_raw(targets[1])
            require(archive_raw == raw[targets[1]], 'An unopened archived game changed.')
            stage('Restoring archived snapshot')
            shell('am', 'force-stop', args.package)
            archive_source = args.output / 'archived-original.json'
            archive_source.write_bytes(archive_raw)
            command('push', archive_source, sessions + '/active.json')
            shell('chown', uid + ':' + uid, sessions + '/active.json')
            shell('chcon', context, sessions + '/active.json')
            launch(identities[1])
            from_archive = wait_saved(json.loads(archive_raw)['updatedAt'])
            write_report(args.output / 'archive-restored.json', from_archive)
            check_restored(before, from_archive)
            require(from_archive['data']['pgn'] == after['data']['pgn'],
                    'Archived snapshot restores differently from the upgraded active game.')
            stage('Checking force-stop and restart')
            shell('am', 'force-stop', args.package)
            launch(identities[1])
            restored = wait_saved(from_archive['updatedAt'])
            check_restored(after, restored)
            require(restored['data']['pgn'] == after['data']['pgn'], 'Restart changed the corrected PGN.')
            write_report(args.output / 'restarted.json', restored)
            logs = command('logcat', '-d', '-v', 'threadtime')
            (args.output / 'logcat.log').write_bytes(logs)
            require(b'FATAL EXCEPTION' not in logs and b'Unhandled Exception' not in logs,
                    'Crash/exception found in the isolated emulator logcat; inspect logcat.log.')
            report.update(files_unchanged_before_launch=True, archive_preserved=True,
                          archived_snapshot_restored=True,
                          saved_game_preserved=True, restart_pgn_unchanged=True)
    finally:
        if touched:
            # Preserve diagnostics on failure too, without replacing its cause.
            for name, parts in [('screen.png', ('exec-out', 'screencap', '-p')),
                                ('logcat.log', ('logcat', '-d', '-v', 'threadtime'))]:
                try:
                    (args.output / name).write_bytes(command(*parts))
                except Exception as error:
                    report.setdefault('diagnostic_errors', []).append(str(error))
            try:
                shell('am', 'force-stop', args.package)
            except Exception as error:
                report.setdefault('diagnostic_errors', []).append(str(error))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sdk_arguments(parser)
    parser.add_argument('--baseline-apk', type=Path, required=True)
    parser.add_argument('--candidate-apk', type=Path, required=True)
    parser.add_argument('--serial', required=True, help='Explicit disposable ARM64 AOSP emulator ID.')
    parser.add_argument('--fixture', type=Path, default=FIXTURE)
    parser.add_argument('--output', type=Path, required=True, help='New or empty directory for diagnostics.')
    parser.add_argument('--allow-reset-test-app', action='store_true')
    parser.add_argument('--timeout', type=int, default=30, choices=range(1, 61), metavar='SECONDS')
    args = parser.parse_args()
    if args.output.exists() and (not args.output.is_dir() or any(args.output.iterdir())):
        parser.error('Use a new or empty output directory.')
    args.output.mkdir(parents=True, exist_ok=True)
    report = {'status': 'running'}
    try:
        verify(args, report)
        report['status'] = 'passed'
    except Exception as error:
        report.update(status='failed', error=str(error))
    write_report(args.output / 'result.json', report)
    print(f"Upgrade verification {report['status']}: {args.output / 'result.json'}")
    if report['status'] != 'passed':
        parser.exit(1, report['error'] + '\n')


if __name__ == '__main__':
    main()
