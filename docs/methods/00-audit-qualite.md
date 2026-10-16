# 00 - Audit of standardized input data

Status: **Suites 1–5 reviewed and retained; Suite 6 revised, with open details identified**.
The executable common audit has not been implemented or remeasured in this review.

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

## What SPF asks

SPF asks to receive, for every aggregated indicator, the numerator and
denominator used (SPF p. 5):

> nous souhaiterions recevoir, pour tous les indicateurs agrégés demandés, le
> numérateur et dénominateur utilisés (le nombre de souches avec une résistance, le
> nombre de souches testés, le nombre total de JH).

ORCHIDEE documents the prepared data supplied at its common entry point before
shared hospital perimeter selection and deduplication. The statements above
motivate explicit quality information; the audit boundary below is an ORCHIDEE
design decision.

## What ORCHIDEE does

### Input and pipeline position

**Agreed scope (2026-10-16; issue #22):** chapter 00 examines the **standardized
site handoff after local preparation, diagnostic selection and retention of
isolates with an antibiogram, before shared hospital perimeter selection and
deduplication**. This supersedes the former raw-only scope and clarifies which
selection has already occurred.

The sites converge on a shared ORCHIDEE representation, as specified by
[ADR-0003](../adr/0003-portable-contract-is-the-product.md). Rouen's native
exports are one site's sources, not the format that other hospitals must
reproduce. The common core reads only the site handoff.

```
Local sources
    -> local cleaning and antibiotic/bacterial mappings
    -> local diagnostic selection and retention of isolates with an antibiogram
    -> standardized site handoff
    -> chapter 00: common input audit
    -> shared hospital perimeter selection
    -> analysis-specific specimen selection
    -> deduplication
    -> indicator construction
```

Data at this boundary have already been prepared; they are not raw source
data. Their fields, row meanings and available values are defined by the
shared input model. Audit rules must use that model rather than Rouen's
native columns or intermediate witness bundles.

The microbiology population supplied by the site is accepted as correctly
prepared, diagnostic and already restricted to isolates with an antibiogram.
The common audit does not reassess those local decisions or recover records
removed upstream. Local diagnostic and antibiogram restrictions do not
authorise additional local hospital perimeter exclusions. The shared pipeline
applies that perimeter after the audit; analysis-specific specimen selection
also precedes deduplication. Existing Emergency linkage decisions are unchanged.

Hospitalisation activity has its own population. It includes relevant activity
from patients without a culture or antibiogram; the microbiology restriction
does not select patients or stays for exposure denominators.

The previous ORCHIDEE antibiotic and bacterial mappings are the agreed starting
point for improvement. The common audit consumes their prepared identities,
without reinterpreting local labels. This revision changes no dictionaries and
does not validate all existing entries. Unsettled antibiotic equivalences,
species/complex groupings and target lists remain mapping decisions.

### Local raw-data checks

Each site determines how to examine its own raw sources. Those activities
remain outside the shared audit. This chapter does not prescribe a portable
raw auditor, a Rouen-shaped raw dataset or a mandatory raw-audit report.

Correct local preparation and diagnostic selection are accepted input
assumptions, not outstanding common-audit findings or requests for local
certification. The audit neither inspects raw comments nor requires counts of
screening records or other records removed upstream. Native typos, source-code
reuse, conflicting source histories or discarded result rows may no longer be
observable in the handoff. The existing provenance qualifications in Suites
1–5 remain intact.

The [review archive](audit-checkpoints-deferred.md) preserves the former
raw-only specification and Rouen source observations. They are historical
material, not a required local workflow for every hospital or a measured
baseline for the new common audit.

### Current response policy

**Document findings only.** No automatic blocking, quarantine, exclusion,
correction or other response is activated. Proposed policies in the
[tripwire register](tripwire-register.md) remain subject to review. An
unavailable field or an unresolved input meaning must not be recorded as
a passed check.

## Audit checks and descriptions

The reviewed Suites 1–5 are retained. The common-input boundary does not
withdraw their rules or reopen the completed methodological review. Suite 6
retains the descriptive decisions made before the raw-only detour, with the
remaining choices stated next to the affected profiles.

Field names such as `PATID`, `EVTID` and `ELTID` identify concepts used by the
existing methods; they do not require every hospital to reproduce Rouen's
native exports. Binding a site's prepared fields to these concepts is an
implementation task. Where the necessary input or provenance is unavailable,
record that a check cannot be evaluated rather than silently marking it passed.

```
Chapter 00 — Audit of standardized input data
├── Suite 1: Patient, stay and sample IDs
│   ├── 1.1 Stay IDs used for different patients
│   ├── 1.2 Sample IDs used for different patients
│   └── 1.3 Laboratory stays missing from administrative data
├── Suite 2: Sex, birth date and age
│   ├── 2.1 Different sex codes recorded for a patient
│   ├── 2.2 Sex-code agreement between laboratory and administrative data
│   ├── 2.3 Different birth dates recorded for a patient
│   └── 2.4 Ages below 0 or above 120 years
├── Suite 3: Sampling, admission and discharge dates
│   ├── 3.1 Discharge before admission and missing discharge dates
│   ├── 3.2 Samples collected inside or outside the linked stay
│   ├── 3.3 Time between sampling and the linked stay
│   └── 3.4 Admission and discharge times recorded at midnight
├── Suite 4: Hospital-unit codes
│   ├── 4.1 Unit codes found in the annual structure
│   └── 4.2 Unit codes not found in the annual structure
├── Suite 5: Antibiotic results and resistance phenotypes
│   ├── 5.1 Susceptible results contrary to the intrinsic-resistance reference
│   ├── 5.2 BLSE and carbapenemase flags compared with antibiotic results
│   ├── 5.3 Declared antibiogram standard version
│   └── 5.4 Result retained when an isolate has several results for one antibiotic
└── Suite 6: Descriptive profiles of the input data
    ├── 6.1 Row counts and entity counts
    ├── 6.2 Isolates of the same species recorded for each patient
    ├── 6.3 Isolate counts by bacterial species
    └── 6.4 Specimens with at least two target species
```

### Suite 1 — Patient, stay and sample IDs

The reviewed identities are patient `PATID`, stay `(PATID, EVTID)`, sample
`(PATID, ELTID)` and isolate `(PATID, ELTID, isolate_id)` (Decision 06.3;
[ADR-0007](../adr/0007-relational-keys-are-composite-against-recycling.md)).
Historical files use `souche_id`, while Rouen's native local isolate field is
`DLVL`. Neither alias changes the complete isolate identity.

#### 1.1 Stay IDs used for different patients

Count distinct `EVTID` values associated with more than one `PATID`. Use the
complete patient–stay key for links, so reuse of a local number cannot join
different patients. If preparation has replaced local identifiers, record
whether that original reuse remains observable in the supplied data.

#### 1.2 Sample IDs used for different patients

Count distinct `ELTID` values associated with more than one `PATID`. Use
complete sample and isolate keys when counting or linking the corresponding
entities. A local isolate label alone is not an isolate count.

#### 1.3 Laboratory stays missing from administrative data

Compare laboratory patient–stay references with administrative patient–stay
keys and report unmatched references and their affected records. Compare
identifiers with a documented common meaning. An unmatched reference is a
finding; it does not by itself prove an erroneous admission or cause exclusion.
The historical Rouen administrative source is PMSI.

### Suite 2 — Sex, birth date and age

#### 2.1 Different sex codes recorded for a patient

For each patient, compare the recorded sex values within each supplied
dataset. Expect a stable value and report patients with differing values.
Code variation is a recorded-data finding; it does not establish a biological
change. Do not choose between conflicting observations silently.

#### 2.2 Sex-code agreement between laboratory and administrative data

Compare sex values for linked patients after their meanings have been made
comparable. Report concordant patients, the number compared and the agreement
percentage. Retain the reviewed expectation of at least **99.9%** agreement.
Record ambiguous or unavailable comparisons explicitly.

#### 2.3 Different birth dates recorded for a patient

For each patient, report differing recorded birth dates, including patterns
such as January 1 versus December 31. Such patterns do not by themselves
establish which date is correct. This check requires the corresponding
observations to be retained in the supplied data.

#### 2.4 Ages below 0 or above 120 years

Report records with an age outside `0 <= age <= 120`, using the documented
age field and unit. Rouen witnesses call that field `PATAGE`. The check does
not correct an age, infer the cause of an outlier or quarantine a record.

### Suite 3 — Sampling, admission and discharge dates

Use the site's declared temporal resolution and the supplied patient–stay
links. Preserve the distinction between the recorded dates and any later
clinical attribution. Missing sampling dates are not replaced with stay dates.

#### 3.1 Discharge before admission and missing discharge dates

Check `DATENT <= DATSORT` for hospitalisation movement intervals. Record
inverted intervals and missing discharge dates separately (Decision 00.3).
Missing bounds cannot be counted as valid closed intervals. No correction,
exclusion or quarantine is triggered by this audit in the current phase.

#### 3.2 Samples collected inside or outside the linked stay

Compare each isolate's sampling date with the bounds of its linked stay.
Count complete isolate keys before admission, within the interval and after
discharge. The denominator contains isolates with a comparable sampling date
and one unambiguously linked stay with ordered bounds (`DATENT <= DATSORT`).
Report missing dates, unavailable or ambiguous links and invalid bounds as
not evaluable for this comparison; this does not exclude those isolates from
surveillance. The reviewed containment
expectation is at least **98%** in the applicable linked-stay context; it is
a quality finding threshold, not a surveillance inclusion rule.

The historical comparison uses `DATENT <= DATEPRELEV <= DATSORT`. The
clinical unit-attribution rule in chapter 05 remains a separate operation;
this descriptive comparison does not replace it or the Emergency linkage rule.

#### 3.3 Time between sampling and the linked stay

Report signed lags for sampling before admission or after discharge.
Retain the reviewed rules:

- Lags greater than **30 days** are reported only; they do not change eligibility.
- Sampling at least **48 hours before admission** is marked suspicious.

The relationship of the 48-hour review rule to ADR-0009's bounded Emergency
linkage remains a specific follow-up in chapter 05. Date lags alone do not
establish a pre-operative visit, follow-up consultation or infection episode.

#### 3.4 Admission and discharge times recorded at midnight

Count `00:00:00` and non-midnight values separately for admission and
discharge. Compare the midnight share with the site's declared format
([TW-04.2](tripwire-register.md); Decision 00.4):

- Declared `datetime`: expect a midnight share at most **10%**.
- Declared `date`: expect a midnight share at least **95%**.
- A share between **10% and 95%** is recorded as a resolution finding.

A midnight value alone does not distinguish an actual midnight from a
default time. Prepared timestamp formatting alone does not prove source
precision. No blocking response is activated. Occupancy-hour mathematics
remain in chapter 04 (Decisions 04.2 and 04.9).

### Suite 4 — Hospital-unit codes

Use the frozen annual `unit_mapping` snapshot supplied for the reporting
period (chapter 05, Decision 05.4). Common-input reference checks use that
snapshot, not Rouen's native structure files.

#### 4.1 Unit codes found in the annual structure

Check that every administrative unit contributing hospitalisation activity
and at least **99.9%** of microbiology observations resolve in the annual
structure. Report the units and observations compared and the proportion
resolved ([TW-05.1](tripwire-register.md)).

#### 4.2 Unit codes not found in the annual structure

Report unmatched unit codes and their affected observations. Chapter 00
documents that result; the positive perimeter definition in chapter 03
remains downstream population selection. This audit does not automatically
exclude the affected records.

### Suite 5 — Antibiotic results and resistance phenotypes

#### 5.1 Susceptible results contrary to the intrinsic-resistance reference

Compare mapped taxa and antibiotic results with the reviewed intrinsic-
resistance reference. EUCAST (Intrinsic Resistance and Unusual Phenotypes
v3.3, p. 4 and Tables 1–2, pp. 5 and 7) and CA-SFM (2025, pp. 33–35) carry
the rows below. For P. aeruginosa, cefotaxime and trimethoprim-sulfamethoxazole
come from CA-SFM p. 35, while EUCAST p. 7 lists ceftriaxone and trimethoprim
alone.

| Taxon | Antibiotics in the reviewed reference check |
|---|---|
| Klebsiella pneumoniae | Ampicillin; amoxicillin |
| Enterobacter cloacae complex | Amoxicillin-clavulanate |
| Proteus mirabilis | Colistin |
| Pseudomonas aeruginosa | Ampicillin; amoxicillin-clavulanate; cefotaxime; ceftriaxone; ertapenem; trimethoprim-sulfamethoxazole |

Flag a reported susceptible result contrary to that reference for review.
The discrepancy alone does not prove a clerical error or misidentification.
Record it without changing the reported result or activating quarantine.

#### 5.2 BLSE and carbapenemase flags compared with antibiotic results

Retain the reviewed distinction in
[TW-06.1](tripwire-register.md#tw-06-1):

- A positive phenotype with no corresponding interpretable antibiotic result
  (`S`, `SFP` or `R`) is a finding;
  retain the reported positive flag.
- Present supporting results read as `R` or `SFP` support the positive flag.
- Present corresponding interpretable results that are all `S` are reported
  as discordant.
- Missing-result cases are counted separately and are not classified as
  discordant. The percentage definition and threshold remain those of TW-06.1.

Within its enzymatic scope for Enterobacterales and Pseudomonas, an absent
phenotype signal follows chapter 06's Note Xa rule (SPARES p. 15 and Annexe 6
footnote a, p. 31). This does not turn an absent
antibiotic susceptibility result into a susceptible or negative result.
The current audit records findings without activating the quarantine policy
retained in the tripwire register for later review.

#### 5.3 Declared antibiogram standard version

For surveillance campaigns from 2024 onward, check the site's declared
interpretation standard against CA-SFM/EUCAST 2020 or later (SPARES p. 15;
[TW-06.2](tripwire-register.md#tw-06-2)). A missing declaration is not a passed
check. Native dictionary tags such as Rouen's `CASFM` can lag clinical
practice: their inspection remains local and does not justify rejecting
historical records solely because a source tag is older.

#### 5.4 Result retained when an isolate has several results for one antibiotic

Retain the reviewed preparation rule: where the same isolate has several
results for the same mapped antibiotic, **keep the last result in the source
file's row order**. This is source row order, not a new chronological rule.
Preparation must produce one retained result per isolate–antibiotic pair.

The common audit checks uniqueness of the resulting pair and the documented
retention rule. Verification against source order uses available preparation
provenance; it does not require the core to read native exports. Without that
provenance, output uniqueness can still be checked, but the last-source-row
choice must not be reported as independently verified. This result-resolution
rule is distinct from surveillance isolate deduplication in chapter 07.

### Suite 6 — Descriptive profiles of the input data

The inventory in 6.1 describes each supplied dataset's own population.
The microbiology profiles in 6.2–6.4 describe the supplied diagnostic
antibiogram population before shared hospital perimeter selection,
analysis-specific specimen selection and deduplication. They do not count
infection episodes, identify biological strains or measure the number of
isolates removed by deduplication.
The [English–French glossary](../../CONTEXT.md#englishfrench-terminology)
defines species, specimen, isolate and antibiotic-result record.

#### 6.1 Row counts and entity counts

For each supplied dataset, state what one row represents before reporting
its row count. A result record for one isolate and antibiotic and a row
containing an isolate's entire antibiogram have different counting units.
Their row totals cannot be read as numbers of the same entity.

Report distinct patients and full-key counts of stays, samples and isolates
represented in each dataset, using the keys in Suite 1. For each entity key,
report the number of rows with a missing or incomplete key, with **rows** as
the counting unit; these are not a count of distinct unidentified entities.
The treatment of these rows in affected calculations remains open below.
Distinct values of `EVTID`, `ELTID` or the local `isolate_id` alone do not count
those entities.

Use the explicit term **antibiotic-result records**, replacing the ambiguous
"handoff observations" label. Keep the earlier decision to omit the PMSI
movement dataset from this comparative volume table. Rouen source files and
the historical diagnostic bundle remain examples in the
[archive](audit-checkpoints-deferred.md), not new common-input baselines.

#### 6.2 Isolates of the same species recorded for each patient

**Question:** within a stated sampling period and specimen scope, how many
isolates of a given bacterial species are recorded for each patient?

**Population:** the supplied microbiology isolates are already diagnostic
isolates with an antibiogram. Their eligibility is an accepted local
preparation assumption, not a presence rule for the common audit to define.
Use complete isolate keys to count each isolate once, regardless of the number
of antibiotic-result rows. Phenotype attributes are not antibiotic-result
records; a result token alone does not identify a mapped antibiotic.

**Periods and specimen scope:** produce the profile separately by sampling
calendar year and calendar year-month, overall and by mapped specimen type.
Keep identifiable isolates with a missing or unclassifiable specimen type
in the overall summary. Missing and unclassifiable are distinct situations;
their combined or separate display remains to be settled. Count unavailable
annual/monthly date attribution explicitly. A known year with an unknown
month can contribute annually; stay dates do not replace a missing sampling
date.

**Taxon attribution:** separately account for identifiable antibiogram
isolates without an assignable mapped taxon. They cannot form a patient–species
pair and must not all be merged into one invented "unknown species". They
remain in the input inventory; the representation of that unassigned remainder
is part of the narrow taxonomic follow-up. The distribution and its `N` below
concern isolates with assignable patient and taxon keys in the stated context.

**Reporting context:** one sampling calendar year or year-month, either all
specimen types together or one mapped specimen type. Within that context,
the pair profile uses complete isolate keys with an assignable patient and
mapped taxon. State this population alongside its totals and account for
unavailable keys, dates, specimen types and taxa in the inventory. Do not
silently choose among conflicting supplied values; the remaining decisions
are listed under Open.

**Totals:** within that pair-profile context, report:

- `N`: included isolates;
- `U`: distinct patients;
- `P`: observed patient–species pairs.

One patient with three E. coli isolates and one K. pneumoniae isolate, all in
the same reporting context, contributes **four isolates, one patient and two
patient–species pairs**: patient–E. coli with three isolates and
patient–K. pneumoniae with one. Neither pair establishes an episode or a
duplicate group. This is a constructed example, not a new Rouen measurement.

**Exact distribution:** retain each observed integer value `k = 1, 2, 3, …`.
For each `k`, report the number of pairs with exactly `k` isolates and the
number of isolates in those pairs (`k` times the pair count). Pair counts
sum to `P`; isolate counts sum to `N`. These are isolate-count classes, not
antibiotic classes.

**Three reviewed percentages:** report numerator, denominator and percentage
for each measure:

| Measure | Numerator | Denominator |
|---|---|---|
| Pairs with one isolate | Pairs containing exactly one included isolate | `P` pairs |
| Pairs with at least two isolates | Pairs containing at least two included isolates | `P` pairs |
| Isolates in those pairs with at least two isolates | All included isolates belonging to those pairs | `N` isolates |

The third numerator includes all isolates in those pairs, not only those
beyond the first. Thus a percentage of patient–species pairs is not a
percentage of isolates. None of these measures is the actual deduplication
removal fraction. In the constructed example, the three percentages are
respectively **1/2 = 50%, 1/2 = 50% and 3/4 = 75%**. Its exact distribution
contains one pair with `k = 1` (one isolate) and one pair with `k = 3` (three
isolates).

Recompute totals, distinct patients and pairs within each period and specimen
context. Annual patient and pair counts and distributions are not sums of
their monthly counterparts: a patient present in several months counts once
in the year. Specimen-specific pairs are also formed independently; they
cannot be inferred from the overall pair grouping.
Use declared mapped taxon identities; the equivalence of a species label and
a species-complex label must not be guessed.

##### Antibiotics recorded for each isolate

Retain the laboratory-practice profiles requested before the raw-only detour:
for each species and specimen type, by sampling year and year-month, describe
the antibiogram-isolate subset with:

1. The distribution of the **number of distinct mapped antibiotics with a
   recorded result per isolate**. Each isolate contributes one count value;
   several rows for the same isolate and antibiotic count once.
2. For each antibiotic, the number of isolates with a recorded result, the
   total included isolates in the same reporting context, and their ratio
   expressed as a percentage. An isolate contributes at most once to that
   antibiotic's numerator; the percentages across antibiotics need not sum
   to 100.

The first output counts antibiotics represented for one isolate, rather than
result rows or distinct species–antibiotic pairs pooled across patients.
The second describes recorded panel composition, not antibiotic resistance.
The exact antibiotic-equivalence key remains the earlier open point: route,
breakpoint and local-test variants must not silently become different
physical molecules, or be merged without a documented rule. Use the supplied
results rather than an indicator panel that omits other recorded antibiotics.
Tests not exported cannot be inferred. A distribution peak alone does not
identify an instrument or protocol.

For an individual antibiotic, `NA` means **not tested unless other source
information explicitly establishes otherwise** (chapter 06). Interpretation
of such source information, including comments, belongs to local preparation;
the common audit reads the prepared result and any supplied distinction.
An untested `NA` placeholder is not a recorded result. If local preparation
establishes a test but supplies no interpretable result, keep that distinction
visible; its treatment in these result counts remains to be confirmed rather
than silently equating it with either an untested or a recorded result.
An individual `NA` does not discard an isolate from the supplied antibiogram
population or from the included-isolate denominator. Recorded `S`, `SFP` and
`R` results use the existing `I` and `ZIT` mappings without changing them.

Raw tested-pair totals, their per-patient/per-stay means and the removed
`(isolates - pairs) / isolates` ratio are not added. Literal raw-label
cardinalities and source typo frequencies remain local-source descriptions;
they are not substituted for the patient–species profile above.

#### 6.3 Isolate counts by bacterial species

Retain the species-specific view as a concrete part of Suite 6 to finish
reviewing. Within the same population, period and specimen context as 6.2,
report for each declared species or target taxon: isolates `N_s`, distinct
patients `U_s`, mean isolates per patient `N_s / U_s`, and patients with at
least two isolates of that taxon `R_s`, with their denominator `U_s` (and
`R_s / U_s` if expressed as a percentage). `U_s` counts patients with that
species in that context, not all patients in the supplied data.

This species detail reconciles with 6.2: species isolate counts sum to `N`,
and species patient counts sum to `P`, since each counts one patient–species
pair. Their sum is not the overall distinct-patient count `U` when a patient
has several species. Apply the same unresolved-information qualifications
as in 6.2; unassigned taxa remain in the inventory.

This is the species detail of the preceding descriptive calculation. Remove
the historical "redundancy ratio" column and the ranking by that ratio.
The target list and any species/complex equivalences remain to be made
explicit. Historical values are preserved in the archive, not revalidated.
The counts do not establish chronic colonisation, acute infections or
ward-specific sampling practices.

#### 6.4 Specimens with at least two target species

**Population:** samples represented by the supplied diagnostic antibiogram
isolates, before shared hospital perimeter selection and deduplication. This
restriction to samples with an antibiogram is settled. The profile cannot
describe samples absent from the handoff.

Count complete sample keys `(PATID, ELTID)` and distinct mapped target species
represented by their supplied isolates. Two isolates of the same species in
one sample still contribute one species; E. coli and K. pneumoniae in the same
sample contribute two. Report rows with incomplete sample keys separately,
as rows, rather than inventing sample identities.

**Recommendation awaiting confirmation:** for a target-restricted view, report
the number of specimens containing at least two distinct mapped target taxa,
the number containing at least one such taxon in the same descriptive input subset,
and their percentage. This proposed fraction is **samples with at least two
target species / samples with at least one target species**, within the same
declared period and specimen context. The exact target list, target-specimen
denominator and reporting detail still require confirmation; the supplied
antibiogram population does not. Several literal identification labels are
not distinct taxa. Missing or conflicting sample, date, specimen or taxon
information must be visible, with the affected counting choices left open.

Species co-detection does not establish polymicrobial infection. The old
36.86% and 13.53% figures describe different historical populations and have
no verified reproduction; they are not a demonstrated processing or
deduplication effect and do not supply the new denominator.

The actual input, retained and removed isolate counts for deduplication are
specified in [chapter 07](07-dedoublonnage.md#deduplication-audit-output), for
each selected analysis. The removed cross-species patient measure remains
removed.

## Decisions

| Decision | Retained requirement or focused follow-up |
|---|---|
| 00.1 | Audit the prepared diagnostic antibiogram site handoff after local cleaning, mappings and diagnostic selection, before shared hospital perimeter selection and deduplication. Trust local preparation; raw audits remain local. |
| 00.2 | Use complete patient–stay, sample and isolate identities; retain the reviewed identifier-reuse and reference checks. |
| 00.3 | Record inverted movement intervals and missing discharge dates. No quarantine is activated. |
| 00.4 | Retain the reviewed midnight-share checks and declared temporal resolution. No blocking is activated. |
| 00.5 | Retain annual structure coverage and unmatched-unit reporting; selection remains downstream. |
| 00.6 | Retain the intrinsic-resistance reference check; record discrepancies for review. |
| 00.7 | Retain phenotype–AST comparisons, distinguishing absent results from susceptible results; retain a reported positive flag when corresponding results are missing. |
| 00.8 | Retain explicit row/entity units, patient–species distributions and reviewed percentages; actual deduplication loss belongs to chapter 07. Suite 6's remaining definitions are listed below. |

The reviewed Suites 1–5 remain specified methods. Field binding and any
unavailable provenance are implementation qualifications, not a withdrawal
of those decisions. Implementation and data measurement remain deferred.

## Historical observations

Rouen figures motivate the checks and are retained below as previously
recorded observations, not remeasured common-input baselines. Derived
diagnostic tables are not raw data or the final selected analysis population.
The [archive](audit-checkpoints-deferred.md) contains the full historical
tables and the superseded raw-only discussion.

### Raw bacteriology counts

The historical `bact22_24` extract contains **5 154 206 laboratory rows**.
The following values count individual source fields, not complete entity keys:

| Source field | Historical distinct values |
|---|---:|
| `PATID` | 107 049 |
| `EVTID` | 196 066 nonmissing values |
| `ELTID` | 507 416 |
| Local isolate field `DLVL` | Not measured in raw data during this review |

### Identifiers recorded for multiple patients

- PMSI: 169 of 194 566 distinct `EVTID` values (0.087%) occur for multiple
  patients; 35 occur within the same administrative source file (`SRC == "C"`).
- Bacteriology: 135 `ELTID` values occur for multiple patients. In 94.8% of
  these cases the recorded dates are more than 30 days apart (median 319 days,
  maximum 1 038 days).

These observations motivate complete patient–stay, sample and isolate keys.
They do not establish raw isolate-key uniqueness; the historical 48 595-row
uniqueness result came from a transformed diagnostic table.

### Recorded sex codes, birth dates and ages

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

### Movement dates and recorded times

- Among 442 183 raw PMSI movement rows, 80 (0.018%) have discharge before
  admission, with signed durations from -0.03 to -27 days. All 80 are in
  source `SRC == "C"`.
- 24 437 movement rows have a missing discharge date; the historical
  observation records `PMSISTATUT == "E"` for these unclosed movements.
- The recorded midnight shares are 4.11% for `DATENT` and 4.08% for `DATSORT`.


### Linked sampling dates and mapped units

The historical diagnostic table linked to PMSI records 45 927 isolates
(98.56%) within the linked stay, 185 (0.40%) before admission and 485 (1.04%)
after discharge. The recorded median outside-stay lags are 4 and 14 days
respectively. These values do not establish the clinical reasons for those
dates or the composition of the full common input.

Historical structure observations report 362/362 administrative units and
272/278 microbiology units resolved. The six unmatched microbiology codes
carry 68 raw laboratory rows and no diagnostic isolates in the historical
bundle. That row count is not an isolate count. The historical intrinsic-
resistance example reports one outpatient K. pneumoniae susceptible to
ampicillin, and no such discrepancy among the 604 eligible inpatient
observations. None of these historical findings activates quarantine here.

Correct local preparation, diagnostic selection and the supplied antibiogram
population are settled assumptions, not open findings. They introduce no
common raw-comment reader, local diagnostic certification or accounting for
upstream exclusions. The agreed annual/monthly reporting, exact distributions
and explicit denominators remain specified above.

## Open

- **Mapping and display.** Improve the previous antibiotic and bacterial
  mappings without declaring their entries validated. Exact antibiotic
  equivalences, species/complex groupings and target lists remain open where
  not already settled. Confirm separate or combined display of missing and
  unclassifiable specimen types and presentation of unassigned taxa.
- **Missing or conflicting prepared information.** Treatment of conflicting
  dates, specimen types or taxa, and incomplete identifiers in affected
  calculations, remains open. The suggested approach is to retain available
  data, use a year or month only where unambiguous, and report calculations
  that cannot be evaluated. This is a recommendation, not an approved conflict
  resolution rule. Row counts for incomplete keys are specified in 6.1;
  they do not resolve those calculation choices. Also confirm how explicitly
  documented tests with no interpretable result enter antibiotic-result
  counts and coverage; default untested `NA` values do not count as results.
- **Empty denominators.** Retaining the counts and displaying “percentage not
  calculable” is proposed, not approved. Do not silently report zero or a
  passed calculation when the denominator is empty.
- **Suite 6.4 fraction and reporting detail.** The at-least-two / at-least-one
  target-species fraction remains a recommendation. Confirm its exact target
  list, target-specimen denominator and reporting detail. Samples with an
  antibiogram are the settled supplied population.
- **Input field binding and preparation provenance.** Consolidate the portable
  fields and available history needed to execute the retained methods. A
  missing input is reported as not evaluable; it does not erase the check.
  Source-order verification of result retention is distinct from output
  uniqueness.
- **Audit output and responses.** Specify the common findings output. For now,
  findings are documented only; no automatic blocking, correction, quarantine
  or exclusion is activated. Later checkpoint organisation remains deferred.
