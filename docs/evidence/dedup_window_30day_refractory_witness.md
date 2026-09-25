# Empirical Witness for Deduplication Window Shape (Calendar vs. 30-Day Rolling Refractory Window)

**Status**: Settled empirical witness for Decision 07.2 (`docs/methods/07-dedoublonnage.md`).  
**Primary Dataset**: CHU de Rouen bacteriology diagnostic scope (`outputs/rouen_current/bundle_v3/sir_wide.rds`, 48,595 raw diagnostic records, 35 antibiotic columns).  
**Perimeter Exposure**: 355,246 Inpatient Days (JH) for Rouen 2024.  
**Issue Reference**: Issue #4 ("Empirical Witness for Deduplication Window Shape").

---

## 1. Context & Regulatory/Surveillance Standards

In bacteriological AMR surveillance, deduplication defines which bacterial isolates represent distinct clinical events rather than redundant sampling from the same infectious episode.

Two foundational traditions exist in European and French surveillance:

1. **SPARES / French National Tradition (Annual Calendar Window with Antibiotype Discrimination)**:
   - Defined in SPARES Methodology, Annexe 1: deduplication operates within the surveillance year (`format(DATEPRELEV, "%Y")`).
   - Duplicate definition: identical species, same specimen type, same patient, without major phenotypic discrepancy (`S <-> R` or `SFP/ZIT <-> R`).
   - Tie-breaker: oldest isolate if identical number of tested antibiotics; otherwise the isolate with more molecules tested.
   - *Limitation*: Collapses two separate episodes occurring 6 months apart into one, while artificially splitting an episode that crosses December 31 / January 1. Furthermore, slicing an annual window into monthly reports causes retrospective instability (`docs/worked-examples/deduplication.md`, Result 3).

2. **EARS-Net / ECDC European Tradition (Episode-Based / 30-Day Rolling Refractory Window)**:
   - EARS-Net Reporting Protocol (ECDC) historically mandates the first invasive isolate (blood/CSF) per patient per quarter or year for national aggregate resistance proportions.
   - For healthcare-associated infection (HAI) and bloodstream infection (BSI) surveillance (ECDC HAI-Net, European BSI surveillance, WHO GLASS, and UK ESPAUR), an **episode of infection** is standardized using a **30-day window**.
   - Standard literature (e.g., Ohmagari et al., *PLOS ONE* 2020 comparing WHO GLASS vs. JANIS 30-day deduplication across 1,795 hospitals; CDC NHSN 14-day Repeat Infection Timeframe) establishes that repeated isolates of the same pathogen recovered within a refractory timeframe belong to the same clinical episode.

---

## 2. Mathematical Formulation & Algorithmic Specification

### 2.1 The Non-Transitivity Problem & The Chaining Fallacy

In `docs/methods/07-dedoublonnage.md`, Decision 07.2 noted:
> *"same window" would stop being transitive — isolates at day 1, day 20 and day 40 with N=30 pair up inconsistently — which needs a sweep rule this document does not have.*

Formally, a predicate `same_window(i, j) = |date(i) - date(j)| <= 30` is **reflexive** and **symmetric**, but **not transitive**:
$$\text{date}(A) = 1, \quad \text{date}(B) = 20, \quad \text{date}(C) = 40$$
$$|20 - 1| \le 30 \implies A \sim B; \quad |40 - 20| \le 30 \implies B \sim C; \quad \text{yet } |40 - 1| = 39 > 30 \implies A \not\sim C.$$

If treated as an equivalence relation via connected components, any patient cultured every 20 days would chain into a single multi-year episode ("chaining fallacy").

### 2.2 The Solution: Ordered Chronological Sweep (Stateful Automaton)

The rolling refractory window is therefore implemented not as a static grouping partition, but as a deterministic **chronological sweep automaton**:

1. **Ordering Discipline**: Isolates for a given patient, species, and specimen scope are sorted chronologically:
   $$\text{Order by: } \text{DATEPRELEV} \uparrow, \; \text{HEUREPRELEV} \uparrow, \; \text{ELTID} \uparrow$$
2. **Episode Inception**: The initial isolate $i_0$ at $T_{\text{onset}} = \text{date}(i_0)$ opens an active refractory window:
   $$W = [T_{\text{onset}}, \; T_{\text{onset}} + 30\text{ days}]$$
3. **In-Window Evaluation**:
   - **Variant A (Pure EARS-Net / Time-Based Episode)**: Every isolate $i$ with $\text{date}(i) \in W$ is suppressed as a duplicate. (Tie-break variant: optionally replaces the index isolate if $i$ has more tested molecules, while anchoring $T_{\text{onset}}$ strictly to the initial sample date).
   - **Variant B (Phenotype-Aware / SPARES-Hybrid Rolling Refractory)**:
     For any isolate $i$ with $\text{date}(i) \in W$, compare $i$ against active retained isolates in $W$:
     - If compatible ($\text{major}(i, j) = \text{FALSE}$): $i$ is a duplicate. If $\text{ntest}(i) > \text{ntest}(j)$, $i$ replaces $j$ as the episode representative, but $T_{\text{onset}}$ is preserved.
     - If a major phenotypic discrepancy exists ($\text{major}(i, j) = \text{TRUE}$ for all active isolates in $W$): $i$ represents an emergence of resistance or polyclonal co-infection and is **retained**.
4. **Window Expiry & New Episodes**: The first isolate arriving at $\text{date}(k) > T_{\text{onset}} + 30\text{ days}$ closes the previous window and establishes a new refractory episode anchored at $\text{date}(k)$.

---

## 3. Empirical Results on Rouen Real Data (2024)

### 3.1 Slice 1: *Escherichia coli* Urines (Diagnostic Scope)

- **Total raw diagnostic isolates**: 4,963  
- **Distinct patients**: 4,039  

| Surveillance Model | Window Shape / Rule | Retained Isolates | $\Delta$ vs. Annual (SPARES) | $\Delta$ vs. Monthly | Incidence Density (/1 000 JH)* |
|---|---|---|---|---|---|
| **Model 1: Annual Calendar (SPARES)** | Calendar Year (`2024`), Phenotype-aware | **4 438** | Baseline | −375 (−7.79 %) | **12.49** |
| **Model 2: Monthly Calendar (Pooled)** | Calendar Month (`YYYY-MM`), Independent | **4 813** | +375 (+8.45 %) | Baseline | **13.55** |
| **Model 3A: 30d Rolling Refractory (Pure)** | 30-Day Window, First Isolate (EARS-Net) | **4 577** | +139 (+3.13 %) | −236 (−4.90 %) | **12.88** |
| **Model 3B: 30d Rolling Refractory (Pheno)** | 30-Day Window, Major Discrepancy (SPARES-Hybrid) | **4 718** | +280 (+6.31 %) | −95 (−1.97 %) | **13.28** |

*\*Incidence density evaluated over Rouen 2024 inpatient exposure (355 246 JH).*

#### Resistance Proportions on Key Antibiotics (*E. coli* Urines 2024)

| Antibiotic Molecule | Annual SPARES %R ($n / N_{\text{tested}}$) | Monthly Calendar %R ($n / N_{\text{tested}}$) | 30d Rolling (Pheno) %R ($n / N_{\text{tested}}$) | 30d Rolling (Pure) %R ($n / N_{\text{tested}}$) |
|---|---|---|---|---|
| **Amoxicilline-acide clavulanique** | 39.23 % (1 739 / 4 433) | 39.56 % (1 901 / 4 805) | 39.74 % (1 872 / 4 711) | 39.00 % (1 782 / 4 569) |
| **Ofloxacine** | 15.93 % (631 / 3 962) | 16.23 % (699 / 4 307) | 16.20 % (684 / 4 222) | 15.75 % (643 / 4 082) |
| **Ciprofloxacine** | 18.19 % (245 / 1 347) | 19.04 % (267 / 1 402) | 18.91 % (263 / 1 391) | 18.61 % (236 / 1 268) |
| **Céfotaxime** | 24.39 % (341 / 1 398) | 25.52 % (370 / 1 450) | 25.28 % (364 / 1 440) | 25.06 % (330 / 1 317) |
| **Cotrimoxazole (SXT)** | 28.80 % (1 270 / 4 409) | 29.09 % (1 390 / 4 778) | 29.19 % (1 368 / 4 686) | 28.26 % (1 284 / 4 543) |
| **Amoxicilline / Ampicilline** | 54.45 % (2 416 / 4 437) | 54.21 % (2 607 / 4 809) | 54.49 % (2 569 / 4 715) | 53.44 % (2 444 / 4 573) |

---

### 3.2 Slice 2: Blood Cultures (Bacteremia Scope 2024)

Blood cultures represent the primary surveillance specimen for EARS-Net and ConsoRes/SPARES bacteremia indicators.

| Organism / Pathogen | Raw Blood Isolates | Distinct Patients | Annual (SPARES) | Monthly (Calendar) | 30d Rolling (Pheno) | 30d Rolling (Pure EARS-Net) | $\Delta$ (30d Pheno vs Ann) | $\Delta$ (30d Pure vs Ann) |
|---|---|---|---|---|---|---|---|---|
| ***Escherichia coli*** | 672 | 530 | **570** | 588 (+3.16 %) | **584** (+2.46 %) | **551** (−3.33 %) | +14 | −19 |
| ***Staphylococcus aureus*** | 450 | 315 | **317** | 333 (+5.05 %) | **327** (+3.15 %) | **325** (+2.52 %) | +10 | +8 |
| ***Klebsiella pneumoniae*** | 158 | 120 | **138** | 143 (+3.62 %) | **140** (+1.45 %) | **128** (−7.25 %) | +2 | −10 |
| ***Enterobacter cloacae complex*** | 136 | 87 | **105** | 111 (+5.71 %) | **107** (+1.90 %) | **91** (−13.33 %) | +2 | −14 |
| ***Pseudomonas aeruginosa*** | 89 | 70 | **74** | 75 (+1.35 %) | **74** (+0.00 %) | **70** (−5.41 %) | 0 | −4 |
| ***Enterococcus faecalis*** | 179 | 150 | **150** | 157 (+4.67 %) | **152** (+1.33 %) | **152** (+1.33 %) | +2 | +2 |
| ***Enterococcus faecium*** | 72 | 49 | **51** | 53 (+3.92 %) | **52** (+1.96 %) | **51** (+0.00 %) | +1 | 0 |
| **ALL Blood Cultures (Total)** | **2 069** | **1 324** | **1 675** | **1 736** (+3.64 %) | **1 710** (+2.09 %) | **1 630** (−2.69 %) | **+35** | **−45** |

#### Key Pathogen Resistance Markers in Blood Cultures (2024)

- ***S. aureus* Oxacillin %R (SARM marker per Rule 4)**:
  - Annual: 6.94 % (22 / 317)
  - Monthly: 6.61 % (22 / 333)
  - 30d Rolling (Pheno): 6.73 % (22 / 327)
  - 30d Rolling (Pure): 6.77 % (22 / 325)
- ***E. coli* Céfotaxime (3GC) %R**:
  - Annual: 11.25 % (64 / 569)
  - Monthly: 11.75 % (69 / 587)
  - 30d Rolling (Pheno): 11.49 % (67 / 583)
  - 30d Rolling (Pure): 10.36 % (57 / 550)
- ***K. pneumoniae* Céfotaxime (3GC) %R**:
  - Annual: 18.12 % (25 / 138)
  - Monthly: 18.88 % (27 / 143)
  - 30d Rolling (Pheno): 18.57 % (26 / 140)
  - 30d Rolling (Pure): 17.19 % (22 / 128)
- ***P. aeruginosa* Ceftazidime %R**:
  - Annual: 13.51 % (10 / 74)
  - Monthly: 13.33 % (10 / 75)
  - 30d Rolling (Pheno): 13.51 % (10 / 74)
  - 30d Rolling (Pure): 11.43 % (8 / 70)

---

## 4. Key Methodological Discoveries & Analysis

### 4.1 Discovery 1: The Calendar Boundary Inflation Artifact

Monthly calendar deduplication artificially inflates episode counts by **+1.97 %** in urines (4,813 vs. 4,718) and **+1.50 %** in blood cultures (1,736 vs. 1,710) compared to a true 30-day refractory window.

**Mechanism**: If a patient is cultured on January 29 and again on February 2 (4 days apart, identical strain):
- In the **monthly calendar model**, January and February are processed independently. Both isolates survive. The patient is counted twice.
- In the **30-day rolling refractory model**, the February 2 sample falls within the 30-day refractory window of January 29 and is correctly suppressed as a duplicate.

### 4.2 Discovery 2: The Cross-Year Boundary Distortion

In annual calendar deduplication, the surveillance window terminates on December 31.
Measured on Rouen longitudinal data (2023–2024):
- Exactly **12 *E. coli* urine isolates** retained in early 2024 were within 30 days of an identical isolate from late December 2023.
- Annual calendar surveillance counts both isolates as distinct incident events, whereas a continuous 30-day rolling window recognizes them as a single ongoing episode.

### 4.3 Discovery 3: The Intra-Episode Resistance Emergence Blindspot (Pure vs. Phenotype-Aware)

A striking finding appears when comparing Pure EARS-Net (time-based) against Annual SPARES and Phenotype-Aware Rolling:
- In *E. coli* blood cultures, Pure 30-day EARS-Net retains **551 isolates**, which is **19 fewer isolates (−3.33 %)** than Annual SPARES (**570 isolates**) and **33 fewer** than Phenotype-Aware Rolling (**584 isolates**).
- In *Enterobacter cloacae complex* blood cultures, Pure 30-day EARS-Net retains **91 isolates** vs. **105 in Annual SPARES (−13.33 %)** and **107 in Phenotype-Aware Rolling**.

**Mechanism**: In severe bacteremic episodes, intensive beta-lactam therapy frequently selects for resistant sub-populations (e.g., AmpC derepression in *E. cloacae*, emergence of 3GC resistance in *E. coli*).
- Under **Pure EARS-Net**, the second sample taken 5 days later is strictly suppressed because it occurred within 30 days. The emergent resistance is completely invisible.
- Under **Phenotype-Aware (SPARES-Hybrid) Rolling**, the major phenotypic discrepancy (`S -> R`) overrides duplicate suppression. Both the wild-type and the resistant isolate are retained.
- Pure time-based deduplication systematically depresses resistance rates in acute hospital settings: *E. coli* 3GC %R is 10.36 % in Pure 30d vs. 11.49 % in Phenotype-Aware Rolling; *K. pneumoniae* 3GC %R is 17.19 % vs. 18.57 %.

---

## 5. Decision Resolution for Decision 07.2

With these empirical measurements, Decision 07.2 in `docs/methods/07-dedoublonnage.md` moves from **`unproven`** to **`settled`**:

1. **Retain Independent Monthly Windows for Closed Production Surveillance (Model 1)**:
   Independent monthly windows (`window = "monthly"`) prevent the retrospective instability where future hospitalizations alter past published monthly tables (`docs/worked-examples/deduplication.md`, Result 3).
2. **Standardize Target Annual / Longitudinal Surveillance on Phenotype-Aware 30-Day Rolling Refractory Windows (Model 3B)**:
   - Eliminates calendar boundary artifacts (both month-end straddling and Dec 31/Jan 1 resetting).
   - Provides true incidence density of infectious episodes (13.28 / 1,000 JH on *E. coli* urines, +6.31 % vs. annual calendar undercount).
   - Protects surveillance against intra-episode resistance selection, unlike pure time-based EARS-Net.

---

## 6. References & Primary Sources

1. **ECDC EARS-Net**: *Reporting Protocol for Antimicrobial Resistance Surveillance*, European Centre for Disease Prevention and Control.
2. **ECDC HAI-Net & BSI Surveillance Protocol**: *Surveillance of healthcare-associated infections in intensive care units and bloodstream infections in Europe*.
3. **WHO GLASS**: *Global Antimicrobial Resistance and Use Surveillance System: Manual for Early Implementation*, World Health Organization.
4. **Ohmagari et al. (2020)**: *Comparison of de-duplication methods used by WHO Global Antimicrobial Resistance Surveillance System (GLASS) and Japan Nosocomial Infections Surveillance (JANIS) in the surveillance of antimicrobial resistance*. PLoS ONE 15(10): e0240902.
5. **CLSI M39-A4**: *Analysis and Presentation of Cumulative Antimicrobial Susceptibility Test Data; Approved Guideline — Fourth Edition*, Clinical and Laboratory Standards Institute.
6. **SPARES Methodology**: *Surveillance de la Prévention de l'Antibiorésistance et des Infections Associées aux Soins*, Annexe 1 (Méthodologie du dédoublonnage), Santé publique France.
7. **ORCHIDEE Architecture**:
   - `docs/methods/07-dedoublonnage.md` (Decision 07.2)
   - `docs/worked-examples/deduplication.md` (Results 1, 2, and 3)
   - `docs/adr/0001-deduplication-is-parameterised.md`
