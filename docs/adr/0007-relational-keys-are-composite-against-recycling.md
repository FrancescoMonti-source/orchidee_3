# Relational identifiers are composite to prevent cross-patient counter recycling

In hospital data pipelines, stays and microbiology isolates must be identified by
composite primary keys `(PATID, EVTID)` and `(PATID, ELTID, isolate_id)`. Single-column
identifiers (`EVTID` or `ELTID`) are not globally unique across time.

The methods name the local isolate identifier `isolate_id`. Historical witness
files name the same field `souche_id`, and Rouen's raw export uses `DLVL`.
Mapping the field name preserves its values, its scope within a sample, and the
composite-key decision. A retained isolate keeps this same key after
deduplication.

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
- The primary isolate key is strictly `(PATID, ELTID, isolate_id)`. Its historical
  uniqueness result (48 595 / 48 595) concerns a derived diagnostic table;
  it does not validate a new site's common input.
- Chapter 00 audits standardized input identities after local preparation,
  diagnostic selection and retention of isolates with an antibiogram, before
  shared hospital perimeter selection and deduplication (`Decision 00.2`).
  Native source inspection remains local; bind the reviewed identifier checks
  to the corresponding common-input key fields and available ID components.
