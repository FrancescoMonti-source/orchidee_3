# Reproduction for docs/worked-examples/unit-attribution.md
# Run from repository root or set ORCHIDEE_V3_REPO_ROOT and ORCHIDEE_V3_RUN.

args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(args) > 0L) dirname(normalizePath(sub("^--file=", "", args[1L]), winslash = "/")) else getwd()
helpers_file <- file.path(script_dir, "deduplication_witness_helpers.R")
if (!file.exists(helpers_file)) {
  repo_root <- Sys.getenv("ORCHIDEE_V3_REPO_ROOT", unset = getwd())
  helpers_file <- file.path(repo_root, "docs", "worked-examples", "deduplication_witness_helpers.R")
}
source(helpers_file)

s <- rows
r <- as.data.frame(readRDS(file.path(bundle_dir, "sample_scope_reference.rds")))
s$year <- as.integer(format(as.Date(s$DATEPRELEV), "%Y"))

# Unassigned isolates characterization (Section 05 / unit-attribution.md)
na_sejuf <- is.na(s$SEJUF)
cat("=== Diagnostic isolates without active PMSI unit (SEJUF = NA) ===\n")
cat(sprintf("Total in bundle: %d (%.1f%% of %d isolates)\n",
            sum(na_sejuf), 100 * mean(na_sejuf), nrow(s)))
cat("By year:", paste(sprintf("%s: %d", names(table(s$year[na_sejuf])), table(s$year[na_sejuf])), collapse = ", "), "\n\n")

# Canonical PMSI attribution (ADR-0009 / Decision 05.1)
s_pmsi <- merge(
  s,
  r[, c("SEJUF", "sample_uf_is_eligible_by_ta_de")],
  by = "SEJUF",
  all.x = TRUE
)
s_pmsi$elig <- !is.na(s_pmsi$sample_uf_is_eligible_by_ta_de) &
  s_pmsi$sample_uf_is_eligible_by_ta_de

ec_pmsi <- s_pmsi[
  s_pmsi$bact_norm == "escherichia_coli" & s_pmsi$year == 2024,
]

cat("=== E. coli 2024 Diagnostic Surveillance (ADR-0009 Canonical Attribution) ===\n")
cat("E. coli 2024 diagnostic total:", nrow(ec_pmsi), "\n")
cat(
  "Eligible under PMSI attribution alone:",
  sum(ec_pmsi$elig),
  "\n"
)

A <- dedup(ec_pmsi[ec_pmsi$elig, ], annexe3_ecoli)

cat("\nStrict PMSI attribution :", nrow(A), "isolates\n")
cat("\n%R (numerator/denominator):\n")
for (ab in c(
  "amoxicilline_acide_clavulanique",
  "cefotaxime",
  "ofloxacine",
  "trimethoprime_sulfamethoxazole",
  "ertapeneme",
  "gentamicine"
)) {
  a <- pr(A, ab)
  cat(sprintf(
    "%-32s %6.2f %%R (n=%4d)\n",
    ab,
    a[1],
    a[2]
  ))
}
