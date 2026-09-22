# 00 - Pre-flight data quality and coherence audit

Status: **method decisions settled**. Eight decisions, eight witnesses, three tripwires, zero unproven. One follow-up is listed under Open.

---

## What SPARES says

> L'analyse des données est assurée par la mission nationale SPARES. Elle comprend,
> en premier lieu, un contrôle de cohérence/vraisemblance de l'ensemble de la base
> de données avec possibilité de contacter les ES en cas de besoin. (Page 16, §1)

> Il est indispensable de s'assurer de la cohérence stricte entre la codification
> des UF utilisée par l'administration, la pharmacie et le laboratoire afin de
> relier ces informations entre elles lors de l'analyse des résultats. (Page 12)

> Note Xa : En l'absence de mention d'un phénotype de résistance BLSE ou
> carbapénémase, celui-ci est considéré comme négatif. (Page 16, §1)

---

## What SPF asks

SPF requires aggregated indicators with complete auditability of numerators and
denominators:

> nous souhaiterions recevoir, pour tous les indicateurs agrégés demandés, le
> numérateur et dénominateur utilisés (le nombre de souches avec une résistance, le
> nombre de souches testés, le nombre total de JH).

Data quality and plausibility cannot remain an unrecorded manual step or an informal
exchange between the national mission and an establishment. In ORCHIDEE, data
quality must be proven automatically and transparently before any population selection,
exposure calculation, or deduplication takes place.

---

## What ORCHIDEE does

ORCHIDEE operationalizes SPARES Page 16 §1 by introducing an **upfront, automated
pre-flight data quality and coherence audit**. This audit runs as an automated gate
immediately upon ingestion of the **site handoff**, before any data reaches population
selection, exposure calculation, or deduplication.

The pre-flight audit inspects six core domains:

```
Section 00 Pre-Flight Audit Gate
├── Suite 1: Relational Integrity & Composite Key Enclosure
│   ├── Test 1.1: Check for stay IDs used by multiple patients (PATID + EVTID)
│   ├── Test 1.2: Check for sample IDs used by multiple patients (PATID + ELTID + souche_id)
│   └── Test 1.3: PMSI Referential Coverage (flags orphaned laboratory stays missing from PMSI)
│
├── Suite 2: Demographic Invariant Plausibility
│   ├── Test 2.1: Intra-patient Sex Stability (expects 100 % stability; flags clerical toggles)
│   ├── Test 2.2: Cross-system Sex Concordance (PMSI vs Laboratory; expects >= 99.9 %)
│   ├── Test 2.3: Birth Date Mutation Audit (flags default dates e.g. 01/01 vs 31/12)
│   └── Test 2.4: Age Range Bounding (0 <= PATAGE <= 120; flags dummy test records)
│
├── Suite 3: Temporal Containment & Chronology
│   ├── Test 3.1: Physical Interval Validity (DATENT <= DATSORT; quarantines negative durations)
│   ├── Test 3.2: Sampling Stay Containment (expects >= 98 % within [DATENT, DATSORT])
│   ├── Test 3.3: Report sample lags outside stays; ≥48 h pre-admission is suspicious, >30 d is report-only
│   └── Test 3.4: Count admission/discharge times at 00:00:00 and with a non-midnight time (TW-04.2)
│
├── Suite 4: Structural & Referential Coverage
│   ├── Test 4.1: Referential Linkage Tolerance (TW-05.1; >= 99.9 % active UFs in structure)
│   └── Test 4.2: Positive Perimeter Exclusion Ledger (logs unmapped UFs in divergence account)
│
├── Suite 5: Intrinsic & Phenotypic Microbiological Plausibility
│   ├── Test 5.1: Intrinsic Microbiological Resistances (flags impossible susceptible phenotypes)
│   ├── Test 5.2: Phenotype–AST Plausibility (TW-06.1; flags C3G-S with BLSE-positive)
│   ├── Test 5.3: CA-SFM Standard Version Referential (TW-06.2; asserts CASFM >= 2020)
│   └── Test 5.4: AST Duplicate Resolution Audit (verifies deterministic pivot rule)
│
└── Suite 6: Descriptive Profiling & Redundancy Statistics
    ├── Test 6.1: Global Entity Volumes (counts of distinct PATID, EVTID, ELTID, isolates)
    ├── Test 6.2: Deduplication Redundancy Profiling (distribution of isolates per patient)
    ├── Test 6.3: Target Pathogen Redundancy Hierarchy (species-specific repeat culture rates)
    └── Test 6.4: Polymicrobial Rate Profiling (specimens yielding multiple target taxa)
```

---

### 1. Relational Integrity and Composite Key Enclosure

In raw hospital databases, identifiers that appear unique within an application are frequently
recycled over time:

- **Stay identifier (`EVTID`) recycling**: In administrative PMSI movements, 169 out of
  194 566 distinct `EVTID`s (0.087 %) are associated with multiple `PATID`s across calendar years.
  Crucially, 35 multi-patient `EVTID`s occur within the exact same administrative source file
  (`SRC == "C"`), demonstrating that hospital information systems recycle stay numbers.
  **Rule**: Stays are strictly composite-keyed as `(PATID, EVTID)`.
- **Sample accession (`ELTID`) recycling**: In routine laboratory data (`bact22_24`), 135
  `ELTID`s occur across multiple patients. Empirical analysis reveals that 94.8 % of these
  collisions occur $> 30$ days apart (median: 319 days, maximum: 2.8 years). `ELTID` is a cyclical
  accession counter in the laboratory system (GLIMS), not an immutable UUID.
  **Rule**: The primary isolate key is strictly composite: `(PATID, ELTID, souche_id)`
  (Decision 06.3), ensuring 100 % global uniqueness (48 595 / 48 595 in `sir_wide.rds`).

---

### 2. Demographic Invariant Plausibility

Patient demographic fields must be stable across surveillance encounters:

- **Sex stability (`PATSEX`)**: Evaluated for every `PATID`. In raw bacteriology, exactly 0 patients
  change sex (100 % stable across 107 049 patients). In PMSI movements, only 13 out of 106 491
  patients (0.012 %) have multiple recorded sexes: 7 undetermined toggles (`F / I`), and 6 clerical
  corrections (`F / M`). Across both databases, concordance is 99.97 % (106 278 / 106 311 patients).
- **Date of birth stability (`PATBD`)**: In PMSI movements, 38 patients (0.036 %) have multiple birth
  dates, primarily caused by default calendar assignments (e.g. `1991-01-01` vs `1991-12-31` when
  birth year is known but day/month is unrecorded).
- **Age range plausibility (`PATAGE`)**: Ages must satisfy $0 \le \text{age} \le 120$. In Rouen
  PMSI movements, ages span 0.0 to 106.0 years with 0 outliers. In raw bacteriology, exactly 4 rows
  carried `PATAGE == 136` (dummy test records or anonymization artifacts), which are flagged and
  quarantined by the audit.

---

### 3. Temporal Containment and Chronology

- **Chronological interval validity**: Movement records must satisfy `DATENT <= DATSORT`.
  Negative stay durations (`DATSORT < DATENT`) are quarantined from exposure calculations
  (Decision 00.3).
- **Sample timing relative to linked stays**: Report how far sample collection falls before admission
  or after discharge. On Rouen surveillance data (`sir_wide.rds` linked to PMSI):
  - **45 927 isolates (98.56 %)** are strictly contained within the stay (`DATENT <= DATEPRELEV <= DATSORT`).
  - **185 isolates (0.40 %)** were sampled *before* admission (`DATEPRELEV < DATENT`), with a median
    lag of 4 days (pre-admission emergency department testing or pre-operative outpatient consultations).
  - **485 isolates (1.04 %)** were sampled *after* discharge (`DATEPRELEV > DATSORT`), with a median
    lag of 14 days (post-discharge surgical wound follow-up).
  - Lags of more than 30 days before admission or after discharge are reported only; they do not
    by themselves change isolate eligibility.
  - Pre-admission lags of 48 hours or more are reported as suspicious. Their relationship to the
    Emergency linkage decision is tracked under Open in `05-structure.md`.
- **Admission and discharge time detail (`TW-04.2`)**: Count `DATENT` and `DATSORT` values at
  exactly `00:00:00` and values with a non-midnight time. Compare the midnight share with the site's
  declared format (`date` or `datetime`).
  The mathematical definition of occupancy hours and its algebraic reduction to midnight presence
  on date-only data belongs strictly to `04-donnees-activite.md` (Decisions 04.2 and 04.9).
  When the site declares `datetime`, a high midnight share may indicate times replaced by the
  `00:00:00` default. The check counts those values and flags the overall pattern; the timestamp alone
  cannot distinguish a real midnight from a default. The operational verification check is:
  - Declared `datetime`: expects $p_{00} \le 10\,\%$ (Rouen: 4.11 % of `DATENT`, 4.08 % of `DATSORT`).
  - Declared `date`: expects $p_{00} \ge 95\,\%$.
  - Intermediate ($10\,\% < p_{00} < 95\,\%$): **blocking refusal** to prevent intra-hospital exposure bias.

---

### 4. Structural and Referential Coverage

The establishment structure is ingested as a frozen annual snapshot `unit_mapping` (Decision 05.4):
- **Administrative completeness**: 100 % of administrative UFs with hospitalisation activity
  must resolve in the structure referential (`CODE_TA`, `CODE_DE`, `de_domain_ref`).
- **Microbiology completeness (`TW-05.1`)**: $\ge 99.9\,\%$ of microbiology observations must
  resolve to known UFs in the structure snapshot.
- **Positive perimeter**: In accordance with Decision 03.5, the perimeter is defined positively.
  Unmapped UFs are excluded by design and logged in the quality ledger, preventing unknown units
  from entering surveillance by omission.

---

### 5. Intrinsic and Phenotypic Microbiological Plausibility

- **Intrinsic microbiological resistances**: Under EUCAST / CA-SFM guidelines, certain bacterial
  species possess universal chromosomal resistance mechanisms. An isolate reported as susceptible
  (`S`) to an intrinsically resistant molecule indicates clerical error or taxonomic misidentification.
  The pre-flight audit validates incoming isolates against the intrinsic resistance matrix:
  - ***Klebsiella pneumoniae***: intrinsically resistant to **Ampicillin / Amoxicillin**.
  - ***Enterobacter cloacae complex***: intrinsically resistant to **Amoxicillin-clavulanate**.
  - ***Proteus mirabilis***: intrinsically resistant to **Colistin**.
  - ***Pseudomonas aeruginosa***: intrinsically resistant to **Ampicillin, Amox-clav, Cefotaxime, Ceftriaxone, Ertapenem, Trimethoprim-sulfamethoxazole**.
- **Phenotype–AST concordance (`TW-06.1`)**: Positive resistance phenotypes must be biologically
  supported by underlying AST measurements. An isolate marked `blse = TRUE` must show resistance (`R`)
  or decreased susceptibility (`SFP`) to at least one 3rd/4th generation cephalosporin.
- **AST duplicate resolution audit**: When the same isolate is tested multiple times against the
  same antibiotic, the audit verifies that the site adapter's pivot engine resolves duplicates
  deterministically via the documented last-row order rule (`vals[[length(vals)]]` in `external_handoff_helpers.R`).

---

### 6. Descriptive Profiling and Deduplication Redundancy Statistics

The pre-flight audit generates a comprehensive descriptive profile of the site handoff:

#### Global Entity Volumes (Rouen 2022–2024 Baseline)

| Entity Level | Raw Bacteriology (`bact22_24`) | PMSI Movements (`pmsi$main`) | Handoff Observations | Surveillance Isolates (`sir_wide.rds`) |
|---|---|---|---|---|
| **Total Rows** | 5 154 206 | 442 183 | 679 101 | 48 595 |
| **Distinct `PATID`** | 107 049 | 106 491 | 23 763 | 23 072 |
| **Distinct `EVTID`** | 196 066 non-NA (262 NA) | 194 566 | 33 406 | 32 399 |
| **Distinct `ELTID`** | 507 416 | 442 183 (movement rows) | 44 767 | 41 951 |
| **Distinct `souche_id`** | — | — | 7 | 7 |

#### Deduplication Redundancy Profiling (Within-Species Partition)

Deduplication never operates across different bacterial species (*E. coli* is never deduplicated
against *K. pneumoniae*). The deduplication universe is strictly partitioned by **`(PATID, species)`**
(and specimen scope).

Across the 3-year surveillance extract (`sir_wide.rds`, $N = 48\,595$ isolates entering deduplication,
$N = 23\,072$ unique patients, representing **$33\,017$ distinct `(PATID, species)` episodes**):
- **Episodes with exactly 1 isolate**: **24 810 (75.14 %)** of `(PATID, species)` pairs have zero duplicate candidates.
- **Episodes with repeat isolates ($\ge 2$)**: **8 207 (24.86 %)** of `(PATID, species)` pairs undergo deduplication.
- **Isolates entering repeat episodes**: **23 785 (48.95 %)** of all surveillance isolates.
- **True Within-Species Redundancy Ratio** $\frac{\text{Isolates} - (\text{PATID, species})}{\text{Isolates}}$:
  - **32.06 %** over the 3-year surveillance window (48 595 isolates $\to$ 33 017 unique episodes).
  - **26.54 %** in 2024 alone (16 545 isolates $\to$ 12 154 unique episodes; 77.88 % single, 22.12 % repeat).
  - **23.83 %** in 2024 Blood Cultures alone (2 069 isolates $\to$ 1 576 unique episodes; 78.55 % single, 21.45 % repeat).

```
Distribution of Isolates per (PATID, Species) Episode (N = 33 017 episodes, 48 595 isolates):
  1 isolate  : [████████████████████████████████████] 75.1 % (24 810 episodes -> 24 810 isolates)
  2 isolates : [████████]                             15.1 % ( 4 985 episodes ->  9 970 isolates)
  3 isolates : [███]                                   5.0 % ( 1 661 episodes ->  4 983 isolates)
  4 isolates : [█]                                     2.1 % (   701 episodes ->  2 804 isolates)
  5 isolates : [ ]                                     1.0 % (   326 episodes ->  1 630 isolates)
  6-9 isolates: [█]                                    1.2 % (   407 episodes ->  2 813 isolates)
  10+ isolates: [ ]                                    0.4 % (   127 episodes ->  1 585 isolates)
```

*(Note on cross-species multi-infection: Across all species combined, 40.83 % of patients have $\ge 2$ total isolates of any organism, demonstrating frequent polymicrobial infection or sequential hospitalizations across distinct infectious episodes, but these isolates never compete in deduplication).*

#### Target Pathogen Redundancy Hierarchy (2024 Alone)

| Target Pathogen (`bact_norm`) | Total Isolates (2024) | Distinct Patients | Mean Isolates / Patient | Repeat Patients (%) | Redundancy Ratio (%) |
|---|---|---|---|---|---|
| ***Pseudomonas aeruginosa*** | 1 223 | 785 | **1.56** | **29.6 %** | **35.8 %** |
| ***Klebsiella pneumoniae*** | 1 201 | 803 | **1.50** | **26.3 %** | **33.1 %** |
| ***Enterobacter cloacae complex*** | 743 | 503 | **1.48** | **27.8 %** | **32.3 %** |
| ***Staphylococcus aureus*** | 2 461 | 1 749 | **1.41** | **25.5 %** | **28.9 %** |
| ***Enterococcus faecium*** | 482 | 352 | **1.37** | **20.2 %** | **27.0 %** |
| ***Escherichia coli*** | 6 519 | 4 839 | **1.35** | **21.9 %** | **25.8 %** |
| ***Proteus mirabilis*** | 781 | 609 | **1.28** | **19.5 %** | **22.0 %** |
| ***Enterococcus faecalis*** | 1 092 | 878 | **1.24** | **16.2 %** | **19.6 %** |

*Epidemiological Insight*: *P. aeruginosa* exhibits the highest redundancy (35.8 %), reflecting
chronic colonization and intensive repeat culturing in ICUs and pulmonology. Conversely,
*E. faecalis* and *E. coli* show the lowest redundancy (~20–25 %), representing acute urinary
episodes with fewer repeat samples.

#### Polymicrobial Rate Profiling

- In raw bacteriology (`bact22_24`): **36.86 % of samples** (39 013 / 105 836) are polymicrobial
  ($\ge 2$ distinct species).
- In surveillance targets (`sir_wide.rds`): **13.53 % of sample containers** (5 677 / 41 951)
  yield $\ge 2$ distinct surveillance target species.

---

## Decisions

All witnesses measured on Rouen 2022–2024 raw data (`data/pmsi`, `data/bact22_24`, `bundle_v3/sir_wide.rds`).

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 00.1 | Pre-flight isolation gate | Automated, upfront pre-flight audit executed at ingestion before population selection | Informal, manual, or post-hoc sanity checks | 100 % of checks automated and logged; prevents silent data corruption before deduplication |
| 00.2 | Relational composite key enclosure | Composite keys `(PATID, EVTID)` and `(PATID, ELTID, souche_id)` | Single-column keys `EVTID` or `ELTID` | In PMSI, 169 `EVTID`s span multiple patients (35 within same source file); in lab, 135 `ELTID`s recycled across patients (up to 2.8 years apart) |
| 00.3 | Movement interval physical integrity | Assert `DATENT <= DATSORT`; negative stay durations quarantined from exposure | Silently accept negative stays or compute erroneous negative days | Rouen 2022–2024: 80 of 442 183 raw movement rows (0.018 %) have `DATENT > DATSORT` (down to -27 days) and are quarantined; 24 437 unclosed stays (`DATSORT == NA`) |
| 00.4 | Denominator grain verification | Operational threshold check on `00:00:00` timestamps; rejects intermediate distributions (TW-04.2) | Silently accept mixed temporal resolutions | Rouen has **4.11 %** `DATENT` and **4.08 %** `DATSORT` at 00:00 (clean `datetime`); method defined in `04-donnees-activite.md` (Decision 04.9) |
| 00.5 | Structure referential link check | Positive perimeter with non-blocking tripwire asserting $\ge 99.9\,\%$ microbiology resolution (TW-05.1) | Blocking pipeline failure on any unmapped code | Admin 362/362 (100 %); lab 272/278 UFs in structure (6 external referral UFs, 68 raw rows, 0 in `sir_wide.rds`) |
| 00.6 | Intrinsic resistance violations | Quarantined and logged in audit ledger; excluded from indicator numerator | Silently admitted or unverified | In 2024 raw extract, 1 *K. pneumoniae* reported S to ampicillin (outpatient ELTID 376198529, quarantined); 0 violations in eligible hospitalisation perimeter (604/604 R) |
| 00.7 | Phenotype-AST plausibility | Assert biological concordance; absent test = `FALSE` kept in species denominator (Note Xa) (TW-06.1) | Restrict denominator to explicit test rows | Under Note Xa, *E. coli* BLSE is **7.61 %** (186/2 445); restricting to explicit tests yields distorted **83.04 %** (186/224) |
| 00.8 | Pre-flight descriptive profiling | Export comprehensive descriptive profile and divergence ledger (`audit_qualite.rds`) | Omit ingestion profiling | Quantifies true within-species redundancy (32.1 % 3-year ratio; 24.9 % repeat episodes; 26.5 % in 2024) and polymicrobial rates (13.5 % target samples) |

Unproven: **0 of 8**.

---

## Notes & Tripwires

### 00.2 note — stay and accession number recycling in hospital IT systems

In French hospital IT infrastructure, stay numbers (`EVTID` / NDA) and laboratory sample numbers
(`ELTID` / numéro d'échantillon) are generated by independent software systems (CPAGE / Crossway for
PMSI movements, GLIMS for microbiology):
- `EVTID` recycling: 169 stays in Rouen's PMSI history belong to $>1$ patient. 35 occur within the
  same extract source (`SRC == "C"`), showing that hospital registration software recycles numbers
  over multi-year periods.
- `ELTID` recycling: 135 `ELTID`s in `bact22_24` belong to $>1$ patient. Temporal analysis proves
  these are not data collisions: 94.8 % occurred $> 30$ days apart (median 319 days, max 1 038 days),
  demonstrating that GLIMS uses a cyclical accession counter.

Treating `EVTID` or `ELTID` as globally unique identifiers would cross-contaminate patient records.
ORCHIDEE strictly enforces composite keys:
$$\text{Stay Key} = (\text{PATID}, \text{EVTID})$$
$$\text{Isolate Key} = (\text{PATID}, \text{ELTID}, \text{souche\_id})$$

### 00.3 note — chronological interval anomalies and quarantine in PMSI data

In raw hospital administrative data, movements with inverted dates (`DATSORT < DATENT`) arise from
clerical data entry mistakes, emergency ward transfer back-dating, or system synchronization lag.

On Rouen 2022–2024 raw PMSI movements (442 183 rows), the audit identified:
- **80 rows** with `DATSORT < DATENT` (negative durations ranging from -0.03 days to -27.0 days).
  All 80 belong to source `SRC == "C"`.
- **24 437 rows** with `DATSORT == NA` representing unclosed stays (`PMSISTATUT == "E"`, ongoing stays).

Allowing negative durations into exposure calculations would subtract patient-days from unit
denominators, corrupting incidence densities. The pre-flight audit isolates inverted movements
into a quarantine ledger, allowing clean closed intervals (417 666 valid movements) to enter
the geometric interval union (Decision 04.5).

### 00.4 tripwire (TW-04.2) — operational timestamp grain verification

The operational verification check for `TW-04.2` inspects the empirical share of timestamps
sitting at `00:00:00`:
- **Statement**: Observed timestamp distribution matches the site's declared resolution.
- **Rule**: $p_{00} \le 10\,\%$ for `datetime`, $p_{00} \ge 95\,\%$ for `date`. Intermediate
  proportions trigger a blocking refusal.
- **Methodology Reference**: The mathematical equivalence of hours and midnights on date-only
  data is specified in `04-donnees-activite.md` (Decision 04.9).

### 00.5 tripwire (TW-05.1) — structural referential coverage

Asserts that $\ge 99.9\,\%$ of active administrative UFs and microbiology orders resolve in the
frozen structure snapshot `unit_mapping` (Decision 05.2).

### 00.7 tripwire (TW-06.1) — phenotype–AST biological plausibility

Asserts that positive resistance phenotypes (BLSE, Carbapenemase) are biologically concordant with
underlying AST measurements. Flags isolates where C3G is fully sensitive (`S`) but `blse == TRUE`,
or carbapenems fully sensitive (`S`) but `carbapenemase == TRUE`.

### 00.8 note — clinical significance of deduplication redundancy profiling

Measuring deduplication redundancy at ingestion provides vital clinical and operational context:
- In acute urinary tract infections (*E. coli*, *E. faecalis*), redundancy is low (~20–25 %),
  meaning most isolates represent independent primary infectious episodes.
- In intensive care and chronic respiratory pathogens (*P. aeruginosa*, *K. pneumoniae*),
  redundancy reaches 33–36 %, reflecting prolonged colonization, treatment monitoring, and
  frequent repeat sampling.
- Within the true deduplication partition `(PATID, species)`, **24.86 % of episodes contain repeat
  isolates**, representing **48.95 % of all surveillance isolates**. The consolidated within-species
  redundancy ratio is **32.06 %** over 3 years and **26.54 %** in 2024, confirming why deduplication
  rules and window definitions govern published AMR rates. Deduplication collapses these repeat isolates
  to retain one representative isolate per deduplication episode.

## Open

- **Action following a quality finding.** In a separate discussion, specify and trace what happens
  after each check finds a problem, including when the outcome is report-only. Keep each action with
  its owning check or tripwire entry; this note is the follow-up marker, not a parallel action register.
