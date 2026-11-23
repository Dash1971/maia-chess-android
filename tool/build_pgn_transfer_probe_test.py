import contextlib
import importlib.util
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import zipfile

spec = importlib.util.spec_from_file_location('transfer_probe', Path(__file__).with_name('build_pgn_transfer_probe.py'))
probe = importlib.util.module_from_spec(spec)
spec.loader.exec_module(probe)


class ProbeToolchainTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.sdk = self.root / 'sdk'
        self.java = self.root / 'jdk'
        self.key = self.root / 'debug.keystore'
        self.key.write_text('synthetic fixture, not a signing key')
        self.output = self.root / 'output'
        self.args = ['probe', '--sdk-root', str(self.sdk), '--output', str(self.output),
                     '--debug-keystore', str(self.key)]

    def invoke(self, extra=(), java_home=None):
        environment = dict(os.environ)
        environment.pop('JAVA_HOME', None)
        if java_home is not None:
            environment['JAVA_HOME'] = java_home
        with patch.object(sys, 'argv', self.args + list(extra)), patch.dict(os.environ, environment, clear=True):
            probe.main()

    def expect_error(self, text, extra=(), java_home=None):
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr), patch.object(probe.subprocess, 'run') as run:
            with self.assertRaises(SystemExit) as error:
                self.invoke(extra, java_home)
        self.assertEqual(error.exception.code, 2)
        self.assertIn(text, stderr.getvalue())
        self.assertNotIn('Traceback', stderr.getvalue())
        self.assertFalse(self.output.exists())
        run.assert_not_called()

    def test_missing_java_home_has_actionable_error_before_output(self):
        self.expect_error('Set JAVA_HOME')

    def test_empty_java_home_is_not_the_current_directory(self):
        self.expect_error('Set JAVA_HOME', java_home='  ')

    def test_missing_selected_tools_are_named_before_output(self):
        self.expect_error('Required shared tool is absent:', java_home=str(self.java))

    def test_old_platform_is_rejected(self):
        self.expect_error('API 36 or newer', extra=['--android-api', '35'])

    def test_tool_version_cannot_escape_sdk(self):
        self.expect_error('not a path', extra=['--build-tools-version', '../unrelated'])

    def test_default_and_explicit_installed_tools_are_used_without_downloads(self):
        for api, version, extra in [(36, '36.0.0', []),
                                    (37, '37.0.0-rc1', ['--android-api', '37', '--build-tools-version', '37.0.0-rc1'])]:
            with self.subTest(api=api, version=version):
                platform = self.sdk / f'platforms/android-{api}/android.jar'
                tools = self.sdk / 'build-tools' / version
                for tool in [self.java / 'bin/javac', platform] + [tools / t for t in ('aapt2', 'd8', 'zipalign', 'apksigner')]:
                    tool.parent.mkdir(parents=True, exist_ok=True)
                    tool.touch()
                commands = []
                def run(command, check):
                    self.assertTrue(check)
                    commands.append(command)
                    if Path(command[0]).name == 'd8':
                        (self.output / 'dex/classes.dex').write_bytes(b'synthetic dex')
                    if Path(command[0]).name == 'aapt2':
                        with zipfile.ZipFile(self.output / 'unsigned.apk', 'w'):
                            pass
                    return subprocess.CompletedProcess(command, 0)
                with patch.object(probe.subprocess, 'run', side_effect=run):
                    self.invoke(extra, str(self.java))
                self.assertIn(str(platform), commands[0])
                self.assertEqual([c[0] for c in commands], [str(self.java / 'bin/javac')] +
                    [str(tools / t) for t in ('d8', 'aapt2', 'zipalign', 'apksigner', 'apksigner')])
                self.assertIn(str(self.key), commands[-2])
                self.assertEqual(self.key.read_text(), 'synthetic fixture, not a signing key')
                import shutil
                shutil.rmtree(self.output)


if __name__ == '__main__': unittest.main()
