# Worked example: incomplete antibiograms in the duplicate comparison

Witness for decisions 07.6 and 07.7 in `07-dedoublonnage.md`: when blank
results make the duplicate comparison ambiguous, which isolates does a new
isolate get compared with, and what happens to isolates sampled at the same
date and hour? Chosen: every isolate of the group; ties ordered by `ELTID`.

**Slice**: every species and every diagnostic sample type in the eligible
perimeter, calendar years 2022, 2023 and 2024 separately. One comparison group
is one patient, one species, one sample type and one year. An isolate with an
unknown sample type is never compared with another. Built from a provisional
bundle, `outputs/rouen_stage2_2024/bundle_v3/sir_wide.rds`, that the v2 pipeline
built from `data/bact22_24` and `data/pmsi` (`build_manifest.txt` records the
commit, the mappings and the md5 of both inputs). The v2 mappings are not
reviewed for ORCHIDEE, so the counts are provisional. Reproduction:
`incomplete_antibiotypes_witness.R`.

## What the sources say

SPARES (pp. 10-11) and SPF (pp. 14-15) give the same rule, in the same words:

- Two isolates are compatible (the sources say « même antibiotype ») when there
  is no major discrepancy (S↔R or SFP↔R) on any molecule both were tested with.
- Among compatible isolates, the isolate kept is the one with more molecules tested; if
  the counts are equal, the oldest.
- A blank antibiotic result is missing data and does not count as a difference.
- The BLSE and carbapenemase phenotypes are also compared, and a blank phenotype
  cell means the phenotype is absent.

The rule comes from ONERBA's 2000 recommendations (pp. 25-27), which both
documents cite. ONERBA defines the original isolate as a « souche dont la
combinaison espèce/antibiotype n'a pas encore été répertoriée pour le sujet »:
each later isolate is compared with the originals already counted, and an
original is never replaced. ONERBA assumes a standard panel, so it has no rule
for blank results.

## What the sources do not say

ConsoRes added two things to ONERBA: blank results do not count as differences,
and a duplicate with more molecules replaces the kept isolate. Together they
create a gap. No source says:

1. what a new isolate is compared with after a replacement: the kept isolate,
   the first isolate of the group, or every isolate of the group;
2. what happens when a new isolate is compatible with two kept isolates that
   have a major discrepancy with each other;
3. which isolate is the oldest when two share the same date and hour.

## The case

Same patient, species, sample type and year.

| Isolate | Ofloxacine | Molecules tested | Compatible with |
|---|---|---:|---|
| A, first | S | 2 | B |
| B, second | blank | 3 | A and C |
| C, third | R | 2 | B |

A and C have a major discrepancy, so they are not compatible. B is a **bridging
isolate**: its blank result makes it compatible with both.

| Way to compare | Kept | Ofloxacine for this patient |
|---|---|---|
| With the kept isolate, which a replacement takes over (current witness code) | B | nothing: the S and the R are both lost |
| With the first isolate, never replaced (ONERBA) | A, C | S and R |
| With every isolate of the group | B, C | R only |
| With the first isolate of the group | B, C | R only |
| Merge every chain of compatible isolates | B | nothing |

With "every isolate of the group", two isolates with a major discrepancy are
never in the same duplicate group. The other ways that keep the retention
rule do not guarantee this.

## Measured at Rouen

| | 2022 | 2023 | 2024 |
|---|---:|---:|---:|
| isolates in the eligible perimeter | 8 623 | 8 877 | 8 933 |
| comparison groups with 2 or more isolates | 780 | 830 | 765 |
| bridging isolates | 5 | 2 | 2 |
| ambiguous groups (duplicate groups not unique) | 7 | 2 | 4 |
| ...where the fewest-groups split has one answer, the one "every isolate" gives | 7 | 2 | 4 |
| groups where "every isolate" differs from the current code | **0** | **0** | **0** |
| groups where "first isolate of the group" differs | 1 | 0 | 1 |
| groups where "merge every chain" differs | 7 | 2 | 4 |
| groups where ONERBA's "never replaced" differs | 107 | 126 | 95 |
| isolates compatible with two different kept isolates | 4 | 1 | 1 |

**The A/B/C failure did not occur in three years.** A bridging isolate has no
result for the molecule that shows the discrepancy, so it usually has fewer
molecules than its neighbours and does not replace them. Comparing with every
isolate of the group gives the same kept isolates as the current code in every
group, so it costs nothing at Rouen and guarantees the property above.

**Comparing with the first isolate of the group does break it.** In the 2024
case (*Serratia marcescens*, urines), the first isolate has no mecillinam
result. The next two have mecillinam R, the fourth has mecillinam S. All three
are compatible with the first isolate, so they join its group, and the retention
rule keeps an R isolate and drops the S one. The 2022 case
(*Enterobacter cloacae* complex, blood culture, ertapénème) is the same pattern.

### What the retention rule loses

An **orphaned result** is a molecule result carried only by isolates that were
not kept, so no kept isolate reports that molecule for that patient.

| | 2022 | 2023 | 2024 |
|---|---:|---:|---:|
| isolates with an orphaned result: more molecules, then oldest | 99 (8 with an R) | 116 (11) | 100 (3) |
| isolates with an orphaned result: oldest, never replaced | 159 (29) | 187 (27) | 148 (22) |

The SPARES retention rule loses fewer results than ONERBA's "never replaced".

### Same date and hour

In 67, 63 and 51 groups, reversing the order of isolates sampled at the same
date and hour changes which isolate is kept. None of these changes alters the
number of isolates kept, and in all but one per year the kept isolates were
tested with the same molecules. A fixed tie-break is enough.

### Phenotypes

Pairs kept apart only by a phenotype: 0, 2 and 0 in the three years with an
unknown BLSE status (no third-generation cephalosporin tested, so the phenotype
could not have been found); 3 more in 2024 with a known status. The source
counts a blank phenotype as negative, which ADR-0005 also does. Treating
"not assessable" as a third state would change ADR-0005 and chapter 08, for at
most 2 isolates in three years.

## What it does not show

- The counts come from one site. A site with smaller or less regular panels will
  have more bridging isolates.
- The measure is on the comparison step only. The analyses by sample type and
  across sample types are not measured here, nor how often they retain
  different isolates (`07-dedoublonnage.md`, Open).
