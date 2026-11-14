# Throwaway `NATUREPVT` Sample-Type Mapping Prototype (CHU Rouen)

Question: how can the local Rouen **site adapter** map all **8,462** distinct raw GLIMS `NATUREPVT` labels observed on antibiogram samples (`data/bact22_24`) into the ONERBA / SPARES sample-type categories (`naturepvt_norm`) while accurately separating diagnostic infection specimens from carriage screening?

> **Architectural Boundary (`ADR-0003`)**: This prototype lives strictly inside the local Rouen **site adapter** experiment layer (`prototype/sample-type-mapping`). Core ORCHIDEE enforces the standardized `data/site_handoff/` contract and Chapter 00 common input audit and never applies French string heuristics internally. See [`docs/adr/0003-portable-contract-is-the-product.md`](../../adr/0003-portable-contract-is-the-product.md), [`docs/methods/00-audit-qualite.md`](../../methods/00-audit-qualite.md), and [`docs/methods/06-donnees-resistance.md`](../../methods/06-donnees-resistance.md).

## Methodological Foundation

- **Target categories (`naturepvt_norm`)**: Derived from the SPARES / ConsoRes sample-type thesaurus (SPARES Annexe 4, *Intitulé application ConsoRes*, p. 27; current indicator scope in `data/site_handoff/mapping_reference/current_indicator_naturepvt_norm.csv`: `hemoculture`, `urines`) and ONERBA surveillance methodology (ONERBA 2001, Chapitre II pp. 21–22 and Annexe 4 p. 44).
- **Rouen GLIMS coding rules**: Structural prefixes and the 84 anatomical origin codes (`AB` through `X`) documented in [`docs/Rouen/Codes enregistrement selon origine anatomique Microbiologie.pdf`](../../Rouen/Codes%20enregistrement%20selon%20origine%20anatomique%20Microbiologie.pdf).
- **Three-tier screening vs. diagnostic model**: Follows [`docs/methods/note-cadrage-depistage-microbiologie.md`](../../methods/note-cadrage-depistage-microbiologie.md) and [`docs/worked-examples/phenotypes-and-screening.md`](../phenotypes-and-screening.md):
  1. Systematic BMR/BHRe carriage batteries (`BGBLSE_R`, `BGCARBA_R`, `BGERV_R`, `BGSAMR_R`, `BGABRI_R`, `BGABMR_R`, `BGPYOBMR_R` — stored in GLIMS `TYPEANA` with `PARENT.CHILD` notation and 100 % empty `NATUREPVT` on screening rows).
  2. Context-dependent orders (`BGSTA_R` standalone vs. co-prescribed with `BGCULTAE`; prenatal `BGSTRB` vaginal screening).
  3. Anatomical site boundary separating superficial carriage reservoirs (`Nez`, `Narine`, `Aisselle`, `Aine`, `Rectum`/`Anus` without suppuration) from purulent or surgical collections (`Abcès marge anale`, `Fistule anale`, `Pus`, `Liquides`, `Biopsies`).

## 3-Stage Pipeline

1. **Stage 1 — Deterministic R Pre-Grouping (`stage1_pregroup.R`)**:
   - Reads `data/bact22_24` (5,154,206 rows; 25,266 distinct `NATUREPVT` values; **58,437** antibiogram `ELTID`s with at least one `STRRES %in% c("S", "SFP", "I", "R", "ZIT")`), extracting all **8,462** exact non-empty `NATUREPVT` labels (`51,351` samples, `61,423` isolates `(PATID, ELTID, DLVL)`), plus a separate audit of labels restricted to non-antibiogram samples and the `7,086` empty-`NATUREPVT` antibiogram `ELTID`s.
   - Extracts `ELTID`-level co-occurrence with `_R` screening orders, `BGSTA_R + BGCULTAE`, and `BGSTRB`, and groups the **8,462** labels into **396** anatomical families exported into 8 balanced JSON shards under `outputs/sample-type-prototype/shards/`.
2. **Stage 2 — Parallel Classification & Cross-Check (`classify_workflow.py` via `run_workflow`)**:
   - Fans out across the 8 shards in parallel to assign strict schema fields (`naturepvt_norm`, `diagnostic_vs_screening_role`, `confidence`, `rationale`).
   - Runs a Phase 2 cross-check pass auditing all `context_dependent`, `ambiguous_needs_human_review`, and heterogeneous families, emitting family adjustments, unit label overrides, and clinical review themes.
3. **Stage 3 — Review Artifacts & Self-Contained Explorer (`build_deliverables.R` & `demo.template.html`)**:
   - Merges Stage 1 and Stage 2 outputs into `outputs/sample-type-prototype/` (git-ignored, zero `PATID`/`EVTID`/`ELTID` exported):
     - `demo.html` — Double-clickable self-contained explorer (pure JS state/filter module + 5 guided walkthroughs + free exploration across families, all 8,462 labels, review queue, category summary matrix [SPARES Annexe 4 p. 27; ONERBA Annexe 4 p. 44], and `_R` audit).
     - `sample-type-review.md` — Structured Markdown review report and bacteriology validation agenda.
     - `family_mapping_table.csv` (396 families) & `naturepvt_mapping_table.csv` (all 8,462 raw labels).

## Running Locally (Windows)

```powershell
# Stage 1 pre-grouping (or rerun full build once Stage 2 JSONs exist):
./docs/worked-examples/sample-type-prototype/run.ps1 -Stage1Only

# After running Stage 2 workflow (`classify_workflow.py`):
./docs/worked-examples/sample-type-prototype/run.ps1 -BuildOnly
```

## References

- [`docs/adr/0003-portable-contract-is-the-product.md`](../../adr/0003-portable-contract-is-the-product.md)
- [`docs/methods/00-audit-qualite.md`](../../methods/00-audit-qualite.md) & [`docs/methods/06-donnees-resistance.md`](../../methods/06-donnees-resistance.md)
- [`docs/methods/note-cadrage-depistage-microbiologie.md`](../../methods/note-cadrage-depistage-microbiologie.md)
- [`docs/worked-examples/phenotypes-and-screening.md`](../phenotypes-and-screening.md)
- SPARES Methodology (`Methodologie SPARES we need to reproduce and improve upon.pdf`), pp. 14–15, Annexe 4 (p. 27), Annexe 6 footnote *a* (p. 31).
- ONERBA Recommendations (`ONERBA Recos_Methodo_Surveillance_onerba_2001.pdf`), Chapitre II (pp. 21–22), Annexe 4 (p. 44).
