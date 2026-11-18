# Indicator tables use tall key-value strata without database cell suppression

The indicator table stores one row per indicator, period, stratum, specimen scope
and exposure profile. Each row keeps the exact numerator and denominator, even
for small counts. Its dimensions are
`(indicator_id, period_grain, period, stratum_dimension, stratum_value, sample_scope, exposure_profile)`.

## Why

Surveillance indicators require flexible stratification (by hospital, clinical
sector, ward, age group, or patient sex) across multiple temporal grains (annual,
quarterly, monthly). A wide relational schema with dedicated columns per stratum
requires structural migrations whenever a new stratification dimension is requested
by public health authorities. A tall key-value schema accommodates arbitrary
stratum dimensions as rows without schema alteration.

In Rouen's 2024 monthly sector analysis of *E. coli*, 22 of 92 non-empty cells
contained fewer than 5 isolates (23.9 %), and 33 contained fewer than 10
(35.9 %). Keeping those counts lets users check totals and use the full series
for time-series regression or statistical process control. [Rouen worked example](../worked-examples/indicators.md)

## When sector counts add up

For a given indicator, period and specimen scope, sector isolate counts sum to
the hospital count when every isolate retained by the hospital-wide analysis is
assigned to exactly one sector.

If an indicator calls for deduplication within each sector, a patient can
contribute one isolate in medicine and one in surgery even when hospital-wide
deduplication retains only one of the two. In that case the hospital count
comes from its own analysis. The indicator definition determines the population
for deduplication and the denominator for the rate. For example, analysis by
specimen type already uses deduplication within each type, and the overall
specimen analysis deduplicates across types. [Chapter 07](../methods/07-dedoublonnage.md)

## Consequences

- The database schema is permanently stable under stratification expansions.
- Core tables store unmasked numerators and denominators for complete auditability.
- Hospitals deliver exact counts in the indicator tables. Any masking of small
  counts for public release takes place at the national publication stage.
  [Chapter 09, decision 09.1](../methods/09-diffusion.md)
