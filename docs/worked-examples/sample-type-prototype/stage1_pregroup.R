# Stage 1: Deterministic catalog extraction & structural pre-grouping of Rouen NATUREPVT labels.
# Local site-adapter exploratory prototype (ADR-0003). Never exports PATID, EVTID, or ELTID.

args <- commandArgs(trailingOnly = TRUE)
script_flag <- grep("^--file=", commandArgs(FALSE), value = TRUE)
here <- if (length(script_flag) > 0L) dirname(normalizePath(sub("^--file=", "", script_flag[1L]), winslash = "/")) else getwd()
root <- normalizePath(file.path(here, "../../.."), winslash = "/")
input <- if (length(args) >= 1L) args[1L] else file.path(root, "data/bact22_24")
output <- if (length(args) >= 2L) args[2L] else file.path(root, "outputs/sample-type-prototype")
dir.create(file.path(output, "shards"), recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
  library(stringi)
})

message("[Stage 1] Reading raw RDS locally: ", input)
raw <- as.data.table(readRDS(input))
rows_raw <- nrow(raw)

# Keep only columns needed for aggregation in memory; identifiers NEVER written to disk.
cols_keep <- c("ELTID", "PATID", "DLVL", "NATUREPVT", "IDENTIFICATION", "TYPEANA", "LBLANA", "STRRES", "DATEPRELEV")
raw <- raw[, ..cols_keep]
for (col in c("ELTID", "PATID", "DLVL", "NATUREPVT", "IDENTIFICATION", "TYPEANA", "LBLANA", "STRRES")) {
  set(raw, j = col, value = as.character(raw[[col]]))
}
invisible(gc())

# 1. Global NATUREPVT counts across all 5.15M rows
all_nv_raw <- unique(raw$NATUREPVT)
total_distinct_naturepvt_incl_empty <- length(all_nv_raw)
total_distinct_naturepvt_nonempty <- sum(!is.na(all_nv_raw) & all_nv_raw != "")
total_distinct_eltid <- uniqueN(raw$ELTID[!is.na(raw$ELTID) & raw$ELTID != ""])

# 2. Identify antibiogram samples (ELTID with >=1 row in STRRES %in% S/SFP/I/R/ZIT)
sir_codes <- c("S", "SFP", "I", "R", "ZIT")
is_sir <- !is.na(raw$STRRES) & raw$STRRES %chin% sir_codes
ab_eltids <- unique(raw$ELTID[is_sir & !is.na(raw$ELTID) & raw$ELTID != ""])
total_ab_samples <- length(ab_eltids)

message(sprintf("[Stage 1] Total rows: %d | Total ELTIDs: %d | Antibiogram ELTIDs: %d",
                rows_raw, total_distinct_eltid, total_ab_samples))
message(sprintf("[Stage 1] Total distinct NATUREPVT (incl empty/NA): %d (non-empty: %d)",
                total_distinct_naturepvt_incl_empty, total_distinct_naturepvt_nonempty))

# Split raw into antibiogram ELTIDs vs non-antibiogram ELTIDs
is_ab_eltid <- !is.na(raw$ELTID) & raw$ELTID %chin% ab_eltids
raw_ab <- raw[is_ab_eltid]
raw_non_ab <- raw[!is_ab_eltid]
rm(raw)
invisible(gc())

# Extract TYPEANA order prefix (before '.')
raw_ab[, typeana_prefix := fifelse(is.na(TYPEANA) | TYPEANA == "", NA_character_, sub("\\..*$", "", TYPEANA))]
raw_non_ab[, typeana_prefix := fifelse(is.na(TYPEANA) | TYPEANA == "", NA_character_, sub("\\..*$", "", TYPEANA))]

# 3. Sample-level (ELTID) screening order context across all rows of each antibiogram ELTID
# Note: screening batteries in note-cadrage-depistage-microbiologie.md & findings.md
sys_r_codes <- c("BGBLSE_R", "BGCARBA_R", "BGERV_R", "BGSAMR_R", "BGABRI_R", "BGABMR_R", "BGPYOBMR_R")
other_r_codes <- setdiff(unique(raw_ab$typeana_prefix[grepl("_R$", raw_ab$typeana_prefix)]), c(sys_r_codes, "BGSTA_R"))

eltid_ctx <- raw_ab[, .(
  NATUREPVT = {
    v <- NATUREPVT[!is.na(NATUREPVT) & NATUREPVT != ""]
    if (length(v)) v[1L] else NA_character_
  },
  n_distinct_nv = uniqueN(NATUREPVT[!is.na(NATUREPVT) & NATUREPVT != ""]),
  has_sys_R = any(typeana_prefix %chin% sys_r_codes),
  has_bgsta_r = any(typeana_prefix == "BGSTA_R"),
  has_bgcultae = any(typeana_prefix == "BGCULTAE"),
  has_bgstrb = any(typeana_prefix == "BGSTRB"),
  has_other_R = any(typeana_prefix %chin% other_r_codes)
), by = ELTID]

eltid_ctx[, order_bucket := fifelse(
  has_sys_R, "sys_R",
  fifelse(has_bgsta_r & !has_bgcultae, "bgsta_only",
  fifelse(has_bgsta_r & has_bgcultae, "bgsta_cultae",
  fifelse(has_bgstrb, "bgstrb", "standard_diag")))
)]

n_ab_missing_nv <- sum(is.na(eltid_ctx$NATUREPVT))
n_ab_multi_nv <- sum(eltid_ctx$n_distinct_nv > 1L)
message(sprintf("[Stage 1] Antibiogram ELTIDs missing NATUREPVT: %d | >1 NATUREPVT per ELTID: %d",
                n_ab_missing_nv, n_ab_multi_nv))

# Diagnostics on screening TYPEANA codes (both raw and antibiogram samples)
r_diag <- raw_ab[grepl("_R$", typeana_prefix) | typeana_prefix %chin% c("BGSTA_R", "BGCULTAE", "BGSTRB"), .(
  n_rows = .N,
  n_samples = uniqueN(ELTID),
  n_sir_rows = sum(!is.na(STRRES) & STRRES %chin% sir_codes),
  sample_lblana = paste(head(unique(LBLANA[!is.na(LBLANA) & LBLANA != ""]), 2L), collapse = " | ")
), by = typeana_prefix][order(-n_samples)]
fwrite(r_diag, file.path(output, "screening_code_diagnostics.csv"))

# 4. Non-antibiogram summary
ab_nv_set <- unique(eltid_ctx$NATUREPVT[!is.na(eltid_ctx$NATUREPVT)])
stopifnot(length(ab_nv_set) == 8462L)

non_ab_nv <- raw_non_ab[!is.na(NATUREPVT) & NATUREPVT != "" & !(NATUREPVT %chin% ab_nv_set), .(
  n_samples = uniqueN(ELTID),
  n_rows = .N,
  top_typeana = {
    tp <- typeana_prefix[!is.na(typeana_prefix)]
    if (length(tp)) {
      tt <- sort(table(tp), decreasing = TRUE)
      paste(sprintf("%s (%d)", names(tt)[seq_len(min(3L, length(tt)))], as.integer(tt)[seq_len(min(3L, length(tt)))]), collapse = "; ")
    } else ""
  },
  top_lblana = {
    lb <- LBLANA[!is.na(LBLANA) & LBLANA != ""]
    if (length(lb)) {
      tt <- sort(table(lb), decreasing = TRUE)
      paste(names(tt)[seq_len(min(2L, length(tt)))], collapse = "; ")
    } else ""
  }
), by = NATUREPVT][order(-n_samples, NATUREPVT)]
fwrite(non_ab_nv, file.path(output, "non_antibiogram_naturepvt_catalog.csv"))

non_ab_typeana <- raw_non_ab[, .(
  n_samples = uniqueN(ELTID),
  n_rows = .N,
  pct_missing_naturepvt = round(100 * mean(is.na(NATUREPVT) | NATUREPVT == ""), 1),
  sample_lblana = paste(head(unique(LBLANA[!is.na(LBLANA) & LBLANA != ""]), 2L), collapse = " | ")
), by = typeana_prefix][order(-n_samples)]
fwrite(non_ab_typeana, file.path(output, "non_antibiogram_typeana_summary.csv"))

non_ab_stats <- list(
  total_non_ab_samples = uniqueN(raw_non_ab$ELTID[!is.na(raw_non_ab$ELTID) & raw_non_ab$ELTID != ""]),
  total_non_ab_rows = nrow(raw_non_ab),
  non_ab_only_distinct_labels = nrow(non_ab_nv),
  non_ab_shared_with_ab_labels = length(intersect(unique(raw_non_ab$NATUREPVT[!is.na(raw_non_ab$NATUREPVT) & raw_non_ab$NATUREPVT != ""]), ab_nv_set)),
  non_ab_missing_nv_rows = sum(is.na(raw_non_ab$NATUREPVT) | raw_non_ab$NATUREPVT == "")
)
rm(raw_non_ab)
invisible(gc())

# 5. Aggregate all 8,462 NATUREPVT labels on antibiogram samples
# 5a. Sample-level counts per NATUREPVT
nv_samples <- eltid_ctx[!is.na(NATUREPVT), .(
  n_samples = .N,
  n_samp_sys_R = sum(order_bucket == "sys_R"),
  n_samp_bgsta_only = sum(order_bucket == "bgsta_only"),
  n_samp_bgsta_cultae = sum(order_bucket == "bgsta_cultae"),
  n_samp_bgstrb = sum(order_bucket == "bgstrb"),
  n_samp_standard_diag = sum(order_bucket == "standard_diag"),
  n_samp_other_R = sum(has_other_R)
), by = NATUREPVT]

# 5b. Isolate-level & SIR-row counts per NATUREPVT (using sample's canonical NATUREPVT or row NATUREPVT)
# Use row NATUREPVT (non-empty) consistent with sample filter on ab_eltids
raw_ab_sir <- raw_ab[!is.na(STRRES) & STRRES %chin% sir_codes & !is.na(NATUREPVT) & NATUREPVT != ""]
raw_ab_sir[, isolate_key := paste(PATID, ELTID, DLVL, sep = "\034")]

nv_isolates <- raw_ab_sir[, .(
  n_isolates = uniqueN(isolate_key),
  n_sir_rows = .N
), by = NATUREPVT]

# Top species per NATUREPVT (counted at isolate level)
iso_sp <- unique(raw_ab_sir[!is.na(IDENTIFICATION) & IDENTIFICATION != "", .(NATUREPVT, isolate_key, IDENTIFICATION)])
sp_counts <- iso_sp[, .(n = .N), by = .(NATUREPVT, IDENTIFICATION)][order(NATUREPVT, -n, IDENTIFICATION)]
nv_top_species <- sp_counts[, .(
  top_species = paste(sprintf("%s (%d)", head(IDENTIFICATION, 3L), head(n, 3L)), collapse = "; ")
), by = NATUREPVT]
rm(iso_sp, sp_counts, raw_ab_sir)

# Top TYPEANA prefixes per NATUREPVT (counted at distinct ELTID-typeana_prefix pairs across all rows of ab_eltids)
elt_tp <- unique(raw_ab[!is.na(NATUREPVT) & NATUREPVT != "" & !is.na(typeana_prefix), .(NATUREPVT, ELTID, typeana_prefix)])
tp_counts <- elt_tp[, .(n = .N), by = .(NATUREPVT, typeana_prefix)][order(NATUREPVT, -n, typeana_prefix)]
nv_top_typeana <- tp_counts[, .(
  top_typeana = paste(sprintf("%s (%d)", head(typeana_prefix, 4L), head(n, 4L)), collapse = "; ")
), by = NATUREPVT]
rm(elt_tp, tp_counts, raw_ab, eltid_ctx)
invisible(gc())

# Merge all metrics for 8,462 labels
cat_dt <- Reduce(function(a, b) merge(a, b, by = "NATUREPVT", all.x = TRUE),
                 list(nv_samples, nv_isolates, nv_top_species, nv_top_typeana))
for (col in c("n_isolates", "n_sir_rows")) {
  cat_dt[is.na(get(col)), (col) := 0L]
}
for (col in c("top_species", "top_typeana")) {
  cat_dt[is.na(get(col)), (col) := ""]
}
setorder(cat_dt, -n_samples, -n_isolates, NATUREPVT)
cat_dt[, rank_samples := seq_len(.N)]
total_nv_samples <- sum(cat_dt$n_samples)
total_nv_isolates <- sum(cat_dt$n_isolates)
cat_dt[, cum_samples := cumsum(n_samples)]
cat_dt[, cum_pct_samples := round(100 * cum_samples / total_nv_samples, 2)]
cat_dt[, pct_samples := round(100 * n_samples / total_nv_samples, 3)]
cat_dt[, pct_sys_R := round(100 * n_samp_sys_R / n_samples, 1)]
cat_dt[, pct_any_screening_order := round(100 * (n_samp_sys_R + n_samp_bgsta_only + n_samp_bgstrb) / n_samples, 1)]

message(sprintf("[Stage 1] Catalog size: %d | Top 50 cum%%: %.2f%% | Top 200 cum%%: %.2f%% | Total non-empty NATUREPVT samples: %d | Isolates: %d",
                nrow(cat_dt), cat_dt$cum_pct_samples[50L], cat_dt$cum_pct_samples[200L],
                total_nv_samples, total_nv_isolates))

# 6. Official Rouen GLIMS Anatomical Origin Codes (Codes enregistrement selon origine anatomique Microbiologie.pdf)
glims_table <- data.table(
  code = c(
    "AB", "ABC", "ABD", "ACA", "AFE", "AIN", "AJ", "ANU", "APP", "ART", "ASC", "AU", "AX",
    "BOS", "BOU", "BRA", "BRO", "CAE", "CAI", "CCH", "CH", "CHO", "CIC", "CIP", "CIPD", "CL", "CLA", "COL", "COLON", "COMB", "CON", "COR", "COU", "CSV",
    "DMA", "DOI", "DOS", "DPI", "DUO", "EDPA", "EDPL", "ENC", "END", "ENM", "EPA", "EST", "EXO", "FE", "FES", "FOE", "FOI", "FRO", "FUR",
    "GAN", "GAS", "GB", "GEC", "GEN", "GET", "GIN", "GL", "GO", "GRL", "HA", "HAN", "HY", "HYP", "IG", "JO", "KT", "KTD",
    "LAMIO", "LAN", "LDOU", "LEV", "LRIN", "MAI", "MAM", "MOI", "MULTI", "NASO", "NEZ",
    "OEI", "OES", "OMB", "OND", "ONO", "ORE", "ORT", "OVA", "P", "PAN", "PAU", "PD", "PHA", "PLA", "PLE", "PLP", "PMA", "POI", "POU", "PRE", "PUS",
    "REC", "SANS", "SIN", "TAL", "TES", "THR", "TRA", "TRO", "ULC", "URE", "VAG", "VE", "VER", "VES", "VI", "VUL", "X"
  ),
  glims_meaning = c(
    "avant bras", "abces", "abdomen", "artere carotide", "artere femorale", "aine", "artere jugulaire", "anus", "appendice", "artere", "artere sous-claviere", "autre", "axillaire",
    "bourse", "bouche", "bras", "bronche", "caecum", "caillot", "cuir chevelu", "cheville", "choledoque", "cicatrice", "sur CIP", "sur CIP avec delai", "canal lacrymal", "clavicule", "col de l'uterus", "colon", "cordon ombilical", "conjonctive", "cornee", "cou", "cul de sac vaginal",
    "dorsale de la main", "doigt", "dos", "dessus du pied", "duodenum", "espace interdigital palmaire", "espace interdigital plantaire", "endocol", "endocarde", "endometre", "epaule", "estomac", "exocol", "femur", "fesse", "foetal(e)", "foie", "front", "furoncle",
    "ganglion", "gastrique", "glandes de Bartholin", "gencive", "genou", "genital non precise", "gros intestin", "gland", "gorge", "grandes levres", "humeur aqueuse", "hanche", "hydrocele", "hypochondre", "intestin grele", "joue", "sur KT", "sur KT avec delai",
    "liquide amniotique", "langue", "liquide de douglas", "levres", "liquide de rincage", "main", "mammelon", "moignon", "multisite (conjonctive/pharynx/nez)", "naso-pharynge", "nez",
    "oeil", "oesophage", "ombilic", "ongle de doigt", "ongle d'orteil", "oreille", "orteil", "ovaires", "peripherique", "panaris", "paupiere", "peripherique avec delai", "pharynx", "placenta", "petites levres", "plante du pied", "paume de la main", "poignet", "poumon", "prepuce", "pus",
    "rectum", "sans", "sinus", "talon", "testicule", "thrombus", "trachee", "trompes", "ulcere", "uretral", "vaginal", "vesicale", "verge", "vesicule", "vitre", "vulve", "inconnue"
  )
)
glims_lookup <- setNames(glims_table$glims_meaning, glims_table$code)

# 7. Deterministic text normalization & structural pre-grouping
norm_ascii <- stri_trans_general(trimws(cat_dt$NATUREPVT), "Latin-ASCII")
norm_ascii <- toupper(norm_ascii)
# Replace apostrophes/punctuation with spaces so "L'AINE", "D'ASCITE", "NOUVEAU-NE" tokenize cleanly
norm_clean <- gsub("[^A-Z0-9]+", " ", norm_ascii)
norm_clean <- trimws(gsub("\\s+", " ", norm_clean))
padded <- paste0(" ", norm_clean, " ")

has_kw <- function(pattern) grepl(pattern, padded, perl = TRUE)

# Match official GLIMS codes present as discrete tokens
match_glims <- function(clean_vec) {
  tokens_list <- strsplit(clean_vec, " ", fixed = TRUE)
  valid_codes <- names(glims_lookup)
  vapply(tokens_list, function(toks) {
    m <- intersect(toks, valid_codes)
    if (length(m)) paste(m, collapse = " ") else ""
  }, character(1))
}

# Assign specimen_prefix in clinical priority order
assign_specimen_prefix <- function(pad, clean) {
  n <- length(clean)
  out <- rep(NA_character_, n)

  set_if_na <- function(mask, val) {
    idx <- is.na(out) & mask
    out[idx] <<- val
  }

  # 1-3 Blood cultures (HEMOCULTURE always takes top precedence over KT/CIP tip!)
  is_hemo <- grepl(" (HEMOCULTURE|HEMOCULTURES|HEMOC|FLACON HEMOC) ", pad) | grepl("^HEMO ", clean)
  is_hemo_kt <- is_hemo & grepl(" (KT|KTD|CATHETER|KAT|KT\\b|CIP|CIPD|CHAMBRE|PICC|MIDLINE|VVC|KTAC|KTA|KTVC|KTP|KTC|DIALYSE|CATH|PORT A CATH|PAC) ", pad)
  is_hemo_periph <- is_hemo & !is_hemo_kt & grepl(" (P|PD|PERIPHERIQUE|PERIPH|VEINE|ARTERIEL|ARTERIELLE|ARTERE|PONCTION VEINEUSE|PLIS? COUDE|PRELEVEMENT PERIPHERIQUE) ", pad)
  set_if_na(is_hemo_kt, "HEMOCULTURE_KT_CIP")
  set_if_na(is_hemo_periph, "HEMOCULTURE_PERIPHERIQUE")
  set_if_na(is_hemo, "HEMOCULTURE_AUTRE")

  # 4-6 Urines vs Urinary catheter material
  is_urines <- grepl(" (URINES|URINE|ECBU|URETEROSTOMIE|NEPHROSTOMIE|CYSTOSTOMIE|BRICKER|PYELOSTOMIE|VESICALE) ", pad) | clean %in% c("VE", "VESICALE")
  is_urines_device <- is_urines & grepl(" (SONDE|SONDAGE|NEPHROSTOMIE|CYSTOSTOMIE|BRICKER|PYELOSTOMIE|JJ|URETEROSTOMIE|COLLECTEUR|POCHE|SAD|SU|SV|KOCK|MITROFANOFF|ETUI PENIEN|PENILEX|VE) ", pad)
  is_urinary_mat <- !is_urines & grepl(" SONDE (URINAIRE|VESICALE|JJ|DOUBLE J|NEPHROSTOMIE|URETERALE) ", pad)
  set_if_na(is_urines_device, "URINES_SONDE_DISPOSITIF")
  set_if_na(is_urines, "URINES_STANDARD_JET")
  set_if_na(is_urinary_mat, "SONDE_MATERIEL_URINAIRE")

  # 7 Intravascular devices (excluding urinary, epidural/LCR catheters, bronchial protected KT)
  is_kt_excluded <- grepl(" (URIN|VESIC|GASTRI|NASO|PERIDURAL|RACHI|INTRA THECAL|VENTRICUL|DVE|BRONCH|PROTEGE|PLASTIE|CHOLANGIO) ", pad)
  is_cip <- !is_kt_excluded & grepl(" (CIP|CIPD|CHAMBRE IMPLANTABLE|CHAMBRE A CATHETER|PORT A CATH|PAC|SITE IMPLANTABLE) ", pad)
  is_iv_kt <- !is_kt_excluded & !is_cip & grepl(" (CATHETER|KT|KTD|PICC|MIDLINE|VVC|KTC|KTVC|KTA|KTAC|KTP|KTAD|DESILET|BOUT DE KT|ABLATION KT|ARTERE CAROTIDE|ACA|AFE|AJ|ASC|SWAN) ", pad)
  set_if_na(is_cip, "DISPOSITIF_CIP")
  set_if_na(is_iv_kt, "DISPOSITIF_KT_VASCULAIRE")

  # 8-17 Sterile & Body Fluids / Drains / Neonatal
  set_if_na(grepl(" (LCR|LIQUIDE CEPHALO|CEPHALO RACHIDIEN|CEPHALORACHIDIEN|PONCTION LOMBAIRE|DVE|DERIVATION VENTRICULAIRE|VENTRICULAIRE EXTERNE|SHUNT|VALVE DERIVATION) ", pad) & grepl(" (LCR|LIQUIDE|DVE|PONCTION|SHUNT|CEPHALO|RACHI|VENTRICUL) ", pad), "LCR_DVE")
  set_if_na(grepl(" (PLEURAL|PLEURALE|PLEVRE|EPANCHEMENT PLEURAL|EMPYEME PLEURAL|THORACENTESE) ", pad) & !grepl(" (BIOPSIE|TISSU|PAROI) ", pad), "LIQUIDE_PLEURAL")
  set_if_na(grepl(" (ARTICULAIRE|SYNOVIAL|SYNOVIALE|PONCTION ARTICULAIRE|ARTHROCENTESE|HYDARTHROSE) ", pad) | grepl(" LIQUIDE (DE |DU |D |)(GENOU|HANCHE|CHEVILLE|EPAULE|COUDE|POIGNET) ", pad), "LIQUIDE_ARTICULAIRE_SYNOVIAL")
  set_if_na(grepl(" (ASCITE|DIALYSE PERITONEALE|DIALYSE PERITON|DPCA|LIQUIDE D ASCITE) ", pad), "LIQUIDE_ASCITE_DP")
  set_if_na(grepl(" (LIQUIDE PERITONEAL|EPANCHEMENT PERITONEAL|LDOU|DOUGLAS|LIQUIDE PERICARDIQUE|PERICARDE|PERICARDITE|BILE|BILIAIRE|CHOLEDOQUE|CHO|VESICULE BILIAIRE|PANCREATIQUE|WIRSUNG) ", pad) & !grepl(" (BIOPSIE|TISSU) ", pad), "LIQUIDE_PERITONEAL_PERICARDE_BILE")
  set_if_na(grepl(" (HUMEUR VITREE|VITRE|HUMEUR AQUEUSE|CHAMBRE ANTERIEURE|PONCTION VITRE) ", pad) | clean %in% c("HA", "VI"), "LIQUIDE_OCULAIRE")
  set_if_na(grepl(" (LIQUIDE DE RINCAGE|LRIN|LIQUIDE RINCAGE|LIQUIDE CONSERVATION|LIQUIDE DE CONSERVATION|PRESERVATION|GREFFON|TRANSPORT GREFFON) ", pad) | grepl("^LRIN ", clean), "LIQUIDE_RINCAGE_CONSERVATION")
  set_if_na(grepl(" (LIQUIDE AMNIOTIQUE|LAMIO|LIQUIDE GASTRIQUE|GAS|MECONIUM|CORDON OMBILICAL|COMB|PLACENTA|PLA|MULTI|MULTISITE|FOE|FOETAL|FOETALE|FOETUS) ", pad) & !grepl(" BIOPSIE ", pad), "NOUVEAU_NE_MATERNO_FOETAL")
  set_if_na(grepl(" (DRAIN|REDON|LAME|ASPIRATION DRAIN|LIQUIDE DRAIN|POCHE DRAIN) ", pad) & !grepl(" (URIN|NEPHRO|CYSTO) ", pad), "LIQUIDE_DRAIN_REDON")

  # 18-19 Respiratory (Protected vs Non-Protected)
  set_if_na(grepl(" (LBA|LAVAGE BRONCHO|LAVAGE ALVEOLAIRE|BRONCHO ALVEOLAIRE|PDP|PBDP|PRELEVEMENT DISTAL PROTEGE|PRELEVEMENT BRONCHIQUE DISTAL|BROSSE|KT PROTEGE|CATHETER PROTEGE|COMBIPROTECT|LBA +BRO) ", pad), "RESPIRATOIRE_PROTEGE")
  set_if_na(grepl(" (EXPECTORATION|EXPECTO|EXP|CRACHAT|ECBC|ASPIRATION BRONCHIQUE|ASPIRATION TRACHEALE|ASPIRATION ENDOTRACHEALE|ASPIRATION TRACHEO|ASPIRATION PHARYNGEE|ASPIRATION PHARYNGE|ASP PHARYNGEE|ASPI PHARYNGEE|ASP PHARYNGE|SECRETION BRONCHIQUE|SECRETIONS BRONCHIQUES|SONDE INTUBATION|CANULE TRACHEOTOMIE|TRACHEOTOMIE|ASPIRATION NASO|NASOPHARYNGE|NASO PHARYNGE|RHINOPHARYNGE|MUCOVISIDOSE|NASO|BRO|TRA|POU) ", pad), "RESPIRATOIRE_NON_PROTEGE")

  # 19b Cardiac Assist / LVAD / Pacemaker / Neuromodulator Hardware
  set_if_na(grepl(" (ASSISTANCE CIRCULATOIRE|HEART MATE|HEARTMATE|HTM|LVAD|PACEMAKER|PACE MAKER|DEFIBRILLATEUR|LOGE PACE|BOITIER PACE|ELECTRODE|NEUROSTIMULATEUR|POMPE INTRATHECALE) ", pad), "MATERIEL_ASSISTANCE_CARDIAQUE_IMPLANT")

  # 20-23 Abscesses/Fistulas vs Deep Biopsies/Bone/Prostheses vs Pus vs Wounds
  # Check perianal abscess/fistula explicitly BEFORE anything else on rectum/anus!
  is_abces_fistule <- grepl(" (ABCES|ABC|FISTULE|PHLEGMON|EMPYEME|FURONCLE|FUR|PANARIS|PAN|COLLECTION PURULENTE|SUPPURATION) ", pad)
  is_biopsie_profond <- grepl(" (BIOPSIE|BIO|OS|OSSEUX|OSSEUSE|OSTEITE|SPONDYLODISCITE|DISQUE|VERTEBRE|EPINEUSE|METATARSIEN|METATARSE|META|PHALANGE|CALCANEUM|TIBIA|PERONE|FEMUR|HUMERUS|RADIUS|CUBITUS|COTYLE|TROCHANTER|SACRUM|STERNAL|STERNUM|STERNOTOMIE|STERNO|VOLET CRANIEN|ISCHION|BOURRE D ALESAGE|ALESAGE|RECOUPE|TRANCHE OSSEUSE|SEQUESTRE|FAUSSE MEMBRANE|FAUSSES MEMBRANES|PSEUDO MEMBRANE|TISSU|FRAGMENT|PIECE OPERATOIRE|CURETAGE|NECROSECTOMIE|VALVE|ENDOCARDE|END|THROMBUS|THR|CAILLOT|CAI|PROTHESE|MATERIEL|OSTEOSYNTHESE|CLOU|PLAQUE|VIS|BROCHE|GREFFE|AORTE|ARTERE|GANGLION|GAN|LAMELL|MENISQUE|TENDON|LIGAMENT|GAINE|PERIOSTE|CORNEE|COR|MOELLE OSSEUSE|CAPSULE ARTICULAIRE|SYNOVIALE) ", pad)
  is_pus <- grepl(" (PUS) ", pad)
  is_liquide <- grepl(" (LIQUIDE|PONCTION|HEMATOME|SEROME|LYMPHOCELE|KYSTE|EPANCHEMENT|COLLECTION) ", pad)
  is_plaie <- grepl(" (PLAIE|ULCERE|ULC|ESCARRE|BRULURE|CICATRICE|CIC|MOIGNON|MOI|NECROSE|GANGRENE|DESUNION|MAL PERFORANT|MPH|SCARIFICATION|PHLYCTENE|VESICULE|BULLE) ", pad)

  set_if_na(is_abces_fistule & is_biopsie_profond, "BIOPSIE_OU_ABCES_PROFOND")
  set_if_na(is_abces_fistule, "ABCES_FISTULE_PHLEGMON")
  set_if_na(is_liquide, "LIQUIDE_PONCTION_COLLECTION")
  set_if_na(is_biopsie_profond, "BIOPSIE_OS_TISSU_MATERIEL_PROFOND")
  set_if_na(is_pus, "PUS")
  set_if_na(is_plaie, "PLAIE_ULCERE_ESCARRE")

  # 24 Stools / Coproculture (when not screening swab)
  set_if_na(grepl(" (SELLES|COPROCULTURE|COPRO|FECES|RECTORRAGIE) ", pad), "COPROCULTURE_SELLES")

  # 25 Genital
  set_if_na(grepl(" (VAGINAL|VAGIN|VAG|ENDOCOL|ENC|EXOCOL|EXO|COL UTERUS|COL UTERIN|CUL DE SAC|CSV|VULVE|VUL|VULVAIRE|GRANDES LEVRES|PETITES LEVRES|GRL|PLE|BARTHOLIN|GB|LOCHIES|ENDOMETRE|ENM|STERILET|DIU|URETRAL|URETRE|URE|SPERME|SPERMOCULTURE|GLAND|PREPUCE|PRE|VERGE|VER|PROSTATE|PROSTATIQUE|BOS|BOURSE|TESTICULE|TES|EPIDIDYME|TROMPE|TRO|OVAIRE|OVA|GET|GENITAL|PAPILLON|BARTHOLINITE) ", pad) | grepl("^COL ", clean), "GENITAL")

  # 26 Explicit screening / carriage sites (NO abscess/pus/biopsy/plaie!)
  set_if_na(grepl(" (DEPISTAGE|BMR|BHRE|BLSE|SARM|ERV|CARBA|PORTAGE) ", pad), "DEPISTAGE_EXPLICITE")
  set_if_na(grepl(" (RECTAL|RECTUM|REC|ANUS|ANU|MARGE ANALE|PERIANAL|PERI ANAL|ANAL) ", pad), "SITE_RECTUM_ANUS_SANS_ABCES")
  set_if_na(grepl(" (NEZ|NARINE|NARINES|NASAL|NASALE|FOSSES? NASALES?) ", pad), "SITE_NEZ_NARINE")
  set_if_na(grepl(" (AISSELLE|AISSELLES|AXILLAIRE|CREUX AXILLAIRE|AX) ", pad), "SITE_AISSELLE")
  set_if_na(grepl(" (AINE|AIN|PLI INGUINAL|PLIS INGUINAUX|INGUINAL|INGUINALE) ", pad), "SITE_AINE")
  set_if_na(grepl(" (GORGE|GO|PHARYNX|PHA|AMYGDALE|AMYGDALES|OROPHARYNX) ", pad), "SITE_GORGE_PHARYNX")

  # 27 ENT & Ophthalmology
  set_if_na(grepl(" (OREILLE|ORE|OTITE|OTORRHEE|CONDUIT AUDITIF|CAE |TYMPAN|MASTOIDE|SINUS|SIN|ETHMOIDE|MAXILLAIRE SINUS) ", pad), "ORL_OREILLE_SINUS")
  set_if_na(grepl(" (BOUCHE|BOU|LANGUE|LAN|GENCIVE|GEC|DENT|DENTAIRE|PALAIS|JOUES?|JO|LEVRES?|LEV) ", pad), "ORL_BOUCHE_DENTAIRE")
  set_if_na(grepl(" (OEIL|OEI|OCULAIRE|CONJONCTIVE|CON|PAUPIERE|PAU|CANAL LACRYMAL|CL|LENTILLE|BOITIER LENTILLE|ORGELET|CHALAZION) ", pad), "OPHTALMO_SUPERFICIEL")

  # 28 Bare GLIMS / unknown / laterality-only codes
  set_if_na(clean %in% c("X", "INCONNUE", "INCONNU", "SANS", "AU", "AUTRE", "AUTRES", "NON PRECISE", "NON RENSEIGNE", "NR", "NP", "PRELEVEMENT", "ECOUVILLON", "ECOUVILLONNAGE", "SANS OBJET", "DIVERS", "MATERIEL", "DROIT", "DROITE", "GAUCHE", "BILATERAL", "BILATERALE", "D", "G", "DT", "GCH"), "INCONNU_SANS_AUTRE")

  # 29 Catch-all anatomical / superficial swab / tissue
  set_if_na(rep(TRUE, n), "CUTANE_OU_ANATOMIQUE_AUTRE")
  out
}

assign_anatomical_site <- function(pad, clean) {
  n <- length(clean)
  out <- rep(NA_character_, n)
  set_if_na <- function(mask, val) {
    idx <- is.na(out) & mask
    out[idx] <<- val
  }

  set_if_na(grepl(" (MARGE ANALE|ANUS|ANU|RECTUM|RECTAL|REC|PERIANAL|PERI ANAL|ANO PERINEAL|ANO PERINEALE|PARARECTAL|PARA RECTAL|SPHINCTER|FESSE|FES|SILLON INTERFESSIER|INTERFESSIER|PILONIDAL|SACRUM|SACRE|SACREE|COCCYX|PERINEE|PERINEAL) ", pad), "PERIANAL_RECTAL_GLUTEAL")
  set_if_na(grepl(" (NEZ|NARINE|NARINES|NASAL|NASALE|FOSSES? NASALES?|NASOPHARYNGE|NASO|SINUS|SIN|RHINO) ", pad), "NASAL_SINUS")
  set_if_na(grepl(" (AISSELLE|AXILLAIRE|CREUX AXILLAIRE|AX) ", pad), "AXILLARY")
  set_if_na(grepl(" (AINE|AIN|INGUINAL|INGUINALE|PLI INGUINAL|SCARPA) ", pad), "INGUINAL")
  set_if_na(grepl(" (GORGE|GO|PHARYNX|PHA|AMYGDALE|BOUCHE|BOU|LANGUE|LAN|GENCIVE|GEC|DENT|OREILLE|ORE|OTORRHEE|CONDUIT AUDITIF|TYMPAN|MASTOIDE|PAROTIDE) ", pad), "ENT_ORAL")
  set_if_na(grepl(" (OEIL|OEI|CONJONCTIVE|CON|CORNEE|COR|PAUPIERE|PAU|VITRE|VI|HA|HUMEUR AQUEUSE|LACRYMAL|CL|LENTILLE) ", pad), "OCULAR")
  set_if_na(grepl(" (LCR|CERVEAU|CEREBRAL|CEREBRALE|MENINGE|RACHIS|RACHIDIEN|VERTEBR|EPINEUSE|MEDULLAIRE|SPINAL|CRANE|VOLET CRANIEN|CCH|CUIR CHEVELU|FRONT|FRO|DVE|EPIDURAL) ", pad), "CNS_SPINE_HEAD")
  set_if_na(grepl(" (URINE|URINES|ECBU|VESICAL|VESICALE|VESSIE|VE|RENAL|REIN|NEPHRO|URETER|URETEROSTOMIE|BRICKER|PYELO|CYSTO) ", pad), "URINARY_TRACT")
  set_if_na(grepl(" (CIP|CIPD|CHAMBRE IMPLANTABLE|PORT A CATH|PAC|SITE IMPLANTABLE) ", pad), "VASCULAR_CIP")
  set_if_na(grepl(" (KT|KTD|CATHETER|PICC|MIDLINE|VVC|KTC|KTVC|KTA|KTAC|KTP|VEINE|ARTERE|ACA|AFE|AJ|ASC|ARTERIEL|AORTE|ENDOCARDE|END|VALVE CARDIAQUE|ASSISTANCE CIRCULATOIRE|HEART MATE|HEARTMATE|HTM|LVAD|PACEMAKER|PACE MAKER|DEFIBRILLATEUR|PERICARDE|PERIPHERIQUE|P|PD) ", pad), "VASCULAR_KT_PERIPH_CARDIAC")
  set_if_na(grepl(" (PLEURAL|PLEVRE|POUMON|POU|BRONCH|BRO|TRACHE|TRA|LBA|PDP|PBDP|MUCOVISIDOSE|ALVEOLAIRE|THORAX|THORACIQUE|MEDIASTIN|PAROI THORACIQUE|STERNUM|STERNAL|STERNOTOMIE|STERNO|COTES?|SEIN|MAMELON|MAM|MAMMAIRE) ", pad), "THORAX_BREAST_LUNG")
  set_if_na(grepl(" (ASCITE|ABDOMEN|ABD|PERITONEAL|PERITOINE|PERITON|FOIE|FOI|HEPAT|BILE|BILIAIRE|CHOLEDOQUE|CHO|VESICULE|VES|PANCREAS|PANCREATIQUE|RATE|SPLENIQUE|ESTOMAC|EST|GASTRIQUE|GAS|DUODENUM|DUO|GRELE|IG|COLON|CAE|CAECUM|APPENDICE|APP|GIN|DOUGLAS|LDOU|OMBILIC|OMB|PAROI ABDOMINALE|HYPOCHONDRE|HYP|FLANC|FOSSE ILIAQUE) ", pad), "ABDOMINAL_DIGESTIVE_HEPATOBILIARY")
  set_if_na(grepl(" (VAGIN|VAGINAL|VAG|ENDOCOL|ENC|EXOCOL|EXO|COL |CSV|VULVE|VUL|GRL|PLE|BARTHOLIN|GB|LOCHIES|ENDOMETRE|ENM|UTERUS|UTERIN|STERILET|TROMPE|TRO|OVAIRE|OVA|PELVIEN|PELVIS|URETRAL|URETRE|URE|SPERME|GLAND|PREPUCE|PRE|VERGE|VER|PROSTATE|BOS|TESTICULE|TES|HY|GENITAL|GET) ", pad), "GENITOURINARY_PELVIC")
  set_if_na(grepl(" (PLACENTA|PLA|AMNIOTIQUE|LAMIO|CORDON|COMB|FOETAL|FOE|NOUVEAU NE|MULTI|MECONIUM) ", pad), "OBSTETRIC_NEONATAL")
  set_if_na(grepl(" (OS|OSSEUX|OSSEUSE|GENOU|GEN|HANCHE|HAN|COTYLE|TROCHANTER|FEMUR|FE|TIBIA|PERONE|CALCANEUM|CHEVILLE|CH|PIED|PLP|DPI|METATARSE|METATARSIEN|META|HALLUX|ORTEIL|ORT|ONO|EDPL|TALON|TAL|JAMBE|CUISSE|MOLLET|ROTULE|ARTICULAIRE|SYNOVIAL|PROTHESE|PTH|PTG|OSTEOSYNTHESE|MOIGNON|MOI) ", pad), "LOWER_LIMB_OSTEOARTICULAR")
  set_if_na(grepl(" (BRAS|BRA|AVANT BRAS|AB|EPAULE|EPA|CLAVICULE|CLA|COUDE|POIGNET|POI|MAIN|MAI|PMA|DMA|DOIGT|DOI|OND|EDPA|PANARIS|PAN|HUMERUS|RADIUS|CUBITUS|POUCE|INDEX|MAJEUR|ANNULAIRE|AURICULAIRE) ", pad), "UPPER_LIMB_HAND")
  set_if_na(grepl(" (SOUS CUTANE|SOUS CUTANEE|S CUTANE|COU|CERVICAL|THYROIDE|CAROTIDE|VISAGE|FACE|JOUE|JO|MENTON|TEMPE|DOS|LOMBAIRE|DORSAL|CICATRICE|CIC|GREFFE|PEAU|CUTANE) ", pad), "HEAD_TRUNK_SKIN")

  set_if_na(rep(TRUE, n), "UNSPECIFIED_OR_OTHER")
  out
}

cat_dt[, norm_ascii := norm_ascii]
cat_dt[, norm_clean := norm_clean]
cat_dt[, glims_codes := match_glims(norm_clean)]
cat_dt[, specimen_prefix := assign_specimen_prefix(padded, norm_clean)]
cat_dt[, anatomical_site := assign_anatomical_site(padded, norm_clean)]

# Sub-pattern refinement inside large catch-all buckets so heterogeneous terms never share one family
assign_sub_pattern <- function(prefix, anat, pad, clean) {
  sub <- rep("MAIN", length(prefix))
  # Distinguish swab vs biopsy/puncture vs unspecified inside generic anatomical or pus/wound groups
  has_ecouv <- grepl(" (ECOUVILLON|ECOUVILLONNAGE|ECOUV|FROTTIS) ", pad)
  has_ponc <- grepl(" (PONCTION|LIQUIDE|ASPIRATION) ", pad)
  has_prof <- grepl(" (PROFOND|PROFONDE|INTERNE|PER OPERATOIRE|PEROPERATOIRE|CHIRURGICAL|CHIRURGICALE|OPERATOIRE) ", pad)
  has_sup <- grepl(" (SUPERFICIEL|SUPERFICIELLE|CUTANE|CUTANEE|PEAU) ", pad)
  sub[has_prof] <- "DEEP_OR_SURGICAL"
  sub[!has_prof & has_ponc] <- "PUNCTURE_FLUID"
  sub[!has_prof & !has_ponc & has_sup] <- "SUPERFICIAL"
  sub[!has_prof & !has_ponc & !has_sup & has_ecouv] <- "SWAB"

  # Within SITE_RECTUM_ANUS_SANS_ABCES, separate bare single codes (REC, ANU, RECTUM, ANUS) from MARGE ANALE / ECOUVILLON RECTAL
  idx_rec <- prefix == "SITE_RECTUM_ANUS_SANS_ABCES"
  sub[idx_rec & clean %in% c("REC", "ANU", "RECTUM", "ANUS")] <- "BARE_RECTUM_ANUS"
  sub[idx_rec & grepl(" (DEPISTAGE|ECOUVILLON|ECOUVILLONNAGE|PORTEUR|PORTAGE) ", pad)] <- "SWAB_OR_SCREENING"
  sub[idx_rec & grepl(" (MARGE ANALE) ", pad)] <- "MARGE_ANALE"

  # Within GENITAL, separate clearly screening/vaginal vs male/urethral vs deep/IUD
  idx_gen <- prefix == "GENITAL"
  sub[idx_gen & grepl(" (VAGINAL|VAG|ENDOCOL|ENC|EXOCOL|EXO|COL |CSV|VULVE|VUL|GRL|PLE) ", pad)] <- "FEMALE_SWAB_TRACT"
  sub[idx_gen & grepl(" (LOCHIES|ENDOMETRE|ENM|STERILET|DIU|BARTHOLIN|GB|TROMPE|TRO|OVAIRE|OVA) ", pad)] <- "FEMALE_DEEP_OR_DEVICE"
  sub[idx_gen & grepl(" (URETRAL|URETRE|URE|SPERME|GLAND|PREPUCE|PRE|VERGE|VER|PROSTATE|BOS|TES) ", pad)] <- "MALE_URETHRAL_GENITAL"

  # Within ABCES_FISTULE_PHLEGMON, keep PANARIS / FURONCLE apart from deep/abdominal/perianal
  idx_abc <- prefix == "ABCES_FISTULE_PHLEGMON"
  sub[idx_abc & grepl(" (PANARIS|PAN|FURONCLE|FUR|HIDROSADENITE) ", pad)] <- "SUPERFICIAL_BOIL_WHITLOW"
  sub[idx_abc & grepl(" (FISTULE) ", pad)] <- "FISTULA"

  # Within URINES_SONDE_DISPOSITIF, separate nephrostomy/Bricker/suprapubic from indwelling bladder catheter
  idx_urs <- prefix == "URINES_SONDE_DISPOSITIF"
  sub[idx_urs & grepl(" (NEPHROSTOMIE|CYSTOSTOMIE|BRICKER|PYELOSTOMIE|URETEROSTOMIE|JJ) ", pad)] <- "NEPHRO_BRICKER_CYSTO"

  # Within CUTANE_OU_ANATOMIQUE_AUTRE, separate bare short tokens (<=4 chars or single word) from compound descriptions
  idx_oth <- prefix == "CUTANE_OU_ANATOMIQUE_AUTRE"
  is_bare <- nchar(clean) <= 5L & !grepl(" ", clean, fixed = TRUE)
  sub[idx_oth & is_bare] <- paste0("BARE_", clean[idx_oth & is_bare])

  # Within ABCES_FISTULE, BIOPSIE, LIQUIDE_DRAIN, PUS, PLAIE, keep top anatomical buckets clean
  sub
}

cat_dt[, sub_pattern := assign_sub_pattern(specimen_prefix, anatomical_site, padded, norm_clean)]
cat_dt[, family_key := paste(specimen_prefix, anatomical_site, sub_pattern, sep = "::")]

# Assign deterministic sequential family_id ordered by total sample volume descending
fam_agg <- cat_dt[, .(
  n_labels = .N,
  n_samples = sum(n_samples),
  n_isolates = sum(n_isolates),
  n_sir_rows = sum(n_sir_rows),
  n_samp_sys_R = sum(n_samp_sys_R),
  n_samp_bgsta_only = sum(n_samp_bgsta_only),
  n_samp_bgsta_cultae = sum(n_samp_bgsta_cultae),
  n_samp_bgstrb = sum(n_samp_bgstrb),
  n_samp_standard_diag = sum(n_samp_standard_diag),
  n_samp_other_R = sum(n_samp_other_R)
), by = .(family_key, specimen_prefix, anatomical_site, sub_pattern)]

setorder(fam_agg, -n_samples, -n_labels, family_key)
fam_agg[, family_id := sprintf("FAM_%03d", seq_len(.N))]
fam_agg[, pct_samples := round(100 * n_samples / total_nv_samples, 3)]
fam_agg[, cum_pct_samples := round(100 * cumsum(n_samples) / total_nv_samples, 2)]
fam_agg[, pct_sys_R := round(100 * n_samp_sys_R / n_samples, 1)]
fam_agg[, pct_any_screening_order := round(100 * (n_samp_sys_R + n_samp_bgsta_only + n_samp_bgstrb) / n_samples, 1)]

cat_dt <- merge(cat_dt, fam_agg[, .(family_key, family_id)], by = "family_key", all.x = TRUE)
setorder(cat_dt, rank_samples)

message(sprintf("[Stage 1] Formed %d families covering %d labels.", nrow(fam_agg), nrow(cat_dt)))

# Compute internal heterogeneity flag per family (for labels with >=10 samples diverging >=25pp in pct_any_screening_order)
fam_stats_rich <- merge(
  fam_agg,
  cat_dt[, .(
    top_glims_codes = paste(head(unique(unlist(strsplit(glims_codes[glims_codes != ""], " "))), 6L), collapse = " "),
    rep_labels = paste(sprintf("%s (%d)", head(NATUREPVT, 6L), head(n_samples, 6L)), collapse = " | "),
    has_internal_heterogeneity = {
      sub <- .SD[n_samples >= 10L]
      if (nrow(sub) >= 2L) (max(sub$pct_any_screening_order) - min(sub$pct_any_screening_order)) >= 25.0 else FALSE
    },
    pct_spread_within = {
      sub <- .SD[n_samples >= 10L]
      if (nrow(sub) >= 2L) round(max(sub$pct_any_screening_order) - min(sub$pct_any_screening_order), 1) else 0.0
    }
  ), by = family_id],
  by = "family_id",
  all.x = TRUE
)
setorder(fam_stats_rich, -n_samples, family_id)

# Write complete pre-grouped tables
fwrite(cat_dt, file.path(output, "catalog_8462_pregrouped.csv"))
fwrite(fam_stats_rich, file.path(output, "families_pregrouped.csv"))

# Build Stage 1 metadata JSON (to carry counts cleanly into Stage 3)
stage1_meta <- list(
  rows_raw = rows_raw,
  total_distinct_eltid = total_distinct_eltid,
  total_ab_samples = total_ab_samples,
  total_distinct_naturepvt_incl_empty = total_distinct_naturepvt_incl_empty,
  total_distinct_naturepvt_nonempty = total_distinct_naturepvt_nonempty,
  n_ab_missing_nv = n_ab_missing_nv,
  n_ab_multi_nv = n_ab_multi_nv,
  ab_distinct_labels = nrow(cat_dt),
  total_nv_samples = total_nv_samples,
  total_nv_isolates = total_nv_isolates,
  top50_cum_pct = cat_dt$cum_pct_samples[50L],
  top200_cum_pct = cat_dt$cum_pct_samples[200L],
  n_families = nrow(fam_stats_rich),
  non_ab_stats = non_ab_stats
)
writeLines(toJSON(stage1_meta, auto_unbox = TRUE, pretty = TRUE),
           file.path(output, "stage1_metadata.json"), useBytes = TRUE)

# Export balanced shards (~35-45 families per shard, interspersed or ordered cleanly into 8 shards)
n_shards <- 8L
fam_order <- seq_len(nrow(fam_stats_rich))
# Round-robin assignment by sample rank so every shard gets both heavy and tail families
shard_idx <- ((fam_order - 1L) %% n_shards) + 1L

for (s in seq_len(n_shards)) {
  f_ids <- fam_stats_rich$family_id[shard_idx == s]
  shard_items <- lapply(f_ids, function(fid) {
    frow <- fam_stats_rich[family_id == fid]
    lrows <- cat_dt[family_id == fid][order(-n_samples, NATUREPVT)]
    top_n <- head(lrows, 15L)
    tail_samples <- if (nrow(lrows) > 15L) head(lrows$NATUREPVT[-seq_len(15L)], 10L) else character(0)
    list(
      family_id = frow$family_id,
      specimen_prefix = frow$specimen_prefix,
      anatomical_site = frow$anatomical_site,
      sub_pattern = frow$sub_pattern,
      n_labels = frow$n_labels,
      n_samples = frow$n_samples,
      n_isolates = frow$n_isolates,
      pct_samples = frow$pct_samples,
      n_samp_sys_R = frow$n_samp_sys_R,
      n_samp_bgsta_only = frow$n_samp_bgsta_only,
      n_samp_bgsta_cultae = frow$n_samp_bgsta_cultae,
      n_samp_bgstrb = frow$n_samp_bgstrb,
      n_samp_standard_diag = frow$n_samp_standard_diag,
      n_samp_other_R = frow$n_samp_other_R,
      pct_sys_R = frow$pct_sys_R,
      pct_any_screening_order = frow$pct_any_screening_order,
      has_internal_heterogeneity = frow$has_internal_heterogeneity,
      pct_spread_within = frow$pct_spread_within,
      top_glims_codes = frow$top_glims_codes,
      top_labels = lapply(seq_len(nrow(top_n)), function(i) {
        r <- top_n[i]
        list(
          naturepvt = r$NATUREPVT,
          rank = r$rank_samples,
          n_samples = r$n_samples,
          n_isolates = r$n_isolates,
          pct_sys_R = r$pct_sys_R,
          pct_any_screening_order = r$pct_any_screening_order,
          n_samp_bgsta_only = r$n_samp_bgsta_only,
          n_samp_bgsta_cultae = r$n_samp_bgsta_cultae,
          n_samp_bgstrb = r$n_samp_bgstrb,
          top_typeana = r$top_typeana,
          top_species = r$top_species
        )
      }),
      more_example_labels = as.list(tail_samples)
    )
  })
  shard_path <- file.path(output, "shards", sprintf("shard_%02d.json", s))
  writeLines(toJSON(shard_items, auto_unbox = TRUE, pretty = TRUE), shard_path, useBytes = TRUE)
  message(sprintf("[Stage 1] Wrote %s (%d families)", basename(shard_path), length(shard_items)))
}

message("[Stage 1] Done.")
