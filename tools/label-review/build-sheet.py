#!/usr/bin/env python3
"""Build the review workbook: one line per laboratory label, seven columns.

    python3 tools/label-review/build-sheet.py [labels_dir]

Reads the pass-1 tables written by pass1-amr.R and the proposals
(`claude-pass-organisms.csv`, `claude-pass-antibiotics.csv`), taken from the
labels directory when they are there and from next to this script otherwise.
Writes `revue-libelles.xlsx` into the labels directory.

Columns: laboratory label, AMR 3.1.0, ORCHIDEE v2, proposed mapping, point to
check, and two columns that only the microbiologist fills. The sheet carries no
count. The decision columns are always written empty.

The build stops when a label that carries a result has no proposal: every line
must carry a best guess before it reaches the reviewer.
"""
import csv
import sys
from datetime import date
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "outputs" / "label-review"

HEADERS = ["Libellé laboratoire", "AMR 3.1.0", "ORCHIDEE v2 (historique)", "Correspondance proposée",
           "Point à vérifier / motif", "Décision microbiologiste", "Correction / commentaire"]
WIDTHS = [35, 34, 30, 43, 57, 23, 43]
DECISIONS = "Accepter,Corriger,Incertain"
INK, HEADER_FILL, INPUT_FILL = "FF243247", "FF30465D", "FFFFF4CC"
NOTES = [
    "À remplir : F et G (jaune). Accepter = valider D ; Corriger = écrire la correction en G ; "
    "Incertain = préciser la question en G.",
    "Source : libellés du laboratoire ({today}). AMR 3.1.0 : suggestion automatique, non validée. "
    "ORCHIDEE v2 : ancien dictionnaire, antibiotiques seulement. Comportement actuel non vérifié.",
    "Propositions à valider, triées par libellé. La validation porte sur le sens du libellé ; "
    "les règles de calcul des indicateurs sont à traiter séparément.",
]


def read_csv(path):
    with open(path, encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def proposals(name):
    """Proposals written from a hospital's label list stay with it; the versioned ones are examples."""
    path = DIR / name if (DIR / name).exists() else HERE / name
    return {row["source_label"]: row for row in read_csv(path)}


def norm(text):
    return " ".join(text.lower().split())


def sort_key(row):
    """Alphabetical order by label, upper and lower case together."""
    return (row[0].casefold(), row[0])


def amr(src):
    return f'{src["amr_code"]} · {src["amr_name"]}' if src["amr_code"] else "(aucune)"


def has_result(src):
    return src["has_result"].upper() == "TRUE"


def organism_rows():
    mine = proposals("claude-pass-organisms.csv")
    rows, missing = [], []
    for src in read_csv(DIR / "organism-pass1.csv"):
        label = src["source_label"]
        if not has_result(src):   # never reaches an antibiogram: nothing to map
            continue
        line = mine.get(label)
        if line is None:
            # No written proposal is needed only when AMR's name is the label itself.
            if src["amr_status"] != "recognised" or norm(src["amr_name"]) != norm(label):
                missing.append(label)
                continue
            line = {"proposal": f'{src["amr_name"]} [{src["amr_code"]}]', "note": ""}
        rows.append([label, amr(src), "Non vérifié", line["proposal"], line["note"], "", ""])
    return sorted(rows, key=sort_key), missing


def antibiotic_rows():
    mine = proposals("claude-pass-antibiotics.csv")
    rows, missing = [], []
    for src in read_csv(DIR / "antibiotic-pass1.csv"):
        label = src["source_label"]
        line = mine.get(label)
        if has_result(src):
            if line is None:
                missing.append(label)
                continue
            legacy = {"": "Non renseigné", "NA": "(hors molécule)"}.get(src["legacy_v2"], src["legacy_v2"])
            rows.append([label, amr(src), legacy, line["proposal"], line["note"], "", ""])
        elif line is not None:
            # A label of the same field with no S/I/R result: a comment, a search, a gene test.
            # It is shown only when a proposal says it speaks about resistance.
            rows.append([label, "Non évalué", "Non vérifié", line["proposal"], line["note"], "", ""])
    return sorted(rows, key=sort_key), missing


def height(row):
    """Row height that shows the longest wrapped cell (Arial 10)."""
    lines = max(-(-len(str(cell)) // max(int(width * 1.1), 1)) for cell, width in zip(row, WIDTHS))
    return max(18.0, 13.0 * max(lines, 1) + 6.0)


def write_tab(ws, title, rows):
    ws.sheet_view.showGridLines = False
    ink = Font(name="Arial", size=10, color=INK)
    ws["A2"] = f"{title} — revue des correspondances"
    ws["A2"].font = Font(name="Arial", size=15, bold=True, color=INK)
    ws.merge_cells("A2:G2")
    for i, note in enumerate(NOTES, 3):
        cell = ws.cell(i, 1, note.format(today=date.today().strftime("%d/%m/%Y")))
        cell.font = ink
        cell.alignment = Alignment(wrap_text=True, vertical="top")
        ws.merge_cells(start_row=i, start_column=1, end_row=i, end_column=7)
        ws.row_dimensions[i].height = 23
    for j, (header, width) in enumerate(zip(HEADERS, WIDTHS), 1):
        cell = ws.cell(6, j, header)
        cell.font = Font(name="Arial", size=10, bold=True, color="FFFFFFFF")
        cell.fill = PatternFill("solid", fgColor=HEADER_FILL)
        cell.alignment = Alignment(wrap_text=True, vertical="center")
        ws.column_dimensions[get_column_letter(j)].width = width
    ws.row_dimensions[6].height = 32
    for i, row in enumerate(rows, 7):
        for j, value in enumerate(row, 1):
            cell = ws.cell(i, j, value or None)
            cell.font = ink
            cell.alignment = Alignment(wrap_text=True, vertical="top")
            if j >= 6:
                cell.fill = PatternFill("solid", fgColor=INPUT_FILL)
        ws.row_dimensions[i].height = height(row)
    last = 6 + len(rows)
    if rows:
        choice = DataValidation(type="list", formula1=f'"{DECISIONS}"', allow_blank=True)
        ws.add_data_validation(choice)
        choice.add(f"F7:F{last}")
        ws.auto_filter.ref = f"A6:G{last}"
    ws.freeze_panes = "B7"


def main():
    organisms, missing_mo = organism_rows()
    antibiotics, missing_ab = antibiotic_rows()
    if missing_mo or missing_ab:
        for kind, labels in (("organism", missing_mo), ("antibiotic", missing_ab)):
            for label in labels:
                print(f"No proposal for {kind} label: {label}", file=sys.stderr)
        sys.exit("Every label that carries a result needs a proposal before the sheet is built.")
    wb = Workbook()
    write_tab(wb.active, "Micro-organismes", organisms)
    wb.active.title = "Micro-organismes"
    write_tab(wb.create_sheet("Antibiotiques et tests"), "Antibiotiques et tests", antibiotics)
    wb.save(DIR / "revue-libelles.xlsx")
    print(f"Organism labels: {len(organisms)}; antibiotic and test labels: {len(antibiotics)}")
    print("Wrote revue-libelles.xlsx")


if __name__ == "__main__":
    main()
