# Reproduction for docs/worked-examples/unit-attribution.md
# Run from anywhere; paths point at the v2 repo.

.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
p_bundle <- "C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/bundle_v3/"
p_site <- "C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/site_inputs/"

s <- as.data.frame(readRDS(paste0(p_bundle, "sir_wide.rds")))
r <- as.data.frame(readRDS(paste0(p_bundle, "sample_scope_reference.rds")))
m <- as.data.frame(readRDS(paste0(p_site, "microbiology_observations.rds")))

panel <- c(
  "amoxicilline_ampicilline",
  "amoxicilline_acide_clavulanique",
  "piperacilline_tazobactam",
  "mecillinam",
  "cefotaxime",
  "ceftriaxone",
  "ceftazidime",
  "cefepime",
  "imipeneme",
  "ertapeneme",
  "gentamicine",
  "amikacine",
  "ofloxacine",
  "levofloxacine",
  "ciprofloxacine",
  "trimethoprime_sulfamethoxazole",
  "nitrofurantoine",
  "fosfomycine_trometamol",
  "fosfomycine_iv"
)
major <- function(a, b) {
  both <- !is.na(a) & !is.na(b)
  if (!any(both)) {
    return(FALSE)
  }
  x <- a[both]
  y <- b[both]
  any(
    (x == "S" & y == "R") |
      (x == "R" & y == "S") |
      (x == "ZIT" & y == "R") |
      (x == "R" & y == "ZIT")
  )
}
dedup <- function(df) {
  M <- as.matrix(df[, panel, drop = FALSE])
  nt <- rowSums(!is.na(M))
  grp <- paste(df$PATID, format(as.Date(df$DATEPRELEV), "%Y"), sep = "|")
  keep <- rep(FALSE, nrow(df))
  for (g in unique(grp)) {
    idx <- which(grp == g)
    idx <- idx[order(df$DATEPRELEV[idx])]
    ret <- integer(0)
    for (i in idx) {
      hit <- NA_integer_
      for (j in ret) {
        if (!major(M[i, ], M[j, ])) {
          hit <- j
          break
        }
      }
      if (is.na(hit)) {
        ret <- c(ret, i)
      } else if (nt[i] > nt[hit]) {
        ret[ret == hit] <- i
      }
    }
    keep[ret] <- TRUE
  }
  df[keep, , drop = FALSE]
}

pr <- function(df, ab) {
  v <- df[[ab]]
  v <- v[!is.na(v) & v %in% c("S", "R", "ZIT")]
  n <- sum(v %in% c("S", "R"))
  if (n == 0) {
    return(c(NA, 0))
  }
  c(round(100 * sum(v == "R") / n, 2), n)
}

s$year <- as.integer(format(as.Date(s$DATEPRELEV), "%Y"))
m_distinct_samples <- unique(m[, c(
  "PATID",
  "EVTID",
  "ELTID",
  "DATEPRELEV",
  "HEUREPRELEV",
  "microbiology_SEJUF",
  "attribution_status",
  "attribution_reason"
)])
s <- merge(
  s,
  m_distinct_samples,
  by = c("PATID", "EVTID", "ELTID", "DATEPRELEV", "HEUREPRELEV"),
  all.x = TRUE
)

# Option A: Strict PMSI attribution
s_pmsi <- merge(
  s,
  r[, c("SEJUF", "sample_uf_is_eligible_by_ta_de")],
  by = "SEJUF",
  all.x = TRUE
)
s_pmsi$elig <- !is.na(s_pmsi$sample_uf_is_eligible_by_ta_de) &
  s_pmsi$sample_uf_is_eligible_by_ta_de

# Option B: Fallback to microbiology ordering UF
s$SEJUF_fallback <- ifelse(is.na(s$SEJUF), s$microbiology_SEJUF, s$SEJUF)
s_fallback <- merge(
  s,
  r[, c("SEJUF", "sample_uf_is_eligible_by_ta_de")],
  by.x = "SEJUF_fallback",
  by.y = "SEJUF",
  all.x = TRUE
)
s_fallback$elig <- !is.na(s_fallback$sample_uf_is_eligible_by_ta_de) &
  s_fallback$sample_uf_is_eligible_by_ta_de

ec_pmsi <- s_pmsi[
  s_pmsi$bact_norm == "escherichia_coli" & s_pmsi$year == 2024,
]
ec_fallback <- s_fallback[
  s_fallback$bact_norm == "escherichia_coli" & s_fallback$year == 2024,
]

cat("E. coli 2024 diagnostic total:", nrow(ec_pmsi), "\n")
cat(
  "Eligible under PMSI attribution alone (Option A):",
  sum(ec_pmsi$elig),
  "\n"
)
cat(
  "Eligible under Fallback to microbiology UF (Option B):",
  sum(ec_fallback$elig),
  "\n"
)

A <- dedup(ec_pmsi[ec_pmsi$elig, ])
B <- dedup(ec_fallback[ec_fallback$elig, ])

cat("\nA) Strict PMSI attribution :", nrow(A), "isolates\n")
cat(
  "B) Fallback to micro UF    :",
  nrow(B),
  "isolates   (delta",
  nrow(B) - nrow(A),
  ")\n"
)
cat("   patients gained by B    :", length(setdiff(B$PATID, A$PATID)), "\n")

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
  b <- pr(B, ab)
  cat(sprintf(
    "%-32s A %6.2f (n=%4d)   B %6.2f (n=%4d)   delta %+5.2f pp\n",
    ab,
    a[1],
    a[2],
    b[1],
    b[2],
    b[1] - a[1]
  ))
}
