# Label review: three passes, three columns

Site-adapter tooling for Rouen. It prepares the review of every source label
(organism labels from `IDENTIFICATION`, antibiotic and test labels from
`LBLANA`) before any mapping is approved.

The procedure has three passes, and their answers never share a column:

1. **AMR pass.** `AMR::as.mo()` and `AMR::as.ab()` (AMR 3.1.0) suggest an
   identity for each label. A suggestion is recognition, not approval.
2. **Assistant pass.** A proposed identity for every label, with a confidence
   level and a reason. It is a guess prepared for review, never a mapping.
3. **Microbiologist pass.** A microbiologist approves or corrects every line.
   Only this column can become a mapping.

## Steps

| Step | Script | Runs where | Reads | Writes |
|---|---|---|---|---|
| 0 | `inventory.R` | Where the raw data is | `data/bact22_24` (and, optionally, a site-inputs table carrying the local diagnostic flag) | Masked aggregate label tables in `outputs/label-review/` |
| 1 | `pass1-amr.R` | Anywhere with AMR 3.1.0 | The aggregate tables, `ref/rouen/atb_regex_map.csv` | `organism-pass1.csv`, `antibiotic-pass1.csv` |
| 2 | (hand-written) | Anywhere | The pass-1 tables | `claude-pass-antibiotics.csv`, `claude-pass-organisms.csv`, `claude-pass-other-fields.csv` |
| 3 | `build-sheet.py` | Anywhere with Python and `openpyxl` | Pass 1 and pass 2 | `revue-libelles.xlsx`, `review-antibiotics.csv`, `review-organisms.csv`, `review-other-fields.csv` |

```sh
Rscript --vanilla tools/label-review/inventory.R [raw_RDS [output_dir [site_inputs_RDS]]]
Rscript --vanilla tools/label-review/pass1-amr.R [output_dir]
python3 tools/label-review/build-sheet.py [output_dir]
```

## What the inventory writes

`inventory.R` writes counts per label. It does not classify samples as
diagnostic or screening: when a site-inputs table is supplied it reads the
site's own flag.

Its tables are masked by construction, so that they can be read outside the
machine that holds the raw data:

- No patient, stay, sample or isolate identifier is written or printed.
- A count of 1 to 9 is written `<10`.
- A label carried by fewer than 10 patients keeps its total. Its splits (by
  year, by result, diagnostic) are written `masked`.
- When one cell of a split is masked, the smallest other cell is rounded to
  the nearest ten and written with a tilde (`~120`), so that subtraction does
  not give the masked cell back.
- Free text never leaves. Sample natures are not written. A result value of a
  comment field is listed only when it is short, frequent and shared by 10
  patients or more, and looks neither like a number nor like initials. The
  other values are counted, not shown.

Everything measured on hospital data stays in the ignored `outputs/`
directory: the tables, the workbook, and the proposals written from the
hospital's own label list. Only the scripts are versioned. The two
`claude-pass-*.csv` files next to the scripts are format examples.

## The assistant pass

`claude-pass-antibiotics.csv` holds one line per antibiotic or test label that
carries an S, SFP, I, R or ZIT result. Its columns are the typed parts of an
antibiotic-result identity: the kind of row, the molecule as an AMR drug code,
the test, the formulation, the reading context (`meningitis`, `cystitis`,
`pneumonia`, `other_contexts`) and a free qualifier. `A|B` is a joint identity
(either molecule); `A+B` is a combination test.

`claude-pass-organisms.csv` holds the organism labels that need a written
proposal. A label that AMR recognises without a flag, and whose AMR name is
the label itself, needs no line. Every other label does.

`claude-pass-other-fields.csv` holds labels of the antibiotic field that never
carry such a result but speak about resistance: comments, searches for
resistant bacteria, gene tests. Labels of that field with no line (cytology,
serology and other analyses) are left out of the workbook.

`build-sheet.py` takes the three files from the output directory when they are
there, and from next to the script otherwise. It stops when a label with a
result has no proposal, so no line reaches the reviewer without a best guess.
The workbook is written in French for the reviewer. It has one tab per file
and sorts the lines where AMR and the assistant disagree first. Its approval
columns are always empty: only a person fills them.
