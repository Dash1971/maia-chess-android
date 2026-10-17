import unittest
from pathlib import Path

from verify_gradle_wrapper import SHA256, URL, verify


class GradleWrapperTest(unittest.TestCase):
    def valid(self):
        return f'distributionUrl={URL}\ndistributionSha256Sum={SHA256}\n'

    def test_committed_wrapper(self):
        verify((Path(__file__).resolve().parents[1] / 'android/gradle/wrapper/gradle-wrapper.properties').read_text())

    def test_escaped_official_url(self):
        verify(self.valid().replace('https:', 'https\\:'))

    def test_rejects_known_vulnerable_and_unreviewed_distributions(self):
        for version in ['9.3.1', '9.8.0', '8.14.5', '9.8.1-rc-1', '10.0.0']:
            with self.subTest(version=version), self.assertRaises(ValueError):
                verify(self.valid().replace('9.8.1', version))

    def test_rejects_untrusted_or_changed_download(self):
        for url in [URL.replace('https:', 'http:'), URL.replace('services.gradle.org', 'example.org'), URL + '?other=1', URL.replace('-all.zip', '-bin.zip')]:
            with self.subTest(url=url), self.assertRaises(ValueError):
                verify(self.valid().replace(URL, url))

    def test_requires_exact_checksum(self):
        for checksum in ['', '0' * 64, SHA256[:-1]]:
            with self.subTest(checksum=checksum), self.assertRaises(ValueError):
                verify(self.valid().replace(SHA256, checksum))
        with self.assertRaises(ValueError):
            verify(f'distributionUrl={URL}')

    def test_duplicate_or_ambiguous_properties_fail(self):
        for extra in [f'distributionUrl={URL}\n', f'distributionSha256Sum={SHA256}\n', 'distributionUrl: unexpected\n']:
            with self.subTest(extra=extra), self.assertRaises(ValueError):
                verify(self.valid() + extra)


if __name__ == '__main__':
    unittest.main()
