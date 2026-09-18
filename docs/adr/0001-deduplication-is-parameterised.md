# Deduplication records its inputs, and varies on only one of them

Deduplication depends on four things: the **grouping key**, the **window**, the
**antibiotype panel**, and the **conflict rule**. None of them can be applied as
a filter afterwards, so every published number records all four values it was
produced under, and numbers produced under different values are never summed or
compared.

Only one of the four varies at run time.

| Input | Value | Treatment |
|---|---|---|
| **Window** | calendar, annual and monthly | **Parameter.** SPF requires monthly; comparability requires annual. Both are needed at once. |
| **Grouping key** | patient (`PATID`) | **Decided**, as SPARES asks. `EVTID` is retained in the data so the stay-level witness stays computable. |
| **Conflict rule** | `S <-> R` and `SFP <-> R` are major; `S <-> SFP` is minor; `ZIT` is read as `SFP` | **Decided**, following the SPF text. |
| **Panel** | every antibiotic the site tests | **Decided, with a tripwire** asserting that the SPARES panel would keep the same isolates. |

## Why record all four when only one varies

Each one silently changes indicators that have no apparent relation to it.
Measured on Rouen, *E. coli* / urines / 2024, 4963 isolates before
deduplication:

- **window**: annual keeps 4438 isolates, monthly keeps 4813 (+8.4 %). The
  proportions move by 0.3 pp while every incidence density moves by 8.4 %.
- **panel**: removing amoxicilline-acide clavulanique from the panel costs 66
  isolates and moves ofloxacine up 0.12 pp while cotrimoxazole moves down
  0.60 pp - two indicators that do not contain it, moving in opposite
  directions.
- **conflict rule**: reading `SFP <-> R` as major keeps 4438 isolates; reading
  `ZIT` as never conflicting, which is what v2's `methods.md` decided, keeps
  4428. On the denominator question alone, amoxicilline-acide clavulanique reads
  39.88 % or 39.16 %.
- **grouping key**: patient-and-year collapses one infection, repeated
  infections and a chronic infection into a single isolate. The undercount
  therefore falls on chronic and re-admitted patients, so it varies with case
  mix - which weakens the comparison between establishments that the
  surveillance exists to provide. SPARES states its choice and never argues for
  it.

The historical case is the same mechanism: correcting one antibiotic's mapping
removed 51 isolates from the deduplicated scope and moved the denominators of 20
antibiotic columns (`docs/evidence/2026-08-02_amc_remapping_cascade.txt`).

Recording a value costs nothing even when it never varies, and it is what makes
a future change visible instead of silent.

## Why not make all four parameters

A parameter is earned only when two consumers need different values at the same
time. Otherwise it pushes the decision downstream onto someone with less context
than we have, which is the failure this project exists to correct. An unresolved
parameter is an unprescribed decision with extra steps.

The alternatives are therefore recorded as **witnesses**, not shipped as
options: the other value is computed once, its numbers are written into the
register, and the code that produced them is set aside.

## Consequences

- There is no such thing as "the deduplicated isolate table". Every isolate set
  exists only relative to its four inputs.
- The window is expressed as a **predicate** over a pair of isolates
  (`same_window(i, j)`), not as a grouping column. A calendar window is
  `year(i) == year(j)`; a rolling refractory window would be
  `abs(date(i) - date(j)) <= N`. Writing it this way now costs nothing and
  changes no behaviour, and it is what keeps the rolling shape cheap to add.
- A rolling refractory window remains an **experiment**, not a parameter. No
  consumer asks for it, and it introduces a non-transitive relation between
  isolates that would need its own sweep rule.
- Sample dates are never discarded, so the window decision destroys no
  information and stays reversible.
