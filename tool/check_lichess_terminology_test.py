import json
import shutil
import tempfile
import unittest
from pathlib import Path

from check_lichess_terminology import check


class LichessTerminologyTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        source = Path(__file__).resolve().parents[1]
        shutil.copytree(source / 'lib/l10n', self.root / 'lib/l10n')
        (self.root / 'docs').mkdir()
        self.reference = self.root / 'docs/lichess-terminology.json'
        shutil.copyfile(source / 'docs/lichess-terminology.json', self.reference)

    def test_committed_catalogs_match_reviewed_reference(self):
        self.assertEqual(check(self.root), [])

    def test_unreviewed_wording_change_is_reported(self):
        path = self.root / 'lib/l10n/app_es.arb'
        data = json.loads(path.read_text())
        data['settings'] = 'Unexpected replacement'
        path.write_text(json.dumps(data))
        self.assertEqual(check(self.root), [
            'es.settings: differs from reviewed Lichess terminology',
        ])

    def test_context_exception_must_explain_its_reason(self):
        data = json.loads(self.reference.read_text())
        data['entries']['promoteVariation']['adaptations']['ja']['reason'] = ''
        self.reference.write_text(json.dumps(data))
        self.assertIn('ja.promoteVariation: adaptation needs a reason', check(self.root))

    def test_missing_upstream_translation_cannot_silently_pass(self):
        data = json.loads(self.reference.read_text())
        data['entries']['settings']['upstream']['es'] = None
        self.reference.write_text(json.dumps(data))
        self.assertIn('es.settings: missing translation or documented fallback', check(self.root))


if __name__ == '__main__':
    unittest.main()
