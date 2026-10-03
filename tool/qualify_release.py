#!/usr/bin/env python3
"""Read-only Stable release gate. Never signs, tags, uploads, or publishes.

See docs/RELEASING.md for evidence collection and the limits of this gate.
Paths in the evidence manifest are relative to that manifest, not the cwd.
"""
from __future__ import annotations

import argparse
import base64
from datetime import datetime, timezone, timedelta
import hashlib
import json
from pathlib import Path
import re
import tempfile
from types import SimpleNamespace
from urllib.request import urlopen

from check_release_source import VERSION_PATTERN, check_release_source
from release_common import file_digest, require, run, sdk_arguments
from verify_release_apk import verify

REPOSITORY = 'Dash1971/maia-chess-android'
PACKAGE = 'com.dash1971.maia_chess'
SIGNER = 'cd6c07c4efacf52bcccb83009b522c1dcad4a171197505a486f0a58edb6f172e'
ROOT = Path(__file__).resolve().parents[1]
SHA = re.compile(r'[0-9a-f]{40}')


def gh_json(*args):
    return json.loads(run('gh', *args))


def check_ci(info, jobs, sha):
    require(info['head_sha'] == sha, 'CI belongs to another source commit.')
    require(info['repository']['full_name'] == REPOSITORY, 'Wrong CI repository.')
    require(info['path'] == '.github/workflows/checks.yml', 'Wrong CI workflow.')
    require(info['event'] == 'workflow_dispatch', 'Use the manual Android release run.')
    require(info['status'] == 'completed' and info['conclusion'] == 'success',
            'CI has not completed successfully.')
    for name in ('test', 'android'):
        matches = [job for job in jobs if job['name'] == name]
        require(len(matches) == 1 and matches[0]['conclusion'].lower() == 'success',
                f'Required CI job {name} did not pass (skipped is not a pass).')


def check_recipe(canonical, candidate, version, code, sha):
    require(canonical['Repo'] == f'https://github.com/{REPOSITORY}.git',
            'Unexpected canonical app repository.')
    base = canonical['Builds'][-1]
    require(not base.get('disable'), 'Latest canonical build is disabled; review upstream.')
    matches = [b for b in candidate['Builds'] if b['versionCode'] == code]
    require(len(matches) == 1, 'Candidate recipe must contain exactly one matching build.')
    build = matches[0]
    require(build['versionName'] == version and build['commit'] == sha,
            'Candidate recipe must pin the qualified full source SHA and version.')
    identity = {'versionName', 'versionCode', 'commit'}
    require({k: v for k, v in build.items() if k not in identity} ==
            {k: v for k, v in base.items() if k not in identity},
            'Candidate build instructions differ from the canonical inherited recipe.')
    for key in ('RepoType', 'Repo', 'Binaries', 'AllowedAPKSigningKeys',
                'AutoUpdateMode', 'UpdateCheckMode', 'UpdateCheckData'):
        require(candidate.get(key) == canonical.get(key), f'Canonical {key} changed.')
    allowed = {'Builds', 'CurrentVersion', 'CurrentVersionCode'}
    require({k: v for k, v in candidate.items() if k not in allowed} ==
            {k: v for k, v in canonical.items() if k not in allowed},
            'Non-build metadata differs from canonical (including disable/scanner settings).')
    require([b for b in candidate['Builds'] if b['versionCode'] != code] ==
            [b for b in canonical['Builds'] if b['versionCode'] != code],
            'Candidate recipe changed or added unrelated build blocks.')
    require(SIGNER in canonical['AllowedAPKSigningKeys'], 'Expected signer is not allowed by F-Droid.')
    require(candidate['CurrentVersion'] == version and candidate['CurrentVersionCode'] == code,
            'Candidate current-version fields do not match the source.')


def check_fdroid_log(log, sha, code, exit_code):
    require(exit_code.strip() == '0', 'Independent F-Droid build did not exit successfully.')
    markers = ('Scanning source for common problems',
               f'Successfully built {PACKAGE}:{code} from {sha}',
               'Scanning APK with dexdump', 'Scanning APK for extra signing blocks',
               '1 build succeeded')
    require(all(marker in log for marker in markers),
            'Missing source/APK scans or exact-source build completion in F-Droid log.')
    require(not re.search(r'\b(?:ERROR|CRITICAL):', log), 'F-Droid log contains an error.')


def check_review(review, sha, now=None):
    """Explicit human/operator review, not a claim of automated upstream approval."""
    require(review['source_commit'] == sha, 'Review belongs to another source commit.')
    checked = datetime.fromisoformat(review['checked_at'].replace('Z', '+00:00'))
    require(checked.tzinfo is not None, 'Review timestamp must include a timezone.')
    age = (now or datetime.now(timezone.utc)) - checked
    require(-timedelta(minutes=5) <= age <= timedelta(hours=24), 'Review is stale or future-dated.')
    require(review['listing_matches_app'] is True, 'Listing accuracy review is missing.')
    require(review['source_publication_reviewed'] is True, 'Source publication review is missing.')
    require(review['upstream_status'] in ('clear', 'blocked', 'unknown'), 'Invalid upstream status.')
    require(isinstance(review['failed_version_codes'], list) and
            all(type(v) is int for v in review['failed_version_codes']), 'Invalid failed-version list.')
    require(review['upstream_status'] != 'clear' or not review['failed_version_codes'],
            'Cannot report upstream clear while retaining failed versions.')
    for key in ('upstream_evidence_url', 'notes', 'test_scope'):
        require(isinstance(review[key], str) and review[key].strip(), f'Missing review {key}.')


def check_signer(signature):
    found = re.findall(r'^Signer #\d+ certificate SHA-256 digest: ([0-9a-fA-F]{64})$',
                       signature, re.MULTILINE)
    require([value.lower() for value in found] == [SIGNER], 'Unexpected APK signing certificate(s).')


def check_version_history(version, code, sha, signed_hash, latest, latest_pubspec, tag_commit):
    require(tag_commit is None or tag_commit == sha, 'Existing release tag points to another source; never replace it.')
    versions = VERSION_PATTERN.findall(latest_pubspec)
    require(len(versions) == 1, 'Cannot establish the latest published version code.')
    latest_version, latest_code = versions[0]
    if latest['tag_name'] == f'v{version}':
        require(tag_commit == sha and latest_version == version and int(latest_code) == code,
                'Published release identity differs from this candidate.')
        assets = [a for a in latest['assets'] if a['name'] == f'Mobile-Maia-v{version}.apk']
        require(len(assets) == 1 and assets[0]['digest'] == 'sha256:' + signed_hash,
                'Published APK differs; do not replace it. Use a new release.')
    else:
        require(code > int(latest_code), 'Version code must exceed the latest published Stable version.')


def qualify(args):
    import apksigcopier
    import yaml

    manifest = args.evidence.read_bytes()
    manifest_hash = hashlib.sha256(manifest).hexdigest()
    evidence = json.loads(manifest)
    require(type(evidence['schema']) is int and evidence['schema'] == 1, 'Unsupported evidence schema.')
    sha = evidence['source_commit']
    require(isinstance(sha, str) and SHA.fullmatch(sha), 'Use a full lowercase source SHA.')
    resolved = run('git', '-C', ROOT, 'rev-parse', '--verify', f'{sha}^{{commit}}').decode().strip()
    require(resolved == sha, 'Source must resolve to exactly that commit.')
    errors = check_release_source(ROOT, sha)
    require(not errors, '; '.join(errors))
    version, code_text = VERSION_PATTERN.findall(
        run('git', '-C', ROOT, 'show', f'{sha}:pubspec.yaml').decode())[0]
    code = int(code_text)
    require(re.fullmatch(r'\d+\.\d+\.\d+', version), 'Use a Stable major.minor.patch version.')
    check_review(evidence['review'], sha)

    def path(name):
        value = (args.evidence.parent / evidence[name]).resolve()
        require(value.is_file(), f'Missing evidence file: {name}')
        return value

    paths = {key: path(key) for key in ('ci_unsigned_apk', 'fdroid_unsigned_apk',
                                      'signed_apk', 'fdroid_recipe', 'fdroid_log', 'fdroid_exit_code')}
    file_hashes = {key: file_digest(value) for key, value in paths.items()}
    hashes = {key: file_hashes[key] for key in
              ('ci_unsigned_apk', 'fdroid_unsigned_apk', 'signed_apk')}
    require(hashes['ci_unsigned_apk'] == hashes['fdroid_unsigned_apk'],
            'Independent unsigned APK does not match CI.')
    run_id = evidence['ci_run_id']
    require(type(run_id) is int and run_id > 0, 'Invalid CI run ID.')
    info = gh_json('api', f'repos/{REPOSITORY}/actions/runs/{run_id}')
    jobs = gh_json('run', 'view', str(run_id), '--repo', REPOSITORY, '--json', 'jobs')['jobs']
    check_ci(info, jobs, sha)

    revision = evidence['canonical_fdroiddata_commit']
    require(isinstance(revision, str) and SHA.fullmatch(revision), 'Pin canonical fdroiddata commit.')
    canonical_url = f'https://gitlab.com/fdroid/fdroiddata/-/raw/{revision}/metadata/{PACKAGE}.yml'
    with urlopen(canonical_url, timeout=60) as response:
        canonical = yaml.safe_load(response.read())
    current_url = f'https://gitlab.com/fdroid/fdroiddata/-/raw/master/metadata/{PACKAGE}.yml'
    with urlopen(current_url, timeout=60) as response:
        current = yaml.safe_load(response.read())
    require(canonical == current, 'Canonical app metadata changed; refresh and requalify the recipe.')
    candidate = yaml.safe_load(paths['fdroid_recipe'].read_text())
    check_recipe(canonical, candidate, version, code, sha)
    require(re.fullmatch(r'registry\.gitlab\.com/fdroid/fdroidserver@sha256:[0-9a-f]{64}',
                         evidence['buildserver_image']), 'Pin the official buildserver image digest.')
    require(SHA.fullmatch(evidence['fdroidserver_commit']), 'Pin fdroidserver source.')
    check_fdroid_log(paths['fdroid_log'].read_text(), sha, code, paths['fdroid_exit_code'].read_text())

    with tempfile.TemporaryDirectory(prefix='maia-qualification-') as temporary:
        scratch = Path(temporary)
        run('gh', 'run', 'download', str(run_id), '--repo', REPOSITORY,
            '--name', f'release-verification-{sha}', '--dir', scratch, timeout=300)
        ci_apk = json.loads((scratch / 'apk.json').read_text())
        require(ci_apk['status'] == 'passed' and ci_apk['apk_sha256'] == hashes['ci_unsigned_apk'],
                'Local APK is not the verified artifact from the selected CI run.')
        provenance = (scratch / 'build-environment.txt').read_text().splitlines()
        require(f'source_commit={sha}' in provenance and 'runner_os=Linux' in provenance,
                'CI provenance does not identify the qualified Linux source build.')
        epoch = run('git', '-C', ROOT, 'log', '-1', '--format=%ct', sha).decode().strip()
        require(f'source_date_epoch={epoch}' in provenance, 'Build timestamp does not match source.')
        apk_args = SimpleNamespace(apk=paths['signed_apk'], sdk_root=args.sdk_root,
                                   build_tools_version=args.build_tools_version, package=PACKAGE,
                                   version_name=version, version_code=code, require_signature=True,
                                   allow_abi=['armeabi-v7a', 'arm64-v8a', 'x86_64'], forbid_path=[],
                                   compare=paths['fdroid_unsigned_apk'], allow_change=[])
        apk = verify(apk_args)
        check_signer(apk['signature'])
        reconstructed = scratch / 'reconstructed.apk'
        apksigcopier.do_copy(str(paths['signed_apk']), str(paths['fdroid_unsigned_apk']),
                            str(reconstructed), exclude=apksigcopier.exclude_meta)
        require(file_digest(reconstructed) == hashes['signed_apk'],
                'Signature reconstruction differs; preserve alignment when signing.')
    require(file_digest(args.evidence) == manifest_hash and
            all(file_digest(value) == file_hashes[key] for key, value in paths.items()),
            'Evidence changed while qualification was running; retry with immutable inputs.')
    tag = f'v{version}'
    refs = gh_json('api', f'repos/{REPOSITORY}/git/matching-refs/tags/{tag}')
    matching = [r for r in refs if r['ref'] == f'refs/tags/{tag}']
    require(len(matching) <= 1, 'Ambiguous release tag.')
    tag_commit = None
    if matching:
        obj = matching[0]['object']
        for _ in range(5):
            if obj['type'] == 'commit':
                tag_commit = obj['sha']
                break
            require(obj['type'] == 'tag' and SHA.fullmatch(obj['sha']), 'Invalid tag target.')
            obj = gh_json('api', f'repos/{REPOSITORY}/git/tags/{obj["sha"]}')['object']
        require(tag_commit is not None, 'Cannot resolve release tag to a commit.')
    latest = gh_json('api', f'repos/{REPOSITORY}/releases/latest')
    # Read the version from the published tag, never current main.
    from urllib.parse import quote
    latest_source = gh_json('api', f'repos/{REPOSITORY}/contents/pubspec.yaml?ref={quote(latest["tag_name"], safe="")}')
    require(latest_source['encoding'] == 'base64', 'Cannot read published source version.')
    check_version_history(version, code, sha, hashes['signed_apk'], latest,
                          base64.b64decode(latest_source['content']).decode(), tag_commit)
    return {'status': 'passed', 'qualified_at': datetime.now(timezone.utc).isoformat(),
            'source_commit': sha, 'version': version, 'version_code': code,
            'ci_run': info['html_url'], 'canonical_metadata': canonical_url,
            'canonical_matches_current': True,
            'published_version_and_tag_checks': 'passed',
            'buildserver_image': evidence['buildserver_image'],
            'fdroidserver_commit': evidence['fdroidserver_commit'], 'apk_hashes': hashes,
            'evidence_sha256': manifest_hash, 'evidence_file_hashes': file_hashes,
            'verification_tool_hashes': {name: file_digest(Path(__file__).parent / name) for name in
                                        ('qualify_release.py', 'check_release_source.py',
                                         'verify_release_apk.py', 'release_common.py', 'verify_model.py',
                                         'requirements-release.txt')},
            'operator_review': evidence['review'], 'apk_verification': apk,
            'signature_reconstruction': 'byte-identical',
            'scope': 'Prepublication qualification only. No tag, upload, or store publication performed.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--evidence', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    sdk_arguments(parser)
    args = parser.parse_args()
    if args.output.resolve() == args.evidence.resolve():
        parser.error('Output must be separate from the evidence manifest.')
    if args.output.exists() or args.output.is_symlink():
        parser.error('Choose a new output path; existing files are never overwritten.')
    try:
        require(args.package == PACKAGE, 'This gate only qualifies the Stable package.')
        report = qualify(args)
    except Exception as error:
        report = {'status': 'failed', 'error': str(error)}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open('x', encoding='utf-8') as stream:
        stream.write(json.dumps(report, indent=2) + '\n')
    print(f"Release qualification {report['status']}: {args.output}")
    if report['status'] != 'passed':
        parser.exit(1, report['error'] + '\n')


if __name__ == '__main__':
    main()
