# 06 - Bacterial resistance data

Status: **existing resistance rules retained; shared input boundary clarified**.
Mapping details remain open below. Historical witnesses are not remeasured by
this documentation revision; no executable audit or automatic response is activated.

## What SPARES says

> Seules les souches de bactéries isolées des prélèvements à visée diagnostique ayant
> fait l'objet d'un antibiogramme durant l'année 2024 sont inclues dans la surveillance
> (date de prélèvement entre le 1er janvier et le 31 décembre 2024). (p. 14)

> Prélèvements exclus de la surveillance : prélèvements à visée écologique (recherche
> de colonisation, portage, dépistage). (p. 15)

> Chaque souche bactérienne d'intérêt est caractérisée par : un patient source [...],
> une date de prélèvement et un site de prélèvement [...] un antibiotype, un phénotype de
> résistance pour les Enterobacterales (BLSE, carbapénémase). (p. 14)

> Pour chaque molécule testée, le résultat S (Sensible), SFP (sensible à forte
> posologie) ou R (Résistant) est renseigné. [...] Seuls les résultats des
> antibiogrammes interprétés selon une version du CA-SFM/EUCAST postérieure à 2019
> (version 2020 ou plus récente) sont pris en compte dans ConsoRes. (p. 15)

> Pour les Enterobacterales et Pseudomonas, les résultats de la recherche de
> bêta-lactamases à spectre étendu (BLSE) et de carbapénèmase sont à renseigner après
> vérification du phénotype. (p. 15)

> les phénotypes de résistance BLSE et carbapénémase des Enterobacterales et Pseudomonas
> doivent être renseignés en cas de positivité et après vérification. Une case vide est
> considérée comme une absence de phénotype de résistance (et non comme une donnée
> manquante). (p. 31)

The last passage is footnote *a* of the variable dictionary (Annexe 6, p. 31), attached
to the BLSE and Carbapénémase rows. These docs call it **Note Xa**. The two pages
disagree on scope: p. 14 names Enterobacterales only, while p. 15 and footnote *a* name
Enterobacterales and Pseudomonas.

## What ORCHIDEE does

### 1. Isolate identity
An **isolate** is identified by `(PATID, ELTID, isolate_id)`. `isolate_id` is the
local isolate identifier: it distinguishes separately recorded isolates recovered
from the same sample, including multiple isolates of the same species. Its value
can recur in other samples, so the full composite key is required.

Historical witness files call this field `souche_id`; Rouen's raw GLIMS exports
call it `DLVL`. Preparing v3 data maps those source names to `isolate_id`. Witness
scripts reading historical bundles continue to use their actual column names.

The isolate exists before deciding whether it duplicates another recovery.
Deduplication preserves the original key of the retained isolate; it does not
rename the column or issue a new identity after grouping. The key identifies an
individual recovery, while a duplicate group belongs to a particular analysis.
See the [English–French glossary](../../CONTEXT.md#englishfrench-terminology).
`EVTID` is retained for stay attribution and grouping witnesses.

### 2. Screening exclusion and site boundary
The **site adapter** cleans and maps local data, classifies samples as diagnostic
or screening, applies diagnostic selection, and retains isolates with an
antibiogram **before supplying the standardized site handoff** (ADR-0003).
The common microbiology audit starts from that prepared diagnostic antibiogram
population and accepts correct local preparation and selection as assumptions.
`diagnostic_scope` describes the site's diagnostic classification; it is not a
requirement to supply screening rows for the common core to exclude later.

The shared audit does not revalidate local classification, recognise antibiogram
eligibility again, inspect raw labels or comments, or recover upstream exclusions.
No shared count of excluded screening records is required from unavailable rows.
The historical keyword witness explains why interpretation belongs locally;
the common core does not reinterpret local analysis codes.

Shared hospital perimeter selection follows the audit. Analysis-specific
specimen selection also precedes deduplication. Local diagnostic and antibiogram
selection does not authorise additional local perimeter exclusions. Emergency
linkage remains governed by chapter 05 and ADR-0009. Hospitalisation activity
retains its own population, including relevant activity from patients without a
culture or antibiogram.

### 3. Result alphabet
For every tested molecule, clinical categories are mapped to a strict ternary alphabet:
- **`S`** (sensible à posologie standard)
- **`SFP`** (sensible à forte posologie / intermédiaire)
- **`R`** (résistant)
- **`NA`** (not tested by default, unless other source information explicitly establishes otherwise)

An individual antibiotic `NA` does not remove an isolate whose antibiogram is
already in the supplied population. If source information establishes a test
with a missing or uninterpretable result (for example `NC` / `Non côté`), local
preparation keeps that distinction explicit instead of treating every `NA` as
equivalent evidence. Any source-comment interpretation belongs to that local
preparation, not a common raw-comment reader or a new antibiogram eligibility
check. The remaining treatment of explicitly documented tests without an
interpretable result in Suite 6's result counts is stated there as open.

Historical results with `I` (CA-SFM &le; 2022) are read as `SFP`. Measurement caveat
`ZIT` (zone d'incertitude technique) is read as `SFP`.

At indicator construction, `SFP` belongs to the `S` side; see chapter 08,
decision 08.2. Thus the current methods give both source `I` and source `ZIT`
the path `SFP` then `S` for that classification. They are recognised values
with established rules, not unknown strings or missing results. The `ZIT`
mapping is an ORCHIDEE choice, recorded in decisions 06.2 and 07.5.

**Source spelling clarification (Rouen):** the site author reports rare manual
entry typos such as `-R` and `--R`, confirming that these exact values mean `R`.
They are not additional clinical categories or laboratory interpretation
failures. Local source diagnostics may document those literal values; chapter
00 examines the standardized handoff after the necessary mappings. Preparation
must preserve the distinction between these known spellings and missing or
unresolved values. No
typo-normalization code or new correction rule is implemented in this review.

### 4. Resistance phenotypes (BLSE, Carbapenemase)
For Enterobacterales (and carbapenemase in *P. aeruginosa* and *A. baumannii*),
resistance phenotypes are modeled as **binary isolate attributes** (`TRUE` / `FALSE`),
not as antibiotic rows.

The site adapter maps local laboratory signals (confirmatory tests, expert comments,
disk synergy rows) into `blse` and `carbapenemase`. In accordance with clinical
laboratory practice and SPARES Note Xa, an **absent phenotype signal is interpreted as
negative (`FALSE`)**. Wild-type susceptible strains do not trigger confirmatory testing
in routine practice. A positive phenotype with no corresponding antibiotic test result
is recorded as a non-blocking finding and processing continues; see the
[TW-06.1 specification](tripwire-register.md#tw-06-1).

During deduplication, comparison operates on the antibiotic panel. Within a deduplicated
patient-sample cluster, positive phenotype status is propagated (`any(positive) -> TRUE`).

### 5. CA-SFM referential validation
Compliance with CA-SFM &ge; 2020 is established via **site run metadata declaration**
for surveillance data from 2024 onward; see
[TW-06.2](tripwire-register.md#tw-06-2) for the rule and source pages.
The common input audit can examine the declaration supplied through the handoff;
its portable metadata fields remain to be specified. Any supporting inspection
of native `CASFM` tags is local site work, not a core read of raw laboratory
files. The method does not reject historical rows solely because dictionary
tags lagged behind clinical reporting.

### 6. Bacterial taxonomy
Local preparation starts from the **previous ORCHIDEE bacterial and antibiotic
mappings and improves them**. This is the user's agreed foundation, not a
declaration that all existing entries are correct. No dictionary changes are
implemented by this revision.

Local organism descriptions are translated on the site side; the common audit
consumes prepared identities rather than interpreting those descriptions.
Isolates without an assignable mapped taxon remain visible in the inventory.
They do not all form an invented “unknown species” pair. Exact antibiotic
equivalences, species/complex groupings and target lists remain mapping decisions
where not already settled. A source species list (SPARES Annexe 5, pp. 28–30)
does not itself decide those ORCHIDEE mappings.

---

## Decisions

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 06.1 | Screening samples | excluded locally before the site handoff and common audit, hence before deduplication | included | Historical: +5.6 % isolates; céfotaxime 16.96 &rarr; 25.19 %R (+8.23 pp); ertapénème x4.3. `docs/worked-examples/screening-exclusion.md` |
| 06.2 | `ZIT` against `SFP` | `ZIT` is read as `SFP` under the ORCHIDEE mapping decision | `ZIT` treated as missing data | see 07.5: 4 441 isolates against 4 431 under the alternative conflict rule. `docs/worked-examples/deduplication.md` |
| 06.3 | Isolate key | `(PATID, ELTID, isolate_id)` | collapse same species within sample | 213 triples split across several local isolate identifiers (historical `souche_id`), 214 extra isolates, 0.4 % |
| 06.4 | Result alphabet | ternary `S`, `SFP`, `R`; historical `I` and `ZIT` &rarr; `SFP`; individual `NA` defaults to not tested unless source information establishes otherwise | retain `I` as distinct 4th value | Historical Rouen 2024: 31 847 SFP, 1 028 ZIT, 279 I. Preserves historical continuity across CA-SFM 2022 transition |
| 06.5 | Resistance phenotypes | binary isolate attribute; absent phenotype signal = `FALSE` (SPARES Note Xa) | require explicit negative test or treat absence as `NA` | Rouen 2024: 99.55 % of C3G-susceptible *E. coli* have no BLSE row (8 636 / 8 675); treating absent as `NA` discards 90 % of wild-type isolates. `docs/worked-examples/phenotypes-and-screening.md` |
| 06.6 | CA-SFM validation | run metadata declaration; native tag inspection remains local | per-row rejection on raw `CASFM` | 100 % of Rouen 2022 rows carried `CASFM = "2019"` despite clinical 2020 compliance; per-row drop discards entire historical years <!-- citecheck: ok, decision row naming the CA-SFM version check; the CA-SFM/SPARES requirement is located in the TW-06.2 entry of tripwire-register.md --> |
| 06.7 | Diagnostic selection | local adapter classifies and applies diagnostic scope before the handoff; common audit accepts the prepared population | common raw-label heuristics or reclassification | Historical: `"recherche"` matches 80 700 rows across 118 tests in 2024, catching 6 231 gonococcal swabs, 18 969 *C. diff* tests, 2 519 malaria smears. `docs/worked-examples/phenotypes-and-screening.md` |
| 06.8 | Bacterial and antibiotic mappings | improve the previous ORCHIDEE mappings locally; common audit consumes prepared identities and inventories unassigned taxa | reinterpret local labels in the core or assume every previous entry correct | Existing mapping work is reused; no new measurement or dictionary validation is claimed. |

The boundary and mapping foundation are agreed design decisions. Historical
figures above do not validate the revised common audit or settle the remaining
mapping choices.

---

## Notes & Tripwires

### 06.5 note: Phenotypes in deduplication
In v2, BLSE and carbapenemase were treated as pseudo-molecules in the antibiotype vector.
At Rouen in 2024, treating phenotypes as molecules changed only 10 isolates across all
Enterobacterales (+4 *E. coli*, +3 *K. pneumoniae*). SPARES compares BLSE and
carbapenemase in deduplication and reads a blank phenotype cell as absent, unlike
a blank antibiotic cell, which is missing data (SPARES p. 11). ORCHIDEE therefore
treats phenotypes as isolate attributes, not as molecules, which avoids
artificial discrepancies driven by delayed confirmatory testing. Phenotype-AST biological plausibility
is guarded by [tripwire TW-06.1](tripwire-register.md#tw-06-1), whose full trigger conditions
and actions are defined in that register entry.

### 06.6 tripwire (TW-06.2)
**Statement**: The common audit checks the supplied declaration; native `CASFM`
tag inspection stays local. See `TW-06.2` in `tripwire-register.md` for the
existing version rule and current report-only response policy.
**Historical observation, not remeasured here**: 100 % of Rouen 2024 rows carry
`CASFM == "2022"`.

---

## Open

- **Mapping details**: exact antibiotic equivalences, bacterial species/complex
  treatment and target lists remain open where not already settled, using the
  previous mappings as the foundation. This revision neither implements an
  offline dictionary job nor approves particular entries.
- **Prepared-result counting**: Suite 6 records the remaining treatment of
  explicitly documented tests with no interpretable result in its antibiotic
  counts and coverage. This does not reopen supplied antibiogram eligibility
  or the individual `NA` default.

Local diagnostic selection and the supplied antibiogram population are settled
assumptions. They are not open questions about common classification, source
certification or publication of excluded screening counts.
