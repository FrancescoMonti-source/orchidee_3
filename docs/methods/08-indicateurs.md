# 08 - Indicator construction

Status: **partial**.

## What SPF asks for

A result per bacterium and per **antibiotic group**, not per molecule. Three
values: `R` if at least one molecule in the group is R; the empty set if no
molecule in the group is documented; `S` otherwise.

> 1 Inclue sensible, et sensible a forte posologie

Indicators: proportion of resistance, and incidence density per 1000 JH, each
computed for all diagnostic samples pooled and separately for blood cultures.
Plus five national-strategy indicators on resistance mechanisms.

> nous souhaiterions recevoir, pour tous les indicateurs agreges demandes, le
> numerateur et denominateur utilises

## What ORCHIDEE does

The indicator table is the primary deliverable: one row per indicator, period
and stratum, carrying its numerator and denominator beside the value, plus the
four deduplication inputs from `07-dedoublonnage.md`. Reports consume this table
and hold no calculation of their own.

The empty-set state is **materialised and counted**, not left as a missing
value. It is not "susceptible" and not "absent data": it is *observed absence of
testing*. It leaves the denominator of a proportion while the isolate still
counts toward incidence density.

Two traps this closes. The empty set applies to the **group**, not the cell: one
documented `S` on ciprofloxacine with the other three fluoroquinolones untested
gives `S`, not the empty set. And a group whose only results are `ZIT` gives
`S`, because `ZIT` is a documented result and `SFP` reports as `S` per the
footnote above.

## Open

- The empty-set count per couple **is** the testing coverage. A 2 % rate on 40
  tested isolates is not the claim a 2 % rate on 3900 tested isolates is. Decide
  whether coverage is published as its own indicator.
- Stratification dimensions: activity sector and department in the short term;
  age, sex, sampling site, sample type in the medium term. Which are dimensions
  on the table, and which are separate tables?
- Small numbers. At monthly frequency, stratified by sector, many cells will
  hold single-digit denominators. Suppression threshold, or publish with the
  denominator and let the reader judge?
- The antibiotic groups themselves - which molecules compose "fluoroquinolones"
  for each species - move from ingestion filters to **indicator definitions**.
  Write them down here, per SPF Annexe 3.
