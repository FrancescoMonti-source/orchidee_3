# 07 - Deduplication

Status: **settled**. Five decisions, four witnesses, one unproven. One
unresolved conflict between the two source documents, recorded under Open.

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

Unproven: **1 of 5**.

### 07.2 note

A rolling refractory window is measured from the initial episode onset for that
patient, not from 1 January. It resolves the definition of an *infectious episode*
used by European surveillance (EARS-Net, HAI-Net, WHO GLASS).

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

## Open

### The two source documents do not specify the same rule

SPF's Annexe 1 restates deduplication, and drops the antibiotype entirely:

> Pour une même souche, l'analyse ne prend en compte qu'un prélèvement par
> patient selon le type de recherche souhaitée :
> • analyse des résistances par type de prélèvement : les doublons
> « prélèvement » sont exclus, un seul prélèvement (le plus ancien) par type de
> prélèvement et par patient, est conservé ;
> • analyse globale des résistances tous types de prélèvements confondus : seul
> un prélèvement par patient est conservé, le plus ancien quel que soit le type
> de prélèvement.

No antibiotype criterion, no major-discrepancy test, no more-molecules-tested
tiebreak. Under the SPARES methodology quoted above, two isolates from one
patient differing by a major discrepancy are **both retained** — they are
different antibiotypes, so neither is a duplicate. Under SPF's restatement only
the oldest survives.

This is not a wording difference. On the *E. coli* / urines / 2024 slice:

| rule | isolates retained |
|---|---|
| SPARES methodology (antibiotype-aware) | **4 438** |
| SPF Annexe 1 (oldest per patient) | **4 039** — one per patient |
| difference | **−399, −9.0 %** |

Measured from `docs/worked-examples/deduplication.md`: the slice holds 4 963
isolates across 4 039 patients, so the SPF rule's output is the patient count by
construction.

ORCHIDEE follows the SPARES methodology, which is the document SPF's own
requirements name as the method to reproduce. The conflict is recorded rather
than resolved: it is a question for SPF, and it is a worked example of the
problem this project exists to address — two official documents describing the
same operation, differing by 9 % of the published numerator, with nothing
anywhere obliged to notice.

### Unproven decisions

Two decisions carry no witness and are marked `unproven` above; measuring either
is a self-contained job against `sir_wide.rds`.
