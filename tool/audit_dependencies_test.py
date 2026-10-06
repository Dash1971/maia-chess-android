import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.error import HTTPError, URLError

from audit_dependencies import audit, inventory, query, request_osv

PACKAGE = {'ecosystem': 'Pub', 'name': 'example', 'version': '1.0.0'}


class DependencyAuditTest(unittest.TestCase):
    def test_clean_response_and_withdrawn_advisories(self):
        self.assertEqual(query(PACKAGE, lambda _: {})['vulnerabilities'], [])
        self.assertEqual(query(PACKAGE, lambda _: {'vulns': [
            {'id': 'withdrawn', 'withdrawn': '2026-01-01T00:00:00Z'}]})['vulnerabilities'], [])

    def test_vulnerability_and_network_failure_block(self):
        self.assertEqual(audit([PACKAGE], lambda _: {'vulns': [{'id': 'OSV-1'}]})['status'], 'blocked')
        def offline(_):
            raise OSError('offline')
        report = audit([PACKAGE], offline)
        self.assertEqual(report['status'], 'blocked')
        self.assertEqual(report['results'][0]['error'], 'offline')
        def empty_timeout(_):
            raise TimeoutError()
        self.assertEqual(audit([PACKAGE], empty_timeout)['status'], 'blocked')

    def test_malformed_response_blocks(self):
        for response in [None, [], {'error': 'bad'}, {'message': 'bad'},
                         {'vulns': {}}, {'vulns': [{}]}, {'vulns': ['oops']},
                         {'unexpected': 'not an OSV response'}, {'next_page_token': False},
                         {'vulns': [{'id': 'x', 'withdrawn': True}]}]:
            with self.subTest(response=response):
                self.assertEqual(audit([PACKAGE], lambda _: response)['status'], 'blocked')

    def test_all_pages_are_checked_and_repeated_tokens_fail(self):
        calls = []
        def request(payload):
            calls.append(payload.copy())
            return {'next_page_token': 'next'} if len(calls) == 1 else {'vulns': [{'id': 'OSV-2'}]}
        self.assertEqual(query(PACKAGE, request)['vulnerabilities'][0]['id'], 'OSV-2')
        self.assertEqual(calls[1]['page_token'], 'next')
        self.assertEqual(calls[1]['version'], '1.0.0')
        with self.assertRaises(ValueError):
            query(PACKAGE, lambda _: {'next_page_token': 'same'})

    def test_transient_network_errors_retry_but_never_become_success(self):
        for error in [URLError('offline'), HTTPError('url', 503, 'unavailable', {}, None)]:
            with patch('audit_dependencies.urlopen', side_effect=error) as fetch, patch('audit_dependencies.time.sleep'):
                with self.assertRaises((URLError, HTTPError)):
                    request_osv({})
                self.assertEqual(fetch.call_count, 3)
        with patch('audit_dependencies.urlopen', side_effect=HTTPError('url', 400, 'bad', {}, None)) as fetch:
            with self.assertRaises(HTTPError):
                request_osv({})
            self.assertEqual(fetch.call_count, 1)

    def test_inventory_requires_real_release_graph_and_locked_sources(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / 'tool/hardening').mkdir(parents=True)
            (root / 'android/gradle/wrapper').mkdir(parents=True)
            (root / 'android/gradle/wrapper/gradle-wrapper.properties').write_text('distributionUrl=https\\://services.gradle.org/distributions/gradle-9.3.1-all.zip')
            (root / 'tool/requirements-release.txt').write_text('PyYAML==6.0.2\n')
            (root / 'tool/hardening/requirements.txt').write_text('# tools\nchess==1.11.2\n')
            (root / 'android/settings.gradle.kts').write_text(
                'id("com.android.application") version "9.1.0"\n'
                'id("org.jetbrains.kotlin.android") version "2.4.20"')
            lock = {'packages': {'example': {'source': 'hosted',
                'description': {'url': 'https://pub.dev'}, 'version': '1.0.0'},
                'flutter': {'source': 'sdk', 'version': '0.0.0'}}}
            (root / 'pubspec.lock').write_text(json.dumps(lock))
            maven = {'schema': 1, 'configuration': 'releaseRuntimeClasspath',
                'android_plugins': ['package_info_plus', 'shared_preferences_android'], 'packages': [
                {'ecosystem': 'Maven', 'name': 'com.microsoft.onnxruntime:onnxruntime-android', 'version': '1.24.3'}]}
            result = inventory(root, maven)
            self.assertIn(PACKAGE, result)
            self.assertEqual(len(result), 7)
            for bad in [{}, {**maven, 'android_plugins': []}, {**maven, 'android_plugins': ['package_info_plus']},
                        {**maven, 'android_plugins': None}, {**maven, 'packages': []}, {**maven, 'configuration': 'debugRuntimeClasspath'},
                        {**maven, 'packages': [{'ecosystem': 'Maven', 'name': 'other', 'version': '1'}]}]:
                with self.assertRaises(ValueError):
                    inventory(root, bad)
            lock['packages']['example']['source'] = 'path'
            (root / 'pubspec.lock').write_text(json.dumps(lock))
            with self.assertRaises(ValueError):
                inventory(root, maven)
