# Reproduction for docs/worked-examples/denominator.md
# Run from repository root or set ORCHIDEE_V3_REPO_ROOT and ORCHIDEE_V3_RUN.
# Part 1: eligible perimeter, profiles, timestamp resolution.

find_repo_root <- function() {
  env_root <- Sys.getenv("ORCHIDEE_V3_REPO_ROOT", unset = "")
  if (nzchar(env_root) && dir.exists(env_root)) return(normalizePath(env_root, winslash = "/"))
  c_args <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(c_args) > 0L) {
    s_dir <- dirname(normalizePath(sub("^--file=", "", c_args[1L]), winslash = "/"))
    cand <- normalizePath(file.path(s_dir, "..", ".."), winslash = "/", mustWork = FALSE)
    if (file.exists(file.path(cand, "CONTEXT.md"))) return(cand)
  }
  normalizePath(getwd(), winslash = "/")
}
repo_root <- find_repo_root()
run_dir <- normalizePath(
  Sys.getenv("ORCHIDEE_V3_RUN", unset = file.path(repo_root, "outputs", "rouen_stage2_2024")),
  winslash = "/", mustWork = FALSE
)
site_dir <- file.path(run_dir, "site_inputs")

merge_intervals_df <- function(df, group_cols, extra_cols = NULL, tz = "Europe/Paris") {
  ord_args <- vector("list", length(group_cols) + 2L)
  for (i in seq_along(group_cols)) {
    ord_args[[i]] <- df[[group_cols[i]]]
  }
  ord_args[[length(group_cols) + 1L]] <- df$s
  ord_args[[length(group_cols) + 2L]] <- df$e2
  ord <- do.call(order, ord_args)

  df_s <- df[ord, ]
  n <- nrow(df_s)
  if (n == 0L) return(df_s[0L, ])

  diff_vec <- rep(FALSE, n - 1L)
  for (col in group_cols) {
    v <- df_s[[col]]
    diff_vec <- diff_vec | (v[-1L] != v[-n])
  }
  is_diff_grp <- c(TRUE, diff_vec)

  s_num <- as.numeric(df_s$s)
  e_num <- as.numeric(df_s$e2)

  out_idx <- 0L
  out_rows <- integer(n)
  out_s <- numeric(n)
  out_e <- numeric(n)

  cur_s <- s_num[1L]
  cur_e <- e_num[1L]
  cur_first_row <- 1L

  for (i in 2L:n) {
    if (is_diff_grp[i] || s_num[i] > cur_e) {
      out_idx <- out_idx + 1L
      out_rows[out_idx] <- cur_first_row
      out_s[out_idx] <- cur_s
      out_e[out_idx] <- cur_e

      cur_first_row <- i
      cur_s <- s_num[i]
      cur_e <- e_num[i]
    } else {
      if (e_num[i] > cur_e) cur_e <- e_num[i]
    }
  }
  out_idx <- out_idx + 1L
  out_rows[out_idx] <- cur_first_row
  out_s[out_idx] <- cur_s
  out_e[out_idx] <- cur_e

  keep_idx <- out_rows[seq_len(out_idx)]
  res <- df_s[keep_idx, c(group_cols, extra_cols), drop = FALSE]
  res$s <- as.POSIXct(out_s[seq_len(out_idx)], origin = "1970-01-01", tz = tz)
  res$e2 <- as.POSIXct(out_e[seq_len(out_idx)], origin = "1970-01-01", tz = tz)
  rownames(res) <- NULL
  res
}

raw <- readRDS(file.path(repo_root, "data", "pmsi"))$main
cat("rows:", nrow(raw), "\n")
cat("class DATENT:", class(raw$DATENT)[1], " DATSORT:", class(raw$DATSORT)[1], "\n")
has_redsan <- requireNamespace("redsan", quietly = TRUE)
cat("redsan available:", has_redsan, "\n")
if (has_redsan) raw <- redsan::prefer_pmsi_src_c_over_dw(raw)
cat("rows after source policy:", nrow(raw), "\n")

d <- raw[!is.na(raw$DATENT) & !is.na(raw$DATSORT), ]
tz <- "Europe/Paris"
sec_ent <- as.numeric(format(d$DATENT, "%H", tz = tz)) * 3600 + as.numeric(format(d$DATENT, "%M", tz = tz)) * 60
sec_sor <- as.numeric(format(d$DATSORT, "%H", tz = tz)) * 3600 + as.numeric(format(d$DATSORT, "%M", tz = tz)) * 60
cat("\n-- share of timestamps at exactly 00:00 --\n")
cat("DATENT midnight:", round(100 * mean(sec_ent == 0), 2), "%   DATSORT midnight:", round(100 * mean(sec_sor == 0), 2), "%\n")
cat("\n-- DATENT hour distribution (top 8) --\n")
print(head(sort(table(as.integer(sec_ent / 3600)), decreasing = TRUE), 8))
cat("\n-- DATSORT hour distribution (top 8) --\n")
print(head(sort(table(as.integer(sec_sor / 3600)), decreasing = TRUE), 8))

# eligible UF set from the stored exposure table
e <- readRDS(file.path(site_dir, "incidence_exposure_by_year_um_uf_ta_de_profile.rds"))
dom <- c("MÉDECINE", "URGENCES", "CHIRURGIE", "RÉANIMATION", "PÉDIATRIE", "GYNÉCOLOGIE-OBSTÉTRIQUE", "SOINS MÉDICAUX ET DE RÉADAPTATION", "SOINS DE LONGUE DURÉE", "PSYCHIATRIE", "ÉTABLISSEMENT D'HÉBERGEMENT POUR PERSONNES ÂGÉES DÉPENDANTES")
elig <- unique(e[e$CODE_TA %in% c("03", "20") & e$de_domain_ref %in% dom, c("SEJUF", "de_domain_ref")])
d$SEJUF <- trimws(as.character(d$SEJUF))
d <- merge(d, elig, by = "SEJUF")
cat("\nrows in eligible UFs:", nrow(d), "\n")

lo <- as.POSIXct("2024-01-01 00:00:00", tz = tz); hi <- as.POSIXct("2025-01-01 00:00:00", tz = tz)
x <- d[d$DATSORT > lo & d$DATENT < hi, ]
x$s <- pmax(x$DATENT, lo)
x$e2 <- pmin(x$DATSORT, hi)
x <- x[x$e2 > x$s, c("PATID", "EVTID", "SEJUM", "SEJUF", "de_domain_ref", "s", "e2")]
x$PATID <- as.character(x$PATID)
x$EVTID <- as.character(x$EVTID)
x$SEJUM <- trimws(as.character(x$SEJUM))

k <- c("PATID", "EVTID", "SEJUM", "SEJUF")
u <- merge_intervals_df(x, k, "de_domain_ref", tz = tz)
u$hours <- as.numeric(difftime(u$e2, u$s, units = "hours"))
u$nights <- as.numeric(as.Date(u$e2, tz = tz) - as.Date(u$s, tz = tz))

cat("\n=== 2024, eligible perimeter ===\n")
cat("midnight_presence nights :", format(sum(u$nights), big.mark = " "), "\n")
cat("occupancy hours / 24     :", format(round(sum(u$hours) / 24), big.mark = " "), "\n")
cat("ratio hours24 / nights   :", round(sum(u$hours) / 24 / sum(u$nights), 4), "\n")
cat("stored exposure (2024)   : 355246\n")

cat("\n-- by sector --\n")
b_nights <- aggregate(nights ~ de_domain_ref, data = u, sum)
b_hours <- aggregate(hours ~ de_domain_ref, data = u, function(h) round(sum(h) / 24))
names(b_hours)[2] <- "hours24"
b <- merge(b_nights, b_hours, by = "de_domain_ref")
b$ratio <- round(b$hours24 / b$nights, 3)
b <- b[order(-b$nights), ]
print(b, row.names = FALSE)

cat("\n-- zero-night intervals (in and out same calendar day) --\n")
z <- u[u$nights == 0, ]
cat("count:", nrow(z), " of ", nrow(u), " (", round(100 * nrow(z) / nrow(u), 2), "% )  hours they carry:", round(sum(z$hours) / 24), " patient-days\n")
z_n <- aggregate(PATID ~ de_domain_ref, data = z, length)
names(z_n)[2] <- "n"
z_days <- aggregate(hours ~ de_domain_ref, data = z, function(h) round(sum(h) / 24))
names(z_days)[2] <- "days"
z_tab <- merge(z_n, z_days, by = "de_domain_ref")
z_tab <- z_tab[order(-z_tab$n), ]
print(z_tab, row.names = FALSE)

# Part 2: all TA codes, where the two profiles diverge.

raw <- readRDS(file.path(repo_root, "data", "pmsi"))$main
if (has_redsan) raw <- redsan::prefer_pmsi_src_c_over_dw(raw)
d <- raw[!is.na(raw$DATENT) & !is.na(raw$DATSORT), ]
e <- readRDS(file.path(site_dir, "incidence_exposure_by_year_um_uf_ta_de_profile.rds"))
ref <- unique(e[, c("SEJUF", "CODE_TA", "de_domain_ref")])
d$SEJUF <- trimws(as.character(d$SEJUF))
d <- merge(d, ref, by = "SEJUF")

lo <- as.POSIXct("2024-01-01 00:00:00", tz = tz)
hi <- as.POSIXct("2025-01-01 00:00:00", tz = tz)
x <- d[d$DATSORT > lo & d$DATENT < hi, ]
x$s <- pmax(x$DATENT, lo)
x$e2 <- pmin(x$DATSORT, hi)
x <- x[x$e2 > x$s, c("PATID", "EVTID", "SEJUM", "SEJUF", "CODE_TA", "de_domain_ref", "s", "e2")]
x$PATID <- as.character(x$PATID)
x$EVTID <- as.character(x$EVTID)
x$SEJUM <- trimws(as.character(x$SEJUM))

k <- c("PATID", "EVTID", "SEJUM", "SEJUF")
u <- merge_intervals_df(x, k, c("CODE_TA", "de_domain_ref"), tz = tz)
u$hours <- as.numeric(difftime(u$e2, u$s, units = "hours"))
u$nights <- as.numeric(as.Date(u$e2, tz = tz) - as.Date(u$s, tz = tz))

cat("=== 2024, TA 10 (accueil des urgences) ===\n")
t10 <- u[u$CODE_TA == "10", ]
cat("unit-episodes:", nrow(t10), "\n")
cat("midnight_presence nights:", round(sum(t10$nights)), "\n")
cat("occupancy hours / 24    :", round(sum(t10$hours) / 24), "\n")
cat("ratio                   :", round(sum(t10$hours) / 24 / sum(t10$nights), 4), "\n")
cat("zero-night episodes     :", sum(t10$nights == 0), " (", round(100 * mean(t10$nights == 0), 1), "% )\n")
cat("median stay hours       :", round(median(t10$hours), 2), "   mean:", round(mean(t10$hours), 2), "\n")

cat("\n=== same, all TA outside the eligible perimeter ===\n")
dom <- c("MÉDECINE", "URGENCES", "CHIRURGIE", "RÉANIMATION", "PÉDIATRIE", "GYNÉCOLOGIE-OBSTÉTRIQUE", "SOINS MÉDICAUX ET DE RÉADAPTATION", "SOINS DE LONGUE DURÉE", "PSYCHIATRIE", "ÉTABLISSEMENT D'HÉBERGEMENT POUR PERSONNES ÂGÉES DÉPENDANTES")
u$elig <- u$CODE_TA %in% c("03", "20") & u$de_domain_ref %in% dom

episodes <- aggregate(PATID ~ elig + CODE_TA, data = u, length)
names(episodes)[3] <- "episodes"
nights <- aggregate(nights ~ elig + CODE_TA, data = u, function(n) round(sum(n)))
hours <- aggregate(hours ~ elig + CODE_TA, data = u, function(h) round(sum(h) / 24))
names(hours)[3] <- "hours24"
b <- merge(merge(episodes, nights, by = c("elig", "CODE_TA")), hours, by = c("elig", "CODE_TA"))
b$ratio <- round(b$hours24 / pmax(b$nights, 1), 3)
b <- b[order(b$elig, -b$nights), ]
print(b, row.names = FALSE)
