# phenotypes_screening_witness.R
# Measures the empirical behavior of screening keywords and BLSE/Carba phenotypes on 2024 raw data.

.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
p <- "C:/Users/franc/Documents/Git/orchidee/data/bact22_24"
b <- readRDS(p)

b24 <- b[format(as.Date(b$DATEPRELEV), "%Y") == "2024", ]

cat("=== PART 1: THE 'RECHERCHE' SCREENING PROXY HAZARD ===\n")
recherche_idx <- grep("recherche", paste(b24$TYPEANA, b24$LBLANA), ignore.case = TRUE)
matched_analyses <- unique(b24[recherche_idx, c("TYPEANA", "LBLANA")])
cat("Total 2024 rows matching 'recherche':", length(recherche_idx), "\n")
cat("Distinct lab test types matching 'recherche':", nrow(matched_analyses), "\n")

# Top diagnostic false positives caught by 'recherche'
gonocoque_rows <- sum(grepl("gonocoque", b24$LBLANA[recherche_idx], ignore.case = TRUE))
gdh_rows <- sum(grepl("gdh", b24$LBLANA[recherche_idx], ignore.case = TRUE))
tcda_rows <- sum(grepl("tcda|tox", b24$LBLANA[recherche_idx], ignore.case = TRUE))
palu_rows <- sum(grepl("frottis|palu", b24$LBLANA[recherche_idx], ignore.case = TRUE))

cat(sprintf("- RECHERCHE GONOCOQUE (diagnostic STI): %d rows\n", gonocoque_rows))
cat(sprintf("- Recherche antigene GDH (diagnostic C. diff): %d rows\n", gdh_rows))
cat(sprintf("- Recherche toxines C. diff: %d rows\n", tcda_rows))
cat(sprintf("- Recherche hematozoaire (diagnostic malaria): %d rows\n", palu_rows))

cat("\n=== PART 2: BLSE STATUS BREAKDOWN AND C3G CORRELATION ===\n")
ecoli_rows <- b24[!is.na(b24$IDENTIFICATION) & grepl("Escherichia coli", b24$IDENTIFICATION, ignore.case = TRUE), ]
ecoli_isolates <- unique(ecoli_rows[, c("PATID", "ELTID", "DLVL")])

# Diagnostic BLSE test: BLSE.BLSE1 (R = positive, S = negative)
blse_tests <- unique(b24[b24$TYPEANA == "BLSE.BLSE1", c("ELTID", "DLVL", "STRRES")])
names(blse_tests)[3] <- "BLSE_RES"

# C3G status (Cefotaxime, Ceftriaxone, Ceftazidime)
c3g_rows <- b24[b24$ELTID %in% ecoli_rows$ELTID & grepl("cefotax|ceftriax|ceftazid", b24$LBLANA, ignore.case = TRUE), ]
c3g_res_eltdlvl <- unique(c3g_rows[c3g_rows$STRRES == "R", c("ELTID", "DLVL")])
c3g_res_eltdlvl$C3G_R <- TRUE

ecoli_iso <- merge(ecoli_isolates, blse_tests, by = c("ELTID", "DLVL"), all.x = TRUE)
ecoli_iso$BLSE_RES[is.na(ecoli_iso$BLSE_RES)] <- "ABSENT"
ecoli_iso <- merge(ecoli_iso, c3g_res_eltdlvl, by = c("ELTID", "DLVL"), all.x = TRUE)
ecoli_iso$C3G_R[is.na(ecoli_iso$C3G_R)] <- FALSE

cat("Total distinct E. coli isolates:", nrow(ecoli_iso), "\n")
t_cross <- table(BLSE = ecoli_iso$BLSE_RES, C3G_R = ecoli_iso$C3G_R)
print(t_cross)

c3g_s_count <- sum(!ecoli_iso$C3G_R)
c3g_s_absent <- sum(!ecoli_iso$C3G_R & ecoli_iso$BLSE_RES == "ABSENT")
cat(sprintf("\nAmong %d C3G-susceptible E. coli isolates, %d (%.2f%%) have NO explicit BLSE test recorded (ABSENT).\n",
            c3g_s_count, c3g_s_absent, 100 * c3g_s_absent / c3g_s_count))
