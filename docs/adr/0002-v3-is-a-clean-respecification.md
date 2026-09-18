# ORCHIDEE v3 is a clean re-specification, not a fork of v2

Nothing is carried over from the `orchidee` repository unless it is re-derived
from the source documents. The v2 codebase is kept as a differential oracle to
measure against, and the published CHU Rouen ConsoRes 2024 report is kept as the
external oracle.

## Why

The stated defect in SPARES/ConsoRes is not that its numbers are wrong but that
its method is unreviewable and its implementation privately held. Restructuring
v2 would inherit the decisions v2 took silently; re-deriving from the documents
forces each one to be stated before it can be implemented.

v2 also cannot serve as its own reference. Its baseline
(`outputs/rouen_2026-08-02_baseline`) was built at commit `a361796`, after the
mapping corrections it would need to detect, so "does v3 match v2?" is not a
question v2 can currently answer.

## Consequences

- v2 stays on disk and readable. Its `documentation/methods.md` is a decision
  register and a useful inventory of decisions already discovered.
- Where v3 and v2 differ, the difference must be attributable to a named
  decision, not merely observed.
