# Exposure derives from movement intervals in the SPARES perimeter, not administrative SAE

Incidence density exposure denominators are derived directly from patient
movement intervals within eligible clinical units in the SPARES perimeter.
ORCHIDEE measures canonical exposure in occupancy hours, which simplifies
identically to midnight presence on date-only movements.

## Why

The third-party platform ConsoRes prints the patient-days figure it divides
incidence densities by: 589 397 for Rouen in 2024 (ConsoRes standard report,
p. 15). SPARES p. 13 says the activity data entered into ConsoRes are the days
declared in the Statistique annuelle des établissements de santé (SAE),
collected per functional unit. Which units Rouen submitted is not documented on
disk. Reading 589 397 as the whole-establishment SAE declaration without
activity filtering is our inference, made because the figure exceeds even
ORCHIDEE's unfiltered exposure table (564 968 patient-days). The ConsoRes
report labels its own perimeter « Sanitaire SPARES » (p. 1).

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
