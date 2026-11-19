# In R, from the repository root:
# source("docs/worked-examples/first_eligible_month.R")
# first_eligible_month(moves, 2022:2024)
#
# Use the complete, source-reconciled movement table from sector_returns.R,
# including ineligible movements and stays without a specimen. Pass the whole
# extract before selecting cohort years. DATENT is a movement start time:
# the first observed movement provides a proxy for administrative admission.

first_eligible_month <- function(moves, years = 2022:2024) {
  fields <- c("PATID", "EVTID", "DATENT", "eligible")
  stopifnot(all(fields %in% names(moves)), inherits(moves$DATENT, "POSIXt"),
            is.logical(moves$eligible), length(years) > 0L, !anyNA(years))
  d <- as.data.frame(moves)[fields]
  keyed <- !is.na(d$PATID) & nzchar(trimws(d$PATID)) &
    !is.na(d$EVTID) & nzchar(trimws(d$EVTID))
  d <- d[keyed, ]
  d <- d[order(d$PATID, d$EVTID, d$DATENT), ]
  first <- !duplicated(d[c("PATID", "EVTID")])
  stay <- cumsum(first)
  ids <- seq_len(sum(first))
  month <- format(d$DATENT, "%Y-%m", tz = "Europe/Paris")
  start <- month[first]

  # After sorting, match selects the earliest month with the given status.
  first_month_with <- function(rows) month[rows][match(ids, stay[rows])]
  eligible <- first_month_with(which(d$eligible))
  unknown <- first_month_with(which(is.na(d$eligible)))
  dated <- !ids %in% stay[is.na(d$DATENT)]
  year <- as.integer(substr(start, 1L, 4L))

  # One known eligible entry in the start month settles the question even if
  # another movement in that month has unknown eligibility. To confirm a later
  # month, every movement recorded in the start month must be known ineligible.
  same <- !is.na(eligible) & eligible == start
  later <- !is.na(eligible) & eligible > start & (is.na(unknown) | unknown > start)
  none_observed <- is.na(eligible) & is.na(unknown)
  later_year <- later & substr(eligible, 1L, 4L) > substr(start, 1L, 4L) &
    (is.na(unknown) | substr(unknown, 1L, 4L) > substr(start, 1L, 4L))

  by_year <- lapply(sort(unique(years)), function(y) {
    cohort <- which(dated & year == y)
    data.frame(first_observed_year = y, stays = length(cohort),
               eligible_in_start_month = sum(same[cohort]),
               first_eligible_later_month = sum(later[cohort]),
               of_which_confirmed_later_year = sum(later_year[cohort]),
               no_eligible_observed = sum(none_observed[cohort]),
               eligibility_indeterminate = sum(!(same | later | none_observed)[cohort]))
  })
  list(by_year = do.call(rbind, by_year),
       rows_without_patient_or_stay = sum(!keyed),
       stays_with_missing_start_time = sum(!dated))
}
