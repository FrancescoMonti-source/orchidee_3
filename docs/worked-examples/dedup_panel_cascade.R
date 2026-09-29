# Reproduction script for deduplication decisions 07.1 and 07.5.
# Run from the repository root, or set ORCHIDEE_V3_REPO_ROOT and ORCHIDEE_V3_RUN.
args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_file <- sub("^--file=", "", args[1L])
script_dir <- dirname(normalizePath(script_file, winslash = "/"))
source(file.path(script_dir, "deduplication_witness_helpers.R"))

full <- deduplicate_witness(d, annexe3_ecoli, "annual")
full_site <- deduplicate_witness(d, all_atb, "annual")
cat("Provisional v3 bundle:", bundle_dir, "\n")
cat("Slice: E. coli / urines / 2024;", nrow(d), "input isolates\n")
same_ids <- identical(sort(full$.witness_row), sort(full_site$.witness_row))
cat("Full supported panel and Annexe 3 list retain identical IDs:", same_ids, "\n")
if (!same_ids) stop("TW-07.1 parity changed: inspect the separating molecules")
cat("\n")

report <- function(label, data) {
  cat(sprintf("%-36s %5d | OFX %s | SXT %s\n", label, nrow(data),
              fmt_resistance(data, "ofloxacine"), fmt_resistance(data, "trimethoprime_sulfamethoxazole")))
}
cat("Panel cascade (same annual window and phenotype-aware 07.6 rule):\n")
report("Full Annexe 3 list (19)", full)
for (drop in c("amoxicilline_acide_clavulanique", "amoxicilline_ampicilline",
               "mecillinam", "nitrofurantoine", "fosfomycine_iv")) {
  report(paste("minus", drop), deduplicate_witness(d, setdiff(annexe3_ecoli, drop), "annual"))
}
