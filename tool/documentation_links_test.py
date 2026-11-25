"""Stable documentation paths and public website fragment compatibility."""

from pathlib import Path
import re
import unittest
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
DOCUMENTS = (
    'README.md', 'AGENTS.md', 'CONTRIBUTING.md', 'FDROID_READINESS.md',
    'docs/README.md', 'docs/USER_GUIDE.md', 'docs/RELEASING.md',
    'docs/ZAPSTORE_PUBLISHING.md', 'docs/BUILD_CHANNELS.md',
    'docs/stable-2.6-preparation.md', 'docs/PGN_ANALYSIS.md',
    'docs/RECENT_GAMES_PGN_EXPORT.md', 'docs/release-notes/v2.6.0.md',
    'tool/hardening/RELEASE_CHECKS.md',
    'docs/CONTINUATION_ELECTRONIC_BOARD.md', 'docs/ELECTRONIC_BOARD_CONTINUATION.md',
    'docs/verification-beta13.md', 'docs/verification-beta14.md',
    'docs/verification-beta16.md', 'docs/verification-beta18.md',
    'docs/verification-beta19.md', 'docs/hardening-beta12.md',
    'docs/L10N_REVIEW.md', 'docs/NATIVE_REVIEW.md', 'docs/CHESS_LANGUAGE_REVIEW.md',
    'docs/LANGUAGE_EXPANSION_REVIEW.md', 'docs/TRANSLATION_QUALITY_REVIEW.md',
    'docs/LICHESS_TERMINOLOGY.md',
)


def anchors(path):
    content = path.read_text()
    result = set(re.findall(r'<a\s+id="([^"]+)"', content))
    occurrences = {}
    for heading in re.findall(r'^#{1,6}\s+(.+)$', content, re.MULTILINE):
        heading = re.sub(r'<[^>]+>', '', heading)
        slug = re.sub(r'[^\w\- ]', '', heading.lower()).replace(' ', '-')
        count = occurrences.get(slug, 0)
        occurrences[slug] = count + 1
        result.add(slug + (f'-{count}' if count else ''))
    return result


class DocumentationLinksTest(unittest.TestCase):
    def test_document_links_and_forwarding_fragments(self):
        documents = {ROOT / name for name in DOCUMENTS}
        for directory in ('l10n', 'history', 'verification'):
            documents.update((ROOT / 'docs' / directory).glob('*.md'))
        documents.update((ROOT / 'docs/screenshots').glob('*provenance.md'))
        errors = []
        for document in sorted(documents):
            content = re.sub(r'```[\s\S]*?```', '', document.read_text())
            links = re.findall(r'\]\(([^\s)]+)\)', content)
            links += re.findall(r'(?:href|src)="([^"]+)"', content)
            for link in links:
                if re.match(r'(?:[a-zA-Z]+:|//)', link):
                    continue
                parsed = urlsplit(link)
                target = ((document.parent / unquote(parsed.path)).resolve()
                          if parsed.path else document)
                if not target.exists():
                    errors.append(f'{document.relative_to(ROOT)}: missing {link}')
                elif (parsed.fragment and target.suffix == '.md'
                      and unquote(parsed.fragment) not in anchors(target)):
                    errors.append(f'{document.relative_to(ROOT)}: missing anchor {link}')
        self.assertEqual([], errors, '\n'.join(errors))

    def test_public_website_readme_fragments_remain_available(self):
        # mobilemaia.org uses these URLs; keep them through README moves.
        required = {
            'feature-guide', 'chessnut-electronic-board-play',
            'install-and-update-with-obtainium', 'download-and-install',
            'availability-and-forks', 'credits-and-attributions',
        }
        self.assertTrue(required <= anchors(ROOT / 'README.md'))


if __name__ == '__main__':
    unittest.main()
