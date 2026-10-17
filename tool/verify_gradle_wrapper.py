#!/usr/bin/env python3
"""Check the reviewed Gradle distribution before CI or local release builds.

Keep this pin in sync with gradle-wrapper.properties after upstream security,
compatibility and reproducibility review. This offline gate supplements OSV;
it is not a general vulnerability scanner.
"""
from pathlib import Path
import sys

VERSION = '9.8.1'
SHA256 = '5ceda8d2425eb2af196dec31b6fc1f38af2fb638fd621f86fa685805f2262224'
URL = f'https://services.gradle.org/distributions/gradle-{VERSION}-all.zip'


def verify(text):
    values = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith(('#', '!')):
            continue
        key, separator, value = line.partition('=')
        if not separator:
            raise ValueError('Expected canonical key=value wrapper properties')
        key = key.strip()
        if key in values:
            raise ValueError(f'Duplicate wrapper property: {key}')
        values[key] = value.strip().replace('\\:', ':')
    if values.get('distributionUrl') != URL:
        raise ValueError(f'Gradle must use the reviewed {VERSION} official distribution; review toolchain changes before updating this gate')
    if values.get('distributionSha256Sum') != SHA256:
        raise ValueError('Gradle distribution checksum is missing or differs from the reviewed upstream SHA-256')


if __name__ == '__main__':
    wrapper = Path(__file__).resolve().parents[1] / 'android/gradle/wrapper/gradle-wrapper.properties'
    try:
        verify(wrapper.read_text())
    except (OSError, ValueError) as error:
        print(f'Gradle security pin check failed: {error}', file=sys.stderr)
        sys.exit(1)
    print(f'Gradle {VERSION} official distribution and checksum verified')
