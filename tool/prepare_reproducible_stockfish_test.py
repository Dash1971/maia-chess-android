import json
from pathlib import Path
import tempfile
import unittest

import prepare_reproducible_stockfish as subject


class PrepareReproducibleStockfishTest(unittest.TestCase):
    def make_package(self, base: Path, *, version: str = subject.PACKAGE_VERSION) -> Path:
        package = base / "multistockfish_sf16"
        (package / "src").mkdir(parents=True)
        (package / "pubspec.yaml").write_text(
            f"name: {subject.PACKAGE_NAME}\nversion: {version}\n",
            encoding="utf-8",
        )
        (package / subject.CMAKE_PATH).write_text(
            "cmake_minimum_required(VERSION 3.10)\n" + subject.UNPATCHED + "\n",
            encoding="utf-8",
        )
        return package

    def test_patches_expected_download_and_is_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            package = self.make_package(Path(directory))
            cmake = package / subject.CMAKE_PATH

            self.assertTrue(subject.patch_cmake(cmake))
            patched = cmake.read_text(encoding="utf-8")
            self.assertIn(subject.NNUE_SHA256, patched)
            self.assertIn("EXPECTED_HASH", patched)
            self.assertIn("message(FATAL_ERROR", patched)
            self.assertNotIn(subject.UNPATCHED, patched)
            self.assertFalse(subject.patch_cmake(cmake))

    def test_resolves_package_root_from_file_uri(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            package = self.make_package(root / "cache")
            dart_tool = root / "app" / ".dart_tool"
            dart_tool.mkdir(parents=True)
            config = dart_tool / "package_config.json"
            config.write_text(
                json.dumps(
                    {
                        "configVersion": 2,
                        "packages": [
                            {
                                "name": subject.PACKAGE_NAME,
                                "rootUri": package.as_uri(),
                                "packageUri": "lib/",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )

            self.assertEqual(subject.package_root_from_config(config), package.resolve())

    def test_rejects_unexpected_package_version(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            package = self.make_package(Path(directory), version="9.9.9")
            with self.assertRaisesRegex(ValueError, "unexpected package"):
                subject.verify_package(package)

    def test_rejects_unexpected_cmake_source(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            package = self.make_package(Path(directory))
            cmake = package / subject.CMAKE_PATH
            cmake.write_text("project(unexpected)\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "unexpected Stockfish CMake"):
                subject.patch_cmake(cmake)


if __name__ == "__main__":
    unittest.main()
