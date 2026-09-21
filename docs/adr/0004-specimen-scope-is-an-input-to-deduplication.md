# Specimen scope is an input to population selection before deduplication

Specimen scoping (e.g. diagnostic samples vs. blood cultures) must run before
deduplication, never as a filter on its result. The deduplication algorithm is
partitioned by `(PATID, species, specimen_scope)`.

## Why

Deduplication is not monotone: filtering after deduplication silently deletes
valid bacteremias. When an isolate is discarded by global deduplication, a later
blood culture from the same patient cannot be resurrected.

On Rouen 2024 data, deduplicating globally and then filtering on blood cultures
deletes **35.65 % of *S. aureus* bacteremias** (216 down to 139, losing 77
isolates) and **15.36 % of *E. coli* bacteremias** (267 down to 226, losing 41
isolates). For methicillin-resistant *S. aureus* (SARM), 5 out of 15 bacteremias
are erased (−33.3 %), artificially suppressing the incidence density from
0.0422 to 0.0281 / 1 000 JH (`Finding 17`).

The mechanism is preemption: an earlier non-blood sample (e.g. urine or wound
swab) wins the oldest-sample rule, collapsing the patient's episode and causing
the subsequent bacteremia to be dropped.

## Consequences

- Specimen scope is an input argument to the deduplication pipeline.
- Indicators for all diagnostic samples and indicators for blood cultures are
  computed from independent deduplication runs.
- Cross-species competition is impossible: an isolate of one species never
  deduplicates against or affects an isolate of another.
