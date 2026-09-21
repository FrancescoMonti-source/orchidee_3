# 06 - Bacterial resistance data

Status: **settled**. Eight decisions, seven witnesses, one tripwire. Zero unproven.

## What SPARES says

> Seules les souches isolées d'un prélèvement à visée diagnostique ayant fait l'objet
> d'un antibiogramme sont incluses. Les prélèvements à visée écologique (dépistage,
> colonisation, portage) sont exclus.

> Chaque isolat est caractérisé par un patient source, une date et un site de
> prélèvement, un antibiotype, et pour les entérobactéries un phénotype de résistance
> (BLSE, carbapénémase). Pour chaque molécule testée, le résultat est S, SFP ou R.

> Seuls les antibiogrammes interprétés selon les recommandations du CA-SFM/EUCAST
> 2020 ou postérieures sont acceptés.

> Note Xa : En l'absence de mention d'un phénotype de résistance BLSE ou carbapénémase,
> celui-ci est considéré comme négatif.

## What ORCHIDEE does

### 1. Isolate identity
An **isolate** is identified by `(PATID, ELTID, souche_id)`. `souche_id` (or `DLVL` in
raw GLIMS exports) distinguishes separate strains recovered from the same sample.
`EVTID` is retained for stay attribution and grouping witnesses.

### 2. Screening exclusion and site boundary
**Screening is excluded** at population selection: after ingestion and before
deduplication. Screening rows are ingested and marked via the boolean contract key
`diagnostic_scope`, never dropped during extraction, allowing ORCHIDEE to publish
exact excluded counts.

Screening vs diagnostic classification is strictly a **site adapter responsibility**
(ADR 0003). In French hospital bacteriology, `"Recherche de [X]"` is the standard
prefix for both screening orders and targeted infectious diagnostics. Core ORCHIDEE
never executes blanket text searches (e.g. `grepl("recherche")`), which corrupt
diagnostic data.

### 3. Result alphabet
For every tested molecule, clinical categories are mapped to a strict ternary alphabet:
- **`S`** (sensible à posologie standard)
- **`SFP`** (sensible à forte posologie / intermédiaire)
- **`R`** (résistant)
- **`NA`** (untested, missing, or uninterpretable tokens such as `NC` / `Non côté`)

Historical results with `I` (CA-SFM &le; 2022) are read as `SFP`. Measurement caveat
`ZIT` (zone d'incertitude technique) is read as `SFP`.

### 4. Resistance phenotypes (BLSE, Carbapenemase)
For Enterobacterales (and carbapenemase in *P. aeruginosa* and *A. baumannii*),
resistance phenotypes are modeled as **binary isolate attributes** (`TRUE` / `FALSE`),
not as antibiotic rows.

The site adapter maps local laboratory signals (confirmatory tests, expert comments,
disk synergy rows) into `blse` and `carbapenemase`. In accordance with clinical
laboratory practice and SPARES Note Xa, an **absent signal is interpreted as negative
(`FALSE`)**. Wild-type susceptible strains do not trigger confirmatory testing in
routine practice.

During deduplication, comparison operates on the antibiotic panel. Within a deduplicated
patient-sample cluster, positive phenotype status is propagated (`any(positive) -> TRUE`).

### 5. CA-SFM referential validation
Compliance with CA-SFM &ge; 2020 is established via **site run metadata declaration**
supported by an **ingestion tripwire** on the raw `CASFM` column (when present,
&ge; 2020 expected for surveillance data from 2024 onward). ORCHIDEE never executes
row-level drops on historical data where laboratory dictionary tags lagged behind clinical
reporting.

### 6. Bacterial taxonomy
Ingestion accepts open raw organism descriptions. A standardized dictionary maps raw
taxa to the target ONERBA/SPARES species list. Unmapped isolates are logged and counted.
Taxonomic mapping expansion is decoupled from pipeline execution and delegated to an
offline LLM batch harmonization pipeline.

---

## Decisions

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 06.1 | Screening samples | excluded before deduplication | included | +5.6 % isolates; céfotaxime 16.96 &rarr; 25.19 %R (+8.23 pp); ertapénème x4.3. `docs/worked-examples/screening-exclusion.md` |
| 06.2 | `ZIT` against `SFP` | `ZIT` is read as `SFP`, per SPF text | `ZIT` treated as missing data | see 07.5: 4 438 isolates against 4 428. `docs/worked-examples/deduplication.md` |
| 06.3 | Isolate key | `(PATID, ELTID, souche_id)` | collapse same species within sample | 213 triples split across several `souche_id`, 214 extra isolates, 0.4 % |
| 06.4 | Result alphabet | ternary `S`, `SFP`, `R`; historical `I` and `ZIT` &rarr; `SFP`; non-interpretive &rarr; `NA` | retain `I` as distinct 4th value | Rouen 2024: 31 847 SFP, 1 028 ZIT, 279 I. Preserves historical continuity across CA-SFM 2022 transition |
| 06.5 | Resistance phenotypes | binary isolate attribute; absent signal = `FALSE` (SPARES Note Xa) | require explicit negative test or treat absence as `NA` | Rouen 2024: 99.55 % of C3G-susceptible *E. coli* have no BLSE row (8 636 / 8 675); treating absent as `NA` discards 90 % of wild-type isolates. `docs/worked-examples/phenotypes-and-screening.md` |
| 06.6 | CA-SFM validation | run metadata declaration + ingestion tripwire | per-row rejection on raw `CASFM` | 100 % of Rouen 2022 rows carried `CASFM = "2019"` despite clinical 2020 compliance; per-row drop discards entire historical years |
| 06.7 | Screening contract | sample-level boolean `diagnostic_scope` from site adapter | internal string heuristics (`"recherche"`, `"rectal"`) | `"recherche"` matches 80 700 rows across 118 tests in 2024, catching 6 231 gonococcal swabs, 18 969 *C. diff* tests, 2 519 malaria smears. `docs/worked-examples/phenotypes-and-screening.md` |
| 06.8 | Bacterial scope | open ingestion &rarr; ONERBA standard mapping &rarr; counted residual | closed hardcoded filter | isolates outside target species logged and surfaced; mapping dictionary maintained via offline LLM batch job |

Unproven: **0 of 8**.

---

## Notes & Tripwires

### 06.5 note: Phenotypes in deduplication
In v2, BLSE and carbapenemase were treated as pseudo-molecules in the antibiotype vector.
At Rouen in 2024, treating phenotypes as molecules changed only 10 isolates across all
Enterobacterales (+4 *E. coli*, +3 *K. pneumoniae*). Adhering to strict SPARES
specifications (comparing only genuine antibiotic molecules) avoids artificial
discrepancies driven by delayed confirmatory testing. Phenotype-AST biological plausibility
is guarded by tripwire `TW-06.1` (see `tripwire-register.md`).

### 06.6 tripwire (TW-06.2)
**Statement**: Ingestion checks that raw `CASFM` &ge; 2020 on surveillance data from 2024 onward. (Cataloged as `TW-06.2` in `tripwire-register.md`).
**Today**: 100 % of Rouen 2024 rows carry `CASFM == "2022"`.

---

## Open

None. Section 06 is fully settled.
- **Site screening coding variance**: As documented in `docs/worked-examples/screening-exclusion.md`,
  differences in how hospital LISs categorize borderline screening samples directly impact
  resistance rates. This cannot be resolved centrally by heuristics; ORCHIDEE publishes
  the exact volume of excluded screening samples alongside resistance indicators so that
  inter-hospital comparisons remain transparent and auditable.
- **Taxonomy dictionary maintenance**: Target taxonomy mapping from local laboratory
  microorganism strings to ONERBA standard codes is scheduled as an offline LLM batch job.
