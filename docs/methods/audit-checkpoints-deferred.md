# Archived audit discussions and historical examples

Status: **archive only; previous scopes and examples, not active requirements**.

On 2026-10-16 the user abandons the raw-only boundary for chapter 00. The
shared audit now concerns standardized site handoff data after the necessary
mappings, before population selection and deduplication. Native raw audits
are each site's responsibility; other hospitals do not reproduce Rouen's raw
format. The active specification is [chapter 00](00-audit-qualite.md).

The user's subsequent clarification preserves the already reviewed Suites
1–5 and directs the revision of Suite 6 using the conversation's decisions.
Those concrete methods are restored in chapter 00; the temporary raw-only
boundary and the blanket replacement by a review outline are superseded.

This file preserves earlier discussions, examples and the superseded raw-only
specification. The active chapter identifies the retained Suite 6 outputs and
its narrow remaining questions. Statements below that withdrew all mapped
work record the abandoned raw-only detour, not the present review status.
Explicitly removed metrics remain removed, and historical figures are not
newly validated. Possible later checkpoints and action policies still require
their own review.

## Earlier decisions during the raw-only review

The statuses below record the earlier raw-only context; they do not define
the current common-input specification.

| Earlier question or choice | Status recorded during that review |
|---|---|
| Q8: include only isolates with an antibiogram | Withdrawn from 00; no verified native rule establishes this population. |
| Q5/Q9: classified specimen breakdown | Withdrawn from 00; source labels do not supply mapped categories. |
| Q9: annual/monthly reporting for the former mapped profile | Does not approve a different raw counting unit; the new raw proposal is stated separately in 00. |
| Q10/Q11: patient–species distribution and shares | Withdrawn from 00; history retained, with no automatic approval for another checkpoint. |
| Q13/Q14: distinct-antibiotic panels and organism–drug coverage | Withdrawn from 00 on the same basis. |
| Preliminary antibiogram availability | Not an active raw metric; native evidence and linkage are unverified. |
| Q15/Q16: antibiotic equivalences and taxonomic grouping | Unanswered and outside the current raw review. |
| Q12/Q17: remove the global beyond-one ratio and cross-species patient measure | Removals remain in force. |
| Q18: two audit moments inside 00 | Superseded by the raw-only scope. |
| Later proposal: counts of tested combinations and means per patient/stay | Explicitly excluded from the final agreed raw 6.2; distinguishing phenotype and antibiotic tests remains outside this profile. |

The former raw laboratory profile consisted of distinct original specimen/identification label
counts and missingness, raw result-value frequencies, and sampling-year/month
detail with unavailable date attribution explicit. It included no long label
frequency lists, tested-pair counts or patient/stay means. Its raw-row counting
units and literal-value rules are preserved in the superseded specification
below; they are not silently transferred to standardized input.

## Historical material preserved from chapter 00

The material below records the previous wording and historical figures. Its
scope and methodological interpretations are not uniformly reviewed. In
particular, diagnostic/mapped bundles do not establish raw pre-flight counts;
clinical explanations of isolate frequency do not prove infection episodes or
colonisation. Source citations are preserved for subsequent review. Proposed
quarantine/exclusion actions are not activated: the current phase documents
findings only.

### Sample–stay example from a derived isolate table

Report how far sample collection falls before admission or after discharge.
On Rouen surveillance data (`sir_wide.rds` linked to PMSI):

- **45 927 isolates (98.56 %)** are strictly contained within the stay (`DATENT <= DATEPRELEV <= DATSORT`).
- **185 isolates (0.40 %)** were sampled *before* admission (`DATEPRELEV < DATENT`), with a median
  lag of 4 days (pre-admission emergency department testing or pre-operative outpatient consultations).
- **485 isolates (1.04 %)** were sampled *after* discharge (`DATEPRELEV > DATSORT`), with a median
  lag of 14 days (post-discharge surgical wound follow-up).
- Lags of more than 30 days before admission or after discharge are reported only; they do not
  by themselves change isolate eligibility.
- Pre-admission lags of 48 hours or more are reported as suspicious. Their relationship to the
  Emergency linkage decision is tracked under Open in `05-structure.md`.

### Microbiological plausibility checks requiring mapping

- **Intrinsic microbiological resistances**: Under EUCAST (Intrinsic Resistance and Unusual
  Phenotypes v3.3, p. 4 and Tables 1-2, pp. 5 and 7) and CA-SFM (2025, pp. 33-35) guidelines, certain
  bacterial species possess universal chromosomal resistance mechanisms. An isolate reported as
  susceptible (`S`) to an intrinsically resistant molecule indicates clerical error or taxonomic
  misidentification. The pre-flight audit validates incoming isolates against the intrinsic resistance
  matrix (both sources list the four rows below; for *P. aeruginosa*, cefotaxime and
  trimethoprim-sulfamethoxazole come from CA-SFM p. 35, while EUCAST p. 7 lists ceftriaxone and
  trimethoprim alone):
  - ***Klebsiella pneumoniae***: intrinsically resistant to **Ampicillin / Amoxicillin**.
  - ***Enterobacter cloacae complex***: intrinsically resistant to **Amoxicillin-clavulanate**.
  - ***Proteus mirabilis***: intrinsically resistant to **Colistin**.
  - ***Pseudomonas aeruginosa***: intrinsically resistant to **Ampicillin, Amox-clav, Cefotaxime, Ceftriaxone, Ertapenem, Trimethoprim-sulfamethoxazole**.
- **Resistance flags and antibiotic test results (`TW-06.1`)**: Compare positive BLSE and
  carbapenemase flags with the relevant antimicrobial susceptibility testing (AST) results. If a
  positive flag has no corresponding antibiotic test result, record a non-blocking finding and
  continue processing; retain the reported phenotype under Decision 06.5. The
  [full TW-06.1 specification](tripwire-register.md#tw-06-1) defines the exact checks and what
  happens to discordant results.
- **Repeated antibiotic test results**: An isolate can have more than one result for the same
  antibiotic. Before analysis, the handoff reduces these to one result for that isolate and
  antibiotic. This check verifies the documented rule: keep the last result in the source file's row
  order.

---

### Descriptive profiles and cross-dataset historical figures

The pre-flight audit profiles the source data supplied by the site, using the
required mappings for classified profiles before surveillance selection. Literal
source-label inventories belong to the first audit moment; the grouped profiles
below belong to the second. The terminology is
defined in the [English–French glossary](../../CONTEXT.md#englishfrench-terminology).
An isolate is an individual bacterial recovery recorded for a sample, before
deciding whether it duplicates another recovery. An antibiotic-result record is
one result attached to that isolate; several result records can describe one
isolate.

#### Dataset row counts and entity counts (Rouen 2022–2024 baseline)

First state what one row represents in each dataset. The three row totals below
count different kinds of records.

| Dataset | Meaning of one row | Recorded rows |
|---|---|---:|
| Raw bacteriology (`bact22_24`) | One laboratory record; several records can concern the same sample and isolate. | 5 154 206 |
| Antibiotic-result records supplied by the site (`microbiology_observations`) | One local antibiotic-result record attached to an isolate. | 679 101 |
| Diagnostic isolate records (`sir_wide.rds`) | One isolate, with antibiotic results in columns, before surveillance deduplication. | 48 595 |

The `microbiology_observations` dataset contains the antibiotic-result records
supplied by the site. The [screening witness](../worked-examples/screening_exclusion_witness.R)
reads its antibiotic-result rows and assembles isolate rows from them. For
example, amoxicillin R, cefotaxime S and ciprofloxacin S for one isolate are three
antibiotic-result records describing one isolate's antibiotype.

These are recorded historical counts, not a newly validated v3 baseline. The
`sir_wide.rds` bundle was built by the v2 pipeline and its site mappings remain
unreviewed; see [witness provenance](../worked-examples/deduplication.md). The
diagnostic isolate table also precedes the hospital-unit perimeter selection used
by the indicator witnesses. The differences between these totals combine changes
in row representation with data selection; they do not measure deduplication.

Next, count the entities represented in each dataset using their full keys:
patient (`PATID`), stay (`PATID`, `EVTID`), sample (`PATID`, `ELTID`), and isolate
(`PATID`, `ELTID`, `isolate_id`). Reused identifiers mean that counting `EVTID` or
`ELTID` alone need not give the number of stays or samples.

The existing measurements below count distinct values of individual fields.
They are preserved as recorded; full composite-key counts for stays and samples
still need to be measured.

| Identifier field counted | Raw bacteriology | Antibiotic-result records | Diagnostic isolate records |
|---|---|---|---|
| Distinct `PATID` values | 107 049 | 23 763 | 23 072 |
| Distinct `EVTID` values | 196 066 non-NA (262 NA) | 33 406 | 32 399 |
| Distinct `ELTID` values | 507 416 | 44 767 | 41 951 |
| Distinct local isolate labels (`isolate_id`) | Not recorded | 7 | 7 |

The historical files call the local isolate identifier `souche_id`; the methods
use `isolate_id` for the same field. Its seven distinct values are local labels
reused across different samples. They are neither seven isolates nor seven
species or biological lineages. Only the full isolate key identifies an isolate.

#### Number of isolates per patient and species

**Former scope — withdrawn from 00:** describe recorded isolates in the original source
population, using the mappings needed for the second audit moment, before
surveillance population selection and deduplication. The main patient–species
distribution counts **only isolates with traceable antibiogram results**.
Counts actually retained or removed by deduplication belong to chapter 07.

**Former preliminary proposal — inactive:** quantify the availability of an
antibiogram for all bacterial isolates identifiable in the raw data. This
coverage calculation has a broader denominator than the main distribution:
isolates without traceable antibiogram results remain represented here, while
the main patient–species distribution uses the antibiogram-result subset.

**Former reporting periods for both calculations:** each sampling calendar
year and each sampling calendar month, retaining the year in the month key
(for example, January 2023 and January 2024 are separate periods).

**Former specimen detail — withdrawn from 00:** for each year and
year-month, produce both an overall summary across all specimen types and a
breakdown by classified specimen type in the second audit moment. Each
calculation uses its own included isolates within that period and specimen
scope. Retain source labels and report classification coverage and the
unclassified remainder. Bacterial and antibiotic groupings likewise require
their dictionaries; their exact equivalence rules remain under review.

**Former unclassified-specimen choice — archived:** identifiable
isolates with an absent specimen type or a type that cannot be classified are
kept in the overall summary when their reporting period is known. The site
author notes that the specimen mapping is not exhaustive. An absent source
value and a supplied value that cannot be classified are distinct situations;
whether their display categories are combined or separate remains open.
Discordant source values are a separate unresolved issue, not a synonym for
incomplete mapping. No exhaustive classification is assumed.

For each period and specimen reporting scope, the **coverage denominator** is
the number of distinct bacterial isolates whose identities can be established
from those raw records, not the number of laboratory or antibiotic-result
rows. The **main distribution** recounts its isolates, patients and observed
patient–species pairs using only the antibiogram-result subset. Raw records
that cannot be assigned to an individual isolate require separate accounting;
they cannot be silently treated as additional isolates.

**Former temporal-accounting choice — archived:** explicitly count isolates
that cannot be assigned to the annual or monthly sampling period, recording
which reporting level is affected. If a sampling year can be established with
certainty but its month cannot, the isolate contributes to the annual profile
and is counted as not attributable at the monthly level. The actual frequency
of these cases has not been measured here.

The period refers to sampling information (`DATEPRELEV` in the existing
witnesses). Admission and discharge dates describe the stay and can support
coherence checks, but the methods define no replacement of a missing sampling
date by either stay date. Pre-admission sampling can cross a month or year
boundary relative to admission; see ADR-0009. Any future recovery rule from
other temporal evidence would require an explicit decision.

The user describes the raw extract as containing results, not examination
requests. No request records, separate reports or examination-status fields
have been verified in the raw export. Visual inspection of the scanned DXLAB
codebook finds a result line labelled "antibiogramme" under the identification
analysis (Codes DXLAB, PDF p. 5). Its presence and values in the actual export,
and whether it establishes a completed examination, remain unverified. The
presence rule must be grounded in the records actually supplied.

A result-based definition is under review: at least one raw antibiotic
susceptibility-result row linked to an identifiable isolate, with result
interpretability assessed separately. This has not yet been approved as the
operational definition. Recognising those result rows requires verification
against the source's test dictionary, rather than adopting the old witness's
restricted antibiotic panel.

Result spelling must be distinguished from the information it carries. The
site author reports rare manually entered source values such as `-R` and `--R`
and confirms that these exact spellings mean `R`. These are recoverable typing
errors, not evidence that the laboratory could not interpret susceptibility.
Their frequencies have not been measured here. Recognised source tokens
(`S`, `R`, `I`, `ZIT`, and `SFP` where used), confirmed typing errors, missing
values and unresolved source strings must not be conflated. `ZIT` is a
recognised technical-uncertainty token; it is not a typing error.

The current methods already give `I` and `ZIT` a defined treatment: preparation
reads them as `SFP` (chapter 06, Result alphabet), and indicator construction
places `SFP` on the `S` side (chapter 08, decision 08.2). These recognised
tokens therefore do not mean unknown source strings or absent antibiogram
results. The raw audit documents them as received; their later mapping does
not need to be reopened to define result availability here.

The raw audit retains and documents source spellings. Any later preparation
rule for confirmed typos must be explicit and site-specific; the two confirmed
examples do not justify stripping punctuation from arbitrary unknown values.
The meaning of a typo does not by itself settle the pending coverage rule for
other source values.

The proposed reporting states are:

| Evidence in the supplied raw data | Count and denominator |
|---|---|
| An antibiogram can be documented and linked to the isolate | Number of such isolates, and share of all identifiable bacterial isolates in the same period |
| No antibiogram can be found for the isolate in the supplied extract | Number of such isolates, and share of the same denominator |
| Available records do not allow antibiogram presence or linkage to be determined | Number of such isolates, and share of the same denominator |

Compute the annual percentages from annual counts, rather than averaging the
monthly percentages. These states must sum to the identifiable-isolate total
within each period. No antibiogram found
in an extract does not establish that none was performed by the laboratory.
Presence of an antibiogram and availability of interpretable susceptibility
results are separate questions. The operational evidence rule, including how
to distinguish absence of evidence from indeterminate linkage, remains to be
agreed and verified against the raw source. This preliminary calculation has
not been run.

For a given patient and a given bacterial species, **how many isolates with
traceable antibiogram results are recorded in the raw data over the stated
period and specimen scope?** Identifying which raw records document an isolate
and its antibiogram results, and taxonomic grouping, remain under review.
The tables below are provisional historical
examples from a diagnostic extract, not a validated raw-data baseline.

For example, suppose patient A has three *E. coli* isolates and one
*K. pneumoniae* isolate with traceable antibiogram results recorded in 2024:

| Patient | Species | Number of isolates in 2024 |
|---|---|---:|
| A | *E. coli* | 3 |
| A | *K. pneumoniae* | 1 |

Each row is a **patient–species pair**: one patient considered together with one
species. The same patient can therefore contribute several pairs. A count of
three means three isolates of that species recorded for that patient. The count
alone says nothing about whether they belong to one or several duplicate groups.

**Former totals and distribution (Q10) — withdrawn from 00:** for each main-profile period and
specimen scope, use the isolates with traceable antibiogram results and report:

- $N$: the number of included isolates;
- $U$: the number of distinct patients;
- $P$: the number of observed patient–species pairs.

Preserve the exact isolate-count values (1, 2, 3, …) in the required
distribution, rather than pooling the upper values. For each value $k$, report
the number of patient–species pairs containing exactly $k$ included isolates
and the number of isolates in those pairs. The latter is $k$ times the number
of pairs in the row. Pair counts sum to $P$ and isolate counts sum to $N$.
A row such as "3 isolates" therefore groups patient–species pairs containing
three isolates; it is not an antibiotic class.

**Former summary percentages — withdrawn from 00:** report all three percentages below, with
their numerators and denominators in the same reporting scope:

| Measure | Numerator | Denominator |
|---|---|---|
| Pairs with one isolate | Number of pairs containing exactly one included isolate | $P$ pairs |
| Pairs with at least two isolates | Number of pairs containing at least two included isolates | $P$ pairs |
| Isolates in those pairs with at least two isolates | All included isolates belonging to such pairs | $N$ isolates |

Multiply each ratio by 100. The third numerator includes every isolate in the
pairs concerned, not just those beyond the first.

The recorded historical example describes a diagnostic extract with **48 595
isolates** from **23 072 patients**, representing **33 017 patient–species
pairs** across 2022–2024. For each pair, it counts the isolates of that species
recorded for that patient over those three years. Its grouped upper rows are
retained as historically recorded; they do not provide the newly required
exact-count distribution:

| Isolates of the species recorded for the patient | Number of patient–species pairs | Isolates in those pairs |
|---|---:|---:|
| 1 | 24 810 | 24 810 |
| 2 | 4 985 | 9 970 |
| 3 | 1 661 | 4 983 |
| 4 | 701 | 2 804 |
| 5 | 326 | 1 630 |
| 6–9 | 407 | 2 813 |
| 10 or more | 127 | 1 585 |
| **Total** | **33 017** | **48 595** |

The following percentages use different denominators:

| Measure over 2022–2024 | Numerator | Denominator | Percentage |
|---|---:|---:|---:|
| Patient–species pairs with exactly one isolate | 24 810 pairs | 33 017 pairs | 75.14 % |
| Patient–species pairs with at least two isolates of that species for that patient | 8 207 pairs | 33 017 pairs | 24.86 % |
| Isolates belonging to those pairs with at least two isolates | 23 785 isolates | 48 595 isolates | 48.95 % |

Thus, **24.86 % of pairs** account for **48.95 % of isolates**. Neither
percentage measures how many isolates deduplication removes. Use "at least two
isolates of the same species recorded for the same patient" rather than
"repeats", "repeated isolates" or "repeated pairs": those expressions can be
mistaken for duplicates already identified by the comparison rules.

These historical counts precede the hospital-unit perimeter selection used by
the indicator witnesses and remain provisional. Their arithmetic reconciles;
they have not been remeasured from the raw data during this review.

For the annual profile, group the raw antibiogram-isolate counts by
`(PATID, species, calendar year)`; for the monthly profile, use
`(PATID, species, calendar year-month)`. Form these counts separately for all
specimen types together and for each reported specimen-type category. Patients
and pairs are recounted within each reporting scope; an annual pair count or
distribution cannot be obtained by summing its monthly counterparts. One
*E. coli* isolate for a patient in 2022 and one in 2024 give two isolates in the
pooled historical profile, but only one in each of those years. These are
descriptive partitions of raw antibiogram records; they do not set a
deduplication window or measure deduplication's impact.

The actual retained and removed counts are part of the later
[deduplication audit in chapter 07](07-dedoublonnage.md#deduplication-audit-output).
They use its selected analysis input, rather than the raw-data counts here.

##### Antibiotic results per isolate, organism and specimen type

**Former outputs (Q13–Q14) — withdrawn from 00:** describe how the antibiotics represented in the
raw results vary by bacterial species and specimen type, providing a view of
laboratory practices. Produce both outputs below separately for each species
and specimen type, by sampling calendar year and calendar year-month. Use
isolates with traceable antibiogram results, before surveillance deduplication.

1. **Number of recorded antibiotics per isolate.** Count distinct antibiotics
   with a recorded susceptibility result for each isolate, then report how many
   isolates have each count value in the reporting group.
2. **Recorded results for each antibiotic.** For each antibiotic, report the
   number of isolates with a result for that antibiotic, the total number of
   isolates with traceable antibiogram results in the same reporting group,
   and the percentage obtained by dividing the former by the latter and
   multiplying by 100. This describes panel composition, not resistance rates.

For the first output, each isolate contributes one antibiotic-count value.
Several result rows for the same isolate and the same antibiotic contribute
one antibiotic to this count. The distribution then records how many isolates
have each antibiotic-count value within the organism, specimen and reporting
period. It uses recorded results before surveillance deduplication, rather than
counts of raw rows or distinct antibiotics pooled across a whole year.

For the second output, an isolate contributes at most once to each antibiotic's
numerator, even if it has several result rows for that antibiotic. Keep the
numerator and denominator explicit. These per-antibiotic percentages need not
sum to 100: one isolate can have results for several antibiotics. They describe
which antibiotics appear in the records, alongside the distribution of their
number.

Distinct antibiotic identity still requires a decision. Existing mappings can
merge aliases but also distinguish route, breakpoint or local test variants;
counting their columns does not automatically count physical molecules or
laboratory measurements. The source dictionary and equivalences must be
reviewed, including unresolved labels. A restricted indicator/comparison panel
cannot establish the full range of antibiotic results recorded in the raw data.

This profile describes recorded antibiotic results. Tests not exported or
results withheld from the extract cannot be inferred. Attribution to an
instrument or testing protocol requires corresponding documented metadata;
peaks in the distribution alone do not identify a machine. No panel-size or
composition counts have been computed here.

#### Target Pathogen Redundancy Hierarchy (2024 Alone)

**Former Test 6.3 — reviewed against the raw-only scope (2026-10-15):**
this mapped-taxon comparison is excluded from chapter 00. The exact population
and preparation rules behind the figures below remain unverified; this review
does not validate or recalculate them. The historical "redundancy ratio" is
not a measured deduplication loss. The clinical explanations following the
table are not established by these counts and are not endorsed by this review.
Preserving this material does not approve a later checkpoint requirement.

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

**Former Test 6.4 — reviewed against the raw-only scope (2026-10-15):**
this multiple-species profile is excluded from chapter 00. The historical
figures below have no verified executable reproduction establishing species
recognition, period, sample grouping, missing-value treatment or denominator
eligibility. In particular, the denominator labelled raw is not documented as
all raw specimens. Whether the historical grouping used the required full
sample key `(PATID, ELTID)` remains unknown. Multiple isolates or literal
identification labels do not establish distinct species, and species
co-detection does not establish polymicrobial infection. The two stated
populations differ; their percentages are not a validated measure of a
processing or deduplication effect. No later requirement is approved here.

- In raw bacteriology (`bact22_24`): **36.86 % of samples** (39 013 / 105 836) are polymicrobial
  ($\ge 2$ distinct species).
- In surveillance targets (`sir_wide.rds`): **13.53 % of sample containers** (5 677 / 41 951)
  yield $\ge 2$ distinct surveillance target species.

---

### Previous chapter-00 decision register (historical; scope under review)

All witnesses measured on Rouen 2022–2024 raw data (`data/pmsi`, `data/bact22_24`, `bundle_v3/sir_wide.rds`).

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 00.1 | Pre-flight isolation gate | Automated, upfront pre-flight audit executed at ingestion before population selection | Informal, manual, or post-hoc sanity checks | 100 % of checks automated and logged; prevents silent data corruption before deduplication |
| 00.2 | Relational composite key enclosure | Composite keys `(PATID, EVTID)` and `(PATID, ELTID, isolate_id)` | Single-column keys `EVTID` or `ELTID` | In PMSI, 169 `EVTID`s span multiple patients (35 within same source file); in lab, 135 `ELTID`s recycled across patients (up to 2.8 years apart) |
| 00.3 | Movement interval physical integrity | Assert `DATENT <= DATSORT`; negative stay durations quarantined from exposure | Silently accept negative stays or compute erroneous negative days | Rouen 2022–2024: 80 of 442 183 raw movement rows (0.018 %) have `DATENT > DATSORT` (down to -27 days) and are quarantined; 24 437 unclosed stays (`DATSORT == NA`) |
| 00.4 | Denominator grain verification | Operational threshold check on `00:00:00` timestamps; rejects intermediate distributions (TW-04.2) | Silently accept mixed temporal resolutions | Rouen has **4.11 %** `DATENT` and **4.08 %** `DATSORT` at 00:00 (clean `datetime`); method defined in `04-donnees-activite.md` (Decision 04.9) |
| 00.5 | Structure referential link check | Positive perimeter with non-blocking tripwire asserting $\ge 99.9\,\%$ microbiology resolution (TW-05.1) | Blocking pipeline failure on any unmapped code | Admin 362/362 (100 %); lab 272/278 UFs in structure (6 external referral UFs, 68 raw rows, 0 in `sir_wide.rds`) |
| 00.6 | Intrinsic resistance violations | Quarantined and logged in audit ledger; excluded from indicator numerator | Silently admitted or unverified | In 2024 raw extract, 1 *K. pneumoniae* reported S to ampicillin (outpatient ELTID 376198529, quarantined); 0 violations in eligible hospitalisation perimeter (604/604 R) |
| 00.7 | Phenotype-AST plausibility | An absent phenotype signal is `FALSE` under Note Xa; a positive flag without matching antibiotic results is logged and processing continues ([TW-06.1](tripwire-register.md#tw-06-1)) | Restrict denominator to explicit test rows | Under Note Xa, *E. coli* BLSE is **7.61 %** (186/2 445); restricting to explicit tests yields distorted **83.04 %** (186/224) |
| 00.8 | Pre-flight descriptive profiling | Export comprehensive descriptive profile and divergence ledger (`audit_qualite.rds`) | Omit ingestion profiling | In the pooled 2022–2024 extract, 24.86 % of patient–species pairs have at least two isolates of that species recorded for that patient, accounting for 48.95 % of isolates. Separately, 13.5 % of samples contain multiple target species. These counts do not measure the fraction removed by deduplication. |

Unproven: **0 of 8**.

---

### Previous interpretation of isolate-frequency profiles (unreviewed)

Measuring deduplication redundancy at ingestion provides vital clinical and operational context:
- In acute urinary tract infections (*E. coli*, *E. faecalis*), redundancy is low (~20–25 %),
  meaning most isolates represent independent primary infectious episodes.
- In intensive care and chronic respiratory pathogens (*P. aeruginosa*, *K. pneumoniae*),
  redundancy reaches 33–36 %, reflecting prolonged colonization, treatment monitoring, and
  frequent repeat sampling.
- In the historical pooled diagnostic extract, **24.86 % of patient–species pairs
  contain two or more isolates**, accounting for **48.95 % of isolates**.
  These are descriptive counts; the deduplication rules can retain several
  isolates from one pair. The actual fraction removed must be
  measured for each analysis from its input and retained isolate counts.

## Follow-up

If a later-stage review is opened, reassess these ideas in that scope rather
than treating the earlier answers as implementation approval. This archive
assigns no checkpoint, input population or mapping policy. No scripts,
mappings or source data were changed to produce this note.

## Raw-only audit specification superseded on 2026-10-16

The following snapshot records the former raw-only chapter. Its scope,
raw-row denominators, source-field checks and statements of agreement
are historical. The user has superseded that boundary: chapter 00 now
audits standardized common input after the necessary site mappings.
This snapshot is neither the common-input specification nor a required
raw audit for other hospitals. Raw-source diagnostics remain local.

The audit examines **raw source data before semantic mapping, analytical
preparation, population selection and deduplication**.

**Current phase: document findings only.** No automatic blocking, quarantine,
exclusion, correction or other response is activated. Actions proposed in the
[tripwire register](tripwire-register.md) remain subject to later review.

Reading documented source fields, parsing dates and comparing existing keys or
literal codes are necessary for these checks. Source values are preserved.
Different labels do not by themselves establish different species, antibiotics
or specimen types. The audit performs no taxonomic, specimen or antibiotic
harmonisation, result recoding, inferred clinical attribution or surveillance
eligibility classification.

Cross-source comparisons require documented, directly comparable identifiers
or codes. If a correspondence or semantic interpretation would first be
needed, report the comparison as not evaluable here. Missing prerequisites
must not be reported as a passed check. Dates retain their declared resolution;
missing sampling dates are not replaced with admission or discharge dates.

Raw inspection belongs on the site side of
[ADR-0003](../adr/0003-portable-contract-is-the-product.md). The portable core
continues to read only the site handoff. How raw findings accompany that
handoff remains to be specified.

An opening inventory states what has been received. The following five
sections group descriptions and coherence checks by subject. Descriptions
report volumes or recorded values; coherence checks compare source records
with a stated condition. Historical Rouen observations are listed separately
from these requirements.

```
Chapter 00 — Raw data pre-flight audit
├── Source data and counts
│   ├── What one row represents
│   └── Row counts and entity counts
├── 1. Patient, stay and sample IDs
│   ├── 1.1 Stay IDs used for different patients
│   ├── 1.2 Sample IDs used for different patients
│   └── 1.3 Laboratory stays found in PMSI
├── 2. Sex, birth date and age
│   ├── 2.1 More than one sex code recorded for a patient
│   ├── 2.2 Sex codes compared between laboratory and PMSI data
│   ├── 2.3 More than one birth date recorded for a patient
│   └── 2.4 Ages below 0 or above 120 years
├── 3. Sampling, admission and discharge dates
│   ├── 3.1 Discharge before admission
│   ├── 3.2 Missing discharge dates
│   ├── 3.3 Samples collected before, during or after the linked stay
│   ├── 3.4 Time between sampling and the linked stay
│   └── 3.5 Admission and discharge times recorded at midnight
├── 4. Hospital-unit codes
│   ├── 4.1 Unit codes found in the supplied structure
│   └── 4.2 Unit codes not found in the supplied structure
└── 5. Laboratory labels and results
    ├── 5.1 Specimen labels: distinct values and missing entries
    ├── 5.2 Organism labels: distinct values and missing entries
    ├── 5.3 Recorded result values and their frequencies
    ├── 5.4 Antibiogram standard versions compared with the site's declaration
    └── 5.5 Multiple result rows for the same test and isolate
```

#### Source data and counts

##### What one row represents

State what one row represents in each raw source. A raw laboratory row is not
automatically an isolate: several rows can concern one sample or isolate,
and not every laboratory row documents a bacterial recovery. The terminology
is defined in the [English–French glossary](../../CONTEXT.md#englishfrench-terminology).

##### Row counts and entity counts

**Question:** how many raw rows, source identifier values and identifiable
entities are present?

**Counting units and output:** distinguish raw row counts, distinct values
of individual source fields, and entity counts established by complete keys.
Count patients, stays, samples and isolates only where the native schema
establishes the corresponding entities. Account separately for missing or
incomplete keys.

| Entity | Complete source key |
|---|---|
| Patient | `PATID` |
| Stay | `(PATID, EVTID)` |
| Sample | `(PATID, ELTID)` |
| Isolate | `(PATID, ELTID, isolate_id)` |

At Rouen, the native local isolate field is `DLVL`; `isolate_id` is its
canonical name in the methods (Decision 06.3). The raw column is not renamed
by this audit. Recognising isolate-bearing records and verifying their full
keys remain prerequisites. An identifier reused in different samples or
patients does not by itself identify an entity.

Counts from transformed antibiotic-result or diagnostic-isolate tables are
outside this inventory. Their historical comparison is preserved in the
[review archive](audit-checkpoints-deferred.md).

#### 1. Patient, stay and sample IDs

Use the complete entity keys defined in the opening inventory. The checks
below inspect identifier reuse and directly comparable source links; they
do not change an identifier or infer a missing link.

##### 1.1 Stay IDs used for different patients

**Question and unit:** is a source `EVTID` recorded for more than one `PATID`?
The inspected unit is a distinct local stay-ID value.

**Operation and output:** group raw source records by `EVTID` and report
values associated with multiple patients. Interpret a stay through its
complete patient–stay key (Decision 00.2).

##### 1.2 Sample IDs used for different patients

**Question and unit:** is a source `ELTID` recorded for more than one `PATID`?
The inspected unit is a distinct local sample-ID value.

**Operation and output:** report values associated with multiple patients.
Use complete sample and isolate keys when referring to the corresponding
entities (Decision 00.2).

##### 1.3 Laboratory stays found in PMSI

**Question and unit:** which complete patient–stay keys in the laboratory
source can be matched directly to the PMSI source?

**Prerequisite, operation and output:** establish that the source identifiers
refer to the same patients and stays, then report direct source-key coverage.
If that equivalence is not established, report the comparison as not
evaluable without mapping. This check does not perform Emergency linkage,
infer an admission or assign a hospital unit.

#### 2. Sex, birth date and age

Compare recorded values within each source patient key. Interpret sex codes
literally; no code harmonisation or inference of a biological change is
performed.

##### 2.1 More than one sex code recorded for a patient

**Question and unit:** does a patient have multiple recorded `PATSEX` values
within one source?

**Operation and output:** compare recorded sex codes for each `PATID` and
report patients with different values. The output describes source-code
variation.

##### 2.2 Sex codes compared between laboratory and PMSI data

**Question and unit:** do recorded sex codes agree for directly linked
patients across the two sources?

**Prerequisite, operation and output:** compare codes only where their
meanings are already documented as equivalent. Report agreement or
disagreement on that basis; otherwise report that semantic agreement is
not evaluable without mapping.

##### 2.3 More than one birth date recorded for a patient

**Question and unit:** does a patient have multiple recorded `PATBD` values
within one source?

**Operation and output:** compare recorded birth dates for each `PATID` and
report patients with differing dates.

##### 2.4 Ages below 0 or above 120 years

**Question and unit:** does a raw row contain a recorded age outside
`0 <= PATAGE <= 120`?

**Operation and output:** report affected source rows as findings. This
check does not correct ages or remove records.

#### 3. Sampling, admission and discharge dates

Use documented native formats and date resolution. Comparisons with a stay
require directly comparable patient–stay source keys. An unavailable date or
link does not establish chronological coherence.

##### 3.1 Discharge before admission

**Question and unit:** does a raw movement row have `DATSORT < DATENT`?

**Operation and output:** compare the recorded bounds and report inverted
intervals (Decision 00.3). Exposure calculation and any treatment of these
rows are outside this audit.

##### 3.2 Missing discharge dates

**Question and unit:** which raw movement rows have no recorded `DATSORT`?

**Operation and output:** record missing discharge dates (Decision 00.3).
Do not impute a date or activate an exclusion or quarantine.

##### 3.3 Samples collected before, during or after the linked stay

**Question and unit:** where does a recorded sampling date fall relative
to its directly linked source stay?

**Operation and output:** compare `DATEPRELEV` with `DATENT` and `DATSORT`
and report containment or a position outside the interval. The result
describes the source dates and link; it does not infer an admission,
Emergency linkage or hospital-unit attribution.

##### 3.4 Time between sampling and the linked stay

**Question and unit:** how far before admission or after discharge was
the sample recorded as collected?

**Operation and output:** report signed lags using the source dates and
their declared resolution. Under the existing review rules, report lags
greater than 30 days and mark sampling at least 48 hours before admission
as suspicious. These findings do not change eligibility; clinical
attribution remains a later-stage question.

##### 3.5 Admission and discharge times recorded at midnight

**Question and unit:** what proportion of recorded admission and discharge
timestamps have the time `00:00:00`?

**Operation and output:** count midnight and non-midnight values separately
for `DATENT` and `DATSORT` and compare the midnight share with the declared
format (`date` or `datetime`). Apply the existing review thresholds
(Decision 00.4; [TW-04.2](tripwire-register.md)):

- Declared `datetime`: expect a midnight share at most 10%.
- Declared `date`: expect a midnight share at least 95%.
- A share between 10% and 95% is recorded as a resolution finding.

A midnight timestamp alone does not distinguish a real midnight from a
default time. Findings trigger no blocking in the current phase. Occupancy
hours and their relation to midnight counts belong to
`04-donnees-activite.md` (Decisions 04.2 and 04.9).

#### 4. Hospital-unit codes

**Shared prerequisite:** raw UF codes and the unmodified site-supplied
structure must share a documented namespace and reference period. Preserve
text representation and leading zeros. If a correspondence would first be
needed, report these comparisons as not evaluable without mapping.

##### 4.1 Unit codes found in the supplied structure

**Question and unit:** which distinct raw UF codes occur directly in the
supplied source structure?

**Operation and output:** compare literal source codes and report those
found, without repairing codes or applying a correspondence table.

##### 4.2 Unit codes not found in the supplied structure

**Question and units:** which raw UF codes are not found, and how many
raw records carry those codes?

**Operation and output:** report unmatched codes and affected source rows.
These checks assign no activity, discipline, canonical unit attribution or
surveillance eligibility (Decision 00.5).

#### 5. Laboratory labels and results

##### Rules for the descriptive summaries

**Agreed scope:** descriptions 5.1–5.3 cover the entire raw bacteriology
extract, before mapping. They use the original specimen label field,
organism identification field and result field.

Frequencies and missingness count **raw bacteriology rows**. Their percentage
denominator is all raw rows in the reporting period. A repeated row
contributes as received. Distinct-label counts use populated literal values
and exclude missing/empty entries. Do not produce full frequency tables of
specimen or identification labels.

Produce these summaries by **sampling calendar year and year-month**. Annual
distinct counts are recomputed on the year, not summed from monthly counts.
Account for unavailable temporal attribution, separating missing/empty
sampling dates from populated dates unreadable in the documented format.
If the year is known but the month is not, retain annual attribution and
report unavailable monthly attribution separately. Do not substitute stay
dates for sampling dates. These reporting rules do not add annual or monthly
requirements to the other checks in this chapter.

Preserve source spelling, case and punctuation. Keep native missing values,
empty values and populated literal strings distinguishable according to the
documented source format. A literal `"NA"` is not treated as missing without
source evidence.

The descriptive specification is agreed. Binding these fields and the
sampling date to the actual native schema and format remains an
implementation prerequisite; no counts have been rerun.

##### 5.1 Specimen labels: distinct values and missing entries

**Question and units:** how many distinct populated original specimen
labels occur, and how many raw rows have a missing or empty value?

**Operation and output:** count literal labels and report missing/empty
rows, with the raw-row denominator above. No specimen categories or
synonym groups are created.

##### 5.2 Organism labels: distinct values and missing entries

**Question and units:** how many distinct populated values occur in the
original organism identification field, and how many raw rows have none?

**Operation and output:** count literal values and report missing/empty
rows, with the same raw-row denominator. A recorded identification label
does not by itself establish a species or an isolate. No taxonomic grouping
or synonym merging is performed.

##### 5.3 Recorded result values and their frequencies

**Question and unit:** which literal result values occur, and how many
raw rows contain each value?

**Operation and output:** report row counts and percentages for the
observed original values, including `S`, `I`, `R`, `ZIT`, typo spellings
such as `-R` and `--R`, other populated values and missing/empty values.
Preserve the values without correction, recoding or clinical interpretation.

The site author confirms that rare manual values such as `-R` and `--R`
mean `R`; this inventory nevertheless preserves their spellings. Recognised
`I` and `ZIT` are not typing errors or absent results. The source result field
also contains phenotype-test results. The table describes that source field;
it does not measure a susceptibility rate or a number of tested antibiotic pairs.

##### 5.4 Antibiogram standard versions compared with the site's declaration

**Question and unit:** what literal standard-version tags are recorded,
and do they agree with the site's declaration?

**Operation and output:** inspect the source `CASFM` tags where supplied
alongside the site declaration. Record discrepancies without recoding
susceptibility results. A source dictionary tag alone does not prove the
clinical standard actually used. The interpretation-version rule and its
sources remain in [TW-06.2](tripwire-register.md#tw-06-2).
<!-- citecheck: ok, describes source-tag inspection and points to the version check; claims no new CA-SFM requirement -->

##### 5.5 Multiple result rows for the same test and isolate

**Question and unit:** are multiple raw result rows recorded for the same
source test code/label and identifiable source isolate key?

**Prerequisite, operation and output:** establish the native isolate key
and stable source test identifier, then inventory repeated test records.
Preserve their results and source row order. Report a missing grouping
prerequisite rather than inventing one. Different codes are not treated as
the same antibiotic, no retained result is selected and no distinct
molecule count is inferred. These records still contribute as received
to descriptions 5.1–5.3.

### Outside this raw audit

Intrinsic-resistance interpretation, phenotype–AST coherence, taxon-specific
isolate profiles, multiple-species specimen profiles, harmonised laboratory
panels and mapped structure coverage require mapping or interpretation.
Antibiogram availability, tested-pair counts and patient/stay means are not
part of the agreed raw profile. No analysis/test-label inventory or inferred
antibiogram-only population is added.

The [review archive](audit-checkpoints-deferred.md) preserves those discussions
and historical examples. It does not approve requirements or placement at a
later checkpoint. Later checkpoints and actions following findings remain
outside the current review.

### Decisions under raw-scope review

Historical observations are not an implemented raw audit or proof that all
checks are settled. All current findings are documented only.

| Decision | Raw pre-flight requirement | Status or limitation |
|---|---|---|
| 00.1 | Inspect raw data before mapping and surveillance transformations. | Scope agreed; executable audit not implemented in this review. |
| 00.2 | Use complete source identities and inspect identifier reuse. | Isolate-bearing records and comparable cross-source keys require verification. |
| 00.3 | Record inverted movement intervals and missing discharge dates. | No automatic treatment is activated. |
| 00.4 | Record timestamp resolution and midnight frequencies. | Existing review thresholds retained; response activation deferred. |
| 00.5 | Compare literal unit codes with directly comparable source structure codes. | Common namespace and structure vintage require verification. |
| 00.8 | Describe raw volumes, original labels, missing values and result values with explicit counting units. | Laboratory label, result and sampling-time outputs agreed; native fields and implementation pending. |

### Historical Rouen observations

The figures below are previously recorded source observations. They have
not been rerun or validated against newly verified native fields during this
review. They are separate from the audit specification. Figures from derived
diagnostic bundles remain in the [archive](audit-checkpoints-deferred.md).

#### Raw bacteriology counts

The historical `bact22_24` extract contains **5 154 206 laboratory rows**.
The following values count individual source fields, not complete entity keys:

| Source field | Historical distinct values |
|---|---:|
| `PATID` | 107 049 |
| `EVTID` | 196 066 nonmissing values |
| `ELTID` | 507 416 |
| Local isolate field `DLVL` | Not measured in raw data during this review |

#### Identifiers recorded for multiple patients

- PMSI: 169 of 194 566 distinct `EVTID` values (0.087%) occur for multiple
  patients; 35 occur within the same administrative source file (`SRC == "C"`).
- Bacteriology: 135 `ELTID` values occur for multiple patients. In 94.8% of
  these cases the recorded dates are more than 30 days apart (median 319 days,
  maximum 1 038 days).

These observations motivate complete patient–stay, sample and isolate keys.
They do not establish raw isolate-key uniqueness; the historical 48 595-row
uniqueness result came from a transformed diagnostic table.

#### Recorded sex codes, birth dates and ages

- Bacteriology: no patient among 107 049 has multiple recorded `PATSEX`
  values. PMSI: 13 of 106 491 patients (0.012%) have multiple values,
  including seven `F / I` and six `F / M` cases.
- The historical cross-source sex-code agreement is 99.97%
  (106 278 / 106 311 patients). Code equivalence must still be verified
  before this can establish semantic agreement.
- PMSI: 38 patients (0.036%) have multiple birth dates; the historical
  discussion includes dates such as `1991-01-01` and `1991-12-31`.
- PMSI ages range from 0.0 to 106.0 years with no reported outliers.
  Four raw bacteriology rows contain `PATAGE == 136`.

#### Movement dates and recorded times

- Among 442 183 raw PMSI movement rows, 80 (0.018%) have discharge before
  admission, with signed durations from -0.03 to -27 days. All 80 are in
  source `SRC == "C"`.
- 24 437 movement rows have a missing discharge date; the historical
  observation records `PMSISTATUT == "E"` for these unclosed movements.
- The recorded midnight shares are 4.11% for `DATENT` and 4.08% for `DATSORT`.

### Open

- **Native fields for the agreed laboratory descriptions.** Verify the
  specimen label, organism identification, literal result and sampling-date
  fields and formats. This is an implementation prerequisite; the agreed
  outputs do not include tested-pair counts or patient/stay means.
- **Source entity recognition and directly comparable codes.** Verify which
  raw records document isolates and which patient, stay, sex-code and unit-code
  comparisons are directly valid. Literal equality alone does not establish
  common meaning across sources.
- **Raw audit and the portable contract.** Specify how site-side findings
  accompany the site handoff under ADR-0003. The portable core continues to
  read the handoff rather than local raw files.
- **Later checkpoints and actions following findings.** Their design is
  deferred. The current phase records findings only.
