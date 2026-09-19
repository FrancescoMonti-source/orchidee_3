# ConsoRes 2024, CHU Rouen: the published denominator

Transcribed from `docs/Rouen/Rapport standard consores  2024.pdf`, section 3.1.
ConsoRes prints its denominator inside the incidence table, which is the only
reason this is checkable at all:

```
SARM : densité d'incidence (DI) : nombre de souches pour 1000 JH

  Bactériémie   0,024 (14/589397)
  Total         0,16  (95/589397)
```

**Denominator used: 589 397 JH.**

## Why it is kept

It is not a reference. It is the receipt for a divergence ORCHIDEE will have to
defend.

ORCHIDEE's denominator for the same establishment, the same year and the SPARES
perimeter is **355 246** patient-days — a ratio of **×1.66**. The 589 397 figure
is an SAE declaration made without any activity filter; it exceeds even
ORCHIDEE's unfiltered exposure table (564 968), so it covers activity that is
not in the movement data at all.

Consequence, using ConsoRes' own numerators:

| indicator | ConsoRes published | perimeter-correct |
|---|---|---|
| SARM, all samples | 0,16 | **0,27** |
| SARM, blood cultures | 0,024 | **0,039** |

Every incidence density in this report is understated by 40 %. Consumption
divides by the same JH, so the establishment figure of 526,9 DDJ/1000 JH is
understated by the same factor.

When ORCHIDEE publishes 0,27 against a national tool's 0,16, the first reading
will be that ORCHIDEE has a bug. This file is the answer.

See `docs/methods/04-donnees-activite.md` decision 04.1 and
`docs/worked-examples/denominator.md`.
