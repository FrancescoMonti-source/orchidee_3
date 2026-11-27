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
the canonical inpatient `SEJUF` is set to `NA`. Under decision 03.5, an isolate
with `SEJUF = NA` is excluded from the strict inpatient perimeter
(`spares_strict`). To support both comparability with the SPARES perimeter
(SPARES pp. 9-10) and complete emergency surveillance without
post-deduplication filtering, ORCHIDEE resolves three named perimeters
(`03-activites.md`, `ADR-0009`):
1. **Precedence of active eligible inpatient stays**: If `sample_datetime` falls
   within an active movement interval (`DATENT <= sample_datetime < DATSORT`) of
   an eligible inpatient unit (`CODE_TA ∈ {03, 20}` and eligible `CODE_DE`),
   that unit takes precedence and the sample enters both **`spares_strict`**
   and **`spares_ed24h`**.
2. **Identification and attribution of Emergency (`TA 10`) samples**: If the
   sample does not fall within an active eligible inpatient interval, it is
   identified as an Emergency (`TA 10`) sample when its laboratory ordering UF
   belongs to `TA 10` (`microbiology_SEJUF ∈ TA 10`) or it falls within a
   `TA 10` movement:
   - It always enters **`emergency_ta10`** (deduplicated strictly within
     `TA 10`, publishing `%R` and isolate counts without a patient-day
     denominator).
   - It **also** enters **`spares_ed24h`** if the patient has an eligible
     inpatient movement (`CODE_TA ∈ {03, 20}` and eligible `CODE_DE`) starting
     within `(sample_datetime, sample_datetime + 24h]`, attributed to the
     earliest such inpatient movement (`min(DATENT)`, `ADR-0009`).

**Specialised intensive-care and continuous-monitoring units** are classified
according to the French national `CODE_DE` → `DOMAINE` reference table
(`reference_code_de.csv`), which already maps specialised units to their
respective disciplines (e.g. DE 106/107/637/641 to MÉDECINE, DE 142 to
CHIRURGIE, DE 235/635/636/638 to PÉDIATRIE) and reserves RÉANIMATION for
general adult intensive care (DE 104, 105, 141, 735). ORCHIDEE validates the
site's declared `de_domain_ref` against this national reference.

**Coherence** across administration, pharmacy, and laboratory is documented
through the pre-flight audit. Because the perimeter is defined positively
(decision 03.5), unmapped UFs cannot enter surveillance by omission. Any
residue of unmapped UFs is counted, published in the divergence account, and
reported without an audit tolerance threshold.

## Decisions

Witnesses measured on Rouen's real PMSI (`data/pmsi`), microbiology observations
(`outputs/rouen_current/site_inputs/microbiology_observations.rds`), diagnostic
isolate extract (`outputs/rouen_current/bundle_v3/sir_wide.rds`), and structure
file (`ref/rouen/establishment_structure_2025.xlsx`), calendar year 2024.

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 05.1 | Unit-less & ED isolates | three named perimeters (`spares_strict`, `spares_ed24h` with 24h `TA 10 -> TA 03/20` linkage, and `emergency_ta10`); no unconditional fallback to laboratory ordering UF | unconditional fallback to microbiology ordering UF | `spares_strict` vs Option B: keeps **2 445** vs **2 555** (+110, +4.5 %, 93 patients gained); céfotaxime moves **14.80 → 15.82 %R (+1.02 pp)** (`docs/worked-examples/unit-attribution.md`). Separate `spares_ed24h` and `emergency_ta10` counts to be measured on refreshed adapter handoff |
| 05.2 | Structure coherence | Report matched and unmatched unit codes and affected records; population selection belongs to 03.5 | Enforce a minimum coverage percentage in the audit | Admin: 362/362 (100 %) in structure; lab: 272/278 in structure (6 external UFs, 68 raw rows) |
| 05.3 | ICU reassignment | defined by national DE table; ORCHIDEE validates compliance | local text-parsing algorithm or subagent guessing | Rouen referential maps 3 USC to Médecine, 1 USC to Chirurgie, 4 réa néonat/péd to Pédiatrie; exactly 0 discrepancies with `reference_code_de.csv` |
| 05.4 | Structure versioning | annual snapshot per surveillance period (`calendar_year`) | dynamic time-validity intervals `[start_date, end_date[` per event | Rouen structure has 1 155 UFs, all with `Date fin UF = 2099-12-31` (0 mid-year splits). Dynamic intervals make annual deduplication non-transitive |
| 05.5 | Hierarchy granularity | `UF` (`SEJUF`) is the atomic key of the contract | `(UM, UF)` composite key, or mandatory Service/Pôle | SPARES's structure file for ConsoRes requires `Code UF`, `Code DE` and `Code TA`, with service and pôle optional and no UM defined (SPARES p. 12, Annexe 6 p. 31). Forcing `UM` leaks Rouen internal schema into portable contract (ADR 0003) |

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
- **1 456 (40 %)** belong to eligible TA/DE sectors in the laboratory ordering
  field: 632 in USLD (`CODE_DE = 176`, soins de longue durée) and 824 in MCO/SSR
  (Chirurgie 266, Médecine 206, Réanimation 124, SSR 115, Pédiatrie 55,
  Obstétrique 51).
  - In **USLD** (and long-stay **SSR**), `data/pmsi` (`SRC = "C"` from CORA and
    `SRC = "DW"`) already contains movement rows for all hospital fields (MCO,
    SSR with 60 526 patient-days in 2024, PSY with 1 092, and USLD with 12 689;
    see `denominator.md`). Across all 927 USLD samples in raw `data/bact22_24`
    (from which the 632 diagnostic antibiogram isolates in the v3 bundle
    derive), interval attribution failed not because USLD was excluded by
    sector, but because the historical extraction filtered on entry date
    `DATENT >= 2022-01-01` (dropping long-stay residents admitted prior to
    2022, which accounts for 624 of the 927 raw USLD samples) and because
    residents still in bed at extraction have an open exit timestamp
    (`DATSORT = NA`, 118 of the remaining 303 matched raw USLD samples). Under
    `04-donnees-activite.md`, the site adapter caps genuinely ongoing
    `CODE_TA ∈ {03, 20}` stays at $\min(T_{\text{end}}, T_{\text{extraction}})$
    when preparing the handoff, while the core never invents end dates on
    remaining `DATSORT = NA` rows.
  - In **acute MCO**, these are predominantly pre-admission samplings (e.g.
    sample taken at 08:30 in the ED before inpatient movement registration opens
    at 15:10).

Falling back unconditionally to the laboratory ordering UF (Option B) adds 110
deduplicated *E. coli* isolates (+4.5 %) and moves céfotaxime by +1.02 pp, but
injects isolates whose stays are absent from the movement interval denominator
(or pre-admission hours prior to ward entry). Under decision 04.7, the
perimeter is one object handed to both numerator and denominator. Admitting
isolates whose hospital days are absent produces an incidence density of
nothing.

Option A (interval-based attribution, never falling back unconditionally to the
laboratory ordering UF for inpatient perimeters) is therefore retained across
the three named perimeters:
1. **`spares_strict`** retains only samples collected inside an active
   `TA 03/20` movement interval.
2. **`spares_ed24h`** adds diagnostic samples collected in the Emergency
   Department (`TA 10`) that are followed within a bounded 24-hour look-ahead
   window by an inpatient admission (`TA 03/20`), attributing them to the
   initial receiving inpatient UF (`ADR-0009`).
3. **`emergency_ta10`** retains all diagnostic samples from the Emergency
   Department (`TA 10`) in a dedicated perimeter deduplicated on its own.

**Period end.** The 24-hour look-ahead stops at the end of the surveillance
period. A `TA 10` sample drawn in the last 24 hours of the period whose
admission starts after the period end is not linked: it stays out of
`spares_ed24h` and still enters `emergency_ta10`. Its sample date is never
moved into the next period, and movements after the period end are not
extracted to look for its admission. v3 accepts this blind spot (about one day
in 365 for an annual run) and reports the number of `TA 10` diagnostic samples
drawn in the last 24 hours of the period, so its size is visible. If runs ever
extract each month separately, the blind spot recurs at every month end and
this rule is to be revisited.

### 05.2 note — structure coverage

The pre-flight audit reports unit codes matched and unmatched to the annual
structure and the counts and proportions of affected records (`00-audit-qualite.md`).
No audit coverage threshold is set. Decision 03.5 owns population selection.

### 05.3 note — specialised intensive care is a nomenclature mapping, not an algorithm

SPARES requires specialised intensive care and continuous monitoring to be
attributed to medicine, surgery, or paediatrics (SPARES p. 10). This requirement does not
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

- **Rouen site adapter (Phase B): CORA movement extraction and ongoing inpatient
  stays.** In Rouen's CORA database (`TB_SEJOUR` + `TB_MVT`, accessed via
  `d2imr` / `redsan` as documented in `chu-data-knowledge`),
  `TRIM(TB_MVT.ID_UNITE_M)` matches the `Code UF` of the establishment
  structure file at 99.9 % and covers MCO, SSR, PSY and USLD. To capture
  long-stay USLD and SSR residents admitted before the start of the extraction
  window, the Rouen adapter query must select movements by interval intersection
  (`DATE_DEBUT_MVT < period_end` and `(DATE_FIN_MVT > period_start OR
  DATE_FIN_MVT IS NULL)`) rather than `DATENT >= period_start`, applying the
  standard CORA filters (`STATUT_PROG != 'P'` and `DATE_ENTREE < TRUNC(SYSDATE)
  + 1`), and cap genuinely ongoing inpatient stays (`CODE_TA ∈ {03, 20}`) at
  $\min(T_{\text{end}}, T_{\text{extraction}})$ while leaving unclosed
  outpatient/ED administrative anomalies (`TA 07`, `TA 10`) as `NA`. The
  query stops at `period_end` by design: emergency samples drawn in the last
  24 hours of the period are not linked to a later admission (see Period end
  above).
- **Rouen site adapter (Phase B): mapping audit of unclassified UFs.** 6 UFs in
  Rouen's referential remain unclassified (2 with TA 03/20 and no DE: 5947,
  8947; 4 absent from structure: 570A, 572A, 6420, 7116), to be rechecked
  against the updated structure file.
- **Rouen site adapter (Phase B): sample-type mapping (`NATUREPVT`).** Local
  categorisation of Rouen's `NATUREPVT` labels (8 462 distinct labels among
  samples with an antibiogram) into the ONERBA thesaurus categories belongs to
  the Rouen site adapter (`ADR-0003`). Under decision 03.6, mapping is required
  only for values that reach an indicator.
