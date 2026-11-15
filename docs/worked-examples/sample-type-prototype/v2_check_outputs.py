import csv
import json
import sys
from pathlib import Path

V2_DIR = Path("outputs/sample-type-prototype/v2")
FORBIDDEN_IDENTIFIERS = {"PATID", "EVTID", "ELTID"}


def walk_json_keys(obj, path="root"):
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in FORBIDDEN_IDENTIFIERS:
                raise AssertionError(f"Privacy violation: forbidden JSON key {k!r} at {path}")
            walk_json_keys(v, f"{path}.{k}")
    elif isinstance(obj, list):
        for i, item in enumerate(obj):
            walk_json_keys(item, f"{path}[{i}]")


def check_csv(path: Path, expected_rows: int | None = None):
    with path.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames or []
        bad = set(fieldnames) & FORBIDDEN_IDENTIFIERS
        if bad:
            raise AssertionError(f"Privacy violation in {path.name}: forbidden columns {bad}")
        rows = list(reader)
    if expected_rows is not None:
        assert len(rows) == expected_rows, f"{path.name}: expected {expected_rows} rows, got {len(rows)}"
    return fieldnames, rows


def main():
    assert V2_DIR.exists(), f"Missing directory: {V2_DIR}"

    # 1. Privacy check across all top-level CSV and JSON files in v2/
    for jf in sorted(V2_DIR.glob("*.json")):
        data = json.loads(jf.read_text(encoding="utf-8"))
        walk_json_keys(data, jf.name)

    for cf in sorted(V2_DIR.glob("*.csv")):
        check_csv(cf)

    # Check batch JSONs too
    for bf in sorted((V2_DIR / "batches").glob("*.json")):
        data = json.loads(bf.read_text(encoding="utf-8"))
        walk_json_keys(data, bf.name)

    # 2. Structural & completeness checks on main v2 table
    _, v2_rows = check_csv(V2_DIR / "naturepvt_mapping_table_v2.csv", expected_rows=8462)
    label_ids = [r["label_id"] for r in v2_rows]
    expected_ids = [f"LBL_{i:04d}" for i in range(1, 8463)]
    assert label_ids == expected_ids, "label_id ordering or completeness mismatch in naturepvt_mapping_table_v2.csv"
    assert sum(int(r["n_samples"]) for r in v2_rows) == 51351
    assert sum(int(r["n_isolates"]) for r in v2_rows) == 61423
    assert all(r["naturepvt_norm"] and r["diagnostic_vs_screening_role"] and r["v1_status"] and r["resolution_lever"] for r in v2_rows)

    _, diff_rows = check_csv(V2_DIR / "v1_vs_v2_diff.csv")
    _, q_rows = check_csv(V2_DIR / "chu_rouen_questions.csv")
    assert (V2_DIR / "sample-type-review.md").exists()
    assert (V2_DIR / "demo.html").exists()

    print(
        f"[py-check] ALL PASSED: zero PATID/EVTID/ELTID keys/columns across v2 outputs; "
        f"v2_table={len(v2_rows)} rows (51,351 samples / 61,423 isolates); "
        f"v1_vs_v2_diff={len(diff_rows)} rows; chu_rouen_questions={len(q_rows)} rows."
    )


if __name__ == "__main__":
    main()
