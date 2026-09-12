#!/usr/bin/env python3

"""Backport deterministic asset-variant ordering to pinned Flutter 3.47.1."""

import argparse
from pathlib import Path
import subprocess


PINNED_FLUTTER_REVISION = "6655482ec06e547f90abf8ae7590466f4415978d"
ASSET_TOOL = Path("packages/flutter_tools/lib/src/asset.dart")
FLUTTER_TOOL_CACHE_FILES = (
    Path("bin/cache/flutter_tools.snapshot"),
    Path("bin/cache/flutter_tools.snapshot.old"),
    Path("bin/cache/flutter_tools.stamp"),
)
UNPATCHED = """          .expand((Directory dir) => dir.listSync())
          .whereType<File>()
          .toList();"""
PATCHED = """          .expand((Directory dir) => dir.listSync())
          .whereType<File>()
          .toList()
        ..sort((File left, File right) => left.path.compareTo(right.path));"""


def verify_flutter_revision(flutter_root: Path) -> None:
    result = subprocess.run(
        ["git", "-C", str(flutter_root), "rev-parse", "HEAD"],
        check=True,
        capture_output=True,
        text=True,
    )
    revision = result.stdout.strip()
    if revision != PINNED_FLUTTER_REVISION:
        raise ValueError(
            f"Refusing to patch Flutter {revision}; expected {PINNED_FLUTTER_REVISION}"
        )


def patch_asset_tool(asset_tool: Path) -> bool:
    source = asset_tool.read_text()
    if source.count(PATCHED) == 1 and UNPATCHED not in source:
        return False
    if source.count(UNPATCHED) != 1 or PATCHED in source:
        raise ValueError(
            f"Refusing to patch unexpected Flutter asset tool source: {asset_tool}"
        )
    asset_tool.write_text(source.replace(UNPATCHED, PATCHED))
    return True


def invalidate_flutter_tool_snapshot(flutter_root: Path) -> list[Path]:
    removed = []
    for relative_path in FLUTTER_TOOL_CACHE_FILES:
        path = flutter_root / relative_path
        if path.exists():
            path.unlink()
            removed.append(relative_path)
    return removed


def flutter_root_from_args(args: argparse.Namespace) -> Path:
    if args.flutter_root:
        return args.flutter_root.resolve()
    return args.flutter_bin.resolve().parent.parent


def main() -> None:
    parser = argparse.ArgumentParser()
    location = parser.add_mutually_exclusive_group(required=True)
    location.add_argument("--flutter-root", type=Path)
    location.add_argument("--flutter-bin", type=Path)
    args = parser.parse_args()

    flutter_root = flutter_root_from_args(args)
    verify_flutter_revision(flutter_root)
    changed = patch_asset_tool(flutter_root / ASSET_TOOL)
    removed = invalidate_flutter_tool_snapshot(flutter_root)
    patch_status = "patched" if changed else "already patched"
    print(f"{patch_status}; invalidated {len(removed)} Flutter tool cache files")


if __name__ == "__main__":
    main()
