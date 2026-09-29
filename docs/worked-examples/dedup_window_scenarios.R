# Reproduction script for deduplication decisions 07.1 and 07.5.
# Run from the repository root, or set ORCHIDEE_V3_REPO_ROOT and ORCHIDEE_V3_RUN.
args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_file <- sub("^--file=", "", args[1L])
script_dir <- dirname(normalizePath(script_file, winslash = "/"))
source(file.path(script_dir, "deduplication_witness_helpers.R"))

annual_annexe3 <- deduplicate_witness(d, annexe3_ecoli, "annual")
annual_full <- deduplicate_witness(d, all_atb, "annual")
monthly_annexe3 <- deduplicate_witness(d, annexe3_ecoli, "monthly")
annual_zit_never_conflicts <- deduplicate_witness(d, annexe3_ecoli, "annual", zit_as_sfp = FALSE)

cat("Provisional v3 bundle:", bundle_dir, "\n")
cat("Slice: E. coli / urines / 2024;", nrow(d), "input isolates;", length(unique(d$PATID)), "patients\n")
cat("Annexe 3 list:", length(annexe3_ecoli), "molecules; supported panel:", length(all_atb), "columns\n\n")

report <- function(label, data) {
  cat(sprintf("%s: %d retained\n", label, nrow(data)))
  for (column in c("amoxicilline_acide_clavulanique", "ofloxacine", "cefotaxime", "trimethoprime_sulfamethoxazole")) {
    cat(sprintf("  %-34s %s\n", column, fmt_resistance(data, column)))
  }
}
report("Annual calendar, Annexe 3 list", annual_annexe3)
report("Annual calendar, full supported panel", annual_full)
report("Monthly calendar, pooled Annexe 3 list", monthly_annexe3)
report("Annual, ZIT never conflicts (alternative)", annual_zit_never_conflicts)

same_ids <- identical(sort(annual_annexe3$.witness_row), sort(annual_full$.witness_row))
cat("Full/Annexe 3 retained IDs identical:", same_ids, "\n")
if (!same_ids) stop("TW-07.1 parity changed: inspect the separating molecules")
cat("Annual-to-monthly count shift:", nrow(monthly_annexe3) - nrow(annual_annexe3),
    sprintf("(%+.2f%%)\n", 100 * (nrow(monthly_annexe3) - nrow(annual_annexe3)) / nrow(annual_annexe3)))
cat("AMC %R, selected / alternative:", fmt_resistance(annual_annexe3, "amoxicilline_acide_clavulanique"), "/",
    fmt_resistance(annual_zit_never_conflicts, "amoxicilline_acide_clavulanique"), "\n")
