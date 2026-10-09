# Reproduction for docs/worked-examples/perimeter-ordering.md
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
cat("bact_norm containing coli:", paste(grep("coli", unique(s$bact_norm), value=TRUE, ignore.case=TRUE), collapse=" | "), "\n")
s <- merge(s, r[,c("SEJUF","sample_uf_is_eligible_by_ta_de")], by="SEJUF", all.x=TRUE)
s$elig <- !is.na(s$sample_uf_is_eligible_by_ta_de) & s$sample_uf_is_eligible_by_ta_de

panel <- annexe3_ecoli

ec <- s[s$bact_norm=="escherichia_coli" & s$year==2024, ]
cat("\nE. coli 2024 isolates (all units, diagnostic):", nrow(ec), "  in eligible units:", sum(ec$elig), "\n")

A <- dedup(ec[ec$elig,])                    # perimeter first, then dedup
B0 <- dedup(ec); B <- B0[B0$elig,]          # dedup first, then perimeter
cat("\nA) perimeter -> dedup :", nrow(A), "isolates\n")
cat("B) dedup -> perimeter :", nrow(B), "isolates   (delta", nrow(B)-nrow(A), ")\n")
cat("   patients lost entirely by B:", length(setdiff(A$PATID, B$PATID)), "\n")
cat("   dedup over all units kept:", nrow(B0), "\n")
cat("\n%R (numerator/denominator):\n")
for (ab in c("amoxicilline_acide_clavulanique","cefotaxime","ofloxacine","trimethoprime_sulfamethoxazole","ertapeneme","gentamicine")) {
  a <- pr(A,ab); b <- pr(B,ab)
  cat(sprintf("%-32s A %6.2f (n=%4d)   B %6.2f (n=%4d)   delta %+5.2f pp\n", ab, a[1], a[2], b[1], b[2], b[1]-a[1]))
}
