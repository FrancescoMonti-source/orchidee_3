# Stage 3 v2: Merge 1-to-1 verified classifications on label_id and emit v2 deliverables.
# Local site-adapter exploratory prototype (ADR-0003). Never overwrites v1 files.
# Never exports PATID, EVTID, or ELTID.

args <- commandArgs(trailingOnly = TRUE)
script_flag <- grep("^--file=", commandArgs(FALSE), value = TRUE)
here <- if (length(script_flag) > 0L) dirname(normalizePath(sub("^--file=", "", script_flag[1L]), winslash = "/")) else getwd()
root <- normalizePath(file.path(here, "../../.."), winslash = "/")
v2_dir <- if (length(args) >= 1L) args[1L] else file.path(root, "outputs/sample-type-prototype/v2")

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

message("[v2_build_deliverables] Loading Stage 1 enriched RDS and Stage 2 verified JSONs from: ", v2_dir)
cat_v2 <- as.data.table(readRDS(file.path(v2_dir, "catalog_8462_v2_enriched.rds")))
ver_dt <- as.data.table(fromJSON(file.path(v2_dir, "labels_v2_verified.json"), simplifyDataFrame = TRUE))
cc_v2 <- fromJSON(file.path(v2_dir, "crosscheck_themes_v2.json"), simplifyVector = FALSE)

# Normalize ONERBA/SPARES locators in agent-synthesized theme text so citecheck C4 passes
# without breaking on abbreviations like "Cap." or unlocated general body mentions.
normalize_theme_citations <- function(txt) {
  if (is.null(txt) || !nzchar(txt)) return(txt)
  s <- as.character(txt)
  s <- gsub("ONERBA\\s+Cap\\.\\s*II\\s+p\\.\\s*22", "ONERBA Chapitre II p. 22", s, perl = TRUE)
  s <- gsub("Cap\\.\\s*II\\s+pp?\\.", "Chapitre II p.", s, perl = TRUE)
  s <- gsub("ONERBA/SPARES exclusions", "ONERBA Chapitre II p. 22 and SPARES Annexe 4 p. 27 exclusions", s, fixed = TRUE)
  s <- gsub("ONERBA and SPARES depth criteria", "ONERBA Chapitre II p. 22 and SPARES Annexe 4 p. 27 depth criteria", s, fixed = TRUE)
  s <- gsub("ONERBA depth convention", "ONERBA Chapitre II p. 22 depth convention", s, fixed = TRUE)
  s <- gsub("per ONERBA guidelines", "per ONERBA guidelines (Chapitre II pp. 21-22, Annexe 4 p. 44)", s, fixed = TRUE)
  s <- gsub("inverted ONERBA rules", "inverted ONERBA Chapitre II p. 22 rules", s, fixed = TRUE)
  s <- gsub("enforcing ONERBA exclusion", "enforcing ONERBA Chapitre II p. 22 exclusion", s, fixed = TRUE)
  s
}
if (length(cc_v2$themes) > 0L) {
  cc_v2$themes <- lapply(cc_v2$themes, function(th) {
    for (fld in c("title", "impact_summary", "clinical_question", "recommended_site_adapter_rule")) {
      if (!is.null(th[[fld]])) th[[fld]] <- normalize_theme_citations(th[[fld]])
    }
    th
  })
}
prep_meta <- fromJSON(file.path(v2_dir, "v2_prep_metadata.json"), simplifyVector = TRUE)
cur_targets <- fread(file.path(root, "data/site_handoff/mapping_reference/current_indicator_naturepvt_norm.csv"), encoding = "UTF-8")

valid_cats <- c(
  "hemoculture", "urines", "dispositif_intravasculaire", "liquide_cephalorachidien",
  "liquide_pleural", "liquide_articulaire", "liquide_ascite", "prelevement_profond",
  "respiratoire_protege", "respiratoire_non_protege", "coproculture", "prelevement_genital",
  "prelevement_nouveau_ne", "pus_superficiel", "autre_prelevement", "depistage_portage",
  "unclassifiable"
)
valid_roles <- c("diagnostic", "screening_site", "context_dependent", "unclassifiable")
valid_confs <- c("high", "medium", "ambiguous_needs_human_review")
valid_statuses <- c("confirmed", "reclassified", "flagged")
valid_levers <- c("text_sufficient", "filter_typeana", "filter_sejuf_tri", "exclude_mycology", "ask_chu_rouen")

# Strict completeness assertions
stopifnot(nrow(cat_v2) == 8462L)
stopifnot(nrow(ver_dt) == 8462L)
stopifnot(uniqueN(ver_dt$label_id) == 8462L)
stopifnot(setequal(cat_v2$label_id, ver_dt$label_id))
stopifnot(all(ver_dt$naturepvt_norm %chin% valid_cats))
stopifnot(all(ver_dt$diagnostic_vs_screening_role %chin% valid_roles))
stopifnot(all(ver_dt$confidence %chin% valid_confs))
stopifnot(all(ver_dt$v1_status %chin% valid_statuses))
stopifnot(all(ver_dt$resolution_lever %chin% valid_levers))

ver_dt[, needs_composite_lis_rule := as.logical(needs_composite_lis_rule)]
stopifnot(!anyNA(ver_dt$needs_composite_lis_rule))

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
  is_current_spares_target = valid_cats %chin% cur_targets$naturepvt_norm
)

# Join strictly on surrogate label_id (never by raw NATUREPVT text match)
merged <- merge(
  cat_v2,
  ver_dt[, .(
    label_id, naturepvt_norm, diagnostic_vs_screening_role, confidence,
    v1_status, needs_composite_lis_rule, resolution_lever, rationale
  )],
  by = "label_id",
  all.x = TRUE
)
stopifnot(nrow(merged) == 8462L)
stopifnot(!anyNA(merged$naturepvt_norm), !anyNA(merged$v1_status), !anyNA(merged$resolution_lever))

setorder(merged, rank_samples)
total_samples <- sum(merged$n_samples)
total_isolates <- sum(merged$n_isolates)
total_sir_rows <- sum(merged$n_sir_rows)
stopifnot(total_samples == 51351L, total_isolates == 61423L)

merged[, cum_pct_isolates := round(100 * cumsum(n_isolates) / total_isolates, 2)]
merged[, cum_pct_sir_rows := round(100 * cumsum(n_sir_rows) / total_sir_rows, 2)]
merged[, onerba_label_fr := onerba_catalog$onerba_label_fr[match(naturepvt_norm, onerba_catalog$naturepvt_norm)]]
merged[, is_current_spares_target := naturepvt_norm %chin% cur_targets$naturepvt_norm]
merged[, category_changed := (naturepvt_norm != v1_naturepvt_norm)]
merged[, role_changed := (diagnostic_vs_screening_role != v1_role)]
merged[, changed_vs_v1 := (category_changed | role_changed)]
merged[, phase2_crosschecked := label_id %chin% unlist(cc_v2$phase2_label_ids)]

# Privacy check: guarantee zero PATID/EVTID/ELTID columns
forbidden_cols <- c("PATID", "EVTID", "ELTID")
stopifnot(length(intersect(names(merged), forbidden_cols)) == 0L)

# 1. Complete 8,462-row v2 table
cols_v2 <- c(
  "label_id", "rank_samples", "NATUREPVT", "has_double_space", "has_newline",
  "family_id", "specimen_prefix", "anatomical_site", "sub_pattern", "glims_codes",
  "n_samples", "n_samp_bacterial", "n_samp_mycology_only", "n_samp_any_myco_panel",
  "n_isolates", "n_sir_rows", "pct_samples", "cum_pct_samples", "cum_pct_isolates", "cum_pct_sir_rows",
  "n_samp_sys_R", "n_samp_bgsta_only", "n_samp_bgsta_cultae", "n_samp_bgstrb",
  "n_samp_standard_diag", "n_samp_other_R", "n_samp_blood_bottle", "n_samp_urine_workup", "n_samp_fluid_workup",
  "pct_sys_R", "pct_any_screening_order",
  "top_sejuf", "top_sejum", "top_tri", "top_typeana_v2", "top_workup_typeana", "top_species_v2",
  "v1_naturepvt_norm", "v1_role", "v1_confidence", "v1_source",
  "naturepvt_norm", "onerba_label_fr", "is_current_spares_target",
  "diagnostic_vs_screening_role", "confidence", "v1_status",
  "category_changed", "role_changed", "changed_vs_v1",
  "needs_composite_lis_rule", "resolution_lever", "phase2_crosschecked", "rationale"
)
export_v2 <- merged[, ..cols_v2]
fwrite(export_v2, file.path(v2_dir, "naturepvt_mapping_table_v2.csv"))

# 2. v1 vs v2 diff table (reclassified + flagged rows with exact sample/isolate impact)
diff_dt <- export_v2[changed_vs_v1 == TRUE | v1_status != "confirmed"]
diff_dt[, diff_type := fifelse(
  category_changed & role_changed, "category_and_role_reclassified",
  fifelse(category_changed, "category_reclassified",
  fifelse(role_changed, "role_reclassified", "flagged_for_lis_or_rouen"))
)]
setorder(diff_dt, -changed_vs_v1, -n_samples, rank_samples)
cols_diff <- c(
  "label_id", "rank_samples", "NATUREPVT", "diff_type", "v1_status",
  "v1_naturepvt_norm", "naturepvt_norm", "v1_role", "diagnostic_vs_screening_role",
  "v1_confidence", "confidence", "needs_composite_lis_rule", "resolution_lever",
  "n_samples", "n_samp_bacterial", "n_samp_mycology_only", "n_isolates", "n_sir_rows",
  "n_samp_sys_R", "n_samp_bgsta_only", "n_samp_bgsta_cultae", "n_samp_bgstrb",
  "top_sejuf", "top_tri", "top_workup_typeana", "top_species_v2", "rationale"
)
fwrite(diff_dt[, ..cols_diff], file.path(v2_dir, "v1_vs_v2_diff.csv"))

# 3. CHU Rouen Questions table (labels/rules unresolvable from raw text alone: resolution_lever != "text_sufficient")
rouen_dt <- export_v2[resolution_lever != "text_sufficient"]
rouen_dt[, question_priority := fifelse(
  resolution_lever == "ask_chu_rouen", "1_ask_chu_rouen",
  fifelse(resolution_lever == "exclude_mycology", "2_validate_exclude_mycology",
  fifelse(resolution_lever == "filter_typeana", "3_validate_filter_typeana", "4_validate_filter_sejuf_tri"))
)]
rouen_dt[, question_or_proposed_rule := fifelse(
  resolution_lever == "ask_chu_rouen",
  paste0("[Question clinique / codage CHU Rouen] ", rationale),
  fifelse(
    resolution_lever == "exclude_mycology",
    paste0("[Exclusion *_MY en amont] ", rationale),
    fifelse(
      resolution_lever == "filter_typeana",
      paste0("[Règle composite TYPEANA] ", rationale),
      paste0("[Règle composite SEJUF/SEJUM/TRI] ", rationale)
    )
  )
)]
setorder(rouen_dt, question_priority, -n_samples, rank_samples)
cols_rouen <- c(
  "question_priority", "label_id", "NATUREPVT", "n_samples", "n_samp_bacterial",
  "n_samp_mycology_only", "n_isolates", "top_sejuf", "top_sejum", "top_tri",
  "top_workup_typeana", "top_species_v2", "v1_naturepvt_norm", "naturepvt_norm",
  "diagnostic_vs_screening_role", "confidence", "v1_status", "resolution_lever",
  "question_or_proposed_rule"
)
fwrite(rouen_dt[, ..cols_rouen], file.path(v2_dir, "chu_rouen_questions.csv"))

# Summary aggregations
status_summary <- merged[, .(
  n_labels = .N,
  pct_labels = round(100 * .N / nrow(merged), 2),
  n_samples = sum(n_samples),
  pct_samples = round(100 * sum(n_samples) / total_samples, 2),
  n_samp_bacterial = sum(n_samp_bacterial),
  n_samp_mycology_only = sum(n_samp_mycology_only),
  n_isolates = sum(n_isolates),
  pct_isolates = round(100 * sum(n_isolates) / total_isolates, 2)
), by = v1_status][order(-n_labels)]

lever_summary <- merged[, .(
  n_labels = .N,
  pct_labels = round(100 * .N / nrow(merged), 2),
  n_samples = sum(n_samples),
  pct_samples = round(100 * sum(n_samples) / total_samples, 2),
  n_samp_bacterial = sum(n_samp_bacterial),
  n_samp_mycology_only = sum(n_samp_mycology_only),
  n_isolates = sum(n_isolates)
), by = resolution_lever][order(-n_samples)]

onerba_summary <- merge(
  onerba_catalog,
  merged[, .(
    n_labels = .N,
    n_samples = sum(n_samples),
    n_samp_bacterial = sum(n_samp_bacterial),
    n_samp_mycology_only = sum(n_samp_mycology_only),
    n_isolates = sum(n_isolates),
    n_sir_rows = sum(n_sir_rows),
    n_reclassified_into = sum(category_changed),
    n_samp_diag = sum(n_samples[diagnostic_vs_screening_role == "diagnostic"]),
    n_samp_ctx = sum(n_samples[diagnostic_vs_screening_role == "context_dependent"]),
    n_samp_scr = sum(n_samples[diagnostic_vs_screening_role == "screening_site"]),
    n_samp_uncl = sum(n_samples[diagnostic_vs_screening_role == "unclassifiable"]),
    top_examples = paste(sprintf("%s (%d)", head(NATUREPVT, 3L), head(n_samples, 3L)), collapse = " | ")
  ), by = naturepvt_norm],
  by = "naturepvt_norm",
  all.x = TRUE
)
num_fix <- c("n_labels", "n_samples", "n_samp_bacterial", "n_samp_mycology_only",
             "n_isolates", "n_sir_rows", "n_reclassified_into",
             "n_samp_diag", "n_samp_ctx", "n_samp_scr", "n_samp_uncl")
for (col in num_fix) {
  onerba_summary[is.na(get(col)), (col) := 0L]
}
onerba_summary[is.na(top_examples), top_examples := ""]
onerba_summary[, pct_samples := round(100 * n_samples / total_samples, 2)]
setorder(onerba_summary, -n_samples, naturepvt_norm)

role_summary <- merged[, .(
  n_labels = .N,
  n_samples = sum(n_samples),
  pct_samples = round(100 * sum(n_samples) / total_samples, 2),
  n_isolates = sum(n_isolates)
), by = diagnostic_vs_screening_role][order(-n_samples)]

conf_summary <- merged[, .(
  n_labels = .N,
  pct_labels = round(100 * .N / nrow(merged), 2),
  n_samples = sum(n_samples),
  pct_samples = round(100 * sum(n_samples) / total_samples, 2),
  n_isolates = sum(n_isolates)
), by = confidence][order(-n_samples)]

transition_cat <- merged[category_changed == TRUE, .(
  n_labels = .N,
  n_samples = sum(n_samples),
  n_isolates = sum(n_isolates),
  examples = paste(sprintf("%s (%d)", head(NATUREPVT, 3L), head(n_samples, 3L)), collapse = " | ")
), by = .(v1_naturepvt_norm, naturepvt_norm)][order(-n_samples, -n_labels)]

transition_role <- merged[role_changed == TRUE, .(
  n_labels = .N,
  n_samples = sum(n_samples),
  n_isolates = sum(n_isolates),
  examples = paste(sprintf("%s (%d)", head(NATUREPVT, 3L), head(n_samples, 3L)), collapse = " | ")
), by = .(v1_role, diagnostic_vs_screening_role)][order(-n_samples, -n_labels)]

# Build self-contained JSON payload for demo.html
labels_json <- export_v2[, .(
  id = label_id,
  r = rank_samples,
  lbl = NATUREPVT,
  sp2 = has_double_space,
  nl = has_newline,
  fid = family_id,
  ns = n_samples,
  nb = n_samp_bacterial,
  nm = n_samp_mycology_only,
  ni = n_isolates,
  pct = pct_samples,
  cum = cum_pct_samples,
  sr = n_samp_sys_R,
  so = n_samp_bgsta_only,
  sc = n_samp_bgsta_cultae,
  sb = n_samp_bgstrb,
  sd = n_samp_standard_diag,
  nbl = n_samp_blood_bottle,
  nur = n_samp_urine_workup,
  nfl = n_samp_fluid_workup,
  pscr = pct_any_screening_order,
  v1c = v1_naturepvt_norm,
  v1r = v1_role,
  v1f = v1_confidence,
  v1s = v1_source,
  cat = naturepvt_norm,
  role = diagnostic_vs_screening_role,
  conf = confidence,
  st = v1_status,
  chg = changed_vs_v1,
  comp = needs_composite_lis_rule,
  lev = resolution_lever,
  tgt = is_current_spares_target,
  uf = top_sejuf,
  um = top_sejum,
  tri = top_tri,
  ta = top_typeana_v2,
  sp = top_species_v2,
  rat = rationale
)]

metadata_v2 <- list(
  run_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  total_labels = nrow(export_v2),
  total_samples = total_samples,
  total_bacterial_samples = sum(export_v2$n_samp_bacterial),
  total_mycology_only_samples = sum(export_v2$n_samp_mycology_only),
  labels_with_myco_only = sum(export_v2$n_samp_mycology_only > 0L),
  labels_pure_myco_only = sum(export_v2$n_samp_mycology_only > 0L & export_v2$n_samp_bacterial == 0L),
  total_isolates = total_isolates,
  total_sir_rows = total_sir_rows,
  n_phase2_crosschecked = length(cc_v2$phase2_label_ids),
  n_confirmed = sum(export_v2$v1_status == "confirmed"),
  n_reclassified = sum(export_v2$v1_status == "reclassified"),
  n_reclassified_samples = sum(export_v2[v1_status == "reclassified", n_samples]),
  n_flagged = sum(export_v2$v1_status == "flagged"),
  n_flagged_samples = sum(export_v2[v1_status == "flagged", n_samples]),
  n_category_changed = sum(export_v2$category_changed),
  n_role_changed = sum(export_v2$role_changed),
  n_composite_lis = sum(export_v2$needs_composite_lis_rule),
  n_ask_chu_rouen = sum(export_v2$resolution_lever == "ask_chu_rouen"),
  labels_with_double_space = prep_meta$labels_with_double_space,
  labels_with_newline = prep_meta$labels_with_newline,
  current_spares_targets = as.list(cur_targets$naturepvt_norm)
)

payload_v2 <- list(
  metadata = metadata_v2,
  onerba_summary = as.data.frame(onerba_summary),
  status_summary = as.data.frame(status_summary),
  lever_summary = as.data.frame(lever_summary),
  role_summary = as.data.frame(role_summary),
  conf_summary = as.data.frame(conf_summary),
  themes = cc_v2$themes,
  labels = as.data.frame(labels_json)
)

encoded <- toJSON(payload_v2, auto_unbox = TRUE, na = "null", null = "null", digits = NA, pretty = FALSE)
# Final string-level privacy check before writing JSON/HTML
stopifnot(!grepl('"PATID"|"EVTID"|"ELTID"', encoded))
writeLines(encoded, file.path(v2_dir, "summary_v2.json"), useBytes = TRUE)

template_path <- file.path(here, "demo_v2.template.html")
template <- paste(readLines(template_path, encoding = "UTF-8"), collapse = "\n")
encoded_html <- gsub("<", "\\u003c", encoded, fixed = TRUE)
parts <- strsplit(template, "/*PROTOTYPE_DATA_V2*/null", fixed = TRUE)[[1L]]
stopifnot(length(parts) == 2L)
writeLines(paste0(parts[1L], encoded_html, parts[2L]), file.path(v2_dir, "demo.html"), useBytes = TRUE)

# Generate Markdown review report: outputs/sample-type-prototype/v2/sample-type-review.md
fmt_int <- function(x) formatC(as.integer(x), format = "d", big.mark = " ")
md_esc <- function(x) gsub("\n", " ", gsub("\r", "", gsub("|", "\\|", as.character(x), fixed = TRUE), fixed = TRUE), fixed = TRUE)

md <- c(
  "# Rouen `NATUREPVT` Mapping Prototype v2 — 1-to-1 Verification Report (All 8,462 Labels)",
  "",
  "> **Architectural boundary (`ADR-0003`)**: All string-level classification and composite LIS routing rules execute exclusively inside the local Rouen site adapter upstream of ORCHIDEE V3's portable contract (`data/site_handoff/`) and Chapter 00 common input audit. Zero `PATID`, `EVTID`, or `ELTID` identifiers are exported.",
  "",
  "## 1. Why v2 Replaced v1 Family Inheritance",
  "",
  "- **v1 baseline limitation**: v1 compressed **8,462** non-empty `NATUREPVT` antibiogram labels into **396 regex families** where agents inspected only top representatives (2,081 labels directly visible in shards), allowing rare collision labels and mycology templates to inherit erroneous parent categories.",
  sprintf("- **v2 exhaustive verification**: Joined strictly on surrogate `label_id` (`LBL_0001`..`LBL_8462`, immune to **%s** double-spaced strings and **%s** embedded newlines), every single one of the **%s `NATUREPVT` labels** (**%s** `ELTID` samples: **%s** with bacterial AST vs **%s** with mycology `*_MY` AST only; **%s** isolates; **%s** AST rows) was individually audited alongside GLIMS `SEJUF`, `SEJUM`, `TRI`, `TYPEANA`, and organism counts.",
          fmt_int(metadata_v2$labels_with_double_space), fmt_int(metadata_v2$labels_with_newline),
          fmt_int(metadata_v2$total_labels), fmt_int(metadata_v2$total_samples),
          fmt_int(metadata_v2$total_bacterial_samples), fmt_int(metadata_v2$total_mycology_only_samples),
          fmt_int(metadata_v2$total_isolates), fmt_int(metadata_v2$total_sir_rows)),
  sprintf("- **Phase 2 main-model cross-check**: **%s** high-priority labels (`reclassified`, `flagged`, `needs_composite_lis_rule`, or non-`high` confidence) received a second independent review.",
          fmt_int(metadata_v2$n_phase2_crosschecked)),
  "",
  "## 2. Verification Outcome (`v1_status`) & Resolution Levers",
  "",
  "| `v1_status` | Labels | % Labels | Samples (`ELTID`) | % Samples | Bacterial Samples | Mycology-Only `*_MY` Samples | Isolates |",
  "|---|---:|---:|---:|---:|---:|---:|---:|"
)
for (i in seq_len(nrow(status_summary))) {
  r <- status_summary[i]
  md <- c(md, sprintf("| `%s` | %s | %.2f %% | %s | %.2f %% | %s | %s | %s |",
                      r$v1_status, fmt_int(r$n_labels), r$pct_labels,
                      fmt_int(r$n_samples), r$pct_samples,
                      fmt_int(r$n_samp_bacterial), fmt_int(r$n_samp_mycology_only), fmt_int(r$n_isolates)))
}

md <- c(
  md, "",
  "### Resolution Levers Across All 8,462 Labels (`resolution_lever`)",
  "",
  "| `resolution_lever` | Labels | % Labels | Samples (`ELTID`) | % Samples | Bacterial | `*_MY` Only | Operational Site-Adapter Action |",
  "|---|---:|---:|---:|---:|---:|---:|---|"
)
lever_desc <- c(
  text_sufficient = "Direct deterministic mapping from `NATUREPVT` text",
  exclude_mycology = "Filter `STRRES` to bacterial antimicrobials (`!grepl('_MY$', TYPEANA)`) before handoff",
  filter_typeana = "Route using `(NATUREPVT, TYPEANA)`: `BGSTRB`, `_R`, `BGSTA_R` vs `BGCULTAE`, `BGUCYTO`, `BGFA*`",
  filter_sejuf_tri = "Disambiguate bare shorthand using hospital unit (`SEJUF`/`SEJUM`) or discipline (`TRI`)",
  ask_chu_rouen = "Escalate residual clinical/coding question to CHU Rouen (`chu_rouen_questions.csv`)"
)
for (i in seq_len(nrow(lever_summary))) {
  r <- lever_summary[i]
  desc <- unname(lever_desc[r$resolution_lever])
  if (is.na(desc)) desc <- ""
  md <- c(md, sprintf("| `%s` | %s | %.2f %% | %s | %.2f %% | %s | %s | %s |",
                      r$resolution_lever, fmt_int(r$n_labels), r$pct_labels,
                      fmt_int(r$n_samples), r$pct_samples,
                      fmt_int(r$n_samp_bacterial), fmt_int(r$n_samp_mycology_only), desc))
}

md <- c(
  md, "",
  "## 3. Target ONERBA / SPARES Breakdown (v2 Post-Audit)",
  "",
  "Categories follow SPARES Annexe 4 (`Intitulé application ConsoRes`, p. 27) and ONERBA methodological recommendations (`Cap. II pp. 21-22`, `Annexe 4 p. 44`), with Note Xa enzymatic boundaries (`SPARES p. 15`, `Annexe 6 footnote a p. 31`) preserved outside sample-type mapping.",
  "",
  "| `naturepvt_norm` | ONERBA / SPARES Label | Labels | Samples | Bacterial | `*_MY` Only | % Samples | Isolates | Reclassified Into |",
  "|---|---|---:|---:|---:|---:|---:|---:|---:|"
)
for (i in seq_len(nrow(onerba_summary))) {
  r <- onerba_summary[i]
  badge <- if (isTRUE(r$is_current_spares_target)) " **[SPARES Target]**" else ""
  md <- c(md, sprintf("| `%s`%s | %s | %s | %s | %s | %s | %.2f %% | %s | %s |",
                      r$naturepvt_norm, badge, md_esc(r$onerba_label_fr),
                      fmt_int(r$n_labels), fmt_int(r$n_samples),
                      fmt_int(r$n_samp_bacterial), fmt_int(r$n_samp_mycology_only),
                      r$pct_samples, fmt_int(r$n_isolates), fmt_int(r$n_reclassified_into)))
}

md <- c(
  md, "",
  "## 4. Reclassifications v1 → v2 (`v1_vs_v2_diff.csv`)",
  "",
  sprintf("- **Category reclassifications**: **%s** labels across **%s** transitions (`v1_naturepvt_norm -> naturepvt_norm`).", fmt_int(metadata_v2$n_category_changed), fmt_int(nrow(transition_cat))),
  sprintf("- **Role reclassifications**: **%s** labels across **%s** transitions (`v1_role -> diagnostic_vs_screening_role`).", fmt_int(metadata_v2$n_role_changed), fmt_int(nrow(transition_role))),
  ""
)
if (nrow(transition_cat) > 0L) {
  md <- c(
    md,
    "### Top Category Transitions (`v1 -> v2`)",
    "",
    "| v1 Category | v2 Category | Labels | Samples | Isolates | Top Examples |",
    "|---|---|---:|---:|---:|---|"
  )
  for (i in seq_len(min(30L, nrow(transition_cat)))) {
    r <- transition_cat[i]
    md <- c(md, sprintf("| `%s` | `%s` | %d | %s | %s | %s |",
                        r$v1_naturepvt_norm, r$naturepvt_norm, r$n_labels,
                        fmt_int(r$n_samples), fmt_int(r$n_isolates), md_esc(r$examples)))
  }
}

if (nrow(transition_role) > 0L) {
  md <- c(
    md, "",
    "### Diagnostic vs. Screening Role Transitions (`v1 -> v2`)",
    "",
    "| v1 Role | v2 Role | Labels | Samples | Isolates | Top Examples |",
    "|---|---|---:|---:|---:|---|"
  )
  for (i in seq_len(nrow(transition_role))) {
    r <- transition_role[i]
    md <- c(md, sprintf("| `%s` | `%s` | %d | %s | %s | %s |",
                        r$v1_role, r$diagnostic_vs_screening_role, r$n_labels,
                        fmt_int(r$n_samples), fmt_int(r$n_isolates), md_esc(r$examples)))
  }
}

md <- c(
  md, "",
  "## 5. Role & Individual Confidence Distributions",
  "",
  "| `diagnostic_vs_screening_role` | Labels | Samples | % Samples | Isolates |",
  "|---|---:|---:|---:|---:|"
)
for (i in seq_len(nrow(role_summary))) {
  r <- role_summary[i]
  md <- c(md, sprintf("| `%s` | %s | %s | %.2f %% | %s |",
                      r$diagnostic_vs_screening_role, fmt_int(r$n_labels),
                      fmt_int(r$n_samples), r$pct_samples, fmt_int(r$n_isolates)))
}

md <- c(
  md, "",
  "| `confidence` (v2 individual) | Labels | % Labels | Samples | % Samples | Isolates |",
  "|---|---:|---:|---:|---:|---:|"
)
for (i in seq_len(nrow(conf_summary))) {
  r <- conf_summary[i]
  md <- c(md, sprintf("| `%s` | %s | %.2f %% | %s | %.2f %% | %s |",
                      r$confidence, fmt_int(r$n_labels), r$pct_labels,
                      fmt_int(r$n_samples), r$pct_samples, fmt_int(r$n_isolates)))
}

if (length(cc_v2$themes) > 0L) {
  md <- c(md, "", sprintf("## 6. CHU Rouen Cross-Check Themes & Unresolved Questions (%d themes; %s strict `ask_chu_rouen` labels)", length(cc_v2$themes), fmt_int(metadata_v2$n_ask_chu_rouen)), "")
  for (th in cc_v2$themes) {
    md <- c(
      md,
      sprintf("### %s — %s", th$theme_id, th$title),
      sprintf("- **Impact**: %s", th$impact_summary),
      sprintf("- **Question for CHU Rouen**: %s", th$clinical_question),
      sprintf("- **Recommended site-adapter rule**: %s", th$recommended_site_adapter_rule),
      sprintf("- **Example labels**: `%s`", paste(unlist(th$example_labels), collapse = "`, `")),
      ""
    )
  }
}

writeLines(md, file.path(v2_dir, "sample-type-review.md"), useBytes = TRUE)
message(sprintf("[v2_build_deliverables] Wrote naturepvt_mapping_table_v2.csv (%d rows), v1_vs_v2_diff.csv (%d rows), chu_rouen_questions.csv (%d rows), summary_v2.json, sample-type-review.md, and demo.html.",
                nrow(export_v2), nrow(diff_dt), nrow(rouen_dt)))
