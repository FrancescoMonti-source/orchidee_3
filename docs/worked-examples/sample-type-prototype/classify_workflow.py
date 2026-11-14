import json
from pathlib import Path

ROOT = Path(WORKSPACES[0]) if WORKSPACES else Path.cwd()
SHARDS_DIR = ROOT / "outputs" / "sample-type-prototype" / "shards"
OUT_DIR = ROOT / "outputs" / "sample-type-prototype"

ONERBA_ENUM = [
    "hemoculture",
    "urines",
    "dispositif_intravasculaire",
    "liquide_cephalorachidien",
    "liquide_pleural",
    "liquide_articulaire",
    "liquide_ascite",
    "prelevement_profond",
    "respiratoire_protege",
    "respiratoire_non_protege",
    "coproculture",
    "prelevement_genital",
    "prelevement_nouveau_ne",
    "pus_superficiel",
    "autre_prelevement",
    "depistage_portage",
    "unclassifiable",
]

ROLE_ENUM = [
    "diagnostic",
    "screening_site",
    "context_dependent",
    "unclassifiable",
]

CONF_ENUM = [
    "high",
    "medium",
    "ambiguous_needs_human_review",
]

CLASSIFICATION_ITEM_SCHEMA = {
    "type": "object",
    "required": [
        "family_id",
        "naturepvt_norm",
        "diagnostic_vs_screening_role",
        "confidence",
        "rationale",
    ],
    "properties": {
        "family_id": {"type": "string"},
        "naturepvt_norm": {"type": "string", "enum": ONERBA_ENUM},
        "diagnostic_vs_screening_role": {"type": "string", "enum": ROLE_ENUM},
        "confidence": {"type": "string", "enum": CONF_ENUM},
        "rationale": {"type": "string"},
    },
}

SHARD_SCHEMA = {
    "type": "object",
    "required": ["classifications"],
    "properties": {
        "classifications": {
            "type": "array",
            "items": CLASSIFICATION_ITEM_SCHEMA,
        }
    },
}

CROSSCHECK_SCHEMA = {
    "type": "object",
    "required": ["updated_classifications", "label_overrides", "review_themes"],
    "properties": {
        "updated_classifications": {
            "type": "array",
            "items": CLASSIFICATION_ITEM_SCHEMA,
        },
        "label_overrides": {
            "type": "array",
            "items": {
                "type": "object",
                "required": [
                    "naturepvt",
                    "naturepvt_norm",
                    "diagnostic_vs_screening_role",
                    "confidence",
                    "rationale",
                ],
                "properties": {
                    "naturepvt": {"type": "string"},
                    "naturepvt_norm": {"type": "string", "enum": ONERBA_ENUM},
                    "diagnostic_vs_screening_role": {"type": "string", "enum": ROLE_ENUM},
                    "confidence": {"type": "string", "enum": CONF_ENUM},
                    "rationale": {"type": "string"},
                },
            },
        },
        "review_themes": {
            "type": "array",
            "items": {
                "type": "object",
                "required": [
                    "theme_id",
                    "title",
                    "impact_summary",
                    "clinical_question",
                    "recommended_site_adapter_rule",
                    "example_labels",
                ],
                "properties": {
                    "theme_id": {"type": "string"},
                    "title": {"type": "string"},
                    "impact_summary": {"type": "string"},
                    "clinical_question": {"type": "string"},
                    "recommended_site_adapter_rule": {"type": "string"},
                    "example_labels": {"type": "array", "items": {"type": "string"}},
                },
            },
        },
    },
}

RULES_GUIDE = """You are classifying Rouen University Hospital (CHU Rouen) GLIMS `NATUREPVT` sample-type families into ORCHIDEE V3's local site-adapter taxonomy (ADR-0003), aligned with ONERBA (Recos 2001 Cap. II pp. 21-22 & Annexe 4 p. 44), SPARES (pp. 14-15 & Annexe 4 p. 27), and Rouen's 3-tier screening framing note (`note-cadrage-depistage-microbiologie.md`).

NEVER invent or alter `family_id`. Classify EVERY single `family_id` provided in the input array.

Target `naturepvt_norm` enum (17 categories):
1. `hemoculture`: All blood cultures (`Hémoculture périphérique`, `Hémoculture sur KT`, `Hémoculture sur CIP`, `Hémoculture avec délai`, `Hémoculture PICCLINE`, `Hémoculture DIALYSE`, `ART`). Mapped directly to current SPARES target `hemoculture`.
2. `urines`: Diagnostic urine cultures (`URINE MILIEU DE JET`, `URINE PAR SONDE VESICALE`, `URINE PAR CATHETER SUS PUBIEN`, `Urine BRICKER`, `Urine NEPHROSTOMIE`, `Urine SONDE JJ`, `VE` vesical). Mapped directly to SPARES target `urines`. NOTE: physical urinary catheter tips (`SONDE_MATERIEL_URINAIRE`, e.g. `Sonde urinaire`, without `URINE`) go to `autre_prelevement`, NOT `urines`.
3. `dispositif_intravasculaire`: Cultured intravascular catheter tips/hubs/ports (`Cathéter`, `PICC LINE`, `MIDLINE`, `CVO`, `CIP` / `Chambre implantable`) when NOT a blood culture (`Hémoculture`).
4. `liquide_cephalorachidien`: `LCR`, `LCR (dérivation)`, `DVE` / `DVP`, CSF shunts.
5. `liquide_pleural`: Pleural fluid/empyema/clot (`Liquide pleural`, `Plèvre`).
6. `liquide_articulaire`: Synovial/joint fluid, articular capsule, synovium (`Liquide articulaire`, `synoviale`).
7. `liquide_ascite`: Ascitic fluid and peritoneal dialysis fluid (`Liquide d'ascite`, `Liquide DIALYSE PERITONEALE`). Note: ordinary postoperative/surgical `Liquide péritonéal` (without `ascite` or `dialyse péritonéale`) is `prelevement_profond` per SPARES Annexe 4 p. 27!
8. `prelevement_profond`: Deep sterile puncture/surgical specimens per SPARES Annexe 4 p. 27: `Liquide péritonéal`, `Liquide de Douglas`, `Liquide péricardique`, `Bile` / `Liquide biliaire`, `Humeur aqueuse`, `Vitré`, deep hematomas/collections/seromas/lymphoceles, deep/visceral/intracavitary abscesses (`Abcès hépatique`, `Abcès cérébral`, `Abcès intra-péritonéal`, `Abcès pelvien`, `Empyème`, `Abcès profond`), bone/joint/spine (`Os`, `Métatarsien`, `Calcanéum`, `Sternum`, `Volet crânien`, `Bourre d'alésage`, `Disque`), heart valves, deep biopsies, surgical false membranes (`Fausse membrane`), internal prostheses/hardware (`Prothèse`, `Ostéosynthèse`, `Boitier pacemaker`), lymph nodes (`Ganglion`).
9. `respiratoire_protege`: Protected distal/bronchial specimens: `LBA` (`Lavage broncho-alvéolaire`), `PBDP` (prélèvement bronchique distal protégé), `PDP`, `Brosse` bronchique, `KT protégé`.
10. `respiratoire_non_protege`: Non-protected respiratory specimens: `Expectoration`, `Crachat`, `Aspiration bronchique`, `Aspiration trachéale/pharyngée`, `Mucovisidose` sputum/pharyngeal aspirates, `Trachéotomie`.
11. `coproculture`: Diagnostic stool cultures (`Selles`, `Coproculture`).
12. `prelevement_genital`: Female/male genital tracts (`Ecouvillon vaginal`, `Endocol`, `Vulve`, `Col utérus`, `Cul-de-sac vaginal`, `Lochies`, `Bartholin`, `Urètre`, `Sperme`, `Verge`, `Prépuce`, `Testicule`, `Bourse`). Note: if predominantly prenatal *S. agalactiae* screening (`BGSTRB`, e.g., `FAM_022` at 96.6%), set `diagnostic_vs_screening_role="context_dependent"` and `confidence="ambiguous_needs_human_review"`. Note also Rouen `BOS` (bourse scrotum vs bourse pré-patellaire knee bursitis!): watch out if a family mixes genital `Bourse` with knee `Bourse pré-patellaire`!
13. `prelevement_nouveau_ne`: `Liquide amniotique`, `Placenta`, `Cordon ombilical`, neonatal `Liquide gastrique` / `Multi-sites` / `Meconium`.
14. `pus_superficiel`: Superficial pus (`Pus` cutaneous/superficial), `Plaie`, `Ulcère`, `Escarre`, `Brûlure`, `Cicatrice`, `Moignon`, `Panaris`, `Furoncle`, subcutaneous collections/abscesses, ENT ear/sinus/oral discharge (`OREILLE`, `Otorrhée`, `Sinus` superficial, `Bouche`), conjunctival swabs (`Ecouvillon conjonctive`, `OEIL`), AND perianal/cutaneous abscesses and fistulas (`Abcès marge anale`, `Fistule anale`, `Abcès fesse`, `Sinus pilonidal` -> ALWAYS `diagnostic_vs_screening_role="diagnostic"`!). Note: subcutaneous/superficial biopsy (`Biopsie cutanée`) is also superficial/diagnostic (`pus_superficiel` or `autre_prelevement`).
15. `autre_prelevement`: Surgical drains/Redons (`Liquide REDON`, `Drain`), graft rinse/preservation fluids (`Liquide de rinçage`, `LRIN`), corneal scrapings (`Cornée`, `Ecouvillon cornée`, `Lentille`), physical urinary/IUD devices (`Sonde urinaire`, `Stérilet`), miscellaneous swabs (`Ecouvillon divers`), cardiac assist driveline orifice/implant collections (`ASSISTANCE CIRCULATOIRE`, `ORIFICE HEART MATE` -> `ambiguous_needs_human_review`), or unspecified superficial/anatomical region labels without clear deep/pus qualifier (`CUTANE_OU_ANATOMIQUE_AUTRE`, e.g. bare limb/skin region).
16. `depistage_portage`: Canonical carriage screening sites & explicit screening labels (`DEPISTAGE_EXPLICITE`, `NEZ`/`Narine`, `AISSELLE`, `AINE`, `RECTUM`/`ANUS`/`Marge anale` without abscess/fistula/pus, `GORGE`/`Pharynx`). Set `diagnostic_vs_screening_role="screening_site"` if clear carriage/screening, or `"context_dependent"` when co-occurring with `BGCULTAE` / bare `ANUS` / `NEZ` / `AINE` / `GORGE`.
17. `unclassifiable`: Missing, unknown, or laterality-only labels (`X`, `SANS`, `Autre`, `Inconnu`, `DROITE`, `GAUCHE`), `diagnostic_vs_screening_role="unclassifiable"`, `confidence="ambiguous_needs_human_review"`.

Rules for `diagnostic_vs_screening_role`:
- `diagnostic`: Intrinsically clinical infection specimen (blood, urine, LCR, fluids, deep tissue/bone, respiratory, ear/eye, wounds, abscesses/fistulas including perianal `Abcès marge anale` & `Fistule`, drain fluids).
- `screening_site`: Pure or canonical carriage-screening sites/labels (`DEPISTAGE_EXPLICITE`, nasal/axillary/inguinal/rectal carriage swabs).
- `context_dependent`: Site or label where diagnostic vs screening depends on co-prescribed `TYPEANA` (`BGSTA_R` alone vs `BGSTA_R + BGCULTAE`, prenatal `BGSTRB`, bare `NEZ`, `ANUS`, `RECTAL`, `AINE`, `AISSELLE`, `GORGE`). Also use for bare superficial sites that frequently serve both roles.
- `unclassifiable`: Non-informative labels (`X`, `SANS`, `Autre`, `DROITE`, `GAUCHE`).

Rules for `confidence`:
- `high`: Unambiguous ONERBA category and diagnostic role, empirically consistent with `pct_any_screening_order`.
- `medium`: Clear primary ONERBA category, minor depth/granularity boundary (e.g., mixed superficial/deep collections under `UNSPECIFIED_OR_OTHER`, urine on indwelling catheter variants, bare region names like `MAIN DROITE` vs `CUISSE GAUCHE` without tissue/pus prefix).
- `ambiguous_needs_human_review`: Bare GLIMS code without fluid/swab context (e.g., `KT`, `CIP`, `VE`, `REC`, `ANU`, `NEZ`), conflict between label text and observed `pct_any_screening_order` (e.g., `Ecouvillon vaginal` at 96.6% `BGSTRB`), heterogeneous hardware (`ORIFICE HEART MATE` vs `PACE MAKER`), or unclassifiable (`X`, `SANS`, `DROITE`).
"""


def compact_family(fam, max_top_labels=8):
    """Keep full statistical metadata and up to `max_top_labels` top labels + 5 tail examples."""
    top_labs = []
    for l in fam.get("top_labels", [])[:max_top_labels]:
        top_labs.append({
            "lbl": l["naturepvt"],
            "n": l["n_samples"],
            "bgsta_cult": l.get("n_samp_bgsta_cultae", 0),
            "bgstrb": l.get("n_samp_bgstrb", 0),
            "pct_sys_r": l.get("pct_sys_R", 0),
            "pct_scr": l.get("pct_any_screening_order", 0),
            "tp": l.get("top_typeana", ""),
            "sp": l.get("top_species", ""),
        })
    return {
        "family_id": fam["family_id"],
        "specimen_prefix": fam["specimen_prefix"],
        "anatomical_site": fam["anatomical_site"],
        "sub_pattern": fam["sub_pattern"],
        "n_labels": fam["n_labels"],
        "n_samples": fam["n_samples"],
        "pct_sys_R": fam["pct_sys_R"],
        "pct_any_scr": fam["pct_any_screening_order"],
        "n_bgsta_cultae": fam["n_samp_bgsta_cultae"],
        "n_bgstrb": fam["n_samp_bgstrb"],
        "heterog": fam["has_internal_heterogeneity"],
        "glims": fam["top_glims_codes"],
        "top_labels": top_labs,
        "more_labels": fam.get("more_example_labels", [])[:5],
    }


async def classify_shard(shard_info):
    sid = shard_info["shard_id"]
    expected_ids = [f["family_id"] for f in shard_info["families"]]
    out_path = SHARDS_DIR / f"classified_{sid:02d}.json"
    if out_path.exists():
        try:
            cached = json.loads(out_path.read_text(encoding="utf-8"))
            if (
                isinstance(cached, list)
                and len(cached) == len(expected_ids)
                and {item.get("family_id") for item in cached} == set(expected_ids)
            ):
                log(f"Loaded cached shard {sid:02d} ({len(cached)} families) from {out_path.name}.")
                return cached
        except Exception as exc:
            log(f"Ignoring invalid cache {out_path.name}: {exc}")

    compact_list = [compact_family(f) for f in shard_info["families"]]
    prompt = f"""Classify Shard {sid:02d} ({len(expected_ids)} families).

{RULES_GUIDE}

Input families (shard {sid:02d}):
{json.dumps(compact_list, ensure_ascii=False)}

Return JSON strictly matching the schema with all {len(expected_ids)} `family_id`s: {expected_ids[0]} .. {expected_ids[-1]}. Call `finish` with the result."""
    res = await agent(
        prompt=prompt,
        schema=SHARD_SCHEMA,
        type_name="research",
        role=f"Classify shard {sid:02d} ({len(expected_ids)} families)",
    )
    items = res["classifications"]
    out_path.write_text(json.dumps(items, ensure_ascii=False, indent=2), encoding="utf-8")
    return items


shard_files = sorted(SHARDS_DIR.glob("shard_*.json"))
assert len(shard_files) == 8, f"Expected 8 shard files, got {len(shard_files)}"

shards = []
all_families_by_id = {}
for idx, sf in enumerate(shard_files, start=1):
    fams = json.loads(sf.read_text(encoding="utf-8"))
    shards.append({"shard_id": idx, "families": fams})
    for fam in fams:
        all_families_by_id[fam["family_id"]] = fam

phase("Parallel shard classification")
log(f"Loaded {len(all_families_by_id)} families across {len(shards)} shards.")
shard_results = await parallel(shards, classify_shard)

cls_by_id = {}
for items in shard_results:
    for item in items:
        cls_by_id[item["family_id"]] = item

missing_ids = sorted(set(all_families_by_id) - set(cls_by_id))
if missing_ids:
    log(f"Backfilling {len(missing_ids)} omitted family_ids: {missing_ids}")
    backfill_compact = [compact_family(all_families_by_id[fid]) for fid in missing_ids]
    bf_res = await agent(
        prompt=f"Classify these {len(missing_ids)} missing families.\n\n{RULES_GUIDE}\n\n{json.dumps(backfill_compact, ensure_ascii=False)}",
        schema=SHARD_SCHEMA,
        type_name="research",
        role="Backfill omitted families",
    )
    for item in bf_res["classifications"]:
        cls_by_id[item["family_id"]] = item

still_missing = sorted(set(all_families_by_id) - set(cls_by_id))
assert not still_missing, f"Still missing classifications for: {still_missing}"
log(f"Phase 1 complete: {len(cls_by_id)}/{len(all_families_by_id)} families classified.")

phase("Cross-check context_dependent and ambiguous cases")
audit_ids = []
audit_prefixes = {
    "SITE_NEZ_NARINE",
    "SITE_AISSELLE",
    "SITE_AINE",
    "SITE_RECTUM_ANUS_SANS_ABCES",
    "SITE_GORGE_PHARYNX",
    "DEPISTAGE_EXPLICITE",
    "MATERIEL_ASSISTANCE_CARDIAQUE_IMPLANT",
    "INCONNU_SANS_AUTRE",
    "SONDE_MATERIEL_URINAIRE",
}

for fid in sorted(all_families_by_id):
    fam = all_families_by_id[fid]
    cls = cls_by_id[fid]
    rank_num = int(fid.split("_")[1])
    if (
        cls["diagnostic_vs_screening_role"] in ("context_dependent", "unclassifiable")
        or cls["confidence"] == "ambiguous_needs_human_review"
        or fam["pct_any_screening_order"] > 0
        or fam["n_samp_bgsta_cultae"] > 0
        or fam["has_internal_heterogeneity"]
        or fam["specimen_prefix"] in audit_prefixes
        or (rank_num <= 35 and cls["confidence"] != "high")
        or fam["specimen_prefix"] in ("URINES_SONDE_DISPOSITIF", "DISPOSITIF_CIP", "DISPOSITIF_KT_VASCULAIRE")
    ):
        audit_ids.append(fid)

log(f"Selected {len(audit_ids)} families for Phase 2 cross-check audit.")

BATCH_SIZE = 35
audit_batches = []
for b_idx, start in enumerate(range(0, len(audit_ids), BATCH_SIZE), start=1):
    batch_ids = audit_ids[start : start + BATCH_SIZE]
    audit_batches.append({"batch_id": b_idx, "family_ids": batch_ids})


async def crosscheck_batch(batch_info):
    bid = batch_info["batch_id"]
    batch_ids = batch_info["family_ids"]
    out_path = SHARDS_DIR / f"crosscheck_batch_{bid:02d}.json"
    if out_path.exists():
        try:
            cached = json.loads(out_path.read_text(encoding="utf-8"))
            if (
                isinstance(cached, dict)
                and "updated_classifications" in cached
                and "label_overrides" in cached
                and "review_themes" in cached
            ):
                log(f"Loaded cached cross-check batch {bid:02d} from {out_path.name}.")
                return cached
        except Exception as exc:
            log(f"Ignoring invalid cross-check cache {out_path.name}: {exc}")

    audit_payload = [
        {
            "family": compact_family(all_families_by_id[fid], max_top_labels=4),
            "initial_classification": cls_by_id[fid],
        }
        for fid in batch_ids
    ]
    crosscheck_prompt = f"""You are performing Phase 2 cross-check audit Batch {bid} ({len(audit_payload)} of {len(audit_ids)} total flagged Rouen `NATUREPVT` families: `context_dependent`, `ambiguous_needs_human_review`, screening-site candidates, urine/catheter boundary cases, or high-volume non-high-confidence families).

All rules from the framing note, ONERBA, and SPARES are already provided in this prompt — do NOT read files or search the repo; evaluate the batch directly from the JSON payload and call `finish` in one turn.

Check every flagged family in this batch carefully against:
1. `docs/methods/note-cadrage-depistage-microbiologie.md`:
   - `BGSTA_R` alone = screening vs `BGSTA_R + BGCULTAE` = diagnostic wound/site (check `n_bgsta_cultae`, e.g., `NEZ` has 10 `BGSTA_R+BGCULTAE`, wounds/plaies keep `diagnostic`).
   - `BGSTRB` vaginal prenatal screening (`Ecouvillon vaginal` 286/293 = 97.6% `BGSTRB`!) -> MUST be `naturepvt_norm="prelevement_genital"`, `diagnostic_vs_screening_role="context_dependent"`, `confidence="ambiguous_needs_human_review"`.
   - Superficial carriage swabs (`Nez`, `Narine`, `Aisselle`, `Aine`, `Rectum`/`Anus` without abscess) MUST be distinguished from surgical collections (`Abcès marge anale`, `Fistule anale`) which MUST stay `diagnostic` (`pus_superficiel` or `prelevement_profond`).
2. `docs/ONERBA Recos_Methodo_Surveillance_onerba_2001.pdf` (Cap. II pp. 21-22 & Annexe 4 p. 44) & SPARES (Annexe 4 p. 27):
   - Urinary catheter cultures (`URINE PAR SONDE VESICALE`, `Urine BRICKER`, `Urine NEPHROSTOMIE`) ARE `naturepvt_norm="urines"` (`diagnostic`), whereas removed physical urinary catheters (`Sonde urinaire`, `Sonde JJ` without `Urine`) are `autre_prelevement`.
   - Vascular catheter tips (`Cathéter`, `CIP`) are `dispositif_intravasculaire`, whereas `Hémoculture sur KT/CIP` is `hemoculture`.
   - Inside `FAM_035` (`MATERIEL_ASSISTANCE_CARDIAQUE_IMPLANT`): `ORIFICE HEART MATE` / `ORIFICE HTM` are external driveline exit-site swabs (`autre_prelevement` / `pus_superficiel`), while `PACE MAKER` / `CANULE HEART MATE` / `LOGE` are deep/implant hardware (`prelevement_profond`) — add `label_overrides` if those labels appear!
   - Check outlier labels in `top_labels` / `more_labels` (e.g., `PLAQUE SOUS VESICALE`, `PROTHESE SOUS VESICALE SURINFECTEE`, `BOURSE PRE PATELLAIRE`, `BOURSE PRE PATELAIRE GENOU DT`, `PLAN PRE CAVUM`, `ABCES SCROTAL`, `ABCES DE PAROI`, `ABCES MARGE ANAL`, `FISTULE ANALE`, `LENTILLE SOLUTION LAVANTE`, `NECROSE MUSCULAIRE`, deep vs superficial collections) and emit `label_overrides` using the exact `lbl` string when an outlier in `top_labels` needs a different classification from its parent family!

{RULES_GUIDE}

Flagged families in Batch {bid} ({batch_ids[0]} .. {batch_ids[-1]}):
{json.dumps(audit_payload, ensure_ascii=False)}

Return JSON matching the schema:
1. `updated_classifications`: ONLY the families in Batch {bid} whose `naturepvt_norm`, `diagnostic_vs_screening_role`, `confidence`, or `rationale` you want to revise or enrich (omit unchanged families).
2. `label_overrides`: specific individual `NATUREPVT` label strings (exact string match from `lbl`) that require a distinct classification from their parent family.
3. `review_themes`: 2-3 crisp clinical review themes (`theme_id` prefixed `B{bid}_T1`, `B{bid}_T2`, ...) arising specifically from Batch {bid} for CHU Rouen microbiologists/hygienists.

Call `finish` now."""

    res = await agent(
        prompt=crosscheck_prompt,
        schema=CROSSCHECK_SCHEMA,
        type_name="research",
        role=f"Cross-check batch {bid}/{len(audit_batches)} ({len(audit_payload)} families)",
    )
    out_path = SHARDS_DIR / f"crosscheck_batch_{bid:02d}.json"
    out_path.write_text(json.dumps(res, ensure_ascii=False, indent=2), encoding="utf-8")
    return res


batch_results = await parallel(audit_batches, crosscheck_batch)

updated_by_fid = {}
overrides_by_lbl = {}
review_themes = []
seen_theme_titles = set()

for b_res in batch_results:
    for upd in b_res.get("updated_classifications", []):
        if upd["family_id"] in cls_by_id:
            cls_by_id[upd["family_id"]] = upd
            updated_by_fid[upd["family_id"]] = upd
    for ov in b_res.get("label_overrides", []):
        overrides_by_lbl[ov["naturepvt"]] = ov
    for th in b_res.get("review_themes", []):
        tkey = th["title"].strip().lower()
        if tkey not in seen_theme_titles:
            seen_theme_titles.add(tkey)
            review_themes.append(th)

for idx, th in enumerate(review_themes, start=1):
    th["theme_id"] = f"THEME_{idx:02d}"

updated_list = [updated_by_fid[fid] for fid in sorted(updated_by_fid)]
overrides_list = list(overrides_by_lbl.values())

final_list = [cls_by_id[fid] for fid in sorted(all_families_by_id)]
(OUT_DIR / "classifications.json").write_text(
    json.dumps(final_list, ensure_ascii=False, indent=2), encoding="utf-8"
)
(OUT_DIR / "crosscheck_decisions.json").write_text(
    json.dumps(
        {
            "audited_family_ids": audit_ids,
            "n_updated": len(updated_list),
            "n_label_overrides": len(overrides_list),
            "updated_classifications": updated_list,
            "label_overrides": overrides_list,
            "review_themes": review_themes,
        },
        ensure_ascii=False,
        indent=2,
    ),
    encoding="utf-8",
)

# Print summary statistics for log
by_cat = {}
by_role = {}
by_conf = {}
for item in final_list:
    by_cat[item["naturepvt_norm"]] = by_cat.get(item["naturepvt_norm"], 0) + 1
    by_role[item["diagnostic_vs_screening_role"]] = by_role.get(item["diagnostic_vs_screening_role"], 0) + 1
    by_conf[item["confidence"]] = by_conf.get(item["confidence"], 0) + 1

log(f"Cross-check finished: {len(updated_list)} family updates, {len(overrides_list)} label overrides, {len(review_themes)} review themes.")
print("BY_CATEGORY:", json.dumps(by_cat, ensure_ascii=False))
print("BY_ROLE:", json.dumps(by_role, ensure_ascii=False))
print("BY_CONFIDENCE:", json.dumps(by_conf, ensure_ascii=False))
print(f"SAVED {len(final_list)} classifications to {OUT_DIR / 'classifications.json'}")
