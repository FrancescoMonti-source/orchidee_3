# 06 - Bacterial resistance data

Status: **partial**.

## What SPARES says

Only strains isolated from **diagnostic** samples having had an antibiogram are
included. Samples taken for ecological purposes - colonisation, carriage,
screening - are excluded.

Each isolate is characterised by a source patient, a sampling date and site, an
antibiotype, and for Enterobacterales a resistance phenotype (BLSE,
carbapenemase). For each molecule tested the result is S, SFP or R. Only
antibiograms interpreted with CA-SFM/EUCAST 2020 or later are accepted.

## What ORCHIDEE does

**Screening is excluded** at population selection: after ingestion, before
deduplication. Screening rows are ingested and **marked**, never dropped, so the
exclusion is a re-run rather than a re-extraction, and so ORCHIDEE can count
what it excluded without asking the site for anything extra.

The order is part of the rule. Deduplicating first can select a screening
isolate as a patient's representative; the later exclusion then removes that
patient entirely, taking a legitimate diagnostic isolate with it.

An **isolate** is `(PATID, ELTID, souche_id)`. `EVTID` carries no additional
identity but is retained: screening propagation depends on it, and the
stay-level grouping witness (07.3) needs it.

## Decisions

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 06.1 | Screening samples | excluded | included | +5.6 % isolates; cefotaxime 16.96 -> 25.19 %R; ertapeneme x4.3. `docs/worked-examples/screening-exclusion.md` |
| 06.2 | `ZIT` against `SFP` | `ZIT` is read as `SFP`, per the SPF text | `ZIT` treated as missing data | see 07.5: 4438 isolates against 4428 |
| 06.3 | Isolate key | `(PATID, ELTID, souche_id)` | collapse same species within a sample | 213 triples split across several `souche_id`, 214 extra isolates, 0.4 % |

Neither specification mentions `ZIT`. It exists only in the CA-SFM reference and
in hospital exports, so equating it with `SFP` is an ORCHIDEE decision that no
external document prescribes. See `CONTEXT.md`.

## Open

- **Screening flag quality.** Misclassification runs one way only: a screening
  sample not identified is counted as diagnostic, never the reverse. The
  published rate is therefore an over-estimate of unknown size. The slope is
  known (+8.23 pp on cefotaxime for the full screening population), so the bias
  can be published as a range once the miss rate is estimated. `unproven`.
- **The flag is set by the site and nothing makes two sites agree.** Two
  hospitals with identical epidemiology and different screening-coding practice
  publish cefotaxime rates several points apart. Not fixable by taking the
  decision back - the site contract must define "diagnostic" in clinical terms,
  and ORCHIDEE must publish the exclusion counts it already derives.
- Resistance phenotypes (BLSE, carbapenemase): an absent phenotype is treated as
  negative in deduplication. Confirm and find a witness.
- CA-SFM version: SPARES refuses antibiograms older than 2020. Does ORCHIDEE
  check the version, and against what field?
- Bacterial vocabulary: open input, closed ONERBA target, counted residue. The
  14-value `recognized_bact_norm.csv` is v2's perimeter, not a taxonomy.
