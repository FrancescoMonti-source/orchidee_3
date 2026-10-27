# Throwaway AMR Python data trial

Question: can AMR for Python map Rouen's raw laboratory labels and calculate a
small resistance table with explicit resistant and tested counts?

This is a local site-adapter experiment, on branch `prototype/amr-python`.
It implements no common input audit or surveillance pipeline. It follows the
explicitly invoked prototype skill.

From the repository root, run:

```powershell
./docs/worked-examples/amr-python-prototype/run.ps1
```

Then double-click `outputs/amr-python-prototype/demo.html`. The generated file
is self-contained: it needs no server or internet connection to explore. It has
free-play controls and three guided walkthroughs: named organisms, ambiguous
labels, and the tested denominator.

Setup uses the existing `uv` command, Python 3.12 and an installed Windows R
(the newest installation under `Program Files/R` by default). Dependencies,
AMR's R library, generated mapping tables and the demo live under ignored
`outputs/amr-python-prototype/`. Setup downloads dependencies when necessary.
The Python script also accepts `--input`, `--year` and `--output`.

## Data and interpretation

- Read `data/bact22_24` directly as an RDS file. No legacy intermediate bundle.
- Select collection dates in 2024 and source results in `S`, `SFP`, `I`, `R`,
  `ZIT`. These are candidate laboratory result rows, including non-antibiotic
  assays. Their label mapping is exploratory.
- Call `AMR.as_mo()` on distinct organism labels. Retain package uncertainty
  diagnostics, failures, suggested identities and source-row frequencies.
  Recognition is not human validation.
- Call `AMR.as_ab()` on distinct result labels and compare suggestions with
  the existing Rouen mapping in `ref/rouen/atb_regex_map.csv`.
- For the small resistance table, use only five exact, recognised species
  names and seven explicitly named source labels and molecule mappings that
  agree with the local mapping. Keep `GENTAMICINE FORTE` labels outside the
  table even though both the package and the legacy mapping fold them into
  ordinary gentamicin. The source label carries an assay distinction requiring
  a local decision. Other suggestions remain review material.
- Declare 19 species-molecule pairs for this trial, rather than taking the
  cross-product of every species and molecule. Count source rows outside
  those pairs separately. These are trial selections, not a protocol manifest.
- Demonstrate `as_mo(reference_df=...)` on `Enterobacter complexe cloacae`:
  an explicit reference preserves `Enterobacter cloacae complex` instead of
  the default subspecies suggestion. Record it as a proposed mapping, without
  applying it to the table or changing the site's dictionary.
- Preserve source isolate identity as `(PATID, ELTID, DLVL)`; `DLVL` supplies
  the local isolate identifier described in chapter 06. Exclude incomplete
  keys and conflicting organism identities from the table, and report counts.
- Map source `SFP`, `I` and `ZIT` to AMR's `I`, then calculate with
  `guideline="EUCAST"`. This keeps them on the susceptible side of the
  resistance proportion, following chapter 06, section 3, and chapter 08.
  Source result categories are reported separately. No MIC or disk result is
  reinterpreted and no expert rule is applied.
- Collapse identical rows for one isolate and molecule. Leave conflicting
  result cells out of this exploratory table and report their number. This
  local trial choice is not an ORCHIDEE audit action or surveillance
  deduplication rule.
- Call `AMR.count_R()`, `AMR.count_all()` and
  `AMR.resistance(minimum=0, guideline="EUCAST")`. Compare each populated cell
  against independent `R / (S + I + R)` arithmetic. Keep small counts visible.

This checkout contains mapping reference files but no prepared microbiology
site handoff. Consequently the trial includes all raw sample types, including
possible screening samples, with no hospital perimeter selection and no
surveillance deduplication. It answers a data compatibility question; the
rates are not ORCHIDEE surveillance indicators. Diagnostic and perimeter
selection would need to precede any later deduplication trial.

Identifiers stay in memory. Generated files contain aggregate counts and
laboratory labels. The run records its input SHA-256 and software versions.
Generated local data artifacts are not committed.

## Windows wrapper workaround

Python AMR 3.1.0 calls R AMR 3.1.0 through `rpy2`. It is not an independent
Python implementation; see the upstream [Python introduction, Introduction and
Prerequisites](https://amr-for-r.org/articles/AMR_for_Python.html).

The installed Python wrapper constructs its version-check expression using a
Windows path inside an R string without escaping backslashes. In this
environment, evaluating that expression caused a native access violation
(`-1073741819`), reproduced with R 4.5.3 and 4.6.1. The equivalent direct R
package call succeeded. Normalising the isolated library path to forward
slashes made the Python wrapper run successfully.

`run.py` applies this one-line workaround to the isolated installation's
`AMR/_engine.py` before importing it. No mapping or resistance algorithm is
changed. This is a locally modified dependency and must be accounted for
before adopting the wrapper in maintained code.

## References

- [Organism mapping: arguments and uncertainty diagnostics](https://amr-for-r.org/reference/as.mo.html).
  The installed 3.1.0 interface uses `minimum_matching_score`; the old
  `allow_uncertain` argument is not a supported control in that version.
  Package uncertainty diagnostics, rather than a presumed strict-matching
  switch, are used here.
- [Antibiotic mapping: Details and custom entries](https://amr-for-r.org/reference/as.ab.html).
- [Resistance: Usage and the minimum argument](https://amr-for-r.org/reference/proportion.html).
- Repository boundaries: [ADR-0003](../../adr/0003-portable-contract-is-the-product.md),
  [chapter 06](../../methods/06-donnees-resistance.md),
  [chapter 08](../../methods/08-indicateurs.md).

## Trial verdict

**Feasible, using AMR as a configurable toolbox in the site adapter.** The actual
Python wrapper ran on the local raw data after the Windows path workaround.
Automatic suggestions need review; they cannot replace the site's mapping
decisions. No production adoption decision is made.

The public archive contains the runnable source and this qualitative verdict.
Measured hospital-data counts, mapping frequencies, proportions and the input
hash remain in ignored local artifacts under `outputs/amr-python-prototype/`.
Open `demo.html` or `summary.json` there to inspect the actual run.

The one-command PowerShell entry point completed successfully. Package counts
and resistance agreed with independent arithmetic. Python and PowerShell syntax
and the repository citation check passed. Local browser checks exercised all
views, both molecule selections and all three walkthroughs, with no browser
errors. No tests, production module, dictionary change or deduplication
implementation was added.
