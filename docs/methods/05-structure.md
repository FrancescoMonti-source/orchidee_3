# 05 - Establishment structure

Status: **settled**. Five decisions, five witnesses, zero unproven.

## What SPARES says

> Afin d'assurer une analyse des données par secteur d'activité clinique et par
> unité fonctionnelle (ou service ou pôle), un fichier « structure » est à
> intégrer dans l'outil avant tout import de données d'activité, de consommation
> ou de résistances bactériennes.
> Le fichier structure doit comporter les informations suivantes pour chaque UF :
> • Code UF
> • Libellé UF
> • Code service (facultatif)
> • Libellé service (facultatif)
> • Code pôle (facultatif)
> • Libellé pôle (facultatif)
> • Code « discipline d'équipement » (DE) (liste codes DE)
> • Code « type d'activité » (TA) (liste codes TA)

> Il est indispensable de s'assurer de la cohérence stricte entre la codification
> des UF utilisée par l'administration, la pharmacie et le laboratoire afin de
> relier ces informations entre elles lors de l'analyse des résultats.

> Si la structure de l'établissement n'est pas modifiée d'une année à l'autre,
> il n'est pas nécessaire d'intégrer à nouveau ces données l'année suivante : les
> données sont mémorisées pour les prochaines connexions.

> La dispensation d'antibiotiques et la réalisation de prélèvements dans les
> unités de soins intensifs et unités de surveillance continue spécialisées sont
> affectées à la discipline correspondante, en médecine, chirurgie ou pédiatrie.

## What ORCHIDEE does

The establishment structure is provided as an annual versioned table
`unit_mapping`, keyed strictly by **`SEJUF`**, carrying `CODE_TA`, `CODE_DE`,
and `de_domain_ref`.

**Sample hospitalisation unit attribution** is derived dynamically from patient
hospitalisation movement intervals at sampling time (`DATENT <= sample_datetime <
DATSORT`). When a sample cannot be attributed to an active hospitalisation stay
(`no_active_interval`, `multiple_active_unit_pairs`, or timestamp edge cases),
the canonical `SEJUF` is set to `NA`. Under decision 03.5, an isolate with `SEJUF
= NA` is excluded from the eligible surveillance perimeter.

**Specialised intensive-care and continuous-monitoring units** are classified
according to the French national `CODE_DE` → `DOMAINE` reference table
(`reference_code_de.csv`), which already maps specialised units to their
respective disciplines (e.g. DE 106/107/637/641 to MÉDECINE, DE 142 to
CHIRURGIE, DE 235/635/636/638 to PÉDIATRIE) and reserves RÉANIMATION for
general adult intensive care (DE 104, 105, 141, 735). ORCHIDEE validates the
site's declared `de_domain_ref` against this national reference.

**Coherence** across administration, pharmacy, and laboratory is verified
through a non-blocking tripwire. Because the perimeter is defined positively
(decision 03.5), unmapped UFs cannot enter surveillance by omission. Any
residue of unmapped UFs is counted, published in the divergence account, and
checked against an established tolerance threshold.

## Decisions

Witnesses measured on Rouen's real PMSI (`data/pmsi`), microbiology observations
(`outputs/rouen_current/site_inputs/microbiology_observations.rds`), diagnostic
isolate extract (`outputs/rouen_current/bundle_v3/sir_wide.rds`), and structure
file (`ref/rouen/establishment_structure_2025.xlsx`), calendar year 2024.

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 05.1 | Unit-less isolates | strict PMSI interval attribution; `SEJUF = NA` excludes isolate from perimeter | fallback to microbiology ordering UF | keeps **2 445** vs **2 555** (+110, +4.5 %, 93 patients gained); céfotaxime moves **14.80 → 15.82 %R (+1.02 pp)**. `docs/worked-examples/unit-attribution.md` |
| 05.2 | Structure coherence | positive perimeter (03.5) with non-blocking tripwire asserting > 99.9 % resolution | blocking schema check on ingestion | admin: 362/362 (100 %) in structure; lab: 272/278 in structure (6 external UFs, 68 raw rows, 0 in `sir_wide`). A blocking check fails on inert codes |
| 05.3 | ICU reassignment | defined by national DE table; ORCHIDEE validates compliance | local text-parsing algorithm or subagent guessing | Rouen referential maps 3 USC to Médecine, 1 USC to Chirurgie, 4 réa néonat/péd to Pédiatrie; exactly 0 discrepancies with `reference_code_de.csv` |
| 05.4 | Structure versioning | annual snapshot per surveillance period (`calendar_year`) | dynamic time-validity intervals `[start_date, end_date[` per event | Rouen structure has 1 155 UFs, all with `Date fin UF = 2099-12-31` (0 mid-year splits). Dynamic intervals make annual deduplication non-transitive |
| 05.5 | Hierarchy granularity | `UF` (`SEJUF`) is the atomic key of the contract | `(UM, UF)` composite key, or mandatory Service/Pôle | SPARES and ConsoRes only recognize `Code UF`. Forcing `UM` leaks Rouen internal schema into portable contract (ADR 0003) |

Unproven: **0 of 5**.

### 05.1 note — why interval attribution failure cannot be patched with laboratory UFs

In Rouen's diagnostic isolate extract (`sir_wide.rds`), 3 650 isolates carry
`SEJUF = NA` (1 173 in 2024). 100 % of them carry a valid `microbiology_SEJUF`
in the raw laboratory export. Attribution failed due to:
- `no_active_interval`: 3 610 (98.9 %)
- `multiple_active_unit_pairs`: 25 (0.7 %)
- `active_interval_missing_complete_unit_pair`: 9 (0.2 %)
- `ambiguous_local_sample_datetime`: 6 (0.2 %)

Examining these 3 650 isolates against the establishment structure reveals why:
- **2 190 (60 %)** belong to excluded sectors: TA 10 (urgences, 1 278), TA 07
  (consultations externes, 447), TA 04 (HDJ, 164), TA 09 (séances, 149). These
  patients were never admitted to complete hospitalisation; the absence of a
  PMSI movement stay is legitimate.
- **1 456 (40 %)** belong to eligible TA/DE sectors: 632 in USLD (soins de
  longue durée) and 824 in MCO (Chirurgie 266, Médecine 206, Réanimation 124,
  SSR 115, Pédiatrie 55, Obstétrique 51). In MCO, these are pre-admission
  samplings (e.g. sample taken at 08:30 in ED, complete hospitalisation movement
  starts at 15:10) or stays omitted from the warehouse export. In USLD, stays
  are not captured in the acute MCO PMSI movement extract.

Falling back to the laboratory UF (Option B) adds 110 deduplicated *E. coli*
isolates (+4.5 %) and moves céfotaxime by +1.02 pp, but the denominator holds
**no corresponding patient-days** for them (USLD has only 17 JH in MCO PMSI;
pre-admission samples have 0 days prior to entry). Under decision 04.7, the
perimeter is one object handed to both numerator and denominator. Admitting
isolates whose hospital days are absent produces an incidence density of
nothing.

Option A is chosen with an explicit admission linkage rule: isolates without
hospitalisation exposure receive `SEJUF = NA` and are excluded from the perimeter.
However, to prevent discarding acute sepsis admissions, specimens collected in the
Emergency Department (TA 10) that are followed by an acute inpatient admission (TA 03/20)
within a bounded 24-hour look-ahead window are linked to the stay and attributed to the
initial receiving inpatient UF (`ADR-0009`). True outpatient visits without subsequent
hospitalisation remain excluded.

### 05.2 tripwire (TW-05.1)

**Statement**: 100 % of administration UFs with hospitalisation activity, and
\> 99.9 % of microbiology observations, resolve in the establishment structure. (Cataloged as `TW-05.1` in `tripwire-register.md`).
**Today**: Rouen administration has 362 UFs, 362/362 (100 %) in structure;
microbiology has 278 UFs, 272 in structure (6 external UFs, 68 raw rows, 0 in
`sir_wide`).

Non-blocking. If an unseen UF appears in laboratory data, decision 03.5
excludes it from surveillance by default, avoiding false-alarm pipeline halts
over external test referrals. The check fails if unmapped laboratory rows
exceed 0.1 %, or if any unit with patient-days cannot be classified.

### 05.3 note — specialised intensive care is a nomenclature mapping, not an algorithm

SPARES requires specialised intensive care and continuous monitoring to be
attributed to medicine, surgery, or paediatrics. This requirement does not
require ORCHIDEE to parse local French ward labels or run language models.

In the official French `CODE_DE` nomenclature (`reference_code_de.csv`):
- DE 106, 107, 637, 639, 640, 641 (USIC, USC médicale) are classified under
  `MÉDECINE`.
- DE 142 (USC chirurgicale) is classified under `CHIRURGIE`.
- DE 235, 635, 636, 638, 720, 734 (soins intensifs et réanimation néonatale /
  pédiatrique) are classified under `PÉDIATRIE`.
- Only DE 104, 105, 141, 735 (adult medical and surgical resuscitation) are
  classified under `RÉANIMATION`.

The site supplies `de_domain_ref` in `unit_mapping`, and ORCHIDEE verifies that
the domain matches the national DE standard.

### 05.4 note — annual structure snapshot protects deduplication monotonicity

Annual deduplication groups isolates across the entire calendar year for each
patient. If a unit's eligibility varied dynamically mid-year, an isolate's
eligibility would depend on its timestamp, introducing non-transitive
deduplication relations between isolates of the same patient.

Structure is therefore frozen per annual surveillance run (`calendar_year`).
Legitimate structural reorganisations (e.g. ward closures or sector mergers) are
monitored through the 04.10 exposure volume tripwire (±30 % year-over-year shift).

## Open

- **Extraction boundary for USLD.** 632 isolates in long-term care units (UFs
  7163, 7183, etc.) lack PMSI intervals because USLD is not extracted in acute
  MCO PMSI. If national surveillance includes USLD for a site, the site adapter
  must supply USLD movements alongside MCO movements so exposure and numerator
  remain coherent.
- **Mapping audit of unclassified UFs.** 6 UFs in Rouen's referential remain
  unclassified (2 with TA 03/20 and no DE: 5947, 8947; 4 absent from structure:
  570A, 572A, 6420, 7116).
- **Luna sample-type mapping.** Categorisation of ~25k `TYPE_PRELEV` labels to
  ONERBA thesaurus categories is suitable for an AI-assisted batch review,
  frozen into a versioned mapping file before code execution. Under decision
  03.6, mapping is required only for values that reach an indicator.
