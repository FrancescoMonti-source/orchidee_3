# Worked example: the perimeter is an input, not a filter

Witness for decision 03.2, and the general rule it establishes in
`07-dedoublonnage.md`.

**Slice**: *Escherichia coli*, all sample types, diagnostic scope, sampling year
2024. Annual window, grouping by patient, SPARES panel, `ZIT` read as `SFP`.
Built from `bundle_v3/sir_wide.rds` joined to
`bundle_v3/sample_scope_reference.rds`. Reproduction:
`perimeter_ordering_witness.R`.

The only thing varying is **when** the perimeter is applied.

| | isolates |
|---|---|
| in the extract, all units | 6 519 |
| in eligible units (`TA ∈ {03,20}` ∩ eligible DE) | 2 868 (44 %) |
| **A — perimeter, then deduplicate** | **2 445** |
| **B — deduplicate, then perimeter** | **2 350** |
| difference | **−95, −3.9 %** |
| **patients lost entirely under B** | **79** |

| Molecule | A %R (n) | B %R (n) | shift |
|---|---|---|---|
| amoxicilline-ac. clavulanique | 39,92 (2380) | 40,01 (2287) | +0,09 pp |
| céfotaxime | 14,80 (1372) | 14,55 (1333) | −0,25 pp |
| ofloxacine | 14,74 (2245) | 14,58 (2160) | −0,16 pp |
| cotrimoxazole | 30,03 (2381) | 29,97 (2292) | −0,06 pp |
| gentamicine | 6,76 (2248) | 6,47 (2163) | −0,29 pp |
| ertapénème | 0,29 (2430) | 0,30 (2337) | +0,01 pp |

Every proportion moves by less than a third of a point. Every incidence density
moves 3.9 %. This is the same signature as the deduplication window: the choice
is invisible in the rates and visible in everything carrying a denominator of
patient-days.

## The mechanism

The 79 lost patients each had **two** diagnostic *E. coli* isolates in 2024: one
in a unit inside the perimeter, one earlier in a unit outside it, with no major
discrepancy between their antibiotypes.

- **Order A.** The outside isolate is removed first. The inside isolate is the
  only candidate, is retained, and the patient contributes 1.
- **Order B.** Both isolates enter deduplication. The earlier one wins on the
  oldest-sample rule, so the outside isolate becomes the patient's
  representative. The perimeter filter then deletes it, and the patient
  contributes 0 — taking a legitimate in-perimeter isolate with it.

## Why this generalises

Deduplication is **not monotone**. Removing a row from its input can add a row
to its result, because both the antibiotype comparison and the
more-molecules-tested tiebreak depend on which other isolates are present for
that patient.

The consequence is not a fact about perimeters, and it was not a fact about
screening either — the screening exclusion exhibits the identical hazard and was
recorded as if it were specific to screening
(`screening-exclusion.md`, *"The order is part of the rule"*).

> **Any selection on isolates is an input to deduplication, never a filter on
> its output.**

Which makes the population selection the fifth input alongside the grouping key,
the window, the antibiotype panel and the conflict rule — and it means a
published number that does not name its population is as incomplete as one that
does not name its window.

## What it does not show

This is one site, one organism, one year. The 3.9 % is not a constant: it is the
rate at which Rouen's patients have *E. coli* isolated in more than one unit
within a year, which varies with transfer practice and case mix. What is
invariant is the sign. Order B can only ever lose isolates relative to order A,
never gain them, because the perimeter can only delete a representative and
never elect one.
