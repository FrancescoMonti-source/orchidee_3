.libPaths("C:/Users/franc/AppData/Local/R/win-library/4.6")
suppressMessages({library(dplyr); library(tidyr)})
d <- "C:/Users/franc/Documents/Git/orchidee/outputs/rouen_current/site_inputs/"
o   <- readRDS(paste0(d,"microbiology_observations.rds"))
map <- read.csv("C:/Users/franc/Documents/Git/orchidee/mappings/atb_regex_map.csv",
                stringsAsFactors=FALSE, fileEncoding="UTF-8")
PANEL <- c("amoxicilline_ampicilline","amoxicilline_acide_clavulanique",
           "piperacilline_tazobactam","mecillinam","cefotaxime","ceftriaxone",
           "ceftazidime","cefepime","imipeneme","ertapeneme","gentamicine",
           "amikacine","ofloxacine","levofloxacine","ciprofloxacine",
           "trimethoprime_sulfamethoxazole","nitrofurantoine",
           "fosfomycine_trometamol","fosfomycine_iv")
ec <- o %>% filter(bacteria_local=="Escherichia coli", format(DATEPRELEV,"%Y")=="2024")
lbl <- unique(ec$antibiotic_local_source)
nm  <- vapply(lbl, function(x){ for(i in seq_len(nrow(map)))
  if(grepl(map$pattern[i], x, perl=TRUE)) return(map$atb_norm[i]); NA_character_ }, character(1))
ec$atb_norm <- nm[match(ec$antibiotic_local_source, lbl)]
wide <- ec %>% filter(!is.na(atb_norm), atb_norm %in% PANEL) %>%
  group_by(PATID, ELTID, souche_id, DATEPRELEV, ratb_diagnostic_scope, atb_norm) %>%
  summarise(v = dplyr::last(sir_result[!is.na(sir_result)]), .groups="drop") %>%
  pivot_wider(names_from=atb_norm, values_from=v)
for (p in setdiff(PANEL, names(wide))) wide[[p]] <- NA_character_
wide <- wide %>% arrange(PATID, DATEPRELEV)
major <- function(a,b){ both <- !is.na(a)&!is.na(b); if(!any(both)) return(FALSE)
  x<-a[both]; y<-b[both]
  any((x=="S"&y=="R")|(x=="R"&y=="S")|(x=="ZIT"&y=="R")|(x=="R"&y=="ZIT")) }
dedup <- function(df){ M <- as.matrix(df[,PANEL,drop=FALSE]); nt <- rowSums(!is.na(M))
  keep <- rep(FALSE,nrow(df))
  for(g in unique(df$PATID)){ idx <- which(df$PATID==g); idx <- idx[order(df$DATEPRELEV[idx])]
    ret <- integer(0)
    for(i in idx){ hit <- NA_integer_
      for(j in ret) if(!major(M[i,],M[j,])){hit <- j; break}
      if(is.na(hit)) ret <- c(ret,i) else if(nt[i]>nt[hit]) ret[ret==hit] <- i }
    keep[ret] <- TRUE }
  df[keep,,drop=FALSE] }
pR <- function(df,col){ v <- df[[col]][df[[col]] %in% c("S","R")]
  if(!length(v)) return(c(NA,0)); c(round(100*sum(v=="R")/length(v),2), length(v)) }
cat("E. coli 2024, global scope (all sample types), annual window, group by PATID\n")
cat("isolate keys before dedup - diagnostic only:", sum(wide$ratb_diagnostic_scope),
    "| including screening:", nrow(wide), "\n\n")
A <- dedup(wide %>% filter(ratb_diagnostic_scope)); B <- dedup(wide)
cat(sprintf("after dedup - diagnostic only : %d isolates\n", nrow(A)))
cat(sprintf("after dedup - incl. screening : %d isolates (%+.1f %%)\n\n",
            nrow(B), 100*(nrow(B)-nrow(A))/nrow(A)))
cat(sprintf("%-34s %17s %17s\n","indicator","diagnostic only","incl. screening"))
for (col in c("amoxicilline_acide_clavulanique","ofloxacine","cefotaxime",
              "trimethoprime_sulfamethoxazole","ertapeneme")) {
  a <- pR(A,col); b <- pR(B,col)
  cat(sprintf("%-34s  %6.2f %%R (n=%4d)  %6.2f %%R (n=%4d)\n", col, a[1],a[2], b[1],b[2])) }
