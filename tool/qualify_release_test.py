import copy
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

from qualify_release import (PACKAGE, REPOSITORY, SIGNER, check_ci, check_fdroid_log,
                             check_recipe, check_review, check_signer, check_version_history, qualify)
from release_common import file_digest

SHA = 'a' * 40
OTHER = 'b' * 40
NOW = datetime(2026, 10, 4, tzinfo=timezone.utc)


def review():
    return {'source_commit': SHA, 'checked_at': NOW.isoformat(),
            'listing_matches_app': True, 'source_publication_reviewed': True,
            'upstream_status': 'blocked', 'failed_version_codes': [77],
            'upstream_evidence_url': 'https://gitlab.com/fdroid/fdroiddata/-/merge_requests/50992',
            'notes': 'Retained failed older build needs inspection.', 'test_scope': 'Host tests.'}


def canonical():
    return {'RepoType': 'git', 'Repo': f'https://github.com/{REPOSITORY}.git',
            'Binaries': 'https://example.org/v%v.apk', 'AllowedAPKSigningKeys': [SIGNER],
            'AutoUpdateMode': 'Version', 'UpdateCheckMode': 'Tags', 'UpdateCheckData': 'pinned pattern',
            'Builds': [{'versionName': '2.1.3', 'versionCode': 76, 'commit': OTHER,
                        'build': ['flutter build apk'], 'scandelete': ['.pub-cache']}]}


def candidate():
    result = canonical()
    build = copy.deepcopy(result['Builds'][-1])
    build.update(versionName='2.2.2', versionCode=79, commit=SHA)
    result['Builds'].append(build)
    result.update(CurrentVersion='2.2.2', CurrentVersionCode=79)
    return result


def ci():
    return {'head_sha': SHA, 'repository': {'full_name': REPOSITORY},
            'path': '.github/workflows/checks.yml', 'event': 'workflow_dispatch',
            'status': 'completed', 'conclusion': 'success', 'html_url': 'https://example.org/run'}


def log():
    return '\n'.join(['Scanning source for common problems...',
                      f'Successfully built {PACKAGE}:79 from {SHA}',
                      'Scanning APK with dexdump for known non-free classes.',
                      'Scanning APK for extra signing blocks.', '1 build succeeded'])


class QualificationChecksTest(unittest.TestCase):
    def test_ci_requires_exact_source_workflow_repository_and_success(self):
        jobs = [{'name': n, 'conclusion': 'success'} for n in ['test', 'android']]
        check_ci(ci(), jobs, SHA)
        for key, value in [('head_sha', OTHER), ('path', 'other.yml'),
                           ('event', 'pull_request'), ('status', 'in_progress'),
                           ('conclusion', 'failure'), ('repository', {'full_name': 'other/repo'})]:
            with self.subTest(key=key):
                bad = ci(); bad[key] = value
                with self.assertRaises(ValueError):
                    check_ci(bad, jobs, SHA)

    def test_missing_skipped_failed_and_duplicate_jobs_fail(self):
        for jobs in [[], [{'name': 'test', 'conclusion': 'success'}],
                     [{'name': 'test', 'conclusion': 'success'}, {'name': 'android', 'conclusion': 'skipped'}],
                     [{'name': 'test', 'conclusion': 'failure'}, {'name': 'android', 'conclusion': 'success'}],
                     [{'name': 'test', 'conclusion': 'success'}] * 2 + [{'name': 'android', 'conclusion': 'success'}]]:
            with self.subTest(jobs=jobs), self.assertRaises(ValueError):
                check_ci(ci(), jobs, SHA)

    def test_canonical_inheritance_passes_only_identity_changes(self):
        check_recipe(canonical(), candidate(), '2.2.2', 79, SHA)
        for key, value in [('build', ['different command']), ('scandelete', ['docs']),
                           ('scanignore', ['.']), ('disable', 'skip'), ('commit', OTHER),
                           ('versionName', 'wrong')]:
            with self.subTest(key=key):
                bad = candidate(); bad['Builds'][-1][key] = value
                with self.assertRaises(ValueError):
                    check_recipe(canonical(), bad, '2.2.2', 79, SHA)

    def test_recipe_rejects_disabled_canonical_and_duplicate_candidate(self):
        bad = canonical(); bad['Builds'][-1]['disable'] = 'broken'
        with self.assertRaises(ValueError):
            check_recipe(bad, candidate(), '2.2.2', 79, SHA)
        bad = candidate(); bad['Builds'].append(bad['Builds'][-1])
        with self.assertRaises(ValueError):
            check_recipe(canonical(), bad, '2.2.2', 79, SHA)

    def test_recipe_preserves_binary_signer_update_fields_and_version(self):
        for key in ['Repo', 'RepoType', 'Binaries', 'AllowedAPKSigningKeys',
                    'AutoUpdateMode', 'UpdateCheckMode', 'UpdateCheckData',
                    'CurrentVersion', 'CurrentVersionCode']:
            with self.subTest(key=key):
                bad = candidate(); bad[key] = 'wrong'
                with self.assertRaises(ValueError):
                    check_recipe(canonical(), bad, '2.2.2', 79, SHA)

    def test_recipe_rejects_global_disable_and_unrelated_build_changes(self):
        bad = candidate(); bad['Disabled'] = 'do not publish'
        with self.assertRaisesRegex(ValueError, 'Non-build metadata'):
            check_recipe(canonical(), bad, '2.2.2', 79, SHA)
        bad = candidate(); bad['Builds'][0]['build'] = ['changed older build']
        with self.assertRaisesRegex(ValueError, 'unrelated build blocks'):
            check_recipe(canonical(), bad, '2.2.2', 79, SHA)
        bad = candidate(); bad['Builds'].insert(1, {**bad['Builds'][0], 'versionCode': 77})
        with self.assertRaisesRegex(ValueError, 'unrelated build blocks'):
            check_recipe(canonical(), bad, '2.2.2', 79, SHA)

    def test_scan_evidence_requires_exact_source_both_scans_and_success(self):
        check_fdroid_log(log(), SHA, 79, '0\n')
        for bad, status in [(log().replace(SHA, OTHER), '0'), (log(), '1'),
                            (log() + '\nERROR: scan failed', '0')]:
            with self.subTest(log=bad, status=status), self.assertRaises(ValueError):
                check_fdroid_log(bad, SHA, 79, status)
        for line in log().splitlines():
            with self.subTest(missing=line), self.assertRaises(ValueError):
                check_fdroid_log(log().replace(line, ''), SHA, 79, '0')

    def test_blocked_upstream_is_disclosed_not_misreported_clear(self):
        check_review(review(), SHA, NOW)
        bad = review(); bad['upstream_status'] = 'clear'
        with self.assertRaises(ValueError):
            check_review(bad, SHA, NOW)
        bad['failed_version_codes'] = []
        check_review(bad, SHA, NOW)

    def test_review_requires_fresh_timezone_and_matching_source(self):
        for key, value in [('source_commit', OTHER), ('listing_matches_app', False),
                           ('source_publication_reviewed', False), ('notes', ''),
                           ('test_scope', ''), ('upstream_evidence_url', ''),
                           ('failed_version_codes', '77'), ('upstream_status', 'published'),
                           ('checked_at', NOW.replace(tzinfo=None).isoformat()),
                           ('checked_at', (NOW - timedelta(hours=25)).isoformat()),
                           ('checked_at', (NOW + timedelta(hours=1)).isoformat())]:
            with self.subTest(key=key, value=value):
                bad = review(); bad[key] = value
                with self.assertRaises(ValueError):
                    check_review(bad, SHA, NOW)

    def test_certificate_requires_exactly_one_allowed_signer(self):
        valid = f'Signer #1 certificate SHA-256 digest: {SIGNER}\n'
        check_signer(valid)
        for signature in ['', valid.replace(SIGNER, '0' * 64),
                          valid + valid.replace('#1', '#2')]:
            with self.subTest(signature=signature), self.assertRaises(ValueError):
                check_signer(signature)

    def test_version_codes_increase_and_existing_tags_are_immutable(self):
        latest = {'tag_name': 'v2.2.1', 'assets': []}
        check_version_history('2.2.2', 79, SHA, 'signedhash', latest, 'version: 2.2.1+78', None)
        for code, tag_commit in [(78, None), (77, None), (79, OTHER)]:
            with self.subTest(code=code, tag_commit=tag_commit), self.assertRaises(ValueError):
                check_version_history('2.2.2', code, SHA, 'signedhash', latest, 'version: 2.2.1+78', tag_commit)

    def test_requalification_never_accepts_replacing_published_apk(self):
        latest = {'tag_name': 'v2.2.2', 'assets': [{'name': 'Mobile-Maia-v2.2.2.apk', 'digest': 'sha256:signedhash'}]}
        check_version_history('2.2.2', 79, SHA, 'signedhash', latest, 'version: 2.2.2+79', SHA)
        for code, digest, tag_commit in [(80, 'signedhash', SHA), (79, 'replacement', SHA),
                                         (79, 'signedhash', None)]:
            with self.subTest(code=code, digest=digest), self.assertRaises(ValueError):
                check_version_history('2.2.2', code, SHA, digest, latest, 'version: 2.2.2+79', tag_commit)

    def test_cli_never_overwrites_existing_output_or_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'evidence.json'
            path.write_text('{}')
            result = subprocess.run([sys.executable, str(Path(__file__).with_name('qualify_release.py')),
                                     '--evidence', str(path), '--output', str(path)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(path.read_text(), '{}')

    def test_cli_writes_failed_report_for_malformed_evidence(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'evidence.json'; path.write_text('{broken')
            output = Path(directory) / 'result.json'
            result = subprocess.run([sys.executable, str(Path(__file__).with_name('qualify_release.py')),
                                     '--evidence', str(path), '--output', str(output)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertEqual(json.loads(output.read_text())['status'], 'failed')


class QualificationWiringTest(unittest.TestCase):
    """Synthetic files; mock external services/SDK only. Never presented as APK qualification."""
    def setUp(self):
        import yaml
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.evidence = {'schema': 1, 'source_commit': SHA, 'ci_run_id': 42,
                         'canonical_fdroiddata_commit': OTHER, 'fdroidserver_commit': OTHER,
                         'buildserver_image': 'registry.gitlab.com/fdroid/fdroidserver@sha256:' + 'c' * 64,
                         'review': {**review(), 'checked_at': datetime.now(timezone.utc).isoformat()}}
        for key in ['ci_unsigned_apk', 'fdroid_unsigned_apk', 'signed_apk']:
            self.evidence[key] = key; (self.root / key).write_bytes(b'unsigned' if key != 'signed_apk' else b'signed')
        for key, value in [('fdroid_recipe', yaml.safe_dump(candidate())), ('fdroid_log', log()),
                           ('fdroid_exit_code', '0')]:
            self.evidence[key] = key; (self.root / key).write_text(value)
        self.args = SimpleNamespace(evidence=self.root / 'evidence.json', sdk_root=None, build_tools_version='36.0.0')
        self.args.evidence.write_text(json.dumps(self.evidence))
        self.ci_hash = file_digest(self.root / 'ci_unsigned_apk')
        self.reconstruction = b'signed'
        self.packaging_called = False

        def external_run(*args, **kwargs):
            if args[0] == 'git':
                if 'rev-parse' in args: return SHA.encode()
                if 'show' in args: return b'version: 2.2.2+79\n'
                if 'log' in args: return b'123'
            if args[:3] == ('gh', 'run', 'download'):
                directory = Path(args[args.index('--dir') + 1])
                (directory / 'apk.json').write_text(json.dumps({'status': 'passed', 'apk_sha256': self.ci_hash}))
                (directory / 'build-environment.txt').write_text(f'source_commit={SHA}\nrunner_os=Linux\nsource_date_epoch=123\n')
                return b''
            raise AssertionError(args)

        def sdk_verify(args):
            self.assertEqual(args.package, PACKAGE)
            self.assertEqual(args.version_name, '2.2.2')
            self.assertEqual(args.version_code, 79)
            self.assertTrue(args.require_signature)
            self.assertEqual(args.allow_change, [])
            self.assertEqual(args.compare, self.root / 'fdroid_unsigned_apk')
            self.packaging_called = True
            return {'signature': f'Signer #1 certificate SHA-256 digest: {SIGNER}\n'}

        def reconstruct(signed, unsigned, output, **kwargs):
            self.assertEqual(Path(unsigned), self.root / 'fdroid_unsigned_apk')
            Path(output).write_bytes(self.reconstruction)

        for target, replacement in [('qualify_release.run', external_run),
                                    ('qualify_release.verify', sdk_verify),
                                    ('apksigcopier.do_copy', reconstruct)]:
            patcher = patch(target, replacement); patcher.start(); self.addCleanup(patcher.stop)
        patcher = patch('qualify_release.check_release_source', return_value=[]); patcher.start(); self.addCleanup(patcher.stop)
        def github(*args):
            if args[0] != 'api':
                return {'jobs': [{'name': name, 'conclusion': 'success'} for name in ['test', 'android']]}
            if '/matching-refs/' in args[1]: return []
            if '/releases/latest' in args[1]: return {'tag_name': 'v2.2.1', 'assets': []}
            if '/contents/' in args[1]:
                import base64
                return {'encoding': 'base64', 'content': base64.b64encode(b'version: 2.2.1+78').decode()}
            return ci()
        patcher = patch('qualify_release.gh_json', side_effect=github)
        patcher.start(); self.addCleanup(patcher.stop)
        from io import BytesIO
        patcher = patch('qualify_release.urlopen', side_effect=lambda *a, **k: BytesIO(yaml.safe_dump(canonical()).encode()))
        patcher.start(); self.addCleanup(patcher.stop)

    def test_full_gate_binds_files_source_ci_recipe_and_signature(self):
        result = qualify(self.args)
        self.assertEqual(result['status'], 'passed')
        self.assertIn('qualified_at', result)
        self.assertIn('qualify_release.py', result['verification_tool_hashes'])
        self.assertTrue(self.packaging_called)
        self.assertEqual(result['operator_review']['upstream_status'], 'blocked')
        self.assertEqual(result['apk_hashes']['signed_apk'], file_digest(self.root / 'signed_apk'))

    def test_missing_file_fails_before_sdk(self):
        (self.root / 'fdroid_log').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing evidence'):
            qualify(self.args)
        self.assertFalse(self.packaging_called)

    def test_actual_unsigned_mismatch_fails(self):
        (self.root / 'fdroid_unsigned_apk').write_bytes(b'wrong build')
        with self.assertRaisesRegex(ValueError, 'does not match CI'):
            qualify(self.args)

    def test_local_file_cannot_replace_ci_artifact(self):
        self.ci_hash = '0' * 64
        with self.assertRaisesRegex(ValueError, 'not the verified artifact'):
            qualify(self.args)

    def test_payload_verification_failure_is_not_waived(self):
        with patch('qualify_release.verify', side_effect=ValueError('wrong model')):
            with self.assertRaisesRegex(ValueError, 'wrong model'):
                qualify(self.args)

    def test_signature_reconstruction_must_be_byte_identical(self):
        self.reconstruction = b'valid payloads but different zip layout'
        with self.assertRaisesRegex(ValueError, 'Signature reconstruction differs'):
            qualify(self.args)

    def test_stale_canonical_metadata_fails(self):
        import yaml
        from io import BytesIO
        changed = canonical(); changed['Builds'][-1]['build'] = ['changed upstream command']
        with patch('qualify_release.urlopen', side_effect=[BytesIO(yaml.safe_dump(canonical()).encode()),
                                                          BytesIO(yaml.safe_dump(changed).encode())]):
            with self.assertRaisesRegex(ValueError, 'Canonical app metadata changed'):
                qualify(self.args)

    def test_evidence_changed_during_checks_fails(self):
        def modified_copy(signed, unsigned, output, **kwargs):
            Path(output).write_bytes(b'signed')
            (self.root / 'ci_unsigned_apk').write_bytes(b'replaced during checks')
        with patch('apksigcopier.do_copy', modified_copy):
            with self.assertRaisesRegex(ValueError, 'Evidence changed'):
                qualify(self.args)
