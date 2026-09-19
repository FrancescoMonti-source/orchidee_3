# Reproduction for docs/worked-examples/perimeter-ordering.md
# Run from anywhere; paths point at the v2 repo.

.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
p <- "C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/bundle_v3/"
s <- as.data.frame(readRDS(paste0(p,"sir_wide.rds")))
r <- as.data.frame(readRDS(paste0(p,"sample_scope_reference.rds")))
s$year <- as.integer(format(as.Date(s$DATEPRELEV), "%Y"))
cat("bact_norm containing coli:", paste(grep("coli", unique(s$bact_norm), value=TRUE, ignore.case=TRUE), collapse=" | "), "\n")
s <- merge(s, r[,c("SEJUF","sample_uf_is_eligible_by_ta_de")], by="SEJUF", all.x=TRUE)
s$elig <- !is.na(s$sample_uf_is_eligible_by_ta_de) & s$sample_uf_is_eligible_by_ta_de

panel <- c("amoxicilline_ampicilline","amoxicilline_acide_clavulanique","piperacilline_tazobactam","mecillinam","cefotaxime","ceftriaxone","ceftazidime","cefepime","imipeneme","ertapeneme","gentamicine","amikacine","ofloxacine","levofloxacine","ciprofloxacine","trimethoprime_sulfamethoxazole","nitrofurantoine","fosfomycine_trometamol","fosfomycine_iv")
major <- function(a,b){ both <- !is.na(a)&!is.na(b); if(!any(both)) return(FALSE)
  x<-a[both]; y<-b[both]
  any((x=="S"&y=="R")|(x=="R"&y=="S")|(x=="ZIT"&y=="R")|(x=="R"&y=="ZIT")) }
dedup <- function(df){
  M <- as.matrix(df[,panel,drop=FALSE]); nt <- rowSums(!is.na(M))
  grp <- paste(df$PATID, format(as.Date(df$DATEPRELEV),"%Y"), sep="|"); keep <- rep(FALSE,nrow(df))
  for(g in unique(grp)){ idx <- which(grp==g); idx <- idx[order(df$DATEPRELEV[idx])]
    ret <- integer(0)
    for(i in idx){ hit <- NA_integer_
      for(j in ret) if(!major(M[i,],M[j,])){hit <- j; break}
      if(is.na(hit)) ret <- c(ret,i) else if(nt[i]>nt[hit]) ret[ret==hit] <- i }
    keep[ret] <- TRUE }
  df[keep,,drop=FALSE] }
pr <- function(df,ab){ v <- df[[ab]]; v <- v[!is.na(v) & v %in% c("S","R","ZIT")]
  n <- sum(v %in% c("S","R")); if(n==0) return(c(NA,0)); c(round(100*sum(v=="R")/n,2), n) }

ec <- s[s$bact_norm=="escherichia_coli" & s$year==2024, ]
cat("\nE. coli 2024 isolates (all units, diagnostic):", nrow(ec), "  in eligible units:", sum(ec$elig), "\n")

A <- dedup(ec[ec$elig,])                    # perimeter first, then dedup
B0 <- dedup(ec); B <- B0[B0$elig,]          # dedup first, then perimeter
cat("\nA) perimeter -> dedup :", nrow(A), "isolates\n")
cat("B) dedup -> perimeter :", nrow(B), "isolates   (delta", nrow(B)-nrow(A), ")\n")
cat("   patients lost entirely by B:", length(setdiff(A$PATID, B$PATID)), "\n")
cat("   dedup over all units kept:", nrow(B0), "\n")
cat("\n%R (numerator/denominator):\n")
for (ab in c("amoxicilline_acide_clavulanique","cefotaxime","ofloxacine","trimethoprime_sulfamethoxazole","ertapeneme","gentamicine")) {
  a <- pr(A,ab); b <- pr(B,ab)
  cat(sprintf("%-32s A %6.2f (n=%4d)   B %6.2f (n=%4d)   delta %+5.2f pp\n", ab, a[1], a[2], b[1], b[2], b[1]-a[1]))
}
