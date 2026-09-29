# Reproduction script for deduplication decisions 07.1 and 07.5.
# Run from the repository root, or set ORCHIDEE_V3_REPO_ROOT and ORCHIDEE_V3_RUN.
args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_file <- sub("^--file=", "", args[1L])
script_dir <- dirname(normalizePath(script_file, winslash = "/"))
source(file.path(script_dir, "deduplication_witness_helpers.R"))

annual_comparison <- deduplicate_witness(d, comparison_panel, "annual")
annual_full <- deduplicate_witness(d, all_atb, "annual")
monthly_comparison <- deduplicate_witness(d, comparison_panel, "monthly")
annual_zit_never_conflicts <- deduplicate_witness(d, comparison_panel, "annual", zit_as_sfp = FALSE)

cat("Provisional v3 bundle:", bundle_dir, "\n")
cat("Slice: E. coli / urines / 2024;", nrow(d), "input isolates;", length(unique(d$PATID)), "patients\n")
cat("comparison panel:", length(comparison_panel), "molecules; supported panel:", length(all_atb), "columns\n\n")

report <- function(label, data) {
  cat(sprintf("%s: %d retained\n", label, nrow(data)))
  for (column in c("amoxicilline_acide_clavulanique", "ofloxacine", "cefotaxime", "trimethoprime_sulfamethoxazole")) {
    cat(sprintf("  %-34s %s\n", column, fmt_resistance(data, column)))
  }
}
report("Annual calendar, comparison panel", annual_comparison)
report("Annual calendar, full supported panel", annual_full)
report("Monthly calendar, pooled comparison panel", monthly_comparison)
report("Annual, ZIT never conflicts (alternative)", annual_zit_never_conflicts)

same_ids <- identical(sort(annual_comparison$.witness_row), sort(annual_full$.witness_row))
cat("Full/comparison panel retained IDs identical:", same_ids, "\n")
if (!same_ids) stop("TW-07.1 parity changed: inspect the separating molecules")
cat("Annual-to-monthly count shift:", nrow(monthly_comparison) - nrow(annual_comparison),
    sprintf("(%+.2f%%)\n", 100 * (nrow(monthly_comparison) - nrow(annual_comparison)) / nrow(annual_comparison)))
cat("AMC %R, selected / alternative:", fmt_resistance(annual_comparison, "amoxicilline_acide_clavulanique"), "/",
    fmt_resistance(annual_zit_never_conflicts, "amoxicilline_acide_clavulanique"), "\n")
