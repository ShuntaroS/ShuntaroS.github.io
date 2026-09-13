#!/usr/bin/env python3
"""Check rendered pages using only the Python standard library.

Run after `quarto render`. This checks internal destinations, language navigation,
landmarks, duplicate IDs, and unresolved Markdown; visual checks remain separate.
"""
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
SITE = ROOT / "_site"
NAV = {
    "ja": ["research", "publications", "seminars", "cv", "contact"],
    "en": ["research", "publications", "cv", "contact"],
}


class Page(HTMLParser):
    def __init__(self, path):
        super().__init__()
        self.path = path
        self.ids = []
        self.references = []
        self.nav = []
        self.in_nav = False
        self.lang = None
        self.h1_count = 0
        self.main_count = 0
        self.text = []
        self.feed(path.read_text(encoding="utf-8"))

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        classes = attrs.get("class", "").split()
        if "id" in attrs:
            self.ids.append(attrs["id"])
        if tag == "html":
            self.lang = attrs.get("lang")
        if tag == "main":
            self.main_count += 1
        if tag == "h1":
            self.h1_count += 1
        if tag == "nav" and "site-nav" in classes:
            self.in_nav = True
        if tag == "a" and self.in_nav and "site-brand" not in classes:
            self.nav.append(attrs)
        for key in ("href", "src"):
            if key in attrs:
                self.references.append(attrs[key])

    def handle_endtag(self, tag):
        if tag == "nav":
            self.in_nav = False

    def handle_data(self, text):
        self.text.append(text)


def check():
    errors = []
    pages = {}
    inputs = sorted(ROOT.glob("*.qmd")) + sorted((ROOT / "en").glob("*.qmd"))
    for source in inputs:
        rendered = SITE / source.relative_to(ROOT).with_suffix(".html")
        if not rendered.is_file():
            errors.append(f"Missing output: {rendered.relative_to(SITE)}")
        else:
            pages[rendered.resolve()] = Page(rendered)

    for path, page in pages.items():
        label = path.relative_to(SITE)
        lang = "en" if label.parts[0] == "en" else "ja"
        slug = path.stem
        if page.lang != lang:
            errors.append(f"{label}: expected language {lang}, got {page.lang}")
        if page.h1_count != 1 or page.main_count != 1:
            errors.append(f"{label}: expected one h1 and one main landmark")
        duplicates = [key for key, count in Counter(page.ids).items() if count > 1]
        if duplicates:
            errors.append(f"{label}: duplicate IDs {duplicates}")
        if ":::" in "".join(page.text):
            errors.append(f"{label}: unresolved fenced div")
        actual = [link["href"] for link in page.nav[:-1]]
        expected = [f"{key}.html" for key in NAV[lang]]
        if actual != expected:
            errors.append(f"{label}: navigation mismatch: {actual}")
        current = [link["href"] for link in page.nav if link.get("aria-current") == "page"]
        if current != ([] if slug == "index" else [f"{slug}.html"]):
            errors.append(f"{label}: incorrect active navigation")
        other = "ja" if lang == "en" else "en"
        counterpart = slug if slug in NAV[other] + ["index"] else "research"
        expected_switch = ("../" if lang == "en" else "en/") + counterpart + ".html"
        switch = page.nav[-1] if page.nav else {}
        if switch.get("href") != expected_switch or switch.get("hreflang") != other:
            errors.append(f"{label}: incorrect language counterpart")

        for reference in page.references:
            url = urlsplit(reference)
            if url.scheme or url.netloc:
                continue
            target = (SITE / unquote(url.path).lstrip("/")) if url.path.startswith("/") else path.parent / unquote(url.path)
            if not url.path:
                target = path
            if target.is_dir():
                target /= "index.html"
            target = target.resolve()
            if not target.exists():
                errors.append(f"{label}: missing internal target {reference}")
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
                errors.append(f"{label}: missing anchor {reference}")
    if not (SITE / ".nojekyll").is_file():
        errors.append("Missing GitHub Pages .nojekyll marker")
    if errors:
        raise SystemExit("\n".join(errors))
    print(f"PASS: {len(pages)} pages, internal links/assets/anchors, language navigation, headings, IDs, and .nojekyll")


if __name__ == "__main__":
    check()
