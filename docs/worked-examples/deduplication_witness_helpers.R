# Shared calculation for the deduplication witness scripts.
# Reads the provisional v3 bundle; the bundle's mappings are not reviewed.

repo_root <- normalizePath(
  Sys.getenv("ORCHIDEE_V3_REPO_ROOT", unset = getwd()),
  winslash = "/", mustWork = TRUE
)
run_dir <- normalizePath(
  Sys.getenv("ORCHIDEE_V3_RUN", unset = file.path(repo_root, "outputs", "rouen_stage2_2024")),
  winslash = "/", mustWork = TRUE
)
bundle_dir <- file.path(run_dir, "bundle_v3")
rows <- as.data.frame(readRDS(file.path(bundle_dir, "sir_wide.rds")))
meta <- readRDS(file.path(bundle_dir, "sir_wide_meta.rds"))
all_atb <- intersect(meta$supported_atb_cols, names(rows))

spares_panel <- c(
  "amoxicilline_ampicilline", "amoxicilline_acide_clavulanique",
  "piperacilline_tazobactam", "mecillinam", "cefotaxime", "ceftriaxone",
  "ceftazidime", "cefepime", "imipeneme", "ertapeneme", "gentamicine",
  "amikacine", "ofloxacine", "levofloxacine", "ciprofloxacine",
  "trimethoprime_sulfamethoxazole", "nitrofurantoine",
  "fosfomycine_trometamol", "fosfomycine_iv"
)
stopifnot(all(spares_panel %in% all_atb))

sample_date <- as.Date(rows$DATEPRELEV)
slice <- !is.na(sample_date) &
  !is.na(rows$bact_norm) &
  rows$bact_norm == "escherichia_coli" &
  !is.na(rows$naturepvt_norm) &
  rows$naturepvt_norm == "urines" &
  format(sample_date, "%Y") == "2024"
d <- rows[slice, , drop = FALSE]
sample_date <- sample_date[slice]
sort_columns <- list(as.character(d$PATID), as.numeric(sample_date))
for (nm in c("HEUREPRELEV", "ELTID", "souche_id")) {
  if (nm %in% names(d)) sort_columns[[length(sort_columns) + 1L]] <- as.character(d[[nm]])
}
ord <- do.call(order, c(sort_columns, list(na.last = TRUE, method = "radix")))
d <- d[ord, , drop = FALSE]
sample_date <- sample_date[ord]
d$.witness_row <- seq_len(nrow(d))
d$.sample_date <- sample_date

major_discrepancy <- function(a, b, zit_as_sfp = TRUE) {
  both <- !is.na(a) & !is.na(b)
  if (!any(both)) return(FALSE)
  x <- as.character(a[both])
  y <- as.character(b[both])
  susceptible <- if (zit_as_sfp) c("S", "SFP", "ZIT") else c("S", "SFP")
  any((x %in% susceptible & y == "R") | (x == "R" & y %in% susceptible))
}

deduplicate_witness <- function(data, panel, grain = c("annual", "monthly"), zit_as_sfp = TRUE) {
  grain <- match.arg(grain)
  panel <- intersect(panel, names(data))
  stopifnot(length(panel) > 0L)
  if (nrow(data) == 0L) return(data)
  period <- if (grain == "annual") format(data$.sample_date, "%Y") else format(data$.sample_date, "%Y-%m")
  key <- paste(data$PATID, data$bact_norm, data$naturepvt_norm, period, sep = "\034")
  groups_by_key <- split(seq_len(nrow(data)), factor(key, levels = unique(key)))
  antibiotypes <- as.matrix(data[, panel, drop = FALSE])
  tested <- rowSums(!is.na(antibiotypes))
  phenotype <- cbind(
    blse = data$blse_flag %in% TRUE,
    carbapenemase = data$carbapenemase_flag %in% TRUE
  )
  retained <- integer(0)

  for (indices in groups_by_key) {
    if (length(indices) == 1L) {
      retained <- c(retained, indices)
      next
    }
    duplicate_groups <- list()
    for (i in indices) {
      accepts <- vapply(duplicate_groups, function(group) {
        all(vapply(group, function(j) {
          !major_discrepancy(antibiotypes[i, ], antibiotypes[j, ], zit_as_sfp) &&
            all(phenotype[i, ] == phenotype[j, ])
        }, TRUE))
      }, TRUE)
      hit <- which(accepts)
      if (length(hit) == 0L) {
        duplicate_groups[[length(duplicate_groups) + 1L]] <- i
      } else {
        duplicate_groups[[hit[1L]]] <- c(duplicate_groups[[hit[1L]]], i)
      }
    }
    retained <- c(retained, vapply(duplicate_groups, function(group) {
      group[order(-tested[group], group, method = "radix")][1L]
    }, 1L))
  }
  data[sort(retained), , drop = FALSE]
}

resistance_summary <- function(data, column) {
  x <- data[[column]]
  tested <- !is.na(x)
  n_tested <- sum(tested)
  n_r <- sum(x == "R", na.rm = TRUE)
  c(percent = if (n_tested) 100 * n_r / n_tested else NA_real_, r = n_r, tested = n_tested)
}

fmt_resistance <- function(data, column) {
  x <- resistance_summary(data, column)
  sprintf("%.2f%% (%d / %d)", x["percent"], x["r"], x["tested"])
}
