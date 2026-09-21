# Indicator tables use tall key-value strata without database cell suppression

The core indicator table deliverable is structured as a tall key-value relation
`(indicator_id, period_grain, period, stratum_dimension, stratum_value, sample_scope, exposure_profile)`
and preserves exact numerators and denominators without cell masking ($n < 5$).

## Why

Surveillance indicators require flexible stratification (by hospital, clinical
sector, ward, age group, or patient sex) across multiple temporal grains (annual,
quarterly, monthly). A wide relational schema with dedicated columns per stratum
requires structural migrations whenever a new stratification dimension is requested
by public health authorities. A tall key-value schema accommodates arbitrary
stratum dimensions as rows without schema alteration.

Furthermore, in fine stratifications (such as monthly sector indicators), small cell
counts are ubiquitous: on Rouen 2024 data, 23.9 % of cells have $n < 5$ and 35.9 %
have $n < 10$. Suppressing or masking small numbers inside the core database destroys
the algebraic property that stratum counts sum to the whole-hospital total, and
prevents epidemiologists from running time-series regression models or statistical
process control.

## Consequences

- The database schema is permanently stable under stratification expansions.
- Core tables store unmasked numerators and denominators for complete auditability.
- Privacy thresholds (e.g. masking cells $< 5$) belong exclusively to presentation
  and export layers (Section 09), never to calculation or storage layers.
