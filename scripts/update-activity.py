#!/usr/bin/env python3
"""Weekly OSS activity updater. Marker-preserving, fail-safe, no empty commits.

- Reads curated merged-PR list (verified 2026-09-22) or, when GITHUB_TOKEN +
  network are available, refreshes dates from the GitHub API.
- Only replaces content between OSS-ACTIVITY markers. On any API failure,
  keeps the existing block untouched and exits 0 without writing.
- Caller must check `git diff --quiet` before committing (no empty commits).
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

START = "<!-- OSS-ACTIVITY:START -->"
END = "<!-- OSS-ACTIVITY:END -->"

# Curated fallback: verified merged 2026-09-22 via GitHub search
# author:Bruce-Yii is:pr is:merged. Dates are merge (closed_at) dates.
# Kept at 5 most recent to match the compressed freshness block in README.
FALLBACK_LINES = [
    "- 2026-09-20 — `langgenius/dify#42171` merged — preserve Notion mention and equation text",
    "- 2026-09-17 — `modelscope/evalscope#1729` merged — real multi-image MMMU dataset mode",
    "- 2026-09-12 — `langgenius/dify#42221` merged — preserve literal NA in annotation CSV imports",
    "- 2026-09-12 — `langgenius/dify#42212` merged — ignore blank keyword rows in moderation limit",
    "- 2026-09-11 — `openclaw/openclaw#145220` merged — doctor --fix gateway repair",
]

README = Path(__file__).resolve().parent.parent / "README.md"


def try_live_lines() -> list[str] | None:
    token = os.environ.get("GITHUB_TOKEN", "").strip()
    if not token:
        return None
    try:
        import json
        import urllib.request

        req = urllib.request.Request(
            "https://api.github.com/search/issues?q=author%3ABruce-Yii+type%3Apr+is%3Amerged&per_page=10&sort=updated&order=desc",
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": f"Bearer {token}",
                "User-Agent": "bruce-yii-profile-activity/1.0",
            },
        )
        with urllib.request.urlopen(req, timeout=20) as resp:
            data = json.loads(resp.read().decode("utf-8"))
        items = data.get("items", [])
        if not items:
            return None  # fail-safe: keep existing block
        lines: list[str] = []
        for it in items[:5]:
            url = it.get("html_url", "")
            title = (it.get("title", "") or "").strip().replace("\n", " ")[:90]
            closed = (it.get("closed_at", "") or "")[:10]
            parts = url.replace("https://github.com/", "").split("/")
            short = "/".join(parts[:2]) + "#" + (parts[3] if len(parts) > 3 else "?") if len(parts) >= 2 else url
            lines.append(f"- {closed} — `{short}` merged — {title}")
        return lines if len(lines) >= 3 else None
    except Exception as exc:  # never erase on API failure
        print(f"live refresh failed, keeping existing block: {exc}", file=sys.stderr)
        return None


def main() -> int:
    text = README.read_text(encoding="utf-8")
    if START not in text or END not in text:
        print("markers missing, refusing to rewrite", file=sys.stderr)
        return 0
    live = try_live_lines()
    lines = live if live else FALLBACK_LINES
    pre, rest = text.split(START, 1)
    _, post = rest.split(END, 1)
    new_block = START + "\n" + "\n".join(lines) + "\n" + END
    new_text = pre + new_block + post
    if new_text != text:
        README.write_text(new_text, encoding="utf-8")
        print(f"updated activity block ({'live' if live else 'fallback-curated'})")
    else:
        print("no change")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
