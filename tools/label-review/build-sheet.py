#!/usr/bin/env python3
"""Build the review workbook: source label, AMR pass, assistant pass, empty approval.

    python3 tools/label-review/build-sheet.py [inventory_dir]

Reads the pass-1 tables written by pass1-amr.R and the assistant proposals
(`claude-pass-*.csv`), taken from the inventory directory when they are there and
from next to this script otherwise. Writes `revue-libelles.xlsx` and three CSV
registers into the inventory directory. The three answers stay in three separate column groups and
the approval columns are always written empty.

The build stops when a label has no assistant proposal: every line must carry a
best guess before it reaches the reviewer.
"""
import csv
import re
import sys
from datetime import date
from pathlib import Path

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent.parent
DIR = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "outputs" / "label-review"


def proposal_file(name):
    """Proposals written from hospital labels stay with the inventory; the versioned ones are examples."""
    return DIR / name if (DIR / name).exists() else HERE / name

ROW_KIND_FR = {
    "antibiotic_result": "résultat d'antibiotique",
    "assay_result": "test de laboratoire",
    "phenotype_signal": "signal de phénotype",
    "comment": "commentaire ou champ technique",
    "organism": "micro-organisme",
    "not_an_organism": "pas un micro-organisme",
}
TEST_FR = {
    "susceptibility": "antibiogramme",
    "high_level": "résistance de haut niveau",
    "screen": "dépistage",
    "inhibition": "inhibition",
    "combination": "association",
}
FORMULATION_FR = {"iv": "IV", "oral": "voie orale", "trometamol": "trométamol"}
CONTEXT_FR = {"meningitis": "méningite", "cystitis": "cystite", "pneumonia": "pneumonie",
              "other_contexts": "autres contextes"}
CONFIDENCE_FR = {"high": "élevée", "medium": "moyenne", "low": "faible"}
# AMR folds some (molecule, test) pairs into one code. Same identity, two spellings.
AMR_TEST_CODES = {
    ("GEN", "high_level"): "GEH", ("KAN", "high_level"): "KAH", ("STR1", "high_level"): "STH",
    ("TOB", "high_level"): "TOH", ("NOR", "screen"): "NOR-S", ("FOX", "screen"): "FOX-S",
    ("OXA", "screen"): "OXA-S", ("PEN", "screen"): "PEN-S", ("NAL", "screen"): "NAL-S",
    ("PEF", "screen"): "PEF-S", ("TCY", "screen"): "TCY-S", ("CTX", "screen"): "CTX-S",
    ("BLA-S", "screen"): "BLA-S", ("CLI", "screen"): "CLI-S",
}
AGREEMENT_ORDER = ["désaccord", "AMR sans suggestion", "AMR incertain", "accord, précision ajoutée", "accord"]


def read_csv(path):
    with open(path, encoding="utf-8-sig", newline="") as handle:
        return list(csv.DictReader(handle))


def count(value):
    """A count as written by the inventory: a number, or a masked string such as "<10"."""
    if value in ("", None):
        return None
    return int(value) if value.isdigit() else value


def size(value):
    """Sort key for a count that may be masked: "<10" sorts below every shown count."""
    return value if isinstance(value, int) else 5 if value else 0


def years(src):
    return " / ".join(src.get(k, "") for k in ("n_2022", "n_2023", "n_2024"))


def norm(text):
    return " ".join(text.lower().split())


def sort_rows(rows):
    rows.sort(key=lambda r: (AGREEMENT_ORDER.index(r["agreement"]), -size(r["n_results"]), r["source_label"]))
    for i, row in enumerate(rows, 1):
        row["rank"] = i
    return rows


def antibiotic_rows():
    names = {r["code"]: r for r in read_csv(DIR / "amr-antimicrobial-names.csv")}
    proposals = {r["source_label"]: r for r in read_csv(proposal_file("claude-pass-antibiotics.csv"))}
    rows, missing = [], []
    for src in read_csv(DIR / "antibiotic-pass1.csv"):
        label = src["source_label"]
        if src["n_results"] == "0":   # no S/SFP/I/R/ZIT result: see other_field_rows()
            continue
        mine = proposals.get(label)
        if mine is None:
            missing.append(label)
            continue
        kind, test = mine["row_kind"], mine["test"]
        assert kind in ("antibiotic_result", "assay_result", "phenotype_signal", "comment"), label
        assert mine["confidence"] in CONFIDENCE_FR and mine["rationale"], label
        parts = [p for p in mine["molecule"].replace("+", "|").split("|") if p]
        assert all(p in names for p in parts), f"{label}: unknown AMR code in {mine['molecule']}"
        if "|" in mine["molecule"]:
            molecule = " ou ".join(names[p]["name_fr"] for p in parts) + " (identité conjointe)"
        else:
            molecule = " + ".join(names[p]["name_fr"] for p in parts)
        amr = src["amr_code"]
        same = bool(parts) and amr in (mine["molecule"], AMR_TEST_CODES.get((mine["molecule"], test)))
        added = bool(mine["formulation"] or mine["context"] or mine["qualifier"]) or (
            test not in ("", "susceptibility") and amr == mine["molecule"])
        if not parts:
            agreement = "désaccord" if amr else "accord"
        elif not amr:
            agreement = "AMR sans suggestion"
        elif same:
            agreement = "accord, précision ajoutée" if added else "accord"
        else:
            agreement = "désaccord"
        legacy = src.get("legacy_v2", "")
        rows.append({
            "source_label": label,
            "n_results": count(src["n_results"]), "n_isolates": count(src["n_isolates"]),
            "n_diag": count(src["n_diag"]), "years": years(src),
            "sir": " / ".join(src[k] for k in ("n_S", "n_SFP", "n_I", "n_R", "n_ZIT")),
            "tested_on": src["tested_on"],
            "other": (src["n_other_rows"] + (" : " + src["other_values"] if src["other_values"] else ""))
                     if src["n_other_rows"] not in ("", "0") else "",
            "amr": f"{amr} · {src['amr_name']}" if amr else "(aucune)",
            "legacy": "(hors molécule)" if legacy == "NA" else legacy,
            "kind": ROW_KIND_FR[kind],
            "molecule_code": mine["molecule"], "molecule": molecule,
            "test": TEST_FR.get(test, ""), "formulation": FORMULATION_FR.get(mine["formulation"], ""),
            "context": CONTEXT_FR.get(mine["context"], ""), "qualifier": mine["qualifier"],
            "confidence": CONFIDENCE_FR[mine["confidence"]], "rationale": mine["rationale"],
            "agreement": agreement,
            "csv": {**mine, "amr_code": amr, "amr_name": src["amr_name"], "legacy_v2": legacy},
        })
    return sort_rows(rows), missing


def organism_rows():
    proposals = {r["source_label"]: r for r in read_csv(proposal_file("claude-pass-organisms.csv"))}
    rows, missing = [], []
    for src in read_csv(DIR / "organism-pass1.csv"):
        label = src["source_label"]
        mine = proposals.get(label)
        status, amr_name = src["amr_status"], src["amr_name"]
        if mine is None:
            # The only line that needs no written proposal: AMR recognised the
            # label without a flag and returns the label itself as the name.
            if status == "recognised" and norm(label) == norm(amr_name):
                mine = {"proposed_code": src["amr_code"], "proposed_name": amr_name,
                        "proposed_rank": src["amr_rank"], "row_kind": "organism", "confidence": "high",
                        "rationale": "Le libellé est le nom scientifique en vigueur."}
            else:
                missing.append(label)
                continue
        assert mine["confidence"] in CONFIDENCE_FR and mine["rationale"], label
        kind = mine.get("row_kind") or "organism"
        if status == "unmapped":
            agreement = "AMR sans suggestion"
        elif mine["proposed_code"] != src["amr_code"] or kind != "organism":
            agreement = "désaccord"
        elif status == "uncertain":
            agreement = "AMR incertain"
        elif norm(label) != norm(amr_name):
            agreement = "accord, précision ajoutée"
        else:
            agreement = "accord"
        rows.append({
            "source_label": label,
            "n_results": count(src["n_results"]), "n_isolates": count(src["n_isolates"]),
            "n_diag": count(src["n_diag"]), "years": years(src),
            "amr": f"{src['amr_code']} · {amr_name}" if src["amr_code"] else "(aucune)",
            "amr_rank": src["amr_rank"], "amr_status": {"recognised": "reconnu", "uncertain": "incertain",
                                                         "unmapped": "non reconnu"}[status],
            "amr_taxonomy": " · ".join(x for x in (src["amr_gram"], src["amr_order"], src["amr_family"]) if x),
            "kind": ROW_KIND_FR[kind],
            "proposed": mine["proposed_name"], "proposed_code": mine["proposed_code"],
            "proposed_rank": mine["proposed_rank"],
            "confidence": CONFIDENCE_FR[mine["confidence"]], "rationale": mine["rationale"],
            "agreement": agreement,
            "csv": {"source_label": label, "amr_code": src["amr_code"], "amr_name": amr_name,
                    "amr_status": status, "row_kind": kind, "proposed_code": mine["proposed_code"],
                    "proposed_name": mine["proposed_name"], "proposed_rank": mine["proposed_rank"],
                    "confidence": mine["confidence"], "rationale": mine["rationale"]},
        })
    return sort_rows(rows), missing


def other_field_rows():
    """Labels of the antibiotic field that never carry an S/SFP/I/R/ZIT result.

    Only those with a written proposal are shown: the fields that may carry a
    resistance signal. The others are other laboratory analyses.
    """
    path = proposal_file("claude-pass-other-fields.csv")
    proposals = {r["source_label"]: r for r in read_csv(path)} if path.exists() else {}
    rows = []
    for src in read_csv(DIR / "antibiotic-pass1.csv"):
        mine = proposals.get(src["source_label"])
        if src["n_results"] != "0" or mine is None:
            continue
        assert mine["confidence"] in CONFIDENCE_FR and mine["rationale"], src["source_label"]
        rows.append({
            "source_label": src["source_label"], "n_results": count(src["n_other_rows"]),
            "values": src["other_values"], "kind": ROW_KIND_FR[mine["row_kind"]],
            "confidence": CONFIDENCE_FR[mine["confidence"]], "rationale": mine["rationale"], "agreement": "",
            "csv": {**mine, "n_other_rows": src["n_other_rows"]},
        })
    rows.sort(key=lambda r: (-size(r["n_results"]), r["source_label"]))
    for i, row in enumerate(rows, 1):
        row["rank"] = i
    return rows


GROUPS = {  # fill colour per column group
    "Source": "E7E6E6", "Passe 1 · AMR": "DDEBF7", "Passe 2 · Claude": "FFF2CC",
    "Comparaison": "F2F2F2", "Passe 3 · Microbiologiste": "E2EFDA",
}
REVIEW = [("Décision", None, 14), ("Identité validée (si correction)", None, 30),
          ("Commentaire", None, 34), ("Validé par", None, 14), ("Date", None, 12)]
ANTIBIOTIC_COLUMNS = [
    ("Source", [("N°", "rank", 5), ("Libellé source (LBLANA)", "source_label", 30),
                ("Résultats S/SFP/I/R/ZIT", "n_results", 11), ("dont diagnostiques", "n_diag", 11),
                ("Isolats", "n_isolates", 9), ("2022 / 2023 / 2024", "years", 20),
                ("Détail S / SFP / I / R / ZIT", "sir", 22),
                ("Testé sur (libellés d'espèce les plus fréquents, nombre de résultats)", "tested_on", 60),
                ("Autres valeurs de résultat", "other", 22)]),
    ("Passe 1 · AMR", [("Suggestion AMR 3.1.0", "amr", 30), ("Dictionnaire v2 (ancien)", "legacy", 24)]),
    ("Passe 2 · Claude", [("Type de ligne", "kind", 20), ("Code", "molecule_code", 10),
                           ("Molécule proposée", "molecule", 30), ("Test", "test", 16),
                           ("Forme", "formulation", 11), ("Contexte de lecture", "context", 14),
                           ("Qualificatif", "qualifier", 10), ("Confiance", "confidence", 10),
                           ("Justification", "rationale", 70)]),
    ("Comparaison", [("AMR / Claude", "agreement", 18)]),
    ("Passe 3 · Microbiologiste", REVIEW),
]
ORGANISM_COLUMNS = [
    ("Source", [("N°", "rank", 5), ("Libellé source (IDENTIFICATION)", "source_label", 40),
                ("Résultats S/SFP/I/R/ZIT", "n_results", 11), ("dont diagnostiques", "n_diag", 11),
                ("Isolats", "n_isolates", 9), ("2022 / 2023 / 2024", "years", 20)]),
    ("Passe 1 · AMR", [("Suggestion AMR 3.1.0", "amr", 44), ("Rang", "amr_rank", 11),
                       ("Statut", "amr_status", 11), ("Gram · ordre · famille", "amr_taxonomy", 40)]),
    ("Passe 2 · Claude", [("Type de ligne", "kind", 18), ("Identité proposée", "proposed", 36),
                           ("Code AMR", "proposed_code", 20), ("Rang", "proposed_rank", 13),
                           ("Confiance", "confidence", 10), ("Justification", "rationale", 70)]),
    ("Comparaison", [("AMR / Claude", "agreement", 18)]),
    ("Passe 3 · Microbiologiste", REVIEW),
]
OTHER_COLUMNS = [
    ("Source", [("N°", "rank", 5), ("Libellé source (LBLANA)", "source_label", 44),
                ("Lignes", "n_results", 10), ("Valeurs les plus fréquentes (nombre de lignes)", "values", 70)]),
    ("Passe 2 · Claude", [("Type de ligne", "kind", 24), ("Confiance", "confidence", 10),
                           ("Justification", "rationale", 80)]),
    ("Passe 3 · Microbiologiste", REVIEW),
]
THIN = Side(style="thin", color="BFBFBF")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)


def write_sheet(ws, columns, rows):
    col = 1
    for group, fields in columns:
        fill = PatternFill("solid", fgColor=GROUPS[group])
        ws.merge_cells(start_row=1, start_column=col, end_row=1, end_column=col + len(fields) - 1)
        for offset, (title, key, width) in enumerate(fields):
            top = ws.cell(row=1, column=col + offset, value=group if offset == 0 else None)
            head = ws.cell(row=2, column=col + offset, value=title)
            for cell in (top, head):
                cell.fill, cell.border = fill, BORDER
                cell.font = Font(bold=True)
                cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)
            ws.column_dimensions[get_column_letter(col + offset)].width = width
            for i, row in enumerate(rows, 3):
                cell = ws.cell(row=i, column=col + offset, value=row.get(key) if key else None)
                cell.border = BORDER
                cell.alignment = Alignment(vertical="top", wrap_text=True)
                if group == "Passe 3 · Microbiologiste":
                    cell.fill = PatternFill("solid", fgColor="F4FAF0")
                elif key in ("n_results", "n_diag", "n_isolates"):
                    cell.alignment = Alignment(vertical="top", horizontal="right")
                elif key == "agreement" and row["agreement"] in ("désaccord", "AMR sans suggestion", "AMR incertain"):
                    cell.fill = PatternFill("solid", fgColor="F8CBAD" if row["agreement"] == "désaccord" else "FCE4D6")
                elif key == "confidence" and row["confidence"] != "élevée":
                    cell.fill = PatternFill("solid", fgColor="FFD966" if row["confidence"] == "moyenne" else "F4B183")
                elif key == "source_label":
                    cell.font = Font(bold=True)
            if title == "Décision" and rows:
                letter = get_column_letter(col + offset)
                check = DataValidation(type="list", formula1='"OK,À corriger,Ne sait pas"', allow_blank=True)
                ws.add_data_validation(check)
                check.add(f"{letter}3:{letter}{len(rows) + 2}")
        col += len(fields)
    ws.row_dimensions[2].height = 48
    ws.freeze_panes = "C3"
    ws.auto_filter.ref = f"A2:{get_column_letter(col - 1)}{len(rows) + 2}"


def write_readme(ws, antibiotics, organisms, others):
    meta = (DIR / "inventory-meta.txt").read_text(encoding="utf-8").splitlines()

    def tally(rows):
        return ", ".join(f"{sum(r['agreement'] == a for r in rows)} « {a} »"
                         for a in AGREEMENT_ORDER if any(r["agreement"] == a for r in rows))

    found = re.search(r"without any such result: (\d+)", "\n".join(meta))
    not_shown = f" sur {found.group(1)}" if found else ""
    lines = [
        ("Revue des libellés de micro-organismes et d'antibiotiques · ORCHIDEE v3 · CHU de Rouen", "title"),
        (f"Document de travail généré le {date.today().isoformat()}. Aucune ligne n'est validée.", None),
        ("", None),
        ("À quoi sert ce classeur", "head"),
        ("Chaque libellé du laboratoire doit recevoir une identité avant de servir à un indicateur de résistance. "
         "Trois passes se suivent et leurs réponses restent dans trois groupes de colonnes distincts.", None),
        ("Passe 1 · AMR : la suggestion automatique du paquet R AMR 3.1.0 (as.mo, as.ab). Elle contient des erreurs connues.", None),
        ("Passe 2 · Claude : une proposition pour chaque ligne, avec un niveau de confiance et une justification. "
         "C'est une hypothèse préparée pour la relecture, jamais une validation.", None),
        ("Passe 3 · Microbiologiste : la seule colonne qui fait foi. Elle est vide.", None),
        ("", None),
        ("Comment remplir", "head"),
        ("Dans « Décision », choisir OK si la proposition de la passe 2 est juste, « À corriger » sinon, "
         "et écrire alors la bonne identité dans la colonne suivante. « Ne sait pas » est une réponse utile.", None),
        ("Les lignes sont triées : désaccords entre AMR et Claude d'abord, puis par nombre de résultats décroissant. "
         "Les premières lignes sont donc celles où votre avis compte le plus.", None),
        ("Pour les antibiotiques, une identité a plusieurs parties : la molécule, le test (antibiogramme usuel, "
         "haut niveau, dépistage, inhibition, association), la forme (IV, orale, trométamol) et le contexte de "
         "lecture (méningite, cystite, pneumonie, autres contextes). Merci de vérifier chaque partie.", None),
        ("", None),
        ("Les questions qui comptent le plus", "head"),
        ("1. COMMENTAIRE BLSE et COMMENTAIRE CARBA sont codés en S ou R. R veut-il bien dire « présence » ? "
         "Ce sont les sources proposées pour les indicateurs BLSE et carbapénémase.", None),
        ("2. Klebsiella pneumoniae/variicola (libellé apparu en 2024) : ces isolats comptent-ils avec K. pneumoniae ? "
         "Même question pour le complexe A. baumannii et pour S. argenteus / schweitzeri avec S. aureus.", None),
        ("3. OXACILLINE est rendue sur les staphylocoques et sur le pneumocoque, PENICILLINE G sur Haemophilus : "
         "sur ces espèces, est-ce bien un disque de dépistage et non un résultat thérapeutique ?", None),
        ("4. PIPERA TAZO et RIFAMPICINE. (avec un point) : est-ce bien le panel des anaérobies ? "
         "Un isolat peut-il porter aussi PIPERACILLINE+TAZOBACTAM ou RIFAMPICINE ?", None),
        ("5. CLOXA 250 et CLOXA 500 : que signifient S et R pour ce test d'inhibition ?", None),
        ("6. « Antibiogramme direct effectué à partir du prélèvement » est rangé parmi les micro-organismes : "
         "ces résultats peuvent-ils être rattachés à une espèce ?", None),
        ("", None),
        ("Colonnes", "head"),
        ("Résultats : nombre de lignes de résultat S, SFP, I, R ou ZIT portant ce libellé, 2022-2024, tous prélèvements. "
         "Ce ne sont pas des nombres d'isolats dédoublonnés.", None),
        ("dont diagnostiques : les mêmes lignes, limitées aux prélèvements marqués diagnostiques dans un ancien jeu de "
         "données du site. Valeur indicative et sous-estimée : une partie des lignes n'a pas de marque.", None),
        ("Petits effectifs : un nombre de 1 à 9 est écrit « <10 ». Pour un libellé porté par moins de 10 patients, "
         "le détail est écrit « masked ». Un nombre précédé de « ~ » est arrondi à la dizaine. "
         "Aucun identifiant de patient ou de prélèvement ne figure dans ce classeur.", None),
        ("Testé sur : les libellés d'espèce sur lesquels le libellé d'antibiotique est rendu, avec le nombre de résultats.", None),
        ("Confiance : élevée (sens du libellé sans ambiguïté), moyenne (sens probable, à confirmer), "
         "faible (hypothèse la plus plausible parmi plusieurs).", None),
        ("", None),
        ("Contenu", "head"),
        (f"Antibiotiques et tests : {len(antibiotics)} libellés. {tally(antibiotics)}.", None),
        (f"Micro-organismes : {len(organisms)} libellés. {tally(organisms)}.", None),
        (f"Autres champs : {len(others)} libellés{not_shown} du même champ que les antibiotiques, qui ne portent jamais "
         "de résultat S/I/R. Seuls ceux qui touchent à la résistance (commentaires, recherches de BMR, PCR de gènes) "
         "sont repris ; les autres sont d'autres analyses du laboratoire (cytologie, sérologie, parasitologie…).", None),
        ("", None),
        ("Extraction", "head"),
    ] + [(line, None) for line in meta]
    ws.column_dimensions["A"].width = 150
    for i, (text, style) in enumerate(lines, 1):
        cell = ws.cell(row=i, column=1, value=text)
        cell.alignment = Alignment(wrap_text=True, vertical="top")
        if style == "title":
            cell.font = Font(bold=True, size=14)
        elif style == "head":
            cell.font = Font(bold=True, size=12)


def write_register(path, rows):
    counts = [k for k in ("n_results", "n_isolates", "n_diag") if k in rows[0]]
    fields = list(rows[0]["csv"]) + counts + ["agreement", "approved_identity", "approved_by", "approved_on", "basis"]
    with open(path, "w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for row in rows:
            writer.writerow({**row["csv"], **{k: row[k] for k in counts}, "agreement": row["agreement"]})


def main():
    antibiotics, missing_ab = antibiotic_rows()
    organisms, missing_mo = organism_rows()
    if missing_ab or missing_mo:
        for kind, labels in (("antibiotic", missing_ab), ("organism", missing_mo)):
            for label in labels:
                print(f"NO PROPOSAL ({kind}): {label}")
        sys.exit(f"{len(missing_ab)} antibiotic and {len(missing_mo)} organism labels have no assistant proposal.")
    others = other_field_rows()
    wb = Workbook()
    write_readme(wb.active, antibiotics, organisms, others)
    wb.active.title = "Lisez-moi"
    write_sheet(wb.create_sheet("Antibiotiques"), ANTIBIOTIC_COLUMNS, antibiotics)
    write_sheet(wb.create_sheet("Micro-organismes"), ORGANISM_COLUMNS, organisms)
    write_sheet(wb.create_sheet("Autres champs"), OTHER_COLUMNS, others)
    wb.save(DIR / "revue-libelles.xlsx")
    write_register(DIR / "review-antibiotics.csv", antibiotics)
    write_register(DIR / "review-organisms.csv", organisms)
    write_register(DIR / "review-other-fields.csv", others)
    for name, rows in (("Antibiotic/test", antibiotics), ("Organism", organisms)):
        print(f"{name} labels: {len(rows)}; " + ", ".join(
            f"{a}: {sum(r['agreement'] == a for r in rows)}" for a in AGREEMENT_ORDER))
    print(f"Wrote {DIR / 'revue-libelles.xlsx'}")


if __name__ == "__main__":
    main()
