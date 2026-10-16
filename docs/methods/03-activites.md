# 03 - Activities included and excluded

Status: **settled**. Six decisions, four witnesses, two unproven.

## What SPARES says

> Sont incluses dans la surveillance, les hospitalisations complètes (y compris
> hospitalisations de semaine) et hébergements dans les secteurs suivants :
> Médecine y compris soins intensifs et surveillance continue, « lits porte » et
> « unités de très court séjour » ou « hospitalisation de courte durée », à
> l'exclusion de la pédiatrie et de la réanimation, [...] Chirurgie [...]
> Réanimation médicale et chirurgicale [...] Pédiatrie [...]
> Gynécologie/obstétrique [...] Soins de suite et de réadaptation / soins
> médicaux et de réadaptation (adultes), Soins de longue durée (adultes),
> Psychiatrie (adultes) [...]

> Les activités exclues de la surveillance sont les activités ne correspondant
> pas à une hospitalisation complète ou de semaine en établissement de santé :
> La rétrocession externe, Les venues (hospitalisation de jour ou de nuit,
> anesthésie), Les séances (traitements et cures ambulatoires : chimiothérapie,
> radiothérapie ...), Les journées de prise en charge (hospitalisation à
> domicile…), Les consultations, Les passages (urgences), Les unités de
> consultations et soins ambulatoires pour les personnes détenues (UCSA).

> La dispensation d'antibiotiques et la réalisation de prélèvements dans les
> unités de soins intensifs et unités de surveillance continue spécialisées sont
> affectées à la discipline correspondante, en médecine, chirurgie ou pédiatrie.

In ConsoRes the perimeter is expressed through the `TA` and `DE` code tables:
`CODE_TA ∈ {03, 20}` — hospitalisation complète and hospitalisation de semaine —
intersected with the eligible discipline domains.

## What ORCHIDEE does

**The handoff is unbounded by the hospital perimeter.** The site supplies
prepared diagnostic isolates with an antibiogram, without additional local
hospital perimeter exclusions. Local cleaning, mappings, diagnostic selection
and retention of isolates with an antibiogram precede the common audit
(chapter 00; ADR-0003). Hospitalisation activity retains its own population,
including relevant activity from patients without cultures or antibiograms.

Keeping the hospital perimeter downstream permits a perimeter change to be a
new run over the supplied data, within the site's authorisation. This does not
require the shared pipeline to ingest screening records or recover other local
preparation exclusions.

**The shared perimeter follows the common audit and precedes deduplication.**
Analysis-specific specimen selection also precedes deduplication; local
diagnostic selection has already occurred. The perimeter remains an input
to deduplication, alongside the grouping key, the window, the antibiotype panel
and the conflict rule. See
`07-dedoublonnage.md`, and the general rule it now states:

> Any selection on isolates is an input to deduplication, never a filter on its
> output.

**The hospital perimeter is one named, versioned set of eligible units.**
Resolve it once for the declared establishment and surveillance period, then
use the same set for the microbiology numerator and hospitalisation exposure
denominator. Record its version with every published number; see 04.7 and
`docs/evidence/2024_consores_rouen_denominator.md` for the consequence of
resolving unit eligibility independently for numerator and denominator.

Record the period, completed local diagnostic and antibiogram selection,
analysis-specific specimen scope and deduplication inputs separately in the
analysis context. Numerator and exposure denominator use the same establishment
and period. Specimen restrictions apply only to microbiology: a blood-culture
analysis still uses all relevant hospitalisation exposure within that perimeter
and period, including activity from patients without a culture or antibiogram.

## Decisions

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 03.1 | Extraction scope | unbounded; the perimeter is applied downstream | extract to the perimeter | 56 % of Rouen's 2024 diagnostic *E. coli* sits outside the SPARES perimeter (3 651 of 6 519). A perimeter change is a re-run, not a re-extraction |
| 03.2 | Where the perimeter applies | population selection, **before** deduplication | after deduplication, or at the indicator stage | 2 445 isolates against 2 350, **79 patients lost entirely**. `docs/worked-examples/perimeter-ordering.md` |
| 03.3 | Perimeter shape | one named, versioned set of eligible units shared by numerator and exposure denominator; other selections recorded separately in the analysis context | mix microbiology restrictions into the hospital perimeter or resolve unit eligibility independently for numerator and denominator | glossary definition and 04.7; methodological clarification, not a new measurement |
| 03.4 | Units with unknown `TA`/`DE` | not eligible; counted and published | eligible until proven otherwise; or blocking | 6 UFs of 1 159 unclassified — 2 with `TA 03/20` and no `DE`, 4 absent from the structure file |
| 03.5 | Perimeter definition | **positive** — eligible codes are listed | negative — excluded codes are listed | forced by 03.4: a code nobody has classified must not become eligible by omission |
| 03.6 | Unmapped vocabulary | lazy — mapped when a value reaches an indicator, residue counted per run | eager, or within the perimeter only | not measured. `unproven` |

Unproven: **2 of 6** (03.3 and 03.6 carry arguments, not numbers).

### 03.1 note — what unbounded extraction is and is not

Unbounded means *within the site's data authorisation*, which is a real boundary
and not an absence of one, and concerns hospital perimeter breadth, not a
requirement to supply non-diagnostic records or isolates without an antibiogram.
Rouen's authorisation covers the full microbiology
and movement scope. A site whose authorisation is narrower has an extraction
perimeter, and for that site a perimeter widening **is** a re-extraction. The
property claimed here holds inside the authorisation and the specification says
so rather than promising it everywhere.

### 03.2 note — why order is part of the rule

Deduplication is not monotone: removing a row from its input can add a row to
its result, because the retention tiebreak and the antibiotype comparison both
depend on which other isolates are present for that patient.

Measured on *E. coli*, 2024, diagnostic, all sample types:

| | isolates |
|---|---|
| in the extract, all units | 6 519 |
| in eligible units | 2 868 |
| perimeter → deduplicate | **2 445** |
| deduplicate → perimeter | **2 350** |
| difference | −95, −3.9 % |
| patients lost entirely | **79** |

Proportions move by at most 0.3 pp while every incidence density moves 3.9 % —
the same signature as the window decision. The 79 patients each had a diagnostic
isolate in an eligible unit and an earlier one outside it; deduplicating first
elects the outside isolate as the patient's representative, and the later
perimeter filter then deletes the patient along with the isolate that belonged.

### 03.4 note — the referential is not the problem

The question *"are these unmapped because they could not be, or because the job
is unfinished?"* has a measured answer: neither. 976 UFs are `ta_not_03_20`,
fully classified and deliberately excluded. Only 6 are open.

The real loss sits elsewhere. **3 650 isolates carry no `SEJUF` at all** — 7.5 %
of the bundle, 1 173 of them in 2024. That is not an unmapped unit; it is a
sample that could not be attributed to a hospitalisation unit, and no amount of
`TA`/`DE` mapping reaches it. See `05-structure.md`.

## Open

- **The intensive-care reassignment rule.** SPARES requires specialised
  intensive-care and continuous-monitoring units to be assigned to medicine,
  surgery or paediatrics (SPARES p. 10). This is a mapping decision and the document does not
  say who applies it. If the site applies it, two sites will differ; if ORCHIDEE
  applies it, it needs a rule over local unit labels it cannot read.
- **The 3 650 unit-less isolates.** Whether they are excluded, counted as an
  unknown stratum, or attributed by a documented fallback is undecided. It is
  the largest single population question left in the document.
- **The `TA 07` anomaly.** Consultation-externe units carrying 123 319 nights
  across 17 738 episodes in 2024. Outside the perimeter today. See
  `04-donnees-activite.md`.
- **Locally-followed sectors.** SPARES allows dialysis and ambulatory surgery to
  be collected with their own denominators (séances, séjours). Under 04.4 these
  cannot be aggregated with patient-day indicators. Whether ORCHIDEE produces
  them at all is undecided.
- **EHPAD attached to the establishment.** Still SPF's open question. See
  `02-etablissements.md`.
