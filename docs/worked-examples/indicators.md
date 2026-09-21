# Worked example: Indicator construction and the blood culture deduplication hazard

Witness for decisions 08.1 through 08.8 in `docs/methods/08-indicateurs.md`.

**Slice**: Calendar year 2024, CHU de Rouen, SPARES-eligible perimeter (`CODE_TA ∈ {03, 20}` ∩ the ten SPARES DE domains), diagnostic scope (`ratb_diagnostic_scope == TRUE`), annual and monthly windows. Exposure denominator: **355 246 JH** (`midnight_presence`). Built from `outputs/rouen_current/bundle_v3/sir_wide.rds`, joined to `sample_scope_reference.rds` and `denominator_bundle.rds`. Reproduction: `indicators_witness.R`.

---

## 1. The specimen deduplication hazard: blood cultures (08.1)

Both SPARES and SPF specify resistance indicators for **all diagnostic samples pooled** and separately for **blood cultures** (*hémocultures* / bactériémies).

SPARES explicitly defines the deduplication scope for specimen-specific analyses:
> *« pour un même type de prélèvement à visée diagnostique [...] un seul prélèvement (le plus ancien) par type de prélèvement et par patient est conservé »*

This makes the specimen scope an **input to deduplication**. If an implementation instead runs global deduplication across all sample types first, and then filters the resulting table on `naturepvt == "hemoculture"`, legitimate bacteremias are erased:

| Organism | Approach A (input to dedup) | Approach B (post-filter) | Lost under B |
|---|---|---|---|
| *E. coli* blood cultures | **267** | **226** | **−41 (−15.36 %)** |
| *S. aureus* blood cultures | **216** | **139** | **−77 (−35.65 %)** |
| *S. aureus* SARM bacteremias | **15** (DI = 0.0422 / 1000 JH) | **10** (DI = 0.0281 / 1000 JH) | **−5 (−33.33 %)** |

### The preemption mechanism

Over a third of *S. aureus* bacteremias and 15 % of *E. coli* bacteremias disappear under post-filtering.

The mechanism is identical to the perimeter ordering hazard (decision 03.2):
A patient admitted to an eligible unit is sampled on day 1 (e.g. urine, superficial pus, sputum) yielding *S. aureus* or *E. coli*. On day 4, the patient deteriorates and blood cultures are drawn, growing the same organism with concordant antibiotype.

- **Approach A (specimen as input)**: Only blood cultures enter the deduplication pipeline. The day 4 blood culture is the patient's first blood culture and is retained. The patient contributes 1 to the blood culture numerator.
- **Approach B (specimen as post-filter)**: All samples enter deduplication together. The day 1 non-blood sample wins on the oldest-sample rule and becomes the patient's annual representative. The subsequent filter on blood cultures discards the representative, and the patient contributes 0. The true hospital-acquired bacteremia is completely erased.

> **Rule**: Specimen scoping is an input to deduplication, never a filter on its output.

---

## 2. Antibiotic group evaluation and testing coverage cascades (08.2, 08.4, 08.7)

SPF specifies indicators aggregated by **antibiotic group** (C3G, Fluoroquinolones, Carbapenems) evaluated using three-valued logic:
- **`R`**: At least one molecule in the group is reported `R`.
- **`Ø` (Empty set)**: No molecule in the group is documented (all untested or missing).
- **`S`**: At least one molecule is documented and none is `R` (`SFP` and `ZIT` count as `S`).

Measured on *E. coli*, 2024, eligible perimeter ($N = 2\,445$ deduplicated isolates):

| Antibiotic Group | R | S | Ø (Empty set) | Tested ($R + S$) | %R (Tested) | %R (Diluted / 2445) |
|---|---|---|---|---|---|---|
| **C3G** (CTX, CRO, CAZ) | 218 | 2 221 | 6 | 2 439 (99.8 %) | **8.94 %** | 8.92 % |
| **Fluoroquinolones** (OFL, LVX, CIP, MXF) | 342 | 2 097 | 6 | 2 439 (99.8 %) | **14.02 %** | 13.99 % |

### The cascade coverage trap

In hospital microbiology, individual molecules are tested selectively via laboratory cascade rules. Looking at individual molecules without group aggregation or testing coverage creates severe clinical distortions:

| Molecule | Tested isolates | Testing coverage | R isolates | %R |
|---|---|---|---|---|
| Céfotaxime (CTX) | 1 372 | 56.1 % | 203 | 14.80 % |
| Ceftriaxone (CRO) | 1 086 | 44.4 % | 3 | 0.28 % |
| Ceftazidime (CAZ) | 2 439 | 99.8 % | 185 | 7.59 % |
| **C3G Group** | **2 439** | **99.8 %** | **218** | **8.94 %** |

Ceftriaxone has a published resistance rate of **0.28 %**, but was only tested on 44.4 % of isolates (at Rouen, ceftriaxone is tested primarily on specific panels where wild-type susceptibility is anticipated). A reader observing only ceftriaxone %R would believe C3G resistance is negligible. Evaluating the group unifies coverage to 99.8 % and captures the true 8.94 % resistance rate.

### Tested denominator vs diluted denominator (08.4)

For antibiotics tested selectively or for specific clinical indications (e.g. urinary antiseptics or second-line agents), dividing by total isolates dilutes the resistance proportion by untested strains:

| Molecule | Tested ($R+S$) | Tested %R | Total isolates | Diluted %R | Distortion |
|---|---|---|---|---|---|
| Fosfomycine trométamol | 431 | **3.02 %** (13/431) | 2 445 | 0.53 % (13/2445) | −2.49 pp (×5.7 dilution) |
| Nitrofurantoïne | 1 784 | **0.73 %** (13/1784) | 2 445 | 0.53 % (13/2445) | −0.20 pp |
| Imipénème | 1 485 | **0.20 %** (3/1485) | 2 445 | 0.12 % (3/2445) | −0.08 pp |

ORCHIDEE strictly divides %R numerators by **tested isolates**, and publishes `tested_isolates`, `total_isolates`, and `coverage_pct` on every row.

---

## 3. Phenotype indicators and the Note Xa denominator (08.6)

For resistance phenotypes (BLSE, Carbapenemase), SPARES Note Xa establishes:
> *« En l'absence de mention d'un phénotype de résistance BLSE ou carbapénémase, celui-ci est considéré comme négatif. »*

This reflects clinical laboratory workflow: wild-type susceptible strains never receive reflex confirmatory phenotype tests.

Comparing *E. coli* BLSE under Note Xa against an explicit-test-only denominator:

| Rule | Numerator | Denominator | BLSE % | Note |
|---|---|---|---|---|
| **Under Note Xa** (species denominator) | **186** | **2 445** (all deduplicated *E. coli*) | **7.61 %** | Reflects epidemiological prevalence (matches ConsoRes 8.2 % on wider extract) |
| **Explicit test rows only** | 186 | 224 (186 positive + 38 negative) | **83.04 %** | **+75.43 pp distortion**; captures only reflex confirmatory tests on resistant strains |

Treating absent phenotype tests as missing data ($NA$) inflates BLSE rates by a factor of 11 because 99.55 % of susceptible strains carry no phenotype row.

---

## 4. SARM methicillin rule and laboratory surrogate handling (08.3)

For *S. aureus* methicillin resistance (SARM), SPF Annexe 3 footnote 2 establishes the marker precedence:
> *« En cas de discordance entre les résultats céfoxitine et oxacilline, le résultat de la céfoxitine est conservé. »*

Under EUCAST and French laboratory guidelines, cefoxitine is the preferred phenotypic surrogate for *mecA/mecC* resistance, but clinical laboratories may export oxacilline depending on local testing panels and LIS configurations. ORCHIDEE enforces the SPF rule:
1. **Primary marker**: Cefoxitine interpretation if tested.
2. **Surrogate fallback**: Oxacilline interpretation if cefoxitine is untested.
3. **Tripwire verification (TW-08.1)**: If an isolate is co-tested for both, cefoxitine takes precedence and any discordance is flagged for clinical review.

On Rouen 2024 eligible *S. aureus* ($N = 1\,100$ deduplicated isolates):
- Cefoxitine was not included in Rouen's routine *S. aureus* panel (all cefoxitine tests at Rouen are deployed on Enterobacterales as an AmpC marker).
- Oxacilline is Rouen's routine clinical AST marker for *S. aureus*: **1 093 tested** (84 R, 1 009 S), with 7 untested isolates.
- SARM prevalence under the surrogate fallback rule: **84 / 1 093 tested (7.69 %)**; slice incidence density = **0.236 / 1 000 JH**.
- Tripwire `TW-08.1` monitors co-tested discordances (trivially 0 here since cefoxitine is absent, but fully active for multi-center sites testing both).

---

## 5. Small numbers in monthly and sector stratifications (08.8)

SPF requests monthly frequency stratified by activity sector. When slicing *E. coli* monthly across Rouen's 9 discipline sectors (92 non-empty sector-month cells in 2024):
- Minimum cell size: 1 isolate
- 1st Quartile: 5 isolates
- Median cell size: 18 isolates
- **Cells with $n < 5$ isolates: 22 / 92 (23.9 %)**
- **Cells with $n < 10$ isolates: 33 / 92 (35.9 %)**

For lower-volume pathogens (*P. aeruginosa*, *E. faecalis*, *E. cloacae*), over 50 % of monthly sector cells hold fewer than 5 isolates.

If database suppression were applied, more than a third of the surveillance time-series would be censored. ORCHIDEE enforces **zero cell suppression in the core indicator table**: every row carries `numerator`, `denominator`, and `value`. Presentation masking is strictly a reporting/UI concern.

---

## 6. Full 2024 Rouen Indicator Baseline

Computed across all SPARES target organisms on the perimeter-correct denominator (**355 246 JH**):

| Taxon | Deduplicated Isolates | Target Group / Molecule | Tested ($R+S$) | %R | Incidence Density (/1 000 JH) |
|---|---|---|---|---|---|
| *E. coli* | 2 445 | C3G | 2 439 | 8.94 % | 0.614 |
| *E. coli* | 2 445 | Fluoroquinolones | 2 439 | 14.02 % | 0.963 |
| *E. coli* | 2 445 | Carbapénèmes | 2 440 | 0.29 % | 0.020 |
| *E. coli* | 2 445 | BLSE (Note Xa) | 2 445 | 7.61 % | 0.524 |
| *K. pneumoniae* | 517 | C3G | 517 | 28.24 % | 0.411 |
| *K. pneumoniae* | 517 | Fluoroquinolones | 517 | 24.37 % | 0.355 |
| *K. pneumoniae* | 517 | BLSE (Note Xa) | 517 | 19.34 % | 0.281 |
| *E. cloacae complex* | 441 | C3G | 436 | 43.35 % | 0.532 |
| *E. cloacae complex* | 441 | BLSE (Note Xa) | 441 | 19.73 % | 0.245 |
| *S. aureus* | 1 100 | SARM (Cefoxitine / Oxacilline) | 1 093 | 7.69 % | 0.236 |
| *P. aeruginosa* | 558 | Carbapénèmes (IPM/MEM) | 547 | 16.45 % | 0.253 |
| *P. aeruginosa* | 558 | Ceftazidime | 554 | 19.49 % | 0.304 |
| *P. aeruginosa* | 558 | Pipéracilline-tazobactam | 554 | 20.40 % | 0.318 |
| *E. faecalis* | 523 | Vancomycine | 506 | 0.00 % | 0.000 |
| *E. faecium* | 289 | Vancomycine (ERV) | 278 | 0.36 % | 0.003 |

### Five National Strategy Indicators (SPF 2022–2025)

1. **DI toutes EPC / 1 000 JH** (tous prélèvements diagnostiques): **31 cases | 0.0873 / 1 000 JH**
2. **DI *K. pneumoniae* C3G-R / 1 000 JH**: **146 cases | 0.4110 / 1 000 JH**
3. **DI *K. pneumoniae* BLSE / 1 000 JH**: **100 cases | 0.2815 / 1 000 JH**
4. **Proportion EPC chez *K. pneumoniae* hémocultures**: **3.61 %** (3 / 83) [under Note Xa / ADR-0005]
5. **Proportion ERV chez *E. faecium* hémocultures**: **0.00 %** (0 / 38 tested)

