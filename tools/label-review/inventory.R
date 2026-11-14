# Label inventory for the mapping review (step 0, runs where the raw data is).
#
#   Rscript --vanilla tools/label-review/inventory.R [raw_RDS [output_dir [site_inputs_RDS]]]
#
# Reads the raw laboratory export and writes aggregate tables only: one line
# per distinct organism label and per distinct antibiotic/test label, with
# result-row counts and the organisms each antibiotic label is tested on.
# No patient, stay, sample or isolate identifier is written or printed.
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
blank_to_na <- function(x) {
  x <- trimws(as.character(x))
  x[!nzchar(x)] <- NA_character_
  x
}

message("Reading ", input, " (identifiers stay in memory).")
raw <- as.data.table(readRDS(input))
raw_columns <- names(raw)
needed <- c("PATID", "ELTID", "DLVL", "IDENTIFICATION", "LBLANA", "STRRES", "DATEPRELEV")
stopifnot(all(needed %in% raw_columns))
rows_raw <- nrow(raw)
sample_nature_col <- intersect(c("NATUREPVT", "naturepvt"), raw_columns)[1L]
keep <- c(needed, if (!is.na(sample_nature_col)) sample_nature_col)
d <- raw[, ..keep]
rm(raw); invisible(gc())
if (!is.na(sample_nature_col)) setnames(d, sample_nature_col, "nature") else d[, nature := NA_character_]
d[, year := as.integer(format(as.Date(DATEPRELEV), "%Y"))]
rows_by_year <- d[, .N, keyby = year]
d <- d[year %in% YEARS]
for (col in c("PATID", "ELTID", "DLVL", "IDENTIFICATION", "LBLANA", "STRRES", "nature")) {
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
top_values <- function(x, group, value, n = TOP_SPECIES) {
  tab <- x[!is.na(get(group)), .N, by = c(group, value)]
  tab[is.na(get(value)), (value) := "(missing)"]
  setorderv(tab, c(group, "N", value), c(1L, -1L, 1L))
  tab[, .(distinct = .N, top = paste0(head(get(value), n), " (", head(N, n), ")", collapse = " | ")),
      by = group]
}

antibiotics <- count_table(res, "LBLANA")
sp <- top_values(res, "LBLANA", "IDENTIFICATION")
antibiotics[sp, c("n_organism_labels", "tested_on") := .(i.distinct, i.top), on = .(source_label = LBLANA)]
# Labels of the same field that never carry an S/SFP/I/R/ZIT result: comments,
# technical fields, qualitative tests. Result values are shown only when short
# and frequent, so that no free-text comment leaves the machine.
other <- d[sir == FALSE & !is.na(LBLANA)]
other_labels <- other[, .(n_other_rows = .N), by = .(source_label = LBLANA)]
frequent <- other[!is.na(STRRES) & nchar(STRRES) <= 20L, .N, by = .(LBLANA, STRRES)][N >= 20L]
setorder(frequent, LBLANA, -N)
frequent <- frequent[, .(other_values = paste0(head(STRRES, 6L), " (", head(N, 6L), ")", collapse = " | ")),
                     by = .(source_label = LBLANA)]
other_labels[frequent, other_values := i.other_values, on = "source_label"]
antibiotics <- merge(antibiotics, other_labels, by = "source_label", all = TRUE)
for (col in setdiff(names(antibiotics), c("source_label", "tested_on", "other_values", if (!has_diag) "n_diag"))) {
  set(antibiotics, which(is.na(antibiotics[[col]])), col, 0L)
}
setorder(antibiotics, -n_results, -n_other_rows, source_label)

organisms <- count_table(res, "IDENTIFICATION")
nat <- top_values(res, "IDENTIFICATION", "nature", n = 4L)
organisms[nat, sample_natures := i.top, on = .(source_label = IDENTIFICATION)]
organisms[, c("n_S", "n_SFP", "n_I", "n_R", "n_ZIT") := NULL]
# Organism labels that never reach an antibiogram are listed apart, counts only.
no_ast <- d[!is.na(IDENTIFICATION) & !IDENTIFICATION %chin% organisms$source_label,
            .(n_rows_without_result = .N), by = .(source_label = IDENTIFICATION)]
setorder(no_ast, -n_rows_without_result, source_label)

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
  paste0("rows by sampling year: ", paste0(rows_by_year$year, "=", rows_by_year$N, collapse = ", ")),
  paste0("years kept: ", paste(range(YEARS), collapse = "-"), "; rows kept: ", nrow(d)),
  paste0("result alphabet: ", paste0(alphabet$result, "=", alphabet$N, collapse = ", ")),
  paste0("rows with S/SFP/I/R/ZIT: ", nrow(res), "; missing organism label among them: ",
         sum(is.na(res$IDENTIFICATION)), "; incomplete isolate key: ", sum(is.na(res$isolate))),
  paste0("distinct antibiotic/test labels with a result: ", sum(antibiotics$n_results > 0L)),
  paste0("distinct labels of the same field without any such result: ", sum(antibiotics$n_results == 0L)),
  paste0("distinct organism labels with a result: ", nrow(organisms)),
  paste0("distinct organism labels without any result: ", nrow(no_ast)),
  diag_note,
  if (!is.null(matched)) paste0("diagnostic join, year ", matched$year, ": result rows ", matched$result_rows,
                                ", with a flag ", matched$with_flag, ", diagnostic ", matched$diagnostic),
  if (!is.null(matched)) paste0("labels with a diagnostic result: antibiotic ",
                                sum(antibiotics$n_diag > 0L, na.rm = TRUE), ", organism ",
                                sum(organisms$n_diag > 0L, na.rm = TRUE)),
  paste0("R: ", R.version.string, "; data.table: ", as.character(packageVersion("data.table")))
)
writeLines(meta, file.path(output, "inventory-meta.txt"), useBytes = TRUE)
cat(meta, sep = "\n")
cat("\nWrote aggregate tables to ", normalizePath(output, winslash = "/"), "\n", sep = "")
