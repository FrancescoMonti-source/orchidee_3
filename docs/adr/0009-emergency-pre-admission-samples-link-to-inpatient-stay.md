# Emergency Department diagnostic samples link to subsequent inpatient stays within 24 hours

Diagnostic bacteriology samples (including blood cultures) collected in the
Emergency Department (TA 10) are linked to an eligible inpatient stay if the
patient is admitted to complete hospitalisation (TA 03 / TA 20) within 24 hours
of sampling, and attributed to the initial receiving inpatient unit.

## Why

In acute hospital workflows, patients presenting with severe infections or
septic shock routinely have blood cultures and diagnostic specimens drawn in the
Emergency Department (TA 10) before transfer to an acute inpatient ward.

Under strict timestamp matching against PMSI movement intervals (`DATENT <=
sample_datetime < DATSORT`), specimens drawn in the ED prior to ward transfer
have `SEJUF = NA`. Discarding these isolates deletes acute community-onset and
admission bacteremias from the surveillance numerator, even though the patient
subsequently spends days or weeks in an intensive care or medical bed contributing
to the hospital exposure denominator ($JH$).

Conversely, unconditionally falling back to the laboratory ordering UF (Option B
in Decision 05.1) is flawed because it admits ambulatory patients and non-admitted
consultations who contribute zero hospitalisation days.

A bounded 24-hour pre-admission linkage window solves this dilemma: it captures
genuine admission bacteremias that triggered hospitalisation while strictly
excluding non-admitted ED visits.

## Consequences

- Because population selection must precede deduplication (`ADR-0004`), ORCHIDEE
  exposes three named perimeters (`perimeter_version` in `03-activites.md`,
  `05-structure.md`, and `08-indicateurs.md`), each deduplicated independently:
  1. **`spares_strict`**: inpatient hospitalisation (`CODE_TA ∈ {03, 20}` and
     eligible `CODE_DE`) restricted strictly to samples collected during an
     active inpatient movement interval (`DATENT <= sample_datetime < DATSORT`);
     all Emergency (`TA 10`) pre-admission samples are excluded.
  2. **`spares_ed24h`**: inpatient hospitalisation (`CODE_TA ∈ {03, 20}` and
     eligible `CODE_DE`) plus diagnostic samples outside an active inpatient
     interval that are identified as Emergency (`TA 10`) samples (via
     `microbiology_SEJUF ∈ TA 10` or a `TA 10` movement) and followed within
     `(sample_datetime, sample_datetime + 24h]` by an eligible inpatient
     movement (`CODE_TA ∈ {03, 20}` and eligible `CODE_DE`), attributed to the
     earliest such inpatient movement (`min(DATENT)`).
  3. **`emergency_ta10`**: a standalone Emergency Department perimeter (`TA 10`)
     retaining all diagnostic samples from `TA 10` (when not inside an active
     eligible `TA 03/20` movement, identified via `microbiology_SEJUF ∈ TA 10`
     or a `TA 10` movement, whether subsequently admitted or discharged home),
     deduplicating them strictly within `TA 10`, and publishing **resistance
     proportions (`%R`) and isolate counts only** (no patient-day `DI`).
- Because admitted pre-admission `TA 10` samples enter both `spares_ed24h` and
  `emergency_ta10`, those two perimeters are not disjoint and must never be
  summed together.
- The pre-flight audit ledger logs the volume and resistance rates of
  ED-to-inpatient linked isolates.
