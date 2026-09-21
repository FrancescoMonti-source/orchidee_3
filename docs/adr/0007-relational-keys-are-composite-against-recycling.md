# Relational identifiers are composite to prevent cross-patient counter recycling

In hospital data pipelines, stays and microbiology isolates must be identified by
composite primary keys `(PATID, EVTID)` and `(PATID, ELTID, souche_id)`. Single-column
identifiers (`EVTID` or `ELTID`) are not globally unique across time.

## Why

Hospital administrative registration systems (e.g. CPAGE) and laboratory information
systems (e.g. GLIMS) generate stay numbers (`EVTID`) and sample accession numbers
(`ELTID`) using cyclical sequence counters rather than globally unique UUIDs. Over
multi-year surveillance horizons, these numbers are systematically recycled.

Empirical audit on Rouen raw data proves:
1. In administrative PMSI movements, **169 out of 194 566 `EVTID`s** are associated
   with multiple patients across calendar years, including 35 collisions within the
   exact same extract file (`SRC == 'C'`).
2. In raw bacteriology (`bact22_24`), **135 `ELTID`s** occur across different patients,
   with 94.8 % of collisions occurring $> 30$ days apart (up to 2.8 years).

Treating `EVTID` or `ELTID` as globally unique keys corrupts relational integrity,
cross-contaminating patient medical histories and corrupting unit attribution.

## Consequences

- Every join between microbiology and movements uses `(PATID, EVTID)`.
- The primary isolate key is strictly `(PATID, ELTID, souche_id)`, ensuring 100 %
  uniqueness across the 3-year surveillance extract (48 595 / 48 595).
- Pre-flight audit Suite 1 tests stay and accession number collision defenses on
  every site handoff (`Decision 00.2`).
