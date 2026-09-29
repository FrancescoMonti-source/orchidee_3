# 01 - Surveillance period

Status: **under review**. Three decisions have current witnesses; Decision 01.3's rolling-window comparison is under audit.

---

## What SPARES says

> Cette étude recueille rétrospectivement les données du 1er janvier au 31 décembre
> 2024. (p. 9)

---

## What SPF asks

SPF asks for monthly estimation, and for the numerator and denominator of every
aggregated indicator (SPF p. 5):

> La fréquence d'estimation des indicateurs devra être mensuelle. [...] nous
> souhaiterions recevoir, pour tous les indicateurs agrégés demandés, le numérateur et
> dénominateur utilisés (le nombre de souches avec une résistance, le nombre de souches
> testés, le nombre total de JH). (p. 5)

The annual cadence comes from SPARES, whose campaign covers one calendar year (p. 9).

---

## What ORCHIDEE does

ORCHIDEE disentangles temporal surveillance along three independent axes:
1. **Cadence (When to report)**: Dual reporting — monthly for operational hospital monitoring, annual for national campaigns.
2. **Deduplication Window (Over what timeframe to group duplicates)**: French calendar boundaries (SPARES Annexe 1) are the production rule. A continuous 30-day rolling refractory window remains an experiment under audit (not the EARS-Net rule; see §3).
3. **State Lifecycle (Can past monthly numbers change?)**: Strictly immutable upon month close — no retrospective revision from later cultures.

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

### 3. Calendar Production Windows and Rolling-Window Experiment
The annual and monthly calendar counts in Decision 07.1 are remeasured with
phenotype comparison and decision 07.6. A former 30-day rolling witness is
under audit: its 4 718 count is not reproduced by the tracked calculation.
A direct implementation of the written description on the current provisional
bundle retains 4 729 with phenotype comparison and 07.6, or 4 727 without
phenotypes. The original boundary and group-reset rules are not recorded.
The historical comparison therefore does not establish calendar month-end
inflation. See `docs/evidence/dedup_window_30day_refractory_witness.md`.

The rolling window differs from the EARS-Net calendar-year rule for the first
blood or CSF isolate per patient and pathogen (ECDC reporting protocol 2025,
pp. 22 and 24-25).

### 4. Minimum Window and Real-Time Surveillance
- A surveillance run requires a minimum temporal slice of **at least one full calendar month**.
- In operational production, monthly indicators run continuously as each month concludes, without requiring the year to be complete.
- Annual indicator tables require a full twelve-month calendar year (`01-01` 00:00:00 to `12-31` 23:59:59) to prevent seasonal bias. Historical Rouen data (2022–2024) serves as the development and calibration baseline, not a temporal restriction on the product.

---

## Decisions

All witnesses measured on real Rouen data (`data/bact22_24`, `data/pmsi`).

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 01.1 | Temporal cadence | dual: monthly **and** annual | annual only | monthly provides real-time detection of resistance surges; annual keeps 4 441 isolates vs monthly 4 814 (+8.40 %) on *E. coli* urines (`07-dedoublonnage.md` 07.1) |
| 01.2 | Monthly finality | immutable upon month close (`window = "monthly"`) | provisional, revised at year-end | prevents retrospective alteration of past published monthly tables (Result 3 in `docs/worked-examples/deduplication.md`) |
| 01.3 | Window shape | calendar windows for production; rolling refractory remains an experiment | calendar only | historical rolling count 4 718 is unreproduced; direct current implementation gives 4 729 with phenotype flags and 07.6 or 4 727 without; see audit in `docs/evidence/dedup_window_30day_refractory_witness.md` |
| 01.4 | Minimum run grain | $\ge 1$ full calendar month | full calendar years only | allows ongoing 2026 operational surveillance; partial months rejected to protect exposure denominators |

Unproven / under audit: **1 of 4** (01.3).

---

## Open

Decision 01.3's historical rolling-window measurements are not reproduced under the current phenotype-aware 07.6 rule. Calendar windows remain the production choice; the rolling comparison does not establish a month-end effect.
