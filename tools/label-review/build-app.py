#!/usr/bin/env python3
"""Build the review app: one self-contained HTML file from the review workbook.

    python3 tools/label-review/build-app.py [workbook.xlsx [app.html]]

Reads the two tabs of the seven-column workbook written by build-sheet.py (or
edited by hand) and writes a single HTML file that a microbiologist opens in
any browser, with no installation and no network. Each line is accepted in one
click, or corrected, or marked uncertain. Decisions are kept in the browser
and exported as a CSV file that goes back with the workbook.

The file holds the label list and the proposals, nothing else. Decisions
already filled in the workbook are loaded as a starting point.
"""
import json
import sys
from pathlib import Path

from openpyxl import load_workbook

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
DEFAULT = ROOT / "outputs" / "label-review" / "revue-libelles.xlsx"
TABS = {"Micro-organismes": "mo", "Antibiotiques et tests": "ab"}
DECISIONS = {"Accepter": "ok", "Corriger": "fix", "Incertain": "unsure"}


def read_items(path):
    wb = load_workbook(path, read_only=True)
    items = []
    for title, tab in TABS.items():
        ws = wb[title]
        rows = ws.iter_rows(values_only=True)
        for row in rows:   # skip the notes down to the header line
            if row and row[0] == "Libellé laboratoire":
                break
        for row in rows:
            if not row or not row[0]:
                continue
            label, amr, v2, proposal, note, decision, comment = (list(row) + [None] * 7)[:7]
            items.append({"t": tab, "l": str(label), "a": amr or "", "v": v2 or "", "p": proposal or "",
                          "n": note or "", "d": DECISIONS.get(decision or "", ""), "c": comment or ""})
    return items


def main():
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT
    target = Path(sys.argv[2]) if len(sys.argv) > 2 else source.with_suffix(".html")
    items = read_items(source)
    data = json.dumps(items, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    target.write_text((HERE / "review-app.html").read_text(encoding="utf-8").replace("__DATA__", data),
                      encoding="utf-8")
    print(f"{len(items)} lines; wrote {target}")


if __name__ == "__main__":
    main()
