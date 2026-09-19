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
against 4 428 on the *E. coli* / urines / 2024 slice.
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
implemented ConsoRes had to decide something, and no document says what.
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
