#!/usr/bin/env python3
"""Add a learning card to the clover-learnings page.

Usage:
    python3 add_learning.py --date "Oct 16, 2026" --title "My title" --body "Paragraph one.

    Paragraph two with **highlighted** words."

Convention: **text** becomes a green highlight span. New cards are appended
after the last card (page reads oldest-first, top to bottom).
"""
import argparse
import html
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent
PAGE = REPO / "index.html"

CARD = """            <article class="card">
                <div class="date">{date}</div>
                <h2 class="card-title">{title}</h2>
                <div class="card-content">
{paras}
                </div>
            </article>
"""


def render_body(body: str) -> str:
    paras = []
    for chunk in body.strip().split("\n\n"):
        chunk = chunk.strip()
        if not chunk:
            continue
        # escape first, then turn **x** into highlight spans
        esc = html.escape(chunk)
        esc = re.sub(r"\*\*(.+?)\*\*", r'<span class="highlight">\1</span>', esc)
        paras.append(f"                    <p>{esc}</p>")
    return "\n".join(paras)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--date", required=True)
    p.add_argument("--title", required=True)
    p.add_argument("--body", required=True)
    a = p.parse_args()

    text = PAGE.read_text()
    marker = "        </main>"
    if marker not in text:
        sys.exit("ERROR: </main> marker not found in index.html")

    card = CARD.format(
        date=html.escape(a.date),
        title=html.escape(a.title),
        paras=render_body(a.body),
    )
    text = text.replace(marker, card + marker, 1)
    PAGE.write_text(text)
    print(f"Added card: {a.title!r} ({a.date})")


if __name__ == "__main__":
    main()
