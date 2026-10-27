import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('check_localization', Path(__file__).with_name('check_localization.py'))
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class LocalizationContractTest(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / 'lib/l10n').mkdir(parents=True)
        (self.root / 'docs').mkdir()
        for lang in checker.LOCALES:
            self.write(lang, {'@@locale': lang, 'countLabel': '{count} ' + lang,
                '@countLabel': {'description': 'Number of games', 'placeholders': {'count': {'type': 'int'}}}})
        checker.write_review(self.root)

    def write(self, lang, data):
        (self.root / f'lib/l10n/app_{lang}.arb').write_text(json.dumps(data))

    def change(self, lang, change):
        data = checker.catalogs(self.root)[lang]
        change(data)
        self.write(lang, data)

    def test_complete_catalogs_and_review_pass(self):
        self.assertEqual([], checker.check(self.root))

    def test_missing_translation_fails(self):
        self.change('ko', lambda data: data.pop('countLabel'))
        self.assertTrue(any('missing=' in error for error in checker.check(self.root)))

    def test_placeholder_loss_fails(self):
        self.change('ja', lambda data: data.update(countLabel='個'))
        self.assertTrue(any('placeholders' in error for error in checker.check(self.root)))

    def test_untranslated_english_fails(self):
        self.change('es', lambda data: data.update(countLabel='{count} en'))
        self.assertTrue(any('untranslated' in error for error in checker.check(self.root)))

    def test_english_sampling_term_inside_translated_prose_fails(self):
        self.change('en', lambda data: data.update(temperature='Temperature',
            report='After Temperature and Top-P.',
            **{'@temperature': {'description': 'Sampling temperature'},
               '@report': {'description': 'Report explanation'}}))
        for lang in checker.LOCALES[1:]:
            self.change(lang, lambda data: data.update(temperature='温度', report='温度とTop-Pを適用'))
        checker.write_review(self.root)
        self.assertEqual([], checker.check(self.root))
        # Japanese characters next to the English word must not hide it from
        # detection; a Unicode word-boundary regex would miss this case.
        self.change('ja', lambda data: data.update(report='TemperatureとTop-Pを適用'))
        checker.write_review(self.root)
        self.assertIn('ja.report: untranslated Temperature term; use the localized sampling label',
                      checker.check(self.root))
        self.change('ja', lambda data: data.update(temperature=7))
        checker.write_review(self.root)
        self.assertIn('ja.temperature: empty/non-string message', checker.check(self.root))

    def test_duplicate_keys_fail(self):
        (self.root / 'lib/l10n/app_zh.arb').write_text('{"same":"a","same":"b"}')
        self.assertTrue(any('duplicate JSON key' in error for error in checker.check(self.root)))

    def test_license_version_is_not_a_localized_decimal(self):
        self.change('en', lambda data: data.update(aboutLicence='Licence: AGPL-3.0-only',
            **{'@aboutLicence': {'description': 'License notice'}}))
        for lang in checker.LOCALES[1:]:
            self.change(lang, lambda data: data.update(aboutLicence='AGPL-3.0-only ' + lang))
        checker.write_review(self.root)
        self.assertEqual([], checker.check(self.root))
        self.change('fr', lambda data: data.update(aboutLicence='Licence : AGPL-3,0-only'))
        checker.write_review(self.root)
        self.assertIn('fr.aboutLicence: missing canonical identifier AGPL-3.0-only',
                      checker.check(self.root))

    def test_outdated_csv_fails(self):
        self.change('ja', lambda data: data.update(countLabel='{count}変更'))
        self.assertTrue(any('CSV ja.' in error for error in checker.check(self.root)))
        checker.write_review(self.root)
        self.assertEqual([], checker.check(self.root))

    def test_english_lookup_bridge_fails(self):
        (self.root / 'lib/bridge.dart').write_text('String appText(context, english) => english;')
        self.assertTrue(any('obsolete English-text lookup' in error for error in checker.check(self.root)))

    def test_plural_placeholder_detection(self):
        self.change('en', lambda data: data.update(countLabel='{count, plural, one{One game} other{{count} games}}'))
        checker.write_review(self.root)
        self.assertEqual([], checker.check(self.root))

    def test_repository_catalogs_and_review(self):
        self.assertEqual([], checker.check(Path(__file__).resolve().parents[1]))


if __name__ == '__main__':
    unittest.main()
