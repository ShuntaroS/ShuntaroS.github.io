#!/usr/bin/env python3
"""Fetch recent PubMed records for the Quarto site."""

from __future__ import annotations

import argparse
import json
import pathlib
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone


BASE = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils"
DEFAULT_QUERY = '"Sato, Shuntaro"[Full Author Name]'
ROOT = pathlib.Path(__file__).resolve().parents[1]


def fetch_json(endpoint: str, params: dict[str, str | int]) -> dict:
    query = urllib.parse.urlencode(params)
    url = f"{BASE}/{endpoint}?{query}"
    request = urllib.request.Request(url, headers={"User-Agent": "shuntaros.github.io quarto pubmed updater"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def article_id(record: dict, idtype: str) -> str:
    for item in record.get("articleids", []):
        if item.get("idtype") == idtype:
            value = item.get("value", "")
            if idtype == "pmc":
                return value.replace("pmc-id: ", "").replace(";", "").strip()
            return value
    return ""


def author_text(record: dict, limit: int = 8) -> str:
    authors = [author.get("name", "") for author in record.get("authors", []) if author.get("name")]
    if len(authors) > limit:
        return ", ".join(authors[:limit]) + ", et al."
    return ", ".join(authors)


def normalize_record(record: dict) -> dict:
    sort_date = record.get("sortpubdate", "")
    year = sort_date[:4] if sort_date else record.get("pubdate", "")[:4]
    volume = record.get("volume", "")
    issue = record.get("issue", "")
    pages = record.get("pages", "")
    citation_parts = [record.get("source", "")]
    if year:
        citation_parts.append(year)
    volume_issue = volume
    if issue:
        volume_issue += f"({issue})" if volume_issue else f"({issue})"
    if volume_issue:
        citation_parts.append(volume_issue)
    if pages:
        citation_parts.append(pages)

    return {
        "pmid": record.get("uid", ""),
        "pmcid": article_id(record, "pmc") or article_id(record, "pmcid"),
        "doi": article_id(record, "doi"),
        "title": record.get("title", "").rstrip("."),
        "authors": author_text(record),
        "journal": record.get("fulljournalname") or record.get("source", ""),
        "source": record.get("source", ""),
        "year": year,
        "pubdate": record.get("pubdate", ""),
        "citation": ". ".join(part for part in citation_parts if part) + ".",
        "sortpubdate": sort_date,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--query", default=DEFAULT_QUERY)
    parser.add_argument("--retmax", type=int, default=12)
    parser.add_argument("--output", default=str(ROOT / "data" / "pubmed.json"))
    parser.add_argument("--skip-render", action="store_true", help="Do not regenerate Quarto include files.")
    args = parser.parse_args()

    search = fetch_json(
        "esearch.fcgi",
        {
            "db": "pubmed",
            "retmode": "json",
            "retmax": args.retmax,
            "sort": "pub date",
            "term": args.query,
        },
    )
    ids = search.get("esearchresult", {}).get("idlist", [])
    if not ids:
        print("No PubMed records found.", file=sys.stderr)
        return 1

    time.sleep(0.34)
    summary = fetch_json(
        "esummary.fcgi",
        {
            "db": "pubmed",
            "retmode": "json",
            "id": ",".join(ids),
        },
    )
    result = summary.get("result", {})
    records = [normalize_record(result[pmid]) for pmid in result.get("uids", []) if pmid in result]

    output = {
        "query": args.query,
        "updated_at": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "count": int(search.get("esearchresult", {}).get("count", 0)),
        "items": records,
    }
    path = pathlib.Path(args.output)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(records)} PubMed records to {path}")

    if not args.skip_render:
        subprocess.run(["ruby", str(ROOT / "scripts" / "render_site_data.rb")], check=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
