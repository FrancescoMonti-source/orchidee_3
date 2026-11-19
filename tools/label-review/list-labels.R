# Label list for the mapping review (step 0, runs where the raw data is).
#
#   Rscript --vanilla tools/label-review/list-labels.R [raw_RDS [output_dir]]
#
# Reads the raw laboratory export and writes the laboratory's own vocabulary:
# one line per distinct organism label and per distinct antibiotic or test
# label. The review is about what a label means, not how often it occurs, so
# nothing is counted. What is written:
#   - the label;
#   - whether it ever carries an S, SFP, I, R or ZIT result;
#   - the sampling years it appears in;
#   - for an antibiotic label, the organism labels it is reported on.
# No number, no identifier, no sample text and no result value is written or
# printed. The identifier columns are not even read into the working table.
suppressPackageStartupMessages(library(data.table))

args <- commandArgs(trailingOnly = TRUE)
script <- sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])
root <- if (length(script)) {
  normalizePath(file.path(dirname(normalizePath(script)), "../.."), winslash = "/")
} else normalizePath(getwd(), winslash = "/")
input <- if (length(args) >= 1L) args[1L] else file.path(root, "data/bact22_24")
output <- if (length(args) >= 2L) args[2L] else file.path(root, "outputs/label-review")
dir.create(output, recursive = TRUE, showWarnings = FALSE)

YEARS <- 2022:2024
SIR <- c("S", "SFP", "I", "R", "ZIT")   # result alphabet of chapter 06, section 3
TOP_ORGANISMS <- 12L                    # organism labels listed per antibiotic label
blank_to_na <- function(x) {
  x <- trimws(as.character(x))
  x[!nzchar(x)] <- NA_character_
  x
}

raw <- as.data.table(readRDS(input))
raw_columns <- names(raw)
needed <- c("IDENTIFICATION", "LBLANA", "STRRES", "DATEPRELEV")
stopifnot(all(needed %in% raw_columns))
d <- raw[, ..needed]
rm(raw); invisible(gc())
d[, year := as.integer(format(as.Date(DATEPRELEV), "%Y"))]
d <- d[year %in% YEARS]
for (col in c("IDENTIFICATION", "LBLANA", "STRRES")) set(d, j = col, value = blank_to_na(d[[col]]))
d[, result := STRRES %chin% SIR]

label_list <- function(col) {
  out <- d[!is.na(get(col)), .(has_result = any(result), years = paste(sort(unique(year)), collapse = " ")),
           by = col]
  setnames(out, col, "source_label")
  setorder(out, source_label)
  out
}
organisms <- label_list("IDENTIFICATION")
antibiotics <- label_list("LBLANA")

# Organism labels each antibiotic label is reported on, most frequent first.
# The order is kept, the frequencies are not written.
pairs <- d[result == TRUE & !is.na(LBLANA) & !is.na(IDENTIFICATION), .N, by = .(LBLANA, IDENTIFICATION)]
setorder(pairs, LBLANA, -N, IDENTIFICATION)
reported <- pairs[, .(reported_on = paste(c(head(IDENTIFICATION, TOP_ORGANISMS), if (.N > TOP_ORGANISMS) "..."),
                                          collapse = " | ")), by = .(source_label = LBLANA)]
antibiotics[reported, reported_on := i.reported_on, on = "source_label"]

write_out <- function(x, name) fwrite(x, file.path(output, name), bom = TRUE, na = "")
write_out(organisms, "organism-labels.csv")
write_out(antibiotics, "antibiotic-labels.csv")
meta <- c(
  paste0("run_utc: ", format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
  paste0("input: ", basename(input)),
  paste0("raw columns: ", paste(raw_columns, collapse = ", ")),
  paste0("columns read: ", paste(needed, collapse = ", ")),
  paste0("sampling years kept: ", paste(range(YEARS), collapse = "-")),
  paste0("R: ", R.version.string, "; data.table: ", as.character(packageVersion("data.table")))
)
writeLines(meta, file.path(output, "labels-meta.txt"), useBytes = TRUE)
cat(meta, sep = "\n")
cat("\nWrote the label lists to ", normalizePath(output, winslash = "/"), "\n", sep = "")
