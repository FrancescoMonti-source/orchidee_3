# 04 - Activity data (the denominator)

Status: **not started**. Shared with the CATB project.

## What SPARES says

The number of hospitalisation days is the count of complete and weekly
hospitalisation days billed in the period, as declared to the SAE. Collected per
unite fonctionnelle.

## Why this section is shared

DDJ / 1000 JH and incidence density / 1000 JH divide by the same denominator,
derived from the same intervals under the same perimeter. If the two projects
each compute it, they will differ, and the difference is undetectable from
inside either one.

Settled: a **file contract**, not a shared library, because the CATB project is
in Python. Owned by **neither** project - a small component both consume,
producing `(unit, period, denominator_profile, patient_days, perimeter_flags)`
and nothing else.

## Open

- **Several denominator profiles.** `midnight_presence` is the only one defined
  today. Emergency and full hospitalisation plausibly need different exposure
  definitions. Decide whether the profile is a dimension carried on every row.
- SPARES takes patient-days from the **SAE declaration**. ORCHIDEE computes them
  from hospitalisation intervals. These will not agree. Measure the gap; it is a
  witness nobody has taken.
- Denominator for admissions-based indicators (SPF asks for incidence per 1000
  admissions in the medium term).
- Who owns and versions the shared component, and where does it live?
