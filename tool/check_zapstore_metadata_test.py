import unittest

from check_zapstore_metadata import check_description, markdown_description


class ZapstoreDescriptionTest(unittest.TestCase):
    HTML = "<b>Play &amp; learn</b><ul><li>One</li><li>Two</li></ul><b>Offline</b>\nNo account."
    MARKDOWN = "**Play & learn**\n\n- One\n- Two\n\n**Offline**\nNo account."

    def test_headings_lists_entities_and_section_boundaries(self):
        self.assertEqual(self.MARKDOWN, markdown_description(self.HTML))
        self.assertEqual([], check_description({"description": self.MARKDOWN}, self.HTML))

    def test_missing_description_and_literal_or_escaped_html_fail(self):
        for value in (None, "", self.HTML, "&lt;b&gt;Play&lt;/b&gt;"):
            with self.subTest(value=value):
                self.assertTrue(check_description({"description": value}, self.HTML))

    def test_changed_store_wording_cannot_silently_drift(self):
        self.assertTrue(check_description({"description": self.MARKDOWN}, self.HTML + " New feature."))

    def test_new_html_construct_requires_review(self):
        with self.assertRaises(ValueError):
            markdown_description('<a href="https://example.com">Link</a>')
