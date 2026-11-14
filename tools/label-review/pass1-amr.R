# Pass 1 of the mapping review: what AMR suggests for every source label.
#
#   Rscript --vanilla tools/label-review/pass1-amr.R [inventory_dir]
#
# Reads the aggregate tables written by inventory.R and adds AMR's suggestion
# to each line. A suggestion is recognition, not approval: nothing here is a
# mapping. Needs AMR 3.1.0 exactly, so that the suggestion column can be
# reproduced. Reads no patient data.
suppressPackageStartupMessages({library(data.table); library(AMR)})
stopifnot(as.character(packageVersion("AMR")) == "3.1.0")

args <- commandArgs(trailingOnly = TRUE)
script <- sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])
root <- normalizePath(file.path(dirname(normalizePath(script)), "../.."), winslash = "/")
dir <- if (length(args) >= 1L) args[1L] else file.path(root, "outputs/label-review")
read_in <- function(name) fread(file.path(dir, name), encoding = "UTF-8", na.strings = "")
write_out <- function(x, name) fwrite(x, file.path(dir, name), bom = TRUE, na = "")

# Organisms: the call of the accepted prototype (prototype/amr-demo-ergonomics, run.R).
organisms <- read_in("organism-labels.csv")
organisms[, amr_code := as.character(as.mo(source_label, language = "en", info = FALSE))]
uncertain <- mo_uncertainties()
organisms[amr_code == "UNKNOWN", amr_code := NA_character_]
organisms[, amr_status := fifelse(is.na(amr_code), "unmapped",
                                  fifelse(source_label %chin% uncertain$original_input, "uncertain", "recognised"))]
mapped <- which(!is.na(organisms$amr_code))
properties <- c(amr_name = "mo_name", amr_rank = "mo_rank", amr_gram = "mo_gramstain",
                amr_order = "mo_order", amr_family = "mo_family", amr_genus = "mo_genus")
for (field in names(properties)) {
  organisms[, (field) := NA_character_]
  values <- getExportedValue("AMR", properties[[field]])(organisms$amr_code[mapped], language = "en")
  values[!nzchar(values)] <- NA_character_
  set(organisms, i = mapped, j = field, value = values)
}
organisms[, amr_group := vapply(amr_code, function(code) {
  groups <- unique(AMR::microorganisms.groups$mo_group_name[
    !is.na(code) & AMR::microorganisms.groups$mo == code])
  if (length(groups)) paste(groups, collapse = " | ") else NA_character_
}, character(1))]
write_out(organisms, "organism-pass1.csv")

# Antibiotic and test labels: the prototype's call, plus the legacy v2 dictionary
# as a second comparator (first matching pattern wins, as in v2).
antibiotics <- read_in("antibiotic-labels.csv")
antibiotics[, amr_code := as.character(as.ab(source_label, language = "fr", info = FALSE))]
antibiotics[, amr_name := ab_name(amr_code, language = "en")]
antibiotics[, amr_group := ab_group(amr_code, language = "en")]
legacy <- fread(file.path(root, "ref/rouen/atb_regex_map.csv"), header = TRUE, encoding = "UTF-8",
                na.strings = NULL)
antibiotics[, legacy_v2 := vapply(source_label, function(label) {
  hit <- which(vapply(legacy$pattern, grepl, logical(1), x = label, perl = TRUE))
  if (length(hit)) legacy$atb_norm[hit[1L]] else NA_character_
}, character(1))]
write_out(antibiotics, "antibiotic-pass1.csv")

cat("Organism labels: ", nrow(organisms), " (", paste0(names(table(organisms$amr_status)), " ",
    table(organisms$amr_status), collapse = ", "), ")\n", sep = "")
cat("Antibiotic/test labels: ", nrow(antibiotics), " (", sum(is.na(antibiotics$amr_code)),
    " without an AMR suggestion)\n", sep = "")
