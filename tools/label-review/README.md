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
| 0 | `inventory.R` | Where the raw data is | `data/bact22_24` (and, optionally, a site-inputs table carrying the local diagnostic flag) | Aggregate label tables in `outputs/label-review/` |
| 1 | `pass1-amr.R` | Anywhere with AMR 3.1.0 | The aggregate tables, `ref/rouen/atb_regex_map.csv` | `organism-pass1.csv`, `antibiotic-pass1.csv` |

`inventory.R` writes counts per label and never writes or prints a patient,
stay, sample or isolate identifier. It does not classify samples as diagnostic
or screening: when a site-inputs table is supplied it reads the site's own
flag.

Counts measured on hospital data stay in the ignored `outputs/` directory.
Only the scripts and the proposals (labels and identities, no counts) are
versioned.

```sh
Rscript --vanilla tools/label-review/inventory.R [raw_RDS [output_dir [site_inputs_RDS]]]
Rscript --vanilla tools/label-review/pass1-amr.R [output_dir]
```
