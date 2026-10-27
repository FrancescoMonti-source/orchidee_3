# Throwaway AMR R data trial

Question: can AMR map Rouen's raw laboratory labels and calculate a small
resistance table directly in R, reproducing the preceding Python-wrapper trial?

This is a local site-adapter experiment on branch `prototype/amr-r`. It implements
no common input audit or surveillance pipeline. The preceding Python version is
archived on `prototype/amr-python`; this version runs the R package directly.

From the repository root on Windows:

```powershell
./docs/worked-examples/amr-r-prototype/run.ps1
```

Or, with `Rscript` available:

```sh
Rscript --vanilla docs/worked-examples/amr-r-prototype/run.R
```

Then double-click `outputs/amr-r-prototype/demo.html`. The self-contained demo
has free-play controls and three guided walkthroughs: named organisms, ambiguous
labels, and the tested denominator. It needs no server to explore.

Setup uses an installed R and installs AMR 3.1.0 if needed. Supporting packages
are `data.table`, `jsonlite` and `digest`; missing packages are installed into
the ignored output directory. No Python runtime or wrapper patch is involved.
The PowerShell entry point selects the newest R under `Program Files/R`, or
accepts `-RHome`; use `-Year` to change the year. The R script accepts positional
arguments `year`, `input_RDS` and `output_directory`.

## What the mapping list contains

Read `data/bact22_24` directly as an RDS file. Select collection dates in 2024
and recorded results in `S`, `SFP`, `I`, `R`, `ZIT`. Map **every distinct,
non-missing organism label in that population**, with no frequency cutoff or
manually selected organism list. These are source labels, not necessarily
distinct species: multiple labels may describe the same organism. This is not
the complete vocabulary across all years or rows without those result codes.

Call `AMR::as.mo()` and retain uncertainty diagnostics, suggested identities,
failures and source-row frequencies. Recognition is not human validation.
Keep missing source identifications outside the label list and count their
rows separately. Treat AMR's `UNKNOWN` code as an unmapped suggestion. These
correct the preceding Python run's missing-value and mapping-status display;
its missing-value placeholder was counted as a label.
Call `AMR::as.ab()` on every distinct result label in the same population;
these include non-antibiotic assays. Compare its suggestions with the existing
Rouen mapping in `ref/rouen/atb_regex_map.csv`, treated as a comparator.

## What the resistance table contains

The small resistance table is deliberately selected: five exact recognised
species names, seven explicitly named antibiotic source labels, and 19 declared
species-molecule pairs. Require agreement with the existing local molecule
mapping. Leave `GENTAMICINE FORTE` outside even when both mappings call it ordinary
gentamicin: the source label carries an assay distinction requiring a local
decision. Other automatic suggestions remain review material.

Preserve source isolate identity as `(PATID, ELTID, DLVL)`. Exclude incomplete
keys, conflicting organism identities and conflicting isolate-molecule results,
and report their counts. Collapse identical rows within one isolate-molecule
cell. This is source-row handling, not surveillance deduplication.

Map source `SFP`, `I` and `ZIT` to AMR's `I`, preserving the explicit local choice
in chapter 06, section 3, and chapter 08. Call `AMR::count_R()`, `AMR::count_all()`
and `AMR::resistance(minimum=0, guideline="EUCAST")`. Compare every populated
cell with independent `R / (S + I + R)` arithmetic. Small counts stay visible;
no MIC or disk measurement is reinterpreted and no expert rule is applied.

Demonstrate `as.mo(reference_df=...)` on `Enterobacter complexe cloacae` to
preserve the complex identity. This is a proposed explicit site reference;
it is not adopted in the resistance table or the site's dictionary.

All raw sample types, including possible screening, remain in this trial.
Diagnostic selection, hospital perimeter selection and surveillance
deduplication have not been applied. The rates are exploratory compatibility
results, not ORCHIDEE surveillance indicators. Selection must precede any
later deduplication trial.

Identifiers stay in memory. Generated local artifacts contain aggregate tables,
laboratory labels, input SHA-256 and software versions. They are ignored by Git.

## References

- [Organism mapping: arguments and uncertainty diagnostics](https://amr-for-r.org/reference/as.mo.html).
- [Antibiotic mapping: details and custom entries](https://amr-for-r.org/reference/as.ab.html).
- [Resistance: usage and the minimum argument](https://amr-for-r.org/reference/proportion.html).
- Repository boundaries: [ADR-0003](../../adr/0003-portable-contract-is-the-product.md),
  [chapter 06](../../methods/06-donnees-resistance.md),
  [chapter 08](../../methods/08-indicateurs.md).

## Trial verdict

**Direct R is sufficient for this trial.** It calls the same AMR package without
the Python bridge or its Windows path workaround. The resistance table agrees
with the previous run. Mapping suggestions agree after correcting the earlier
missing-value placeholder and failed-mapping statuses. The source mapping CSV
is read explicitly as UTF-8 so accented labels retain the existing mapping.

The local run completed, each populated resistance cell agreed with independent
arithmetic, and syntax, citation and browser checks passed. No tests, production
core, site dictionary or surveillance deduplication implementation were added.

The archive contains runnable source and a qualitative verdict only. Measured
hospital-data counts, mapping frequencies, proportions and input hash stay in
ignored local artifacts under `outputs/amr-r-prototype/`. Open `demo.html` or
`summary.json` there to inspect the run.
