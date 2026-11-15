import json
from pathlib import Path

ROOT = Path(WORKSPACES[0]) if WORKSPACES else Path.cwd()
V2_DIR = ROOT / "outputs" / "sample-type-prototype" / "v2"
BATCH_DIR = V2_DIR / "batches"

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

V1_STATUS_ENUM = [
    "confirmed",
    "reclassified",
    "flagged",
]

LEVER_ENUM = [
    "text_sufficient",
    "filter_typeana",
    "filter_sejuf_tri",
    "exclude_mycology",
    "ask_chu_rouen",
]

ONERBA_SET = set(ONERBA_ENUM)
ROLE_SET = set(ROLE_ENUM)
CONF_SET = set(CONF_ENUM)
V1_STATUS_SET = set(V1_STATUS_ENUM)
LEVER_SET = set(LEVER_ENUM)

ITEM_SCHEMA = {
    "type": "object",
    "required": [
        "label_id",
        "naturepvt_norm",
        "diagnostic_vs_screening_role",
        "confidence",
        "v1_status",
        "needs_composite_lis_rule",
        "resolution_lever",
        "rationale",
    ],
    "properties": {
        "label_id": {"type": "string"},
        "naturepvt_norm": {"type": "string", "enum": ONERBA_ENUM},
        "diagnostic_vs_screening_role": {"type": "string", "enum": ROLE_ENUM},
        "confidence": {"type": "string", "enum": CONF_ENUM},
        "v1_status": {"type": "string", "enum": V1_STATUS_ENUM},
        "needs_composite_lis_rule": {"type": "boolean"},
        "resolution_lever": {"type": "string", "enum": LEVER_ENUM},
        "rationale": {"type": "string"},
    },
}

BATCH_VERIFY_SCHEMA = {
    "type": "object",
    "required": ["items"],
    "properties": {
        "items": {
            "type": "array",
            "items": ITEM_SCHEMA,
        }
    },
}

CROSSCHECK_V2_SCHEMA = {
    "type": "object",
    "required": ["items", "themes"],
    "properties": {
        "items": {
            "type": "array",
            "items": ITEM_SCHEMA,
        },
        "themes": {
            "type": "array",
            "items": {
                "type": "object",
                "required": [
                    "title",
                    "impact_summary",
                    "clinical_question",
                    "recommended_site_adapter_rule",
                    "example_labels",
                ],
                "properties": {
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

V2_RULES_GUIDE = """You are auditing CHU Rouen GLIMS `NATUREPVT` sample labels 1-by-1 (overriding v1 family inheritance) for ORCHIDEE V3's local site adapter (ADR-0003), aligned with ONERBA (Cap. II pp. 21-22 & Annexe 4 p. 44), SPARES (pp. 14-15 & Annexe 4 p. 27), and Rouen's 3-tier screening note (`note-cadrage-depistage-microbiologie.md`).

CRITICAL EXECUTION RULES:
- DO NOT call any file-reading or search tools. All context (`lbl`, `v1_cat`, `v1_role`, `v1_conf`, GLIMS `ta`/`wk`, `uf` SEJUF, `um` SEJUM, `tri` TRI, `sp` species, `nbact`, `nmyco`, `nblood`, `nurine`, `nfluid`, `nsysr`, `nbgsta_only`, `nbgsta_cult`, `nbgstrb`) is ALREADY in the JSON payload.
- Evaluate EVERY single `id` (`LBL_xxxx`) in the input array directly and call `finish` in ONE turn. Return every exact `label_id` unmodified.
- NEVER copy `v1_conf` blindly! Assess `confidence` AT THE INDIVIDUAL LABEL LEVEL: many surgical/bone/abscess labels had `v1_conf='medium'` solely because their v1 *family* (`UNSPECIFIED_OR_OTHER`) was heterogeneous, whereas individually `"BIOPSIE OSSEUSE METATARSE"` or `"ABCES DU FOIE"` is `confidence="high"`.

OUTPUT COMPACTNESS RULE (PREVENT JSON TRUNCATION):
- If `v1_status == "confirmed"` AND `needs_composite_lis_rule == False`: write an ultra-short `rationale` of 3 to 6 words (e.g. `"Confirmed diagnostic urine midstream."`, `"Confirmed peripheral blood culture."`, `"Confirmed deep bone tissue."`).
- If `v1_status == "reclassified"` or `"flagged"` (or `needs_composite_lis_rule == True`): write 1 crisp sentence (12-28 words) citing the distinguishing text or GLIMS signal (`ta`/`wk`/`uf`/`tri`/`sp`/`nmyco` or ONERBA p. 22 / SPARES Annexe 4 p. 27).

17 TARGET `naturepvt_norm` CATEGORIES:
1. `hemoculture`: Blood cultures (`Hémoculture...`, `ART`, or `nblood == n` with arterial/venous blood line label).
2. `urines`: Diagnostic urines (`URINE MILIEU DE JET`, `URINE PAR SONDE VESICALE`, `URINE PAR CATHETER SUS PUBIEN`, `Urine BRICKER/NEPHROSTOMIE/JJ/AUTO-SONDAGE`, bare `VE`). NOTE: urinary catheter hardware WITHOUT urine (`Sonde urinaire`, `Sonde JJ`) -> `autre_prelevement`; renal/nephrostomy abscess/pus (`ABCES LOGE DE NEPHROSTOMIE`) -> `prelevement_profond`, NEVER `urines`.
3. `dispositif_intravasculaire`: Cultured intravascular catheter tips/ports (`Cathéter`, `PICC LINE`, `MIDLINE`, `CVO`, `CIP`, `KT` vascular) when NOT `Hémoculture` and NOT CSF shunt (`DVP`) or peritoneal dialysis (`KT DP`).
4. `liquide_cephalorachidien`: `LCR`, `LCR (dérivation)`, `DVE`, `DVP` (ventriculoperitoneal shunt), CSF reservoir (`OMMAYA`) — verify `nfluid > 0` or unambiguous CSF wording; superficial `SOUS CUTANE DVE` with wound culture and `nfluid == 0` -> `pus_superficiel` or `flagged`.
5. `liquide_pleural`: Pleural fluid, empyema, plèvre.
6. `liquide_articulaire`: Joint/synovial fluid, articular capsule, synovium, AND orthopedic bursitis (`BOURSE PRE PATELLAIRE`, `BOURSE GENOU/COUDE/OLECRANE`). NOTE per ONERBA Cap. II p. 22: explicit swabs of joints (`ECOUVILLON INTRA ARTICULAIRE`) should be flagged (`flagged` / `ask_chu_rouen` or `autre_prelevement`).
7. `liquide_ascite`: Ascitic fluid and peritoneal dialysis fluid (`Liquide d'ascite`, `Liquide DIALYSE PERITONEALE`). Ordinary surgical/post-op `Liquide péritonéal` (without `ascite` or `dialyse péritonéale`) is `prelevement_profond` (SPARES Annexe 4 p. 27)!
8. `prelevement_profond`: Deep sterile puncture/surgical/bone/implant specimens (SPARES Annexe 4 p. 27): `Liquide péritonéal` (non-ascite), `Liquide péricardique`, `Bile`, `Humeur aqueuse`, `Vitré`, deep hematomas/collections/seromas, visceral/intracavitary abscesses, `Os` / `Biopsie osseuse` / `Séquiestre` / `Métatarse` / `Calcanéum`, `Muscle`, `Aponévrose`, `Tendon` / `Gaine fléchisseur`, heart valves, `Ganglion`, internal implants (`Prothèse`, `Ostéosynthèse`, `Boîtier Pacemaker`, `Canule HeartMate`).
   - NOTE per ONERBA Cap. II p. 22: swabs (`ECOUVILLON...` even `ECOUVILLON EPIDURAL`, `ECOUVILLON OS...`) and open decubitus/pressure ulcers (`ESCARRE`, even `"PRELEVEMENT PROFOND ESCARRE"` without bone biopsy) are EXCLUDED from `prelevement_profond` (reclassify `ESCARRE` without bone to `pus_superficiel`; flag deep-site swabs!).
   - NOTE on surgical drains (`Liquide REDON`, `Drain`): standard drain fluids go to `autre_prelevement` per SPARES/ONERBA unless deep abscess puncture; deep surgical false membranes (`Fausse membrane`) or deep prostheses go to `prelevement_profond`.
9. `respiratoire_protege`: `LBA`, `PBDP`, `PDP`, bronchial brush (`Brosse`), `KT protégé`.
10. `respiratoire_non_protege`: `Expectoration`, `Crachat`, `Aspiration bronchique/trachéale/pharyngée`, `Mucovisidose` sputum/pharyngeal aspirate, `Trachéotomie`.
11. `coproculture`: Diagnostic stool (`Selles`, `Coproculture`), NOT rectal carriage screening swabs (`REC`, `ANU`, `BGBLSE_R`).
12. `prelevement_genital`: Female/male genital tracts (`Ecouvillon vaginal`, `Endocol`, `Vulve`, `Col`, `Cul-de-sac vaginal`, `Bartholin`, `Lochies`, `Urètre`, `Sperme`, `Verge`, `Prépuce`, `Testicule`, scrotal `Bourse`).
    - WATCH OUT for v1 regex illusions: `BOURSE PRE PATELLAIRE`/`GENOU` is `liquide_articulaire`, `CUL DE SAC SOUS QUADRICIPITAL` is orthopedic (`liquide_articulaire`/`prelevement_profond`), and `PRE AURICULAIRE`/`PRE STERNAL`/`PRE THYROIDIEN`/`PRE CAVUM`/`PRE PATELLAIRE`/`PRE TRAGIEN`/`PRE XIPHOIDIEN` is anatomical *pré-* (`pus_superficiel` or `prelevement_profond`), NOT `prépuce` (`prelevement_genital`)!
    - For `Ecouvillon vaginal` with `nbgstrb > 0`: `prelevement_genital`, `context_dependent`, `needs_composite_lis_rule=True`, `resolution_lever="filter_typeana"`.
13. `prelevement_nouveau_ne`: `Liquide amniotique`, `Placenta`, `Cordon ombilical`, neonatal `Liquide gastrique` / `Multi-sites` / `Meconium`. WATCH OUT: ophthalmology corneal amniotic membrane grafts (`COLLERETTE MENBRANE AMNIOTIQUE` with ophthalmology `uf`/`ta`) -> `autre_prelevement`, NOT `prelevement_nouveau_ne`!
14. `pus_superficiel`: Superficial pus/swabs, `Plaie`, `Ulcère`, `Escarre` (without bone biopsy), `Brûlure`, `Cicatrice`, `Moignon`, `Panaris`, `Furoncle`, subcutaneous/parietal collections (`Abcès de paroi`, `Pré-sternal`), ENT ear/sinus/oral/tonsil (`OREILLE`, `CAE` = *Conduit Auditif Externe*!, `AMYGDALE*`, `Otorrhée`, oral mycology swabs), conjunctiva (`OEIL`, `CONJONCTIVE`), catheter exit sites (`ORIFICE HEART MATE` / `EMERGENCE KT DP` -> `pus_superficiel` or `autre_prelevement`), AND perianal abscesses/fistulas (`Abcès marge anale`, `Fistule anale`, `Sinus pilonidal` -> ALWAYS `diagnostic`).
15. `autre_prelevement`: Surgical drains/Redons (`Liquide REDON`, `Drain`), rinse/preservation fluids (`Liquide de rinçage`), corneal scrapings (`Cornée`, `Lentille`), non-vascular physical devices (`Sonde urinaire`, `Sonde JJ`, `KT DP`, `Stérilet`, `Canule trachéo`), bare anatomical regions without pus/biopsy/abscess (`MAIN DROITE`, `CUISSE GAUCHE`, `SCARPA` - check `ta`: `BGASP` vs superficial `BGCULTAE`), exit sites (`ORIFICE`/`EMERGENCE`), ophthalmology grafts.
16. `depistage_portage`: Canonical carriage screening sites & explicit screening labels (`DEPISTAGE_EXPLICITE`, bare `NEZ`/`Narine`, `AISSELLE`, `AINE`, `RECTUM`/`ANUS`/`Marge anale` without abscess/fistula/pus, `GORGE`/`Pharynx`).
    - WATCH OUT: ENT tonsils (`AMYGDALE*` with 0% screening) -> `pus_superficiel` (or `autre_prelevement`), `diagnostic`, NOT `depistage_portage`! Nasal septal/sinus lesions (`CLOISON NASALE`, `FOSSE NASALE`) -> `pus_superficiel`, `diagnostic`. Mycology-only swabs on `Ecouvillon  nez`/`Ecouvillon  aine`/`Ecouvillon  gorge` -> set `needs_composite_lis_rule=True`, `resolution_lever="exclude_mycology"`.
17. `unclassifiable`: Non-informative labels (`X`, `SANS`, `Autre`, `Inconnu`, `DROITE`, `GAUCHE`, container-only text like `1 POT ST + 1 TUBE BORATE` without anatomical text). Check `ta`/`uf`: if `ta` reveals `BGUCYTO`/`BGASPU` or `BGFA*` or `_R`, keep `unclassifiable` (on raw text alone) OR flag `needs_composite_lis_rule=True`, `resolution_lever="filter_typeana"` (or `"ask_chu_rouen"`).

WHEN TO SET `v1_status`, `needs_composite_lis_rule`, `resolution_lever`:
- `v1_status`:
  - `"reclassified"`: you change `naturepvt_norm != v1_cat` OR `diagnostic_vs_screening_role != v1_role`.
  - `"flagged"`: `naturepvt_norm == v1_cat` AND `diagnostic_vs_screening_role == v1_role`, EXCEPT a composite LIS rule is needed (`needs_composite_lis_rule=True`), or mycology-only leakage (`nmyco > 0`), or ONERBA swab/sterile ambiguity / bare shorthand / CHU Rouen question (`resolution_lever != "text_sufficient"`), or text conflicts with `ta`/`uf`/`sp`.
  - `"confirmed"`: `naturepvt_norm == v1_cat` AND `diagnostic_vs_screening_role == v1_role` AND `needs_composite_lis_rule == False` AND `resolution_lever == "text_sufficient"`.
- `needs_composite_lis_rule` (`true`/`false`): `true` whenever correct routing/filtering cannot rely on `NATUREPVT` text alone and requires `TYPEANA` (e.g. `nsysr > 0`, `nbgsta_only > 0`, `nbgsta_cult > 0`, `nbgstrb > 0`, uninformative text rescued by `BGUCYTO`/`BGFA*`), `SEJUF`/`SEJUM`/`TRI` (ambiguous shorthand `SONDE`/`VE`/`CIP`/age neonatal `Liquide gastrique`/ophthalmology `MENBRANE AMNIOTIQUE`), or `*_MY` mycology exclusion (`nmyco > 0`).
- `resolution_lever`:
  - `"exclude_mycology"`: label entered antibiogram catalog wholly (`nbact == 0, nmyco > 0`) or partly (`nmyco > 0`) via antifungal `*_MY` panels.
  - `"filter_typeana"`: `TYPEANA` resolves the ambiguity (`BGSTRB`, `BGSTA_R` vs `BGCULTAE`, `_R`, `BGUCYTO`/`BGASPU`, `BGFA*`, `BGNUML`/`BGEDL`, `BGASP+BGCULTANAG` vs bare site).
  - `"filter_sejuf_tri"`: clinical unit `uf`/`um` (`SEJUF`/`SEJUM`) or discipline `tri` (`TRI`) resolves bare shorthand (`SONDE` in Card vs Urol, `POCHE`, `VALVE`, neonatal age, ophthalmology vs obstetrics).
  - `"ask_chu_rouen"`: neither text nor available LIS columns unambiguously decide; needs Rouen bacteriologist/hygienist ruling (e.g., parietal abscess depth vs superficial ONERBA convention, `ECOUVILLON` on epidural/joint, completely opaque typo/`DROITE`/`X` without disambiguating `TYPEANA`).
  - `"text_sufficient"`: `NATUREPVT` text is clear on its own (`needs_composite_lis_rule == False`).
"""


def is_valid_item(it, expected_set=None):
    if not isinstance(it, dict):
        return False
    lid = it.get("label_id")
    if not isinstance(lid, str) or (expected_set is not None and lid not in expected_set):
        return False
    if it.get("naturepvt_norm") not in ONERBA_SET:
        return False
    if it.get("diagnostic_vs_screening_role") not in ROLE_SET:
        return False
    if it.get("confidence") not in CONF_SET:
        return False
    if it.get("v1_status") not in V1_STATUS_SET:
        return False
    if not isinstance(it.get("needs_composite_lis_rule"), bool):
        return False
    if it.get("resolution_lever") not in LEVER_SET:
        return False
    rat = it.get("rationale")
    if not isinstance(rat, str) or not rat.strip():
        return False
    return True


def sync_item_with_v1(it, inp):
    """Ensure v1_status is 100% consistent with (naturepvt_norm, role) vs (v1_cat, v1_role)."""
    out = dict(it)
    changed_vs_v1 = (
        out["naturepvt_norm"] != inp["v1_cat"]
        or out["diagnostic_vs_screening_role"] != inp["v1_role"]
    )
    if changed_vs_v1:
        out["v1_status"] = "reclassified"
    elif out["v1_status"] == "reclassified":
        # Category and role matched v1, so downgrade spurious 'reclassified' to 'flagged' or 'confirmed'
        if out["needs_composite_lis_rule"] or out["resolution_lever"] != "text_sufficient" or out["confidence"] == "ambiguous_needs_human_review":
            out["v1_status"] = "flagged"
        else:
            out["v1_status"] = "confirmed"
    return out


async def verify_batch(batch_meta):
    bid = batch_meta["batch_id"]
    batch_items = batch_meta["inputs"]
    expected_ids = [x["id"] for x in batch_items]
    expected_set = set(expected_ids)
    input_by_id = {x["id"]: x for x in batch_items}
    out_path = BATCH_DIR / f"batch_{bid:03d}.json"

    if out_path.exists():
        try:
            cached = json.loads(out_path.read_text(encoding="utf-8"))
            if (
                isinstance(cached, list)
                and len(cached) == len(expected_ids)
                and all(is_valid_item(it, expected_set) for it in cached)
                and {it["label_id"] for it in cached} == expected_set
            ):
                log(f"Batch {bid:03d}: loaded valid 100% cache ({len(cached)} labels).")
                return [sync_item_with_v1(it, input_by_id[it["label_id"]]) for it in cached]
            else:
                log(f"Batch {bid:03d}: cache failed 100% label_id/schema check; regenerating.")
        except Exception as exc:
            log(f"Batch {bid:03d}: unreadable cache ({exc}); regenerating.")

    prompt = f"""Audit Batch {bid:03d} ({len(expected_ids)} labels: {expected_ids[0]} .. {expected_ids[-1]}).

{V2_RULES_GUIDE}

Input labels (Batch {bid:03d}):
{json.dumps(batch_items, ensure_ascii=False)}

Return JSON with key `items` containing ALL {len(expected_ids)} `label_id`s from `{expected_ids[0]}` to `{expected_ids[-1]}`. Call `finish` now."""

    res = await agent(
        prompt=prompt,
        schema=BATCH_VERIFY_SCHEMA,
        type_name="research",
        model="flash",
        role=f"Verify batch {bid:03d}/{batch_meta['total_batches']} ({len(expected_ids)} labels)",
    )
    by_id = {}
    for it in res.get("items", []):
        if is_valid_item(it, expected_set):
            by_id[it["label_id"]] = it

    # Strict auto-backfill loop for any missing label_ids
    attempt = 0
    while len(by_id) < len(expected_ids) and attempt < 3:
        attempt += 1
        missing_ids = [eid for eid in expected_ids if eid not in by_id]
        log(f"Batch {bid:03d}: backfill attempt {attempt} for {len(missing_ids)} missing label_ids: {missing_ids[:10]}")
        # Chunk backfills to <=40 to guarantee zero truncation
        for c_start in range(0, len(missing_ids), 40):
            chunk_ids = missing_ids[c_start : c_start + 40]
            chunk_inputs = [input_by_id[eid] for eid in chunk_ids]
            bf_res = await agent(
                prompt=f"""Backfill missing labels for Batch {bid:03d} ({len(chunk_ids)} labels: {chunk_ids}).

{V2_RULES_GUIDE}

Missing labels:
{json.dumps(chunk_inputs, ensure_ascii=False)}

Return JSON with `items` containing every single missing `label_id`. Call `finish` now.""",
                schema=BATCH_VERIFY_SCHEMA,
                type_name="research",
                model="flash",
                role=f"Backfill batch {bid:03d} ({len(chunk_ids)} labels)",
            )
            for it in bf_res.get("items", []):
                if is_valid_item(it, expected_set):
                    by_id[it["label_id"]] = it

    still_missing = [eid for eid in expected_ids if eid not in by_id]
    if still_missing:
        raise RuntimeError(f"Batch {bid:03d} still missing {len(still_missing)} labels after backfill: {still_missing}")

    ordered = [sync_item_with_v1(by_id[eid], input_by_id[eid]) for eid in expected_ids]
    out_path.write_text(json.dumps(ordered, ensure_ascii=False, indent=2), encoding="utf-8")
    return ordered


input_files = sorted(BATCH_DIR.glob("input_batch_*.json"))
assert len(input_files) >= 70, f"Expected input_batch_*.json files in {BATCH_DIR}, found {len(input_files)}"

all_batches = []
all_inputs_by_id = {}
for idx, fpath in enumerate(input_files, start=1):
    rows = json.loads(fpath.read_text(encoding="utf-8"))
    for r in rows:
        all_inputs_by_id[r["id"]] = r
    all_batches.append({
        "batch_id": idx,
        "total_batches": len(input_files),
        "inputs": rows,
    })

assert len(all_inputs_by_id) == 8462, f"Expected 8462 distinct label_ids across input batches, got {len(all_inputs_by_id)}"

phase(f"Phase 1: 1-to-1 verification across all {len(all_inputs_by_id)} labels in waves of 6")
phase1_by_id = {}
WAVE_SIZE = 6
n_waves = (len(all_batches) + WAVE_SIZE - 1) // WAVE_SIZE

for w_idx, start in enumerate(range(0, len(all_batches), WAVE_SIZE), start=1):
    wave = all_batches[start : start + WAVE_SIZE]
    log(f"Starting Phase 1 Wave {w_idx}/{n_waves} (batches {wave[0]['batch_id']}..{wave[-1]['batch_id']})")
    wave_results = await parallel(wave, verify_batch)
    for items in wave_results:
        for it in items:
            phase1_by_id[it["label_id"]] = it

assert set(phase1_by_id) == set(all_inputs_by_id), (
    f"Phase 1 mismatch: missing {len(set(all_inputs_by_id) - set(phase1_by_id))}"
)

n_recl_p1 = sum(1 for v in phase1_by_id.values() if v["v1_status"] == "reclassified")
n_flag_p1 = sum(1 for v in phase1_by_id.values() if v["v1_status"] == "flagged")
n_conf_p1 = sum(1 for v in phase1_by_id.values() if v["v1_status"] == "confirmed")
n_comp_p1 = sum(1 for v in phase1_by_id.values() if v["needs_composite_lis_rule"])
n_nonhigh_p1 = sum(1 for v in phase1_by_id.values() if v["confidence"] != "high")
log(
    f"Phase 1 complete (8,462/8,462): confirmed={n_conf_p1}, reclassified={n_recl_p1}, "
    f"flagged={n_flag_p1}, composite_lis={n_comp_p1}, non_high_conf={n_nonhigh_p1}"
)

phase("Phase 2: Main-model cross-check on high-priority clinical labels")

# Always include reclassified, flagged, composite_lis, ambiguous_needs_human_review, ask_chu_rouen,
# plus non-high confidence labels (prioritizing higher sample counts if total candidate pool is very large).
tier_a_ids = []
tier_b_ids = []
for lid in sorted(all_inputs_by_id):
    p1 = phase1_by_id[lid]
    if (
        p1["v1_status"] in ("reclassified", "flagged")
        or p1["needs_composite_lis_rule"]
        or p1["resolution_lever"] != "text_sufficient"
        or p1["confidence"] == "ambiguous_needs_human_review"
    ):
        tier_a_ids.append(lid)
    elif p1["confidence"] != "high":
        tier_b_ids.append(lid)

tier_a_ids.sort(key=lambda lid: (-all_inputs_by_id[lid]["n"], lid))
tier_b_ids.sort(key=lambda lid: (-all_inputs_by_id[lid]["n"], lid))

MAX_P2_TOTAL = 1200
if len(tier_a_ids) + len(tier_b_ids) <= MAX_P2_TOTAL:
    p2_ids = tier_a_ids + tier_b_ids
else:
    rem = max(0, MAX_P2_TOTAL - len(tier_a_ids))
    p2_ids = tier_a_ids + tier_b_ids[:rem]

log(
    f"Phase 2 selection: {len(tier_a_ids)} Tier-A (reclassified/flagged/composite/ambiguous/ask_rouen) + "
    f"{len(p2_ids) - len(tier_a_ids)} of {len(tier_b_ids)} Tier-B (medium conf) = {len(p2_ids)} labels total."
)

P2_BATCH_SIZE = 55
p2_batches = []
for c_idx, start in enumerate(range(0, len(p2_ids), P2_BATCH_SIZE), start=1):
    c_ids = p2_ids[start : start + P2_BATCH_SIZE]
    p2_batches.append({
        "cc_id": c_idx,
        "total_cc": (len(p2_ids) + P2_BATCH_SIZE - 1) // P2_BATCH_SIZE,
        "label_ids": c_ids,
    })


async def crosscheck_p2_batch(cc_meta):
    cid = cc_meta["cc_id"]
    expected_ids = cc_meta["label_ids"]
    expected_set = set(expected_ids)
    out_path = BATCH_DIR / f"crosscheck_{cid:03d}.json"

    if out_path.exists():
        try:
            cached = json.loads(out_path.read_text(encoding="utf-8"))
            c_items = cached.get("items", []) if isinstance(cached, dict) else []
            if (
                isinstance(cached, dict)
                and "themes" in cached
                and len(c_items) == len(expected_ids)
                and all(is_valid_item(it, expected_set) for it in c_items)
                and {it["label_id"] for it in c_items} == expected_set
            ):
                log(f"Cross-check {cid:03d}: loaded valid cache ({len(c_items)} labels).")
                return cached
            else:
                log(f"Cross-check {cid:03d}: cache invalid/incomplete; regenerating.")
        except Exception as exc:
            log(f"Cross-check {cid:03d}: unreadable cache ({exc}); regenerating.")

    payload = [
        {
            "input": all_inputs_by_id[lid],
            "phase1_flash": phase1_by_id[lid],
        }
        for lid in expected_ids
    ]
    prompt = f"""Phase 2 Main-Model Cross-Check Batch {cid:03d}/{cc_meta['total_cc']} ({len(expected_ids)} priority labels).

{V2_RULES_GUIDE}

You are the senior microbiology/methodology reviewer verifying Phase 1 (`flash`) decisions.
For each entry (`input` + `phase1_flash`), confirm or refine:
1. `naturepvt_norm` (17 categories), `diagnostic_vs_screening_role`, `confidence`, `v1_status`, `needs_composite_lis_rule`, `resolution_lever`, and `rationale`.
   - Enforce ONERBA Cap. II p. 22 strictly: `ESCARRE` without bone biopsy -> `pus_superficiel` (never `prelevement_profond`); superficial swabs (`ECOUVILLON` on joints/epidural/CAE osteitis) flagged cleanly.
   - Enforce v1 homograph fixes: `CAE` (ear -> `pus_superficiel`), orthopedic `BOURSE...GENOU/PATELL` -> `liquide_articulaire`, `CUL DE SAC SOUS QUADRI*` -> `liquide_articulaire`/`prelevement_profond`, `PRE AURICULAIRE/STERNAL/THYROIDIEN/PATELLAIRE` -> NOT `prelevement_genital`, `AMYGDALE*` -> diagnostic ENT (not `depistage_portage`), `DVP` -> `liquide_cephalorachidien`, `KT DP`/`EMERGENCE KT DP` -> `autre_prelevement`/`pus_superficiel`, ophthalmology `MENBRANE AMNIOTIQUE` -> `autre_prelevement`.
   - Enforce Mycology `*_MY` (`nmyco > 0`, `nbact == 0`) -> `needs_composite_lis_rule=True`, `resolution_lever="exclude_mycology"`, clearly explaining mycology leakage.
   - Check composite LIS rules (`filter_typeana` for `BGSTRB`, `BGSTA_R` vs `BGCULTAE`, `_R`, `BGUCYTO`, `BGFA*`, `BGNUML`; `filter_sejuf_tri` for `uf`/`tri` unit resolution; `ask_chu_rouen` ONLY when text + LIS signals remain genuinely ambiguous for CHU Rouen bacteriologists).
   - Ensure `v1_status` reflects comparison against `input.v1_cat` and `input.v1_role` (`reclassified` if either differs from v1; `flagged` if same category/role but requires composite rule, mycology exclusion, or Rouen question; `confirmed` only if identical to v1 and `needs_composite_lis_rule == False` and `resolution_lever == "text_sufficient"`).
2. `themes`: 1 to 3 concise clinical themes / unresolved questions arising from this batch (avoid generic filler).

Batch {cid:03d} entries:
{json.dumps(payload, ensure_ascii=False)}

Return JSON with `items` (ALL {len(expected_ids)} exact `label_id`s) and `themes`. Call `finish` now."""

    res = await agent(
        prompt=prompt,
        schema=CROSSCHECK_V2_SCHEMA,
        type_name="research",
        model=None,
        role=f"Cross-check batch {cid:03d}/{cc_meta['total_cc']} ({len(expected_ids)} labels)",
    )
    by_id = {}
    for it in res.get("items", []):
        if is_valid_item(it, expected_set):
            by_id[it["label_id"]] = it

    attempt = 0
    while len(by_id) < len(expected_ids) and attempt < 2:
        attempt += 1
        missing_ids = [eid for eid in expected_ids if eid not in by_id]
        log(f"Cross-check {cid:03d}: backfilling {len(missing_ids)} missing label_ids...")
        bf_payload = [{"input": all_inputs_by_id[lid], "phase1_flash": phase1_by_id[lid]} for lid in missing_ids]
        bf_res = await agent(
            prompt=f"""Backfill missing labels for Cross-check Batch {cid:03d}: {missing_ids}.

{V2_RULES_GUIDE}

{json.dumps(bf_payload, ensure_ascii=False)}

Return JSON with `items` and `themes`. Call `finish` now.""",
            schema=CROSSCHECK_V2_SCHEMA,
            type_name="research",
            model=None,
            role=f"Backfill cross-check {cid:03d} ({len(missing_ids)} labels)",
        )
        for it in bf_res.get("items", []):
            if is_valid_item(it, expected_set):
                by_id[it["label_id"]] = it

    still_missing = [eid for eid in expected_ids if eid not in by_id]
    if still_missing:
        raise RuntimeError(f"Cross-check {cid:03d} still missing: {still_missing}")

    ordered_items = [sync_item_with_v1(by_id[eid], all_inputs_by_id[eid]) for eid in expected_ids]
    out_obj = {
        "items": ordered_items,
        "themes": res.get("themes", []),
    }
    out_path.write_text(json.dumps(out_obj, ensure_ascii=False, indent=2), encoding="utf-8")
    return out_obj


final_by_id = dict(phase1_by_id)
all_themes = []
seen_titles = set()

if p2_batches:
    CC_WAVE_SIZE = 2
    n_cc_waves = (len(p2_batches) + CC_WAVE_SIZE - 1) // CC_WAVE_SIZE
    for w_idx, start in enumerate(range(0, len(p2_batches), CC_WAVE_SIZE), start=1):
        cc_wave = p2_batches[start : start + CC_WAVE_SIZE]
        log(f"Starting Phase 2 Wave {w_idx}/{n_cc_waves} (cross-check {cc_wave[0]['cc_id']}..{cc_wave[-1]['cc_id']})")
        cc_results = await parallel(cc_wave, crosscheck_p2_batch)
        for c_res in cc_results:
            for it in c_res["items"]:
                final_by_id[it["label_id"]] = it
            for th in c_res.get("themes", []):
                tkey = th.get("title", "").strip().lower()
                if tkey and tkey not in seen_titles:
                    seen_titles.add(tkey)
                    all_themes.append(th)

# Deterministic ordering and final invariant synchronization against v1
final_list = []
for lid in sorted(all_inputs_by_id):
    synced = sync_item_with_v1(final_by_id[lid], all_inputs_by_id[lid])
    final_list.append(synced)

assert len(final_list) == 8462, f"Expected 8462 final labels, got {len(final_list)}"

for idx, th in enumerate(all_themes, start=1):
    th["theme_id"] = f"V2_THEME_{idx:02d}"

(V2_DIR / "labels_v2_verified.json").write_text(
    json.dumps(final_list, ensure_ascii=False, indent=2), encoding="utf-8"
)
(V2_DIR / "crosscheck_themes_v2.json").write_text(
    json.dumps(
        {
            "n_phase1_total": len(phase1_by_id),
            "n_phase2_crosschecked": len(p2_ids),
            "phase2_label_ids": p2_ids,
            "themes": all_themes,
        },
        ensure_ascii=False,
        indent=2,
    ),
    encoding="utf-8",
)

by_status = {}
by_lever = {}
for it in final_list:
    by_status[it["v1_status"]] = by_status.get(it["v1_status"], 0) + 1
    by_lever[it["resolution_lever"]] = by_lever.get(it["resolution_lever"], 0) + 1

log(f"v2 workflow complete: 8,462/8,462 labels verified ({len(p2_ids)} cross-checked by main model).")
print("BY_V1_STATUS:", json.dumps(by_status, ensure_ascii=False))
print("BY_RESOLUTION_LEVER:", json.dumps(by_lever, ensure_ascii=False))
print("SAVED:", str(V2_DIR / "labels_v2_verified.json"))
