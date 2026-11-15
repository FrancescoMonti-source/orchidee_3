# Stage 1 v2: Deterministic 1-to-1 enrichment of all 8,462 Rouen NATUREPVT labels.
# Local site-adapter exploratory prototype (ADR-0003). Never overwrites v1 files.
# Never exports PATID, EVTID, or ELTID.

args <- commandArgs(trailingOnly = TRUE)
script_flag <- grep("^--file=", commandArgs(FALSE), value = TRUE)
here <- if (length(script_flag) > 0L) dirname(normalizePath(sub("^--file=", "", script_flag[1L]), winslash = "/")) else getwd()
root <- normalizePath(file.path(here, "../../.."), winslash = "/")
input_rds <- if (length(args) >= 1L) args[1L] else file.path(root, "data/bact22_24")
v1_csv <- if (length(args) >= 2L) args[2L] else file.path(root, "outputs/sample-type-prototype/naturepvt_mapping_table.csv")
out_v2 <- if (length(args) >= 3L) args[3L] else file.path(root, "outputs/sample-type-prototype/v2")
batches_dir <- file.path(out_v2, "batches")
dir.create(batches_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("[v2_prepare] Reading v1 baseline table: ", v1_csv)
v1_dt <- fread(
  v1_csv,
  encoding = "UTF-8",
  colClasses = list(character = c(
    "family_id", "family_key", "NATUREPVT", "top_species", "top_typeana",
    "norm_ascii", "norm_clean", "glims_codes", "specimen_prefix",
    "anatomical_site", "sub_pattern", "naturepvt_norm",
    "diagnostic_vs_screening_role", "confidence", "rationale",
    "classification_source", "onerba_label_fr"
  ))
)
stopifnot(nrow(v1_dt) == 8462L)
setorder(v1_dt, rank_samples)
stopifnot(identical(as.integer(v1_dt$rank_samples), seq_len(8462L)))
v1_dt[, label_id := sprintf("LBL_%04d", rank_samples)]
stopifnot(uniqueN(v1_dt$NATUREPVT) == 8462L)

message("[v2_prepare] Reading raw GLIMS RDS: ", input_rds)
raw <- as.data.table(readRDS(input_rds))
req_cols <- c(
  "ELTID", "PATID", "DLVL", "NATUREPVT", "IDENTIFICATION",
  "TRI", "TYPEANA", "LBLANA", "STRRES", "SEJUF", "SEJUM"
)
missing_cols <- setdiff(req_cols, names(raw))
if (length(missing_cols) > 0L) {
  stop("Missing expected columns in data/bact22_24: ", paste(missing_cols, collapse = ", "))
}
raw <- raw[, ..req_cols]
for (col in req_cols) {
  if (!is.character(raw[[col]])) {
    set(raw, j = col, value = as.character(raw[[col]]))
  }
}
invisible(gc())

# Identify antibiogram samples at ELTID level
sir_codes <- c("S", "SFP", "I", "R", "ZIT")
is_sir <- !is.na(raw$STRRES) & raw$STRRES %chin% sir_codes
ab_eltids <- unique(raw$ELTID[is_sir & !is.na(raw$ELTID) & raw$ELTID != ""])
stopifnot(length(ab_eltids) == 58437L)

message(sprintf("[v2_prepare] Antibiogram ELTIDs: %d | Subsetting all rows of those ELTIDs...", length(ab_eltids)))
raw_ab <- raw[!is.na(ELTID) & ELTID %chin% ab_eltids]
rm(raw)
invisible(gc())

# Canonical non-empty NATUREPVT per ELTID (matches stage1_pregroup.R exactly)
raw_ab[, typeana_prefix := fifelse(is.na(TYPEANA) | TYPEANA == "", NA_character_, sub("\\..*$", "", TYPEANA))]
raw_ab[, is_sir_row := !is.na(STRRES) & STRRES %chin% sir_codes]
raw_ab[, is_myco_tp := !is.na(typeana_prefix) & (
  grepl("_MY$", typeana_prefix) | grepl("^PM_MY", typeana_prefix) | grepl("^PM_ATF", typeana_prefix)
)]
raw_ab[, is_fungal_id := !is.na(IDENTIFICATION) & grepl(
  "^(Candida|Aspergillus|Cryptococcus|Malassezia|Pichia|Torulopsis|Saccharomyces|Geotrichum|Trichosporon|Fusarium|Mucor|Rhizopus|Scedosporium|Exophiala|Alternaria|Nakaseomyces|Clavispora|Meyerozyma|Kluyveromyces|Yarrowia|Rhodotorula|Trichophyton|Microsporum|Epidermophyton)\\b",
  IDENTIFICATION,
  ignore.case = TRUE
)]
raw_ab[, is_myco_sir := is_sir_row & (is_myco_tp | is_fungal_id)]

sys_r_codes <- c("BGBLSE_R", "BGCARBA_R", "BGERV_R", "BGSAMR_R", "BGABRI_R", "BGABMR_R", "BGPYOBMR_R")
other_r_codes <- setdiff(unique(raw_ab$typeana_prefix[grepl("_R$", raw_ab$typeana_prefix)]), c(sys_r_codes, "BGSTA_R"))

first_nonempty <- function(x) {
  v <- x[!is.na(x) & x != ""]
  if (length(v)) v[1L] else NA_character_
}

message("[v2_prepare] Aggregating ELTID-level co-occurrence across all rows of antibiogram ELTIDs...")
eltid_ctx <- raw_ab[, .(
  NATUREPVT = first_nonempty(NATUREPVT),
  SEJUF = first_nonempty(SEJUF),
  SEJUM = first_nonempty(SEJUM),
  TRI = first_nonempty(TRI),
  has_any_sir = any(is_sir_row),
  has_bacterial_ast = any(is_sir_row & !is_myco_sir),
  has_myco_ast = any(is_myco_sir),
  has_myco_panel = any(is_myco_tp | is_fungal_id),
  has_sys_R = any(typeana_prefix %chin% sys_r_codes),
  has_bgsta_r = any(typeana_prefix == "BGSTA_R"),
  has_bgcultae = any(typeana_prefix == "BGCULTAE"),
  has_bgstrb = any(typeana_prefix == "BGSTRB"),
  has_other_R = any(typeana_prefix %chin% other_r_codes),
  has_blood_bottle = any(!is.na(typeana_prefix) & grepl("^BGFA", typeana_prefix)),
  has_urine_workup = any(typeana_prefix %chin% c("BGUCYTO", "BGASPU")),
  has_fluid_workup = any(typeana_prefix %chin% c("BGNUML", "BGEDL"))
), by = ELTID]

eltid_ctx[, is_mycology_only_ab := has_any_sir & !has_bacterial_ast]
eltid_ctx[, order_bucket := fifelse(
  has_sys_R, "sys_R",
  fifelse(has_bgsta_r & !has_bgcultae, "bgsta_only",
  fifelse(has_bgsta_r & has_bgcultae, "bgsta_cultae",
  fifelse(has_bgstrb, "bgstrb", "standard_diag")))
)]

# Map raw NATUREPVT -> stable label_id without fragile string join later
nv_map <- setNames(v1_dt$label_id, v1_dt$NATUREPVT)
eltid_labeled <- eltid_ctx[!is.na(NATUREPVT) & NATUREPVT != ""]
eltid_labeled[, label_id := unname(nv_map[NATUREPVT])]

# Fallback check in case CSV normalized CRLF -> LF on embedded newlines
if (anyNA(eltid_labeled$label_id)) {
  norm_nv <- function(x) gsub("\r\n", "\n", x, fixed = TRUE)
  nv_map_norm <- setNames(v1_dt$label_id, norm_nv(v1_dt$NATUREPVT))
  miss_idx <- which(is.na(eltid_labeled$label_id))
  eltid_labeled[miss_idx, label_id := unname(nv_map_norm[norm_nv(NATUREPVT)])]
}
n_unmapped <- sum(is.na(eltid_labeled$label_id))
if (n_unmapped > 0L) {
  stop(sprintf("Failed to map %d labeled antibiogram ELTIDs to LBL_0001..LBL_8462!", n_unmapped))
}
stopifnot(uniqueN(eltid_labeled$label_id) == 8462L)
message(sprintf("[v2_prepare] Mapped %d labeled antibiogram ELTIDs cleanly across %d label_ids.",
                nrow(eltid_labeled), uniqueN(eltid_labeled$label_id)))

# Attach label_id to raw_ab rows via ELTID so co-occurrence counts across ALL rows of those ELTIDs
eltid_lbl_lookup <- eltid_labeled[, .(ELTID, label_id)]
raw_ab_lbl <- merge(raw_ab, eltid_lbl_lookup, by = "ELTID", all = FALSE)
rm(raw_ab)
invisible(gc())

# Sample-level metrics by label_id
lbl_samp_metrics <- eltid_labeled[, .(
  n_samples_check = .N,
  n_samp_bacterial = sum(has_bacterial_ast),
  n_samp_mycology_only = sum(is_mycology_only_ab),
  n_samp_any_myco_panel = sum(has_myco_panel),
  n_samp_sys_R_chk = sum(order_bucket == "sys_R"),
  n_samp_bgsta_only_chk = sum(order_bucket == "bgsta_only"),
  n_samp_bgsta_cultae_chk = sum(order_bucket == "bgsta_cultae"),
  n_samp_bgstrb_chk = sum(order_bucket == "bgstrb"),
  n_samp_standard_diag_chk = sum(order_bucket == "standard_diag"),
  n_samp_other_R_chk = sum(has_other_R),
  n_samp_blood_bottle = sum(has_blood_bottle),
  n_samp_urine_workup = sum(has_urine_workup),
  n_samp_fluid_workup = sum(has_fluid_workup)
), by = label_id]

fmt_topk_sample <- function(dt, val_col, k = 3L) {
  sub <- dt[!is.na(get(val_col)) & get(val_col) != "", .(label_id, val = get(val_col))]
  if (nrow(sub) == 0L) return(data.table(label_id = character(0), top_str = character(0)))
  agg <- sub[, .(n = .N), by = .(label_id, val)][order(label_id, -n, val)]
  agg[, .(top_str = paste(sprintf("%s (%d)", head(val, k), head(n, k)), collapse = "; ")), by = label_id]
}

top_sejuf_dt <- fmt_topk_sample(eltid_labeled, "SEJUF", 3L)
setnames(top_sejuf_dt, "top_str", "top_sejuf")
top_sejum_dt <- fmt_topk_sample(eltid_labeled, "SEJUM", 3L)
setnames(top_sejum_dt, "top_str", "top_sejum")
top_tri_dt <- fmt_topk_sample(eltid_labeled, "TRI", 3L)
setnames(top_tri_dt, "top_str", "top_tri")

# Top TYPEANA prefixes across ALL rows of these ELTIDs
elt_tp <- unique(raw_ab_lbl[!is.na(typeana_prefix) & typeana_prefix != "", .(label_id, ELTID, typeana_prefix)])
tp_counts <- elt_tp[, .(n = .N), by = .(label_id, typeana_prefix)]
# Prioritize structural workup / screening / mycology panels in tie-breaking so they are never hidden behind single drug codes
tp_counts[, is_workup := grepl("^(BG|PM)|_MY$|_R$", typeana_prefix)]
setorder(tp_counts, label_id, -n, -is_workup, typeana_prefix)
top_typeana_dt <- tp_counts[, .(
  top_typeana_v2 = paste(sprintf("%s (%d)", head(typeana_prefix, 6L), head(n, 6L)), collapse = "; "),
  top_workup_typeana = {
    wk <- .SD[is_workup == TRUE]
    if (nrow(wk)) paste(sprintf("%s (%d)", head(wk$typeana_prefix, 5L), head(wk$n, 5L)), collapse = "; ") else ""
  }
), by = label_id]
rm(elt_tp, tp_counts)

# Top species at isolate level across all SIR rows of these ELTIDs
raw_ab_sir <- raw_ab_lbl[is_sir_row == TRUE]
raw_ab_sir[, isolate_key := paste(PATID, ELTID, DLVL, sep = "\034")]
iso_sp <- unique(raw_ab_sir[!is.na(IDENTIFICATION) & IDENTIFICATION != "", .(label_id, isolate_key, IDENTIFICATION)])
sp_counts <- iso_sp[, .(n = .N), by = .(label_id, IDENTIFICATION)][order(label_id, -n, IDENTIFICATION)]
top_species_dt <- sp_counts[, .(
  top_species_v2 = paste(sprintf("%s (%d)", head(IDENTIFICATION, 4L), head(n, 4L)), collapse = "; ")
), by = label_id]
rm(raw_ab_sir, iso_sp, sp_counts, raw_ab_lbl, eltid_ctx, eltid_labeled)
invisible(gc())

# Build enriched baseline table anchored on v1_dt (by label_id)
base <- v1_dt[, .(
  label_id,
  rank_samples,
  NATUREPVT,
  family_id,
  specimen_prefix,
  anatomical_site,
  sub_pattern,
  glims_codes,
  n_samples,
  n_isolates,
  n_sir_rows,
  pct_samples,
  cum_samples,
  cum_pct_samples,
  n_samp_sys_R,
  n_samp_bgsta_only,
  n_samp_bgsta_cultae,
  n_samp_bgstrb,
  n_samp_standard_diag,
  n_samp_other_R,
  pct_sys_R,
  pct_any_screening_order,
  v1_naturepvt_norm = naturepvt_norm,
  v1_role = diagnostic_vs_screening_role,
  v1_confidence = confidence,
  v1_source = classification_source,
  v1_rationale = rationale
)]

for (enrich_dt in list(lbl_samp_metrics, top_sejuf_dt, top_sejum_dt, top_tri_dt, top_typeana_dt, top_species_dt)) {
  base <- merge(base, enrich_dt, by = "label_id", all.x = TRUE)
}

num_zero_cols <- c(
  "n_samp_bacterial", "n_samp_mycology_only", "n_samp_any_myco_panel",
  "n_samp_blood_bottle", "n_samp_urine_workup", "n_samp_fluid_workup"
)
for (col in num_zero_cols) {
  base[is.na(get(col)), (col) := 0L]
}
char_empty_cols <- c("top_sejuf", "top_sejum", "top_tri", "top_typeana_v2", "top_workup_typeana", "top_species_v2")
for (col in char_empty_cols) {
  base[is.na(get(col)), (col) := ""]
}

# Verify exact match with v1 sample counts
diff_n <- sum(base$n_samples != base$n_samples_check)
if (diff_n > 0L) {
  message(sprintf("[v2_prepare] Note: %d labels differ slightly in n_samples vs v1 (sum v1=%d vs v2_check=%d).",
                  diff_n, sum(base$n_samples), sum(base$n_samples_check)))
} else {
  message(sprintf("[v2_prepare] Verified exact 100%% n_samples agreement across all 8,462 label_ids (%d total).", sum(base$n_samples)))
}
base[, has_double_space := grepl("  ", NATUREPVT, fixed = TRUE)]
base[, has_newline := grepl("[\r\n]", NATUREPVT)]
setorder(base, rank_samples)

# Privacy guard
forbidden <- c("PATID", "EVTID", "ELTID")
stopifnot(length(intersect(names(base), forbidden)) == 0L)

# Save full enriched catalog (RDS for lossless multi-line string preservation + CSV for inspection)
saveRDS(base, file.path(out_v2, "catalog_8462_v2_enriched.rds"))
fwrite(base, file.path(out_v2, "catalog_8462_v2_enriched.csv"))

# Export summary prep metadata
prep_meta <- list(
  total_labels = nrow(base),
  total_samples = sum(base$n_samples),
  total_isolates = sum(base$n_isolates),
  total_sir_rows = sum(base$n_sir_rows),
  total_bacterial_samples = sum(base$n_samp_bacterial),
  total_mycology_only_samples = sum(base$n_samp_mycology_only),
  labels_with_myco_only_samples = sum(base$n_samp_mycology_only > 0L),
  labels_pure_myco_only = sum(base$n_samp_mycology_only > 0L & base$n_samp_bacterial == 0L),
  labels_with_double_space = sum(base$has_double_space),
  labels_with_newline = sum(base$has_newline),
  labels_with_sejuf = sum(base$top_sejuf != "")
)
writeLines(toJSON(prep_meta, auto_unbox = TRUE, pretty = TRUE), file.path(out_v2, "v2_prep_metadata.json"), useBytes = TRUE)

# Partition all 8,462 labels into batches of 110 labels (77 batches total: 76*110 + 102 = 8,462)
BATCH_SIZE <- 110L
n_batches <- ceiling(nrow(base) / BATCH_SIZE)
for (b in seq_len(n_batches)) {
  i1 <- (b - 1L) * BATCH_SIZE + 1L
  i2 <- min(b * BATCH_SIZE, nrow(base))
  sub <- base[i1:i2]
  payload_items <- lapply(seq_len(nrow(sub)), function(k) {
    r <- sub[k]
    list(
      id = r$label_id,
      lbl = r$NATUREPVT,
      n = as.integer(r$n_samples),
      ni = as.integer(r$n_isolates),
      nbact = as.integer(r$n_samp_bacterial),
      nmyco = as.integer(r$n_samp_mycology_only),
      nsysr = as.integer(r$n_samp_sys_R),
      nbgsta_only = as.integer(r$n_samp_bgsta_only),
      nbgsta_cult = as.integer(r$n_samp_bgsta_cultae),
      nbgstrb = as.integer(r$n_samp_bgstrb),
      pscr = as.numeric(r$pct_any_screening_order),
      nblood = as.integer(r$n_samp_blood_bottle),
      nurine = as.integer(r$n_samp_urine_workup),
      nfluid = as.integer(r$n_samp_fluid_workup),
      uf = r$top_sejuf,
      um = r$top_sejum,
      tri = r$top_tri,
      ta = r$top_typeana_v2,
      wk = r$top_workup_typeana,
      sp = r$top_species_v2,
      fam = r$family_id,
      pref = r$specimen_prefix,
      site = r$anatomical_site,
      v1_cat = r$v1_naturepvt_norm,
      v1_role = r$v1_role,
      v1_conf = r$v1_confidence,
      v1_src = r$v1_source
    )
  })
  b_path <- file.path(batches_dir, sprintf("input_batch_%03d.json", b))
  writeLines(toJSON(payload_items, auto_unbox = TRUE, pretty = FALSE), b_path, useBytes = TRUE)
}

message(sprintf("[v2_prepare] Wrote %d batch JSON files in %s (total %d labels).",
                n_batches, batches_dir, nrow(base)))
message(sprintf("[v2_prepare] Summary: myco-only labels=%d (%d pure myco-only), double-space=%d, newline=%d.",
                prep_meta$labels_with_myco_only_samples, prep_meta$labels_pure_myco_only,
                prep_meta$labels_with_double_space, prep_meta$labels_with_newline))
