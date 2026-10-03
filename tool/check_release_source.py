#!/usr/bin/env python3
"""Fail early on release-source mistakes that APK checks cannot see.

This is a targeted repository gate, not a substitute for F-Droid's own scanner
and the pre-tag build using the bot-inherited F-Droid recipe.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


ARCHIVE_SUFFIXES = (
    ".zip", ".apk", ".aab", ".jar", ".aar", ".tar", ".tar.gz",
    ".tar.bz2", ".tar.xz", ".tgz", ".7z", ".rar", ".whl",
)
VERSION_PATTERN = re.compile(r"^version:\s*([^\s+]+)\+(\d+)\s*$", re.MULTILINE)
LISTING = "fastlane/metadata/android/en-US"


def check_release_source(root: Path, ref: str | None = None) -> list[str]:
    errors: list[str] = []

    def git(*args: str) -> bytes:
        return subprocess.check_output(["git", "-C", str(root), *args], stderr=subprocess.PIPE)

    try:
        # Resolve once: all subsequent reads use this immutable commit, never ref again.
        commit = git("rev-parse", "--verify", "--end-of-options", f"{ref}^{{commit}}").decode().strip() if ref is not None else None
        if commit:
            entries = git("ls-tree", "-r", "-z", commit).split(b"\0")
            tracked = set()
            for entry in entries:
                if entry:
                    header, path = entry.split(b"\t", 1)
                    if header.split()[0] in (b"100644", b"100755"):
                        tracked.add(path.decode("utf-8", "surrogateescape"))
            archive_paths = [entry.split(b"\t", 1)[1].decode("utf-8", "surrogateescape") for entry in entries if entry]
        else:
            tracked = {path.decode("utf-8", "surrogateescape") for path in git("ls-files", "-z", "--cached").split(b"\0") if path}
            archive_paths = tracked
    except subprocess.CalledProcessError:
        return [f"cannot read Git release source{f' for ref {ref!r}' if ref is not None else ''}"]

    def read(path: str) -> str | None:
        try:
            if commit:
                if path not in tracked:
                    return None
                return git("show", f"{commit}:{path}").decode("utf-8")
            return (root / path).read_text(encoding="utf-8")
        except (OSError, UnicodeError, subprocess.CalledProcessError):
            return None

    pubspec = read("pubspec.yaml")
    matches = VERSION_PATTERN.findall(pubspec or "")
    if len(matches) != 1:
        errors.append("pubspec.yaml must contain exactly one versionName+versionCode line")
    else:
        version_name, version_code = matches[0]
        changelog = f"{LISTING}/changelogs/{version_code}.txt"
        content = read(changelog)
        if content is None:
            errors.append(f"missing Fastlane changelog: {changelog}")
        else:
            content = content.strip()
            if not content or len(content) > 500:
                errors.append(f"{changelog} must contain 1–500 characters")
            if version_name not in content:
                errors.append(f"{changelog} must identify version {version_name}")

    for filename, limit in (("title.txt", 50), ("short_description.txt", 80), ("full_description.txt", 4000)):
        path = f"{LISTING}/{filename}"
        content = read(path)
        if content is None:
            errors.append(f"missing Fastlane metadata: {path}")
        elif not content.strip() or len(content.strip()) > limit:
            errors.append(f"{path} must contain 1–{limit} characters")

    screenshots = [path for path in tracked if re.fullmatch(
        re.escape(LISTING) + r"/images/[^/]*Screenshots/[^/]+\.(?:png|jpg|jpeg|webp)", path, re.IGNORECASE
    )]
    if not any(commit or (root / path).is_file() for path in screenshots):
        errors.append(f"missing tracked Fastlane screenshot under {LISTING}/images/*Screenshots/")

    archives = sorted(path for path in archive_paths if path.lower().endswith(ARCHIVE_SUFFIXES))
    if archives:
        errors.append(
            "tracked archives in release source require removal or an explicitly reviewed gate change: "
            + ", ".join(archives)
        )
    return errors


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ref", help="check the exact Git tree of a commit or tag")
    args = parser.parse_args()
    issues = check_release_source(Path(__file__).resolve().parents[1], args.ref)
    if issues:
        for issue in issues:
            print(f"release-source gate: {issue}", file=sys.stderr)
        sys.exit(1)
    print("release-source gate passed")
