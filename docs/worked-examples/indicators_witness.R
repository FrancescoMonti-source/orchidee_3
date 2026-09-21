# indicators_witness.R
# Reproduction script for Section 08 (Indicator construction) witnesses.
# Computes empirical witnesses on Rouen 2024 bacteriology data.

.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
suppressMessages(library(dplyr))

p_bundle <- "C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/bundle_v3/"
p_site <- "C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/site_inputs/"

s <- as.data.frame(readRDS(paste0(p_bundle, "sir_wide.rds")))
r <- as.data.frame(readRDS(paste0(p_bundle, "sample_scope_reference.rds")))
den <- readRDS(paste0(
  p_bundle,
  "denominator_bundle.rds"
))$incidence_exposure_by_year_um_uf_ta_de_profile

# Merge scope eligibility
s <- merge(
  s,
  r[, c("SEJUF", "sample_uf_is_eligible_by_ta_de", "sample_de_domain_ref")],
  by = "SEJUF",
  all.x = TRUE
)
s$elig <- !is.na(s$sample_uf_is_eligible_by_ta_de) &
  s$sample_uf_is_eligible_by_ta_de
s$year <- as.integer(format(as.Date(s$DATEPRELEV), "%Y"))

# Calendar year 2024
s24 <- s[s$year == 2024, ]
s24_elig <- s24[s24$elig, ]

# Exposure denominator: midnight_presence for 2024 eligible units
den24 <- den[
  den$calendar_year == 2024 & den$denominator_profile_id == "midnight_presence",
]
den24_elig <- merge(
  den24,
  r[, c("SEJUF", "sample_uf_is_eligible_by_ta_de")],
  by = "SEJUF",
  all.x = TRUE
)
total_jh_2024 <- sum(
  den24_elig$exposure_value[den24_elig$sample_uf_is_eligible_by_ta_de == TRUE],
  na.rm = TRUE
)

cat(
  "=========================================================================\n"
)
cat("SECTION 08 WITNESSES - ROUEN 2024\n")
cat(
  "Perimeter-correct exposure denominator (midnight_presence):",
  total_jh_2024,
  "JH\n"
)
cat(
  "=========================================================================\n\n"
)

PANEL <- c(
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
  "fosfomycine_iv",
  "oxacilline",
  "cefoxitine",
  "vancomycine",
  "teicoplanine",
  "daptomycine",
  "linezolide",
  "kanamycine",
  "tobramycine",
  "erythromycine",
  "pristinamycine",
  "rifampicine",
  "acide_fusidique"
)
avail_panel <- intersect(PANEL, colnames(s))

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

dedup <- function(df, panel_cols = avail_panel, window = "annual") {
  if (nrow(df) == 0) {
    return(df)
  }
  M <- as.matrix(df[, panel_cols, drop = FALSE])
  nt <- rowSums(!is.na(M))
  if (window == "annual") {
    grp <- paste(df$PATID, df$year, sep = "|")
  } else if (window == "monthly") {
    grp <- paste(df$PATID, format(as.Date(df$DATEPRELEV), "%Y-%m"), sep = "|")
  } else {
    grp <- paste(df$PATID, window, sep = "|")
  }
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

eval_group <- function(df, cols) {
  M <- as.matrix(df[, intersect(cols, colnames(df)), drop = FALSE])
  if (ncol(M) == 0) {
    return(rep("EMPTY_SET", nrow(df)))
  }
  tested <- rowSums(!is.na(M)) > 0
  has_r <- rowSums(M == "R", na.rm = TRUE) > 0
  ifelse(!tested, "EMPTY_SET", ifelse(has_r, "R", "S"))
}

# --- WITNESS 08.1: SPECIMEN DEDUPLICATION HAZARD ---
cat("--- 08.1: Specimen Scope Deduplication Hazard (Blood Cultures) ---\n")
# E. coli
ec_elig <- s24_elig[s24_elig$bact_norm == "escherichia_coli", ]
ec_hemo_raw <- ec_elig[
  !is.na(ec_elig$naturepvt_norm) & ec_elig$naturepvt_norm == "hemoculture",
]
ec_hemo_input <- dedup(ec_hemo_raw) # Approach A: input to dedup
ec_global <- dedup(ec_elig)
ec_hemo_post <- ec_global[
  !is.na(ec_global$naturepvt_norm) & ec_global$naturepvt_norm == "hemoculture",
] # Approach B: post-filter

cat(sprintf(
  "E. coli blood cultures:\n  Approach A (input to dedup) : %d isolates\n  Approach B (post-filter)    : %d isolates\n  Delta                       : %d (-%.2f%%)\n",
  nrow(ec_hemo_input),
  nrow(ec_hemo_post),
  nrow(ec_hemo_input) - nrow(ec_hemo_post),
  100 * (nrow(ec_hemo_input) - nrow(ec_hemo_post)) / nrow(ec_hemo_input)
))

# S. aureus
sa_elig <- s24_elig[s24_elig$bact_norm == "staphylococcus_aureus", ]
sa_hemo_raw <- sa_elig[
  !is.na(sa_elig$naturepvt_norm) & sa_elig$naturepvt_norm == "hemoculture",
]
sa_hemo_input <- dedup(sa_hemo_raw)
sa_global <- dedup(sa_elig)
sa_hemo_post <- sa_global[
  !is.na(sa_global$naturepvt_norm) & sa_global$naturepvt_norm == "hemoculture",
]

sarm_input <- sum(
  (!is.na(sa_hemo_input$cefoxitine) & sa_hemo_input$cefoxitine == "R") |
    (is.na(sa_hemo_input$cefoxitine) &
      !is.na(sa_hemo_input$oxacilline) &
      sa_hemo_input$oxacilline == "R")
)
sarm_post <- sum(
  (!is.na(sa_hemo_post$cefoxitine) & sa_hemo_post$cefoxitine == "R") |
    (is.na(sa_hemo_post$cefoxitine) &
      !is.na(sa_hemo_post$oxacilline) &
      sa_hemo_post$oxacilline == "R")
)

cat(sprintf(
  "S. aureus blood cultures:\n  Approach A (input to dedup) : %d isolates (%d SARM, DI = %.4f / 1000 JH)\n  Approach B (post-filter)    : %d isolates (%d SARM, DI = %.4f / 1000 JH)\n  Delta isolates              : %d (-%.2f%%)\n  Delta SARM bacteremias      : %d (-%.2f%%)\n\n",
  nrow(sa_hemo_input),
  sarm_input,
  1000 * sarm_input / total_jh_2024,
  nrow(sa_hemo_post),
  sarm_post,
  1000 * sarm_post / total_jh_2024,
  nrow(sa_hemo_input) - nrow(sa_hemo_post),
  100 * (nrow(sa_hemo_input) - nrow(sa_hemo_post)) / nrow(sa_hemo_input),
  sarm_input - sarm_post,
  100 * (sarm_input - sarm_post) / sarm_input
))

# --- WITNESS 08.2: GROUP EVALUATION ALPHABET ---
cat("--- 08.2: Group Evaluation Alphabet (E. coli C3G & FQ) ---\n")
c3g_ec <- eval_group(ec_global, c("cefotaxime", "ceftriaxone", "ceftazidime"))
fq_ec <- eval_group(
  ec_global,
  c("ofloxacine", "levofloxacine", "ciprofloxacine", "moxifloxacine")
)

cat("E. coli C3G evaluation breakdown (total = 2445):\n")
print(table(c3g_ec))
cat("E. coli FQ evaluation breakdown (total = 2445):\n")
print(table(fq_ec))

cat("\nIndividual molecule testing coverage within C3G group:\n")
for (ab in c("cefotaxime", "ceftriaxone", "ceftazidime")) {
  val <- ec_global[[ab]]
  nt <- sum(!is.na(val) & val %in% c("S", "R", "SFP", "ZIT"))
  nr <- sum(val == "R", na.rm = TRUE)
  cat(sprintf(
    "  %-15s : tested=%4d (%5.1f%%) | R=%3d | %%R=%5.2f%%\n",
    ab,
    nt,
    100 * nt / nrow(ec_global),
    nr,
    100 * nr / nt
  ))
}
cat(sprintf(
  "  %-15s : tested=%4d (%5.1f%%) | R=%3d | %%R=%5.2f%%\n\n",
  "C3G GROUP",
  sum(c3g_ec != "EMPTY_SET"),
  100 * sum(c3g_ec != "EMPTY_SET") / nrow(ec_global),
  sum(c3g_ec == "R"),
  100 * sum(c3g_ec == "R") / sum(c3g_ec != "EMPTY_SET")
))

# --- WITNESS 08.3: SARM DISCORDANCE ---
cat("--- 08.3: SARM Methicillin Rule & Concordance ---\n")
t_sa <- table(
  cefoxitine = ifelse(is.na(sa_global$cefoxitine), "NA", sa_global$cefoxitine),
  oxacilline = ifelse(is.na(sa_global$oxacilline), "NA", sa_global$oxacilline)
)
print(t_sa)
sarm_status <- ifelse(
  !is.na(sa_global$cefoxitine),
  sa_global$cefoxitine == "R",
  ifelse(!is.na(sa_global$oxacilline), sa_global$oxacilline == "R", NA)
)
cat(sprintf(
  "SARM isolates: %d / %d tested (%5.2f%%)\n\n",
  sum(sarm_status, na.rm = TRUE),
  sum(!is.na(sarm_status)),
  100 * sum(sarm_status, na.rm = TRUE) / sum(!is.na(sarm_status))
))

# --- WITNESS 08.4: PROPORTION DENOMINATOR (TESTED VS TOTAL) ---
cat(
  "--- 08.4: Proportion Denominator (Tested Denominator vs Diluted Total) ---\n"
)
for (ab in c(
  "fosfomycine_trometamol",
  "nitrofurantoine",
  "imipeneme",
  "cefotaxime"
)) {
  val <- ec_global[[ab]]
  nt <- sum(!is.na(val) & val %in% c("S", "R", "SFP", "ZIT"))
  nr <- sum(val == "R", na.rm = TRUE)
  cat(sprintf(
    "  %-25s: %%R tested = %5.2f%% (%d/%d) vs diluted = %5.2f%% (%d/%d)\n",
    ab,
    100 * nr / nt,
    nr,
    nt,
    100 * nr / nrow(ec_global),
    nr,
    nrow(ec_global)
  ))
}
cat("\n")

# --- WITNESS 08.5: INCIDENCE DENSITY DENOMINATOR ---
cat(
  "--- 08.5: Incidence Density Denominator (Perimeter-Correct vs ConsoRes SAE) ---\n"
)
sarm_count <- sum(sarm_status, na.rm = TRUE)
cat(sprintf(
  "SARM total DI:\n  ORCHIDEE (interval-derived 355 246 JH) : %.3f / 1000 JH (%d / 355246)\n  ConsoRes published (SAE 589 397 JH)     : %.3f / 1000 JH (95 / 589397)\n",
  1000 * sarm_count / total_jh_2024,
  sarm_count,
  0.16
))
cat(sprintf(
  "SARM bacteremia DI:\n  ORCHIDEE (interval-derived 355 246 JH) : %.4f / 1000 JH (%d / 355246)\n  ConsoRes published (SAE 589 397 JH)     : %.4f / 1000 JH (14 / 589397)\n\n",
  1000 * sarm_input / total_jh_2024,
  sarm_input,
  0.024
))

# --- WITNESS 08.6: PHENOTYPE DENOMINATOR (NOTE XA VS EXPLICIT TEST) ---
cat(
  "--- 08.6: Phenotype Denominators (Note Xa Species Denominator vs Explicit Tests) ---\n"
)
blse_ec_pos <- sum(ec_global$blse_flag)
ec_tested_row <- sum(ec_global$blse_status_row %in% c("positive", "negative"))
cat(sprintf(
  "E. coli BLSE proportion:\n  Under Note Xa (total isolates = %d)   : %5.2f%% (%d / %d)\n  Explicit test rows only (tested = %d) : %5.2f%% (%d / %d)\n  Distortion delta                        : +%5.2f pp\n\n",
  nrow(ec_global),
  100 * blse_ec_pos / nrow(ec_global),
  blse_ec_pos,
  nrow(ec_global),
  ec_tested_row,
  100 * blse_ec_pos / ec_tested_row,
  blse_ec_pos,
  ec_tested_row,
  100 * blse_ec_pos / ec_tested_row - 100 * blse_ec_pos / nrow(ec_global)
))

# --- WITNESS 08.8: SMALL NUMBERS IN STRATIFICATIONS ---
cat(
  "--- 08.8: Small Numbers Distribution in Monthly Sector Stratifications ---\n"
)
ec_monthly <- dedup(ec_elig, window = "monthly")
sec_m_counts <- ec_monthly %>%
  mutate(month = format(as.Date(DATEPRELEV), "%Y-%m")) %>%
  group_by(sample_de_domain_ref, month) %>%
  summarise(n = n(), .groups = "drop")

cat("Monthly-sector cell size distribution:\n")
print(summary(sec_m_counts$n))
cat(sprintf(
  "Cells with n < 5  : %d / %d (%.1f%%)\n",
  sum(sec_m_counts$n < 5),
  nrow(sec_m_counts),
  100 * sum(sec_m_counts$n < 5) / nrow(sec_m_counts)
))
cat(sprintf(
  "Cells with n < 10 : %d / %d (%.1f%%)\n\n",
  sum(sec_m_counts$n < 10),
  nrow(sec_m_counts),
  100 * sum(sec_m_counts$n < 10) / nrow(sec_m_counts)
))

cat(
  "=========================================================================\n"
)
cat("ALL WITNESSES COMPUTED SUCCESSFULLY.\n")
cat(
  "=========================================================================\n"
)
