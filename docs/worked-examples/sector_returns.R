# Exploratory count of observed returns to a clinical sector within one stay.
# From the repository root, using the protected Rouen PMSI RDS ($main):
# Rscript docs/worked-examples/sector_returns.R data/pmsi 2024
# Optional third argument: path to the UF structure workbook for the cohort.
# Requires redsan and readxl for the Rouen input. The default workbook is the
# Rouen snapshot used in the other 2024 worked examples. Verify its applicability.
# The cohort year is the year of the first observed movement. Supply whole stays,
# including movements across calendar boundaries. Only aggregate counts are printed.

count_sector_returns <- function(moves, year) {
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

  # A gap alone cannot establish a return. A different observed sector must
  # intervene. Keep out-of-perimeter movements when reconstructing the path.
  paths <- list()
  pending_year <- uncertain <- outside <- 0L
  for (pos in by_stay) {
    s <- d[pos, ]
    if (anyNA(s$DATENT)) {
      pending_year <- pending_year + 1L
      next
    }
    if (as.integer(format(s$DATENT[1L], "%Y", tz = "Europe/Paris")) != year) next
    starts <- as.numeric(s$DATENT)
    ends <- as.numeric(s$DATSORT)
    # An open final movement can confirm an observed entry. A missing earlier
    # end or overlapping different sectors makes the sequence uncertain.
    if (anyNA(s$sector) || any(!nzchar(s$sector)) || anyNA(s$eligible) ||
        anyNA(head(ends, -1L)) || any(ends <= starts, na.rm = TRUE)) {
      uncertain <- uncertain + 1L
      next
    }
    change <- s$sector[-1L] != head(s$sector, -1L)
    if (any(change & starts[-1L] < cummax(head(ends, -1L)))) {
      uncertain <- uncertain + 1L
      next
    }
    if (!any(s$eligible)) {
      outside <- outside + 1L
      next
    }
    # Adjacent units of the same sector form one visit. Count an observed
    # sector visit if at least one movement in it is eligible.
    visit <- cumsum(c(TRUE, change))
    entries <- unique(data.frame(visit, sector = s$sector)[s$eligible, ])
    counts <- table(entries$sector)
    paths[[length(paths) + 1L]] <- data.frame(
      patient = as.character(s$PATID[1L]), stay = s$stay[1L],
      sector = names(counts), entries = as.integer(counts))
  }
  all <- if (length(paths)) do.call(rbind, paths) else
    data.frame(patient = character(), stay = integer(), sector = character(), entries = integer())
  summarise <- function(rows) {
    repeated <- rows$entries > 1L
    data.frame(patients = length(unique(rows$patient)),
               patients_with_return = length(unique(rows$patient[repeated])),
               stays = length(unique(rows$stay)),
               stays_with_return = length(unique(rows$stay[repeated])),
               extra_entries = sum(rows$entries - 1L))
  }
  list(year = year, rows_without_patient_or_stay = unkeyed_rows,
       stays_with_uncertain_cohort_year = pending_year,
       cohort_stays_with_uncertain_path = uncertain,
       cohort_stays_without_eligible_sector = outside,
       any_sector = summarise(all),
       by_sector = lapply(split(all, all$sector), summarise))
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

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args) %in% 2:3) stop("Usage: Rscript sector_returns.R PMSI_RDS YEAR [STRUCTURE_XLSX]")
  year <- as.integer(args[2L])
  stopifnot(!is.na(year))
  workbook <- if (length(args) == 3L) args[3L] else "ref/rouen/establishment_structure_2025.xlsx"
  raw <- readRDS(args[1L])$main
  # Apply the same Rouen source precedence as the denominator worked example.
  raw <- as.data.frame(redsan::prefer_pmsi_src_c_over_dw(raw))
  units <- as.data.frame(readxl::read_excel(workbook, sheet = "Fichier Structure", col_types = "text"))
  domains <- read.csv2("ref/consores/codes_de.csv", colClasses = "character", fileEncoding = "UTF-8")
  print(count_sector_returns(classify_rouen_movements(raw, units, domains), year))
}
