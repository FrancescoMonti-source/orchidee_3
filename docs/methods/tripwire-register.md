# Dynamic Pipeline Tripwire Register

Status: **settled**. Seven active tripwires, zero unproven, verified against Rouen 2024 baseline data.

---

## 1. Principles of Tripwire Architecture

In the ORCHIDEE architecture, a **tripwire** is an automated runtime verification on a
statement that is true today, designed to fail on the day it stops being true (`CONTEXT.md`).

A tripwire is used instead of a runtime parameter when two interpretations or data readings
are known to agree today, but where silent divergence must be actively detected. Maintaining
parallel execution branches forever is expensive and error-prone; trusting an assumption
silently is hazardous. A tripwire provides automated alerting at zero operational overhead
during normal execution.

### Tripwire Severity and Action Policy

Every tripwire in ORCHIDEE defines an explicit trigger condition and an action policy:

1. **Blocking (Pipeline Refusal)**:
   Triggered when data violates physical invariants or foundational contracts (e.g. ambiguous
   temporal grain that would systematically distort intra-hospital exposure comparisons). The
   pipeline halts ingestion until the site adapter rectifies the handoff.
2. **Non-blocking with Recorded Acknowledgement (Quality Ledger)**:
   Triggered when data diverges from historical expectations or standard baselines, but where
   the divergence may represent a legitimate hospital reorganization (e.g. ward closure, new
   microbiology panel, or clinical emergence). A non-blocking tripwire never silently halts
   production; instead, it logs the event in the pre-flight quality ledger (`00-audit-qualite.md`)
   and requires an explicit signed acknowledgement before publication ("converts *nobody noticed*
   into *someone signed*").

---

## 2. Master Catalog of Dynamic Tripwires

| Tripwire ID | Name | Pipeline Stage | Target Scope | Action Policy | Rouen 2024 Witness |
|---|---|---|---|---|---|
| **TW-04.1** | Unit Denominator Annual Stability | Exposure derivation | PMSI movement exposure | Non-blocking (acknowledgement) | Denominators: 327 301 / 347 303 / 355 246 JH (2022–2024) |
| **TW-04.2** | Timestamp Grain Resolution | Ingestion & pre-flight audit | Movement timestamps (`DATENT`, `DATSORT`) | Blocking refusal | Rouen: 4.11 % `DATENT`, 4.08 % `DATSORT` at 00:00 (clean `datetime`) |
| **TW-05.1** | Structure Snapshot Referential Coverage | Referential linkage | UFs in movement and laboratory data | Non-blocking (divergence ledger) | Admin 362/362 (100 %); lab 272/278 UFs (99.9 % observations) |
| **TW-06.1** | Resistance Flags and Antibiotic Test Results | Ingestion & pre-flight audit | BLSE/carbapenemase flags vs antibiotic results | Non-blocking warning; discordant results quarantined, missing results logged | 99.55 % concordance on absent BLSE / C3G-S; 0 wild-type BLSE+ |
| **TW-06.2** | CA-SFM Interpretation Version Referential | Ingestion & pre-flight audit | Antibiogram interpretation standard | Ingestion warning / blocking on $\ge 2024$ | 100 % of Rouen 2024 rows carry `CASFM == "2022"` |
| **TW-07.1** | Antibiotype Panel Deduplication Parity | Deduplication | Antibiotype panel molecules | Non-blocking (divergence ledger) | 4 438 isolates under full panel vs 4 438 under SPARES panel |
| **TW-08.1** | SARM Marker Concordance | Indicator construction | *S. aureus* Cefoxitine vs Oxacilline | Non-blocking (enforces Fox precedence) | 91 co-tested isolates: 84 R/R, 7 S/S, exactly 0 discordances |

---

## 3. Detailed Specifications

### TW-04.1 — Unit Denominator Annual Stability

- **Identifier**: `TW-04.1`
- **Pipeline Stage**: Exposure derivation (`04-donnees-activite.md`, Decision 04.10)
- **Statement**: No clinical unit's eligible patient-days move by more than $\pm 30\,\%$
  year-over-year without explicit site acknowledgement.
- **Rationale & Risk**: A sudden drop or surge in a unit's patient-days indicates potential
  data extraction errors, missing PMSI files, or unnotified ward closures. A blocking check
  is unacceptable because hospitals genuinely open or merge wards; non-blocking acknowledgement
  guarantees institutional accountability without blocking publication.
- **Trigger Condition**:
  $$\left|\frac{\text{JH}_{u, \text{year}} - \text{JH}_{u, \text{year}-1}}{\text{JH}_{u, \text{year}-1}}\right| > 0.30$$
  evaluated for every functional unit $u$ belonging to the eligible SPARES perimeter.
- **Action on Trip**: Warning raised in the exposure report; requires explicit recorded
  acknowledgement from the site epidemiologist to validate the annual run.
- **Rouen Baseline Witness**: Rouen eligible hospitalisation days progressed steadily from
  327 301 (2022) to 347 303 (2023) and 355 246 (2024), while unfiltered raw days contracted
  sharply (1 016 036 to 564 968) due to ambulatory data warehouse realignment. Zero eligible
  wards breached $\pm 30\,\%$ without recorded structural reorganization.

---

### TW-04.2 — Timestamp Grain Resolution

- **Identifier**: `TW-04.2`
- **Pipeline Stage**: Ingestion & pre-flight audit (`00-audit-qualite.md`, Decision 00.4;
  `04-donnees-activite.md`, Decision 04.9)
- **Statement**: The observed distribution of timestamps falling at exactly `00:00:00` matches
  the site's declared resolution (`datetime` or `date`).
- **Rationale & Risk**: On pure date-only movements, occupancy hours divided by 24 simplifies
  identically to midnight presence ($\frac{\text{hours}}{24} \equiv \text{days}$). However, if
  a hospital delivers mixed-resolution data (e.g. intensive care with real hours and general
  wards defaulted to `00:00:00`), calculating occupancy hours introduces systematic intra-hospital
  exposure bias. Intermediate distributions (~40 % at midnight) represent corrupted or
  partially defaulted extracts and must not be silently accepted.
- **Trigger Condition**:
  - If declared `datetime`: Proportion of `DATENT` or `DATSORT` at `00:00:00` $> 10\,\%$.
  - If declared `date`: Proportion of `DATENT` or `DATSORT` at `00:00:00` $< 95\,\%$.
  - Any site falling in the intermediate range ($10\,\% < p < 95\,\%$) triggers a failure.
- **Action on Trip**: Blocking refusal on ingestion. The site adapter must either provide clean
  timestamps or declare a uniform date-only grain.
- **Rouen Baseline Witness**: Rouen 2024 movements show 4.11 % of `DATENT` and 4.08 % of `DATSORT`
  at `00:00:00`, with distinct admission peaks at 08:00 and discharge peaks at 15:00. This
  confirms a clean `datetime` profile.

---

### TW-05.1 — Structure Snapshot Referential Coverage

- **Identifier**: `TW-05.1`
- **Pipeline Stage**: Referential linkage (`05-structure.md`, Decision 05.2; `00-audit-qualite.md`,
  Decision 00.5)
- **Statement**: 100 % of administration UFs with hospitalisation activity, and $\ge 99.9\,\%$
  of microbiology observations, resolve in the annual establishment structure snapshot.
- **Rationale & Risk**: In accordance with Decision 03.5, the perimeter is defined positively:
  unmapped UFs are excluded from surveillance. A tripwire ensures that unmapped codes do not
  hide newly opened wards or significant clinical activity. A blocking check is refused because
  microbiology files frequently include inert external reference codes (e.g. referral samples
  sent from external clinics) that carry no hospitalisation activity.
- **Trigger Condition**:
  - Any administrative UF with $> 0$ hospitalisation days missing from `unit_mapping`.
  - Unmapped microbiology observation UFs $> 0.1\,\%$ of total laboratory observations.
- **Action on Trip**: Non-blocking warning. Unmapped UFs are logged in the divergence account
  with isolate and day counts.
- **Rouen Baseline Witness**: Rouen administration has 362 UFs, 362/362 (100 %) resolved in
  structure. Microbiology has 278 ordering UFs: 272 resolved in structure; 6 external UFs
  represent 68 raw laboratory rows and 0 diagnostic isolates in `sir_wide.rds` (100 % resolution
  for eligible diagnostic isolates).

---

<a id="tw-06-1"></a>
### TW-06.1 — Resistance Flags and Antibiotic Test Results

- **Identifier**: `TW-06.1`
- **Pipeline Stage**: Ingestion & pre-flight audit (`00-audit-qualite.md`, Decision 00.7;
  `06-donnees-resistance.md`, Decision 06.5)
- **Statement**: Positive BLSE and carbapenemase flags are checked against results for the
  corresponding antibiotics. Wild-type susceptible Enterobacterales have 0 unexplained positive
  phenotype flags.
- **Rationale & Risk**: Under SPARES Note Xa, an absent **phenotype signal** is treated as
  negative (`FALSE`); this is distinct from a positive phenotype with no corresponding antibiotic
  test result. If a site adapter inverts boolean flags or misinterprets LIS expert comments, a
  susceptible isolate could be falsely marked as carrying a resistance mechanism, distorting
  national indicators.
- **Trigger Condition**:
  - Any Enterobacterales isolate marked `blse = TRUE` with no interpretable result (`S`, `SFP`, or
    `R`) for any corresponding 3rd/4th generation cephalosporin (cefotaxime, ceftriaxone,
    ceftazidime, cefepime).
  - Any Enterobacterales isolate marked `blse = TRUE` with at least one corresponding result, where
    all interpretable results are susceptible (`S`). An `R` or `SFP` result supports the flag.
  - Any isolate marked `carbapenemase = TRUE` with no interpretable result (`S`, `SFP`, or `R`) for
    any corresponding carbapenem (meropenem, imipenem, ertapenem).
  - Any isolate marked `carbapenemase = TRUE` with at least one corresponding result, where all
    interpretable results are susceptible (`S`). An `R` or `SFP` result supports the flag.
  - Total discordant phenotype-AST isolates $> 0.5\,\%$ of phenotype-positive isolates. Missing-result
    findings are reported separately and are not included in this proportion.
- **Action on Trip**: Non-blocking warning; processing continues.
  - If a positive phenotype has no corresponding antibiotic test result, log that finding in the
    quality audit ledger and retain the reported phenotype under Decision 06.5.
  - If corresponding results are present but all are susceptible (`S`), quarantine the discordant
    isolate from indicator numerators and export it to the quality audit ledger.
- **Rouen Baseline Witness**: Rouen 2024 has 9 586 *E. coli* isolates: 99.55 % of C3G-susceptible
  isolates (8 636 / 8 675) carry no BLSE record, and 99.1 % of positive BLSE records coincide with
  C3G resistance. Exactly 0 wild-type pan-susceptible isolates are flagged BLSE-positive.

---

### TW-06.2 — CA-SFM Interpretation Version Referential

- **Identifier**: `TW-06.2`
- **Pipeline Stage**: Ingestion & standardization (`06-donnees-resistance.md`, Decision 06.6)
- **Statement**: The antibiogram interpretation referential declared by the site corresponds to
  CA-SFM/EUCAST $\ge 2020$ on surveillance campaigns from 2024 onward.
- **Rationale & Risk**: SPARES requires CA-SFM $\ge 2020$ rules, where the intermediate category
  `I` was redefined as "Susceptible at increased exposure" (SFP). Testing at the row level
  against raw laboratory version strings (`CASFM`) is dangerous because LIS dictionary updates
  often lagged behind bench practice (e.g. Rouen 2022 rows carried `CASFM = "2019"` despite clinical
  2020 compliance; row-level drops discarded whole years). The tripwire verifies site metadata
  declaration while inspecting raw tags.
- **Trigger Condition**:
  - Surveillance campaign $\ge 2024$ with site declared referential $< 2020$.
  - In raw laboratory data from 2024 onward, $> 5\,\%$ of rows carry explicit `CASFM < 2020`.
- **Action on Trip**: Warning for historical campaigns ($\le 2023$); blocking refusal on
  metadata declaration for campaigns $\ge 2024$.
- **Rouen Baseline Witness**: 100 % of Rouen 2024 raw laboratory rows carry `CASFM == "2022"`.
  Historical 2022 data with `CASFM = "2019"` dictionary tags are documented and validated via
  expert review.

---

### TW-07.1 — Antibiotype Panel Deduplication Parity

- **Identifier**: `TW-07.1`
- **Pipeline Stage**: Deduplication (`07-dedoublonnage.md`, Decision 07.4)
- **Statement**: Deduplicating on the site's full tested antibiotype panel retains the exact same
  isolates as deduplicating on the SPARES recommended species panel.
- **Rationale & Risk**: Deduplication is sensitive to the antibiotype panel. Testing an additional
  out-of-panel molecule can create a major discrepancy between two isolates that were previously
  identical, splitting an episode into two and increasing the deduplicated numerator. This was
  observed in v2 when the CLAVENTIN / AMC remapping moved 51 isolates and the denominators of 20
  antibiotic columns. The tripwire ensures that panel expansions are noticed immediately.
- **Trigger Condition**:
  $$\Delta N = |N_{\text{full\_panel}} - N_{\text{spares\_panel}}| > 0$$
  evaluated on deduplicated isolates for target species within the surveillance window.
- **Action on Trip**: Non-blocking warning. Logs the diverging isolate IDs and identifies the
  specific antibiotic molecules responsible for separating the antibiotypes.
- **Rouen Baseline Witness**: On Rouen 2024 data (*E. coli* / urines / 2024 slice), both the full
  site panel (21 molecules) and the SPARES recommended panel retain exactly **4 438 isolates**
  ($\Delta N = 0$). All tested molecules reaching indicator columns already participate in the
  panel; meropenem is the only extra molecule and creates zero isolate splits.

---

### TW-08.1 — SARM Marker Precedence and Concordance

- **Identifier**: `TW-08.1`
- **Pipeline Stage**: Indicator construction (`08-indicateurs.md`, Decision 08.3; `00-audit-qualite.md`,
  Decision 00.6)
- **Statement**: Cefoxitine is prioritized as primary marker for *S. aureus* methicillin resistance;
  oxacilline acts as surrogate fallback when cefoxitine is untested. Co-tested isolates are monitored
  for discordant clinical interpretations.
- **Rationale & Risk**: SPF Annexe 3 note 2 specifies: *"En cas de discordance entre les résultats
  céfoxitine et oxacilline, le résultat de la céfoxitine est conservé."* Cefoxitine is the
  preferred EUCAST surrogate for mecA/mecC-mediated methicillin resistance, but French clinical
  laboratories often test oxacilline. If both are tested and discordant, cefoxitine precedence must
  be strictly applied and the isolate flagged for microbiological review.
- **Trigger Condition**:
  Count of co-tested *S. aureus* isolates with $(\text{FOX} == \text{'R'} \land \text{OXA} == \text{'S'})$
  or $(\text{FOX} == \text{'S'} \land \text{OXA} == \text{'R'}) > 0$.
- **Action on Trip**: Non-blocking warning. Enforces cefoxitine precedence automatically in the
  group evaluation logic and logs discordant isolates in the audit ledger.
- **Rouen Baseline Witness**: On Rouen 2024 eligible *S. aureus* ($N = 1\,100$ deduplicated isolates),
  oxacilline is Rouen's routine clinical marker (1 093 tested: 84 R, 1 009 S, 7 NA; cefoxitine is
  untested on *S. aureus*). Under the surrogate fallback rule, SARM prevalence is 84 / 1 093 (7.69 %).
  Discordances on co-tested isolates = **0**.

---

## 4. Tripwire Governance and Audit Integration

All 7 dynamic tripwires are evaluated automatically during pipeline execution:
1. **Execution**: Tripwires TW-04.2, TW-05.1, TW-06.1, and TW-06.2 execute during the pre-flight
   audit (`00-audit-qualite.md`). TW-04.1 executes during exposure calculation. TW-07.1 executes
   during deduplication. TW-08.1 executes during indicator construction.
2. **Ledger Recording**: The status of all tripwires (PASS / TRIP / ACKNOWLEDGED), their numerical
   readings, and baseline comparisons are recorded in the run metadata and published alongside
   the **indicator table**.
3. **Auditability**: When an indicator diverges from national figures (e.g. ConsoRes), the tripwire
   ledger provides the empirical proof of whether local data shifted or whether divergence is
   attributable to explicit methodological choices.
