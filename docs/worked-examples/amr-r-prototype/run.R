# THROWAWAY: map raw Rouen labels and calculate a small resistance table in R.
# Rscript --vanilla run.R [year [input_RDS [output_directory]]]
args <- commandArgs(trailingOnly = TRUE)
script <- sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])
here <- dirname(normalizePath(script, winslash = "/"))
root <- normalizePath(file.path(here, "../../.."), winslash = "/")
year <- if (length(args) >= 1L) as.integer(args[1L]) else 2024L
input <- if (length(args) >= 2L) args[2L] else file.path(root, "data/bact22_24")
output <- if (length(args) >= 3L) args[3L] else file.path(root, "outputs/amr-r-prototype")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
lib <- file.path(output, "R_libs")
dir.create(lib, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
if (!requireNamespace("AMR", quietly = TRUE) || as.character(packageVersion("AMR")) != "3.1.0") {
  install.packages("https://cloud.r-project.org/src/contrib/AMR_3.1.0.tar.gz",
                  lib = lib, repos = NULL, type = "source")
}
helpers <- c("data.table", "jsonlite", "digest")
missing <- helpers[!vapply(helpers, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, lib = lib, repos = "https://cloud.r-project.org")
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(AMR))
stopifnot(as.character(packageVersion("AMR")) == "3.1.0")

message("Reading raw RDS locally; only aggregates and mapping labels will be written.")
raw <- as.data.table(readRDS(input))
in_year <- !is.na(raw$DATEPRELEV) & raw$DATEPRELEV >= as.Date(paste0(year, "-01-01")) &
  raw$DATEPRELEV < as.Date(paste0(year + 1L, "-01-01"))
rows_raw <- nrow(raw)
rows_year <- sum(in_year)
data <- raw[in_year & STRRES %chin% c("S", "SFP", "I", "R", "ZIT"),
            .(PATID, ELTID, DLVL, IDENTIFICATION, LBLANA, STRRES)]
setnames(data, c("patient", "sample", "isolate", "organism", "analysis", "result"))
data[, names(data) := lapply(.SD, function(x) {
  x <- as.character(x)
  x[x == ""] <- NA_character_
  x
})]
rm(raw)
invisible(gc())
message("Loaded ", nrow(data), " result rows in ", year, ".")

# Every distinct non-missing label in this population; no manual list or cutoff.
organisms <- data[!is.na(organism), .(result_rows = .N), by = .(local_label = organism)]
setorder(organisms, -result_rows, local_label)
message("Mapping all ", nrow(organisms), " distinct organism labels with AMR::as.mo().")
organisms[, amr_code := as.character(as.mo(local_label, language = "en", info = FALSE))]
uncertainties <- mo_uncertainties()
uncertain_inputs <- uncertainties$original_input
organisms[amr_code == "UNKNOWN", amr_code := NA_character_]
organisms[, amr_name := mo_name(amr_code, language = "en")]
organisms[, status := fifelse(is.na(amr_code), "unmapped",
                             fifelse(local_label %chin% uncertain_inputs, "uncertain", "recognised"))]

analyses <- data[!is.na(analysis), .(result_rows = .N), by = .(local_label = analysis)]
setorder(analyses, -result_rows, local_label)
message("Mapping all ", nrow(analyses), " distinct result labels with AMR::as.ab().")
analyses[, amr_code := as.character(as.ab(local_label, language = "fr", info = FALSE))]
analyses[, amr_name := ab_name(amr_code, language = "en")]
site_map <- fread(file.path(root, "ref/rouen/atb_regex_map.csv"), header = TRUE, encoding = "UTF-8")
analyses[, site_mapping := vapply(local_label, function(label) {
  matches <- which(vapply(site_map$pattern, grepl, logical(1), x = label, perl = TRUE))
  if (length(matches)) site_map$atb_norm[matches[1L]] else NA_character_
}, character(1))]

# The resistance table is deliberately selected, unlike the mapping inventory.
table_drugs <- c(cefotaxime = "CTX", ceftazidime = "CAZ", ciprofloxacine = "CIP",
                 ertapeneme = "ETP", gentamicine = "GEN", piperacilline_tazobactam = "TZP",
                 vancomycine = "VAN")
table_labels <- c("CEFOTAXIME", "CEFTAZIDIME", "CIPROFLOXACINE", "ERTAPENEME",
                  "GENTAMICINE", "PIPERACILLINE+TAZOBACTAM", "VANCOMYCINE")
# GENTAMICINE FORTE remains outside, even though both mappings call it GEN.
analyses[, used_in_table := local_label %chin% table_labels & !is.na(amr_code) &
           !is.na(table_drugs[site_mapping]) & table_drugs[site_mapping] == amr_code]
table_pairs <- list(
  "Escherichia coli" = c("CTX", "CAZ", "CIP", "ETP", "GEN", "TZP"),
  "Klebsiella pneumoniae" = c("CTX", "CAZ", "CIP", "ETP", "GEN", "TZP"),
  "Pseudomonas aeruginosa" = c("CAZ", "CIP", "GEN", "TZP"),
  "Staphylococcus aureus" = c("GEN", "VAN"), "Enterococcus faecium" = "VAN"
)
confirmed_species <- organisms[status == "recognised" & local_label == amr_name &
                                local_label %chin% names(table_pairs), local_label]

keys <- c("patient", "sample", "isolate")
complete_keys <- complete.cases(data[, ..keys])
identified <- data[complete_keys & !is.na(organism)]
identity_counts <- identified[, .(identities = uniqueN(organism)), by = keys]
conflicting_keys <- identity_counts[identities > 1L, ..keys]
clean <- identified[!conflicting_keys, on = keys]
selected <- clean[organism %chin% confirmed_species]
total_isolates <- unique(selected[, c(keys, "organism"), with = FALSE])[
  , .(total_isolates = .N), by = organism]
drug_map <- analyses[used_in_table == TRUE, .(analysis = local_label, amr_code)]
selected <- merge(selected, drug_map, by = "analysis", sort = FALSE)
allowed_pairs <- data.table(organism = rep(names(table_pairs), lengths(table_pairs)),
                            amr_code = unlist(table_pairs, use.names = FALSE))
outside_trial_pairs <- nrow(selected[!allowed_pairs, on = .(organism, amr_code)])
selected <- selected[allowed_pairs, on = .(organism, amr_code), nomatch = 0L]
# Preserve the declared local SFP/I/ZIT choice; do not reinterpret measurements.
selected[, sir := fifelse(result %chin% c("SFP", "ZIT"), "I", result)]
cells <- c(keys, "organism", "amr_code")
cell_counts <- selected[, .(results = uniqueN(sir)), by = cells]
conflicting_cells <- cell_counts[results > 1L, ..cells]
unambiguous <- selected[!conflicting_cells, on = cells]
identical_repeats <- nrow(unambiguous) - uniqueN(unambiguous, by = cells)
unambiguous <- unique(unambiguous, by = cells)

table <- list()
for (species in confirmed_species) {
  for (code in table_pairs[[species]]) {
    results <- unambiguous[organism == species & amr_code == code, sir]
    n <- if (length(results)) count_R(results) else 0L
    tested <- if (length(results)) count_all(results) else 0L
    rate <- if (length(results)) resistance(results, minimum = 0, guideline = "EUCAST") else NA_real_
    if (length(results)) {
      stopifnot(n == sum(results == "R"), tested == length(results), isTRUE(all.equal(rate, n / tested)))
    }
    table[[length(table) + 1L]] <- data.table(
      organism = species, antibiotic = code, resistant = n, tested = tested,
      total_isolates = total_isolates[organism == species, total_isolates], resistance_pct = 100 * rate
    )
  }
}
table <- rbindlist(table)

# Exercise an explicit site reference without adopting it in the table/dictionary.
complex_label <- "Enterobacter complexe cloacae"
complex_code <- as.character(as.mo("Enterobacter cloacae complex", info = FALSE))
mo_reset_session()
reference <- data.frame(local = complex_label, mo = complex_code)
configured <- as.mo(complex_label, reference_df = reference, info = FALSE)
custom_mapping_trial <- list(
  local_label = complex_label, default_suggestion = organisms[local_label == complex_label, amr_name],
  configured_code = as.character(configured), configured_name = mo_name(configured, language = "en"),
  status = "Proposed explicit site reference; demonstrated, not applied to the table."
)
status_rows <- organisms[, .(result_rows = sum(result_rows)), by = status]
metadata <- list(
  question = "Can AMR for R map Rouen labels and calculate a transparent resistance table?",
  run_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"), year = year,
  input_name = basename(input), input_sha256 = digest::digest(file = input, algo = "sha256"),
  versions = as.list(c(AMR = as.character(packageVersion("AMR")), R = R.version.string,
                      data.table = as.character(packageVersion("data.table")),
                      jsonlite = as.character(packageVersion("jsonlite")), digest = as.character(packageVersion("digest")))),
  runtime = "Direct R; no Python wrapper or dependency patch.",
  population = "All raw sample types, including possible screening; no hospital perimeter selection; no surveillance deduplication.",
  organism_label_selection = "Every distinct non-missing organism label in the selected year with S/SFP/I/R/ZIT results; no manual list or frequency cutoff.",
  organism_labels = nrow(organisms),
  result_mapping = "S -> S; R -> R; SFP/I/ZIT -> I; EUCAST counts I on the susceptible side. No MIC reinterpretation.",
  rows_raw = rows_raw, rows_year = rows_year, result_rows = nrow(data),
  missing_key_rows = sum(!complete_keys), missing_organism_rows = sum(is.na(data$organism)),
  identity_conflicts = nrow(conflicting_keys), conflicting_result_cells = nrow(conflicting_cells),
  identical_repeated_rows_collapsed = identical_repeats,
  result_alphabet = as.list(sort(base::table(data$result), decreasing = TRUE)),
  organism_statuses = as.list(sort(base::table(organisms$status), decreasing = TRUE)),
  organism_result_rows_by_status = setNames(as.list(status_rows$result_rows), status_rows$status),
  analysis_labels = nrow(analyses), analysis_labels_used_in_table = sum(analyses$used_in_table),
  table_isolates = sum(total_isolates$total_isolates), table_tested_cells = nrow(unambiguous),
  arithmetic_agrees = TRUE, outside_selected_trial_pairs_rows = outside_trial_pairs,
  trial_pairs = lapply(table_pairs, as.list), custom_mapping_trial = custom_mapping_trial
)
# Identifiers remain in memory. The payload contains only aggregate tables/labels.
payload <- list(metadata = metadata, organisms = as.data.frame(organisms),
                analyses = as.data.frame(analyses), table = as.data.frame(table))
encoded <- jsonlite::toJSON(payload, auto_unbox = TRUE, na = "null", null = "null", digits = NA, pretty = TRUE)
writeLines(encoded, file.path(output, "summary.json"), useBytes = TRUE)
write.csv(organisms, file.path(output, "organism-mapping.csv"), row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.csv(analyses, file.path(output, "antibiotic-mapping.csv"), row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.csv(table, file.path(output, "resistance-table.csv"), row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.csv(uncertainties, file.path(output, "organism-uncertainties.csv"), row.names = FALSE, na = "", fileEncoding = "UTF-8")
template <- paste(readLines(file.path(here, "demo.template.html"), encoding = "UTF-8"), collapse = "\n")
encoded_html <- gsub("<", "\\u003c", encoded, fixed = TRUE)
parts <- strsplit(template, "/*PROTOTYPE_DATA*/null", fixed = TRUE)[[1L]]
writeLines(paste0(parts[1L], encoded_html, parts[2L]), file.path(output, "demo.html"), useBytes = TRUE)
print(table)
message("Open ", normalizePath(file.path(output, "demo.html"), winslash = "/"))
