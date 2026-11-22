# Exploratory count of observed returns to a clinical sector within one stay.
# From the repository root, using the protected Rouen PMSI RDS ($main):
# Rscript docs/worked-examples/sector_returns.R data/pmsi 2024
# Optional third argument: path to the UF structure workbook for the cohort.
# Requires redsan and readxl for the Rouen input. The default workbook is the
# Rouen snapshot used in the other 2024 worked examples. Verify its applicability.
# The cohort year is the year of the first observed movement. Supply whole stays,
# including movements across calendar boundaries. Only aggregate counts are printed.
# With pmsi$main already in R, source this file from the repository root,
# then run moves <- prepare_rouen_pmsi_moves(pmsi$main).
# monthly_sector_admissions(moves) compares reporting months across sectors.

# Return the first eligible row of each observed sector visit, in time order.
# The annual return check selects stays by start year. The monthly comparison
# examines the whole supplied history before selecting reporting months.
observed_sector_entries <- function(moves, cohort_year = NULL) {
  required <- c("PATID", "EVTID", "DATENT", "DATSORT", "sector", "eligible")
  stopifnot(all(required %in% names(moves)), inherits(moves$DATENT, "POSIXt"),
            inherits(moves$DATSORT, "POSIXt"), is.logical(moves$eligible))
  moves <- as.data.frame(moves)[required]
  keyed <- !is.na(moves$PATID) & nzchar(trimws(moves$PATID)) &
    !is.na(moves$EVTID) & nzchar(trimws(moves$EVTID))
  unkeyed_rows <- sum(!keyed)
  d <- unique(moves[keyed, ])
  d <- d[order(d$PATID, d$EVTID, d$DATENT, d$DATSORT), ]
  d$stay <- cumsum(!duplicated(d[c("PATID", "EVTID")]))
  by_stay <- split(seq_len(nrow(d)), d$stay)

  starts <- as.numeric(d$DATENT)
  ends <- as.numeric(d$DATSORT)
  month <- format(d$DATENT, "%Y-%m", tz = "Europe/Paris")
  stay_month <- month[!duplicated(d$stay)]
  entry <- logical(nrow(d))
  pending_year <- uncertain <- outside <- 0L
  for (pos in by_stay) {
    if (anyNA(starts[pos])) {
      pending_year <- pending_year + 1L
      next
    }
    if (!is.null(cohort_year) && substr(month[pos[1L]], 1L, 4L) != cohort_year) next
    sector <- d$sector[pos]
    eligible <- d$eligible[pos]
    exit_time <- ends[pos]
    # An open final movement can confirm an observed entry. A missing earlier
    # end or overlapping different sectors makes the sequence uncertain.
    if (anyNA(sector) || any(!nzchar(sector)) || anyNA(eligible) ||
        anyNA(head(exit_time, -1L)) || any(exit_time <= starts[pos], na.rm = TRUE)) {
      uncertain <- uncertain + 1L
      next
    }
    change <- sector[-1L] != head(sector, -1L)
    if (any(change & starts[pos[-1L]] < cummax(head(exit_time, -1L)))) {
      uncertain <- uncertain + 1L
      next
    }
    if (!any(eligible)) {
      outside <- outside + 1L
      next
    }
    # A gap alone cannot establish a return. A different observed sector must
    # intervene. Date a visit at its first eligible movement.
    visit <- cumsum(c(TRUE, change))
    eligible_rows <- pos[eligible]
    entry[eligible_rows[!duplicated(visit[eligible])]] <- TRUE
  }
  entries <- data.frame(patient = as.character(d$PATID[entry]), stay = d$stay[entry],
    sector = as.character(d$sector[entry]), stay_month = stay_month[d$stay[entry]],
    entry_month = month[entry])
  list(entries = entries, rows_without_patient_or_stay = unkeyed_rows,
       stays_with_missing_start_time = pending_year, stays_with_uncertain_path = uncertain,
       stays_without_eligible_sector = outside)
}

count_sector_returns <- function(moves, year) {
  result <- observed_sector_entries(moves, cohort_year = year)
  all <- result$entries
  summarise <- function(rows) {
    repeated <- duplicated(rows[c("stay", "sector")])
    data.frame(patients = length(unique(rows$patient)),
               patients_with_return = length(unique(rows$patient[repeated])),
               stays = length(unique(rows$stay)),
               stays_with_return = length(unique(rows$stay[repeated])),
               extra_entries = sum(repeated))
  }
  list(year = year, rows_without_patient_or_stay = result$rows_without_patient_or_stay,
       stays_with_uncertain_cohort_year = result$stays_with_missing_start_time,
       cohort_stays_with_uncertain_path = result$stays_with_uncertain_path,
       cohort_stays_without_eligible_sector = result$stays_without_eligible_sector,
       any_sector = summarise(all),
       by_sector = lapply(split(all, all$sector), summarise))
}

# Compare counts for the same evaluable paths. A stay may enter different
# sectors in different years. Select the reporting month separately for each
# convention. Quality counts describe the entire supplied extract.
monthly_sector_admissions <- function(moves, years = 2022:2024,
    sectors = sort(unique(as.character(moves$sector[which(moves$eligible)])))) {
  stopifnot(is.numeric(years), length(years) > 0L, all(is.finite(years)),
            all(years == as.integer(years)), !anyNA(sectors))
  months <- sort(unique(as.vector(outer(years, sprintf("%02d", 1:12), paste, sep = "-"))))
  sectors <- unique(as.character(sectors))
  result <- observed_sector_entries(moves)
  entries <- result$entries
  first <- entries[!duplicated(entries[c("stay", "sector")]), ]
  grid <- expand.grid(month = months, sector = sectors, stringsAsFactors = FALSE)
  dates <- moves$DATENT[!is.na(moves$DATENT)]
  in_extract <- rep(FALSE, nrow(grid))
  if (length(dates)) {
    observed <- format(range(dates), "%Y-%m", tz = "Europe/Paris")
    in_extract <- grid$month >= observed[1L] & grid$month <= observed[2L]
  }
  count <- function(month, sector) {
    counts <- as.integer(table(factor(month, levels = months), factor(sector, levels = sectors)))
    counts[!in_extract] <- NA_integer_
    counts
  }
  grid$by_first_observed_stay_month <- count(first$stay_month, first$sector)
  grid$by_first_eligible_sector_month <- count(first$entry_month, first$sector)
  grid$entries_including_returns <- count(entries$entry_month, entries$sector)
  list(by_sector_month = grid, quality_full_extract = result[names(result) != "entries"])
}

classify_rouen_movements <- function(raw, units, domains) {
  stopifnot(all(c("UF", "CODE_DE", "CODE_TA") %in% names(units)),
            all(c("CODE_DE", "DOMAINE") %in% names(domains)), "SEJUF" %in% names(raw))
  units <- units[!is.na(units$UF), c("UF", "CODE_DE", "CODE_TA")]
  # Normalise numeric padding while preserving alphanumeric DE codes.
  de_key <- function(x) sub("^0+([0-9])", "\\1", trimws(x))
  domains$CODE_DE <- de_key(domains$CODE_DE)
  domains <- unique(domains[c("CODE_DE", "DOMAINE")])
  ambiguous <- domains$CODE_DE[duplicated(domains$CODE_DE)]
  domains <- domains[!domains$CODE_DE %in% ambiguous, ]
  stopifnot(!anyDuplicated(trimws(units$UF)))
  units$sector <- domains$DOMAINE[match(de_key(units$CODE_DE), domains$CODE_DE)]
  unit <- match(trimws(as.character(raw$SEJUF)), trimws(units$UF))
  raw$sector <- units$sector[unit]
  clinical <- c("MÉDECINE", "CHIRURGIE", "RÉANIMATION", "PÉDIATRIE", "GYNÉCOLOGIE-OBSTÉTRIQUE",
                "SOINS MÉDICAUX ET DE RÉADAPTATION", "SOINS DE LONGUE DURÉE", "PSYCHIATRIE", "URGENCES")
  ta <- as.integer(units$CODE_TA[unit])
  raw$eligible <- ifelse(is.na(ta) | is.na(raw$sector), NA, ta %in% c(3L, 20L) & raw$sector %in% clinical)
  raw
}

prepare_rouen_pmsi_moves <- function(raw, workbook = "ref/rouen/establishment_structure_2025.xlsx") {
  # Apply the same Rouen source precedence as the denominator worked example.
  raw <- as.data.frame(redsan::prefer_pmsi_src_c_over_dw(raw))
  units <- as.data.frame(readxl::read_excel(workbook, sheet = "Fichier Structure", col_types = "text"))
  domains <- read.csv2("ref/consores/codes_de.csv", colClasses = "character", fileEncoding = "UTF-8")
  classify_rouen_movements(raw, units, domains)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args) %in% 2:3) stop("Usage: Rscript sector_returns.R PMSI_RDS YEAR [STRUCTURE_XLSX]")
  year <- as.integer(args[2L])
  stopifnot(!is.na(year))
  raw <- readRDS(args[1L])$main
  moves <- if (length(args) == 3L) prepare_rouen_pmsi_moves(raw, args[3L]) else prepare_rouen_pmsi_moves(raw)
  print(count_sector_returns(moves, year))
}
