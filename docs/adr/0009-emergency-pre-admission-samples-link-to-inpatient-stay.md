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

- The interval attribution engine supports a 24-hour look-ahead window for
  Emergency Department (TA 10) specimens.
- An ED specimen followed by an acute inpatient admission (TA 03/20) within 24
  hours is attributed to the initial receiving inpatient unit (and flagged as an
  admission episode).
- ED specimens from patients who are discharged home without inpatient
  hospitalisation remain excluded from inpatient surveillance.
- The pre-flight audit ledger logs the volume and resistance rates of
  ED-to-inpatient linked isolates.
