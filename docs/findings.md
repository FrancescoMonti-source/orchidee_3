# Findings

An append-only log of things discovered while writing the specification, in the
order they were found. One paragraph each, with a pointer to where the finding
is recorded in full.

This is a **log, not an index**. It does not claim to be complete and nothing
depends on it, so it cannot drift: an entry only says *this was found on this
date*. Decisions live in `docs/methods/`, measurements in
`docs/worked-examples/`, external facts in `docs/evidence/`, vocabulary in
`CONTEXT.md`. Those are authoritative; this file exists so a reader can see what
was learned without reading nine sections.

Entries are never edited after the fact. A finding that turns out to be wrong
gets a new entry saying so.

---

### 2026-09-18 — ZIT appears in neither specification

`ZIT` (zone d'incertitude technique) is absent from the SPARES methodology and
from the SPF requirements. It exists only in the CA-SFM reference and in
hospital exports. Reading it as `SFP` is therefore an ORCHIDEE decision that no
external document prescribes, and the two readings differ: 4 438 isolates
against 4 428 on the *E. coli* / urines / 2024 slice. <!-- citecheck: ok, absence checked in the 2026-09-29 entry (SPARES pp. 1-31, SPF pp. 1-21) -->
→ `docs/methods/06-donnees-resistance.md` 06.2, `07-dedoublonnage.md` 07.5

### 2026-09-18 — Widening the antibiotype panel has no effect at Rouen

Measured to test the opposite claim, which had been argued at length. All 21
antibiotics tested on *E. coli* at Rouen already reach an indicator column; the
only out-of-panel column carrying data is meropenem. Removing molecules changes
the count (full panel 4 438, minus AMC 4 372) but adding them does not. The risk
is not breadth. The risk is change.
→ `docs/worked-examples/deduplication.md`, `07-dedoublonnage.md` 07.4

### 2026-09-18 — Excluding screening samples is the largest single effect measured

*E. coli* 2024, global scope: 5 489 isolates diagnostic-only against 5 798
including screening (+5.6 %). Céfotaxime moves 16,96 → 25,19 %R (+8,23 pp) and
ertapénème quadruples. Screening is not a random sample — carriage swabs are
taken *because* resistance is suspected — so the bias runs one way.
→ `docs/worked-examples/screening-exclusion.md`, `06-donnees-resistance.md` 06.1

### 2026-09-18 — One mapping correction moved 51 isolates and 20 denominators

CLAVENTIN is ticarcillin-clavulanate and had been fed into the
amoxicilline-acide clavulanique column, deciding 14 005 of 30 787 published
cells. Correcting one source row removed 51 isolates from the deduplicated
global scope and moved the denominators of 20 antibiotic columns. Nothing in the
pipeline was able to object.
→ `docs/evidence/2026-08-02_amc_remapping_cascade.txt`

### 2026-09-19 — ConsoRes' denominator for Rouen has no activity filter

The report prints `(95/589397)`, which is the only reason this was checkable.
ORCHIDEE's perimeter-correct denominator for the same year is 355 246 — a ratio
of ×1.66. The declared figure exceeds even ORCHIDEE's *unfiltered* exposure
table. Every incidence density in Rouen's ConsoRes report is understated by
40 %, and consumption divides by the same JH.
→ `docs/evidence/2024_consores_rouen_denominator.md`, `04-donnees-activite.md` 04.1

### 2026-09-19 — SPF's monthly requirement is unsatisfiable as specified

SPF asks for monthly indicators and defines the denominator as SAE-declared
days. The SAE is an annual declaration; there is no monthly SAE. Whoever
implemented ConsoRes had to decide something, and no document says what. <!-- citecheck: ok, pages and corrections in the 2026-09-29 entry -->
→ `docs/methods/04-donnees-activite.md`, *What SPF asks*

### 2026-09-19 — Occupancy hours and midnight presence agree, except where it matters

Across the SPARES-eligible perimeter the two measures differ by 0.35 %
(356 492 against 355 246). Across ambulatory activity they differ by factors of
3.7 (hospitalisation de jour) and 55 (traitement et cure ambulatoire). The
emergency ward comes out at 0.998 despite 49.4 % of its unit-episodes carrying
zero nights, because a long tail repays in aggregate what the short stays lose —
so midnight presence is wrong on half the episodes while being right on the
total.
→ `docs/worked-examples/denominator.md`

### 2026-09-19 — Timestamps at Rouen are real, and the degradation is exact

4.11 % of `DATENT` and 4.08 % of `DATSORT` sit at exactly 00:00; admissions peak
at 08:00 and discharges at 15:00. If both timestamps were 00:00, occupancy hours
÷ 24 would be *identically* the midnight-presence count — so a date-only site
lands on exactly the old number. Which is why the resolution must be declared
rather than inferred: a site at 40 % is neither, and averaging it produces a
denominator biased within one hospital.
→ `docs/methods/04-donnees-activite.md` 04.9

### 2026-09-19 — The two source documents specify different deduplication rules

SPF's Annexe 1 restates deduplication without the antibiotype: one sample per
patient, the oldest. SPARES retains both isolates when they differ by a major
discrepancy. On the *E. coli* / urines / 2024 slice the rules differ by 399
isolates — 9.0 % of the numerator. Two official documents describing the same
operation, with nothing obliged to notice.
→ `docs/methods/07-dedoublonnage.md`, *Open*

### 2026-09-19 — Deduplication is not monotone, so every selection is an input

Removing a row from deduplication's input can *add* a row to its result. Applied
to the perimeter: filtering then deduplicating keeps 2 445 *E. coli* isolates,
deduplicating then filtering keeps 2 350, and 79 patients disappear entirely
because their retained representative sat in an ineligible unit. This is the
same mechanism as the screening ordering hazard, which makes it a property of
deduplication rather than a fact about screening: **any selection on isolates is
an input to deduplication, never a filter on its output.**
→ `docs/worked-examples/perimeter-ordering.md`, `03-activites.md` 03.2,
`07-dedoublonnage.md`

### 2026-09-19 — The SPARES perimeter discards more than half the microbiology

Of 6 519 diagnostic *E. coli* isolates at Rouen in 2024, 2 868 (44 %) are in
eligible units. Whatever else the perimeter is, it is not a trim.
→ `docs/methods/03-activites.md` 03.1

### 2026-09-19 — The unit referential is essentially complete; the attribution is not

6 UFs of 1 159 are unclassified (2 with TA 03/20 and no DE, 4 absent from the
structure file). But 3 650 isolates — 7.5 % of the bundle, 1 173 in 2024 —
carry no `SEJUF` at all. The gap is not unfinished mapping work; it is samples
that could not be attributed to a hospitalisation unit. No mapping effort of any
kind reaches them.
→ `docs/methods/03-activites.md` 03.4 and *Open*, `05-structure.md`

### 2026-09-19 — Unit-less isolates are outpatient visits and extraction boundaries, not unmapped units

All 3 650 isolates with `SEJUF = NA` carry a valid ordering UF in the laboratory
file. 60 % (2 190) are outpatient or emergency visits (TA 10 urgences 1 278, TA 07
consultations 447, TA 04 HDJ 164) where no complete hospitalisation occurred. The
remaining 40 % (1 456) reflect extraction boundaries: 632 in USLD long-term care
(absent from acute MCO movements) and 824 in MCO (pre-admission sampling or omitted
stays). Falling back to laboratory UFs adds 110 deduplicated *E. coli* isolates
(+4.5 %) and moves céfotaxime +1.02 pp, but injects isolates without corresponding
denominator days.
→ `docs/worked-examples/unit-attribution.md`, `05-structure.md` 05.1

### 2026-09-19 — The keyword "recherche" is a catastrophic screening proxy

Naive string search for "recherche" across raw laboratory data catches 80 700 rows
across 118 test types in 2024 alone. In French medical biology, "Recherche" is the
standard order prefix for both screening orders and high-acuity diagnostics: the search
catches 6 231 N. gonorrhoeae diagnostic swabs, 18 969 C. difficile GDH and toxin tests,
and 2 519 malaria blood films. Filtering sample nature on "rectal" similarly discards
surgical deep-abscess drainages. Screening classification must remain a site-adapter
contract boolean, never an internal string heuristic.
→ `docs/worked-examples/phenotypes-and-screening.md`, `06-donnees-resistance.md` 06.7

### 2026-09-19 — Absent phenotype signals are 99.55 % concordant with wild-type susceptibility

In routine hospital microbiology, confirmatory phenotype tests (BLSE, carbapenemase) are
never performed or documented for wild-type isolates. Across 9 586 *E. coli* isolates in 2024,
99.55 % of C3G-susceptible isolates (8 636 / 8 675) carry no BLSE record whatsoever, while
99.1 % of positive BLSE tests coincide with C3G resistance. Treating an absent signal as
negative (`FALSE`) reflects clinical laboratory reality and introduces zero missing-data
leakage, directly confirming SPARES Note Xa.
→ `docs/worked-examples/phenotypes-and-screening.md`, `06-donnees-resistance.md` 06.5

### 2026-09-19 — Reverse-engineering screening requires a three-tier model to avoid wound data loss

Reverse-engineering the screening boundary from raw GLIMS data cannot rely on simple
heuristics. An audit of all 12 test batteries ending in `_R` establishes three tiers:
(1) Pure BMR/BHRe carriage batteries (`BGBLSE_R`, `BGCARBA_R`, `BGERV_R`, `BGSAMR_R`,
`BGABRI_R`, `BGABMR_R`, `BGPYOBMR_R`) carry 0 direct antibiograms, qualitative results,
and 100 % NA specimen natures; their positive results trigger reflex antibiograms on the
same `ELTID`.
(2) Dual-use orders like `BGSTA_R` (*S. aureus* search) are nasal carriage screens when
standalone (0 AST rows), but active diagnostic cultures on acute infected wounds
(`PLAIE DOS`, `VESICULE CUTANEE`) when co-ordered with `BGCULTAE` (yielding 681 AST rows
of *P. aeruginosa*, *Proteus*, and *Serratia*); treating `BGSTA_R` as a blanket screening
flag discards legitimate wound infections.
(3) Specimen mapping must separate superficial non-sterile reservoirs (`^NEZ$`, `^AISSELLE$`)
from surgical collections (`Liquide ABCES MARGE ANALE`, `FISTULE ANO PERINEALE`), which
represent > 95 % of specimens matching "anal/rectal" that have antibiograms.
→ `docs/methods/note-cadrage-depistage-microbiologie.md`, `06-donnees-resistance.md` 06.7

### 2026-09-19 — Specimen scoping is an input to deduplication; post-filtering deletes 35.6 % of bacteremias

Comparing blood-culture-specific indicators on Rouen 2024 data: feeding blood cultures
as an input to deduplication keeps 216 *S. aureus* and 267 *E. coli* isolates, whereas
deduplicating globally and post-filtering keeps only 139 *S. aureus* (−35.6 %) and 226 *E. coli*
(−15.4 %). 5 SARM bacteremias are erased (−33.3 %, dropping DI from 0.0422 to 0.0281 / 1000 JH).
Because prior non-blood samples (urine, sputum, wound) preempt secondary bacteremias under
the oldest-sample tiebreak, specimen scoping must remain an input to deduplication.
→ `docs/worked-examples/indicators.md`, `docs/methods/08-indicateurs.md` 08.1

### 2026-09-19 — Restricting phenotype denominators to explicit test rows inflates BLSE from 7.6 % to 83.0 %

In routine bacteriology, wild-type susceptible Enterobacterales do not trigger confirmatory
double-disk synergy or PCR tests. On Rouen 2024 eligible *E. coli*, 186 isolates are BLSE-positive
out of 2 445 total deduplicated isolates (7.61 % prevalence under SPARES Note Xa). If the
denominator is restricted to isolates with an explicit BLSE test row in the laboratory export
(224 isolates: 186 positive, 38 negative), the rate jumps to 83.04 % (+75.4 pp). Treating an
absent phenotype test as missing data rather than negative completely destroys surveillance validity.
→ `docs/worked-examples/indicators.md`, `docs/methods/08-indicateurs.md` 08.6

### 2026-09-20 — Pre-flight data quality operationalizes SPARES §1 and unifies 7 pipeline tripwires

SPARES Page 16 §1 specifies an upfront coherence and plausibility audit of the whole database.
In ConsoRes this step was informal and unreviewable. ORCHIDEE formalizes this into an upfront automated
pre-flight audit (`00-audit-qualite.md`) and a master catalog of seven dynamic pipeline tripwires
(`tripwire-register.md`), verifying movement interval ordering (`DATENT <= DATSORT`), timestamp grain
degradation (where date-only occupancy hours simplifies identically to midnight presence), structural
referential linkage (> 99.9 %), EUCAST intrinsic resistances (*K. pneumoniae*/ampicillin, *P. mirabilis*/colistin),
and reflex phenotype-AST plausibility under Note Xa.
Empirical audit at Rouen revealed 80 raw PMSI movement rows (0.018 %) with negative durations (`DATSORT < DATENT`,
down to -27 days) quarantined to protect exposure denominators, and 1 outpatient *K. pneumoniae* isolate
reported susceptible to ampicillin (ELTID 376198529) quarantined from numerator computation (0 violations
in the eligible hospitalisation perimeter, 604/604 R).
→ `docs/methods/00-audit-qualite.md`, `docs/methods/tripwire-register.md`

### 2026-09-21 — SARM Oxacilline ground truth, Note Xa boundary, and Emergency linkage window (ADR-0009)

1. **SARM Methicillin Ground Truth**: Forensic analysis of raw GLIMS data (`data/bact22_24`) revealed that Rouen exports `OXACILLINE` for *S. aureus* (1 093 tested: 84 R, 1 009 S, 7 NA; 7.69 % SARM), with 0 tests of Cefoxitine on *S. aureus* (cefoxitine was tested exclusively on Enterobacterales). ORCHIDEE enforces the SPF Annexe 3 note 2 rule: cefoxitine takes primary precedence, falling back to oxacilline when cefoxitine is untested. Fabricated contingency tables were removed from documentation and tripwire registers.
→ `docs/worked-examples/indicators.md`, `docs/methods/08-indicateurs.md` 08.3, `docs/methods/tripwire-register.md` TW-08.1

2. **Note Xa Scope Confined to Enzymatic Phenotypes**: SPARES Note Xa applies strictly to enzymatic reflex phenotypes (BLSE and carbapenemases in Enterobacterales), where absent signals mean negative. Routine antibiogram molecules like vancomycin in *E. faecium* are not covered by Note Xa; their resistance proportions divide strictly by tested isolates ($n / N_{\text{tested}}$).
→ `docs/methods/08-indicateurs.md` 08.4, `docs/adr/0005-phenotype-indicators-use-spares-note-xa.md`

3. **Emergency Department 24h Pre-Admission Linkage Window**: Blood cultures drawn in Emergency (TA 10) shortly before transfer to an acute inpatient ward (TA 03/20) previously had `SEJUF = NA` under strict timestamp matching, dropping severe sepsis cases from the numerator while their inpatient stay days were counted in the exposure denominator. ADR-0009 defines a 24-hour pre-admission linkage window attributing these specimens to the initial admitting inpatient UF.
→ `docs/adr/0009-emergency-pre-admission-samples-link-to-inpatient-stay.md`, `docs/methods/05-structure.md` 05.1

4. **Monthly Surveillance Model Finality**: Monthly indicators operate under independent monthly calendar partitions (`window = "monthly"`) and are final upon month close, preventing retrospective fluctuations from later hospitalizations. The long-term architectural goal is aligning with the European ECDC / EARS-Net 30-day rolling refractory window (Decision 07.2).
→ `docs/worked-examples/deduplication.md`, `docs/methods/07-dedoublonnage.md` 07.1–07.2

### 2026-09-25 — 30-day rolling refractory window resolves episode non-transitivity and surfaces monthly calendar inflation

Decision 07.2 compared annual calendar, monthly calendar, and 30-day rolling refractory deduplication on Rouen 2024 diagnostic data. The chronological sweep automaton mathematically resolves the non-transitivity chaining problem by anchoring a 30-day refractory window at episode onset. On *E. coli* urines (4 963 raw isolates), 30-day rolling phenotype-aware deduplication retains 4 718 isolates (+6.31 % vs annual 4 438; −1.97 % vs monthly 4 813). Monthly calendar deduplication introduces an artificial +1.97 % inflation in urines and +1.50 % in blood cultures due to repeat cultures 2–4 days apart straddling month ends (e.g. Jan 29 and Feb 2) counted twice. Annual calendar splits ongoing episodes across Dec 31 / Jan 1 (12 early-2024 *E. coli* urines within 30 days of late-2023 isolates). Furthermore, pure time-based deduplication (EARS-Net) creates an intra-episode resistance blindspot, suppressing emergent resistant sub-populations during bacteremias (−13.3 % in *E. cloacae* blood cultures, 91 vs 105), proving that phenotype-awareness must be retained within rolling refractory windows.
→ `docs/evidence/dedup_window_30day_refractory_witness.md`, `docs/methods/07-dedoublonnage.md` 07.2

### 2026-09-25 — Chapter 09 settling: unmasked delivery to PDS/SPF, immutable delivery bundle, two-tier post-flight audit, and turnkey local feedback

1. **Statistical Disclosure Control Boundary**: Core ORCHIDEE enforces ADR-0008 by delivering 100 % unmasked tall indicator tables directly to the national receiving platform (Plateforme des données de santé - PDS / Health Data Hub). Presentation masking ($n < 5$) and public visualizations are strictly the operational responsibility of PDS and Santé publique France, eliminating distributed masking logic across hospitals and preserving algebraic additivity across strata.
2. **Delivery Bundle Architecture**: Standardized, self-contained immutable package (`.tar.gz` / `.zip`) containing strongly-typed `indicators.parquet` with `indicators.csv.gz` fallback, stratified exposure tables, and a signed `manifest.json` recording pipeline git SHA, snapshot hashes, runtime timestamps, and audit ledgers.
3. **Two-Tier Post-Flight Quality Audit**: Fatal structural invariants ($N_{\text{num}} \le N_{\text{den}}$, rates $\in [0, 1]$, exposure $> 0$) hard-block delivery bundle packaging. Epidemiological anomalies (TW-09.2: $> 3\times$ surge with $N \ge 30$) and microbiological violations (TW-09.1: EUCAST intrinsic/exceptional resistance phenotypes) log non-blocking warnings to `manifest.json` (`status = "FLAGGED"`) for medical biologist and PDS/SPF review.
4. **Turnkey Local Clinical Feedback**: Built-in parameterized Quarto HTML report consuming unmasked indicator tables delivers zero-server clinical steering for hospital infection control (EOH/CLIN) and bacteriology, while preserving raw table access for custom hospital BI.
→ `docs/methods/09-diffusion.md`, `docs/methods/tripwire-register.md` TW-09.1, TW-09.2

### 2026-09-27 — Issue #5 premise was false; the 30-day window is not EARS-Net; incomplete antibiograms

1. **No conflict between SPF and SPARES on deduplication**: both documents give the same
   antibiotype rule, retention rule and phenotype rule (SPARES pp. 10-11, SPF pp. 14-15), and
   both follow it with the same passage on analyses by sample type and across sample types
   (SPARES p. 16, SPF p. 15). The "Open" section of `07-dedoublonnage.md` and the premise of
   issue #5 read that passage as a rival SPF rule; 4 438 and 4 039 were isolates after
   deduplication and distinct patients, not two methods. ONERBA's 2000 recommendations
   (pp. 25-27), which both documents cite, support reading "pour une même souche" as applying
   within compatible isolates (same species, no major discrepancy, same resistance
   phenotypes), so the passage never collapses isolates with a major discrepancy. This is an
   inference: SPARES p. 11 glosses « même souche » as « même bactérie, même prélèvement ». <!-- citecheck: ok, the pages are in the sentences above; the earlier reading is ORCHIDEE's own (2026-09-29 entry) --> The
   global analysis excludes duplicates, the analysis by sample type excludes sample-type
   duplicates.
   → `CONTEXT.md` (Compatible isolates, Duplicate group, Duplicate, Sample-type duplicate)

2. **The 30-day rolling window is not the EARS-Net rule** (correcting the 2026-09-21 item 4 and
   the 2026-09-25 entry above). EARS-Net defines no episode: it keeps the first blood or CSF
   isolate per patient and pathogen in the calendar year (ECDC reporting protocol 2025, p. 22
   and pp. 24-25). WHO GLASS keeps the first isolate per patient, specimen type and period. <!-- citecheck: ok, GLASS checked against its manual in item 6 below; EARS-Net checked in the 2026-09-29 entry --> The
   nearest published rule to the phenotype-aware 30-day window is Japan's JANIS (Kajihara et
   al., PLoS ONE 2020;15(6):e0228234). The evidence file cited that paper as "Ohmagari et al.,
   15(10): e0240902", a DOI that belongs to an unrelated article.
   → `docs/methods/01-periode-surveillance.md`, `07-dedoublonnage.md` 07.2 note,
   `docs/evidence/dedup_window_30day_refractory_witness.md`, `docs/worked-examples/deduplication.md`

3. **Blank antibiotic results make duplicate groups ambiguous**: a bridging isolate can be
   compatible with two isolates that have a major discrepancy with each other. The sources do not
   say which isolate a new isolate is compared with after the retention rule replaces the
   retained isolate. At Rouen, 2022-2024, 5, 2 and 2 bridging isolates; comparing with every
   isolate of the group gives the same retained isolates as the current witness code in every
   group, while comparing with the first isolate of the group merges a major discrepancy in 1,
   0 and 1 groups. The retention rule leaves orphaned results on 99-116 isolates a year, fewer
   than keeping the oldest (148-187).
   → `docs/worked-examples/incomplete-antibiotypes.md`

4. **Blank phenotype read as negative is weak when no screening molecule was tested**: 0, 2 and
   0 pairs of isolates kept apart only by such a BLSE flag. Traced, not fixed.
   → `docs/adr/0005-phenotype-indicators-use-spares-note-xa.md` (Known weakness)

5. **The source gives two retention rules, and its two analyses can retain different
   isolates**: SPARES p. 11 keeps the isolate with more molecules tested, then the oldest;
   p. 16 keeps « le plus ancien » (SPF repeats both on p. 15). ORCHIDEE applies p. 11. With a
   bridging isolate, the analysis by sample type and the global analysis can retain different
   isolates: an isolate can be a sample-type duplicate without being a duplicate. Not measured.
   → `07-dedoublonnage.md` (Open)

6. **The bundle behind the counts above is provisional**: `outputs/rouen_stage2_2024/bundle_v3`
   was built on 2026-09-26 by the v2 pipeline (repository `orchidee` at 500f7fd, v2 mappings)
   from `data/bact22_24` and `data/pmsi`. Only the raw inputs are ORCHIDEE's; the mappings
   are not reviewed, and which pipeline builds ORCHIDEE's data is not decided. The first
   version of this entry and the documents it points to called it the "raw-backed build".
   → `07-dedoublonnage.md` (Witnesses to re-measure)

### 2026-09-27 — Corrected TW-08.1 baseline and remeasured deduplication witnesses

The 2024 *E. coli* / urine deduplication witnesses for 07.1, 07.4 and 07.5 were
remeasured on the provisional `outputs/rouen_stage2_2024/bundle_v3` with BLSE and
carbapenemase comparison and Decision 07.6's all-members grouping. Annual and pooled
monthly windows retain 4 441 and 4 814 isolates. The 35-column supported panel and
19-molecule SPARES panel retain identical isolate IDs (4 441). Reading `ZIT` as
`SFP` retains 4 441; treating it as never conflicting retains 4 431. Site mappings
remain unreviewed, so these figures are provisional.

The prior 4 718 result for the 30-day rolling window is not reproduced. The tracked
repository contains no rolling-window witness script or exact historical boundary
and group-reset rule. A direct implementation of the prose on the current bundle
retains 4 729 with phenotype comparison and 07.6, or 4 727 without phenotype
comparison. Decision 07.2 remains under audit; these direct counts do not establish
the missing historical comparison.

The TW-08.1 catalog row claiming 91 co-tested *S. aureus* isolates (84 R/R and
7 S/S) was incorrect. Rouen has zero cefoxitine tests on *S. aureus*; oxacilline
has 1 093 tested results (84 R, 1 009 S) and 7 untested isolates. The co-tested
denominator is zero, so concordance is not assessable. SARM fallback remains
84 / 1 093 (7.69 %).
→ `docs/methods/07-dedoublonnage.md`, `docs/evidence/dedup_window_30day_refractory_witness.md`, `docs/methods/tripwire-register.md` TW-08.1, `docs/methods/08-indicateurs.md` 08.3

### 2026-09-27 — Eleven block quotes were not in their sources; SPARES disagrees with itself on phenotype scope

Found by the first full run of `tools/citecheck` (check C3), then read page by page.

1. **Eleven block quotes were not in any of the seven source PDFs in `docs/`.** Most kept the
   meaning in other words. Three did more: the period quote added a sentence the source does
   not contain; the establishments quote named MECSS « à caractère sanitaire spécialisé »
   (SPARES p. 9 says « sanitaire et social »); the SPF quote changed the meaning (item 4). The
   Note Xa quote, repeated in four documents, was reworded, dropped Pseudomonas, and was cited to
   p. 16: the passage is footnote *a* of the SPARES variable dictionary (Annexe 6, p. 31). All
   SPARES quotes are now verbatim, with pages.
   → `00-audit-qualite.md`, `01-periode-surveillance.md`, `02-etablissements.md`,
   `06-donnees-resistance.md`, `08-indicateurs.md`, `09-diffusion.md`,
   `docs/worked-examples/phenotypes-and-screening.md`

2. **SPARES disagrees with itself on which species carry a BLSE or carbapenemase phenotype.**
   Page 14 lists « un phénotype de résistance pour les Enterobacterales »; p. 15 and footnote *a*
   on p. 31 name Enterobacterales and Pseudomonas. The national indicators (p. 8) name only
   Enterobacterales and *K. pneumoniae*. Invariant 3 and ADR-0005 limit Note Xa to
   Enterobacterales. Open: whether to follow p. 15 and p. 31.

3. **What Note Xa changes for *P. aeruginosa***, measured on the raw `data/bact22_24`: isolates
   `(ELTID, DLVL)` with an antibiogram, before deduplication, screening not removed. In 2024,
   1 293 isolates; carbapenemase 4 positive of 85 tested (4.71 % of tested, 0.31 % of all);
   BLSE 2 of 222 (0.90 %, 0.15 %). 2022 and 2023 give carbapenemase 9.71 % against 0.75 %, and
   9.09 % against 0.59 %. Phenotype rows: `BLSE.BLSE1`, `CARBA.CARBA1`, `PSE_COM` (BLSE, CARBA)
   and `BGCARBA*`; positive = « PRESENCE DE … », `R` or `POSITIVE`.

4. **SPF asks for numerators and denominators, not a consolidated annual report.** The chapter
   01 quote read « les résultats mensuels ainsi que le bilan annuel consolidé ». SPF p. 5 asks
   for « le numérateur et dénominateur utilisés » for every aggregated indicator and says
   separately « La fréquence d'estimation des indicateurs devra être mensuelle ». The SPF PDF
   contains neither « bilan annuel » nor « consolidé ». Not yet corrected.
   → `01-periode-surveillance.md`

5. **The GLASS rule in the entry above is second-hand.** It comes from a paper about GLASS
   (Kajihara et al., PLoS ONE 2020;15(6):e0228234), not from a GLASS document; to be checked
   against the GLASS manual.

6. **GLASS checked against its manual** (closes item 5): one result per patient, surveyed
   specimen type and surveyed pathogen in the surveillance period, one year recommended,
   « even if the resistance characteristics differ » (GLASS manual 2023, section 9.5.1,
   printed p. 31). Two exceptions the second-hand summary missed: blood and CSF on the same
   day keep the CSF isolate only, and a change of infection origin keeps both. Local sites
   may use other algorithms for their own purposes.
   → first written into the `07-dedoublonnage.md` 07.2 note and
   `docs/evidence/dedup_window_30day_refractory_witness.md`; both were shortened on
   2026-09-28 (f31c694) and no longer name GLASS, so this entry is the only record.

7. **Decided: Note Xa covers Enterobacterales and Pseudomonas** (closes item 2), following
   SPARES p. 15 and footnote *a* on p. 31. SPF's monthly frequency and numerator/denominator
   request replace the invented chapter 01 quote (closes item 4).
   → `docs/adr/0005-phenotype-indicators-use-spares-note-xa.md` (Scope), invariant 3 in
   `AGENTS.md`, `01-periode-surveillance.md`

### 2026-09-29 — Older claims about external bodies now carry pages (issue #12)

The citation check flagged claims about named bodies that had no page. Giving them one (PRs #15 to #17 and this one) meant reading each source again. Older entries are not edited; the six flagged paragraphs above carry a marker that points here. Every page below was read in its PDF in the session that added it.

1. **Checked, and the older entries stand.**
   - ZIT (2026-09-18): the term occurs nowhere in the SPARES methodology (pp. 1-31) or in the SPF requirements (pp. 1-21), by full-text search of both PDFs.
   - SPF's monthly requirement (2026-09-19): monthly frequency is SPF p. 5; the days are those « telles que déclarées dans le cadre de la statistique annuelle des établissements de santé (SAE) », SPF p. 15, item 8, and SPARES p. 13.
   - EARS-Net (2026-09-27, item 2): the 2026 ECDC protocol on disk keeps the records of the first date within the year per patient and pathogen, and only the CSF if blood and CSF are both reported that day (ECDC protocol 2026, p. 26). The 2025 edition that entry cites (pp. 22 and 24-25) is not on disk, so those pages stay unchecked.

2. **Corrected while giving pages.** The text in `docs/` is corrected; the entries above are not.
   - **ConsoRes' denominator.** No document says ConsoRes divides by the whole-establishment SAE: the report prints 589 397 (ConsoRes report p. 15) and labels its perimeter « Sanitaire SPARES » (p. 1), and SPARES p. 13 says only that the days are those declared in the SAE. "No activity filter", the title of the 2026-09-19 entry, is our inference. Lines that still state it as fact: ADR-0006 (« understates … by 40 % »), `denominator.md` (« It carries no activity filter »), `docs/evidence/2024_consores_rouen_denominator.md`.
   - **No SAE counting rule.** SPARES p. 13 gives none, so "the number the SPARES definition would have given" (midnight presence) was our assumption.
   - **No SPARES panel of molecules.** SPARES pp. 1-31 lists none; the 19-molecule panel is the witnesses' comparison panel, provenance unverified. "SPARES panel" wording remains in `07-dedoublonnage.md` and some worked examples.
   - **SPARES compares BLSE and carbapenemase phenotypes in deduplication** and reads an empty phenotype cell as absent (SPARES p. 11), against the claim that strict SPARES compares only molecules.
   - **Codes.** SPARES p. 12 and Annexe 6 (p. 31) ask for UF, DE and TA codes, not only UF.
   - **ONERBA has no "standard mapping"** (ONERBA p. 23): it asks for species-level identification and lists species to monitor, with no code list. The target species list is SPARES Annexe 5, pp. 28-30.
   - **SPF says nothing of PDS or statistical disclosure control** (SPF pp. 1 and 5); that split is ORCHIDEE's own design.
   - **Cefoxitine.** The precedence rule is footnote 2 of the SPF table on p. 3, not "Annexe 3"; EUCAST is not the source of the surrogate claim in the PDFs on disk, CA-SFM 2025 p. 72 is.
   - **EUCAST.** The tables on disk are the intrinsic resistance and unusual phenotypes tables v3.3 (p. 3 replaces "exceptional" by "unusual"). The Expert Rules document is not in `docs/`, so its content is unverified.

3. **Locators that pass the check and are wrong, not yet fixed.** `01-periode-surveillance.md` and `docs/worked-examples/deduplication.md` cite « SPARES Annexe 1 » for the deduplication rule; it is on SPARES pp. 10-11.

→ `docs/methods/04-donnees-activite.md`, `05-structure.md`, `06-donnees-resistance.md`, `09-diffusion.md`, `docs/worked-examples/indicators.md`

### 2026-10-14 — Suite 6.1 review: bilingual vocabulary and counting units

The English glossary had no English–French terminology table. It now distinguishes
an individual isolate before deduplication, biological lineage, operational
comparison, antibiotype, antibiogram, and an antibiotic-result record. The two
uses of *souche* are explained together, with the operational reading kept as the
chapter 07 inference (SPARES pp. 10-11 and 14-16).

Suite 6.1 mixed dataset row totals and distinct identifier values under "Entity
Level". Its row totals now have a separate table defining one row in each
dataset. "Handoff Observations" becomes antibiotic-result records supplied by the
site. The PMSI movement count previously placed under `ELTID` becomes not
applicable. The seven distinct `souche_id` values are reused local labels.

The historical numbers have not been remeasured. Distinct `EVTID` and `ELTID`
values must not be presented as full stay and sample counts; the composite-key
counts remain to be measured. The diagnostic isolate bundle's provisional v2
provenance and the later hospital-unit perimeter selection are now explicit.
Chapter 06 describes `souche_id` as a local isolate identifier instead of a
biological strain identifier; this vocabulary change does not rename a column.

→ `CONTEXT.md`, `docs/methods/00-audit-qualite.md` Suite 6.1,
`docs/methods/06-donnees-resistance.md` Isolate identity

### 2026-10-14 — Suite 6.1 follow-up: omit movements and adopt `isolate_id`

The review removes the PMSI movement dataset from the Suite 6.1 volume tables,
keeping this comparison focused on microbiology records and isolates. Movement
audits elsewhere in chapter 00 retain their scope.

The methods now call the local isolate identifier `isolate_id`. Historical
witness files retain `souche_id`, and raw Rouen files retain `DLVL`; preparing
v3 data maps these source names to the methods name. The full key remains
patient, sample and local isolate identifier. Deduplication selects retained
isolates with their original keys; it does not rename the column or create new
isolate identities. ADR-0007's spelling is aligned without changing the key's
components or the historical witness scripts.

→ `CONTEXT.md`, `docs/methods/00-audit-qualite.md` Suite 6.1,
`docs/methods/06-donnees-resistance.md` Isolate identity, `07-dedoublonnage.md`
07.7, `docs/adr/0007-relational-keys-are-composite-against-recycling.md`

### 2026-10-14 — Retain the deduplication mapping for each analysis

The review agrees to save group membership alongside retained isolates as a
local audit table. Each input isolate maps to its group's retained isolate by
the original full keys; retained isolates map to themselves. An analysis
reference records the exact data version and rules, so membership cannot be
silently reused after changing population, panel, period or another input.
The retained key identifies its group within that analysis; an additional group
identifier is unnecessary.

The current `deduplicate_witness()` builds groups and returns only retained
rows. The incomplete-antibiogram witness also constructs groups while comparing
alternative policies and investigating lost results. Saving membership addresses
this traceability gap. This entry records the agreed output requirement; the
witness scripts have not been changed or rerun.

→ `CONTEXT.md` (Deduplication mapping), `docs/methods/07-dedoublonnage.md`
(Deduplication audit output), `docs/adr/0001-deduplication-is-parameterised.md`

### 2026-10-14 — Quality findings are documentation-only for the current phase

The review specifies that findings are documented for now, with no automatic
response triggered. Chapter 00 now distinguishes this current phase from the
proposed blocking, quarantine, exclusion and other response policies described
for a later phase. Reviewing and activating those responses is deferred. This
is a documentation change; no audit execution or response code has been added.

→ `docs/methods/00-audit-qualite.md` (Current phase; Open)

### 2026-10-14 — Suite 6.2 counts repeated recovery, not infection episodes or duplicates

Suite 6.2 calls `(PATID, species)` pairs "episodes" and labels the fraction
`(isolates - pairs) / isolates` as true redundancy. A pair in a pooled extract
can span years, sample types and incompatible antibiotypes; deduplication can
retain several of its isolates. The section now describes patient–species pairs
and the fraction of isolates beyond one per pair, with the actual duplicate
fraction reserved for a fully specified analysis after population selection.

The displayed distribution reconciles to 33 017 pairs and 48 595 isolates;
8 207 pairs have multiple isolates, accounting for 23 785 isolates. The 32.06 %,
26.54 % and 23.83 % fractions reconcile arithmetically. These checks use the
numbers already in the document, not the unavailable raw inputs, so the counts
remain provisional. The three-year pooled profile is not a production
deduplication window.

The claim that 40.83 % of patients having multiple isolates demonstrates
polymicrobial infection or separate infection episodes was also withdrawn:
multiple isolates can be repeated recoveries of the same species. Decision
00.8 and its note now use the same descriptive interpretation.

→ `docs/methods/00-audit-qualite.md` Suite 6.2 and Decision 00.8;
`docs/methods/07-dedoublonnage.md` (Deduplication audit output)

### 2026-10-14 — Suite 6.2: state the patient, species and period instead of "repeats"

The review identifies "repeats", "repeated isolates" and "repeated pairs" as
ambiguous: readers can understand them as duplicates already identified by the
deduplication rules. Suite 6.2 now asks how many isolates of a given species are
recorded for a given patient within a stated population, period and specimen
scope. A patient–species pair is defined in the bilingual glossary, with a
concrete example in the section.

The distribution precedes the summary percentages; each percentage gives its
numerator and denominator. The 24.86 % of pairs with at least two isolates and
the 48.95 % of isolates in those pairs are kept distinct. The fraction beyond
one isolate per pair is presented as an additional descriptive calculation,
separate from the actual fraction removed by deduplication. Historical counts
and their provisional status are unchanged; no analysis code is modified.

→ `CONTEXT.md` (Patient–species pair), `docs/methods/00-audit-qualite.md`
Suite 6.2 and Decision 00.8

### 2026-10-14 — Suite 6.2 investigation: reproducibility and grouping remain unresolved

The user requests an explicit calculation specification before approving Suite
6.2, then invokes `grill-with-docs` to investigate and resolve its choices.
Earlier vocabulary corrections do not settle the full output specification.

No executable profiling witness for the historical distribution, the 33 017
patient–species pairs or the 40.83 % patient figure was found in the tracked
repository. `audit_qualite.rds` is named as a proposed output, without a tracked
writer. The figures already occur in the initial chapter commit `5272926`
(2026-09-21); the provisional bundle build recorded earlier in this log is dated
2026-09-26. Matching isolate totals alone do not establish the exact source
snapshot or the grouping and missing-value rules that produced the figures.
Documented local raw, handoff and bundle paths are absent in this workspace;
external protected-path availability is unknown. No source counts were rerun.

The chapter places the audit before population selection, but its historical
isolate example is described as already diagnostic and before hospital-unit
perimeter selection. Its population therefore differs from both full ingestion
and the selected input of an indicator analysis. The intended population for
Suite 6.2 needs an explicit decision.

The taxonomic counting key also needs definition: the indicator witness combines
`enterobacter_cloacae` and `enterobacter_cloacae_complex` before deduplication,
while the generic witness groups on exact `bact_norm`. Historical Suite 6.2
treatment of those labels and of unmapped taxa is unverified. These findings
record open questions; they do not change population or deduplication rules.

→ `docs/methods/00-audit-qualite.md` Suite 6.2;
`docs/worked-examples/deduplication.md`, `deduplication_witness_helpers.R`,
`indicators_witness.R`; `docs/methods/06-donnees-resistance.md`

### 2026-10-14 — Suite 6.2 decision: chapter 00 audits raw data

In the `grill-with-docs` interview, the user confirms that Suite 6.2 is
descriptive and that actual retained/removed counts belong to chapter 07. The
user explicitly clarifies the stage: chapter 00 examines raw data, whereas
deduplication happens later on transformed data. The earlier agent proposal to
use selected analysis input for Suite 6.2 is withdrawn. The temporary term
"t0" is not adopted as the definition of the audit input.

Chapter 00 now records this raw-data scope, marks the remaining calculation
specification as under review, and treats its historical diagnostic-isolate
tables as provisional examples rather than a raw-audit baseline. The actual
removed-count formula is placed with the later deduplication audit. No scripts
or data are changed and no automated response is activated.

An architectural documentation issue remains explicit: the old chapter wording
and ADR-0007 place the audit at handoff ingestion, while ADR-0003 allows the core
to read only the portable handoff. Raw hospital data and that handoff are
distinct. The boundary between site-level raw auditing and portable-contract
validation needs specification; this review does not change core access.

Existing raw readers expect `PATID`, `ELTID`, `DLVL`, `IDENTIFICATION` and
`DATEPRELEV`, but field completeness and a generic rule recognising all
isolate-bearing records remain unverified. Counting distinct recorded recoveries
from several laboratory rows is not surveillance deduplication. Whether Suite
6.2 includes isolates without an antibiogram is the next open decision.

→ `CONTEXT.md` (Raw site data), `docs/methods/00-audit-qualite.md`;
`docs/methods/07-dedoublonnage.md` (Deduplication audit output);
`docs/adr/0003-portable-contract-is-the-product.md`;
`docs/worked-examples/phenotypes_screening_witness.R`

### 2026-10-14 — Suite 6.2: quantify antibiogram availability before choosing a restriction

In response to Q2, the user first selected isolates with an antibiogram, then
reopened that answer and requested quantifying the distinction itself. No
AST-only restriction is treated as an approved final inclusion rule. The
requested preliminary calculation concerns antibiogram availability among
bacterial isolates whose identities can be established in the raw data.

The draft proposes separate counts and shares for a documented linked
antibiogram, no antibiogram found in the supplied extract, and indeterminate
presence or linkage. All three use the same identifiable-isolate denominator.
Non-reconstructable laboratory records must be accounted for separately.
An absent record in an extract cannot establish that no antibiogram was
performed. Test presence and interpretable-result availability need separate
definitions; the operational presence rule remains open.

The tracked raw witness counts identified isolates without requiring an
antibiogram. The observation-based screening witness instead requires a mapped
antibiotic inside its selected panel and a nonmissing standardized result before
assembling isolates; that is narrower than documented antibiogram presence.
Neither reader supplies a validated general presence rule for this calculation.
Raw inputs remain unavailable here, so no coverage counts have been computed.
This is a documentation update; scripts and data remain unchanged.

→ `docs/methods/00-audit-qualite.md` Suite 6.2;
`docs/worked-examples/phenotypes_screening_witness.R`;
`docs/worked-examples/screening_exclusion_witness.R`

### 2026-10-14 — Suite 6.2 preliminary coverage: annual and monthly reporting

The user requests antibiogram-availability counts by year and by month. The
preliminary calculation therefore uses sampling calendar years and sampling
year-months, with an identifiable-isolate denominator specific to each period.
Months with the same name in different years are not pooled. Annual percentages
are computed from annual counts, rather than averaging monthly percentages.

This settles the reporting periods for the preliminary coverage calculation,
not all remaining choices for the patient–species distribution. The presence
rule, ambiguous linkage and missing/conflicting sampling-date accounting remain
under review. No source counts are computed and no scripts are changed.

→ `docs/methods/00-audit-qualite.md` Suite 6.2 (preliminary calculation)

### 2026-10-14 — Suite 6.2 presence rule must use the supplied result records

The user indicates that the raw export probably contains results only, not
examination requests. No verified request, report-header or examination-status
schema was found in the tracked repository, so the audit must not assume such
source features. This clarification does not approve the pending distinction
between presence of an antibiogram and interpretable results.

The next proposed rule is result-based: an identifiable isolate with at least
one linked raw antibiotic susceptibility-result row, with interpretability
assessed separately. This definition and the source-dictionary recognition rule
remain under review; no data are classified and no counts are computed.

→ `docs/methods/00-audit-qualite.md` Suite 6.2 (preliminary calculation)

### 2026-10-15 — Source-result typos are distinct from interpretation failures

The site author reports very rare manually entered raw result values such as
`-R` and `--R`, and explicitly confirms that these exact spellings mean `R`.
This is site-provided knowledge; their frequency has not been measured in this
workspace. These recoverable source typos must not be described as laboratory
inability to interpret susceptibility. Recognised source tokens (including
`ZIT`), confirmed typos, missing values and unresolved strings are distinct.

No explicit normalization for these exact typos, complete raw-token inventory
or raw `STRRES`-to-`sir_result` converter was found in the tracked code. The raw
phenotype witness uses exact `STRRES == "R"` for its resistance check and would
not recognise these spellings there. The observation witness consumes already
standardized results, so its behaviour does not establish the upstream typo
handling. Existing witness counts have not been corrected or rerun.

Chapters 00 and 06 record the semantic distinction and the confirmed examples.
Any future source correction must use explicit, reviewed site equivalences;
the examples do not justify arbitrary punctuation stripping. This clarification
does not approve the pending general antibiogram-coverage rule. Source data and
scripts are unchanged.

→ `docs/methods/00-audit-qualite.md` Suite 6.2;
`docs/methods/06-donnees-resistance.md` (Result alphabet);
`docs/worked-examples/phenotypes_screening_witness.R`

### 2026-10-15 — Recognised I/ZIT handling is already defined

The user points out that `I` and `ZIT` already have a treatment in the methods.
The existing rule is `I` and `ZIT` to `SFP` during preparation, then `SFP` on the
`S` side at indicator construction (decisions 06.2, 06.4, 07.5 and 08.2).
Those recognised source tokens must not be described as unknown codes or as
absence of antibiogram results. Chapter 00 preserves the raw spellings; this
clarification does not introduce a new mapping.

Both primary PDFs were rechecked. SPF Expression de besoins p. 2 includes
sensible and sensible a forte posologie on the `S` side of antibiotic-group
evaluation. SPARES p. 22 explains the change from the old intermediate category,
previously grouped with resistant for resistance percentages, to SFP from
version 2020; p. 15 retains `S`, `SFP` and `R` as recorded categories. The
deduplication comparisons distinguish major `S`/`R` and `SFP`/`R` discrepancies
from minor `S`/`SFP` discrepancies (SPARES p. 11; SPF pp. 14-15).

Full-text searches still find no standalone `ZIT` or zone-of-uncertainty term
in either source (SPARES pp. 1-31; SPF pp. 1-21). The `ZIT` to `SFP` mapping is
therefore the documented ORCHIDEE decision, not a direct instruction from those
two sources. Chapters 00 and 06 now make the existing processing stages
explicit. No source values or scripts are changed, and the general coverage
rule remains under review.

→ `docs/methods/00-audit-qualite.md` Suite 6.2;
`docs/methods/06-donnees-resistance.md` (Result alphabet);
`docs/methods/08-indicateurs.md` 08.2

### 2026-10-15 — Preliminary antibiogram coverage: overall and by specimen type

The user confirms an overall summary and a breakdown by specimen type for each
annual and monthly reporting period. Specimen categories are those recorded in
the raw data. The denominator of each detail percentage is the number of
identifiable isolates of that specimen type within the same period.

This decision concerns the preliminary availability calculation. The handling
of missing or discordant specimen types, missing/conflicting dates and the
scope of the later patient–species distribution remain under review. No raw
records are classified or corrected and no analysis code is changed.

→ `docs/methods/00-audit-qualite.md` Suite 6.2 (preliminary calculation)

### 2026-10-15 — Retain unclassified specimen types and count temporal non-attribution

The user confirms retaining isolates with absent or unclassifiable specimen
types and notes that the mapping is not yet exhaustive. The choice between
combined and separate display categories for absent and unclassifiable types
is explicitly deferred. These are not the same as discordant source values,
whose handling remains open. No complete mapping or automatic classification
is presumed.

The user also accepts explicit counts of isolates that cannot be assigned to
annual or monthly sampling periods, with annual inclusion where sampling year
is certain but month is not. The user expects non-attribution to be uncommon;
no frequency is measured here.

Existing readers derive periods from `DATEPRELEV`. No method was found that
replaces a missing sampling date with `DATENT` or `DATSORT`. Those dates concern
the stay; ADR-0009 links already-dated pre-admission samples to later admissions
and can cross a month/year boundary. The user's mention of these dates does not
approve a new fallback or imputation. Raw date values, metadata and scripts are
unchanged.

→ `docs/methods/00-audit-qualite.md` Suite 6.2;
`docs/worked-examples/indicators_witness.R`;
`docs/adr/0009-emergency-pre-admission-samples-link-to-inpatient-stay.md`

### 2026-10-15 — Main Suite 6.2 distribution requires an antibiogram

The user resolves the main population explicitly: the patient–species isolate
distribution concerns only isolates with an antibiogram, because this strand
of ORCHIDEE addresses antibiotic resistance. This clarifies the earlier Q2
answer; a parallel main distribution of all raw isolates is not requested.
The preliminary availability calculation still quantifies identifiable raw
isolates with, without or without determinable evidence of linked antibiogram
results. Its broader denominator is kept distinct from the main distribution.

The user also confirms that the main distribution uses annual and monthly
sampling periods, with overall and specimen-type detail. Isolates, patients
and observed patient–species pairs are recounted within each included set and
reporting context. Missing/unclassifiable specimen metadata remain represented
under the already agreed retention rule; their combined or separate display
remains undecided.

Source-recognition rules, taxonomy keys and exact required distribution and
summary outputs remain under review. No raw data, mappings or scripts are
changed; no counts are rerun.

→ `docs/methods/00-audit-qualite.md` Suite 6.2

### 2026-10-15 — Scanned DXLAB codebook documents an antibiogram-related result line

Visual inspection of the image-only Codes DXLAB PDF finds a result line
labelled antibiogramme under the identification analysis (PDF p. 5). The same
sheet lists identification and comment/result fields, but not a catalogue of
bacterial taxa or validated equivalences between organism labels. The anatomical
origin codebook (PDF p. 1) describes specimen origins, not bacterial taxonomy.

This qualifies the earlier text-search finding: an antibiogram-related result
line is documented. Whether it appears in the supplied raw export, which values
it takes and whether it proves a completed examination are still unverified.
It does not yet supply an operational coverage classifier or change the approved
main population. Missing extracted text from the scanned PDF is not evidence
that the underlying document lacks such a field.

→ `docs/Rouen/Codes DXLAB.pdf` p. 5;
`docs/Rouen/Codes enregistrement selon origine anatomique Microbiologie.pdf` p. 1;
`docs/methods/00-audit-qualite.md` Suite 6.2

### 2026-10-15 — Approve three shares, remove the global ratio, request laboratory testing profiles

The user approves all three summary shares for the main antibiogram-isolate
profile: patient–species pairs with one isolate, pairs with at least two, and
all isolates belonging to those latter pairs. Numerators and denominators remain
explicit. The user instructs removal of the former `(isolates - pairs) /
isolates` summary from Suite 6.2; that section and its related global note are
aligned. This does not settle the separately unreviewed Suite 6.3 table.

Q10 remains open: the user asks what the proposed classes mean. They are bins
of isolate counts per patient–species pair, not antibiotic classes. Exact
integer counts versus grouped rows are still to be approved.

The user requests an additional distribution describing bacteria–antibiotic
testing by specimen type, to examine laboratory practices. A per-isolate count
of distinct antibiotics with recorded results is proposed; the exact counting
unit, output detail and complementary per-antibiotic coverage remain under
review. Repeated source rows must not be mistaken for additional antibiotics.

Existing column counts use restricted transformed panels, and the antibiotic
map distinguishes some route/breakpoint/local-test variants. Their cardinality
therefore cannot automatically be called the number of physical molecules.
Raw instrument/card information has not been verified. DXLAB PDF p. 5 lists
technique and Vitek-related result fields, but these alone do not establish
instrument attribution for an isolate. No raw panel counts are computed or
source/script changes made.

→ `docs/methods/00-audit-qualite.md` Suite 6.2;
`docs/worked-examples/deduplication_witness_helpers.R`;
`ref/rouen/atb_regex_map.csv`; `docs/Rouen/Codes DXLAB.pdf` p. 5

### 2026-10-15 — Approve per-isolate antibiotic counts and per-antibiotic result coverage

The user explicitly answers yes to Q13 and Q14. The laboratory-practice profile
therefore includes both the distribution of distinct antibiotics with a recorded
result per isolate and complementary per-antibiotic isolate counts and coverage.
Both outputs are stratified by bacterial species and specimen type, annually
and monthly by sampling date, before surveillance deduplication. Multiple rows
for one isolate and antibiotic count once for these outputs.

For each antibiotic, the coverage numerator is the number of isolates with a
recorded result for it; the denominator is all isolates with traceable
antibiogram results in the same species, specimen-type and period group. This
is result coverage, not a resistance percentage. Distinct antibiotic identity
and source recognition remain unresolved; the approvals do not validate the
existing restricted-panel mappings as a raw inventory.

Q10 remains unanswered. Its patient–species isolate-count distribution is
separate from the newly approved antibiotic-count distribution. The user
reports that the Q13/Q14 questions were hidden in folded reasoning, so further
interview questions should also be visible directly in chat. Only documentation
is changed; no scripts or data are modified and no counts are computed.

→ `docs/methods/00-audit-qualite.md` Suite 6.2

### 2026-10-15 — Approve exact patient–species isolate counts and three totals

The user answers "q10 ok" to the clarified Q10. For each approved main-profile
period and specimen scope, report the number of isolates with traceable
antibiogram results, distinct patients and observed patient–species pairs.
The required distribution retains each exact isolate-count value, with both
the number of pairs and the number of isolates in the corresponding row.
Upper values are not pooled in this required output. Historical grouped rows
are retained as examples, without claiming they reconstruct the exact counts.

The method and interview record now mark Q10 resolved. Antibiotic identity,
taxonomic grouping and the optional historical cross-species patient summary
remain the next methodological choices; raw-source recognition still requires
factual verification. No raw data or scripts are changed and no counts rerun.

→ `docs/methods/00-audit-qualite.md` Suite 6.2

### 2026-10-15 — Raw-population audit does not yet define the mapping boundary

The user challenges Q15 and Q16: if chapter 00 executes before mapping, grouped
specimen, bacterial and antibiotic profiles cannot assume harmonised labels.
They also ask for Q17 to be explained; none of these questions is approved by
this reply. Earlier approvals specify desired outputs, not their feasibility
before all mappings.

Read-only verification finds that chapter 00 says before analytical preparation
and population selection, but does not define when each mapping is available.
Suite 4 already uses the structure referential and Suite 5 recognises bacterial
taxa and antibiotic targets. Chapter 05 already lists approximately 25k specimen
labels awaiting classification; that estimate is not newly measured. Methods
chapters follow the source methodology's organisation, not a documented total
execution order. Existing witnesses use mixed raw and mapped inputs.

Literal source-label counts and profiles using harmonised categories have
different dependencies. A proposed split would run source checks before mapping
and classified profiles/checks after mapping, both before population selection
and deduplication. This remains an unapproved proposal. It must preserve the
source population, document unresolved classifications, reconcile the scope
with decision 03.6 and respect ADR-0003's site-adapter/core boundary. Q15 and Q16
are suspended behind this prerequisite; Q17 remains open pending explanation.
The method now exposes the dependency without moving checks or changing core
access, scripts or data.

→ `docs/methods/00-audit-qualite.md` (What ORCHIDEE does; Suite 6.2; Open);
`docs/methods/03-activites.md` decision 03.6;
`docs/methods/05-structure.md` Open;
`docs/methods/README.md` introduction;
`docs/adr/0003-portable-contract-is-the-product.md`

### 2026-10-15 — Approve two audit moments and remove the cross-species patient measure

The user approves Q18: chapter 00 contains source checks before semantic
mapping and classified profiles/checks after the required mappings, both before
surveillance population selection and deduplication. Each check now states its
recognition, mapping or reference prerequisites. The second moment uses a
mapped representation of the original source population; preserving source
values does not make that representation an untouched raw table. Classification
coverage and unresolved records remain explicit, without requiring an
exhaustive mapping before any audit can run.

Read-only review qualifies several assignments: cross-system identifier and
sex comparisons require documented equivalences; raw-token agreement alone
does not establish semantic concordance. CA-SFM metadata/version checks can
run before microbiological mapping. Repeated literal test labels can be counted
early, while collisions between labels mapped to one antibiotic require that
mapping. Counting isolates requires recognised isolate-bearing records as
well as complete keys.

Decision 03.6 and chapter 05's specimen-mapping note are aligned: available
classifications serve audit needs as well as indicators, with residual
vocabulary counted. The glossary distinguishes semantic mapping from source
representation and surveillance eligibility. The methods index now reflects
chapter 00's ongoing review. Raw inspection and local mappings remain on the
site side of ADR-0003; the transport of findings and portable validation still
need specification.

The user also explicitly approves Q17's removal. The historical 40.83% measure
of patients with at least two isolates across all species is removed from
Suite 6.2's outputs and example discussion. This append-only log preserves its
history. Q15 and Q16 are now unblocked but remain unanswered. No scripts or
source data are changed and no counts are computed.

→ `docs/methods/00-audit-qualite.md` (two audit moments; Suite 6.2; Open);
`CONTEXT.md` (Raw site data; Semantic mapping);
`docs/methods/03-activites.md` decision 03.6;
`docs/methods/05-structure.md` Open;
`docs/methods/README.md` status

### 2026-10-15 — Supersede Q18: chapter 00 is exclusively raw pre-flight

The user explicitly restricts the current review and chapter 00 to raw source
data before semantic mapping. This supersedes the preceding Q18 agreement to
include an after-mapping moment inside chapter 00. Possible checkpoints before
deduplication, after deduplication and after indicators are only ideas for later
review; their organisation is not decided now.

Chapter 00 is aligned throughout: source keys and directly comparable codes,
recorded demographic values, source dates and direct sample–stay links,
literal unit-code membership, native version tags and repeated identical test
codes can be inspected without harmonising taxa, specimens or antibiotics.
Comparisons requiring a crosswalk are not silently performed. Literal labels
are not called species, distinct drugs or evidence of polymicrobial specimens.
Source-key counts still require recognition of the represented entities.

Mapped checks and the historical diagnostic/derived-bundle figures are preserved
in `audit-checkpoints-deferred.md`. This includes intrinsic/phenotype checks,
patient–species distributions and laboratory panel profiles already discussed.
Their prior reporting requirements are retained, while their future placement
and unanswered Q15/Q16 are deferred. Q12/Q17 removals remain in force. Raw-only
6.2 outputs require agreement; approvals for mapped metrics are not silently
reused for different source-label counting units. Preliminary source-level
antibiogram availability remains a requested investigation with an unverified
native evidence/linkage rule.

The temporary 03.6/05 extension made for the two-moment audit is reverted. The
tripwire register no longer places derived structure or phenotype checks inside
raw pre-flight. The glossary and methods index reflect the raw-only scope.
The portable boundary remains unchanged. Findings still trigger no automatic
response; no scripts, mappings or source data are changed or counts rerun.

→ `docs/methods/00-audit-qualite.md`;
`docs/methods/audit-checkpoints-deferred.md`;
`docs/methods/tripwire-register.md`;
`CONTEXT.md` (Raw pre-flight audit)

### 2026-10-15 — Withdraw Q8/Q9 assumptions and propose four raw questions for 6.2

The user explicitly challenges Q8's antibiogram-only population before mapping
and rejects Q9's classified specimen detail. They state that many earlier
reflections must be dropped from the pre-mapping specification. Accordingly,
Q8/Q9 and the dependent mapped metrics are withdrawn from chapter 00. Their
conversation history is archived, without carrying approval into a different
checkpoint. A native field might identify a result type, but this unverified
possibility does not establish an active antibiogram subset or availability
metric. The removed ratios and cross-species patient measure remain removed.

The user also asks for a concise list of the questions 6.2 seeks to answer,
to close the review. Chapter 00 now records a new raw-only closing proposal:
literal specimen/identification/test-label frequencies, literal result-value
frequencies, field completeness and variation by sampling year and year-month.
Its unit is a raw bacteriology row. Missing temporal attribution is explicit;
no specimen classification, species equivalence, drug equivalence or inferred
antibiogram population is applied. These proposed outputs are not presented as
approved by the earlier mapped-statistic answers. Native fields and formats
still require verification before implementation. No scripts, source data or
counts are changed.

→ `docs/methods/00-audit-qualite.md` Suite 6.2;
`docs/methods/audit-checkpoints-deferred.md` (archive status and withdrawn choices)

### 2026-10-15 — Agree the reduced raw-only 6.2 and close its methodological review

The user reviews the proposal before registration, choosing distinct-label
counts and missingness rather than full frequency tables for the original
specimen and identification fields. A separate laboratory analysis/test field
is not included among these two descriptive fields. The result-value table
retains literal S/I/R/ZIT values, rare typo spellings, other values and
missing/empty values without recoding. These summaries are reported by sampling
calendar year and year-month, with unavailable date attribution explicit.
Their unit and frequency/missingness denominator are raw bacteriology rows in
the reporting period; annual distinct counts are recomputed, not summed from
months. This describes source values, not antibiotic resistance rates.

The user first confirms that two isolates each tested for the same ten
antibiotics would count as twenty isolate–test combinations. That settles a
counting distinction, not inclusion in the final profile. Discussion of native
result semantics shows that S/R can also encode phenotype tests, as documented
for BLSE.BLSE1 in the raw witness. After expressing uncertainty about phenotype
results, the user explicitly approves leaving tested-pair counts and all
patient/stay means out of 6.2. No native test classifier or inferred AST subset
is introduced to recover those metrics.

Chapter 00 and its index now mark the 6.2 specification agreed. The rest of the
chapter remains under review; source-field binding and implementation remain
pending. Archived proposals do not acquire approval for another checkpoint.
No scripts, source data or calculations are changed or rerun.

→ `docs/methods/00-audit-qualite.md` Suite 6.2;
`docs/methods/README.md` status;
`docs/methods/audit-checkpoints-deferred.md` status of earlier choices;
`docs/worked-examples/phenotypes_screening_witness.R` (TYPEANA BLSE.BLSE1 and STRRES)

### 2026-10-15 — Review former 6.3 against the agreed raw-only boundary

Review of the former target-pathogen hierarchy applies the user's already
agreed chapter-00 scope. The historical table groups on mapped `bact_norm`,
including species and a species complex, and compares isolate/patient counts,
means, patients with multiple isolates and a beyond-one ratio. These are not
literal-label inventories; the exact source population and preparation rules
for the historical figures remain unverified. An existing raw witness's
textual identification of E. coli does not establish all target assignments
or reproduce the table.

Chapter 00 now explicitly closes 6.3's scope review as outside raw pre-flight,
without introducing a replacement metric or approving its later placement.
Source entity/key counts and literal identification-label counts remain in
6.1 and 6.2 respectively. The archived table is locally annotated: its ratio
does not measure actual deduplication loss, and the counts do not establish
the accompanying clinical explanations. No scripts, data or calculations are
changed or rerun; no new methodological requirement is introduced.

→ `docs/methods/00-audit-qualite.md` Test 6.3;
`docs/methods/audit-checkpoints-deferred.md` (historical target-pathogen table);
`docs/methods/06-donnees-resistance.md` section 6 (taxonomic mapping);
`docs/worked-examples/phenotypes_screening_witness.R` (IDENTIFICATION and source isolate key)

### 2026-10-15 — Review former 6.4 against the agreed raw-only boundary

The former polymicrobial profile concerns specimens with at least two distinct
bacterial species, not simply several isolates or identification strings.
Reliable taxonomic recognition and full `(PATID, ELTID)` specimen grouping are
necessary. Applying the user's already agreed raw-only scope keeps this
profile outside chapter 00, without adding a replacement raw metric or
approving requirements at a later checkpoint. Species co-detection alone does
not establish clinical polymicrobial infection.

No tracked executable reproduction was found for the historical 39 013 /
105 836 or 5 677 / 41 951 figures. Their species recognition, sampling period,
grouping key, missing-value handling and denominator eligibility remain
unverified. The first denominator is not the historical total of distinct raw
ELTID values (507 416); the second matches the historical distinct-ELTID count
in the derived diagnostic table but does not prove which key the calculation
used. The populations are stated differently, so their difference cannot be
presented as a demonstrated processing or deduplication effect.

Chapter 00 records this scope conclusion and the archive now annotates the
limitations beside the historical figures. No scripts, data or calculations
are changed or rerun; no new methodological requirement is introduced.

→ `docs/methods/00-audit-qualite.md` Test 6.4;
`docs/methods/audit-checkpoints-deferred.md` (historical sample counts and polymicrobial figures);
`docs/adr/0007-relational-keys-are-composite-against-recycling.md` (recycled sample accessions);
`CONTEXT.md` (Isolate; Sample / specimen)

### 2026-10-15 — Reorganise raw chapter 00 and make check titles explicit

The user approves an opening source/volume inventory followed by thematic
sections for identifiers, demographics, dates, hospital-unit codes and
laboratory labels/results. They explicitly decline an old-to-new identifier
correspondence and ask for simple titles stating what each description or
check actually examines.

Chapter 00 now places row meanings, counts and complete entity keys at the
start. Laboratory label cardinalities/missingness and raw result frequencies
are together with the other laboratory checks. Sampling-year/year-month
reporting remains a shared rule for those approved descriptions. Titles now
name concrete fields or conditions, such as discharge before admission,
unit codes not found in the supplied structure, and multiple result rows for
the same test and isolate. Missing discharge dates, already reported in the
chapter, have their own explicit heading.

Requirements and historical Rouen observations are separated. Repeated key
definitions and timestamp-threshold notes are consolidated; long withdrawn
question histories and excluded profiles remain in the existing archive.
The methods index and the active identifier-check reference in ADR-0007 are
aligned. No correspondence table is added, and append-only findings are not
rewritten.

The agreed raw scope, literal-value preservation, all-row denominators,
date-attribution rules, exclusion of tested-pair means and documentation-only
response policy are unchanged. The chapter remains under review and source
field verification is pending. No pipeline scripts, source data or
calculations are changed or rerun.

→ `docs/methods/00-audit-qualite.md`;
`docs/methods/README.md`;
`docs/methods/audit-checkpoints-deferred.md` current-status introduction;
`docs/adr/0007-relational-keys-are-composite-against-recycling.md`

### 2026-10-16 — Move the shared audit to standardized input after site mappings

The user explicitly abandons chapter 00's raw-only constraint. The shared
audit now examines the site handoff at the convergence point, after the
mappings needed to produce common input and before population selection and
deduplication. Native raw auditing remains each site's responsibility. Other
hospitals must not reproduce Rouen's raw representation to join the method.

This applies ADR-0003's existing portable boundary. The glossary now separates
local raw examination from the common input audit, and the ADR and agent
instructions record the chapter's position. Coherence of a standardized
handoff does not by itself establish correctness of the local mappings.

The former raw-only chapter is preserved in the review archive. Its literal
source-label inventories, typo frequencies, raw-row denominators and repeated
native-test observations cannot be renamed as portable common-input metrics:
mapping can merge labels, recode results, resolve repeated tests and change
row meaning. Likewise, demographic source histories and raw ID reuse may
not survive preparation. The common schema already has some methodological
concepts, but its complete fields, grains, metadata and unresolved-value
conventions still need consolidation.

Chapter 00 retains the opening inventory and five thematic areas as review
organisation. Its current scope is agreed; check-by-check common-input
specifications remain under review. Mapped checks formerly set aside may be
reconsidered in this context, but no archived metric is automatically restored.
Explicit removals, including the old ratio and cross-species patient measure,
remain in force; tested-pair counts and patient/stay means are not introduced.

The methods index, tripwire boundary notes and references in chapters 06/07
and ADR-0007 are aligned. Local raw CASFM inspection is separated from the
common review of declared interpretation-standard metadata. Existing result
mapping and deduplication decisions are not changed. Findings still trigger
no automatic blocking, correction, quarantine or exclusion. No pipeline
scripts, source data or calculations are changed or rerun.

→ `CONTEXT.md` (Raw pre-flight audit; Common input audit);
`docs/adr/0003-portable-contract-is-the-product.md`;
`docs/methods/00-audit-qualite.md`;
`docs/methods/audit-checkpoints-deferred.md` (superseded raw-only specification);
`docs/methods/tripwire-register.md`;
`docs/methods/06-donnees-resistance.md`;
`docs/methods/07-dedoublonnage.md`

### 2026-10-16 — Retain reviewed Suites 1–5 and revise Suite 6 after the raw-only detour

The user explicitly clarifies that Suites 1–5 had already been reviewed and
must remain. The instruction to drop work arose during the temporary raw-only
detour and is now reversed. The shared input boundary remains after the
necessary mappings, before population selection and deduplication; it is not
a reason to replace the completed checks with a generic review outline.

Chapter 00 restores the detailed identifier, demographic, temporal, annual
structure and microbiological checks. It retains the plain titles, complete
isolate identity, reviewed expectations and source page citations. Intrinsic
resistance and phenotype–AST comparisons are active specifications again.
Positive phenotype with missing corresponding AST remains a separate finding
with the flag retained. The reviewed last-source-row result-resolution rule
is restored, with preparation provenance distinguished from common output
uniqueness. All automatic response policies remain inactive.

Suite 6 again has concrete descriptive requirements. Row versus entity
counts use complete keys; the PMSI movement dataset remains omitted from the
comparative volume table. The patient–species profile recovers the earlier
antibiogram-isolate population, calendar-year/year-month and specimen scopes,
exact count distribution, three totals and three explicit-denominator shares.
The earlier requested distinct-antibiotics-per-isolate distribution and
per-antibiotic recorded-result coverage are retained. These differ from the
excluded raw tested-pair totals and their patient/stay means.

Remaining choices are narrow and visible: linked-antibiogram evidence,
missing/unclassifiable specimen display, antibiotic equivalences, taxonomic
groupings and the target-specimen denominator in 6.4. The species view in
6.3 has no old redundancy-ratio column or clinical causal explanation. The
multiple-target-species profile remains available for review with an explicit
proposed numerator/denominator rather than excluded solely for needing
mapping. Historical counts are not revalidated, and counts removed by actual
deduplication remain in chapter 07. The removed ratio and cross-species
patient measure are not restored.

The methods index, tripwire notes, active key reference and archive status are
aligned. The intermediate raw-only snapshot remains history; it does not
override the restored reviewed specification. No old-to-new ID correspondence
table is added. No pipeline scripts, source data or calculations are changed
or rerun, and no commit or push is performed.

→ `docs/methods/00-audit-qualite.md` Suites 1–6;
`docs/methods/README.md`;
`docs/methods/tripwire-register.md`;
`docs/adr/0007-relational-keys-are-composite-against-recycling.md`;
`docs/methods/audit-checkpoints-deferred.md`
