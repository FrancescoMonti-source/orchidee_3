# 07 - Deduplication

Status: **under review** (issue #1). Seven decisions, six witnesses, two
unproven. Decisions 07.1, 07.4 and 07.5 have been remeasured with phenotype
flags and decision 07.6 on the current provisional v3 bundle. Decision 07.2's
historical rolling-window result is under audit; 07.3 remains unmeasured.

## What SPARES says

> Un doublon est une souche isolée chez un malade pour lequel une souche de la
> même espèce et de même antibiotype a déjà été prise en compte durant la
> période de l'enquête pour un même type de prélèvement à visée diagnostique.

> Deux antibiotypes sont considérés comme différents s'il existe, entre les
> souches comparées et pour au moins une molécule, une différence majeure
> (S <-> R ou SFP <-> R) de catégories cliniques. Deux antibiotypes sont
> considérés comme identiques (doublons), s'il existe uniquement des différences
> mineures (S <-> SFP) entre les souches comparées.

> En cas de doublon [...] le prélèvement qui sera conservé [...] est :
> • Le prélèvement le plus ancien, si l'antibiotype est le même et avec un nombre
> identique d'antibiotiques testés
> • Le prélèvement avec le plus de molécules testées, si l'antibiotype est le même
> mais avec un nombre différent d'antibiotiques testés

> Une absence de résultat [case vide] [...] ne fait pas partie des caractères
> discriminants pour le dédoublonnage.

The same passage adds that deduplication also compares the BLSE and
carbapenemase phenotypes, and that a blank phenotype cell means the phenotype is
absent (SPARES p. 11, SPF p. 15).

Scope rule (SPARES p. 16, SPF p. 15): « pour une même souche », one sample per
patient — the oldest per sample type for the analysis by sample type, the oldest
across sample types for the global analysis.

What « même souche » means there is an inference, not text. SPARES p. 11 glosses
the same phrase as « même bactérie, même prélèvement », in a sentence that opens
with « en cas de doublon ». ONERBA's recommendations (2000, pp. 25-27), which
both documents cite, count an isolate as original when its species and
antibiotype combination is new for the patient, and distinguish the « doublon »
(per patient) from the « doublon prélèvement » (per patient and sample site).
ORCHIDEE therefore reads the scope rule as applying within compatible isolates:
the analysis by sample type excludes sample-type duplicates, the global analysis
excludes duplicates, and two isolates with a major discrepancy are never
collapsed.

## What ORCHIDEE does

ORCHIDEE applies this rule, and records the four inputs it depends on with every
number it publishes. See `docs/adr/0001-deduplication-is-parameterised.md`.

| Input | Value |
|---|---|
| Grouping key | patient (`PATID`) |
| Window | calendar, annual and monthly |
| Antibiotype panel | every antibiotic the site tests |
| Conflict rule | `S <-> R` and `SFP <-> R` major; `S <-> SFP` minor; `ZIT` read as `SFP` |
| Phenotypes | BLSE and carbapenemase compared; a blank flag is absent (`ADR-0005`) |
| Population selection | the perimeter object and the diagnostic scope; see `03-activites.md` |

The window is expressed as a predicate over a pair of isolates,
`same_window(i, j)`, not as a grouping column. A calendar window is
`year(i) == year(j)`. This costs nothing now and is what keeps a rolling
refractory window cheap to add later.

Deduplication runs **after** population selection and **before** indicator
computation. It never runs before the screening exclusion; see
`06-donnees-resistance.md` for why the order is part of the rule.

That ordering is not a precaution specific to screening. Deduplication is **not
monotone**: removing a row from its input can add a row to its result, because
both the antibiotype comparison and the more-molecules-tested tiebreak depend on
which other isolates are present for that patient. Hence the general rule:

> **Any selection on isolates is an input to deduplication, never a filter on
> its output.**

Measured on the perimeter: filtering then deduplicating keeps 2 445 *E. coli*
isolates, deduplicating then filtering keeps 2 350, and 79 patients vanish
entirely. `docs/worked-examples/perimeter-ordering.md`.

## Decisions

All witnesses are measured on real Rouen rows. Method and scripts:
`docs/worked-examples/deduplication.md`.

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 07.1 | Window length | annual **and** monthly | one only | annual keeps 4 441 isolates, monthly 4 814 (+8.40 %); resistance proportions move +0.27 to +1.14 pp and incidence density moves +8.40 % |
| 07.2 | Window shape | calendar (production); rolling refractory comparison remains an experiment | pure calendar only | the historical 4 718 rolling result is not reproduced; current direct implementations keep 4 729 with phenotypes and 07.6, or 4 727 without phenotypes; exact historical rule is unknown |
| 07.3 | Grouping key | patient | patient and stay | not measured; `EVTID` is retained so it stays computable. `unproven` |
| 07.4 | Antibiotype panel | everything the site tests | the species\' SPF Annexe 3 list (SPF p. 20) | the 35-column supported panel and 19-column Annexe 3 *E. coli* list retain 4 441 isolates each, with identical retained IDs; guarded by a tripwire |
| 07.5 | Conflict rule | `SFP <-> R` is major; `ZIT` is read as `SFP` | `ZIT` never conflicts | 4 441 vs 4 431 retained isolates; AMC %R is 39.23 % vs 39.16 % |
| 07.6 | Comparison when antibiograms are incomplete | compare a new isolate with **every** isolate of a duplicate group | with the retained isolate only (the witness code until now); with the first isolate of the group; merge every chain of compatible isolates | Rouen 2022-2024: same retained isolates as the witness code in every group; comparing with the first isolate merges a major discrepancy in 1, 0 and 1 groups; `docs/worked-examples/incomplete-antibiotypes.md` |
| 07.7 | Isolates sampled at the same date and hour | order by `ELTID`, then `souche_id` | any other fixed order | reversing the order changes the retained isolate in 67, 63 and 51 groups, the number retained in none; `incomplete-antibiotypes.md` |

Unproven: **2 of 7**.

### 07.2 note

The 30-day rolling comparison is an ORCHIDEE experiment. It differs from the
EARS-Net calendar-year rule for the first blood or CSF isolate per patient and
pathogen (ECDC reporting protocol 2025, pp. 22 and 24-25).

The historical 4 718 count is not reproducible from the tracked witness
scripts. It used a v2 bundle and a comparison rule that decision 07.6
replaces. On the current provisional v3 bundle, the annual and monthly
calendar baselines are 4 441 and 4 814. A direct implementation of the
written rolling-window description yields 4 729 with phenotype flags and
07.6, or 4 727 without phenotype flags. Neither reproduces 4 718. The
historical boundary and group-reset rules are not recorded, so the rolling
comparison remains under audit and does not establish a month-end effect.

### 07.3 note

Grouping by patient and calendar year collapses one infection, repeated
infections and a chronic infection into a single isolate. The undercount
therefore falls on chronic and re-admitted patients, so it varies with case
mix - which weakens exactly the comparison between establishments that the
surveillance exists to provide. SPARES states its choice (SPARES pp. 10, 16) and never argues for
it. ORCHIDEE follows the choice and records the objection.

### 07.4 tripwire (TW-07.1)

**Statement**: the species' Annexe 3 list and the full supported panel retain the same isolates. (Cataloged as `TW-07.1` in `tripwire-register.md`).
**Today**: 4 441 under each panel, with identical retained isolate IDs, *E. coli* / urines / 2024. The full panel has 35 supported columns; 21 have results in this slice.

The check fails on the day a site starts testing a molecule that separates two
antibiotypes which were identical before. That is the CLAVENTIN situation, which
in v2 changed 51 isolates and the denominators of 20 antibiotic columns with
nothing able to object
(`docs/evidence/2026-08-02_amc_remapping_cascade.txt`).

### 07.6 note

The source says a blank result never counts as a difference, and that among
duplicates the isolate with more molecules tested is retained. It does not say
what a new isolate is compared with once the retained isolate has been
replaced. The gap matters when a **bridging isolate** has no result for the
molecule that separates two others:

| Isolate | Ofloxacine | Molecules tested |
|---|---|---:|
| A, first | S | 2 |
| B, second | blank | 3 |
| C, third | R | 2 |

B is compatible with A and with C, but A and C have a major discrepancy.
Compared with the retained isolate only, C meets B, is compatible, and only B is
retained: both the S and the R disappear. Merging every chain gives the same
result.

The rule ORCHIDEE applies:

1. Take the isolates of one patient, species and window (and one sample type,
   for an analysis by sample type) from the oldest to the most recent (ties:
   decision 07.7).
2. Each isolate tries the existing groups from the oldest to the most recent,
   and joins the first group where it is compatible with **every** isolate
   already in it.
3. If no group accepts it, it opens a new group.
4. Each group then retains one isolate by the retention rule.

In the case above, A opens group 1, B joins it, C has a major discrepancy with
A and opens group 2: B and C are retained. Two isolates with a major discrepancy
are never in the same duplicate group, which is what the source's definition of
a doublon requires.

A real case, Rouen 2024, *Serratia marcescens*, urines, mecillinam: isolate 1
(June, not tested, 17 molecules) opens group 1; isolates 2 and 3 (7 November,
R, 18 molecules) join it; isolate 4 (19 November, S, 18 molecules) has a major
discrepancy with 2 and opens group 2. Retained: 2 and 4. Comparing with the
first isolate of the group only would have put 4 in group 1 and lost its S.

The groups could also be formed all at once: the fewest groups with no major
discrepancy inside any of them. That does not remove the choice. In the case
above, {A, B} + {C} and {A} + {B, C} are both minimal and retain different
isolates, so a tie-break is still needed, and date order is the natural one.
At Rouen, in the 13 ambiguous groups of 2022-2024, the minimal grouping has a
single answer and it is the one this rule gives.

## Open

### Withdrawn: "the two source documents do not specify the same rule"

This section used to say that SPF's Annexe 1 replaces the antibiotype rule
with "the oldest sample per patient", and measured 4 438 against 4 039 isolates
as the gap between two rules. That was wrong. SPF (pp. 14-15) contains the same
antibiotype, retention and phenotype rules as SPARES (pp. 10-11), and SPARES
(p. 16) contains the same scope passage as SPF. Read with ONERBA (2000, pp. 26-27), the scope
passage applies within compatible isolates (see What SPARES says), so it never
collapses isolates with a major discrepancy. 4 039 was the number of distinct patients in the slice,
not the output of a rule. Issue #5 was opened on this premise.
`docs/findings.md`, 2026-09-27.

### Witness status

Decisions 07.1, 07.4 and 07.5 were remeasured on 2026-09-27 against
`outputs/rouen_stage2_2024/bundle_v3`, comparing BLSE and carbapenemase
flags and using decision 07.6's all-members grouping. The 07.1, 07.4 and
07.5 counts in this chapter and `docs/worked-examples/deduplication.md`
reflect that run. The source bundle was built from raw files by the v2
pipeline; the site mappings remain unreviewed, so these results are
provisional.

The 07.2 rolling-window witness is under audit: no tracked script or exact
historical boundary/group-reset rule reproduces its 4 718 count. Decision
07.3 remains unmeasured. The witnesses in `perimeter-ordering.md`,
`screening-exclusion.md` and `unit-attribution.md` also remain on the older
baseline and have not been remeasured with phenotype comparison and 07.6.

### The source is incomplete

The SPARES text does not settle 07.6 and 07.7, nor the reading of a blank
phenotype when no screening molecule was tested (`ADR-0005`, Known weakness).
Two implementations faithful to the text can retain different isolates.

It also gives two retention rules. p. 11 keeps the isolate with more molecules
tested, then the oldest; p. 16 keeps « le plus ancien » in both analyses. SPF
repeats both on p. 15. Within one duplicate group the two conflict. ORCHIDEE applies the
p. 11 rule, the only one that says what happens when the panels differ.

### The two analyses can retain different isolates

The analysis by sample type and the global analysis form their duplicate groups
separately, so an isolate can be discarded in one and retained in the other.
Same patient and species, in date order:

| Isolate | Sample type | Ofloxacine | Molecules tested |
|---|---|---|---:|
| U1 | urines | blank | 12 |
| X | blood culture | R | 10 |
| U2 | urines | S | 15 |

U1 is compatible with X and with U2; X and U2 are not compatible. By sample
type, U1 and U2 form one group and U2 is retained: U1 is a sample-type
duplicate. Across sample types, U1 and X form one group and U2 opens another;
U1 is retained. U1 is discarded from the urine analysis and counted in the
global one. Without a bridging isolate this cannot happen: compatible isolates
then fall into fixed classes, and an isolate outranked within its sample type is
outranked across sample types too. Not measured at Rouen.

### Unproven decisions

One decision (07.3) carries no witness and is marked `unproven` above;
measuring it is a self-contained job.
