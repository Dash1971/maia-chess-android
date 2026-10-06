#!/usr/bin/env python3
"""Fail-closed OSV audit of locked Pub/Python and resolved Android dependencies.

No changes to dependencies, ignores or app behavior. See docs/RELEASING.md for
coverage limits and the separate upstream/native toolchain review.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import time

import yaml

ROOT = Path(__file__).resolve().parents[1]
ENDPOINT = 'https://api.osv.dev/v1/query'


def inventory(root, maven):
    lock = yaml.safe_load((root / 'pubspec.lock').read_text())
    packages = []
    for name, item in lock['packages'].items():
        if item['source'] == 'sdk':
            continue  # Flutter/Dart are reviewed separately, not Pub packages.
        if item['source'] != 'hosted' or item['description']['url'] != 'https://pub.dev':
            raise ValueError(f'Unreviewed dependency source: {name}')
        packages.append(dict(ecosystem='Pub', name=name, version=item['version']))
    if not packages:
        raise ValueError('Empty Pub lockfile')
    if maven.get('schema') != 1 or maven.get('configuration') != 'releaseRuntimeClasspath':
        raise ValueError('Expected resolved releaseRuntimeClasspath inventory')
    plugins = maven.get('android_plugins')
    if not isinstance(plugins, list) or not all(isinstance(p, str) for p in plugins) or not {
        'package_info_plus', 'shared_preferences_android'
    }.issubset(plugins):
        raise ValueError('Android inventory is missing the app plugin graph')
    android = maven.get('packages')
    if not isinstance(android, list) or not android:
        raise ValueError('Empty Android inventory')
    if not any(p.get('name') == 'com.microsoft.onnxruntime:onnxruntime-android' for p in android):
        raise ValueError('Android inventory is missing ONNX Runtime')
    for p in android:
        if p.get('ecosystem') != 'Maven':
            raise ValueError('Unexpected Android ecosystem')
    packages += android
    # Auditing tools are not APK dependencies, but execute in release CI.
    for filename in ('tool/requirements-release.txt', 'tool/hardening/requirements.txt'):
        for line in (root / filename).read_text().splitlines():
            line = line.split('#', 1)[0].strip()
            if not line:
                continue
            match = re.fullmatch(r'([A-Za-z0-9_.-]+)==([A-Za-z0-9_.+-]+)', line)
            if not match:
                raise ValueError(f'Unpinned audit requirement: {line}')
            packages.append(dict(ecosystem='PyPI', name=match[1], version=match[2]))
    settings = (root / 'android/settings.gradle.kts').read_text()
    for plugin, artifact in [('com.android.application', 'com.android.tools.build:gradle'),
                             ('org.jetbrains.kotlin.android', 'org.jetbrains.kotlin:kotlin-gradle-plugin')]:
        found = re.findall(r'id\("' + re.escape(plugin) + r'"\) version "([^"]+)"', settings)
        if len(found) != 1:
            raise ValueError(f'Missing/unexpected plugin version: {plugin}')
        packages.append(dict(ecosystem='Maven', name=artifact, version=found[0]))
    wrapper = (root / 'android/gradle/wrapper/gradle-wrapper.properties').read_text()
    versions = re.findall(r'gradle-(\d+(?:\.\d+){1,2})-(?:all|bin)\.zip', wrapper)
    if len(versions) != 1:
        raise ValueError('Missing/unexpected Gradle distribution version')
    packages.append(dict(ecosystem='Maven', name='org.gradle:gradle-core', version=versions[0]))
    for p in packages:
        if set(p) != {'ecosystem', 'name', 'version'} or any(not isinstance(v, str) or not v for v in p.values()):
            raise ValueError('Malformed package entry')
        if any(c in p['version'] for c in ('+', '[', ']', '(', ')', '*')) or p['version'].endswith('-SNAPSHOT'):
            raise ValueError(f'Unresolved/dynamic version: {p}')
    return [dict(ecosystem=e, name=n, version=v) for e, n, v in sorted({
        (p['ecosystem'], p['name'], p['version']) for p in packages})]


def request_osv(payload):
    request = Request(ENDPOINT, data=json.dumps(payload).encode(),
                      headers={'Content-Type': 'application/json', 'User-Agent': 'Mobile-Maia-release-audit'})
    for attempt in range(3):
        try:
            with urlopen(request, timeout=45) as response:
                return json.load(response)
        except HTTPError as error:
            if error.code not in (408, 429, 500, 502, 503, 504) or attempt == 2:
                raise
        except (URLError, TimeoutError):
            if attempt == 2:
                raise
        time.sleep(attempt + 1)
    raise RuntimeError('OSV request did not complete')


def query(package, request=request_osv):
    payload = {'package': {k: package[k] for k in ('name', 'ecosystem')}, 'version': package['version']}
    found, seen = {}, set()
    while True:
        response = request(payload)
        if not isinstance(response, dict) or set(response) - {'vulns', 'next_page_token'}:
            raise ValueError('Invalid OSV response')
        vulnerabilities = response.get('vulns', [])
        if not isinstance(vulnerabilities, list):
            raise ValueError('Invalid OSV vulnerability list')
        for vuln in vulnerabilities:
            if not isinstance(vuln, dict) or not isinstance(vuln.get('id'), str) or not vuln['id']:
                raise ValueError('Malformed OSV vulnerability')
            withdrawn = vuln.get('withdrawn')
            if withdrawn is not None:
                if not isinstance(withdrawn, str) or datetime.fromisoformat(withdrawn.replace('Z', '+00:00')).tzinfo is None:
                    raise ValueError('Malformed OSV withdrawal timestamp')
            else:
                found[vuln['id']] = vuln
        token = response.get('next_page_token')
        if token is None or token == '':
            break
        if not isinstance(token, str) or token in seen or len(seen) >= 100:
            raise ValueError('Invalid OSV pagination')
        seen.add(token)
        payload = {**payload, 'page_token': token}
    return {'package': package, 'vulnerabilities': list(found.values())}


def audit(packages, request=request_osv):
    def one(package):
        try:
            return query(package, request)
        except Exception as error:
            return {'package': package, 'error': str(error)}
    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(one, packages))
    failed = any('error' in item or item.get('vulnerabilities') for item in results)
    return {'status': 'blocked' if failed else 'pass', 'results': results}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--maven', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    report = {'schema': 1, 'checked_at': datetime.now(timezone.utc).isoformat(), 'status': 'blocked',
              'coverage': 'Locked Pub, resolved Android release Maven, direct pinned Python audit tools and declared AGP/Kotlin plugins and Gradle core. Not a scan of native binaries, SDKs, models or all build-tool transitives.'}
    try:
        report['source_commit'] = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', 'HEAD'], text=True).strip()
        report['pubspec_lock_sha256'] = hashlib.sha256((ROOT / 'pubspec.lock').read_bytes()).hexdigest()
        report['maven_inventory_sha256'] = hashlib.sha256(args.maven.read_bytes()).hexdigest()
        report.update(audit(inventory(ROOT, json.loads(args.maven.read_text()))))
    except Exception as error:
        report['error'] = str(error)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2) + '\n')
    print(f"Dependency audit: {report['status']} ({len(report.get('results', []))} packages); {args.output}")
    return 0 if report['status'] == 'pass' else 1


if __name__ == '__main__':
    raise SystemExit(main())
