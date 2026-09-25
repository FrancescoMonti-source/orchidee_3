# 01 - Surveillance period

Status: **settled**. Four decisions, four witnesses, zero unproven. Zero open.

---

## What SPARES says

> Les données de résistance bactérienne sont recueillies rétrospectivement sur une
> période annuelle allant du 1er janvier au 31 décembre de l'année considérée.
> Les données de consommation et d'activité couvrent la même année civile.

---

## What SPF asks

SPF requires **monthly surveillance indicators** alongside the national annual campaign:

> nous souhaiterions recevoir, pour tous les indicateurs agrégés demandés, les
> résultats mensuels ainsi que le bilan annuel consolidé.

---

## What ORCHIDEE does

ORCHIDEE supports both active ongoing monthly surveillance and the annual national campaign:

### 1. Dual Temporal Cadence
Surveillance indicators are produced at two distinct grains:
- **`period_grain = "monthly"`**: Twelve independent monthly intervals per year (`YYYY-01` through `YYYY-12`).
- **`period_grain = "annual"`**: A consolidated twelve-month campaign (`YYYY`).

### 2. Monthly Immutability and Closed Windows
To prevent the **retrospective instability hazard** identified in `docs/worked-examples/deduplication.md` (Result 3):
- Under an annual deduplication window, the tiebreak rule favoring the isolate with **more molecules tested** can reach backwards across months (e.g. an October isolate with 22 molecules tested retroactively drops an April isolate with 19 molecules, reducing April's published count months later).
- ORCHIDEE resolves this by enforcing **independent closed monthly windows** (`window = "monthly"`). Each calendar month is deduplicated in strict isolation.
- Once a calendar month is closed, its published indicators are **final, closed, and immutable**. Subsequent hospitalizations or bacteriology cultures in later months never retroactively alter past monthly figures.
- The annual indicator table is an independent measurement under `window = "annual"`, not an arithmetic sum of the twelve monthly tables.

### 3. Dual Episode Modeling: European Alignment (EARS-Net / ECDC)
To eliminate calendar boundary artifacts while supporting international benchmarks:
- **Calendar Windows (Production Standard)**: Satisfies the French national SPARES/SPF convention. As measured in Decision 07.2, monthly calendar deduplication introduces an artificial **+1.97 % episode inflation** in urines and **+1.50 % in blood cultures** due to cultures 2–4 days apart straddling month ends (e.g. Jan 29 and Feb 2) counted twice.
- **30-Day Rolling Refractory Window (European Reference)**: ORCHIDEE implements the European EARS-Net / ECDC 30-day episode standard using the **chronological sweep automaton** (`docs/evidence/dedup_window_30day_refractory_witness.md`), while preserving phenotype-awareness for emergent resistance under therapy.
- Both episode models are computable from the same underlying dataset; either can be selected or retired by configuration at zero architectural cost.

### 4. Minimum Window and Real-Time Surveillance
- A surveillance run requires a minimum temporal slice of **at least one full calendar month**.
- In operational production (such as 2026 ongoing surveillance), monthly indicators run continuously as each month concludes, without requiring the year to be complete.
- Annual indicator tables require a full twelve-month calendar year (`01-01` 00:00:00 to `12-31` 23:59:59) to prevent seasonal bias. Historical Rouen data (2022–2024) serves as the development and calibration baseline, not a temporal restriction on the product.

---

## Decisions

All witnesses measured on real Rouen data (`data/bact22_24`, `data/pmsi`).

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 01.1 | Temporal cadence | dual: monthly **and** annual | annual only | monthly provides real-time detection of resistance surges; annual keeps 4 438 isolates vs monthly 4 813 (+8.45 %) on *E. coli* urines (`07-dedoublonnage.md` 07.1) |
| 01.2 | Monthly finality | immutable upon month close (`window = "monthly"`) | provisional, revised at year-end | prevents retrospective alteration of past published monthly tables (Result 3 in `docs/worked-examples/deduplication.md`) |
| 01.3 | Episode model | calendar windows (SPARES), with 30-day rolling refractory window (EARS-Net) | calendar only | 30d rolling refractory eliminates +1.97 % month-end calendar inflation and cross-year resetting; `docs/evidence/dedup_window_30day_refractory_witness.md` |
| 01.4 | Minimum run grain | $\ge 1$ full calendar month | full calendar years only | allows ongoing 2026 operational surveillance; partial months rejected to protect exposure denominators |

Unproven: **0 of 4**.

---

## Open

None. Chapter 01 is settled.
