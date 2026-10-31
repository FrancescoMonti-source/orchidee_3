# THROWAWAY: draft a local review of the label catalogue already explored.
# Does not apply decisions, edit the source data or regenerate resistance rates.
script <- sub("^--file=", "", commandArgs()[grepl("^--file=", commandArgs())])
root <- normalizePath(file.path(dirname(normalizePath(script)), "../../.."), winslash = "/")
output <- file.path(root, "outputs/amr-classification-prototype")
.libPaths(c(file.path(output, "R_libs"), .libPaths()))
payload <- jsonlite::fromJSON(file.path(output, "summary.json"))
stopifnot(as.character(packageVersion("AMR")) == payload$metadata$versions$AMR)
review <- payload$analyses[, c("local_label", "result_rows", "amr_code", "amr_name")]
review$action <- ifelse(is.na(review$amr_code), "Local meaning needed", "Retain AMR candidate")
review$proposed_code <- review$amr_code
review$qualifier <- ""
review$note <- "Candidate retained for review; not a validation decision."

# Explicit proposals, not keyword rules. Qualifiers never imply a sample type
# or an infection diagnosis and are not used to reinterpret the recorded result.
corrections <- as.data.frame(do.call(rbind, list(
  c("TEICOPLANINE", "TEC", "", "Correct the proposed molecule to teicoplanin."),
  c("PENICILLINE G", "PEN", "", "Correct the proposed molecule to benzylpenicillin."),
  c("PENI G MENINGITE", "PEN", "MENINGITE", "Keep the recorded interpretation context separately."),
  c("PENI G AUTRES CONTEXTES", "PEN", "AUTRES CONTEXTES", "Keep the recorded interpretation context separately."),
  c("AUGMENTIN CYSTITE", "AMC", "CYSTITE", "Propose amoxicillin/clavulanic acid; preserve the recorded context."),
  c("AUGMENTIN AUTRES CONTEXTES", "AMC", "AUTRES CONTEXTES", "Propose amoxicillin/clavulanic acid; preserve the recorded context."),
  c("CLAVENTIN", "TCC", "", "Propose ticarcillin/clavulanic acid, consistent with the existing local dictionary; check the trade-name mapping."),
  c("FOSFOMYCINE TROMETAMOL", "FOS", "TROMETAMOL", "Preserve the formulation qualifier; keep it distinguishable from the IV-labelled test."),
  c("PIPERA TAZO", "TZP", "", "Propose piperacillin/tazobactam; clarify the local test format separately."),
  c("GENTAMICINE FORTE", "GEH", "FORTE", "AMR has a gentamicin-high identity; confirm that the local label denotes that assay."),
  c("GENTAMICINE FORTE.", "GEH", "FORTE", "Same candidate assay identity; preserve the original label."),
  c("CEFOTAXIME AUTRES CONTEXTES", "CTX", "AUTRES CONTEXTES", "The context qualifier is not a cefotaxime screening-test identity."),
  c("CEFOTAXIME MENINGITE", "CTX", "MENINGITE", "The context qualifier is not a cefotaxime screening-test identity."),
  c("CETRIAXONE AUTRES CONTEXTES", "CRO", "AUTRES CONTEXTES", "Propose ceftriaxone for the apparent spelling variant; no inhibitor combination is specified."),
  c("CEFTRIAXONE MENINGITE", "CRO", "MENINGITE", "Retain the molecule and preserve the recorded interpretation context."),
  c("AMOX MENINGITE", "AMX", "MENINGITE", "Propose amoxicillin, not a cefoxitin screening test."),
  c("AMPI AUTRES CONTEXTES", "AMP", "AUTRES CONTEXTES", "Propose ampicillin, not a beta-lactamase screening test."),
  c("AMOX VO", "AMX", "VO", "Retain the molecule and the source qualifier."),
  c("FOSFOMYCINE IV", "FOS", "IV", "Retain the molecule and keep the IV test distinguishable from trometamol."),
  c("CLOXA 250", "CLO", "250", "AMR identifies cloxacillin; the legacy mapping says oxacillin. Clarify the assay qualifier and any surrogate use separately."),
  c("CLOXA 500", "CLO", "500", "Retain cloxacillin as the molecule candidate; clarify the assay qualifier and any surrogate use separately.")
)), stringsAsFactors = FALSE)
names(corrections) <- c("local_label", "proposed_code", "qualifier", "note")
idx <- match(corrections$local_label, review$local_label)
stopifnot(!anyNA(idx))
review$action[idx] <- ifelse(!is.na(review$amr_code[idx]) & review$amr_code[idx] == corrections$proposed_code,
                            "Retain code; preserve qualifier", "Propose code correction")
review[idx, c("proposed_code", "qualifier", "note")] <- corrections[, c("proposed_code", "qualifier", "note")]

non_molecule <- c("Technique ATB", "Commentaire C3G", "COMMENTAIRE SAMR", "COMMENTAIRE BLSE",
                  "COMMENTAIRE CARBA", "COMMENTAIRE ERG", "CEFINASE")
idx <- match(non_molecule, review$local_label)
stopifnot(!anyNA(idx))
review$action[idx] <- "Outside molecule matching"
review$proposed_code[idx] <- NA_character_
review$note[idx] <- "Retain for separate technical, comment or assay handling; do not pass this field to the antibiotic-name matcher."

unresolved <- c("AMOXICILLINE / AMPICILLINE", "AMPICILLINE/AMOXICILLINE", "NITROFURANES",
                "NORFLO DEPIST RCC FQUINOLONES", "ASSO AZTRE/CAZA", "ASSO AUGMENTIN/CEFIXIME")
idx <- match(unresolved, review$local_label)
stopifnot(!anyNA(idx))
review$action[idx] <- "Local meaning needed"
review$proposed_code[idx] <- NA_character_
review$note[idx] <- c(
  "Resolve the joint amoxicillin/ampicillin reporting rule; do not substitute an inhibitor combination.",
  "Same joint-label question; the automatic penicillin/novobiocin proposal does not resolve it.",
  "The source names a family; the existing dictionary chooses nitrofurantoin. Confirm the actual assay before assigning a molecule.",
  "Clarify the screening assay and its intended result meaning before assigning a therapeutic drug identity.",
  "Clarify the combination-test identity; do not substitute aztreonam/nacubactam.",
  "Clarify the combination-test identity; do not substitute the automatic multidrug product."
)

reference <- as.data.frame(AMR::antimicrobials)
stopifnot(all(na.omit(review$proposed_code) %in% as.character(reference$ab)))
review$proposed_name <- reference$name[match(review$proposed_code, as.character(reference$ab))]
review$current <- ifelse(is.na(review$amr_code), "Unmapped", paste0(review$amr_name, " (", review$amr_code, ")"))
review$proposal <- ifelse(is.na(review$proposed_code), review$action, paste0(review$proposed_name, " (", review$proposed_code, ")"))

counts <- sort(table(review$action), decreasing = TRUE)
md <- c("# DRAFT - local antibiotic-label review", "",
        "AMR is the chosen base for organism mapping, replacing the DIY bacterial dictionary with local exceptions.",
        "This document covers antibiotic/test labels from LBLANA, not sample-type labels.", "",
        paste0("Source: the classification snapshot for ", payload$metadata$year, "; ", nrow(review), " distinct labels; AMR ", payload$metadata$versions$AMR, "."),
        paste0("Snapshot generated at ", payload$metadata$run_utc, ". This review does not rerun the raw-data extraction."),
        "All entries are draft review proposals. No mapping, source row or resistance value has been changed.",
        "Frequencies are source result-row counts, not isolate counts.", "",
        "## Review summary", "",
        paste0("- ", names(counts), ": ", as.integer(counts)), "",
        "Molecule identity, laboratory assay, formulation and recorded interpretation context remain distinguishable.",
        "A context qualifier such as MENINGITE does not establish the sample type or an infection diagnosis.",
        "Rows outside molecule matching remain available for separate handling; they are not deleted from the source.")
for (action in c("Propose code correction", "Local meaning needed", "Outside molecule matching",
                 "Retain code; preserve qualifier", "Retain AMR candidate")) {
  rows <- review[review$action == action, ]
  md <- c(md, "", paste0("## ", action), "",
          "| Source label | Result rows | Current AMR candidate | Draft target / handling | Source qualifier | Review note |",
          "|---|---:|---|---|---|---|")
  cells <- rows[, c("local_label", "result_rows", "current", "proposal", "qualifier", "note")]
  cells[] <- lapply(cells, function(x) gsub("|", "&#124;", as.character(x), fixed = TRUE))
  md <- c(md, apply(cells, 1L, function(row) paste0("| ", paste(row, collapse = " | "), " |")))
}
path <- file.path(output, "antibiotic-label-review.md")
writeLines(enc2utf8(md), path, useBytes = TRUE)
cat(paste0(names(counts), ": ", as.integer(counts), collapse = "\n"), "\n")
cat("Draft only: no corrections applied.\nOpen ", normalizePath(path, winslash = "/"), "\n", sep = "")
