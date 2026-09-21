# 04 - Activity data (the denominator)

Status: **settled**. Eleven decisions, nine witnesses, two unproven. Shared with
the CATB project.

## What SPARES says

> Le nombre de journées d'hospitalisation correspond au nombre de journées
> d'hospitalisation complète, y compris les hospitalisations de semaine,
> facturées lors de l'année 2024, telles que déclarées dans le cadre de la
> statistique annuelle des établissements de santé (SAE). Elles sont
> renseignées de manière indépendante pour chaque unité fonctionnelle faisant
> l'objet du recueil.

> Ces données sont à intégrer dans l'outil ConsoRes de façon annuelle ou
> trimestrielle, au choix de l'établissement participant, et sont recueillies
> par unité fonctionnelle.

## What SPF asks

SPF Annexe 1 §8 restates the SPARES definition, changing only the period:
*"facturées lors de la période concernée, telles que déclarées dans le cadre de
la SAE"*. The body of the requirements asks for monthly indicators:

> La fréquence d'estimation des indicateurs devra être mensuelle.

> nous souhaiterions recevoir, pour tous les indicateurs agrégés demandés, le
> numérateur et dénominateur utilisés (le nombre de souches avec une résistance,
> le nombre de souches testés, le nombre total de JH).

**These two requirements are not jointly satisfiable as written.** The SAE is an
annual declaration; there is no monthly SAE. A monthly indicator divided by an
SAE-derived denominator requires a decision that neither document prescribes.
This is recorded here rather than resolved silently: see decision 04.1.

## What ORCHIDEE does

The denominator is **derived from the site's hospitalisation intervals**, never
from an administrative declaration. The canonical measure is **occupancy hours,
expressed in days**; `midnight_presence` is computed in parallel from the same
intervals so that a SPARES-comparable series still exists.

One **perimeter object** is resolved once and handed to both the numerator and
the denominator. The exposure table is keyed
`(unit, period, profile, exposure_value, exposure_unit, perimeter_flags)` and
carries nothing else.

Two rules govern everything downstream:

> **Aggregation is legal only within a single profile.** Days and
> hour-equivalents can be added arithmetically, which is exactly why the result
> is dangerous: "per 1000 patient-days" stops naming anything once two
> definitions of a patient-day are in the pool.

> **Denominators add. Numerators do not.** Monthly patient-days sum exactly to
> the annual patient-days, because days are additive. Monthly isolate counts do
> not sum to the annual isolate count, because annual deduplication removes the
> cross-month recurrences that monthly deduplication keeps.

## Decisions

Witnesses measured on Rouen's real PMSI (`data/pmsi`) and on the v2 exposure
table, calendar year 2024, SPARES-eligible perimeter
(`CODE_TA ∈ {03, 20}` ∩ the ten SPARES DE domains).

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 04.1 | Source | derived from hospitalisation intervals | the SAE declaration, as specified | SAE/ConsoRes 2024 = **589 397 JH**; perimeter-correct = **355 246**. Ratio **×1.66** |
| 04.2 | Exposure measure | occupancy hours, expressed in days | midnight presence | 356 492 against 355 246, **+0.35 %**. TA 04 ×3.705, TA 19 ×55.1, TA 23 ×1.316 |
| 04.3 | Comparability profile | `midnight_presence` derived in parallel | a single profile | same intervals, no second pipeline; per-sector ratio 0.988 to 1.020 |
| 04.4 | Aggregation | only within one profile | free aggregation | the units are incommensurable; no number can be produced to defend the alternative |
| 04.5 | Overlapping intervals | unioned per patient / stay / unit | convex hull of the episode | 2024 hull 365 887 against union 355 246: **−10 641 (3.0 %)**, 1 953 episodes |
| 04.6 | Period grain | month, plus an independent annual run | annual only, or annual ÷ 12 | annual dedup keeps 4 438, monthly keeps 4 813 (**+8.4 %**) on *E. coli*/urines/2024 |
| 04.7 | Perimeter | one object, consumed by numerator and denominator | each stage selects independently | ConsoRes' own failure: SPARES numerator over whole-establishment denominator |
| 04.8 | Admissions | establishment level only | stratified by sector | not measured. `unproven` |
| 04.9 | Timestamp resolution | declared by the site, checked against the data | inferred silently | Rouen: **4.11 %** of `DATENT` and 4.08 % of `DATSORT` at exactly 00:00; peaks 08:00 and 15:00 |
| 04.10 | Plausibility | non-blocking, requires acknowledgement | blocking, or nothing | eligible denominator 327 301 / 347 303 / 355 246 while the raw table moved 1 016 036 → 564 968 |
| 04.11 | Shared component | ORCHIDEE-RATB publishes a versioned file; CATB consumes it | a jointly owned repository | not measured. `unproven` |

Unproven: **2 of 11**.

### 04.1 note — why the specified source is refused

The SAE figure delivered to ConsoRes for Rouen carries no activity filter at
all. It exceeds even ORCHIDEE's *unfiltered* exposure table (564 968), so it
includes activity absent from the movement data entirely.

The consequence is in the published report:

| Rouen 2024, ConsoRes | published | with the perimeter-correct denominator |
|---|---|---|
| SARM, all samples | 0,16 (95/589397) | **0,27** |
| SARM, blood cultures | 0,024 (14/589397) | **0,039** |

Every incidence density in Rouen's ConsoRes report is understated by **40 %**,
and since consumption divides by the same JH, so is the 526,9 DDJ/1000 JH
establishment figure. The numerator is not at fault.

`589 397` is retained in `docs/evidence/` as a receipt, not as an oracle. When
ORCHIDEE publishes SARM at 0,27 against ConsoRes' 0,16, the field's first
reading will be that ORCHIDEE has a bug. See `09-diffusion.md`.

### 04.2 note — why hours rather than midnights

The two measures agree to within 0.35 % across the whole eligible perimeter, so
the change costs almost nothing in comparability. Three reasons to take it
anyway.

**Hours are lossless.** Midnights are derivable from hours; hours are not
derivable from midnights. One choice keeps both readings available forever, the
other destroys one permanently. This is the reversibility rule in `CONTEXT.md`:
a decision is cheap to reverse when it destroys no information.

**One unit removes the profile-per-perimeter problem.** If each perimeter binds
its own definition of a hospital day, no establishment-wide indicator exists,
because its strata are incommensurable. A single canonical measure makes
aggregation legal everywhere.

**The divergence is concentrated where the perimeter is heading.** Full
hospitalisation is 1.003. Ambulatory is not: day hospital 3.705, ambulatory
treatment 55.1. SPF has said the perimeter will be enlarged.

The emergency ward, which motivated the question, comes out at **0.998** — but
for a reason worth recording. **49.4 %** of TA 10 unit-episodes carry zero
nights, median stay 10.1 hours; the mean of 68.4 hours shows a long tail that
pays back in aggregate what the short stays lose. Midnight presence is wrong on
half the individual episodes while being almost exactly right on the total. That
is acceptable for a total and not acceptable for anything stratified finer, or
expressed per passage.

### 04.9 note — the degradation is exact, and that is the hazard

When both timestamps are 00:00, occupancy hours equal
`(date_out − date_in) × 24`, so hours ÷ 24 is *identically* the midnight-presence
count. A site with date-only movements gets precisely the number the SPARES
definition would have given it. Nothing breaks.

Which is why the resolution must be declared rather than inferred:

- **Mixed resolution inside one site is worse than none.** Timed rows and
  00:00-defaulted rows in the same hospital produce a denominator where some
  units are systematically undercounted relative to others.
- **The fallback expires with the perimeter.** Safe at 0.3 % for full
  hospitalisation; a factor of 3.7 out on day hospital.
- **`00:00` is ambiguous by construction** — unknown time, or a real midnight
  admission. No row distinguishes them, so detection is distributional.

A site declares `datetime` or `date`. ORCHIDEE compares the declaration against
the observed share at 00:00 and refuses a site that is neither — Rouen at 4.11 %
is a clean `datetime`; a site at 97 % is a clean `date`; a site at 40 % is
refused rather than averaged. Guarded by tripwire `TW-04.2` (see `tripwire-register.md`).

### 04.10 tripwire (TW-04.1)

**Statement**: no unit's eligible patient-days move more than ±30 % year over
year without acknowledgement. (Cataloged as `TW-04.1` in `tripwire-register.md`).
**Today**: 327 301 / 347 303 / 355 246 for 2022-2024.

Non-blocking by design. A hospital that genuinely closes a ward must still be
able to publish, and a blocking check that fires on legitimate change is
disabled within a year. The acknowledgement is the point: it converts *nobody
noticed* into *someone signed*.

### 04.6 note — the two series, and the gap between them

Deduplication is not distributive over time: it removes repeats, and how many
repeats it removes depends on how long you look. One patient with the same
antibiotype in March and July contributes 2 under twelve monthly runs and 1
under one annual run. The inequality is one-directional and guaranteed:
**Σ monthly ≥ annual**.

Neither series is derivable from the other. Summing twelve monthly numerators
over the annual denominator produces a number inflated by exactly the recurrence
rate, which varies with case mix — which is the comparison between
establishments the surveillance exists to make.

So the monthly figure is **final**, not provisional: nothing outside its own
month can change it. The annual figure is a separate measurement under a
different window, not a summary of the twelve.

The gap is published as an indicator in its own right. `Σ(monthly numerators) −
annual numerator` is the count of patients with a recurrent episode of the same
organism and antibiotype in a different month — **375** on the *E. coli* /
urines / 2024 slice. Both runs already exist, so it costs nothing, and it
answers the one question every reader of the two series will ask.

## Why this section is shared

DDJ / 1000 JH and incidence density / 1000 JH divide by the same denominator,
derived from the same intervals under the same perimeter. If the two projects
each compute it, they will differ, and the difference is undetectable from
inside either one — which is the situation that makes ConsoRes unauditable.

A **file contract**, not a shared library, because the CATB project is in
Python. ORCHIDEE-RATB produces the versioned file and the CATB project consumes
it, so that one number exists and the consumer can name the version it divided
by. A jointly owned component is the stated destination and is premature: a
shared repository needs an owner and a release process before it needs code.

## Open

- **The TA 07 anomaly.** `CONSULTATIONS_EXTERNES` units carry 123 319 nights
  across 17 738 episodes in 2024 — an average of 7 nights per outpatient
  consultation. Something is attached to those UFs that is not a consultation.
  Outside the perimeter today, inside it the moment the perimeter widens.
- **The exposure table is annual today.** The monthly grain of 04.6 is a
  decision, not an implementation: the current `site_inputs` table is keyed
  `calendar_year` and physically cannot produce a month. The intervals can.
- Admissions attribution (04.8) is unmeasured, as is the shared-component
  ownership (04.11).
- EHPAD attached to the establishment. Still SPF's open question, not ORCHIDEE's
  to close. See `02-etablissements.md`.
