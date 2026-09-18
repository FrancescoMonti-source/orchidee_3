# Worked example: how deduplication choices move indicators

Measured on real Rouen rows, not on a constructed fixture.

**Slice**: *Escherichia coli*, urines, sampling year 2024, diagnostic scope.
**4963 isolates before deduplication, 4039 distinct patients.**
Source: `bundle_v3/sir_wide.rds` from the v2 pipeline, 48595 isolates and 35
antibiotic columns.

Two choices are normally left implicit, and neither can be applied after the
fact. Both are inputs to deduplication, and deduplication decides which isolates
exist at all.

1. **The antibiotype panel** - which molecules the antibiotype is compared on.
2. **The window** - over what period duplicates are sought.

## The rule being applied

From the SPARES methodology, Annexe 1:

> Un doublon est une souche isolee chez un malade pour lequel une souche de la
> meme espece et de meme antibiotype a deja ete prise en compte durant la
> periode de l'enquete pour un meme type de prelevement a visee diagnostique.

Two antibiotypes differ if, **for at least one molecule tested on both**, there
is a *major* discrepancy (S to R, or ZIT to R). A S/ZIT difference is minor and
does not. Among duplicates the retained isolate is the **oldest** if the same
number of molecules was tested, otherwise the one with **more molecules
tested**. An empty cell is absence of data and does not discriminate.

## Result 1 - the window is the large effect

Same rule, same panel, same rows. Only the period over which duplicates are
sought changes.

| Window | Isolates retained | AMC %R | OFX %R | CTX %R | SXT %R |
|---|---|---|---|---|---|
| **annual** (SPARES) | **4438** | 39.23 | 15.93 | 24.39 | 28.80 |
| **monthly** | **4813** | 39.56 | 16.23 | 25.52 | 29.09 |
| difference | **+8.4 %** | +0.33 | +0.30 | +1.13 | +0.29 |

Deduplicating month by month keeps **375 more isolates over one year on one
species and one sample type** - patients who returned in a later month with the
same organism and the same antibiotype.

Note what this does and does not move. The **proportions barely shift** (+0.3 pp
on three of four columns). The **isolate count rises 8.4 %**, and incidence
density is the isolate count over patient-days, so **every incidence density on
this slice rises 8.4 %** while every proportion looks unchanged.

A validation that compares proportions against ConsoRes and finds them matching
would pass this scenario with all incidence densities wrong by 8.4 %.

## Result 2 - the panel is a real effect, but conditional

Remove **one** antibiotic from the panel and re-run. Nothing else changes. The
removed molecule is not the one being measured.

| Panel | Isolates | OFX %R | SXT %R |
|---|---|---|---|
| full SPARES panel (19 molecules) | 4438 | **15.93** | **28.80** |
| minus amoxicilline-acide clavulanique | 4372 | 16.05 | 28.20 |
| minus amoxicilline-ampicilline | 4425 | 15.95 | 28.82 |
| minus mecillinam | 4415 | 15.91 | 28.66 |
| minus nitrofurantoine | 4433 | 15.87 | 28.79 |
| minus fosfomycine IV | 4433 | 15.92 | 28.84 |

Dropping AMC from the panel removes **66 isolates** and moves **ofloxacine up
0.12 pp while cotrimoxazole moves down 0.60 pp**. Neither indicator involves
amoxicilline-acide clavulanique. They move because AMC was discriminating
between antibiotypes that are otherwise identical, and removing it merges pairs
of isolates into single ones.

**The two indicators move in opposite directions**, so no aggregate sanity check
catches it.

### Why widening the panel changes nothing at Rouen today

The reverse experiment - adding molecules - has **no effect on this slice at
all**. Rouen tests 21 distinct antibiotics on *E. coli* and every one already
reaches an indicator column. Of the 35 supported columns, the only one outside
the SPARES *E. coli* panel that carries any data here is meropenem: 1468
results, **6 of them R**. It almost never discriminates.

This is worth stating plainly because it contradicts the intuitive fear. **The
risk is not breadth. The risk is change.** Any edit to panel composition - a
molecule added, removed, or *remapped* - propagates into indicators that have
nothing to do with it. Widening the panel once, deliberately, costs nothing
here. Changing it repeatedly and silently is what damages comparability.

This is exactly the CLAVENTIN event: see
`docs/evidence/2026-08-02_amc_remapping_cascade.txt`, where correcting a single
antibiotic's mapping removed **51 isolates** from the deduplicated global scope
and moved the denominators of **20 antibiotic columns**.

## Result 3 - annual deduplication makes monthly figures provisional

This one is a property of the rule, not of any implementation.

The tiebreak keeps the isolate with **more molecules tested**, not the earlier
one, whenever the counts differ. That reaches backwards:

- **End of April** - a patient's April isolate is the only one so far, so it is
  retained and April publishes it.
- **End of September** - the same patient returns, same antibiotype, one extra
  molecule tested. The rule now keeps September and drops April. **April's
  published count falls by one.**

A figure already sent to SPF changes because of a sample taken five months
later. Inside an annual window this cannot be avoided, only disclosed - or
traded away by choosing a different window.

## What this implies for the specification

Every published number needs two attributes that no current output carries:

- the **antibiotype panel** it was deduplicated on;
- the **window** it was deduplicated over, and whether it is final or
  provisional.

Without them, two ORCHIDEE numbers are not comparable to each other, let alone
to ConsoRes, and a mapping correction cannot be distinguished from a method
change by anyone reading the output.

## Appendix - the mechanism isolated

The real-data effects above are small per indicator, which makes the mechanism
hard to see. Four rows, one species, one sample type, make it visible. `TCC` is
ticarcilline-acide clavulanique, the CLAVENTIN molecule, outside the SPARES
panel; `FOS` is tested only on the last sample.

| Patient | Sample date | AMC | OFX | CTX | TCC | FOS |
|---------|-------------|-----|-----|-----|-----|-----|
| P1 | 2024-03-04 | R | S | S | S | - |
| P1 | 2024-06-11 | R | S | S | **R** | - |
| P2 | 2024-04-02 | S | R | S | S | - |
| P2 | 2024-09-15 | S | R | S | S | **S** |

- **SPARES panel, annual**: P1's two samples are identical on the panel, so keep
  the oldest. P2's September tested one more, so keep September. **2 isolates**,
  AMC 50 %, OFX 50 %.
- **Full panel, annual**: TCC differs S/R on P1, so they are not duplicates.
  **3 isolates**, AMC 66.7 %, OFX 33.3 %.
- **SPARES panel, monthly**: **4 isolates**, AMC 50 %, OFX 50 %.

Two bolded cells, neither an AMC nor an OFX cell, and both indicators move - in
opposite directions.

## Reproducing

The scripts that produced Results 1 and 2 read
`outputs/rouen_current/bundle_v3/sir_wide.rds` from the `orchidee` repository
and implement the ONERBA rule directly, parameterised by panel and window. They
are not part of any pipeline; they exist to be re-run and disagreed with.
