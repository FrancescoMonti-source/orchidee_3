.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
suppressMessages({library(dplyr)})
w <- readRDS("C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/bundle_v3/sir_wide.rds")

ALL_ATB <- readRDS("C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/bundle_v3/sir_wide_meta.rds")$supported_atb_cols

# SPARES Annexe 3 panel for E. coli
PANEL <- c("amoxicilline_ampicilline","amoxicilline_acide_clavulanique",
           "piperacilline_tazobactam","mecillinam",
           "cefotaxime","ceftriaxone","ceftazidime","cefepime",
           "imipeneme","ertapeneme","gentamicine","amikacine",
           "ofloxacine","levofloxacine","ciprofloxacine",
           "trimethoprime_sulfamethoxazole","nitrofurantoine",
           "fosfomycine_trometamol","fosfomycine_iv")
stopifnot(all(PANEL %in% ALL_ATB))
OUTSIDE <- setdiff(ALL_ATB, PANEL)

d <- w %>%
  filter(bact_norm == "escherichia_coli",
         naturepvt_norm == "urines",
         format(DATEPRELEV, "%Y") == "2024") %>%
  arrange(PATID, DATEPRELEV)

cat("E. coli / urines / 2024 isolates before dedup:", nrow(d), "\n")
cat("distinct patients:", n_distinct(d$PATID), "\n")
cat("columns with any data here:", sum(sapply(ALL_ATB, function(c) any(!is.na(d[[c]])))), "of", length(ALL_ATB), "\n")
cat("out-of-panel columns with data:",
    paste(OUTSIDE[sapply(OUTSIDE, function(c) any(!is.na(d[[c]])))], collapse=", "), "\n\n")

major <- function(a, b) {
  both <- !is.na(a) & !is.na(b)
  if (!any(both)) return(FALSE)
  x <- a[both]; y <- b[both]
  any((x=="S" & y=="R") | (x=="R" & y=="S") | (x=="ZIT" & y=="R") | (x=="R" & y=="ZIT"))
}

dedup <- function(df, panel, window) {
  M <- as.matrix(df[, panel, drop = FALSE])
  ntest <- rowSums(!is.na(M))
  grp <- paste(df$PATID, df$naturepvt_norm, window, sep = "|")
  keep <- rep(FALSE, nrow(df))
  for (g in unique(grp)) {
    idx <- which(grp == g)
    idx <- idx[order(df$DATEPRELEV[idx])]
    retained <- integer(0)
    for (i in idx) {
      hit <- NA_integer_
      for (j in retained) if (!major(M[i, ], M[j, ])) { hit <- j; break }
      if (is.na(hit)) retained <- c(retained, i)
      else if (ntest[i] > ntest[hit]) retained[retained == hit] <- i
    }
    keep[retained] <- TRUE
  }
  df[keep, , drop = FALSE]
}

pR <- function(df, col) {
  v <- df[[col]][!is.na(df[[col]])]
  if (!length(v)) return(c(NA, 0, 0))
  c(round(100 * sum(v == "R") / length(v), 2), sum(v == "R"), length(v))
}

yr <- format(d$DATEPRELEV, "%Y")
mo <- format(d$DATEPRELEV, "%Y-%m")

A <- dedup(d, PANEL,   yr)
B <- dedup(d, ALL_ATB, yr)
C <- dedup(d, PANEL,   mo)

report <- function(nm, x) {
  cat(sprintf("--- %s : %d isolates retained\n", nm, nrow(x)))
  for (col in c("amoxicilline_acide_clavulanique","ofloxacine","ciprofloxacine",
                "cefotaxime","trimethoprime_sulfamethoxazole","amoxicilline_ampicilline")) {
    r <- pR(x, col)
    cat(sprintf("    %-34s %6.2f %%R   (%d / %d)\n", col, r[1], r[2], r[3]))
  }
  cat("\n")
}
report("A  SPARES panel, annual window", A)
report("B  full panel,   annual window", B)
report("C  SPARES panel, monthly window", C)

cat("=== headline ===\n")
cat(sprintf("A %d isolates | B %d (%+.1f%%) | C %d (%+.1f%%)\n",
            nrow(A), nrow(B), 100*(nrow(B)-nrow(A))/nrow(A),
            nrow(C), 100*(nrow(C)-nrow(A))/nrow(A)))
