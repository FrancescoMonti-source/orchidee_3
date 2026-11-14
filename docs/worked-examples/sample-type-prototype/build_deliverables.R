# Stage 3: Merge Stage 1 pre-grouping with Stage 2 classifications & cross-check decisions,
# and emit review CSVs, Markdown report, summary JSON, and self-contained demo.html.
# Local site-adapter exploratory prototype (ADR-0003). Never exports PATID, EVTID, or ELTID.

args <- commandArgs(trailingOnly = TRUE)
script_flag <- grep("^--file=", commandArgs(FALSE), value = TRUE)
here <- if (length(script_flag) > 0L) dirname(normalizePath(sub("^--file=", "", script_flag[1L]), winslash = "/")) else getwd()
root <- normalizePath(file.path(here, "../../.."), winslash = "/")
output <- if (length(args) >= 1L) args[1L] else file.path(root, "outputs/sample-type-prototype")

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("[Stage 3] Loading Stage 1 & Stage 2 artifacts from: ", output)
cat_dt <- fread(file.path(output, "catalog_8462_pregrouped.csv"), encoding = "UTF-8")
fam_dt <- fread(file.path(output, "families_pregrouped.csv"), encoding = "UTF-8")
s1_meta <- fromJSON(file.path(output, "stage1_metadata.json"), simplifyVector = TRUE)
cls_raw <- as.data.table(fromJSON(file.path(output, "classifications.json"), simplifyDataFrame = TRUE))
cc_raw <- fromJSON(file.path(output, "crosscheck_decisions.json"), simplifyVector = FALSE)
non_ab_nv <- fread(file.path(output, "non_antibiogram_naturepvt_catalog.csv"), encoding = "UTF-8")
non_ab_ta <- fread(file.path(output, "non_antibiogram_typeana_summary.csv"), encoding = "UTF-8")
scr_diag <- fread(file.path(output, "screening_code_diagnostics.csv"), encoding = "UTF-8")
cur_targets <- fread(file.path(root, "data/site_handoff/mapping_reference/current_indicator_naturepvt_norm.csv"), encoding = "UTF-8")

# Assertions on completeness
stopifnot(nrow(cat_dt) == 8462L)
stopifnot(nrow(fam_dt) == nrow(cls_raw))
stopifnot(all(fam_dt$family_id %chin% cls_raw$family_id))

valid_cats <- c(
  "hemoculture", "urines", "dispositif_intravasculaire", "liquide_cephalorachidien",
  "liquide_pleural", "liquide_articulaire", "liquide_ascite", "prelevement_profond",
  "respiratoire_protege", "respiratoire_non_protege", "coproculture", "prelevement_genital",
  "prelevement_nouveau_ne", "pus_superficiel", "autre_prelevement", "depistage_portage",
  "unclassifiable"
)
valid_roles <- c("diagnostic", "screening_site", "context_dependent", "unclassifiable")
valid_confs <- c("high", "medium", "ambiguous_needs_human_review")

stopifnot(all(cls_raw$naturepvt_norm %chin% valid_cats))
stopifnot(all(cls_raw$diagnostic_vs_screening_role %chin% valid_roles))
stopifnot(all(cls_raw$confidence %chin% valid_confs))

# Official ONERBA / SPARES category metadata
onerba_catalog <- data.table(
  naturepvt_norm = valid_cats,
  onerba_label_fr = c(
    "Hémoculture",
    "Urine (hors matériel de sondage)",
    "Dispositif intravasculaire (KT, CIP)",
    "Liquide céphalorachidien (LCR)",
    "Liquide pleural",
    "Liquide articulaire / synovial",
    "Liquide d'ascite / dialyse péritonéale",
    "Prélèvement profond (chirurgical / ponction / os)",
    "Respiratoire protégé ou distal (LBA, PDP/PBDP, brosse)",
    "Respiratoire non protégé (expectoration, aspi.)",
    "Coproculture (hors dépistage)",
    "Prélèvement génital",
    "Prélèvement nouveau-né / materno-foetal",
    "Pus superficiel / plaie / ORL / abcès cutané",
    "Autre prélèvement (drain, cornée, matériel, anatomique)",
    "Dépistage / portage (sites superficiels & BMR/BHRe)",
    "Non classable (X, SANS, Autre, latéralité seule)"
  ),
  spares_reference = c(
    "SPARES Annexe 4 (p. 27) & current_indicator_naturepvt_norm.csv",
    "SPARES Annexe 4 (p. 27) & current_indicator_naturepvt_norm.csv",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27)",
    "SPARES Annexe 4 (p. 27) & ONERBA Annexe 4 (p. 44)",
    "SPARES Annexe 4 (p. 27)",
    "ONERBA Cap. II (pp. 21-22) & Annexe 4 (p. 44); SPARES (p. 15)",
    "Site adapter quarantine / audit review"
  ),
  is_current_spares_target = valid_cats %chin% cur_targets$naturepvt_norm
)

# Join classifications to families
fam_merged <- merge(fam_dt, cls_raw, by = "family_id", all.x = TRUE)
fam_merged[, is_current_spares_target := naturepvt_norm %chin% cur_targets$naturepvt_norm]
fam_merged[, was_crosscheck_audited := family_id %chin% unlist(cc_raw$audited_family_ids)]
fam_merged[, onerba_label_fr := onerba_catalog$onerba_label_fr[match(naturepvt_norm, onerba_catalog$naturepvt_norm)]]
setorder(fam_merged, -n_samples, -n_labels, family_id)

# Propagate family classification to all 8,462 labels
lbl_merged <- merge(
  cat_dt,
  cls_raw[, .(family_id, naturepvt_norm, diagnostic_vs_screening_role, confidence, rationale)],
  by = "family_id",
  all.x = TRUE
)
lbl_merged[, classification_source := "family_rule"]

# Apply cross-check individual label overrides (exact NATUREPVT match)
overrides_list <- cc_raw$label_overrides
n_overrides_applied <- 0L
if (length(overrides_list) > 0L) {
  for (ov in overrides_list) {
    stopifnot(ov$naturepvt_norm %chin% valid_cats)
    stopifnot(ov$diagnostic_vs_screening_role %chin% valid_roles)
    stopifnot(ov$confidence %chin% valid_confs)
    idx <- which(lbl_merged$NATUREPVT == ov$naturepvt)
    if (length(idx) > 0L) {
      lbl_merged[idx, `:=`(
        naturepvt_norm = ov$naturepvt_norm,
        diagnostic_vs_screening_role = ov$diagnostic_vs_screening_role,
        confidence = ov$confidence,
        rationale = ov$rationale,
        classification_source = "crosscheck_label_override"
      )]
      n_overrides_applied <- n_overrides_applied + length(idx)
    }
  }
}
message(sprintf("[Stage 3] Applied %d label-level cross-check overrides.", n_overrides_applied))

# Sort labels by sample frequency and compute isolate/SIR cumulative coverage
setorder(lbl_merged, rank_samples)
total_samples <- sum(lbl_merged$n_samples)
total_isolates <- sum(lbl_merged$n_isolates)
total_sir_rows <- sum(lbl_merged$n_sir_rows)

lbl_merged[, cum_pct_isolates := round(100 * cumsum(n_isolates) / total_isolates, 2)]
lbl_merged[, cum_pct_sir_rows := round(100 * cumsum(n_sir_rows) / total_sir_rows, 2)]
lbl_merged[, is_current_spares_target := naturepvt_norm %chin% cur_targets$naturepvt_norm]
lbl_merged[, onerba_label_fr := onerba_catalog$onerba_label_fr[match(naturepvt_norm, onerba_catalog$naturepvt_norm)]]

# Check override impacts per family so families table notes any overrides inside it
ov_by_fam <- lbl_merged[classification_source == "crosscheck_label_override", .(
  n_label_overrides_inside = .N
), by = family_id]
fam_merged <- merge(fam_merged, ov_by_fam, by = "family_id", all.x = TRUE)
fam_merged[is.na(n_label_overrides_inside), n_label_overrides_inside := 0L]
setorder(fam_merged, -n_samples, -n_labels, family_id)

# Privacy check: guarantee no raw IDs in exported structures
forbidden_cols <- c("PATID", "EVTID", "ELTID")
stopifnot(length(intersect(names(lbl_merged), forbidden_cols)) == 0L)
stopifnot(length(intersect(names(fam_merged), forbidden_cols)) == 0L)

# Write complete CSV review tables
fwrite(fam_merged, file.path(output, "family_mapping_table.csv"))
fwrite(lbl_merged, file.path(output, "naturepvt_mapping_table.csv"))

# Build summary aggregations from exact post-override 8,462 labels
onerba_summary <- merge(
  onerba_catalog,
  lbl_merged[, .(
    n_families = uniqueN(family_id),
    n_labels = .N,
    n_samples = sum(n_samples),
    n_isolates = sum(n_isolates),
    n_sir_rows = sum(n_sir_rows),
    n_samp_diag = sum(n_samples[diagnostic_vs_screening_role == "diagnostic"]),
    n_samp_scr = sum(n_samples[diagnostic_vs_screening_role == "screening_site"]),
    n_samp_ctx = sum(n_samples[diagnostic_vs_screening_role == "context_dependent"]),
    n_samp_uncl = sum(n_samples[diagnostic_vs_screening_role == "unclassifiable"]),
    n_samp_high = sum(n_samples[confidence == "high"]),
    n_samp_med = sum(n_samples[confidence == "medium"]),
    n_samp_ambig = sum(n_samples[confidence == "ambiguous_needs_human_review"]),
    top_examples = paste(sprintf("%s (%d)", head(NATUREPVT, 4L), head(n_samples, 4L)), collapse = " | ")
  ), by = naturepvt_norm],
  by = "naturepvt_norm",
  all.x = TRUE
)
num_cols <- c("n_families", "n_labels", "n_samples", "n_isolates", "n_sir_rows",
              "n_samp_diag", "n_samp_scr", "n_samp_ctx", "n_samp_uncl",
              "n_samp_high", "n_samp_med", "n_samp_ambig")
for (col in num_cols) {
  onerba_summary[is.na(get(col)), (col) := 0L]
}
onerba_summary[is.na(top_examples), top_examples := ""]
onerba_summary[, pct_samples := round(100 * n_samples / total_samples, 2)]
onerba_summary[, pct_isolates := round(100 * n_isolates / total_isolates, 2)]
setorder(onerba_summary, -n_samples, naturepvt_norm)

role_summary <- lbl_merged[, .(
  n_labels = .N,
  n_families = uniqueN(family_id),
  n_samples = sum(n_samples),
  pct_samples = round(100 * sum(n_samples) / total_samples, 2),
  n_isolates = sum(n_isolates),
  pct_isolates = round(100 * sum(n_isolates) / total_isolates, 2),
  n_samp_sys_R = sum(n_samp_sys_R),
  n_samp_bgsta_cultae = sum(n_samp_bgsta_cultae),
  n_samp_bgstrb = sum(n_samp_bgstrb),
  n_samp_standard_diag = sum(n_samp_standard_diag)
), by = diagnostic_vs_screening_role][order(-n_samples)]

confidence_summary <- lbl_merged[, .(
  n_labels = .N,
  n_families = uniqueN(family_id),
  n_samples = sum(n_samples),
  pct_samples = round(100 * sum(n_samples) / total_samples, 2),
  n_isolates = sum(n_isolates),
  pct_isolates = round(100 * sum(n_isolates) / total_isolates, 2)
), by = confidence][order(-n_samples)]

milestones <- c(10L, 25L, 50L, 100L, 200L, 500L, 1000L, nrow(lbl_merged))
coverage_curve <- rbindlist(lapply(milestones, function(k) {
  sub <- lbl_merged[seq_len(k)]
  data.table(
    top_k = k,
    pct_of_labels = round(100 * k / nrow(lbl_merged), 2),
    n_samples = sum(sub$n_samples),
    cum_pct_samples = round(100 * sum(sub$n_samples) / total_samples, 2),
    n_isolates = sum(sub$n_isolates),
    cum_pct_isolates = round(100 * sum(sub$n_isolates) / total_isolates, 2),
    n_sir_rows = sum(sub$n_sir_rows),
    cum_pct_sir_rows = round(100 * sum(sub$n_sir_rows) / total_sir_rows, 2)
  )
}))

# Compact JSON label array for smooth browser performance across all 8,462 labels
labels_compact <- lbl_merged[, .(
  r = rank_samples,
  lbl = NATUREPVT,
  fid = family_id,
  cat = naturepvt_norm,
  role = diagnostic_vs_screening_role,
  conf = confidence,
  src = classification_source,
  tgt = is_current_spares_target,
  ns = n_samples,
  ni = n_isolates,
  pct = pct_samples,
  cum = cum_pct_samples,
  sr = n_samp_sys_R,
  sc = n_samp_bgsta_cultae,
  sb = n_samp_bgstrb,
  pscr = pct_any_screening_order,
  gc = glims_codes,
  sp = top_species,
  ta = top_typeana,
  rat = rationale
)]

families_export <- fam_merged[, .(
  family_id,
  family_key,
  specimen_prefix,
  anatomical_site,
  sub_pattern,
  naturepvt_norm,
  onerba_label_fr,
  diagnostic_vs_screening_role,
  confidence,
  rationale,
  is_current_spares_target,
  was_crosscheck_audited,
  n_label_overrides_inside,
  n_labels,
  n_samples,
  n_isolates,
  n_sir_rows,
  pct_samples,
  cum_pct_samples,
  n_samp_sys_R,
  n_samp_bgsta_only,
  n_samp_bgsta_cultae,
  n_samp_bgstrb,
  n_samp_standard_diag,
  n_samp_other_R,
  pct_sys_R,
  pct_any_screening_order,
  top_glims_codes,
  rep_labels,
  has_internal_heterogeneity
)]

metadata <- list(
  question = "How can Rouen's raw GLIMS NATUREPVT labels be mapped in the local site adapter to ONERBA/SPARES categories while separating diagnostic specimens from carriage screening?",
  run_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  input_name = "bact22_24",
  scope = "Local Rouen site-adapter prototype (ADR-0003). All years in data/bact22_24; samples (ELTID) with >=1 AST result in S/SFP/I/R/ZIT.",
  rows_raw = s1_meta$rows_raw,
  total_distinct_eltid = s1_meta$total_distinct_eltid,
  total_ab_samples = s1_meta$total_ab_samples,
  n_ab_missing_nv = s1_meta$n_ab_missing_nv,
  n_ab_multi_nv = s1_meta$n_ab_multi_nv,
  total_distinct_naturepvt_incl_empty = s1_meta$total_distinct_naturepvt_incl_empty,
  total_distinct_naturepvt_nonempty = s1_meta$total_distinct_naturepvt_nonempty,
  ab_distinct_labels = nrow(lbl_merged),
  total_nv_samples = total_samples,
  total_nv_isolates = total_isolates,
  total_sir_rows = total_sir_rows,
  top50_cum_pct_samples = coverage_curve[top_k == 50L, cum_pct_samples],
  top50_cum_pct_isolates = coverage_curve[top_k == 50L, cum_pct_isolates],
  top200_cum_pct_samples = coverage_curve[top_k == 200L, cum_pct_samples],
  top200_cum_pct_isolates = coverage_curve[top_k == 200L, cum_pct_isolates],
  n_families = nrow(fam_merged),
  n_crosscheck_audited = length(cc_raw$audited_family_ids),
  n_family_updates = cc_raw$n_updated,
  n_label_overrides_applied = n_overrides_applied,
  current_spares_targets = as.list(cur_targets$naturepvt_norm),
  non_ab_stats = s1_meta$non_ab_stats
)

payload <- list(
  metadata = metadata,
  onerba_catalog = as.data.frame(onerba_catalog),
  onerba_summary = as.data.frame(onerba_summary),
  role_summary = as.data.frame(role_summary),
  confidence_summary = as.data.frame(confidence_summary),
  coverage_curve = as.data.frame(coverage_curve),
  review_themes = cc_raw$review_themes,
  label_overrides = cc_raw$label_overrides,
  families = as.data.frame(families_export),
  labels = as.data.frame(labels_compact),
  screening_diagnostics = as.data.frame(scr_diag),
  non_ab_typeana = as.data.frame(head(non_ab_ta, 60L)),
  non_ab_labels = as.data.frame(head(non_ab_nv, 200L))
)

encoded <- toJSON(payload, auto_unbox = TRUE, na = "null", null = "null", digits = NA, pretty = FALSE)
writeLines(encoded, file.path(output, "summary.json"), useBytes = TRUE)

# Inject JSON into demo.template.html -> outputs/sample-type-prototype/demo.html
template_path <- file.path(here, "demo.template.html")
template <- paste(readLines(template_path, encoding = "UTF-8"), collapse = "\n")
encoded_html <- gsub("<", "\\u003c", encoded, fixed = TRUE)
parts <- strsplit(template, "/*PROTOTYPE_DATA*/null", fixed = TRUE)[[1L]]
stopifnot(length(parts) == 2L)
demo_path <- file.path(output, "demo.html")
writeLines(paste0(parts[1L], encoded_html, parts[2L]), demo_path, useBytes = TRUE)

# Generate Markdown review report: outputs/sample-type-prototype/sample-type-review.md
fmt_int <- function(x) formatC(as.integer(x), format = "d", big.mark = " ")
md_esc <- function(x) gsub("\n", " ", gsub("\r", "", gsub("|", "\\|", as.character(x), fixed = TRUE), fixed = TRUE), fixed = TRUE)

md <- c(
  "# Rouen `NATUREPVT` Sample-Type Mapping Review",
  "",
  "> **Architectural boundary (`ADR-0003`)**: This report evaluates a **local Rouen site-adapter** mapping of GLIMS `NATUREPVT` strings into ONERBA/SPARES categories (`naturepvt_norm`) and diagnostic vs. screening roles (`diagnostic_vs_screening_role`), executed upstream of the portable contract (`data/site_handoff/`) and Chapter 00 common input audit. Zero `PATID`, `EVTID`, or `ELTID` identifiers are exported.",
  "",
  "## 1. Global Volume Funnel & Empirical Coverage (`data/bact22_24`)",
  "",
  sprintf("- **Raw rows (`data/bact22_24`)**: %s rows across %s distinct samples (`ELTID`)", fmt_int(metadata$rows_raw), fmt_int(metadata$total_distinct_eltid)),
  sprintf("- **Samples with an antibiogram** (`STRRES %%in%% c(\"S\", \"SFP\", \"I\", \"R\", \"ZIT\")`): **%s** `ELTID`s", fmt_int(metadata$total_ab_samples)),
  sprintf("  - **%s** `ELTID`s have empty/`NA` `NATUREPVT` (predominantly standalone reflex antibiograms triggered by `_R` carriage screening panels such as `BGBLSE_R`, `BGCARBA_R`, `BGERV_R`; cf. `docs/findings.md` 2026-09-19).", fmt_int(metadata$n_ab_missing_nv)),
  sprintf("  - **%s** labeled sample records (`%s` isolates `(PATID, ELTID, DLVL)`, `%s` AST result rows) carry a non-empty `NATUREPVT`.", fmt_int(metadata$total_nv_samples), fmt_int(metadata$total_nv_isolates), fmt_int(metadata$total_sir_rows)),
  sprintf("- **Distinct `NATUREPVT` strings**: **%s** overall (`%s` non-empty) -> **%s** distinct non-empty labels on antibiogram samples + **%s** labels occurring exclusively on non-antibiogram samples.", fmt_int(metadata$total_distinct_naturepvt_incl_empty), fmt_int(metadata$total_distinct_naturepvt_nonempty), fmt_int(metadata$ab_distinct_labels), fmt_int(metadata$non_ab_stats$non_ab_only_distinct_labels)),
  sprintf("- **Stage 1 deterministic pre-grouping**: **8 462** antibiogram `NATUREPVT` labels compressed into **%d anatomical families** (plus **%d** individual label overrides identified in Phase 2 cross-check).", metadata$n_families, n_overrides_applied),
  "",
  "### Cumulative Coverage Milestones (Antibiogram Samples with Non-Empty `NATUREPVT`)",
  "",
  "| Slice | % of 8 462 labels | Samples covered | % of samples | Isolates covered | % of isolates | AST rows | % of AST rows |",
  "|---|---:|---:|---:|---:|---:|---:|---:|"
)
for (i in seq_len(nrow(coverage_curve))) {
  r <- coverage_curve[i]
  md <- c(md, sprintf("| Top %s | %.2f %% | %s | %.2f %% | %s | %.2f %% | %s | %.2f %% |",
                      fmt_int(r$top_k), r$pct_of_labels, fmt_int(r$n_samples), r$cum_pct_samples,
                      fmt_int(r$n_isolates), r$cum_pct_isolates, fmt_int(r$n_sir_rows), r$cum_pct_sir_rows))
}

md <- c(
  md,
  "",
  "## 2. Breakdown by Target ONERBA / SPARES Category (`naturepvt_norm`)",
  "",
  "Aligns with SPARES Annexe 4 (`Intitulé application ConsoRes`, p. 27) and ONERBA Cap. II (pp. 21–22) & Annexe 4 (p. 44). Categories matching `data/site_handoff/mapping_reference/current_indicator_naturepvt_norm.csv` are flagged **[SPARES Target]**.",
  "",
  "| `naturepvt_norm` | ONERBA / SPARES Label | Families | Raw Labels | Samples | % Samples | Isolates | Top Examples |",
  "|---|---|---:|---:|---:|---:|---:|---|"
)
for (i in seq_len(nrow(onerba_summary))) {
  r <- onerba_summary[i]
  badge <- if (isTRUE(r$is_current_spares_target)) " **[SPARES Target]**" else ""
  md <- c(md, sprintf("| `%s`%s | %s | %d | %s | %s | %.2f %% | %s | %s |",
                      r$naturepvt_norm, badge, md_esc(r$onerba_label_fr), r$n_families,
                      fmt_int(r$n_labels), fmt_int(r$n_samples), r$pct_samples,
                      fmt_int(r$n_isolates), md_esc(r$top_examples)))
}

md <- c(
  md,
  "",
  "## 3. Diagnostic vs. Screening Role & 3-Tier Empirical Audit",
  "",
  "| `diagnostic_vs_screening_role` | Families | Raw Labels | Samples | % Samples | Isolates | `_R` sys. | `BGSTA_R` + `BGCULTAE` | `BGSTRB` |",
  "|---|---:|---:|---:|---:|---:|---:|---:|---:|"
)
for (i in seq_len(nrow(role_summary))) {
  r <- role_summary[i]
  md <- c(md, sprintf("| `%s` | %d | %s | %s | %.2f %% | %s | %d | %d | %d |",
                      r$diagnostic_vs_screening_role, r$n_families, fmt_int(r$n_labels),
                      fmt_int(r$n_samples), r$pct_samples, fmt_int(r$n_isolates),
                      r$n_samp_sys_R, r$n_samp_bgsta_cultae, r$n_samp_bgstrb))
}

md <- c(
  md,
  "",
  "### Confidence Distribution",
  "",
  "| `confidence` | Families | Raw Labels | Samples | % Samples | Isolates |",
  "|---|---:|---:|---:|---:|---:|"
)
for (i in seq_len(nrow(confidence_summary))) {
  r <- confidence_summary[i]
  md <- c(md, sprintf("| `%s` | %d | %s | %s | %.2f %% | %s |",
                      r$confidence, r$n_families, fmt_int(r$n_labels),
                      fmt_int(r$n_samples), r$pct_samples, fmt_int(r$n_isolates)))
}

md <- c(md, "", "## 4. Cross-Check Review Agenda for CHU Rouen", "")
for (th in cc_raw$review_themes) {
  md <- c(
    md,
    sprintf("### %s — %s", th$theme_id, th$title),
    sprintf("- **Impact**: %s", th$impact_summary),
    sprintf("- **Clinical decision needed**: %s", th$clinical_question),
    sprintf("- **Recommended site-adapter rule**: %s", th$recommended_site_adapter_rule),
    sprintf("- **Representative labels**: `%s`", paste(unlist(th$example_labels), collapse = "`, `")),
    ""
  )
}

# Rectal / perianal comparison table
perianal_fams <- fam_merged[anatomical_site == "PERIANAL_RECTAL_GLUTEAL"][order(-n_samples)]
if (nrow(perianal_fams) > 0L) {
  md <- c(
    md,
    "## 5. Perianal / Rectal Audit (Surgical Collections vs. Superficial Portage)",
    "",
    "| Family ID | Pattern | Mapped ONERBA | Role | Confidence | Labels | Samples | Examples |",
    "|---|---|---|---|---|---:|---:|---|"
  )
  for (i in seq_len(nrow(perianal_fams))) {
    r <- perianal_fams[i]
    md <- c(md, sprintf("| `%s` | `%s` | `%s` | `%s` | `%s` | %d | %d | %s |",
                        r$family_id, r$specimen_prefix, r$naturepvt_norm,
                        r$diagnostic_vs_screening_role, r$confidence,
                        r$n_labels, r$n_samples, md_esc(r$rep_labels)))
  }
  md <- c(md, "")
}

# Queue of context_dependent and ambiguous_needs_human_review families
queue_fams <- fam_merged[diagnostic_vs_screening_role %in% c("context_dependent", "unclassifiable") | confidence == "ambiguous_needs_human_review"][order(-n_samples)]
md <- c(
  md,
  sprintf("## 6. Human Review Queue (%d Families: `context_dependent`, `unclassifiable`, or `ambiguous_needs_human_review`)", nrow(queue_fams)),
  "",
  "| Family ID | Samples | Labels | `naturepvt_norm` | Role | Confidence | Top Labels | Rationale |",
  "|---|---:|---:|---|---|---|---|---|"
)
for (i in seq_len(min(120L, nrow(queue_fams)))) {
  r <- queue_fams[i]
  md <- c(md, sprintf("| `%s` | %d | %d | `%s` | `%s` | `%s` | %s | %s |",
                      r$family_id, r$n_samples, r$n_labels, r$naturepvt_norm,
                      r$diagnostic_vs_screening_role, r$confidence,
                      md_esc(r$rep_labels), md_esc(r$rationale)))
}
if (nrow(queue_fams) > 120L) {
  md <- c(md, sprintf("\n*(Showing top 120 of %d review-queue families by sample volume; inspect all %d in `family_mapping_table.csv` or `demo.html`.)*", nrow(queue_fams), nrow(queue_fams)))
}

# Label overrides section
if (length(overrides_list) > 0L) {
  md <- c(
    md,
    "",
    sprintf("## 7. Cross-Check Individual Label Overrides (%d Labels / %d Sample Occurrences Matched)", length(overrides_list), n_overrides_applied),
    "",
    "| Raw `NATUREPVT` | Override Category | Override Role | Confidence | Rationale |",
    "|---|---|---|---|---|"
  )
  for (ov in overrides_list) {
    md <- c(md, sprintf("| `%s` | `%s` | `%s` | `%s` | %s |",
                        md_esc(ov$naturepvt), ov$naturepvt_norm, ov$diagnostic_vs_screening_role,
                        ov$confidence, md_esc(ov$rationale)))
  }
}

# Non-antibiogram summary section
md <- c(
  md,
  "",
  "## 8. Non-Antibiogram `NATUREPVT` Summary (Upstream Excluded Population)",
  "",
  sprintf("- **Non-antibiogram samples**: **%s** `ELTID`s (%s rows) without any `S/SFP/I/R/ZIT` row.", fmt_int(metadata$non_ab_stats$total_non_ab_samples), fmt_int(metadata$non_ab_stats$total_non_ab_rows)),
  sprintf("- **Distinct labels exclusive to non-antibiogram samples**: **%s** (plus %s labels shared with antibiogram samples, and %s rows with empty/`NA` `NATUREPVT`).", fmt_int(metadata$non_ab_stats$non_ab_only_distinct_labels), fmt_int(metadata$non_ab_stats$non_ab_shared_with_ab_labels), fmt_int(metadata$non_ab_stats$non_ab_missing_nv_rows)),
  "",
  "### Top 15 Non-Antibiogram `TYPEANA` Orders",
  "",
  "| `TYPEANA` Prefix | Samples | Rows | % Missing `NATUREPVT` | Sample Label (`LBLANA`) |",
  "|---|---:|---:|---:|---|"
)
for (i in seq_len(min(15L, nrow(non_ab_ta)))) {
  r <- non_ab_ta[i]
  md <- c(md, sprintf("| `%s` | %s | %s | %.1f %% | %s |",
                      md_esc(r$typeana_prefix), fmt_int(r$n_samples), fmt_int(r$n_rows),
                      r$pct_missing_naturepvt, md_esc(r$sample_lblana)))
}
md <- c(
  md,
  "",
  "### Top 20 `NATUREPVT` Labels Exclusive to Non-Antibiogram Samples",
  "",
  "| Raw `NATUREPVT` | Samples | Rows | Top `TYPEANA` |",
  "|---|---:|---:|---|"
)
for (i in seq_len(min(20L, nrow(non_ab_nv)))) {
  r <- non_ab_nv[i]
  md <- c(md, sprintf("| `%s` | %s | %s | %s |",
                      md_esc(r$NATUREPVT), fmt_int(r$n_samples), fmt_int(r$n_rows), md_esc(r$top_typeana)))
}

md_path <- file.path(output, "sample-type-review.md")
writeLines(md, md_path, useBytes = TRUE)

message("[Stage 3] Wrote CSVs, summary.json, sample-type-review.md, and demo.html in: ", output)
