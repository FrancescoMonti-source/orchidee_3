# 07 - Deduplication

Status: **under review** (issue #1). Seven decisions, six witnesses, one
unproven. The witnesses of 07.1-07.5 predate the phenotype comparison; see Open.

## What SPARES says

> Un doublon est une souche isolée chez un malade pour lequel une souche de la
> même espèce et de même antibiotype a déjà été prise en compte durant la
> période de l'enquête pour un même type de prélèvement à visée diagnostique.

> Deux antibiotypes sont considérés comme différents s'il existe, entre les
> souches comparées et pour au moins une molécule, une différence majeure
> (S <-> R ou SFP <-> R) de catégories cliniques. Deux antibiotypes sont
> considérés comme identiques (doublons), s'il existe uniquement des différences
> mineures (S <-> SFP).

> En cas de doublon [...] le prélèvement qui sera conservé [...] est : le
> prélèvement le plus ancien, si l'antibiotype est le même et avec un nombre
> identique d'antibiotiques testés ; le prélèvement avec le plus de molécules
> testées, si l'antibiotype est le même mais avec un nombre différent
> d'antibiotiques testés.

> Une absence de résultat [case vide] [...] ne fait pas partie des caractères
> discriminants pour le dédoublonnage.

The same passage adds that deduplication also compares the BLSE and
carbapenemase phenotypes, and that a blank phenotype cell means the phenotype is
absent (SPARES p. 11, SPF p. 15).

Scope rule (SPARES p. 16, SPF p. 15): for one souche, one sample per patient —
the oldest per sample type for the analysis by sample type, the oldest across
sample types for the global analysis. ONERBA's recommendations (2000,
pp. 25-27), which both documents cite, show which souche is meant: the
operational souche (species, antibiotype, phenotypes). The analysis by sample
type excludes sample-type duplicates; the global analysis excludes duplicates.
Two isolates with a major discrepancy are never collapsed by this rule.

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
| 07.1 | Window length | annual **and** monthly | one only | annual keeps 4438 isolates, monthly 4813 (+8.4 %); proportions move 0.3 pp while every incidence density moves 8.4 % |
| 07.2 | Window shape | calendar (production) with 30-day rolling refractory reference | pure calendar only | 30d rolling refractory keeps 4 718 isolates on E. coli urines (+6.31 % vs annual), eliminating 1.97 % calendar month-end inflation and cross-year resetting; witness in `docs/evidence/dedup_window_30day_refractory_witness.md` |
| 07.3 | Grouping key | patient | patient and stay | not measured; `EVTID` is retained so it stays computable. `unproven` |
| 07.4 | Antibiotype panel | everything the site tests | the SPARES panel per species | identical at Rouen today (4438 both ways); guarded by a tripwire |
| 07.5 | Conflict rule | `SFP <-> R` is major, per the SPARES text | `ZIT` never conflicts, as v2 decided | 4438 isolates against 4428 |
| 07.6 | Comparison when antibiograms are incomplete | compare a new isolate with **every** isolate of a group of duplicates | with the retained isolate only (the witness code until now); with the first isolate of the group; merge every chain of duplicates | Rouen 2022-2024: same retained isolates as the witness code in every group; comparing with the first isolate merges a major discrepancy in 1, 0 and 1 groups; `docs/worked-examples/incomplete-antibiotypes.md` |
| 07.7 | Isolates sampled at the same date and hour | order by `ELTID`, then `souche_id` | any other fixed order | reversing the order changes the retained isolate in 67, 63 and 51 groups, the number retained in none; `incomplete-antibiotypes.md` |

Unproven: **1 of 7**.

### 07.2 note

A rolling refractory window is measured from the initial episode onset for that
patient, not from 1 January. It is an ORCHIDEE experiment, not a European
standard: EARS-Net defines no episode and keeps the first blood or CSF isolate
per patient and pathogen in the calendar year (ECDC reporting protocol 2025,
p. 22 and pp. 24-25); WHO GLASS keeps the first isolate per patient, specimen
type and surveillance period. The nearest published rule is Japan's JANIS,
which removes repeats within 30 days but keeps an isolate whose resistance
phenotype changed (Kajihara et al., PLoS ONE 2020;15(6):e0228234).

The non-transitivity dilemma noted previously (chaining across sequential cultures)
is settled mathematically by the **chronological sweep automaton**: an episode window
$[T_{\text{onset}}, T_{\text{onset}} + 30\text{d}]$ is anchored at the initial culture.
Subsequent isolates within 30 days are compared against active isolates (retaining
emergent resistance under phenotype-aware rules), while isolates arriving $> 30$ days
close the episode and initiate a new one. Full empirical comparison across *E. coli*,
*S. aureus*, *K. pneumoniae*, and *E. cloacae* blood cultures and urines is
cataloged in `docs/evidence/dedup_window_30day_refractory_witness.md`.

### 07.3 note

Grouping by patient and calendar year collapses one infection, repeated
infections and a chronic infection into a single isolate. The undercount
therefore falls on chronic and re-admitted patients, so it varies with case
mix - which weakens exactly the comparison between establishments that the
surveillance exists to provide. SPARES states its choice and never argues for
it. ORCHIDEE follows the choice and records the objection.

### 07.4 tripwire (TW-07.1)

**Statement**: the SPARES panel and the full panel retain the same isolates. (Cataloged as `TW-07.1` in `tripwire-register.md`).
**Today**: 4438 and 4438, *E. coli* / urines / 2024.

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

B is a duplicate of A and of C, but A and C have a major discrepancy. Compared
with the retained isolate only, C meets B, is a duplicate, and only B is
retained: both the S and the R disappear. Merging every chain gives the same
result.

The rule ORCHIDEE applies:

1. Take the isolates of one patient, species, sample type and window from the
   oldest to the most recent (ties: decision 07.7).
2. Each isolate tries the existing groups from the oldest to the most recent,
   and joins the first group where it has no major discrepancy, and the same
   phenotypes, with **every** isolate already in it.
3. If no group accepts it, it opens a new group.
4. Each group then retains one isolate by the retention rule.

In the case above, A opens group 1, B joins it, C has a major discrepancy with
A and opens group 2: B and C are retained. Two isolates with a major discrepancy
are never in the same group, which is what the source's definition of a
duplicate requires.

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
(p. 16) contains the same scope passage as SPF. The scope passage is about one
operational souche (see What SPARES says), so it never collapses isolates with
a major discrepancy. 4 039 was the number of distinct patients in the slice,
not the output of a rule. Issue #5 was opened on this premise.
`docs/findings.md`, 2026-09-27.

### Witnesses to re-measure

The witnesses of 07.1-07.5, and of `perimeter-ordering.md`,
`screening-exclusion.md` and `unit-attribution.md`, were measured on the v2
bundle, without comparing the BLSE and carbapenemase phenotypes that the source
includes in deduplication. They must be re-measured on the raw-backed build with
the phenotype comparison. 07.6 and 07.7 already are.

### The source is incomplete

The SPARES text does not settle 07.6 and 07.7, nor the reading of a blank
phenotype when no screening molecule was tested (`ADR-0005`, Known weakness).
Two implementations faithful to the text can retain different isolates.

### Unproven decisions

One decision (07.3) carries no witness and is marked `unproven` above;
measuring it is a self-contained job against the raw-backed `sir_wide.rds`.
