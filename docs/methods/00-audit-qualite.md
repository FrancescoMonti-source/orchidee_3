# 00 - Pre-flight data quality and coherence audit

Status: **Suites 1–5 recovered from the reviewed checkpoint; Suite 6 pending**.
The audit documents and flags findings without automatic action or acceptance
thresholds. This is a method specification; its executable common audit has not
been implemented or remeasured by this recovery.

---

## What SPARES says

> L'analyse des données est assurée par la mission nationale SPARES. Elle comprend,
> en premier lieu, un contrôle de cohérence/vraisemblance de l'ensemble de la base
> de données avec possibilité de contacter les ES en cas de besoin. (Page 16, §1)

> Il est indispensable de s'assurer de la cohérence stricte entre la codification
> des UF utilisée par l'administration, la pharmacie et le laboratoire afin de
> relier ces informations entre elles lors de l'analyse des résultats. (Page 12)

> les phénotypes de résistance BLSE et carbapénémase des Enterobacterales et Pseudomonas
> doivent être renseignés en cas de positivité et après vérification. Une case vide est
> considérée comme une absence de phénotype de résistance (et non comme une donnée
> manquante). (p. 31)

---

## What SPF asks

SPF asks to receive, for every aggregated indicator, the numerator and
denominator used (SPF p. 5):

> nous souhaiterions recevoir, pour tous les indicateurs agrégés demandés, le
> numérateur et dénominateur utilisés (le nombre de souches avec une résistance, le
> nombre de souches testés, le nombre total de JH).

Data quality and plausibility cannot remain an unrecorded manual step or an informal
exchange between the national mission and an establishment. In ORCHIDEE, data
quality findings must be documented automatically and transparently before any population selection,
exposure calculation, or deduplication takes place.

---

## What ORCHIDEE does

ORCHIDEE operationalizes SPARES Page 16 §1 by introducing an **upfront, automated
pre-flight data quality and coherence audit**. This audit runs as an automated assessment
immediately upon ingestion of the **site handoff**, before any data reaches population
selection, exposure calculation, or deduplication.

The audit documents and flags findings. It does not exclude records, alter reported
results, or block processing. Population selection, exposure calculation and unit
attribution remain governed by their respective chapters; an audit flag is not an
eligibility decision.

The pre-flight audit inspects six core domains:

```
Section 00 Pre-Flight Audit
├── Suite 1: Stay and Sample Identifiers
│   ├── Test 1.1: Count distinct EVTID values associated with more than one PATID; report patients and records affected
│   ├── Test 1.2: Count distinct ELTID values associated with more than one PATID; report patients and records affected
│   └── Test 1.3: Count missing PATID, EVTID and ELTID values separately in each applicable input table
│
├── Suite 2: Recorded Demographic Values
│   ├── Test 2.1: Count patients with more than one recorded PATSEX value, separately in bacteriology and PMSI
│   ├── Test 2.2: Compare recorded PATSEX values between bacteriology and PMSI for matching patients; report agreement and disagreement
│   ├── Test 2.3: Count patients with more than one recorded birth date (PATBD)
│   ├── Test 2.4: Report the age distribution, minimum, maximum and count of negative ages
│   └── Test 2.5: Count missing PATSEX, PATBD and PATAGE values separately in each applicable input table
│
├── Suite 3: Movement Chronology and Sample Timing
│   ├── Test 3.1: Count movements with end before start or missing start/end times; report distinct stays affected
│   ├── Test 3.2: Count samples collected before, within or after their whole linked stay; report comparisons not assessable separately
│   ├── Test 3.3: Describe time differences before admission or after discharge, without timing thresholds
│   └── Test 3.4: Report declared timestamp format and midnight/non-midnight admission and discharge counts
│
├── Suite 4: Recorded Unit Codes and Structure Matches
│   ├── Test 4.1: Count distinct UF codes appearing in bacteriology and PMSI that are found or not found in the structure file, separately for each source
│   ├── Test 4.2: List UF codes not found in the structure file and count affected records
│   └── Test 4.3: Count records with missing UF values separately for each source
│
├── Suite 5: Reported Microbiology and Interpretation Standards
│   ├── Test 5.1: Count recorded S results against uppercase R rules in CA-SFM 2025 V1.1 (pp. 33-39)
│   ├── Test 5.2: Summarise positive BLSE/carbapenemase flags with no recorded S/SFP/R marker result or with all recorded marker results S
│   └── Test 5.3: Document the declared interpretation standard and raw CASFM version tags
│
└── Suite 6: Descriptive Profiling & Redundancy Statistics
    ├── Test 6.1: Global Entity Volumes (counts of distinct PATID, EVTID, ELTID, isolates)
    ├── Test 6.2: Deduplication Redundancy Profiling (distribution of isolates per patient)
    ├── Test 6.3: Target Pathogen Redundancy Hierarchy (species-specific repeat culture rates)
    └── Test 6.4: Polymicrobial Rate Profiling (specimens yielding multiple target taxa)
```

---

All numerical examples and witnesses below come from Rouen data covering
**2022–2024**. Unless a narrower period is explicitly stated (for example, 2024
alone), each figure refers to that full three-year period.

### 1. Stay and Sample Identifiers

Stay and sample identifiers are intended to be unique, but the Rouen examples show
that the same identifier can occur under different patients. The audit documents
these observations without inferring their cause.

- **Stay identifiers associated with multiple patients (Test 1.1)**: Count distinct
  `EVTID` values associated with more than one non-missing `PATID`. Report the number
  of patients and input records affected, with a detail table listing each affected
  `EVTID`, its associated patients and their record counts.
- **Sample identifiers associated with multiple patients (Test 1.2)**: Count distinct
  `ELTID` values associated with more than one non-missing `PATID`. Report the number
  of patients and input records affected, with a detail table listing each affected
  `ELTID`, its associated patients and their record counts.
- **Missing identifiers (Test 1.3)**: Report simple missing-value counts for `PATID`,
  `EVTID` and `ELTID` separately in each input table that carries the field. Missing
  identifiers are reported separately from identifiers associated with multiple
  patients; they are not treated as an additional patient or identifier.

The audit does not construct, repair or deduplicate isolates. Multiple antibiotic-result
rows belonging to one isolate are expected and are not counted as duplicate isolates.
The composite keys remain the identification rule defined in ADR-0007: `(PATID, EVTID)`
for stays and `(PATID, ELTID, souche_id)` for isolates (Decision 06.3).

**Rouen examples:**

- In administrative PMSI movements, 169 out of 194 566 distinct `EVTID`s (0.087 %)
  are associated with multiple `PATID`s, including 35 within the same administrative
  source file (`SRC == "C"`).
- In routine laboratory data (`bact22_24`), 135 `ELTID`s occur under multiple
  patients. Of these observed cross-patient occurrences, 94.8 % are more than 30 days
  apart (median: 319 days, maximum: 2.8 years).

These findings establish that `EVTID` and `ELTID` cannot safely be treated as globally
unique on their own. Their temporal separation does not establish the cause of reuse.

---

### 2. Recorded Demographic Values

The audit documents recorded demographic values and their differences. It sets no
agreement threshold and does not correct values, exclude records or require an action
following a finding. Differences alone do not establish their cause.

- **Multiple recorded sex values (Test 2.1)**: Count patients with more than one
  distinct non-missing `PATSEX` value, separately in bacteriology and PMSI. Report
  the patient counts and a detail table of their recorded values and record counts.
- **Sex values across systems (Test 2.2)**: Compare patients with a non-missing
  `PATID` present in both bacteriology and PMSI. Among patients with exactly one
  distinct non-missing `PATSEX` value in each system, report agreement and
  disagreement counts; any agreement proportion uses only these comparable patients
  as its denominator. Separately report patients with multiple recorded values in
  either system and patients with no recorded value in either or both systems.
  Include the differing values in the detail table without choosing or replacing a
  patient's recorded value.
- **Multiple recorded birth dates (Test 2.3)**: Count patients with more than one
  distinct non-missing `PATBD` value, separately in each input table carrying the
  field. Report the patient counts and a detail table of their recorded dates and
  record counts. Do not infer that a date was a default or a correction.
- **Recorded ages (Test 2.4)**: Report the distribution, minimum and maximum of
  non-missing `PATAGE` values and the number of records with a negative age,
  separately in each input table carrying the field. No upper-age cutoff is set.
  Unusual recorded ages do not establish that a record is a test or anonymisation
  artifact.
- **Missing demographic values (Test 2.5)**: Report simple missing-value counts for
  `PATSEX`, `PATBD` and `PATAGE` separately in each input table carrying the field.
  Missing values do not count as an additional sex value or birth date. Patient-level
  checks use non-missing `PATID`; missing patient identifiers are counted in Suite 1.

**Rouen examples:**

- In raw bacteriology, 0 of 107 049 patients have multiple recorded sex values.
  In PMSI movements, 13 of 106 491 patients (0.012 %) have multiple recorded values:
  7 have `F / I` and 6 have `F / M`.
- The historical cross-system comparison reported agreement for 106 278 of 106 311
  patients (99.97 %). Its denominator construction is not documented here; this is
  a historical example, not an acceptance threshold or a specification of Test 2.2.
- In PMSI movements, 38 patients (0.036 %) have multiple recorded birth dates,
  including `1991-01-01` and `1991-12-31` for the same patient.
- Recorded ages in PMSI movements span 0.0 to 106.0 years. In raw bacteriology,
  4 rows carry `PATAGE == 136`. These examples do not establish the origin of those
  values.

---

### 3. Movement Chronology and Sample Timing

The audit documents movement chronology and sample timing. It does not correct
intervals, fill missing timestamps, exclude records or set timing thresholds.

- **Movement chronology and missing timestamps (Test 3.1)**: Count movement rows
  with `DATSORT < DATENT`, missing `DATENT`, and missing `DATSORT` separately.
  For each finding, report the movement-row count and distinct `(PATID, EVTID)`
  stay count. Also count records with a missing sample collection time.
- **Sample timing relative to the whole linked stay (Test 3.2)**: Group movements
  by `(PATID, EVTID)`. The whole-stay boundaries are `min(DATENT)` and
  `max(DATSORT)` when admission and final discharge can be established from the
  recorded movements. Compare the sample collection time with those boundaries,
  rather than with an individual unit movement. Report samples before admission,
  within the stay (including its recorded boundaries), and after discharge.
  Report the counts and proportions among assessable comparisons, with their
  denominator, and a detail table of samples outside the stay.

  If the final movement has no `DATSORT`, the whole-stay discharge is unavailable:
  do not substitute an earlier movement's exit using `max(DATSORT, na.rm = TRUE)`.
  Report the affected stays separately. Comparisons with a missing sample time,
  unavailable whole-stay boundary, or a whole-stay end before its start are
  reported as not assessable. Missing movement start times may prevent identifying
  the first or final movement; do not infer the missing timestamps. These reporting
  categories do not change record eligibility. Unit attribution remains governed
  by `05-structure.md`.
- **Time differences outside the stay (Test 3.3)**: For assessable comparisons,
  describe the distribution of time from sampling to admission for samples collected
  before the stay, and from discharge to sampling for samples collected after it.
  State the time unit. No 48-hour or 30-day threshold is set, and timing alone does
  not establish the clinical reason for sampling.
- **Timestamp format and midnight values (Test 3.4)**: Report the site's declared
  format (`date` or `datetime`). Count `DATENT` and `DATSORT` values at exactly
  `00:00:00`, non-midnight values and missing values separately. Report midnight
  shares among non-missing values for each field, by unit and period and for the
  whole site. A midnight timestamp alone cannot distinguish a real midnight from
  a default. No acceptance threshold is set. Exposure calculation belongs to
  `04-donnees-activite.md` (Decisions 04.2 and 04.9).

**Rouen examples:**

- Among surveillance isolates linked to PMSI, the historical comparison reported
  45 927 isolates within the stay (98.56 %), 185 before admission (0.40 %, median
  time difference: 4 days), and 485 after discharge (1.04 %, median time difference:
  14 days). These are descriptive examples; they do not establish why samples
  were taken or demonstrate the whole-stay calculation specified above.
- The historical timestamp profile reported 4.11 % of `DATENT` and 4.08 % of
  `DATSORT` at midnight. These figures are examples, not acceptance thresholds.

---

### 4. Recorded Unit Codes and Structure Matches

The site supplies the annual structure file `unit_mapping` (Decision 05.4).
The comparison runs from UF codes appearing in bacteriology and PMSI to this
file. UFs appearing only in the structure file are outside this check.

- **UF codes found or not found in the structure file (Test 4.1)**: For each period,
  compare distinct non-missing UF codes appearing in the supplied records with the
  corresponding annual structure. Report matched and unmatched distinct-code
  counts and the record counts affected, separately for PMSI movement UFs and
  laboratory ordering UFs. Any matched-code proportion uses the distinct
  non-missing codes appearing in that source and period as its denominator.
- **Detail of unmatched UF codes (Test 4.2)**: List each recorded UF code not found
  in the structure file, its source and period, and its affected record count.
- **Missing UF values (Test 4.3)**: Count records with a missing UF value,
  separately for each source and period. Report these separately from populated
  codes not found in the structure file.

The laboratory ordering UF is distinct from the hospitalisation unit attributed
at sampling time in `05-structure.md`. The audit documents structure matches;
no coverage threshold, correction or exclusion follows from this check.
Population selection remains governed by Decision 03.5.

**Rouen example:** Of the distinct codes appearing in the records, 362 of 362
administrative UFs and 272 of 278 laboratory ordering UFs appear in the structure
file. The six unmatched laboratory UFs affect 68 raw records. UFs appearing only
in the structure file are not included in these denominators.

---

### 5. Reported Microbiology and Interpretation Standards

- **Susceptible results against the natural resistance reference (Test 5.1)**:
  Count recorded `S` results for organism-antibiotic combinations designated
  uppercase `R` in CA-SFM 2025 V1.1, Section 2, pp. 33-39, respecting the
  group-level rules, species-specific rules and footnote exceptions. Report counts
  by organism and antibiotic. Lowercase `r` denotes low-level natural resistance
  that does not automatically require an `R` interpretation; do not include it
  in this comparison as though it were uppercase `R` (CA-SFM 2025 V1.1, p. 33).
  Retain recorded results without correction or exclusion. A finding does not
  establish a clerical error or taxonomic misidentification. For the 2022-2024
  examples, this is a comparison against the 2025 reference, not a claim that
  the laboratory breached the interpretation rules applicable at the time.
  The following examples illustrate the rule rather than define its full scope
  (CA-SFM 2025 V1.1, pp. 33-35):
  - ***Klebsiella pneumoniae***: **Ampicillin / Amoxicillin**.
  - ***Enterobacter cloacae complex***: **Amoxicillin-clavulanate**.
  - ***Proteus mirabilis***: **Colistin**.
  - ***Pseudomonas aeruginosa***: **Ampicillin, Amox-clav, Cefotaxime, Ceftriaxone, Ertapenem, Trimethoprim-sulfamethoxazole**.
- **Positive phenotype flags and recorded marker results (Test 5.2)**: For each
  species, phenotype and year, report two summary counts and percentages:
  1. Positive BLSE or carbapenemase flags with no recorded `S`, `SFP` or `R` result
     for any antibiotic in the applicable audit panel. The denominator is all
     isolates with that positive flag.
  2. Positive flags with at least one recorded `S`, `SFP` or `R` marker result,
     and all such recorded results equal to `S`. The denominator is positive-flag
     isolates with at least one recorded `S`, `SFP` or `R` marker result.

  These are separate descriptive findings. Missing or unrecognised results do not
  count as `S`. A recorded `SFP` is interpretable but does not satisfy the literal
  all-`S` condition. The audit uses recorded categories without recategorising them.
  The second summary concerns all recorded marker results, not a claim that the
  complete panel was tested. No panel-completeness breakdown or routine isolate-level
  detail table is required.

  | Organism group | Positive flag | Antibiotics in the audit panel |
  |---|---|---|
  | Enterobacterales | BLSE | Cefotaxime, ceftriaxone, ceftazidime, cefepime |
  | Enterobacterales | Carbapenemase | Ertapenem, imipenem, meropenem |
  | *P. aeruginosa* | Carbapenemase | Imipenem, meropenem |
  | *A. baumannii* | Carbapenemase | Imipenem, meropenem |

  These panels are descriptive audit choices informed by the screening and
  confirmation agents discussed in EUCAST's detection guidance (2017, Sections
  2.4, 3.4 and 6), not a diagnostic algorithm:
  [EUCAST detection of resistance mechanisms](https://www.eucast.org/fileadmin/eucast/pdf/eucast_guidelines/EUCAST_detection_of_resistance_mechanisms_170711.pdf).
  BLSE in Pseudomonas is deferred because an audit panel has not been defined;
  retain its reported flags and do not apply the Enterobacterales panel to it.
  For any species/phenotype combination without a defined panel, these two
  comparisons are not assessed rather than counted as missing marker results.

  Neither finding establishes that a mechanism flag is wrong. Retain reported
  phenotypes and antibiotic results. No exclusion, correction or trigger threshold
  follows from these summaries.
- **Interpretation standard versions (Test 5.3)**: Record the site's declared interpretation
  standard and the distribution of raw `CASFM` version tags, when available, by year.
  Document differences without imposing a trigger threshold or excluding records.

---

Suite 6, decision 00.8 and its related note retain the text from `main` for a
separate review. Their definitions, figures and interpretations are not approved
by this recovery.

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

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 00.1 | Pre-flight documentation | Specify an upfront audit of supplied data before shared population selection | Informal, undocumented checks | Method requirement; executable common audit not implemented or remeasured here |
| 00.2 | Stay and sample identifier documentation | Report identifiers associated with multiple patients, affected patients and records, detail tables and separate missing-value counts; identification follows ADR-0007 | Assume single-column identifiers are globally unique or leave missing identifiers undocumented | In PMSI, 169 `EVTID`s span multiple patients (35 within the same source file); in lab, 135 `ELTID`s occur under multiple patients (up to 2.8 years apart) |
| 00.3 | Movement chronology documentation | Report inverted intervals, missing start/end times and affected stays; no correction or audit exclusion | Leave chronology and missing timestamps undocumented | 80 of 442 183 raw movement rows (0.018 %) have `DATENT > DATSORT` (down to -27 days) and are flagged; 24 437 movements without an end time (`DATSORT == NA`) |
| 00.4 | Timestamp profile | Report declared resolution and midnight shares by unit and period; no acceptance threshold | Infer timestamp quality from a fixed percentage | Rouen has **4.11 %** `DATENT` and **4.08 %** `DATSORT` at midnight; exposure method defined in `04-donnees-activite.md` (Decision 04.9) |
| 00.5 | Recorded UF structure matches | Compare recorded PMSI and laboratory ordering UFs to the structure file; report matched/unmatched codes, affected records and missing UF counts; no audit exclusion or coverage threshold | Check all structure UFs against the data or enforce a minimum match percentage | Admin 362/362 (100 %); lab 272/278 recorded UFs found in structure (6 unmatched UFs, 68 raw records) |
| 00.6 | Susceptible results against natural resistance reference | Count and document S results against uppercase R rules in CA-SFM 2025 V1.1, Section 2, pp. 33-39, respecting exceptions; retain reported results | Infer an error or alter results from the reference comparison alone | In 2024 raw extract, 1 *K. pneumoniae* reported S to ampicillin (outpatient ELTID 376198529); 604/604 results R in the eligible hospitalisation perimeter |
| 00.7 | Positive phenotype marker summaries | By species, phenotype and year, report positive flags without recorded S/SFP/R marker results and those with all recorded marker results S, using explicit audit panels and denominators; retain values | Infer mechanism validity from susceptibility categories or routinely list every positive isolate | Definitions specified in Test 5.2; measured counts for these two summaries are not documented here |
| 00.8 | Pre-flight descriptive profiling | Export comprehensive descriptive profile and divergence ledger (`audit_qualite.rds`) | Omit ingestion profiling | Quantifies true within-species redundancy (32.1 % 3-year ratio; 24.9 % repeat episodes; 26.5 % in 2024) and polymicrobial rates (13.5 % target samples) |

The historical examples illustrate the available observations; they do not establish implementation or validation of every check defined here.

---

## Notes

### 00.2 note — identifiers associated with multiple patients

The Rouen counts above document shared identifiers, not a confirmed explanation
of how they arose. A time gap between occurrences does not distinguish identifier
recycling from other source-data issues. No such explanation is required to report
the finding or to use the composite keys defined in ADR-0007.

### 00.3 note — chronological interval findings in PMSI data

Among raw PMSI movements (442 183 rows), the historical audit identified:
- **80 rows** with `DATSORT < DATENT` (negative durations ranging from -0.03 days to -27.0 days).
  All 80 belong to source `SRC == "C"`.
- **24 437 rows** with `DATSORT == NA`, recorded with `PMSISTATUT == "E"`.

The audit reports movement-row counts and distinct stays affected without
inferring why dates are inverted or end times are missing. The 24 437 rows are
not necessarily 24 437 distinct stays. Missing final movement end times must
remain visible when documenting whole-stay boundaries.

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
