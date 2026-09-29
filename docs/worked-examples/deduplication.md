# Worked example: how deduplication choices move indicators

Measured on real Rouen rows, not on a constructed fixture. Remeasured
2026-09-27 with BLSE/carbapenemase comparison and decision 07.6's
all-members grouping. The source bundle is provisional because its site
mappings have not been reviewed.

**Slice**: *Escherichia coli*, urines, sampling year 2024, diagnostic scope.
**4 963 isolates before deduplication, 4 039 distinct patients.**
Source: `outputs/rouen_stage2_2024/bundle_v3/sir_wide.rds`, built by the v2
pipeline; 48 595 records and 35 supported antibiotic columns.

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
sought changes:
- **Annual window (SPARES convention)**: A patient can contribute at most one isolate per antibiotype profile across the entire calendar year.
- **Monthly window**: Deduplication is performed within each calendar month independently; a patient returning in a later month with the same profile is retained again. The row below represents the pooled 12-month surveillance total ($\sum R / \sum N_{\text{tested}}$).

| Window Parameter | Deduplicated Isolates | AMC %R ($n / N_{\text{tested}}$) | OFX %R ($n / N_{\text{tested}}$) | CTX %R ($n / N_{\text{tested}}$) | SXT %R ($n / N_{\text{tested}}$) | Slice Incidence Density (/1 000 JH)* |
|---|---|---|---|---|---|---|
| **Annual (SPARES)** | **4 441** | 39.23 % (1 740 / 4 435) | 15.94 % (632 / 3 964) | 24.37 % (341 / 1 399) | 28.84 % (1 272 / 4 411) | **12.50 / 1 000 JH** |
| **Monthly (Pooled)** | **4 814** | 39.58 % (1 902 / 4 806) | 16.23 % (699 / 4 308) | 25.52 % (370 / 1 450) | 29.11 % (1 391 / 4 779) | **13.55 / 1 000 JH** |
| **Shift ($\Delta$)** | **+373 (+8.40 %)** | **+0.34 pp** | **+0.28 pp** | **+1.14 pp** | **+0.27 pp** | **+1.05 / 1 000 JH (+8.40 %)** |

*\*Incidence density measured over Rouen 2024 eligible inpatient exposure (355 246 JH).*

### Key methodological takeaways from this comparison:

1. **The denominator disclosure matters**:
   Cefotaxime (CTX) was tested on **31.5 % of isolates** (1 399 / 4 441), while amoxicillin-clavulanate (AMC) was tested on **99.9 %** (4 435 / 4 441). The CTX proportion moves by +1.14 percentage points, compared with +0.34 pp for AMC. Reporting $n / N_{\text{tested}}$ prevents readers from mistaking cascade-testing artifacts for true microbiological divergence.

2. **Divergence of metric types (Proportions vs. Densities)**:
   - **The widely tested proportions move modestly**: AMC, OFX and SXT shift by +0.27 to +0.34 percentage points; CTX, tested on a selected subset, shifts by +1.14 pp.
   - **Isolate counts and incidence density move by +8.40 %**: Because incidence density is defined as $\frac{\text{Isolates retained} \times 1\,000}{\text{Exposure (JH)}}$, retaining 373 additional monthly isolates moves the slice incidence density from **12.50 to 13.55 / 1 000 JH**.

3. **The percentage-only validation trap**:
   Comparing only the widely tested proportions could make the annual and monthly results appear similar, but CTX moves by +1.14 pp and all isolate counts and incidence densities change by **+8.40 %**. Surveillance engines must validate both resistance proportions and isolate volume counts.

## Result 2 - the panel is a real effect, but conditional

Remove **one** antibiotic from the panel and re-run. Nothing else changes. The
removed molecule is not the one being measured.

| Panel | Isolates | OFX %R (R / tested) | SXT %R (R / tested) |
|---|---:|---:|---:|
| full SPARES panel (19 molecules) | 4 441 | **15.94** (632 / 3 964) | **28.84** (1 272 / 4 411) |
| minus amoxicilline-acide clavulanique | 4 376 | 16.06 (627 / 3 904) | 28.23 (1 227 / 4 347) |
| minus amoxicilline-ampicilline | 4 429 | 15.99 (632 / 3 953) | 28.87 (1 270 / 4 399) |
| minus mecillinam | 4 418 | 15.92 (628 / 3 944) | 28.69 (1 259 / 4 388) |
| minus nitrofurantoine | 4 436 | 15.89 (629 / 3 959) | 28.82 (1 270 / 4 406) |
| minus fosfomycine IV | 4 437 | 15.93 (631 / 3 960) | 28.86 (1 272 / 4 407) |

Dropping AMC from the panel removes **65 isolates** and moves **ofloxacine up
0.12 pp while cotrimoxazole moves down 0.61 pp**. Neither indicator involves
amoxicilline-acide clavulanique. AMC discriminated between antibiotypes that
are otherwise identical, so removing it merges pairs of isolates. The full
35-column supported panel and the 19-molecule SPARES panel retain the same
4 441 isolate IDs in this slice.

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

## Result 2b - conflict interpretation changes the retained set

Using the current selected interpretation (`ZIT` read as `SFP`) retains
4 441 isolates. Treating `ZIT` as never conflicting retains 4 431. On AMC,
the selected interpretation gives 1 740 / 4 435 = 39.23 %R; the alternative
gives 1 733 / 4 425 = 39.16 %R. The full-panel and SPARES-panel runs agree
for both interpretations.

## Result 3 - why slicing an annual deduplication window produces retrospective instability

This result explains why an annual deduplication window cannot simply be sliced into monthly surveillance reports.

If monthly reports are generated by slicing a single year-to-date annual deduplication run, the tiebreak rule (which favors the isolate with **more molecules tested** over the earlier date) reaches backwards across months:

- **End of April** - a patient's April isolate is the only one so far, so it is
  retained and April publishes it.
- **End of September** - the same patient returns, same antibiotype, one extra
  molecule tested. The annual rule now keeps September and drops April. **April's
  published count falls by one.**

A surveillance figure already communicated to hospital committees or SPF would change because of a sample taken five months later.

### ORCHIDEE's Resolution: Two Distinct Surveillance Models

To prevent this instability:

1. **Current Production Policy (Independent Closed Windows — Model 1)**:
   Monthly surveillance runs under an independent monthly window (`window = "monthly"`). Deduplication is performed within each calendar month in isolation. Published monthly indicators are **final, closed, and immutable** upon month close; no subsequent hospitalization in September can alter April's count.
2. **Annual Surveillance (Model 2)**:
   The annual indicator table is a distinct measurement under `window = "annual"`, not the arithmetic sum of the twelve monthly tables.
3. **Rolling Refractory Window (Experiment)**:
   A rolling refractory window (e.g. 30-day episode window from the initial isolate, as outlined in Decision 07.2) would eliminate calendar boundary artifacts. It is an ORCHIDEE experiment, not the ECDC / EARS-Net standard, which keeps the first blood or CSF isolate per patient and pathogen in the calendar year (ECDC reporting protocol 2025, pp. 22, 24-25). The nearest published rule is Japan's JANIS (Kajihara et al., PLoS ONE 2020;15(6):e0228234).

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
and implement the ONERBA rule (pp. 26-27) directly, parameterised by panel and window. They
are not part of any pipeline; they exist to be re-run and disagreed with.
