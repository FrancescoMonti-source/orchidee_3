# Worked example: what the denominator is worth

Witnesses for `docs/methods/04-donnees-activite.md`.

**Source**: Rouen's real PMSI movement table (v2 repo, `data/pmsi`, `$main`,
442 183 rows; 312 589 after the source policy `prefer_pmsi_src_c_over_dw`).
Intervals are clipped to the calendar year, then unioned per
`(PATID, EVTID, SEJUM, SEJUF)`. Reproduction: `denominator_profiles.R`.

**Perimeter**: `CODE_TA ∈ {03, 20}` intersected with the ten SPARES DE domains,
which is what v2 publishes. 124 169 movement rows fall in eligible UFs.

## 1. The specified source against the derived one

| 2024 denominator | patient-days |
|---|---|
| ORCHIDEE, derived from intervals, SPARES perimeter | **355 246** |
| SAE, as declared to ConsoRes | **589 397** |
| ratio | **×1.66** |

The SAE figure exceeds ORCHIDEE's *unfiltered* exposure table (564 968), so it
is not "everything we have" either — it covers activity absent from the movement
data entirely. It carries no activity filter.

In ConsoRes' own published numbers for Rouen 2024:

| indicator | published | perimeter-correct |
|---|---|---|
| SARM, all samples | 0,16 (95/589397) | **0,27** |
| SARM, blood cultures | 0,024 (14/589397) | **0,039** |

Every incidence density understated by 40 %. The numerator is the SPARES
perimeter and is not at fault; only the denominator is.

## 2. Occupancy hours against midnight presence

Same perimeter, same year, same intervals.

| exposure measure | patient-days |
|---|---|
| midnight presence | 355 246 |
| occupancy hours ÷ 24 | 356 492 |
| ratio | **1.0035** |

By sector:

| sector | nights | hours ÷ 24 | ratio |
|---|---|---|---|
| MÉDECINE | 140 728 | 140 685 | 1.000 |
| CHIRURGIE | 79 483 | 80 145 | 1.008 |
| SOINS MÉDICAUX ET DE RÉADAPTATION | 60 526 | 60 560 | 1.001 |
| PÉDIATRIE | 23 411 | 23 616 | 1.009 |
| RÉANIMATION | 20 537 | 20 658 | 1.006 |
| GYNÉCOLOGIE-OBSTÉTRIQUE | 14 449 | 14 735 | 1.020 |
| SOINS DE LONGUE DURÉE | 12 689 | 12 696 | 1.001 |
| URGENCES | 2 331 | 2 302 | 0.988 |
| PSYCHIATRIE | 1 092 | 1 096 | 1.004 |

Within the eligible perimeter the choice is worth a third of one percent. It is
not a choice about today's numbers.

## 3. Where the two measures actually diverge

All `CODE_TA`, 2024, same union rule:

| TA | activity | episodes | nights | hours ÷ 24 | ratio |
|---|---|---|---|---|---|
| 03 | hospitalisation complète | 42 082 | 350 443 | 351 554 | 1.003 |
| 07 | consultations externes | 17 738 | 123 319 | 127 034 | 1.030 |
| 10 | accueil des urgences | 25 038 | 71 516 | 71 374 | **0.998** |
| 09 | autres UF médico-techniques | 1 668 | 11 865 | 12 413 | 1.046 |
| 20 | hospitalisation de semaine | 1 000 | 4 803 | 4 938 | 1.028 |
| 32 | radio-diag/thérap | 156 | 989 | 1 025 | 1.036 |
| 23 | chirurgie ambulatoire | 697 | 608 | 800 | **1.316** |
| 04 | hospitalisation de jour | 6 031 | 654 | 2 423 | **3.705** |
| 19 | traitement et cure ambulatoire | 2 854 | 9 | 496 | **55.1** |

The divergence is an ambulatory phenomenon. Midnight presence undercounts day
hospital by a factor of 3.7 and ambulatory treatment by 55, because those
patients are, by definition, not present at midnight.

### The emergency ward is not the case it looks like

TA 10 comes out at 0.998 — the two measures agree on the total. But:

- **49.4 %** of TA 10 unit-episodes carry **zero** nights (12 374 of 25 038)
- median stay **10.1 hours**, mean **68.4 hours**

Half the episodes contribute nothing under midnight presence, and a long tail
pays the difference back in aggregate. The measure is wrong on half the
individual episodes while being almost exactly right on the total. That is
acceptable for a total and not acceptable for anything stratified finer, or
expressed per passage.

## 4. Are the timestamps real?

The hours measure is only better than midnights if the times are data rather
than padding.

| | share at exactly 00:00 |
|---|---|
| `DATENT` | **4.11 %** |
| `DATSORT` | **4.08 %** |

Modal admission hour is 08:00 (56 475 rows), modal discharge hour 15:00
(33 934). These are real clinical clocks.

Note the degeneracy that makes the choice safe: if both timestamps were 00:00,
occupancy hours would equal `(date_out − date_in) × 24`, so hours ÷ 24 would be
*identically* the midnight-presence count. A date-only site gets exactly the
number the SPARES definition would have given it — which is why the resolution
must be declared rather than inferred. See decision 04.9.

## 5. Union against hull

From v2's own audit (`outputs/denominator_interval_audit/`), eligible perimeter:

| year | convex hull | interval union | excess | episodes affected |
|---|---|---|---|---|
| 2022 | 337 272 | 327 301 | 9 971 | 1 732 |
| 2023 | 358 297 | 347 303 | 10 994 | 1 780 |
| 2024 | 365 887 | 355 246 | 10 641 | 1 953 |

Taking the hull of an episode — first entry to last exit — overstates by **3.0 %**
every year, because a patient who leaves a unit and returns to it after a stay
elsewhere has the gap counted as occupancy.

## 6. The perimeter filter is doing most of the work

| year | raw exposure table | eligible |
|---|---|---|
| 2022 | 1 016 036 | **327 301** |
| 2023 | 706 872 | **347 303** |
| 2024 | 564 968 | **355 246** |

The raw table falls by 44 % in two years while the published denominator rises
by 8.5 %. The movement is entirely in `TA 07` and `TA 10` rows, which never
reach the denominator. Two readings of the same table, one of which looks like a
catastrophe and one of which looks like a hospital.

This is the witness for the 04.10 tripwire: the check belongs on the **eligible**
denominator, and a check placed one step upstream would have fired every year
for no reason.
