"""THROWAWAY: feed Rouen laboratory data to AMR for Python, then open demo.html."""

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import platform
import re
import sys
from datetime import datetime, timezone
from importlib.metadata import version

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--input", type=Path, default=ROOT / "data/bact22_24")
parser.add_argument("--year", type=int, default=2024)
parser.add_argument("--output", type=Path, default=ROOT / "outputs/amr-python-prototype")
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
sys.stdout.reconfigure(encoding="utf-8", errors="backslashreplace")

# AMR 3.1.0 embeds this path in R source without escaping Windows backslashes.
# Normalise the isolated installation's path; do not change its AMR algorithms.
engine = Path(importlib.util.find_spec("AMR").origin).parent / "_engine.py"
original = 'r_lib_path = os.path.join(venv_path, "R_libs")'
patched = original + '.replace("\\\\", "/")'
source = engine.read_text(encoding="utf-8")
if original + "\n" in source:
    engine.write_text(source.replace(original + "\n", patched + "\n"), encoding="utf-8")
os.environ["LC_ALL"] = "C"
os.environ.setdefault("RPY2_CFFI_MODE", "ABI")
if sys.platform == "win32":
    if "R_HOME" not in os.environ:
        installations = list(Path(os.environ["ProgramFiles"]).glob("R/R-*/bin/Rscript.exe"))
        os.environ["R_HOME"] = str(max(installations, key=lambda p: tuple(map(int, p.parents[1].name[2:].split(".")))).parents[1])
    os.environ["PATH"] = str(Path(os.environ["R_HOME"]) / "bin/x64") + os.pathsep + os.environ["PATH"]

import numpy as np
import pandas as pd
import AMR
import rpy2.robjects as ro
from rpy2.robjects import default_converter, pandas2ri
from rpy2.robjects.conversion import localconverter
from AMR._engine import restore_sink

restore_sink()
print("Reading raw RDS locally; only aggregates and mapping labels will be written.", flush=True)
read_raw = ro.r('''function(path, year) {
  b <- as.data.frame(readRDS(path))
  in_year <- !is.na(b$DATEPRELEV) & b$DATEPRELEV >= as.Date(paste0(year, "-01-01")) &
    b$DATEPRELEV < as.Date(paste0(year + 1L, "-01-01"))
  has_result <- !is.na(b$STRRES) & b$STRRES %in% c("S", "SFP", "I", "R", "ZIT")
  d <- b[in_year & has_result, c("PATID", "ELTID", "DLVL", "IDENTIFICATION", "LBLANA", "STRRES")]
  list(data=d, rows_raw=nrow(b), rows_year=sum(in_year))
}''')
raw = read_raw(str(args.input.resolve()), args.year)
with localconverter(default_converter + pandas2ri.converter):
    data = ro.conversion.rpy2py(raw.rx2("data"))
data.columns = ["patient", "sample", "isolate", "organism", "analysis", "result"]
for column in data:
    data[column] = data[column].astype("string").replace("", pd.NA)
print(f"Loaded {len(data):,} rows with recognised result categories in {args.year}.", flush=True)

def strings(values):
    return [None if str(v) in {"NA_character_", "UNKNOWN", "None", "nan", "<NA>"} else str(v) for v in values]

organisms = data["organism"].value_counts().rename_axis("local_label").reset_index(name="result_rows")
labels = organisms["local_label"].tolist()
print(f"Mapping {len(labels)} organism labels with AMR.as_mo().", flush=True)
organisms["amr_code"] = strings(AMR.as_mo(labels, info=False))
uncertainties = AMR.mo_uncertainties()
uncertain_inputs = set(uncertainties["original_input"].astype(str)) if isinstance(uncertainties, pd.DataFrame) and len(uncertainties) else set()
organisms["amr_name"] = strings(AMR.mo_name(organisms["amr_code"].fillna("UNKNOWN").tolist(), language="en"))
organisms["status"] = ["unmapped" if code is None else "uncertain" if label in uncertain_inputs else "recognised"
                       for label, code in zip(labels, organisms["amr_code"])]

analyses = data["analysis"].value_counts().rename_axis("local_label").reset_index(name="result_rows")
print(f"Mapping {len(analyses)} laboratory result labels with AMR.as_ab().", flush=True)
analyses["amr_code"] = strings(AMR.as_ab(analyses["local_label"].tolist(), language="fr", info=False))
analyses["amr_name"] = strings(AMR.ab_name(analyses["amr_code"].fillna("").tolist(), language="en"))
site_map = pd.read_csv(ROOT / "ref/rouen/atb_regex_map.csv")
patterns = [(re.compile(row.pattern), row.atb_norm) for row in site_map.itertuples()]
analyses["site_mapping"] = [next((target for pattern, target in patterns if pattern.search(label)), None)
                            for label in analyses["local_label"]]
# A deliberately small, explicit crosswalk. Other automatic suggestions remain proposals.
table_drugs = {"cefotaxime": "CTX", "ceftazidime": "CAZ", "ciprofloxacine": "CIP",
               "ertapeneme": "ETP", "gentamicine": "GEN", "piperacilline_tazobactam": "TZP", "vancomycine": "VAN"}
# Keep an explicit source-label list as well: the legacy regex map also folds
# GENTAMICINE FORTE into ordinary gentamicin. Agreement alone does not validate it.
table_labels = {"CEFOTAXIME", "CEFTAZIDIME", "CIPROFLOXACINE", "ERTAPENEME",
                "GENTAMICINE", "PIPERACILLINE+TAZOBACTAM", "VANCOMYCINE"}
analyses["used_in_table"] = [label in table_labels and table_drugs.get(local) == candidate and candidate is not None
                             for label, local, candidate in zip(analyses["local_label"], analyses["site_mapping"], analyses["amr_code"])]
target_species = ["Escherichia coli", "Klebsiella pneumoniae", "Pseudomonas aeruginosa", "Staphylococcus aureus", "Enterococcus faecium"]
table_pairs = {"Escherichia coli": ["CTX", "CAZ", "CIP", "ETP", "GEN", "TZP"],
               "Klebsiella pneumoniae": ["CTX", "CAZ", "CIP", "ETP", "GEN", "TZP"],
               "Pseudomonas aeruginosa": ["CAZ", "CIP", "GEN", "TZP"],
               "Staphylococcus aureus": ["GEN", "VAN"], "Enterococcus faecium": ["VAN"]}
confirmed_species = organisms.loc[(organisms["status"] == "recognised") &
    (organisms["local_label"] == organisms["amr_name"]) & organisms["local_label"].isin(target_species), "local_label"]

keys = ["patient", "sample", "isolate"]
complete_keys = data[keys].notna().all(axis=1)
identified = data.loc[complete_keys & data["organism"].notna()]
identity_conflicts = identified.groupby(keys)["organism"].nunique()
conflicting_keys = identity_conflicts[identity_conflicts > 1].index
clean = identified.loc[~pd.MultiIndex.from_frame(identified[keys]).isin(conflicting_keys)]
selected = clean.loc[clean["organism"].isin(confirmed_species)].copy()
total_isolates = selected[keys + ["organism"]].drop_duplicates().groupby("organism").size()
drug_map = analyses.loc[analyses["used_in_table"], ["local_label", "amr_code"]].rename(columns={"local_label": "analysis"})
selected = selected.merge(drug_map, on="analysis", how="inner", validate="many_to_one")
outside_trial_pairs = sum(code not in table_pairs[species] for species, code in zip(selected["organism"], selected["amr_code"]))
selected = selected.loc[[code in table_pairs[species] for species, code in zip(selected["organism"], selected["amr_code"])]].copy()
# The source convention is SFP/I/ZIT -> increased-exposure susceptible; retain it as I for AMR.
selected["sir"] = selected["result"].replace({"SFP": "I", "ZIT": "I"})
cells = keys + ["organism", "amr_code"]
cell_counts = selected.groupby(cells)["sir"].nunique()
conflicting_cells = cell_counts[cell_counts > 1].index
keep_cells = ~pd.MultiIndex.from_frame(selected[cells]).isin(conflicting_cells)
unambiguous = selected.loc[keep_cells]
identical_repeats = len(unambiguous) - len(unambiguous.drop_duplicates(cells))
unambiguous = unambiguous.drop_duplicates(cells)

table = []
for species in confirmed_species:
    for code in table_pairs[species]:
        results = unambiguous.loc[(unambiguous["organism"] == species) & (unambiguous["amr_code"] == code), "sir"].tolist()
        n = int(AMR.count_R(results)[0]) if results else 0
        tested = int(AMR.count_all(results)[0]) if results else 0
        rate = float(AMR.resistance(results, minimum=0, guideline="EUCAST")[0]) if results else None
        # Independent arithmetic verifies the package's numerator/denominator convention on this run.
        if results:
            assert n == results.count("R") and tested == len(results) and np.isclose(rate, n / tested)
        table.append({"organism": species, "antibiotic": code, "resistant": n, "tested": tested,
                      "total_isolates": int(total_isolates[species]), "resistance_pct": None if rate is None else 100 * rate})

# Exercise the package's extension point without adopting a new site mapping.
complex_label = "Enterobacter complexe cloacae"
complex_code = strings(AMR.as_mo(["Enterobacter cloacae complex"], info=False))[0]
AMR.mo_reset_session()
reference = pd.DataFrame({"local": [complex_label], "mo": [complex_code]})
configured = strings(AMR.as_mo([complex_label], reference_df=reference, info=False))
custom_mapping_trial = {"local_label": complex_label,
    "default_suggestion": organisms.set_index("local_label").loc[complex_label, "amr_name"],
    "configured_code": configured[0], "configured_name": strings(AMR.mo_name(configured, language="en"))[0],
    "status": "Proposed explicit site reference; demonstrated, not applied to the table."}

metadata = {
    "question": "Can AMR for Python map Rouen labels and calculate a transparent resistance table?",
    "run_utc": datetime.now(timezone.utc).isoformat(), "year": args.year,
    "input_name": args.input.name, "input_sha256": hashlib.file_digest(args.input.open("rb"), "sha256").hexdigest(),
    "versions": {"Python": platform.python_version(), "AMR Python": version("AMR"),
                 "AMR R": str(ro.r('as.character(packageVersion("AMR"))')[0]),
                 "R": str(ro.r("R.version.string")[0]), "rpy2": version("rpy2"), "pandas": version("pandas"), "numpy": version("numpy")},
    "runtime_workaround": "AMR _engine.py: normalise its isolated R library path to forward slashes before embedding it in R source.",
    "population": "All raw sample types, including possible screening; no hospital perimeter selection; no surveillance deduplication.",
    "result_mapping": "S -> S; R -> R; SFP/I/ZIT -> I; EUCAST counts I on the susceptible side. No MIC reinterpretation.",
    "rows_raw": int(raw.rx2("rows_raw")[0]), "rows_year": int(raw.rx2("rows_year")[0]), "result_rows": len(data),
    "missing_key_rows": int((~complete_keys).sum()), "missing_organism_rows": int(data["organism"].isna().sum()),
    "identity_conflicts": len(conflicting_keys), "conflicting_result_cells": len(conflicting_cells),
    "identical_repeated_rows_collapsed": identical_repeats, "result_alphabet": {str(k): int(v) for k, v in data["result"].value_counts().items()},
    "organism_statuses": {str(k): int(v) for k, v in organisms["status"].value_counts().items()},
    "organism_result_rows_by_status": {str(k): int(v) for k, v in organisms.groupby("status")["result_rows"].sum().items()},
    "analysis_labels": len(analyses), "analysis_labels_used_in_table": int(analyses["used_in_table"].sum()),
    "table_isolates": int(total_isolates.sum()), "table_tested_cells": len(unambiguous), "arithmetic_agrees": True,
    "outside_selected_trial_pairs_rows": int(outside_trial_pairs), "trial_pairs": table_pairs,
    "custom_mapping_trial": custom_mapping_trial,
}
# No patient, stay, sample or isolate identifiers leave memory.
payload = {"metadata": metadata, "organisms": json.loads(organisms.to_json(orient="records")),
           "analyses": json.loads(analyses.to_json(orient="records")), "table": table}
(args.output / "summary.json").write_text(json.dumps(payload, indent=2, ensure_ascii=False, allow_nan=False), encoding="utf-8")
organisms.to_csv(args.output / "organism-mapping.csv", index=False)
analyses.to_csv(args.output / "antibiotic-mapping.csv", index=False)
pd.DataFrame(table).to_csv(args.output / "resistance-table.csv", index=False)
if isinstance(uncertainties, pd.DataFrame):
    uncertainties.to_csv(args.output / "organism-uncertainties.csv", index=False)
encoded = json.dumps(payload, ensure_ascii=False, allow_nan=False).replace("<", "\\u003c")
demo = (HERE / "demo.template.html").read_text(encoding="utf-8").replace("/*PROTOTYPE_DATA*/null", encoded)
(args.output / "demo.html").write_text(demo, encoding="utf-8")
print(json.dumps(metadata, indent=2, ensure_ascii=False), flush=True)
print(pd.DataFrame(table).query("tested > 0").to_string(index=False), flush=True)
print(f"Open {args.output / 'demo.html'}", flush=True)
