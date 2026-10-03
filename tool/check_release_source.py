#!/usr/bin/env python3
"""Fail early on release-source mistakes that APK checks cannot see.

This is a targeted repository gate, not a substitute for F-Droid's own scanner
and the pre-tag build using the bot-inherited F-Droid recipe.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ARCHIVE_SUFFIXES = (
    ".zip", ".apk", ".aab", ".jar", ".aar", ".tar", ".tar.gz",
    ".tar.bz2", ".tar.xz", ".tgz", ".7z", ".rar", ".whl",
)
VERSION_PATTERN = re.compile(r"^version:\s*([^\s+]+)\+(\d+)\s*$", re.MULTILINE)


def check_release_source(root: Path) -> list[str]:
    errors: list[str] = []
    matches = VERSION_PATTERN.findall((root / "pubspec.yaml").read_text(encoding="utf-8"))
    if len(matches) != 1:
        errors.append("pubspec.yaml must contain exactly one versionName+versionCode line")
    else:
        version_name, version_code = matches[0]
        changelog = root / "fastlane/metadata/android/en-US/changelogs" / f"{version_code}.txt"
        if not changelog.is_file():
            errors.append(f"missing Fastlane changelog: {changelog.relative_to(root)}")
        else:
            content = changelog.read_text(encoding="utf-8").strip()
            if not content or len(content) > 500:
                errors.append(f"{changelog.relative_to(root)} must contain 1–500 characters")
            if version_name not in content:
                errors.append(f"{changelog.relative_to(root)} must identify version {version_name}")

    tracked = subprocess.check_output(
        ["git", "-C", str(root), "ls-files", "-z", "--cached"]
    )
    archives = sorted(
        path.decode("utf-8", "surrogateescape")
        for path in tracked.split(b"\0")
        if path and path.decode("utf-8", "surrogateescape").lower().endswith(ARCHIVE_SUFFIXES)
    )
    if archives:
        errors.append(
            "tracked archives in release source require removal or an explicitly reviewed gate change: "
            + ", ".join(archives)
        )
    return errors


if __name__ == "__main__":
    issues = check_release_source(Path(__file__).resolve().parents[1])
    if issues:
        for issue in issues:
            print(f"release-source gate: {issue}", file=sys.stderr)
        sys.exit(1)
    print("release-source gate passed")
