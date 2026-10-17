#!/usr/bin/env python3
"""Keep Zapstore's Markdown description aligned with the F-Droid listing."""

import argparse
from html import unescape
from html.parser import HTMLParser
from pathlib import Path
import re

import yaml


class DescriptionParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.parts = []

    def handle_starttag(self, tag, attrs):
        if attrs or tag not in ("b", "ul", "li"):
            raise ValueError(f"Review conversion for unsupported HTML: {tag}")
        self.parts.append({"b": "**", "ul": "\n\n", "li": "- "}[tag])

    def handle_endtag(self, tag):
        if tag not in ("b", "ul", "li"):
            raise ValueError(f"Review conversion for unsupported HTML: {tag}")
        self.parts.append({"b": "**", "ul": "\n", "li": "\n"}[tag])

    def handle_data(self, data):
        self.parts.append(data)


def markdown_description(html):
    parser = DescriptionParser()
    parser.feed(html)
    parser.close()
    markdown = re.sub(r"(\*\*)\n", r"\1\n\n", "".join(parser.parts))
    return re.sub(r"\n{3,}", "\n\n", markdown).strip()


def check_description(config, html):
    description = config.get("description") if isinstance(config, dict) else None
    if not isinstance(description, str) or not description.strip():
        return ["zapstore.yaml needs an explicit Markdown description; do not fall back to Fastlane HTML"]
    if re.search(r"</?[a-zA-Z][^>]*>", unescape(description)):
        return ["Zapstore description contains HTML; Android renders Markdown, unlike the website"]
    if description.strip() != markdown_description(html):
        return ["Zapstore description differs from the F-Droid wording/format conversion; run --print-description and review"]
    return []


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--print-description", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    html = (root / "fastlane/metadata/android/en-US/full_description.txt").read_text()
    if args.print_description:
        print(markdown_description(html))
    else:
        issues = check_description(yaml.safe_load((root / "zapstore.yaml").read_text()), html)
        if issues:
            raise SystemExit("\n".join(issues))
        print("Zapstore Markdown description matches the F-Droid listing")
