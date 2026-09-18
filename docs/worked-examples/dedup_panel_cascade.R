.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
suppressMessages(library(dplyr))
w <- readRDS("C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/bundle_v3/sir_wide.rds")
PANEL <- c("amoxicilline_ampicilline","amoxicilline_acide_clavulanique",
           "piperacilline_tazobactam","mecillinam","cefotaxime","ceftriaxone",
           "ceftazidime","cefepime","imipeneme","ertapeneme","gentamicine",
           "amikacine","ofloxacine","levofloxacine","ciprofloxacine",
           "trimethoprime_sulfamethoxazole","nitrofurantoine",
           "fosfomycine_trometamol","fosfomycine_iv")
d <- w %>% filter(bact_norm=="escherichia_coli", naturepvt_norm=="urines",
                  format(DATEPRELEV,"%Y")=="2024") %>% arrange(PATID, DATEPRELEV)
major <- function(a,b){ both <- !is.na(a)&!is.na(b); if(!any(both)) return(FALSE)
  x<-a[both]; y<-b[both]
  any((x=="S"&y=="R")|(x=="R"&y=="S")|(x=="ZIT"&y=="R")|(x=="R"&y=="ZIT")) }
dedup <- function(df,panel,window){
  M <- as.matrix(df[,panel,drop=FALSE]); nt <- rowSums(!is.na(M))
  grp <- paste(df$PATID, window, sep="|"); keep <- rep(FALSE,nrow(df))
  for(g in unique(grp)){ idx <- which(grp==g); idx <- idx[order(df$DATEPRELEV[idx])]
    ret <- integer(0)
    for(i in idx){ hit <- NA_integer_
      for(j in ret) if(!major(M[i,],M[j,])){hit <- j; break}
      if(is.na(hit)) ret <- c(ret,i) else if(nt[i]>nt[hit]) ret[ret==hit] <- i }
    keep[ret] <- TRUE }
  df[keep,,drop=FALSE] }
pR <- function(df,col){ v <- df[[col]][!is.na(df[[col]])]
  c(round(100*sum(v=="R")/length(v),2), sum(v=="R"), length(v)) }
yr <- format(d$DATEPRELEV,"%Y")

full <- dedup(d, PANEL, yr)
cat("=== CASCADE: remove ONE antibiotic from the panel, watch the others move ===\n")
cat("slice: E. coli / urines / 2024, annual window.", nrow(d), "raw isolates\n\n")
cat(sprintf("%-34s %8s %8s %8s\n","panel used","isolates","OFX %R","SXT %R"))
r <- pR(full,"ofloxacine"); s <- pR(full,"trimethoprime_sulfamethoxazole")
cat(sprintf("%-34s %8d %8.2f %8.2f\n","full SPARES panel (19)", nrow(full), r[1], s[1]))
for (drop in c("amoxicilline_acide_clavulanique","amoxicilline_ampicilline",
               "nitrofurantoine","fosfomycine_iv","mecillinam")) {
  x <- dedup(d, setdiff(PANEL, drop), yr)
  r <- pR(x,"ofloxacine"); s <- pR(x,"trimethoprime_sulfamethoxazole")
  cat(sprintf("%-34s %8d %8.2f %8.2f\n", paste0("minus ", substr(drop,1,26)), nrow(x), r[1], s[1]))
}
cat("\n=== does any out-of-panel molecule discriminate here? ===\n")
sup <- readRDS("C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/bundle_v3/sir_wide_meta.rds")$supported_atb_cols
for (c0 in setdiff(sup, PANEL)) { n <- sum(!is.na(d[[c0]])); if (n>0)
  cat(sprintf("  %-32s %6d results, %d R\n", c0, n, sum(d[[c0]]=="R", na.rm=TRUE))) }
