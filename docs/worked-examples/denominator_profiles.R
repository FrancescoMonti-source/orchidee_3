# Reproduction for docs/worked-examples/denominator.md
# Run from the v2 repo root (C:/Users/franc/Documents/Git/orchidee).
# Part 1: eligible perimeter, profiles, timestamp resolution.

.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
suppressPackageStartupMessages(library(data.table))
setwd("C:/Users/franc/Documents/Git/orchidee")
raw <- readRDS("data/pmsi")$main
cat("rows:", nrow(raw), "\n")
cat("class DATENT:", class(raw$DATENT)[1], " DATSORT:", class(raw$DATSORT)[1], "\n")
has_redsan <- requireNamespace("redsan", quietly=TRUE)
cat("redsan available:", has_redsan, "\n")
if (has_redsan) raw <- redsan::prefer_pmsi_src_c_over_dw(raw)
cat("rows after source policy:", nrow(raw), "\n")
d <- as.data.table(raw)[!is.na(DATENT) & !is.na(DATSORT)]
tz <- "Europe/Paris"
sec_ent <- as.numeric(format(d$DATENT, "%H", tz=tz))*3600 + as.numeric(format(d$DATENT,"%M",tz=tz))*60
sec_sor <- as.numeric(format(d$DATSORT, "%H", tz=tz))*3600 + as.numeric(format(d$DATSORT,"%M",tz=tz))*60
cat("\n-- share of timestamps at exactly 00:00 --\n")
cat("DATENT midnight:", round(100*mean(sec_ent==0),2), "%   DATSORT midnight:", round(100*mean(sec_sor==0),2), "%\n")
cat("\n-- DATENT hour distribution (top 8) --\n")
print(head(sort(table(as.integer(sec_ent/3600)), decreasing=TRUE), 8))
cat("\n-- DATSORT hour distribution (top 8) --\n")
print(head(sort(table(as.integer(sec_sor/3600)), decreasing=TRUE), 8))

# eligible UF set from the stored exposure table
e <- as.data.table(readRDS("outputs/rouen_current/site_inputs/incidence_exposure_by_year_um_uf_ta_de_profile.rds"))
dom <- c("MÉDECINE","URGENCES","CHIRURGIE","RÉANIMATION","PÉDIATRIE","GYNÉCOLOGIE-OBSTÉTRIQUE","SOINS MÉDICAUX ET DE RÉADAPTATION","SOINS DE LONGUE DURÉE","PSYCHIATRIE","ÉTABLISSEMENT D'HÉBERGEMENT POUR PERSONNES ÂGÉES DÉPENDANTES")
elig <- unique(e[CODE_TA %in% c("03","20") & de_domain_ref %in% dom, .(SEJUF, de_domain_ref)])
d[, SEJUF := trimws(as.character(SEJUF))]
d <- merge(d, elig, by="SEJUF")
cat("\nrows in eligible UFs:", nrow(d), "\n")

lo <- as.POSIXct("2024-01-01 00:00:00", tz=tz); hi <- as.POSIXct("2025-01-01 00:00:00", tz=tz)
x <- d[DATSORT > lo & DATENT < hi]
x[, `:=`(s = pmax(DATENT, lo), e2 = pmin(DATSORT, hi))]
x <- x[e2 > s, .(PATID=as.character(PATID), EVTID=as.character(EVTID), SEJUM=trimws(as.character(SEJUM)), SEJUF, de_domain_ref, s, e2)]
setorder(x, PATID, EVTID, SEJUM, SEJUF, s, e2)
k <- c("PATID","EVTID","SEJUM","SEJUF")
x[, blk := cumsum(as.numeric(s) > shift(cummax(as.numeric(e2)), fill=-Inf)), by=k]
u <- x[, .(s=min(s), e2=max(e2), de_domain_ref=de_domain_ref[1]), by=c(k,"blk")]
u[, hours := as.numeric(difftime(e2, s, units="hours"))]
u[, nights := as.numeric(as.Date(e2, tz=tz) - as.Date(s, tz=tz))]
cat("\n=== 2024, eligible perimeter ===\n")
cat("midnight_presence nights :", format(sum(u$nights), big.mark=" "), "\n")
cat("occupancy hours / 24     :", format(round(sum(u$hours)/24), big.mark=" "), "\n")
cat("ratio hours24 / nights   :", round(sum(u$hours)/24/sum(u$nights), 4), "\n")
cat("stored exposure (2024)   : 355246\n")
cat("\n-- by sector --\n")
b <- u[, .(nights=sum(nights), hours24=round(sum(hours)/24)), by=de_domain_ref]
b[, ratio := round(hours24/nights, 3)]
print(b[order(-nights)])
cat("\n-- zero-night intervals (in and out same calendar day) --\n")
z <- u[nights==0]
cat("count:", nrow(z), " of ", nrow(u), " (", round(100*nrow(z)/nrow(u),2), "% )  hours they carry:", round(sum(z$hours)/24), " patient-days\n")
print(z[, .(n=.N, days=round(sum(hours)/24)), by=de_domain_ref][order(-n)])

# Part 2: all TA codes, where the two profiles diverge.

.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
suppressPackageStartupMessages(library(data.table))
setwd("C:/Users/franc/Documents/Git/orchidee")
raw <- redsan::prefer_pmsi_src_c_over_dw(readRDS("data/pmsi")$main)
d <- as.data.table(raw)[!is.na(DATENT) & !is.na(DATSORT)]
tz <- "Europe/Paris"
e <- as.data.table(readRDS("outputs/rouen_current/site_inputs/incidence_exposure_by_year_um_uf_ta_de_profile.rds"))
ref <- unique(e[, .(SEJUF, CODE_TA, de_domain_ref)])
d[, SEJUF := trimws(as.character(SEJUF))]
d <- merge(d, ref, by="SEJUF")
lo <- as.POSIXct("2024-01-01 00:00:00", tz=tz); hi <- as.POSIXct("2025-01-01 00:00:00", tz=tz)
x <- d[DATSORT > lo & DATENT < hi]
x[, `:=`(s = pmax(DATENT, lo), e2 = pmin(DATSORT, hi))]
x <- x[e2 > s, .(PATID=as.character(PATID), EVTID=as.character(EVTID), SEJUM=trimws(as.character(SEJUM)), SEJUF, CODE_TA, de_domain_ref, s, e2)]
setorder(x, PATID, EVTID, SEJUM, SEJUF, s, e2)
k <- c("PATID","EVTID","SEJUM","SEJUF")
x[, blk := cumsum(as.numeric(s) > shift(cummax(as.numeric(e2)), fill=-Inf)), by=k]
u <- x[, .(s=min(s), e2=max(e2), CODE_TA=CODE_TA[1], de_domain_ref=de_domain_ref[1]), by=c(k,"blk")]
u[, hours := as.numeric(difftime(e2, s, units="hours"))]
u[, nights := as.numeric(as.Date(e2, tz=tz) - as.Date(s, tz=tz))]
cat("=== 2024, TA 10 (accueil des urgences) ===\n")
t10 <- u[CODE_TA=="10"]
cat("unit-episodes:", nrow(t10), "\n")
cat("midnight_presence nights:", round(sum(t10$nights)), "\n")
cat("occupancy hours / 24    :", round(sum(t10$hours)/24), "\n")
cat("ratio                   :", round(sum(t10$hours)/24/sum(t10$nights), 4), "\n")
cat("zero-night episodes     :", sum(t10$nights==0), " (", round(100*mean(t10$nights==0),1), "% )\n")
cat("median stay hours       :", round(median(t10$hours),2), "   mean:", round(mean(t10$hours),2), "\n")
cat("\n=== same, all TA outside the eligible perimeter ===\n")
dom <- c("MÉDECINE","URGENCES","CHIRURGIE","RÉANIMATION","PÉDIATRIE","GYNÉCOLOGIE-OBSTÉTRIQUE","SOINS MÉDICAUX ET DE RÉADAPTATION","SOINS DE LONGUE DURÉE","PSYCHIATRIE","ÉTABLISSEMENT D'HÉBERGEMENT POUR PERSONNES ÂGÉES DÉPENDANTES")
u[, elig := CODE_TA %in% c("03","20") & de_domain_ref %in% dom]
b <- u[, .(episodes=.N, nights=round(sum(nights)), hours24=round(sum(hours)/24)), by=.(elig, CODE_TA)]
b[, ratio := round(hours24/pmax(nights,1),3)]
print(b[order(elig, -nights)])
