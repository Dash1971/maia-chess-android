#!/usr/bin/env python3

"""Make multistockfish_sf16's build-time NNUE download fail closed."""

import argparse
import json
from pathlib import Path
import re
from urllib.parse import unquote, urljoin, urlparse


PACKAGE_NAME = "multistockfish_sf16"
PACKAGE_VERSION = "0.1.1"
NNUE_SHA256 = "5af11540bbfefcb54e38c5dd000cab4b469dfa7599a1d55be5d2722c20a8929b"
CMAKE_PATH = Path("src/CMakeLists.txt")
UNPATCHED = (
    "file(DOWNLOAD https://tests.stockfishchess.org/api/nn/"
    "nn-5af11540bbfe.nnue ${CMAKE_BINARY_DIR}/nn-5af11540bbfe.nnue)"
)
PATCHED = f"""set(stockfishNnueUrl
  \"https://tests.stockfishchess.org/api/nn/nn-5af11540bbfe.nnue\"
)
set(stockfishNnuePath \"${{CMAKE_BINARY_DIR}}/nn-5af11540bbfe.nnue\")
file(DOWNLOAD
  \"${{stockfishNnueUrl}}\"
  \"${{stockfishNnuePath}}\"
  EXPECTED_HASH \"SHA256={NNUE_SHA256}\"
  STATUS stockfishNnueDownloadStatus
)
list(GET stockfishNnueDownloadStatus 0 stockfishNnueDownloadCode)
list(GET stockfishNnueDownloadStatus 1 stockfishNnueDownloadMessage)
if(NOT stockfishNnueDownloadCode EQUAL 0)
  message(FATAL_ERROR
    \"Stockfish NNUE download failed verification: ${{stockfishNnueDownloadMessage}}\"
  )
endif()"""


def package_root_from_config(package_config: Path) -> Path:
    data = json.loads(package_config.read_text(encoding="utf-8"))
    matches = [
        package
        for package in data.get("packages", [])
        if package.get("name") == PACKAGE_NAME
    ]
    if len(matches) != 1:
        raise ValueError(
            f"Expected one {PACKAGE_NAME} entry in {package_config}; found {len(matches)}"
        )
    root_uri = matches[0].get("rootUri")
    if not isinstance(root_uri, str):
        raise ValueError(f"Invalid {PACKAGE_NAME} rootUri in {package_config}")
    resolved = urlparse(urljoin(package_config.resolve().as_uri(), root_uri))
    if resolved.scheme != "file" or resolved.netloc not in ("", "localhost"):
        raise ValueError(f"Refusing non-file {PACKAGE_NAME} rootUri: {root_uri}")
    return Path(unquote(resolved.path)).resolve()


def verify_package(package_root: Path) -> None:
    pubspec = (package_root / "pubspec.yaml").read_text(encoding="utf-8")
    name_match = re.search(r"^name:\s*(\S+)\s*$", pubspec, re.MULTILINE)
    version_match = re.search(r"^version:\s*(\S+)\s*$", pubspec, re.MULTILINE)
    name = name_match.group(1) if name_match else None
    version = version_match.group(1) if version_match else None
    if name != PACKAGE_NAME or version != PACKAGE_VERSION:
        raise ValueError(
            f"Refusing unexpected package {name!r} version {version!r}; "
            f"expected {PACKAGE_NAME!r} {PACKAGE_VERSION!r}"
        )


def patch_cmake(cmake_path: Path) -> bool:
    source = cmake_path.read_text(encoding="utf-8")
    if source.count(PATCHED) == 1 and UNPATCHED not in source:
        return False
    if source.count(UNPATCHED) != 1 or PATCHED in source:
        raise ValueError(f"Refusing unexpected Stockfish CMake source: {cmake_path}")
    cmake_path.write_text(source.replace(UNPATCHED, PATCHED), encoding="utf-8")
    return True


def main() -> None:
    parser = argparse.ArgumentParser()
    location = parser.add_mutually_exclusive_group(required=True)
    location.add_argument("--package-config", type=Path)
    location.add_argument("--package-root", type=Path)
    args = parser.parse_args()

    package_root = (
        args.package_root.resolve()
        if args.package_root
        else package_root_from_config(args.package_config)
    )
    verify_package(package_root)
    changed = patch_cmake(package_root / CMAKE_PATH)
    print(
        f"{PACKAGE_NAME} NNUE verification "
        f"{'patched' if changed else 'already patched'} ({NNUE_SHA256})"
    )


if __name__ == "__main__":
    main()
