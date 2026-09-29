# Historical 30-day deduplication witness — under audit

**Status**: The earlier 30-day rolling results in this file are unreproduced and do
not establish Decision 07.2. They were measured on a previous bundle and used a
comparison rule superseded by Decision 07.6. No tracked script or recorded
boundary/group-reset rule reproduces the reported rolling count.

## Current reproducible baseline

The 2024 Rouen *E. coli* / urine slice contains 4 963 input isolates and 4 039
patients. On the provisional v3 bundle, comparing BLSE/carbapenemase flags and
using the all-members grouping from Decision 07.6 retains 4 441 isolates under
the annual calendar window and 4 814 under pooled monthly windows.

A direct implementation of the former rolling-window description retains 4 729
isolates with phenotype comparison and Decision 07.6, or 4 727 without phenotype
comparison. Neither reproduces the historical 4 718. The missing historical
boundary and group-reset rules prevent an authoritative comparison. These current
counts are also provisional because the bundle's site mappings have not been
reviewed.

The historical figures from the former witness were removed because their
calculation cannot be reproduced from tracked code. See
`docs/worked-examples/deduplication.md` for the current calendar-window witness
and `docs/methods/07-dedoublonnage.md` for the Decision 07.2 status.
