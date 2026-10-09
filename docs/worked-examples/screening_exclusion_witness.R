# Reproduction for docs/worked-examples/screening-exclusion.md
# Run from repository root or set ORCHIDEE_V3_REPO_ROOT and ORCHIDEE_V3_RUN.

args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_dir <- if (length(args) > 0L) dirname(normalizePath(sub("^--file=", "", args[1L]), winslash = "/")) else getwd()
helpers_file <- file.path(script_dir, "deduplication_witness_helpers.R")
if (!file.exists(helpers_file)) {
  repo_root <- Sys.getenv("ORCHIDEE_V3_REPO_ROOT", unset = getwd())
  helpers_file <- file.path(repo_root, "docs", "worked-examples", "deduplication_witness_helpers.R")
}
source(helpers_file)

o   <- readRDS(file.path(site_dir, "microbiology_observations.rds"))
map <- read.csv(file.path(repo_root, "ref", "rouen", "atb_regex_map.csv"),
                stringsAsFactors = FALSE, fileEncoding = "UTF-8")
PANEL <- annexe3_ecoli

ec_rows <- !is.na(o$bacteria_local) & o$bacteria_local == "Escherichia coli" &
  !is.na(o$DATEPRELEV) & format(as.Date(o$DATEPRELEV), "%Y") == "2024"
ec <- o[ec_rows, ]
lbl <- unique(ec$antibiotic_local_source)
nm  <- vapply(lbl, function(x) {
  for (i in seq_len(nrow(map))) {
    if (grepl(map$pattern[i], x, perl = TRUE)) return(map$atb_norm[i])
  }
  NA_character_
}, character(1))
ec$atb_norm <- nm[match(ec$antibiotic_local_source, lbl)]

valid <- !is.na(ec$atb_norm) & ec$atb_norm %in% PANEL & !is.na(ec$sir_result)
ec_v <- ec[valid, ]
ec_v$key <- paste(ec_v$PATID, ec_v$ELTID, ec_v$souche_id, ec_v$DATEPRELEV, sep = "\034")
row_m <- match(ec_v$key, unique(ec_v$key))
n_u <- max(row_m)
first_i <- match(seq_len(n_u), row_m)
patid <- as.character(ec_v$PATID[first_i])
datep <- as.Date(ec_v$DATEPRELEV[first_i])
rdiag <- as.logical(tapply(ec_v$ratb_diagnostic_scope %in% TRUE, row_m, any))

col_m <- match(ec_v$atb_norm, PANEL)
mat <- matrix(NA_character_, nrow = n_u, ncol = length(PANEL), dimnames = list(NULL, PANEL))
mat[cbind(row_m, col_m)] <- as.character(ec_v$sir_result)

wide <- data.frame(PATID = patid, DATEPRELEV = datep, ratb_diagnostic_scope = rdiag, mat, stringsAsFactors = FALSE)
wide <- wide[order(wide$PATID, wide$DATEPRELEV), ]

cat("E. coli 2024, global scope (all sample types), annual window, group by PATID\n")
cat("isolate keys before dedup - diagnostic only:", sum(wide$ratb_diagnostic_scope),
    "| including screening:", nrow(wide), "\n\n")

A <- dedup(wide[wide$ratb_diagnostic_scope, ], PANEL)
B <- dedup(wide, PANEL)

cat(sprintf("after dedup - diagnostic only : %d isolates\n", nrow(A)))
cat(sprintf("after dedup - incl. screening : %d isolates (%+.1f %%)\n\n",
            nrow(B), 100 * (nrow(B) - nrow(A)) / nrow(A)))
cat(sprintf("%-34s %17s %17s\n", "indicator", "diagnostic only", "incl. screening"))
for (col in c("amoxicilline_acide_clavulanique", "ofloxacine", "cefotaxime",
              "trimethoprime_sulfamethoxazole", "ertapeneme")) {
  a <- pr(A, col)
  b <- pr(B, col)
  cat(sprintf("%-34s  %6.2f %%R (n=%4d)  %6.2f %%R (n=%4d)\n", col, a[1], a[2], b[1], b[2]))
}
