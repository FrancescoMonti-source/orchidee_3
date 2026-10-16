# Dynamic Pipeline Tripwire Register

Status: **settled**. Five active tripwires, zero unproven, verified against Rouen 2024 baseline data.

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
   or post-flight delivery manifest (`09-diffusion.md`) and requires an explicit acknowledgement
   before publication ("converts *nobody noticed* into *someone signed*").

---

Pre-flight measurements are documented in `00-audit-qualite.md`. They have no
tripwire thresholds or enforcement actions; population selection and calculation
rules remain owned by their method chapters.

## 2. Master Catalog of Dynamic Tripwires

| Tripwire ID | Name | Pipeline Stage | Target Scope | Action Policy | Rouen 2024 Witness |
|---|---|---|---|---|---|
| **TW-04.1** | Unit Denominator Annual Stability | Exposure derivation | PMSI movement exposure | Non-blocking (acknowledgement) | Denominators: 327 301 / 347 303 / 355 246 JH (2022–2024) |
| **TW-07.1** | Antibiotype Panel Deduplication Parity | Deduplication | Antibiotype panel molecules | Non-blocking (divergence ledger) | 4 441 under the 35-column supported panel and 4 441 under the 19-column Annexe 3 *E. coli* list; retained IDs identical |
| **TW-08.1** | SARM Marker Concordance | Indicator construction | *S. aureus* Cefoxitine vs Oxacilline | Non-blocking (enforces Fox precedence) | 0 co-tested isolates at Rouen; concordance is not assessable; oxacilline fallback: 84 / 1 093 R |
| **TW-09.1** | EUCAST Exceptional Phenotype Integrity | Diffusion & post-flight audit | Output tables & unquarantined isolates | Non-blocking warning (`manifest.json` flagged for biologist review) | Rouen 2024: 0 exceptional phenotypes (0 VRSA, 0 Amp-S *K. pneumoniae*) |
| **TW-09.2** | Temporal Surge Outbreak Detection | Diffusion & post-flight audit | Output indicators ($N_{\text{tested}} \ge 30$) | Non-blocking warning (`manifest.json` flagged for epidemiological review) | Rouen 2022–2024: 0 indicators with $> 3\times$ year-over-year surge |


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

### TW-07.1 — Antibiotype Panel Deduplication Parity

- **Identifier**: `TW-07.1`
- **Pipeline Stage**: Deduplication (`07-dedoublonnage.md`, Decision 07.4)
- **Statement**: Deduplicating on the site's full tested antibiotype panel retains the exact same
  isolates as deduplicating on the species\' SPF Annexe 3 list (SPF p. 20, titled "Méthodologie Spares"; the SPARES methodology itself, pp. 1-31, lists no panel of molecules). Witnessed on *E. coli* only; the lists of the other species in Annexe 3 are not yet run.
- **Rationale & Risk**: Deduplication is sensitive to the antibiotype panel. Testing an additional
  out-of-panel molecule can create a major discrepancy between two isolates that were previously
  identical, splitting an episode into two and increasing the deduplicated numerator. This was
  observed in v2 when the CLAVENTIN / AMC remapping moved 51 isolates and the denominators of 20
  antibiotic columns. The tripwire ensures that panel expansions are noticed immediately.
- **Trigger Condition**:
  $$\Delta N = |N_{\text{full\_panel}} - N_{\text{annexe3\_list}}| > 0$$
  evaluated on deduplicated isolates for target species within the surveillance window.
- **Action on Trip**: Non-blocking warning. Logs the diverging isolate IDs and identifies the
  specific antibiotic molecules responsible for separating the antibiotypes.
- **Rouen Baseline Witness**: On Rouen 2024 data (*E. coli* / urines / 2024 slice), both the full
  site-supported panel (35 columns; 21 have results in this slice) and the
  19-column Annexe 3 *E. coli* list retain exactly **4 441 isolates each**
  ($\Delta N = 0$), with identical retained isolate IDs. Meropenem is the only
  out-of-panel molecule carrying data in this slice and creates no isolate splits.

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
  oxacilline is Rouen's routine clinical marker (1 093 tested: 84 R, 1 009 S;
  7 untested); cefoxitine has no tests on *S. aureus*. Under the surrogate fallback
  rule, SARM prevalence is 84 / 1 093 (7.69 %). The co-tested denominator is 0,
  so concordance and discordance are not assessable at this site.

---

### TW-09.1 — EUCAST Exceptional Phenotype Integrity

- **Identifier**: `TW-09.1`
- **Pipeline Stage**: Diffusion & post-flight audit (`09-diffusion.md`, Decision 09.3)
- **Statement**: Zero unquarantined isolates display biologically aberrant resistance phenotypes
  contradicting the EUCAST intrinsic resistance and unusual phenotype tables (v3.3, Tables 1-8,
  pp. 5-13; the tables are a tool to validate species identification and susceptibility results, p. 4).
- **Rationale & Risk**: Bacterial species have predictable intrinsic resistance mechanisms (e.g. *Klebsiella pneumoniae*
  is naturally ampicillin-resistant; *Proteus mirabilis* is naturally colistin-resistant) and certain acquired
  resistances are exceptionally rare (e.g. vancomycin resistance in *Staphylococcus aureus* [VRSA]). Identifying
  such isolates usually points to species misidentification, laboratory contamination, or transcription errors,
  though very rarely it represents a true superbug emergence. In either case, the run must flag the finding
  for medical biologist review rather than silently passing it to national aggregation.
- **Trigger Condition**:
  Count of unquarantined isolates matching any EUCAST unusual phenotype (v3.3, Tables 6-8, pp. 11-13;
  headed "exceptional" in earlier versions, p. 3) or susceptible to an agent listed as intrinsically resistant
  (Tables 1-5, pp. 5-10) $> 0$.
- **Action on Trip**: Non-blocking warning. Records finding in `manifest.json` (`status = "FLAGGED"`),
  detailing isolate identifiers, species, and contradictory antibiotic results for medical validation.
- **Rouen Baseline Witness**: On Rouen 2024 data, exactly **0** exceptional phenotypes detected across
  all eligible surveillance isolates.

---

### TW-09.2 — Temporal Surge Outbreak Detection

- **Identifier**: `TW-09.2`
- **Pipeline Stage**: Diffusion & post-flight audit (`09-diffusion.md`, Decision 09.3)
- **Statement**: In routine hospital surveillance, annual resistance proportions on stable sample
  volumes ($N_{\text{tested}} \ge 30$) do not experience $> 3\times$ relative increases.
- **Rationale & Risk**: A sudden 3-fold surge in resistance either indicates a severe nosocomial outbreak
  or an operational testing artifact (e.g. abrupt change in laboratory testing panels, shift from universal
  to selective cascade reporting). The check flags the anomalous indicator row for epidemiologist inspection
  before external transmission.
- **Trigger Condition**:
  For any stratum with $N_{\text{tested}} \ge 30$:
  $$\frac{\text{rate}_{t}}{\text{rate}_{t-1}} > 3.0 \quad \text{with} \quad \Delta \text{rate} \ge 0.05$$
- **Action on Trip**: Non-blocking warning. Attaches an epidemiological alert flag to the indicator row
  in `manifest.json`, alerting the local hygiene team and PDS/SPF.
- **Rouen Baseline Witness**: 0 indicators exhibit $> 3\times$ relative jumps between 2022 and 2024 at CHU de Rouen.

---

## 4. Tripwire Governance and Audit Integration

All 5 dynamic tripwires are evaluated automatically during pipeline execution:
1. **Execution**: TW-04.1 executes during exposure calculation. TW-07.1 executes
   during deduplication. TW-08.1 executes during indicator construction. TW-09.1 and
   TW-09.2 execute during post-flight quality audit (`09-diffusion.md`) prior to
   delivery bundle packaging. Pre-flight measurements have no tripwire triggers.
2. **Ledger Recording**: The status of all tripwires (PASS / TRIP / ACKNOWLEDGED), their numerical
   readings, and baseline comparisons are recorded in the run metadata (`manifest.json`) and published alongside
   the **indicator table**.
3. **Auditability**: When an indicator diverges from national figures (e.g. ConsoRes), the tripwire
   ledger provides the empirical proof of whether local data shifted or whether divergence is
   attributable to explicit methodological choices.

