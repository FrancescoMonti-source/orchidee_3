# 00 - Audit of standardized input data

Status: **Suites 1–5 preserved; Suite 6 revised for review, with open choices**.
The audit documents and flags findings without automatic action or acceptance
thresholds. This chapter specifies the method; this documentation revision
implements no executable common audit and remeasures no hospital data.

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

ORCHIDEE specifies a common input audit of the prepared site handoff. The
pipeline position below is an ORCHIDEE design decision; the source passages
motivate explicit, documented quality information.

---

## What ORCHIDEE does

The common audit examines the **standardized site handoff after local cleaning,
antibiotic and bacterial mappings, diagnostic selection and retention of isolates
with an antibiogram**. Correct local preparation is accepted as an input
assumption. Shared hospital perimeter selection and analysis-specific specimen
selection follow the audit and precede deduplication (ADR-0003).

```
Local sources
    -> local preparation, mappings and diagnostic antibiogram selection
    -> standardized site handoff
    -> common input audit
    -> shared hospital perimeter and analysis-specific specimen selection
    -> deduplication
    -> indicator construction
```

The shared core reads the prepared handoff. Each site owns its source-specific
classification and preparation; the common audit does not inspect native
comments, reclassify diagnostic samples or recover upstream exclusions. Local
preparation does not authorise additional local hospital perimeter exclusions.
Hospitalisation activity retains its own population, including relevant activity
from patients without a culture or antibiogram. Emergency linkage remains governed
by chapter 05 and ADR-0009.

**Document findings only.** The audit sets no acceptance thresholds, changes no
reported results, excludes no records and blocks no processing. Population
selection, exposure calculation and unit attribution remain in their owning
chapters. This documentation revision implements no executable audit and
remeasures no counts.

Fields such as `PATID`, `EVTID` and `ELTID` name concepts to bind to the prepared
common input; they do not require Rouen's native schema. The reviewed checks use
available values and history. A missing input is reported as not assessable;
preparation may make earlier source variation unavailable to the common audit.
The audit does not require sites to reconstruct discarded source histories.

The expected input-format specification defines what each row represents, the
fields and the complete entity keys. The audit uses those definitions rather
than discovering the meaning of a row. Missing definitions belong to the
[portable contract](../adr/0003-portable-contract-is-the-product.md).

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
│   └── Test 5.3: Document the declared interpretation standard and supplied version metadata
│
└── Suite 6: Descriptive Profiles of the Supplied Data
    ├── Test 6.1: Row counts and complete-key entity counts
    ├── Test 6.2: Isolates of each species for each patient, and antibiotic results
    ├── Test 6.3: Detail by species within the same population
    └── Test 6.4: Samples containing at least two target species
```

---

The historical Rouen examples and witnesses in Suites 1–5 cover **2022–2024**.
Unless a narrower period is explicitly stated (for example, 2024 alone), each
figure refers to that full three-year period. Suite 6 uses explicitly
constructed examples, separate from those hospital observations.

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
for stays and `(PATID, ELTID, isolate_id)` for isolates (Decision 06.3).
Historical witness files name the local isolate field `souche_id`; Rouen's raw
export names it `DLVL`. Those aliases do not change the complete isolate key.

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
- **Interpretation standard versions (Test 5.3)**: Record the site's declared
  interpretation standard and any version metadata supplied through the handoff,
  by year. Document differences without imposing a trigger threshold or excluding
  records. Inspection of native tags such as Rouen's `CASFM` remains local; the
  common audit does not read raw laboratory exports. A missing declaration is
  reported as unavailable.

---

### 6. Descriptive Profiles of the Supplied Data

The inventory in 6.1 describes each supplied dataset's own population. The
microbiology profiles in 6.2–6.4 describe the supplied diagnostic antibiogram
isolates before shared hospital perimeter selection, analysis-specific specimen
selection and deduplication. Correct local preparation is an input assumption.

For every output, identify the site, input version and dataset coverage, the
applicable mapping versions, period and specimen scope, and the population and
counting unit. Every percentage carries its numerator and denominator. State
the taxon definitions and antibiotic identities used by the relevant profile.
The [Open](#open) section distinguishes proposed conventions from agreed rules.

#### 6.1 How much data was received?

Use the row meanings and complete entity keys defined by the expected input
format. For each supplied dataset separately, report its row count and the
distinct patients, stays, samples and isolates represented, where applicable.
These are counts of different units, each with the dataset's stated coverage.

In the methods' notation, the keys are patient `PATID`, stay `(PATID, EVTID)`,
sample `(PATID, ELTID)` and isolate `(PATID, ELTID, isolate_id)` (ADR-0007).
A local isolate number alone does not count isolates. Several antibiotic-result
rows can describe one isolate. Historical `souche_id` is an alias for the local
isolate identifier, as explained in Suite 1 and Decision 06.3.

For each entity key, separately report rows with a missing or incomplete key.
State **rows** as the unit; these are not a count of unidentified patients,
samples or isolates. Keep identifiable isolates without an assignable taxon
visible in the inventory. The treatment of incomplete or conflicting information
in affected calculations is proposed under Open.

Preserve the omission of movements from this comparative volume table. The
inventory does not restrict hospitalisation activity to microbiology patients.

#### 6.2 Isolates of each species recorded for each patient

For each period, overall and by specimen type, count the isolates of each
species for each patient. Show how many patients have one, two, three… isolates
of that species. Consider each patient separately for every species present.

**Population and reporting groups.** Use complete-key input isolates with an
assignable patient, mapped taxon and reporting period. Count each isolate once,
irrespective of its number of antibiotic-result rows. Separately account for
data that cannot be assigned to these groups, using isolates where their keys
are complete and rows where isolate identity cannot be established. Unassigned
taxa do not form an invented common “unknown species”.

Produce profiles by sampling calendar year and calendar year-month, overall
and by mapped specimen type. A known year can support an annual profile when
the month is unknown. Stay dates do not replace sampling dates. Keep isolates
with a missing or unclassifiable specimen type in the overall profile when
the other required information is usable; account for them explicitly.

Recompute patient and species counts within each period and specimen group.
Annual distinct-patient counts are not sums of monthly counts. A species
represented once in urine and once in blood for a patient contributes one
isolate to each specimen-specific profile and two to the overall profile.

**Counts.** Report total isolates, distinct patients and the total number of
species counted separately for each patient. The glossary calls the latter
the **patient–species pair count**: E. coli in two patients contributes twice.
Use the declared taxon mapping for species and complexes, without guessing
equivalences between overlapping labels.

For every observed exact isolate count, report how many patient–species
combinations have that count and how many isolates they contain. Retain each
count 1, 2, 3… rather than arbitrary bins. Combination counts sum to the total
patient–species count; their isolate contributions sum to total included
isolates.

**Three summary percentages.** For each patient, count how many species have
just one isolate and how many have at least two isolates. Sum those counts
across patients, then calculate the percentages below. Each denominator uses
the same population, period and specimen group as its numerator.

| Summary | Numerator | Denominator |
|---|---|---|
| Species with one isolate, counted separately for each patient | Sum across patients of the number of species with one isolate | Sum across patients of the number of all included species |
| Species with at least two isolates, counted separately for each patient | Sum across patients of the number of species with at least two isolates | The same total species count |
| Isolates belonging to the second group | All isolates of those species in those patients, including the first isolate | All included isolates |

Calculate these percentages from the summed counts, rather than averaging
individual patients' percentages. The first two count species separately for
each patient; the third counts isolates.

**Constructed example**, within one period and specimen scope:

| Patient | Species | Isolates |
|---|---|---:|
| A | E. coli | 3 |
| A | K. pneumoniae | 1 |

There are **four isolates, one patient and two species counted for that
patient**:

- One species has one isolate: **1/2 = 50%**.
- One species has at least two isolates: **1/2 = 50%**.
- All three E. coli isolates belong to the latter group: **3/4 = 75%**.

The exact distribution has one patient–species combination with one isolate
and one with three isolates. Adding patient B with one E. coli isolate gives
three combinations and five isolates: the three fractions become **2/3, 1/3
and 3/5**. These are explanatory examples, not hospital measurements.

##### Antibiotic results

Within each species, period and specimen group, report:

- The distribution of distinct mapped antibiotics with a recorded result per
  isolate. Each included isolate contributes one count, including zero if none
  of its supplied results meets the declared counting rule.
- For each antibiotic, isolates with a recorded result divided by **all
  included isolates in that group**, with both counts and the percentage.
  An isolate contributes at most once to that antibiotic's numerator.

These outputs describe the available antibiotic results. An individual `NA`
does not remove an isolate from the denominator or reopen its antibiogram
eligibility. The proposed definition of a countable result is under Open;
local interpretation of source information stays local (chapter 06).

Use all supplied mapped antibiotics rather than an indicator-only panel.
Repeated rows do not increase isolate or antibiotic counts. Phenotype
attributes are not antibiotic results. Document the antibiotic counting key
and its relationship to the key used to resolve several results for one
isolate and antibiotic during preparation. This profile does not choose a
new result-resolution rule or infer tests absent from the handoff.

#### 6.3 Detail by species

Use the same population, taxon definitions, periods and specimen groups as
6.2. For each species report:

- Isolates and distinct patients.
- Mean isolates per patient: species isolates / patients with that species.
- Patients with at least two isolates of that species, the number of all
  patients with that species, and their percentage.

Species isolate counts sum to the 6.2 isolate total. Species patient counts
sum to the patient–species count. Their sum can exceed the distinct-patient
total because one patient may have several species. Unassigned taxa remain
visible in the inventory.

#### 6.4 Samples containing at least two target species

Use samples represented by the supplied diagnostic antibiogram isolates,
before shared hospital perimeter selection and deduplication. Count complete
sample keys `(PATID, ELTID)` and distinct mapped target species represented
by the supplied isolates. Two isolates of one species contribute one species.

**Proposal awaiting confirmation:** within one declared period and specimen
scope, report samples with at least two target species, samples with at least
one target species, and their percentage:

> Samples with at least two target species / samples with at least one target species.

The denominator, exact target list and reporting detail remain open. The
restriction to samples represented by the supplied antibiogram population is
agreed. Several identification labels are not automatically distinct taxa;
use the declared species/complex mapping. Keep unassigned taxa distinguishable
from confirmed absence of another target species. Incomplete or conflicting
sample information follows the explicit proposals under Open.

The profiles describe the supplied input. They do not identify infection
episodes, biological strains or actual deduplication removals. The latter are
specified for each selected analysis in
[chapter 07](07-dedoublonnage.md#deduplication-audit-output).

---

## Decisions

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 00.1 | Common input audit | Audit the prepared diagnostic antibiogram handoff before shared hospital perimeter selection and deduplication; accept completed local preparation | Reclassify local source data in the common core | Agreed boundary; executable common audit not implemented or remeasured here |
| 00.2 | Stay and sample identifier documentation | Report identifiers associated with multiple patients, affected patients and records, detail tables and separate missing-value counts; identification follows ADR-0007 | Assume single-column identifiers are globally unique or leave missing identifiers undocumented | In PMSI, 169 `EVTID`s span multiple patients (35 within the same source file); in lab, 135 `ELTID`s occur under multiple patients (up to 2.8 years apart) |
| 00.3 | Movement chronology documentation | Report inverted intervals, missing start/end times and affected stays; no correction or audit exclusion | Leave chronology and missing timestamps undocumented | 80 of 442 183 raw movement rows (0.018 %) have `DATENT > DATSORT` (down to -27 days) and are flagged; 24 437 movements without an end time (`DATSORT == NA`) |
| 00.4 | Timestamp profile | Report declared resolution and midnight shares by unit and period; no acceptance threshold | Infer timestamp quality from a fixed percentage | Rouen has **4.11 %** `DATENT` and **4.08 %** `DATSORT` at midnight; exposure method defined in `04-donnees-activite.md` (Decision 04.9) |
| 00.5 | Recorded UF structure matches | Compare recorded PMSI and laboratory ordering UFs to the structure file; report matched/unmatched codes, affected records and missing UF counts; no audit exclusion or coverage threshold | Check all structure UFs against the data or enforce a minimum match percentage | Admin 362/362 (100 %); lab 272/278 recorded UFs found in structure (6 unmatched UFs, 68 raw records) |
| 00.6 | Susceptible results against natural resistance reference | Count and document S results against uppercase R rules in CA-SFM 2025 V1.1, Section 2, pp. 33-39, respecting exceptions; retain reported results | Infer an error or alter results from the reference comparison alone | In 2024 raw extract, 1 *K. pneumoniae* reported S to ampicillin (outpatient ELTID 376198529); 604/604 results R in the eligible hospitalisation perimeter |
| 00.7 | Positive phenotype marker summaries | By species, phenotype and year, report positive flags without recorded S/SFP/R marker results and those with all recorded marker results S, using explicit audit panels and denominators; retain values | Infer mechanism validity from susceptibility categories or routinely list every positive isolate | Definitions specified in Test 5.2; measured counts for these two summaries are not documented here |
| 00.8 | Descriptive profiles of the supplied input | Report rows and complete-key entities, isolates of each species for each patient, antibiotic results and target species per sample; show populations and denominators and keep unresolved definitions explicit | Omit descriptive profiles or interpret repeat counts as actual deduplication removals | Constructed examples in 6.2; no new hospital measurement or executable-audit validation; proposals remain under Open |

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

### 00.8 note — reading the descriptive profiles

The first two percentages in 6.2 describe species counted separately for each
patient. The third describes isolates and includes every isolate belonging to
those repeated-species counts, including the first. These percentages describe
the input before shared population selection. Deduplication removals depend on
the selected analysis and its rules in chapter 07.

Species-specific repeat counts do not establish chronic colonisation, acute
infection or a reason for repeated sampling. Several target species in a
sample do not establish polymicrobial infection.

The former Rouen tables, figures and interpretations remain preserved in the
[pre-revision chapter](https://github.com/FrancescoMonti-source/orchidee_3/blob/d5fd57a4a5032c266a753cbe6e61132e9299243c/docs/methods/00-audit-qualite.md#6-descriptive-profiling-and-deduplication-redundancy-statistics).
They concern historical source data or derived extracts, not measurements of
the revised common-input profiles. They have not been remeasured here and
do not determine the new profiles' populations or denominators.

## Open

- **Action following a quality finding.** In a separate discussion, specify and trace what happens
  after each check finds a problem, including when the outcome is report-only. Keep each action with
  its owning check or tripwire entry; this note is the follow-up marker, not a parallel action register.

- **Common input fields.** Bind the reviewed concepts to the portable fields and
  available metadata without changing their populations, counting units or
  denominators. Unavailable inputs remain not assessable.

The following Suite 6 choices remain proposals or unresolved definitions;
this revision does not turn them into approved defaults:

- **Antibiotic result counts.** Proposed: count available `S`, `SFP` and `R`
  results, using the existing `I` and `ZIT` mappings. Untested `NA` placeholders
  do not count as results. Where the prepared input distinguishes a test
  without a usable result, keep that information separate. This does not
  change an isolate's inclusion in the supplied antibiogram population.
- **Mapping details.** Declare the antibiotic counting identities, their
  relationship to result-resolution identities, species/complex equivalences
  and the target list. Improve the previous mappings without assuming every
  existing entry is correct. No dictionaries are changed by this revision.
- **Incomplete or conflicting information.** Proposed: retain the available
  data, use only unambiguous year/month, specimen and taxon attribution, and
  report an affected calculation as not assessable where attribution or
  identity cannot be established. Report affected isolates when identifiable
  and affected rows when isolate counting is impossible. This does not
  exclude records from surveillance or change eligibility.
- **Empty denominators.** Proposed: display “percentage not calculable” and
  retain the numerator and denominator.
- **Missing classifications.** Decide the separate or combined display of
  missing and unclassifiable specimen types, and the presentation of
  unassigned taxa. Keep their different meanings and affected counts visible.
- **Samples with several target species.** Confirm the proposed 6.4
  denominator, target list and reporting detail.

Local diagnostic selection, retention of isolates with an antibiogram and
the position of the common audit are agreed input assumptions.
