# 07 - Deduplication

Status: **settled**. Four decisions, four witnesses, none unproven.

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

Scope rule, same annexe: for analysis by sample type, one sample per type per
patient; for the global analysis, one sample per patient regardless of type.

## What ORCHIDEE does

ORCHIDEE applies this rule, and records the four inputs it depends on with every
number it publishes. See `docs/adr/0001-deduplication-is-parameterised.md`.

| Input | Value |
|---|---|
| Grouping key | patient (`PATID`) |
| Window | calendar, annual and monthly |
| Antibiotype panel | every antibiotic the site tests |
| Conflict rule | `S <-> R` and `SFP <-> R` major; `S <-> SFP` minor; `ZIT` read as `SFP` |

The window is expressed as a predicate over a pair of isolates,
`same_window(i, j)`, not as a grouping column. A calendar window is
`year(i) == year(j)`. This costs nothing now and is what keeps a rolling
refractory window cheap to add later.

Deduplication runs **after** population selection and **before** indicator
computation. It never runs before the screening exclusion; see
`06-donnees-resistance.md` for why the order is part of the rule.

## Decisions

All witnesses are measured on real Rouen rows. Method and scripts:
`docs/worked-examples/deduplication.md`.

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 07.1 | Window length | annual **and** monthly | one only | annual keeps 4438 isolates, monthly 4813 (+8.4 %); proportions move 0.3 pp while every incidence density moves 8.4 % |
| 07.2 | Window shape | calendar | rolling refractory | not measured - recorded as an experiment, not a parameter. `unproven` |
| 07.3 | Grouping key | patient | patient and stay | not measured; `EVTID` is retained so it stays computable. `unproven` |
| 07.4 | Antibiotype panel | everything the site tests | the SPARES panel per species | identical at Rouen today (4438 both ways); guarded by a tripwire |
| 07.5 | Conflict rule | `SFP <-> R` is major, per the SPARES text | `ZIT` never conflicts, as v2 decided | 4438 isolates against 4428 |

Unproven: **2 of 5**.

### 07.2 note

A rolling refractory window is measured from the previous retained isolate for
that patient, not from 1 January. It is closer to what *incidence* means,
because it counts episodes rather than calendar coincidences. It is not a
parameter because no consumer asks for it, and because "same window" would stop
being transitive - isolates at day 1, day 20 and day 40 with N=30 pair up
inconsistently - which needs a sweep rule this document does not have.

### 07.3 note

Grouping by patient and calendar year collapses one infection, repeated
infections and a chronic infection into a single isolate. The undercount
therefore falls on chronic and re-admitted patients, so it varies with case
mix - which weakens exactly the comparison between establishments that the
surveillance exists to provide. SPARES states its choice and never argues for
it. ORCHIDEE follows the choice and records the objection.

### 07.4 tripwire

**Statement**: the SPARES panel and the full panel retain the same isolates.
**Today**: 4438 and 4438, *E. coli* / urines / 2024.

The check fails on the day a site starts testing a molecule that separates two
antibiotypes which were identical before. That is the CLAVENTIN situation, which
in v2 changed 51 isolates and the denominators of 20 antibiotic columns with
nothing able to object
(`docs/evidence/2026-08-02_amc_remapping_cascade.txt`).

## Open

Nothing blocking. Two decisions carry no witness and are marked `unproven`
above; measuring either is a self-contained job against `sir_wide.rds`.
