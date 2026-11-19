# Monthly resistant isolates per 1 000 admissions

## What a sector-month can show

Suppose one patient enters surgery in February, stays in the same ward and
has a resistant isolate collected and retained in March. No other patient
has a resistant isolate. Vary only the number of other stays entering
surgery for the first time in March.

| March in surgery | Retained isolates | Stays with a first eligible surgical entry | Isolates per 1 000 such stays |
|---|---:|---:|---:|
| No new entry | 1 | 0 | Not calculable |
| One new entry | 1 | 1 | 1 000 |

Neither case requires a transfer or a return. In the second case the new
entrant had no resistant isolate. Several isolates from earlier admissions
could take the ratio above 1 000 per 1 000. Keep the two counts visible. A
confirmed zero denominator gives an undefined ratio for both 1/0 and 0/0.
A zero numerator with a positive denominator gives a rate of zero. Record an
unknown admission count as missing so it can be distinguished from zero entries.

### Choosing a denominator

- Isolates per 1 000 first sector entries relate specimens collected during
  the month to new entries during that month.
- Isolates per 1 000 sector patient-days relate the same events to time
  spent in the sector during the month, including time from earlier admissions.
- The proportion of stays with at least one resistant isolate requires
  following the stays with a first sector entry in a given month until an
  agreed endpoint, such as hospital discharge. Each affected stay counts once.
  A February cohort can therefore require March specimens before it is complete.

## What the Rouen movement checks measured

The following aggregate results were reported from the protected Rouen PMSI
extract. The year is the year of the first observed movement in each stay.

- **Returns within a stay, 2024.** Of 27 268 evaluable stays, 1 353 returned
  to at least one sector. In surgery, 770 of 7 691 evaluable stays returned.
  Their 849 extra entries would raise the denominator from 7 691 to 8 540
  (+11.0%). Another 6 509 stays had an uncertain path, including 130 with a
  documented eligible surgical movement. The extract may conceal surgical
  entries among the other uncertain paths. [Sector return script](../worked-examples/sector_returns.R)
- **First eligible hospital movement, 2022–2024.** In 319, 262 and 225 stays
  respectively, the first confirmed eligible movement fell after the month
  of the first observed movement (806 total). In 51 of these stays eligibility
  was first confirmed in a later year. A further 15 172 stays had indeterminate
  eligibility or timing. The first observed movement approximates administrative
  admission. End-of-extract follow-up limits observation of later entries.
  [First eligible month script](../worked-examples/first_eligible_month.R)

Both checks use movements. Neither counts sector-months with positive isolates
and zero entries. To measure the effect in Rouen, compare the monthly sector
denominators using hospital admission month, first eligible sector entry and
all eligible sector entries including returns. Link the retained isolates to
their stays to count how many come from earlier entry months and how many
sector-months have isolates but zero first entries. Report uncertain paths
and missing history separately. A December admission can have its first
surgical entry in January; determining whether it is the first requires
earlier movements of that same stay, even outside the reporting year.

## Questions sent on 19 November 2026

The project asked Santé publique France to clarify the indicator per 1 000
admissions in the [requirements, p. 7](../Expression%20de%20besoins%20SPF.pdf).
Its reply is pending.

1. Should the monthly figure relate isolates to first entries during the
   same calendar month, or measure the proportion of stays entering that
   month with a resistant isolate before discharge?
2. For the hospital denominator, should a stay first entering an eligible
   unit in January count in January if its administrative admission was in
   December? January is the project proposal. Assigning it to December
   would require knowing the January movement before closing December, or
   revising the closed month. [Monthly closure](../methods/01-periode-surveillance.md#2-monthly-immutability-and-closed-windows)
3. Are both sector measures wanted? The rate within surgery uses isolates
   deduplicated within surgery and stays entering surgery. The contribution
   of surgery to the hospital rate uses isolates assigned to surgery after
   hospital-wide deduplication and all eligible hospital admissions.
   [Sector and hospital counts](../adr/0008-indicator-tables-use-tall-strata-without-cell-suppression.md#when-sector-counts-add-up)
