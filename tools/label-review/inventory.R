# Label inventory for the mapping review (step 0, runs where the raw data is).
#
#   Rscript --vanilla tools/label-review/inventory.R [raw_RDS [output_dir [site_inputs_RDS]]]
#
# Reads the raw laboratory export and writes aggregate tables only: one line
# per distinct organism label and per distinct antibiotic/test label, with
# result-row counts and the organisms each antibiotic label is tested on.
#
# What is written is masked by construction, so that the tables can be read
# outside the hospital machine:
#   - no patient, stay, sample or isolate identifier is written or printed;
#   - a count of 1 to 9 is written "<10";
#   - a label carried by fewer than 10 patients keeps its total, and its splits
#     (by year, by result, diagnostic) are written "masked";
#   - when one cell of a split is masked, the smallest other cell is rounded to
#     the nearest ten ("~120"), so that subtraction does not give it back;
#   - free text never leaves: sample natures are not written, and a result
#     value is listed only when it is short, frequent and shared by 10 patients
#     or more, and looks neither like a number nor like initials.
#
# The optional third argument is a site-inputs table that carries the local
# diagnostic classification (`ratb_diagnostic_scope`). When given, each label
# also gets its count inside the diagnostic population. This script does not
# classify samples itself: that is the site adapter's job (ADR-0003).
suppressPackageStartupMessages(library(data.table))

args <- commandArgs(trailingOnly = TRUE)
script <- sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])
root <- if (length(script)) {
  normalizePath(file.path(dirname(normalizePath(script)), "../.."), winslash = "/")
} else normalizePath(getwd(), winslash = "/")
input <- if (length(args) >= 1L) args[1L] else file.path(root, "data/bact22_24")
output <- if (length(args) >= 2L) args[2L] else file.path(root, "outputs/label-review")
site_inputs <- if (length(args) >= 3L) args[3L] else NA_character_
dir.create(output, recursive = TRUE, showWarnings = FALSE)

YEARS <- 2022:2024
SIR <- c("S", "SFP", "I", "R", "ZIT")   # result alphabet of chapter 06, section 3
TOP_SPECIES <- 12L                      # organisms listed per antibiotic label
SMALL <- 10L                            # counts and patient numbers below this are masked
VALUE_MIN_ROWS <- 20L                   # a result value is listed from this many rows
VALUE_MAX_CHARS <- 20L
RESULT_CODES <- c("POS", "NEG", "NDM", "VIM", "KPC", "IMP", "OXA")   # short codes that are not initials
blank_to_na <- function(x) {
  x <- trimws(as.character(x))
  x[!nzchar(x)] <- NA_character_
  x
}

below <- paste0("<", SMALL)
mask <- function(n) fifelse(is.na(n), NA_character_, fifelse(n > 0L & n < SMALL, below, as.character(n)))
# A split of a total that is shown. One masked cell alone could be recovered by
# subtraction, so the smallest other cell is then rounded to the nearest ten.
mask_split <- function(n) {
  out <- mask(n)
  small <- which(n > 0L & n < SMALL)
  if (length(small) == 1L) {
    others <- setdiff(which(n > 0L), small)
    if (length(others)) {
      j <- others[which.min(n[others])]
      out[j] <- paste0("~", as.integer(round(n[j], -1L)))
    }
  }
  out
}
# Masks the columns `cols` of `x` as one split per line; "masked" where `hide`.
mask_columns <- function(x, cols, hide) {
  values <- t(apply(as.matrix(x[, ..cols]), 1L, mask_split))
  for (k in seq_along(cols)) set(x, j = cols[k], value = fifelse(hide, "masked", values[, k]))
}

message("Reading ", input, " (identifiers stay in memory).")
raw <- as.data.table(readRDS(input))
raw_columns <- names(raw)
needed <- c("PATID", "ELTID", "DLVL", "IDENTIFICATION", "LBLANA", "STRRES", "DATEPRELEV")
stopifnot(all(needed %in% raw_columns))
rows_raw <- nrow(raw)
d <- raw[, ..needed]
rm(raw); invisible(gc())
d[, year := as.integer(format(as.Date(DATEPRELEV), "%Y"))]
rows_by_year <- d[, .N, keyby = year]
d <- d[year %in% YEARS]
for (col in c("PATID", "ELTID", "DLVL", "IDENTIFICATION", "LBLANA", "STRRES")) {
  set(d, j = col, value = blank_to_na(d[[col]]))
}
d[, sir := STRRES %chin% SIR]

# Diagnostic flag, from the site's own classification when a file is supplied.
diag_note <- "No site-inputs file supplied: n_diag columns are empty."
d[, diag := NA]
if (!is.na(site_inputs) && file.exists(site_inputs)) {
  si <- as.data.table(readRDS(site_inputs))
  stopifnot(all(c("PATID", "ELTID", "ratb_diagnostic_scope") %in% names(si)))
  flags <- si[, .(diag = any(ratb_diagnostic_scope %in% TRUE)),
              by = .(PATID = blank_to_na(PATID), ELTID = blank_to_na(ELTID))]
  rm(si); invisible(gc())
  d[flags, diag := i.diag, on = .(PATID, ELTID)]
  matched <- d[sir == TRUE, .(result_rows = .N, with_flag = sum(!is.na(diag)),
                              diagnostic = sum(diag %in% TRUE)), keyby = year]
  diag_note <- paste0("Diagnostic flag from ", basename(dirname(dirname(site_inputs))), "/",
                      basename(dirname(site_inputs)), "/", basename(site_inputs),
                      ", joined on (PATID, ELTID); a sample is diagnostic when any of its rows is.")
} else matched <- NULL

has_diag <- !all(is.na(d$diag))
d[, diag := if (has_diag) diag %in% TRUE else NA]
res <- d[sir == TRUE]
res[, isolate := fifelse(is.na(PATID) | is.na(ELTID) | is.na(DLVL), NA_character_,
                         paste(PATID, ELTID, DLVL, sep = "\034"))]
count_table <- function(x, by) {
  out <- x[!is.na(get(by)), .(
    patients = uniqueN(PATID, na.rm = TRUE),
    n_results = .N, n_isolates = uniqueN(isolate, na.rm = TRUE),
    n_diag = if (has_diag) sum(diag) else NA_integer_,
    n_2022 = sum(year == 2022L), n_2023 = sum(year == 2023L), n_2024 = sum(year == 2024L),
    n_S = sum(STRRES == "S"), n_SFP = sum(STRRES == "SFP"), n_I = sum(STRRES == "I"),
    n_R = sum(STRRES == "R"), n_ZIT = sum(STRRES == "ZIT")
  ), by = by]
  setnames(out, by, "source_label")
  setorder(out, -n_results, source_label)
  out
}
# Masks a count table in place. Totals keep their value from SMALL upwards;
# splits are hidden for a label carried by fewer than SMALL patients.
mask_table <- function(x, splits) {
  rare <- !is.na(x$patients) & x$patients < SMALL
  if (has_diag) {
    outside <- x$n_results - x$n_diag   # not written, but total minus diagnostic gives it
    diag <- fifelse(outside > 0L & outside < SMALL & x$n_diag >= SMALL,
                    paste0("~", as.integer(round(x$n_diag, -1L))), mask(x$n_diag))
    set(x, j = "n_diag", value = fifelse(rare, "masked", diag))
  } else set(x, j = "n_diag", value = NA_character_)
  for (cols in splits) mask_columns(x, cols, rare)
  for (col in c("n_results", "n_isolates")) set(x, j = col, value = mask(x[[col]]))
  set(x, j = "patients", value = fifelse(is.na(x$patients), NA_character_,
                                         fifelse(rare, below, paste0(">=", SMALL))))
  invisible(x)
}
YEAR_SPLIT <- c("n_2022", "n_2023", "n_2024")
SIR_SPLIT <- c("n_S", "n_SFP", "n_I", "n_R", "n_ZIT")

# Organisms each antibiotic label is tested on, with masked counts.
tested_on <- function(x, n = TOP_SPECIES) {
  tab <- x[!is.na(LBLANA), .N, by = .(LBLANA, IDENTIFICATION)]
  tab[is.na(IDENTIFICATION), IDENTIFICATION := "(missing)"]
  setorder(tab, LBLANA, -N, IDENTIFICATION)
  tab[, .(distinct = .N, top = {
    shown <- head(N, n)
    counts <- if (.N <= n) mask_split(shown) else mask(shown)   # a complete list is a split
    paste0(head(IDENTIFICATION, n), " (", counts, ")", collapse = " | ")
  }), by = LBLANA]
}

antibiotics <- count_table(res, "LBLANA")
sp <- tested_on(res)
antibiotics[sp, c("n_organism_labels", "tested_on") := .(i.distinct, i.top), on = .(source_label = LBLANA)]
# Labels of the same field that never carry an S/SFP/I/R/ZIT result: comments,
# technical fields, qualitative tests. Their result values are free text. A
# value is listed only when it is short, frequent, shared by SMALL patients or
# more, has no long number (possible identifier) and is not a two- or
# three-letter code outside RESULT_CODES (possible initials). The others are
# counted, not shown.
other <- d[sir == FALSE & !is.na(LBLANA)]
other_labels <- other[, .(n_other_rows = .N, patients_other = uniqueN(PATID, na.rm = TRUE)),
                      by = .(source_label = LBLANA)]
frequent <- other[!is.na(STRRES), .(N = .N, patients = uniqueN(PATID, na.rm = TRUE)),
                  by = .(LBLANA, STRRES)][N >= VALUE_MIN_ROWS]
frequent[, listed := patients >= SMALL & nchar(STRRES) <= VALUE_MAX_CHARS & !grepl("[0-9]{4,}", STRRES) &
           !(grepl("^[[:alpha:]]{2,3}$", STRRES) & !toupper(STRRES) %chin% RESULT_CODES)]
setorder(frequent, LBLANA, -N, STRRES)
frequent <- frequent[, .(other_values = {
  shown <- head(which(listed), 6L)
  parts <- c(if (length(shown)) paste0(STRRES[shown], " (", N[shown], ")"),
             if (any(!listed)) paste0("(", sum(!listed), " value(s) withheld)"))
  paste(parts, collapse = " | ")
}), by = .(source_label = LBLANA)]
other_labels[frequent, other_values := i.other_values, on = "source_label"]
antibiotics <- merge(antibiotics, other_labels, by = "source_label", all = TRUE)
for (col in c("n_results", "n_isolates", YEAR_SPLIT, SIR_SPLIT, "n_organism_labels", "n_other_rows",
              if (has_diag) "n_diag")) {
  set(antibiotics, which(is.na(antibiotics[[col]])), col, 0L)
}
setorder(antibiotics, -n_results, -n_other_rows, source_label)
labels_with_result <- sum(antibiotics$n_results > 0L)
antibiotics_diag <- sum(antibiotics$n_diag > 0L, na.rm = TRUE)
antibiotics[is.na(patients), patients := patients_other]
antibiotics[, patients_other := NULL]
mask_table(antibiotics, list(YEAR_SPLIT, SIR_SPLIT))
set(antibiotics, j = "n_other_rows", value = mask(antibiotics$n_other_rows))

organisms <- count_table(res, "IDENTIFICATION")
organisms[, (SIR_SPLIT) := NULL]
organisms_diag <- sum(organisms$n_diag > 0L, na.rm = TRUE)
# Organism labels that never reach an antibiogram are listed apart, counts only.
no_ast <- d[!is.na(IDENTIFICATION) & !IDENTIFICATION %chin% organisms$source_label,
            .(patients = uniqueN(PATID, na.rm = TRUE), n_rows_without_result = .N),
            by = .(source_label = IDENTIFICATION)]
setorder(no_ast, -n_rows_without_result, source_label)
set(no_ast, j = "n_rows_without_result", value = mask(no_ast$n_rows_without_result))
set(no_ast, j = "patients", value = fifelse(no_ast$patients < SMALL, below, paste0(">=", SMALL)))
mask_table(organisms, list(YEAR_SPLIT))

alphabet <- d[, .N, by = .(result = fifelse(sir, STRRES, fifelse(is.na(STRRES), "(missing)", "(other value)")))]
setorder(alphabet, -N)

write_out <- function(x, name) fwrite(x, file.path(output, name), bom = TRUE, na = "")
write_out(antibiotics, "antibiotic-labels.csv")
write_out(organisms, "organism-labels.csv")
write_out(no_ast, "organism-labels-without-result.csv")
meta <- c(
  paste0("run_utc: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
  paste0("input: ", basename(input), "; rows: ", rows_raw),
  paste0("raw columns: ", paste(raw_columns, collapse = ", ")),
  paste0("rows by sampling year: ", paste0(rows_by_year$year, "=", mask(rows_by_year$N), collapse = ", ")),
  paste0("years kept: ", paste(range(YEARS), collapse = "-"), "; rows kept: ", nrow(d)),
  paste0("result alphabet: ", paste0(alphabet$result, "=", mask(alphabet$N), collapse = ", ")),
  paste0("rows with S/SFP/I/R/ZIT: ", nrow(res), "; missing organism label among them: ",
         mask(sum(is.na(res$IDENTIFICATION))), "; incomplete isolate key: ", mask(sum(is.na(res$isolate)))),
  paste0("distinct antibiotic/test labels with a result: ", labels_with_result),
  paste0("distinct labels of the same field without any such result: ", nrow(antibiotics) - labels_with_result),
  paste0("distinct organism labels with a result: ", nrow(organisms)),
  paste0("distinct organism labels without any result: ", nrow(no_ast)),
  diag_note,
  if (!is.null(matched)) paste0("diagnostic join, year ", matched$year, ": result rows ", mask(matched$result_rows),
                                ", with a flag ", mask(matched$with_flag), ", diagnostic ", mask(matched$diagnostic)),
  if (!is.null(matched)) paste0("labels with a diagnostic result: antibiotic ", antibiotics_diag,
                                ", organism ", organisms_diag),
  paste0("masking: counts of 1 to ", SMALL - 1L, " are written \"", below, "\"; a label carried by fewer than ", SMALL,
         " patients shows \"masked\" for its splits; \"~\" marks a count rounded to the nearest ten; ",
         "sample natures and free-text values are not written."),
  paste0("R: ", R.version.string, "; data.table: ", as.character(packageVersion("data.table")))
)
writeLines(meta, file.path(output, "inventory-meta.txt"), useBytes = TRUE)
cat(meta, sep = "\n")
cat("\nWrote aggregate tables to ", normalizePath(output, winslash = "/"), "\n", sep = "")
