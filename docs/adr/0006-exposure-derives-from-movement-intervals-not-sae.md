# Exposure derives from movement intervals in the SPARES perimeter, not administrative SAE

Incidence density exposure denominators are derived directly from patient
movement intervals within eligible clinical units in the SPARES perimeter.
ORCHIDEE measures canonical exposure in occupancy hours, which simplifies
identically to midnight presence on date-only movements.

## Why

The third-party platform ConsoRes calculates incidence densities by dividing by
the whole-establishment administrative declaration (Statistique annuelle des
établissements de santé, SAE). At Rouen in 2024, the SAE declares 589 397
patient-days across the entire hospital group without activity filtering.

However, the SPARES method restricts surveillance to complete and weekly
hospitalisation within designated clinical sectors (excluding ambulatory care,
sessions, consultations, emergency passages, and home care). ORCHIDEE calculates
exposure directly from hospitalisation movement intervals within that defined
perimeter (355 246 patient-days at Rouen in 2024). Dividing by the unfiltered
SAE understates all incidence densities in ConsoRes by **40 %** (`Finding 16`).

Furthermore, calculating exposure in occupancy hours divided by 24 provides
exact intra-day precision when timestamps exist, while algebraically reducing to
midnight presence on pure date-only movement extracts (`Finding 8`).

## Consequences

- SAE is not used as an exposure reference; it is recorded only as a comparability
  witness in the divergence ledger.
- The unit of exposure is always traceable to specific patient movement intervals.
- The numerator (deduplicated isolates) and denominator (exposure hours/days) are
  bound to the exact same positive clinical perimeter.
- Tripwire `TW-04.2` protects against mixed-grain timestamp contamination.
