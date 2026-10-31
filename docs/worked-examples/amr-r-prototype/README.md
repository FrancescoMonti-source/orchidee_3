# Throwaway AMR classification explorer

Question: can AMR add useful organism and antibiotic classifications to our
local labels while preserving the uncertainty of their proposed mappings?

This is a local site-adapter experiment on branch `prototype/amr-demo-ergonomics`.
It extends the label review on `prototype/amr-label-review`, classification
trial on `prototype/amr-classification`, direct R trial on `prototype/amr-r`
and preceding Python version on `prototype/amr-python`. The prototype
implements no common input audit or surveillance pipeline.

From the repository root on Windows:

```powershell
./docs/worked-examples/amr-r-prototype/run.ps1
```

Or, with `Rscript` available:

```sh
Rscript --vanilla docs/worked-examples/amr-r-prototype/run.R
```

Then double-click `outputs/amr-classification-prototype/demo.html`. The demo
is self-contained and needs no server. Explore every source label, choose a
classification level and group, select a mapping status, and search. Click a
source label to inspect its full classification and other labels sharing the
same proposed AMR code.

The page follows controls, selected source label, then the matching-label table.
Previous/Next move through the current filtered list. Clear filters keeps the
current view; Reset demo returns to the initial view and closes optional panels.
Inspecting a table row preserves the list scroll position and keyboard focus.

Walkthroughs are collapsed above the controls, so they do not interrupt the
control-to-result relationship. Long ATC-code lists and explanatory material
are expandable within the selected-label card. Full selection state and run
provenance remain available under Run details. The earlier-table usage flag is
labelled "Used in resistance demo" to make its limited meaning clearer.

Four guided walkthroughs cover organism hierarchy, complex versus subspecies,
antibiotic classifications and preservation of source assay distinctions.
The earlier mapping, resistance views and three walkthroughs remain accessible
under expandable controls.

## Chosen direction and label review

The user chose AMR to replace the DIY bacterial mapping, with a small set of
local corrections. The prototype already uses AMR for organism suggestions.
There is no production surveillance runner in this checkout to switch yet.
Antibiotic mapping will also build on AMR; a finite local label review supplies
the corrections and preserves assay or interpretation distinctions.

The inputs reviewed here are `LBLANA` antibiotic/test labels, including some
technical and comment fields. They are not sample labels. Sample-type mapping
remains local and is a settled, separate responsibility.

After running the classification trial, prepare the draft review with:

```sh
Rscript --vanilla docs/worked-examples/amr-r-prototype/prepare-antibiotic-review.R
```

Open `outputs/amr-classification-prototype/antibiotic-label-review.md`. It covers
the complete label list, groups the proposed changes and unresolved meanings,
and retains the original suggestions for comparison. It applies no decisions.

Technical/comment fields stay outside molecule-name matching, while remaining
available for separate handling. Context-labelled antibiotic results retain
their molecule and their recorded context separately; a label containing
MENINGITE is not converted into a screening-test identity or a sample type.
Compound test labels and underspecified families retain an explicit local
meaning question. No surveillance selection or deduplication rule is added.

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

## What the classifications mean

All mapped organism suggestions receive AMR's taxonomic rank, organism type,
Gram stain, taxonomic class, order, family and genus. Explicit species/complex
memberships come from `AMR::microorganisms.groups`. Missing properties remain
missing; the prototype invents no more precise classification for an unknown
identity. Properties still describe a suggestion when its mapping is uncertain.
An unflagged suggestion remains distinct from human validation.

All mapped analysis suggestions receive AMR's drug group, ATC broad class and
subgroup, and every ATC code supplied by the reference. ATC means Anatomical
Therapeutic Chemical, a classification of medicines. A catalogue drug can have
several codes for different uses, including veterinary uses. No formulation is
inferred from those codes.

Five real AMR class selectors demonstrate overlapping membership: beta-lactams,
third-generation cephalosporins, carbapenems, fluoroquinolones and aminoglycosides.
They use `only_treatable=TRUE`; this affects the catalogue membership, not which
source labels are retained in the explorer. No drug class is guessed from a
local name in JavaScript.

Every source label remains separate even when several share the same proposed
code. In particular, an antibiotic classification does not resolve a local
assay distinction such as high-level gentamicin testing. Selection for the
earlier resistance table is shown as a trial choice, not a general mapping
approval. Frequencies are source result-row counts, never isolate counts.

For the high-level gentamicin labels, show the separate `GEN` and `GEH`
catalogue entries and compare `aminoglycosides(only_treatable=TRUE/FALSE)`.
The high-level test identity is available; adopting it for the French labels
requires a local decision. The comparison does not change their current mapping.

The walkthrough also exposes non-antibiotic comment labels that receive a drug
suggestion and inherit its class. Source-field eligibility and mapping review
must precede adoption of grouped counts. An AMR drug group and an ATC subgroup
can select different rows because some candidate identities lack ATC metadata.

The explicit complex-reference example additionally compares taxonomic ranks
and orders, showing how a complex can retain its broader identity while still
receiving a useful order/family/genus classification.

Sample type and infection context are different concepts. Sample-type mapping
and diagnostic selection remain local preparation; neither is added here.

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
- [Organism properties: taxonomy, rank and Gram stain](https://amr-for-r.org/reference/mo_property.html).
- [Antibiotic properties: drug groups and ATC](https://amr-for-r.org/reference/ab_property.html).
- [Antibiotic class selectors and their arguments](https://amr-for-r.org/reference/antimicrobial_selectors.html).
- [Explicit species/complex memberships](https://amr-for-r.org/reference/microorganisms.groups.html).
- [Resistance: usage and the minimum argument](https://amr-for-r.org/reference/proportion.html).
- Repository boundaries: [ADR-0003](../../adr/0003-portable-contract-is-the-product.md),
  [chapter 06](../../methods/06-donnees-resistance.md),
  [chapter 08](../../methods/08-indicateurs.md).

## Trial verdict

**Classification is feasible as an enrichment of proposed identities.** AMR
supplies organism hierarchy and antibiotic groups directly. Taxonomic rank,
ATC groupings and overlapping selector membership can be explored without
flattening complexes or merging source assay labels. The package's clear
classification of a candidate identity does not validate the source mapping.

The local run completed, each populated resistance cell agreed with independent
arithmetic, and syntax, citation and browser checks passed. No tests, production
core, site dictionary or surveillance deduplication implementation were added.

The archive contains runnable source and a qualitative verdict only. Measured
hospital-data counts, mapping frequencies, proportions and input hash stay in
ignored local artifacts under `outputs/amr-classification-prototype/`. Open
`demo.html` or `summary.json` there to inspect the run.
