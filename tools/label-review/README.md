# Label review: three passes, one sheet

Site-adapter tooling for Rouen. It prepares the review of every source label
(organism labels from `IDENTIFICATION`, antibiotic and test labels from
`LBLANA`) before any mapping is approved.

The procedure has three passes, and their answers never share a column:

1. **AMR pass.** `AMR::as.mo()` and `AMR::as.ab()` (AMR 3.1.0) suggest an
   identity for each label. A suggestion is recognition, not approval.
2. **Assistant pass.** A proposed mapping for every label, with a point to
   check. It is a guess prepared for review, never a mapping.
3. **Microbiologist pass.** A microbiologist accepts or corrects every line.
   Only this column can become a mapping.

## Steps

| Step | Script | Runs where | Reads | Writes |
|---|---|---|---|---|
| 0 | `list-labels.R` | Where the raw data is | `data/bact22_24` | `organism-labels.csv`, `antibiotic-labels.csv` in `outputs/label-review/` |
| 1 | `pass1-amr.R` | Anywhere with AMR 3.1.0 | The label lists, `ref/rouen/atb_regex_map.csv` | `organism-pass1.csv`, `antibiotic-pass1.csv` |
| 2 | (hand-written) | Anywhere | The pass-1 tables | `claude-pass-organisms.csv`, `claude-pass-antibiotics.csv` |
| 3 | `build-sheet.py` | Anywhere with Python and `openpyxl` | Pass 1 and pass 2 | `revue-libelles.xlsx` |

```sh
Rscript --vanilla tools/label-review/list-labels.R [raw_RDS [output_dir]]
Rscript --vanilla tools/label-review/pass1-amr.R [output_dir]
python3 tools/label-review/build-sheet.py [output_dir]
```

## Nothing is counted

The review is about what a label means, not how often it occurs. So
`list-labels.R` writes the laboratory's vocabulary and no number:

- the label;
- whether it ever carries an S, SFP, I, R or ZIT result;
- the sampling years it appears in;
- for an antibiotic label, the organism labels it is reported on, most
  frequent first.

It writes no identifier, no sample text and no result value, and it does not
read the identifier columns into its working table. With no count there is
nothing to mask.

The lists, the workbook and the proposals written from the hospital's own
label list stay in the ignored `outputs/` directory. Only the scripts are
versioned. The two `claude-pass-*.csv` files next to the scripts are format
examples.

## The assistant pass

Each proposals file has three columns: `source_label`, `proposal` and `note`.
They fill the "proposed mapping" and "point to check" columns of the sheet.

`claude-pass-organisms.csv` holds the organism labels that need a written
proposal. A label that AMR recognises without a flag, and whose AMR name is
the label itself, needs no line: the sheet then shows AMR's name. Every other
label that carries a result needs a line.

`claude-pass-antibiotics.csv` holds one line per antibiotic or test label that
carries a result. A proposal names the molecule with its AMR drug code, then
the test, then the formulation or the reading context when the label has one,
for example `Amoxicilline/acide clavulanique [AMC] ; antibiogramme ; cystite`.
The file may also hold labels that never carry a result but speak about
resistance (comments, searches for resistant bacteria, gene tests). The other
labels of that field are left out of the sheet.

## The sheet

`build-sheet.py` takes the proposals from the output directory when they are
there, and from next to the script otherwise. It stops when a label that
carries a result has no proposal, so no line reaches the reviewer without a
best guess.

The workbook is written in French for the reviewer. It has one tab for
organisms and one for antibiotics and tests, sorted by label, with seven
columns: laboratory label, AMR 3.1.0, ORCHIDEE v2, proposed mapping, point to
check, microbiologist decision (`Accepter`, `Corriger`, `Incertain`) and
correction or comment. The last two are always written empty: only a person
fills them.
