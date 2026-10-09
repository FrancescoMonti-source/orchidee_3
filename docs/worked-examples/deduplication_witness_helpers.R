# Shared calculation for the deduplication witness scripts.
# Reads the provisional v3 bundle; the bundle's mappings are not reviewed.

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
  winslash = "/", mustWork = TRUE
)
bundle_dir <- file.path(run_dir, "bundle_v3")
site_dir <- file.path(run_dir, "site_inputs")
rows <- as.data.frame(readRDS(file.path(bundle_dir, "sir_wide.rds")))
meta <- readRDS(file.path(bundle_dir, "sir_wide_meta.rds"))
all_atb <- intersect(meta$supported_atb_cols, names(rows))

# SPF Expression de besoins, Annexe 3 (p. 20), E. coli column. Annexe 3 lists
# fosfomycine once; the bundle splits it into trometamol and IV.
annexe3_ecoli <- c(
  "amoxicilline_ampicilline", "amoxicilline_acide_clavulanique",
  "piperacilline_tazobactam", "mecillinam", "cefotaxime", "ceftriaxone",
  "ceftazidime", "cefepime", "imipeneme", "ertapeneme", "gentamicine",
  "amikacine", "ofloxacine", "levofloxacine", "ciprofloxacine",
  "trimethoprime_sulfamethoxazole", "nitrofurantoine",
  "fosfomycine_trometamol", "fosfomycine_iv"
)
stopifnot(all(annexe3_ecoli %in% all_atb))

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
major <- major_discrepancy

dedup <- function(df, panel_cols = NULL, window = "annual", zit_as_sfp = TRUE) {
  if (nrow(df) == 0L) {
    return(df)
  }
  if (is.null(panel_cols)) {
    if (exists("avail_panel", envir = parent.frame(), inherits = TRUE)) {
      panel_cols <- get("avail_panel", envir = parent.frame())
    } else if (exists("panel", envir = parent.frame(), inherits = TRUE)) {
      panel_cols <- get("panel", envir = parent.frame())
    } else if (exists("PANEL", envir = parent.frame(), inherits = TRUE)) {
      panel_cols <- get("PANEL", envir = parent.frame())
    } else if (exists("all_atb", envir = parent.frame(), inherits = TRUE)) {
      panel_cols <- get("all_atb", envir = parent.frame())
    } else if (exists("all_atb")) {
      panel_cols <- all_atb
    } else {
      panel_cols <- colnames(df)
    }
  }
  panel_cols <- intersect(panel_cols, colnames(df))
  M <- as.matrix(df[, panel_cols, drop = FALSE])
  nt <- rowSums(!is.na(M))

  sample_dates <- if ("DATEPRELEV" %in% names(df)) as.Date(df$DATEPRELEV) else NULL
  year_val <- if ("year" %in% names(df) && !all(is.na(df$year))) {
    df$year
  } else if (!is.null(sample_dates)) {
    format(sample_dates, "%Y")
  } else {
    rep("all", nrow(df))
  }

  if (window == "annual") {
    grp <- paste(df$PATID, year_val, sep = "|")
  } else if (window == "monthly") {
    month_val <- if (!is.null(sample_dates)) format(sample_dates, "%Y-%m") else year_val
    grp <- paste(df$PATID, month_val, sep = "|")
  } else {
    grp <- paste(df$PATID, window, sep = "|")
  }

  keep <- rep(FALSE, nrow(df))
  for (g in unique(grp)) {
    idx <- which(grp == g)
    if (!is.null(sample_dates)) {
      idx <- idx[order(sample_dates[idx])]
    }
    ret <- integer(0)
    for (i in idx) {
      hit <- NA_integer_
      for (j in ret) {
        if (!major_discrepancy(M[i, ], M[j, ], zit_as_sfp = zit_as_sfp)) {
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
  v <- v[!is.na(v) & v %in% c("S", "R", "SFP", "ZIT")]
  n <- sum(v %in% c("S", "R"))
  if (n == 0L) {
    return(c(percent = NA_real_, count = 0L))
  }
  c(percent = round(100 * sum(v == "R") / n, 2), count = n)
}
pR <- pr


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
