# incomplete_antibiotypes_witness.R
# Reproduction script for docs/worked-examples/incomplete-antibiotypes.md.
# Measures how often blank antibiotic results make the duplicate comparison
# ambiguous, and how five ways of resolving it differ. Reads a provisional bundle
# that the v2 pipeline built from data/bact22_24 and data/pmsi (see
# build_manifest.txt: commit and mappings); its counts are provisional.
# Run from the repository root.

suppressMessages(library(dplyr))

p_run <- Sys.getenv("ORCHIDEE_V3_RUN", unset = file.path("outputs", "rouen_stage2_2024"))
p_bundle <- file.path(p_run, "bundle_v3")
manifest <- readLines(file.path(p_run, "build_manifest.txt"), warn = FALSE)
stopifnot(
  "source_contract: v3" %in% manifest,
  any(grepl(paste0("md5=", unname(tools::md5sum("data/bact22_24"))), manifest, fixed = TRUE)),
  any(grepl(paste0("md5=", unname(tools::md5sum("data/pmsi"))), manifest, fixed = TRUE))
)

s <- as.data.frame(readRDS(file.path(p_bundle, "sir_wide.rds")))
r <- as.data.frame(readRDS(file.path(p_bundle, "sample_scope_reference.rds")))
meta <- readRDS(file.path(p_bundle, "sir_wide_meta.rds"))
s <- merge(s, r[, c("SEJUF", "sample_uf_is_eligible_by_ta_de")], by = "SEJUF", all.x = TRUE)
s$elig <- !is.na(s$sample_uf_is_eligible_by_ta_de) & s$sample_uf_is_eligible_by_ta_de
s$year <- as.integer(format(as.Date(s$DATEPRELEV), "%Y"))
panel <- intersect(meta$supported_atb_cols, names(s))
c3g <- intersect(c("cefotaxime", "ceftriaxone", "ceftazidime", "cefepime"), panel)

# Source rule (SPARES pp. 10-11, SPF pp. 14-15): a major discrepancy is S<->R or
# SFP<->R; ZIT is read as SFP; a blank antibiotic result never discriminates; a
# blank phenotype cell means the phenotype is absent.
major <- function(a, b) {
  both <- !is.na(a) & !is.na(b)
  if (!any(both)) return(FALSE)
  x <- a[both]; y <- b[both]
  susc <- c("S", "SFP", "ZIT")
  any((x %in% susc & y == "R") | (x == "R" & y %in% susc))
}

# Five ways to decide which isolates of one comparison group are kept. `idx` is in
# chronological order; `compatible(i, j)` is TRUE when i and j are compatible; `nt`
# counts tested molecules. Retention rule within a group: more molecules tested,
# then oldest.
best <- function(v, nt) v[which.max(nt[v])]
policies <- list(
  # Previous witness code: compare with the kept isolate; it is replaced when a
  # compatible isolate has more molecules, and the replacement becomes the comparison.
  kept_isolate = function(idx, compatible, nt) {
    ret <- integer(0)
    for (i in idx) {
      hit <- NA_integer_
      for (j in ret) if (compatible(i, j)) { hit <- j; break }
      if (is.na(hit)) ret <- c(ret, i) else if (nt[i] > nt[hit]) ret[ret == hit] <- i
    }
    ret
  },
  # ONERBA reading: the first isolate is kept and never replaced.
  first_never_replaced = function(idx, compatible, nt) {
    ret <- integer(0)
    for (i in idx) if (!any(vapply(ret, function(j) compatible(i, j), TRUE))) ret <- c(ret, i)
    ret
  },
  # Decision 07.6: compare with every isolate already in the group.
  every_group_member = function(idx, compatible, nt) {
    grp <- list()
    for (i in idx) {
      k <- NA_integer_
      for (g in seq_along(grp)) if (all(vapply(grp[[g]], function(j) compatible(i, j), TRUE))) { k <- g; break }
      if (is.na(k)) grp[[length(grp) + 1L]] <- i else grp[[k]] <- c(grp[[k]], i)
    }
    vapply(grp, best, 1L, nt = nt)
  },
  # Compare with the first isolate of the group only.
  first_group_member = function(idx, compatible, nt) {
    grp <- list()
    for (i in idx) {
      k <- NA_integer_
      for (g in seq_along(grp)) if (compatible(i, grp[[g]][1])) { k <- g; break }
      if (is.na(k)) grp[[length(grp) + 1L]] <- i else grp[[k]] <- c(grp[[k]], i)
    }
    vapply(grp, best, 1L, nt = nt)
  },
  # Merge every chain of compatible isolates, even when its two ends have a major discrepancy.
  merge_chains = function(idx, compatible, nt) {
    lab <- seq_along(idx)
    for (a in seq_along(idx)) for (b in seq_along(idx)) {
      if (a < b && compatible(idx[a], idx[b])) lab[lab == lab[b]] <- lab[a]
    }
    vapply(split(idx, lab), best, 1L, nt = nt)
  }
)

# The case that motivated the question. A: ofloxacine S, 2 molecules. B: ofloxacine
# blank, 3 molecules. C: ofloxacine R, 2 molecules. A-B and B-C have no major
# discrepancy; A-C has one.
abc <- matrix(c("S", "S", NA, NA,
                NA,  "S", "S", "S",
                "R", NA,  NA,  "S"), nrow = 3, byrow = TRUE)
abc_compatible <- function(i, j) !major(abc[i, ], abc[j, ])
abc_nt <- rowSums(!is.na(abc))
abc_kept <- lapply(policies, function(f) LETTERS[sort(f(1:3, abc_compatible, abc_nt))])
stopifnot(
  identical(abc_kept$kept_isolate, "B"),
  identical(abc_kept$first_never_replaced, c("A", "C")),
  identical(abc_kept$every_group_member, c("B", "C")),
  identical(abc_kept$first_group_member, c("B", "C")),
  identical(abc_kept$merge_chains, "B")
)
cat("A/B/C case, isolates kept:\n")
for (p in names(abc_kept)) cat(sprintf("  %-21s %s\n", p, paste(abc_kept[[p]], collapse = " ")))

# Every way to split a group into sub-groups with no major discrepancy inside any
# of them, to compare the date-order rule with forming the groups all at once.
partitions <- function(idx, compatible) {
  res <- list()
  rec <- function(k, blocks) {
    if (k > length(idx)) { res[[length(res) + 1L]] <<- blocks; return(invisible()) }
    i <- idx[k]
    for (b in seq_along(blocks)) if (all(vapply(blocks[[b]], function(j) compatible(i, j), TRUE))) {
      nb <- blocks; nb[[b]] <- c(nb[[b]], i); rec(k + 1L, nb)
    }
    rec(k + 1L, c(blocks, list(i)))
  }
  rec(1L, list())
  res
}
minimal_answers <- function(idx, compatible, nt) {
  p <- partitions(idx, compatible)
  k <- lengths(p)
  unique(lapply(p[k == min(k)], function(x) sort(vapply(x, best, 1L, nt = nt))))
}
abc_min <- lapply(minimal_answers(1:3, abc_compatible, abc_nt), function(v) LETTERS[v])
stopifnot(length(abc_min) == 2L)
cat("A/B/C case, minimal groupings retain:", vapply(abc_min, paste, "", collapse = " "), sep = "\n  ")

for (yr in 2022:2024) {
  d <- s[s$year == yr & s$elig, ]
  d <- d[order(d$DATEPRELEV, d$HEUREPRELEV, d$ELTID, d$souche_id, na.last = TRUE), ]
  rownames(d) <- NULL
  M <- as.matrix(d[, panel])
  nt <- rowSums(!is.na(M))
  ph <- cbind(d$blse_flag %in% TRUE, d$carbapenemase_flag %in% TRUE)
  compatible <- function(i, j) !major(M[i, ], M[j, ]) && all(ph[i, ] == ph[j, ])
  spec <- ifelse(is.na(d$naturepvt_norm), paste0("unknown:", seq_len(nrow(d))), d$naturepvt_norm)
  G <- split(seq_len(nrow(d)), paste(d$PATID, d$bact_norm, spec, sep = "|"))
  G <- G[lengths(G) >= 2]

  kept <- setNames(vector("list", length(policies)), names(policies))
  differ <- setNames(integer(length(policies)), names(policies))
  bridges <- 0L; attach2 <- 0L; phen_only <- 0L; phen_unassessed <- 0L
  ambiguous <- 0L; single_answer <- 0L; rule_is_minimal <- 0L
  orphan <- c(retention_rule = 0L, first_never_replaced = 0L)
  orphan_r <- orphan
  for (idx in G) {
    out <- lapply(policies, function(f) f(idx, compatible, nt))
    for (p in names(out)) {
      kept[[p]] <- c(kept[[p]], out[[p]])
      if (!setequal(out[[p]], out$kept_isolate)) differ[p] <- differ[p] + 1L
    }
    n <- length(idx)
    C <- outer(seq_len(n), seq_len(n), Vectorize(function(a, b) a == b || compatible(idx[a], idx[b])))
    # Bridging isolate: B later than A and earlier than C, compatible with both, while
    # A and C are not compatible.
    for (b in seq_len(n)) for (a in seq_len(b - 1)) if (C[a, b]) for (c in seq_len(n)[-seq_len(b)]) {
      if (C[b, c] && !C[a, c]) bridges <- bridges + 1L
    }
    # Ambiguous group: some isolate is compatible with two isolates that are not
    # compatible with each other, so the duplicate groups are not unique.
    if (any(vapply(seq_len(n), function(b) { nb <- which(C[b, ]); any(!C[nb, nb]) }, TRUE))) {
      ambiguous <- ambiguous + 1L
      ans <- minimal_answers(idx, compatible, nt)
      if (length(ans) == 1L) single_answer <- single_answer + 1L
      if (any(vapply(ans, function(x) setequal(x, out$every_group_member), TRUE))) {
        rule_is_minimal <- rule_is_minimal + 1L
      }
    }
    # An isolate compatible with two kept isolates that are not compatible.
    ret <- integer(0)
    for (i in idx) {
      h <- sum(vapply(ret, function(j) compatible(i, j), TRUE))
      if (h >= 2) attach2 <- attach2 + 1L
      if (h == 0) ret <- c(ret, i)
    }
    # Pairs kept apart only by a phenotype, and whether the negative side could not
    # have shown a BLSE because no third-generation cephalosporin was tested.
    for (a in seq_len(n)) for (b in seq_len(n)) if (a < b) {
      x <- idx[a]; y <- idx[b]
      if (!major(M[x, ], M[y, ]) && any(ph[x, ] != ph[y, ])) {
        phen_only <- phen_only + 1L
        neg <- if (ph[x, 1] != ph[y, 1]) (if (ph[x, 1]) y else x) else NA
        if (!is.na(neg) && d$blse_status_row[neg] == "no_signal" && all(is.na(M[neg, c3g]))) {
          phen_unassessed <- phen_unassessed + 1L
        }
      }
    }
    # Orphaned result: a molecule result carried only by isolates that are not kept.
    for (p in names(orphan)) {
      rr <- if (p == "retention_rule") out$every_group_member else out$first_never_replaced
      tested <- colSums(!is.na(M[rr, , drop = FALSE])) > 0
      for (l in setdiff(idx, rr)) {
        o <- !is.na(M[l, ]) & !tested
        if (any(o)) {
          orphan[p] <- orphan[p] + 1L
          if (any(M[l, o] == "R")) orphan_r[p] <- orphan_r[p] + 1L
        }
      }
    }
  }
  # Same-day, same-hour ties: reverse the tie-break and see what changes under 07.6.
  rev_ord <- order(d$DATEPRELEV, d$HEUREPRELEV, -rank(d$ELTID), -rank(d$souche_id))
  pos <- match(seq_len(nrow(d)), rev_ord)
  tie_changed <- 0L; tie_count <- 0L; tie_molecules <- 0L
  for (idx in G) {
    cur <- policies$every_group_member(idx, compatible, nt)
    alt <- policies$every_group_member(idx[order(pos[idx])], compatible, nt)
    if (!setequal(alt, cur)) {
      tie_changed <- tie_changed + 1L
      if (length(alt) != length(cur)) tie_count <- tie_count + 1L
      tested <- function(v) sort(unique(panel[colSums(!is.na(M[v, , drop = FALSE])) > 0]))
      if (!identical(tested(alt), tested(cur))) tie_molecules <- tie_molecules + 1L
    }
  }

  cat(sprintf("\n== %d, eligible perimeter: %d isolates, %d comparison groups with 2+ isolates ==\n",
              yr, nrow(d), length(G)))
  cat("isolates kept in those groups, and groups that differ from the current code:\n")
  for (p in names(policies)) cat(sprintf("  %-21s %5d kept, %3d groups differ\n", p, length(kept[[p]]), differ[p]))
  cat(sprintf("bridging isolates (A~B~C with A-C major discrepancy): %d\n", bridges))
  cat(sprintf("ambiguous groups: %d; minimal grouping has a single answer: %d; it is the every-member answer: %d\n",
              ambiguous, single_answer, rule_is_minimal))
  cat(sprintf("isolates compatible with two different kept isolates: %d\n", attach2))
  cat(sprintf("orphaned results, retention rule: %d isolates (%d with an R)\n", orphan["retention_rule"], orphan_r["retention_rule"]))
  cat(sprintf("orphaned results, first never replaced: %d isolates (%d with an R)\n", orphan["first_never_replaced"], orphan_r["first_never_replaced"]))
  cat(sprintf("groups whose kept isolates change when same-time ties are reversed: %d (count changes: %d; tested molecules change: %d)\n",
              tie_changed, tie_count, tie_molecules))
  cat(sprintf("pairs kept apart only by a phenotype: %d, of which BLSE side untestable (no C3G): %d\n",
              phen_only, phen_unassessed))
}
