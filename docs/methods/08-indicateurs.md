# 08 - Indicator construction

Status: **settled**. Eight decisions, eight witnesses, one tripwire. Zero unproven.

---

## What SPARES says

> Les données de résistances bactériennes sont analysées après dédoublonnage par
> l'application ConsoRes. Pour une même souche, l'analyse ne prend en compte qu'un
> prélèvement par patient selon le type de recherche souhaitée :
> • analyse des résistances par type de prélèvement : les doublons « prélèvement » sont
> exclus, un seul prélèvement (le plus ancien) par type de prélèvement et par patient,
> est conservé ;
> • analyse globale des résistances tous types de prélèvements confondus : seul un
> prélèvement par patient est conservé, le plus ancien quel que soit le type de prélèvement.

> Note Xa : En l'absence de mention d'un phénotype de résistance BLSE ou carbapénémase,
> celui-ci est considéré comme négatif.

---

## What SPF asks

### 1. Antibiotic groups and evaluation logic

A result per bacterium and per **antibiotic group**, evaluated under three-valued logic:
- **`R`** if at least one molecule in the group is rendered R;
- **`Ø` (empty set)** if no molecule in the group is documented;
- **`S`** otherwise (includes sensible and sensible à forte posologie `SFP`).

> En cas de discordance entre les résultats céfoxitine et oxacilline, le résultat de la
> céfoxitine est conservé. (Annexe 3, note 2)

### 2. Standard indicator definitions

For all diagnostic samples pooled and separately for blood cultures (*hémocultures*):

- **Proportion of resistance (%R)**:
  $$\frac{\text{nombre de souches du micro-organisme résistantes à une classe d'ATB}}{\text{nombre de souches du micro-organisme testées pour cet antibiotique}}$$

- **Incidence density (DI)**:
  $$\frac{\text{nombre de souches du micro-organisme résistantes à une classe d'ATB}}{\text{nombre total de journées d'hospitalisation}} \times 1000$$

> nous souhaiterions recevoir, pour tous les indicateurs agrégés demandés, le
> numérateur et dénominateur utilisés (le nombre de souches avec une résistance, le
> nombre de souches testés, le nombre total de JH).

### 3. Five national strategy indicators (2022–2025)

1. **DI toutes Enterobacterales productrices de carbapénémases / 1 000 JH** (tous prélèvements).
2. **DI *K. pneumoniae* résistantes aux C3G / 1 000 JH** (tous prélèvements).
3. **DI *K. pneumoniae* productrices de BLSE / 1 000 JH** (tous prélèvements).
4. **Proportion de souches productrices de carbapénémases chez *K. pneumoniae* isolées d'hémocultures**.
5. **Proportion de souches résistantes à la vancomycine chez *E. faecium* isolées d'hémocultures**.

---

## What ORCHIDEE does

### 1. The Indicator Table as the Primary Deliverable

The **indicator table** is the primary deliverable: a single unified, tall relational table
holding one row per indicator, period, stratum, and sample scope.

Each row carries:
- `indicator_id`, `bacterium`, `antibiotic_group`
- `period_grain` (`annual`, `monthly`), `period`
- `stratum_dimension` (`overall`, `discipline_sector`, `department`), `stratum_value`
- `sample_scope` (`all_diagnostic`, `hemoculture`)
- `numerator`, `denominator`, `indicator_value`
- `tested_isolates`, `total_isolates`, `coverage_pct`
- Provenance metadata: `exposure_profile` (`midnight_presence`, `hours`), `perimeter_version`, `deduplication_hash`

Reports and dashboards consume this table and contain no business calculations of their own.

### 2. The Empty Set and Tested Coverage Transparency

The empty set ($\emptyset$) is **materialised and counted**, never treated as susceptible or
dropped silently. It represents the *observed absence of testing*.

- In a **resistance proportion (%R)**, an isolate with $\emptyset$ leaves the denominator: the
  denominator is strictly `tested_isolates` ($R + S$).
- In an **incidence density (DI)**, the isolate remains part of the exposed population, while
  the denominator is the perimeter-matched hospitalisation exposure ($JH$).
- **Testing coverage** is published as an explicit contract column:
  $$\text{coverage\_pct} = \frac{\text{tested\_isolates}}{\text{total\_isolates}} \times 100$$
  This protects consumers from mistaking selective cascade reporting (e.g. ceftriaxone tested
  on only 44.4 % of isolates with %R = 0.28 %) for universal bacterial susceptibility.

### 3. Specimen Scopes as Inputs to Deduplication

In accordance with SPARES methodology and the general non-monotone rule established in
`07-dedoublonnage.md`:

> **Any selection on isolates is an input to deduplication, never a filter on its output.**

For blood culture indicators, isolates are filtered to `naturepvt == "hemoculture"` **before**
deduplication. Deduplicating globally across all sample types and post-filtering on blood culture
erases **35.6 % of *S. aureus* bacteremias** (77 isolates) and **15.4 % of *E. coli* bacteremias**
(41 isolates) due to preemption by prior non-blood samples.

### 4. Resistance Phenotypes and Note Xa

For BLSE, carbapenemase, and vancomycin resistance mechanisms, an absent laboratory test signal
is interpreted as negative (`FALSE`) per SPARES Note Xa. The proportion denominator is the
**total deduplicated population of that species**, not just isolates with an explicit confirmatory
test row. Restricting the denominator to explicit tests distorts *E. coli* BLSE from **7.61 % to 83.04 %**.

### 5. Exposure Denominator Matching (Inherited Invariant)

Incidence density divides strictly by the **exposure derived from movement intervals** for the
matching perimeter, as settled in `04-donnees-activite.md` (decisions 04.1 and 04.7). Section 08
does not define a new exposure measure; it consumes the exposure table produced under Section 04.
The comparability witness at Rouen in 2024 uses the `midnight_presence` profile (**355 246 JH**,
decision 04.3); using the canonical `occupancy hours` profile (**356 492 JH**, decision 04.2) yields
an identical rounded rate of 0.236 / 1 000 JH.

### 6. Zero-Suppression Policy

In monthly sector stratifications, 23.9 % of cells have $n < 5$ and 35.9 % have $n < 10$.
ORCHIDEE enforces **zero cell suppression in the core indicator table**: every cell publishes
its exact numerator and denominator. Privacy masking or presentation thresholds are strictly
delegated to visualization consumers (Section 09).

---

## Decisions

All witnesses measured on Rouen 2024 bacteriology data (`outputs/rouen_current/bundle_v3/sir_wide.rds`)
and interval-derived exposure (**355 246 JH**). Method and reproduction:
`docs/worked-examples/indicators.md` and `docs/worked-examples/indicators_witness.R`.

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 08.1 | Specimen scope deduplication | Specimen scope is an **input** to deduplication (per SPARES text) | Deduplicate globally, then filter specimen | *E. coli* blood cultures: **267 vs 226 (−41, −15.4 %)**; *S. aureus* blood cultures: **216 vs 139 (−77, −35.6 %)**, SARM bacteremias: **15 vs 10 (−33.3 %)**. `docs/worked-examples/indicators.md` |
| 08.2 | Group evaluation alphabet | Ternary logic: `R` if any R; `Ø` if no molecule documented; `S` otherwise (`SFP` and `ZIT` count as `S`) | Require all molecules tested, or treat untested as missing | *E. coli* C3G: 218 R, 2221 S, 6 Ø. Universal coverage (99.8 %) despite single molecules tested at only 44.4–56.1 % |
| 08.3 | SARM methicillin rule | Cefoxitine precedence over oxacilline in case of discordance (SPF Annexe 3 note 2) | Any R = R (naive group logic) | 84 SARM in eligible perimeter; 0 discordances at Rouen in 2024 (84 Fox-R / 1009 Fox-S / 7 NA). Guarded by tripwire |
| 08.4 | Resistance proportion denominator | Count of **tested** isolates (`R + S`), strictly excluding the empty set `Ø` | Total isolates of the species (treating Ø as S) | For targeted/reflex antibiotics (e.g. fosfomycine cov 17.6 %): %R is **3.02 %** (13/431) vs diluted **0.53 %** (13/2445) |
| 08.5 | Phenotype proportion denominator | Total deduplicated isolates of that taxon; absent phenotype = negative (`FALSE`) per SPARES Note Xa | Explicit-test-only denominator | *E. coli* BLSE: **7.61 %** (186 / 2445) under Note Xa vs **83.04 %** (186 / 224) if restricted to explicit test rows |
| 08.6 | Testing coverage transparency | Materialised on every indicator row (`tested_isolates`, `total_isolates`, `coverage_pct`) | Suppressed or hidden | Ceftriaxone %R is 0.28 % but coverage is only 44.4 %; without coverage, selective cascade reporting creates false clinical confidence |
| 08.7 | Small numbers handling | No cell suppression in the core indicator table; numerator and denominator always published | Cell suppression (masking n < 5 or n < 10) | At monthly sector level, 23.9 % of cells have n < 5 and 35.9 % have n < 10. Suppression breaks time-series trend modeling and auditability |
| 08.8 | Primary deliverable architecture | Single unified, tall indicator table with explicit dimensions, scopes, and provenance hash | Disparate separate tables per frequency / stratification | Unifies ratb indicators; guarantees identical schema across surveillance campaigns |

Unproven: **0 of 8**.

---

## Notes & Tripwires

### 08.1 note — the preemption of secondary bacteremias

When deduplication is run globally across all sample types, a patient who has a urine, wound, or
sputum sample on day 1 and develops bacteremia on day 4 will have the day 1 sample selected by the
oldest-sample rule. Post-filtering on blood cultures discards the representative, erasing the
hospital-acquired bacteremia entirely.

This explains why SPARES explicitly prescribed:
> *« analyse des résistances par type de prélèvement : les doublons « prélèvement » sont exclus,
> un seul prélèvement (le plus ancien) par type de prélèvement et par patient, est conservé »*

Feeding the specimen filter as an input to deduplication is required to prevent preemption.

### 08.3 tripwire (TW-08.1) — SARM marker concordance

**Statement**: Cefoxitine and oxacilline tests on *S. aureus* never yield discordant clinical interpretations. (Cataloged as `TW-08.1` in `tripwire-register.md`).
**Today**: Rouen 2024 has 1 093 cefoxitine tests and 91 oxacilline tests. All 91 co-tested isolates are
100 % concordant (84 R / 7 S). Discordances = **0**.

The tripwire fails if a site records an isolate with `cefoxitine == "S"` and `oxacilline == "R"` or vice versa,
verifying that cefoxitine precedence remains active.

### 08.6 note — why routine laboratory workflow necessitates Note Xa

In French hospital bacteriology, wild-type susceptible Enterobacterales do not trigger phenotypic
synergy testing (double-disk synergy) or PCR testing. A wild-type *E. coli* has no entry in the laboratory
system for BLSE. Treating an absent record as missing data ($NA$) restricts the denominator to strains
that triggered reflex testing (which are overwhelmingly resistant), turning a 7.6 % BLSE prevalence
into an alarming 83.0 % artifact.

### 08.8 note — database transparency vs presentation masking

Statistical disclosure control (SDC) guidelines recommend suppressing cells with $n < 5$ or $n < 10$ in
publicly facing reports to prevent patient re-identification. Applying suppression inside the database
is catastrophic: it destroys additivity, prevents monthly-to-annual roll-ups, and prevents audits.
ORCHIDEE's contract guarantees unmasked counts in the core indicator table; suppression is strictly a
presentation-layer concern.

---

## Open

None. All 8 indicator construction decisions are settled with empirical witnesses measured on Rouen 2024 raw data.
Medium-term stratification additions (age, sex, infection site) requested by SPF will reuse the
`stratum_dimension` / `stratum_value` architecture established in decision 08.8 without schema breakage.
