"""Stable documentation paths and public website fragment compatibility."""

from pathlib import Path
import re
import subprocess
import tempfile
import unittest
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]


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


def tracked_documents(root):
    names = subprocess.check_output(
        ['git', '-C', str(root), 'ls-files', '-z', '--', '*.md'],
    ).decode().split('\0')
    # Vendored upstream changelogs can link to omitted upstream-only files.
    # They are pinned third-party source, not repository-maintained guidance.
    return {root / name for name in names
            if name and not name.startswith('third_party/')}


def link_errors(root, documents):
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
                errors.append(f'{document.relative_to(root)}: missing {link}')
            elif (parsed.fragment and target.suffix == '.md'
                  and unquote(parsed.fragment) not in anchors(target)):
                errors.append(f'{document.relative_to(root)}: missing anchor {link}')
    return errors


class DocumentationLinksTest(unittest.TestCase):
    def test_document_links_and_forwarding_fragments(self):
        errors = link_errors(ROOT, tracked_documents(ROOT))
        self.assertEqual([], errors, '\n'.join(errors))

    def test_new_markdown_is_checked_without_a_handwritten_file_list(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary).resolve()
            subprocess.run(['git', 'init', '-q', str(root)], check=True)
            for name in ('PRIVACY.md', 'SECURITY.md', 'docs/ARCHITECTURE.md',
                         'docs/new-feature.md'):
                path = root / name
                path.parent.mkdir(exist_ok=True)
                path.write_text('[Missing](missing.md)\n')
            subprocess.run(['git', '-C', str(root), 'add', '.'], check=True)
            documents = tracked_documents(root)
            self.assertEqual(4, len(documents))
            self.assertEqual(4, len(link_errors(root, documents)))

    def test_public_website_readme_fragments_remain_available(self):
        # mobilemaia.org uses these URLs; keep them through README moves.
        required = {
            'feature-guide', 'chessnut-electronic-board-play',
            'install-and-update-with-obtainium', 'download-and-install',
            'availability-and-forks', 'about-privacy-and-licences',
        }
        self.assertTrue(required <= anchors(ROOT / 'README.md'))


if __name__ == '__main__':
    unittest.main()
