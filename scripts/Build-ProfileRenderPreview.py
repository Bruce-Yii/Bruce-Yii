#!/usr/bin/env python3
"""Render a GitHub profile README the way GitHub renders it, for layout measurement.

Usage:
    python Build-ProfileRenderPreview.py <readme> <out.html> [--width 320]
    python Build-ProfileRenderPreview.py <readme> <out.html> --baseline <git-ref>

Why this exists
---------------
The profile README is hand-laid-out HTML inside Markdown, and this project has
been bitten twice by layout that only breaks on GitHub's real renderer: a card
table that overflowed horizontally at 320px, and constellation icons whose
baselines drifted apart by 10px. Both were invisible in the source and both
needed a browser to see. This builds a page you can open in any browser, at any
container width, that reproduces the geometry.

Three corrections separate it from a plain Markdown render, and all three come
from measurements recorded in Measure-*.json against the live site:

  1. GitHub's sanitizer strips inline `style`, so
     `style="width:100%; table-layout:fixed"` is dead markup in production. It
     is stripped here too, or the local render honours table-layout:fixed and
     reports a clean fit the live page never had. Confirmed live: getAttribute
     ('style') is empty on the rendered table even though the source carries one.
  2. GitHub's stylesheet forces every Markdown table to `display:block;
     width:max-content; max-width:100%; overflow:auto`. Without that rule a wide
     table just squeezes, and the measurement says nothing. With it, a table
     wider than its container reports scrollWidth > clientWidth, which is the
     overflow this project has to catch.
  3. The HTML comes from GitHub's own POST /markdown endpoint, so the markup
     (including the <markdown-accessiblity-table> wrapper, the dark-mode
     <picture> rewrite and the sanitiser-visible attribute set) is production
     markup rather than a local Markdown library's approximation.

The injected script reports, per table: client vs scroll width, per-row icon
offset spread, per-column widths, and the widest cell with its text. The widest
cell is the part that matters when a table grows — a Markdown table's column
width is the max max-content over its rows, so knowing *which cell* drives the
width is what turns "the table got wider" into an actionable edit.

Width is driven explicitly with ?w=<px> instead of being inferred from the
viewport. GitHub's container width at a given viewport is not a fixed function
of that viewport, because the page adds padding this file does not model, so
absolute clientWidth values here differ from the live site. Overflow and icon
spread are the comparable numbers. Load ?w=320, ?w=360, ?w=390, ?w=1012.

This is a simulation, not the live renderer. The Measure-*.json records were
taken against github.com itself; treat this file as a fast regression check on
geometry, and re-measure live before trusting a number that matters.
"""

import argparse
import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

# The subset of GitHub's markdown-body rules that governs table geometry, pinned
# from the values this project measured on the live site: 13px horizontal cell
# padding per side and a 1px cell border.
CSS = """
* { box-sizing: border-box; }
body { margin: 0; font-family: -apple-system, "Segoe UI", Helvetica, Arial, sans-serif;
       font-size: 16px; line-height: 1.5; color: #1f2328; background: #fff; }
.markdown-body { padding: 16px; max-width: 1012px; margin: 0 auto; }
.markdown-body table { display: block; width: max-content; max-width: 100%;
                       overflow: auto; border-spacing: 0; border-collapse: collapse; }
.markdown-body table th, .markdown-body table td { padding: 6px 13px; border: 1px solid #d1d9e0; }
.markdown-body table tr { background-color: #fff; }
.markdown-body img { max-width: 100%; box-sizing: content-box; }
.markdown-body sub { font-size: 0.8em; }
"""

MEASURE_JS = r"""
<script>
// Container width is forced rather than inferred; see the module docstring.
const forced = new URLSearchParams(location.search).get('w');
if (forced) {
  const a = document.querySelector('.markdown-body');
  a.style.width = forced + 'px';
  a.style.maxWidth = forced + 'px';
}

function run() {
  const out = { forcedWidth: forced || 'viewport', viewport: window.innerWidth, tables: [] };

  document.querySelectorAll('table').forEach((t, index) => {
    const s = {
      index,
      rows: t.querySelectorAll('tr').length,
      clientWidth: t.clientWidth,
      scrollWidth: t.scrollWidth,
      // Positive means the table scrolls sideways inside its own overflow box.
      // GitHub applies that same overflow, so a positive value is contained
      // rather than a page-level break, but it is still the number that grew
      // when a cell got wider.
      overflow: t.scrollWidth - t.clientWidth,
    };

    // Icon baseline spread per row: each icon's distance from the top of its own
    // cell, then max-minus-min across the row. Zero means the icons line up.
    // This is the metric that caught the 10px constellation drift in v2.4.
    s.iconOffsetSpread = Array.from(t.querySelectorAll('tr')).map(tr => {
      const offsets = Array.from(tr.querySelectorAll('td'))
        .map(td => {
          const img = td.querySelector('img');
          return img ? Math.round(img.getBoundingClientRect().top - td.getBoundingClientRect().top) : null;
        })
        .filter(v => v !== null);
      return offsets.length < 2 ? null : Math.max(...offsets) - Math.min(...offsets);
    });

    // A Markdown table's column width is the max max-content over its rows, so
    // the widest cell is what to edit when the table grows.
    s.colWidths = Array.from(t.querySelectorAll('tr')).map(tr =>
      Array.from(tr.querySelectorAll('td')).map(td => Math.round(td.getBoundingClientRect().width))
    );
    s.widest = { w: 0, row: -1, col: -1 };
    s.colWidths.forEach((row, r) => row.forEach((w, c) => {
      if (w > s.widest.w) s.widest = { w, row: r, col: c };
    }));
    if (s.widest.row >= 0) {
      const cell = t.querySelectorAll('tr')[s.widest.row].querySelectorAll('td')[s.widest.col];
      s.widestCellText = cell.textContent.replace(/\s+/g, ' ').trim().slice(0, 110);
    }
    out.tables.push(s);
  });

  const pre = document.createElement('pre');
  pre.id = 'measure';
  pre.textContent = JSON.stringify(out, null, 1);
  document.body.prepend(pre);
  document.title = 'measured';
}

if (document.readyState === 'complete') run();
else window.addEventListener('load', run);
</script>
"""


def render_markdown(text):
    """GFM-render through GitHub's own endpoint so the HTML matches production.

    The payload goes in as a file: a multi-kilobyte README on the command line
    runs into the Windows command-length limit and gh fails before it posts.
    The endpoint replies with an HTML body, not JSON, unless an Accept header
    asks otherwise.
    """
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as fh:
        json.dump({"text": text, "mode": "gfm"}, fh)
        payload = Path(fh.name)
    try:
        result = subprocess.run(
            ["gh", "api", "-X", "POST", "markdown", "--input", str(payload)],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            sys.exit(f"gh api markdown failed: {result.stderr.strip()}")
        return result.stdout
    finally:
        payload.unlink(missing_ok=True)


def read_readme(path, baseline):
    if baseline:
        result = subprocess.run(
            ["git", "-C", str(path.parent), "show", f"{baseline}:{path.name}"],
            capture_output=True, text=True, check=True,
        )
        return result.stdout
    return path.read_text(encoding="utf-8")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("readme", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--width", type=int, default=320,
                    help="container width baked into the page; override at load with ?w=")
    ap.add_argument("--baseline", help="git ref to read the README from instead of the working tree")
    args = ap.parse_args()

    body = read_readme(args.readme, args.baseline)
    html = render_markdown(body)

    # Apply the sanitizer's style-stripping. Without this the render honours
    # table-layout:fixed and reports a fit the live page never had.
    stripped = re.sub(r'\sstyle="[^"]*"', "", html)

    page = (
        '<!doctype html><html><head><meta charset="utf-8">'
        f"<style>{CSS}</style></head>"
        f'<body><article class="markdown-body" style="width:{args.width}px;max-width:{args.width}px">'
        f"{stripped}</article>{MEASURE_JS}</body></html>"
    )
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(page, encoding="utf-8")

    print(json.dumps({
        "out": str(args.out),
        "baked_width": args.width,
        "html_bytes": len(page),
        "tables": len(re.findall(r"<table", stripped)),
        # Must be 0. A non-zero count means the style-stripping regressed and
        # every width in this render is optimistic.
        "inline_styles_left": len(re.findall(r'\sstyle="', stripped)),
    }))


if __name__ == "__main__":
    main()
