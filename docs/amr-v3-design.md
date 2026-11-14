# AMR in ORCHIDEE v3: design proposal for the methodology specification

Status: **proposal**. This file proposes how the AMR package fits the v3
specification. It implements no pipeline, applies no correction and changes no
method chapter.

Written 2026-11-13. It starts from the evidence dossier `docs/amr-dossier.md`
(pull request #27, branch `claude/project-thread-1m1kyf`, commit `f9e18fc`;
not on `main` yet).

## How to read this file

In this file **AMR** always means the R package named AMR, version 3.1.0 unless
stated. The health problem is written out as "antimicrobial resistance".

Every statement carries one of three marks:

- **[D]** demonstrated. It was read in a file at the cited line, or produced
  by a check listed in section 1.
- **[I]** inference. My reading, not something a file or a run shows.
- **[V]** verification missing, with who can settle it: `data` (needs the
  Rouen data), `bio` (needs a biologist), `ext` (needs an answer from the SPF
  or SPARES teams), `legal`.

Citations:

- `path:line` is `main` at `8c66522`.
- `sha:file:line` is a prototype branch at that commit. `README`, `run.R` and
  `prepare` stand for the files under `docs/worked-examples/amr-r-prototype/`
  (`prepare` is `prepare-antibiotic-review.R`). `83eafc0` is the head of
  `prototype/amr-demo-ergonomics`; `3e48bdf` is `prototype/amr-label-review`.
- `AMR v3.1.0:path:line` is the AMR source at tag `v3.1.0` (commit `052edc4`).
  `AMR dev` is its `main` branch at `49a0f37` (version 3.1.0.9021, 2026-11-09).
- `dossier §n` is a section of the dossier at `f9e18fc`. `N`, `K` and `P`
  numbers are the dossier's needs, conflicts and prototype decisions.
- `A1` to `A12` are the checks of section 1.

Words used:

| Word | Meaning here |
|---|---|
| `as.mo()` | AMR function that reads an organism label and returns an AMR organism code, such as `B_ESCHR_COLI`. |
| `as.ab()` | AMR function that reads an antibiotic label and returns an AMR drug code, such as `CTX` for cefotaxime. |
| Automatic recognition | What `as.mo()` or `as.ab()` returns for a label. It is a suggestion. |
| Approved mapping | A line "this label means this identity" that a person reviewed and accepted. |
| Taxon | A named unit of classification: a species, a genus, an order. |
| Complex | A named set of close species that laboratories often report together. |
| Assay | A laboratory test. An assay result is not always a result that guides treatment. |
| GPL-2 | GNU General Public License version 2, the licence of AMR. |

Fixed inputs, not reopened here:

1. AMR (`as.mo()` plus local corrections) is the base of the organism mapping.
   The local file `organism-mapping.csv` is obsolete (dossier §1, P1, P3).
2. The antibiotic mapping builds on AMR and needs work (P2). It is the centre
   of this analysis.
3. `CLOXA` is cloxacillin. For SARM (decision 08.3) the markers are cefoxitine,
   then true oxacilline only. Cloxacillin is not a fallback. No *S. aureus*
   isolate is affected in the raw data (dossier §5, K4, P18).
4. `main` lags behind the prototype branches. Where they conflict, this file
   says which side the evidence supports (section 8).

## Summary

1. **AMR is a good vocabulary and a good organism recogniser. It is not a safe
   antibiotic mapper.** [D] `as.mo()` recognises all 347 organism names of the
   SPARES thesaurus (Annexe 5, pp. 28-30) (A10). `as.ab()` returns the draft
   review's code for only 5 of its 21 corrected labels (A1). It reads
   `TEICOPLANINE` as avoparcin, because AMR's own reference table holds
   teicoplanin's names on the avoparcin line (A3). It reads `CLAVENTIN` as
   amoxicillin/clavulanic acid, the same mistake that once moved 51 isolates and
   20 denominators (`docs/findings.md:45-52`).
2. **So recognition and approval stay two separate columns.** An AMR suggestion
   never becomes a mapping by itself. For antibiotics, only approved lines feed
   results (section 4.1, decision 1).
3. **AMR runs only in the site adapter.** The core needs no AMR. AMR's own
   group rule, class lists and small-count default disagree with the SPF rules
   (A5, A6, A7), so the core keeps its own rules from chapter 08 (section 3).
4. **A result identity has four typed parts**: molecule, test, formulation and
   context, plus a free qualifier. A taxon identity keeps the rank the
   laboratory reported. Groups such as "Enterobacterales" or a complex are
   membership tables owned by the core, not part of the identity (section 4).
5. **Three things are versioned apart**: the AMR reference, a shared list of
   corrections to AMR, and each site's approved mappings. Approved identities
   are stored, not recomputed, so an AMR upgrade cannot change a result
   silently (section 5).
6. **Version 3.1.0 is still the latest numbered AMR release**, going by the
   tags of its repository. The development version changes nothing that
   ORCHIDEE needs, and does not fix the teicoplanin defect (section 5.3).
7. **Seven decisions remain** (section 6). The first two carry most of the
   impact: the approval policy, and keeping AMR out of the core.

---

## 1. Checks run for this document

**[D]** The dossier ran no R session (dossier §10). For this file, AMR was
built from source and run on 2026-11-13: R 4.3.3, UTF-8 locale, AMR 3.1.0 from
tag `v3.1.0` and AMR 3.1.0.9021 from `main`. The inputs were label strings
already published in the repository (the prototype's review script) and the
species names of SPARES Annexe 5 (pp. 28-30). A11 and A12 use invented rows.
**No hospital data was read.**
The script is in the appendix. Both AMR versions give the same output except
for A9.

| # | What was run | Result |
|---|---|---|
| A1 | `as.ab()` on the 34 labels named in `3e48bdf:prepare:17-56` | Of the 21 labels with a draft correction, AMR gives the draft's code for 5 and another answer for 16. All 7 comment or technical fields get a drug code (`COMMENTAIRE BLSE` → cefuroxime/metronidazole). 5 of the 6 labels of unknown meaning get a drug code (`AMOXICILLINE / AMPICILLINE` → amoxicillin/sulbactam). |
| A2 | `as.ab()` on the plain French names of the 18 molecules in the SPF groups (SPF pp. 2-4) | 17 correct. `TEICOPLANINE` → `AVO`, avoparcin. |
| A3 | AMR's own French drug names, mapped back with `as.ab()` | 5 of 506 names do not come back to their own code. `Teicoplanine` → `AVO`. Cause: in AMR's table the synonyms `teicoplanine`, `targocid`… sit on the avoparcin line, and the teicoplanin line has none (`AMR v3.1.0:data-raw/datasets/antimicrobials.txt:25`, `:455`). In the same way `penicilline` sits on the clometocillin line (`:158`), so `PENICILLINE G` → `CLM`. The same lines exist in AMR 3.0.1 and in `AMR dev`. |
| A4 | AMR's own correction hook, `add_custom_antimicrobial_synonyms()` | It refuses `TEICOPLANINE` → `TEC` and `PENICILLINE G` → `PEN`, because AMR already attaches those words to another drug (rule at `AMR v3.1.0:R/custom_antimicrobials.R:70`). It accepts `CLAVENTIN` → `TCC`. |
| A5 | `as.sir()` and `resistance()` | `as.sir()` turns `SFP` and `ZIT` into missing values. `resistance()` returns a missing value under 30 results by default; with `minimum = 0` it gives 0.3 with `guideline = "EUCAST"` and 0.5 with `guideline = "CLSI"` on the same ten results. |
| A6 | `sir_combine(method = "most_resistant")` on cefotaxime, ceftazidime, ceftriaxone | An isolate with one `S` and two untested molecules gets a missing value, not `S` (documented at `AMR v3.1.0:R/sir_combine.R:46`, `:63`). |
| A7 | Class selectors and laboratory-test codes | `cephalosporins_3rd()` holds 36 drug codes, `carbapenems()` 13, `fluoroquinolones()` 50, `glycopeptides()` 12 (avoparcin among them). AMR has at least 17 codes that name a test, not a treatment: `GEH` (gentamicin-high), `FOX-S` (cefoxitin screening test), `OXA-S`, `NOR-S`… |
| A8 | `as.mo()` on labels from the repository | `Enterobacter complexe cloacae` → subspecies *E. cloacae cloacae*, flagged uncertain. `Staphylococcus argenteus / schweitzeri (ex S. aureus)` → `UNKNOWN`. AMR's *Enterobacter cloacae* complex has 6 species; *E. roggenkampii* is not one of them. Two invented non-organism labels, `Levures` and `Flore polymorphe`, come back as a *Salmonella* serovar and a *Fusobacterium* subspecies, both flagged uncertain. A taxon added with `add_custom_microorganisms()` gets a code made for the session (`CUSTOM1_…`). |
| A9 | `mo_is_intrinsic_resistant()` | *E. cloacae* complex with amoxicillin/clavulanic acid: `FALSE` in 3.1.0, `TRUE` in `AMR dev`. |
| A10 | `as.mo()` on the 347 names of SPARES Annexe 5 (pp. 28-30) | 0 unknown, 1 flagged uncertain. 35 come back under another name, mostly renamed taxa. 6 pairs of thesaurus names share one AMR code (`Raoultella spp` and `Klebsiella spp`). 57 names fall in AMR's order Enterobacterales, in 18 genera, with *Salmonella*, *Shigella*, *Yersinia* and *Plesiomonas* among them. |
| A11 | `first_isolate()` with `testcodes_exclude`, on two invented rows: one patient, one species, a row with test code `screen` on day 1 and a row with test code `diag` on day 5 | Both rows come back `FALSE`. The function marks first isolates over all rows (`AMR v3.1.0:R/first_isolate.R:502-505`), then sets the excluded rows to `FALSE` (`:514`). With the screening row removed before the call, the diagnostic row is `TRUE`. With upper-case codes in the data, nothing is excluded: only the list of codes is lower-cased (`:514`). `specimen_group` works the other way round: the rows of the chosen specimen are selected first (`:398-411`), and on rectal, blood, blood the first blood row is `TRUE`. |
| A12 | `first_isolate()` on invented pairs of isolates: one patient, *E. coli*, day 1 and day 5 | One `S`/`R` difference on one molecule: the second isolate is a duplicate by default and with `type = "keyantimicrobials"`; it is counted with `points_threshold = 1`. Two `S`/`I` differences and no `S`/`R` difference: the second isolate is counted with `points_threshold = 1`, and is a duplicate once every `I` is read as `S` before the call. Same results, more molecules tested on the second isolate: the first one is kept. |

**[D]** A1 agrees with the prototype's own run on the user's machine. The notes
of the review script name the same wrong suggestions for 8 labels: a
cefotaxime screening test, a ceftriaxone/inhibitor combination, a cefoxitin
screening test, a beta-lactamase screening test, penicillin/novobiocin,
aztreonam/nacubactam, a multidrug product (`3e48bdf:prepare:29-34`, `:62-67`).

---

## 2. Matrix: v3 needs against AMR capabilities

Verdicts: **Direct** (use as is), **Adapt** (usable with a stated change),
**Incompatible** (do not use for this need), **Unverified** (a check is
missing).

| # | v3 need | AMR capability | Verdict | Evidence |
|---|---|---|---|---|
| M1 | Map organism labels to taxa (N1, N2) | `as.mo()` | **Adapt** | [D] Every SPARES Annexe 5 name is recognised (A10). [D] Labels that are not plain scientific names go wrong or fail (A8). The approved corrections cover them. [V:data] The full Rouen label list in the diagnostic population. |
| M2 | Unassigned taxa stay visible (N6) | Code `UNKNOWN` | **Direct** | [D] `AMR v3.1.0:R/mo.R:72`; the prototype reads `UNKNOWN` as unmapped (`83eafc0:run.R:50`). |
| M3 | Do not guess between overlapping labels (N7) | `mo_uncertainties()` | **Direct**, as a review aid | [D] It lists every guessed label with a score, for the last call only (dossier §6.2). [D] In A8 every wrong guess was flagged. A flag is a signal, not an approval (P16). |
| M4 | A taxon identity that stays readable across years | Renames to the current name by default (`keep_synonyms = FALSE`) | **Adapt** | [D] 35 of 347 thesaurus names change name; 6 pairs merge (A10). [D] `keep_synonyms = TRUE` keeps `Enterobacter aerogenes` under its own code (A8). [D] "MO codes might change between package versions" (`AMR v3.1.0:R/mo.R:214`); a registry of codes exists since 3.1.0 (`AMR v3.1.0:NEWS.md:57`). |
| M5 | Species and complex treatment (N4, N7) | `microorganisms.groups` (33 groups), rank "species group" | **Adapt** | [D] AMR's *E. cloacae* complex matches the SPF list at species level (SPF p. 2). The list in CA-SFM 2025 V1.1 (p. 34, note 3) is longer: it adds *E. roggenkampii* and three others (A8). Membership has to be declared by ORCHIDEE. Decided 2026-11-13 (Francesco): the complex follows the six-species list of SPF p. 2 (Q8). |
| M6 | "Toutes Enterobacterales" (N15) | `mo_order()` | **Adapt** | [D] 57 thesaurus names, 18 genera (A10). Project reading (Francesco, 2026-11-13): the indicator on SPF p. 4 means this whole taxonomic order, as far as he is aware. So *Salmonella*, *Shigella*, *Yersinia* and *Plesiomonas* count in it. [I] `mo_order()` then gives the first draft of the membership table that the core owns (Decision 5). [D] The list of target organisms writes "Entérobacterales toutes espèces" (SPF p. 2), which supports this reading. |
| M7 | Descriptive classification (Gram stain, family, genus) | `mo_*()` helpers | **Direct**, descriptive only | [D] The properties describe the suggested taxon, not the label (P15). |
| M8 | Map antibiotic and test labels to identities (N1, N2) | `as.ab()` | **Adapt**: suggestion only | [D] A1, A2, A3. [D] There is no table of uncertain matches for drugs (dossier §6.6). [D] `CLAVENTIN` → `AMC` repeats the error measured in `docs/findings.md:45-52`. |
| M9 | One molecule vocabulary for all sites (N2) | AMR drug codes | **Direct** | [D] Every molecule of the SPF groups (SPF pp. 2-4) and of SPF Annexe 3 (p. 20) has an AMR code (A2 and the AMR table). |
| M10 | Hold the local corrections (P1, P2) | `add_custom_antimicrobial_synonyms()`, `add_custom_antimicrobials()`, option `AMR_custom_ab` | **Incompatible** as the place of record | [D] The hook refuses the two corrections that matter most (A4). [D] Additions last one R session (`AMR v3.1.0:R/custom_antimicrobials.R:36`); the option can point to a remote file (`:42`). |
| M11 | Keep assay distinctions (P8) | Laboratory-test codes (at least 17) | **Adapt** | [D] A7. [D] AMR has no code for a formulation or a context. [D] AMR also assigns test codes from context words: `CEFOTAXIME MENINGITE` → cefotaxime screening test (A1). |
| M12 | Antibiotic groups of the indicators (N10, N15) | Class selectors, `ab_group()`, ATC | **Incompatible** for indicators; **Direct** for description | [D] The C3G group lists three molecules (SPF p. 2); `cephalosporins_3rd()` holds 36, with cefixime and ceftazidime/avibactam. The same gap exists for carbapenems (three on SPF p. 3, 13 in AMR), fluoroquinolones (four on SPF p. 2, 50 in AMR) and glycopeptides (two on SPF p. 3, 12 in AMR) (A7). |
| M13 | Joint or family labels (N4) | None | **Incompatible** | [D] `AMOXICILLINE / AMPICILLINE` → amoxicillin/sulbactam; `NITROFURANES` → nitrofurazone; `C3G` → nothing; `FLUOROQUINOLONES` → nifuroquine (A1). [D] SPF Annexe 3 (p. 20) itself lists "Amoxicilline-ampicilline" as one antibiotic of interest. |
| M14 | Result alphabet `S`, `SFP`, `R` (N9) | `as.sir()`, class `sir` | **Incompatible** by default | [D] `SFP` and `ZIT` become missing (A5). The class has no `SFP` level (dossier §6.9). |
| M15 | %R over tested isolates, no cell suppression (N11, N12) | `resistance()`, `count_R()`, `count_all()` | **Adapt**, and not needed | [D] The default hides counts under 30 (A5; `AMR v3.1.0:R/proportion.R:36`). [D] With `minimum = 0` and `guideline = "EUCAST"` the prototype matched hand arithmetic (`83eafc0:README:166-170`). [I] The core needs only that arithmetic. |
| M16 | Group rule `R` / `Ø` / `S` (N10) | `sir_combine(method = "most_resistant")` | **Incompatible** | [D] One `S` plus untested molecules gives a missing value (A6). In the SPF table that case is "Autres situations", rendered `S` (SPF p. 2; `docs/methods/08-indicateurs.md:27-32`). |
| M17 | SARM rule (N14) | None; codes `FOX`, `OXA`, `FOX-S`, `OXA-S`, `CLO` | **Incompatible**; codes only | [I] The precedence of cefoxitine is an ORCHIDEE rule on named identities (`docs/methods/08-indicateurs.md:142`). |
| M18 | BLSE and carbapenemase stored as a yes/no flag on the isolate, not as an antibiotic row (N13) | None | **Incompatible** | [D] AMR treats every input as a drug: the comment fields get drug codes (A1). These rows must never reach `as.ab()`. This row is about storage only. [D] Deduplication already compares the two flags (`docs/methods/07-dedoublonnage.md:29-31`); this proposal does not change that. |
| M19 | Natural-resistance audit, Test 5.1 (N16) | `mo_is_intrinsic_resistant()` | **Incompatible** as the reference | [D] Test 5.1 reads CA-SFM 2025 V1.1, Section 2, pp. 33-39 (`docs/methods/00-audit-qualite.md:270-286`). [D] AMR's table is built from another document (`AMR v3.1.0:R/data.R:348-354`) and changes between versions (A9). |
| M20 | Interpretation standard recorded, not re-applied (N17) | Breakpoint tables in `as.sir()` | **Not used** | [D] The prototype reinterprets no measurement (`83eafc0:README:169-170`). |
| M21 | Every output states its mapping versions (N8) | `packageVersion()`, checksums in `data-raw/*.md5` | **Adapt** | [I] Needs the manifest of section 5. |
| M22 | R modules for the core and the Rouen adapter (N21) | R package with no required dependency | **Direct** | [D] `AMR v3.1.0:DESCRIPTION:39-40`. R, not the Python wrapper (K10). |
| M23 | A licence position for ORCHIDEE | GPL-2 | **Adapt** | Section 3.3. |
| M24 | Keep screening samples out before deduplication (`ADR-0004`) | `first_isolate()` arguments `col_testcode`, `testcodes_exclude`, `col_specimen`, `specimen_group`; `as.sir(include_screening = )` | **Incompatible** | [D] AMR holds no list of screening samples. The caller supplies the test codes to drop (`AMR v3.1.0:R/first_isolate.R:37`, `:42`). [D] The drop runs after the first-isolate step (`AMR v3.1.0:R/first_isolate.R:514`), so a diagnostic isolate can be lost behind a screening one (A11). That is the reverse of "selection precedes deduplication". [I] It looks like an oversight, not a design: the only test of this argument checks that a message is printed (`AMR v3.1.0:tests/testthat/test-first_isolate.R:154-162`), and `specimen_group` selects before (A11). [I] It cannot occur in ORCHIDEE, where screening rows never reach the core (`CONTEXT.md:321-326`). It is a reason not to rely on these arguments, not a reason against AMR by itself. [D] `include_screening` is about screening breakpoints of a laboratory test, not about why a sample was taken (`AMR v3.1.0:R/sir.R:68`, `:1587-1590`). [D] `as.sir()` guesses urine samples by matching "urin" in a specimen column (`AMR v3.1.0:R/sir.R:850-853`): a text heuristic that `ADR-0003` keeps out of the core. The site classifies its samples (`CONTEXT.md:314-326`). |
| M25 | Deduplication by the rule of chapter 07 | `first_isolate()` | **Incompatible** | [D] By default one major discrepancy does not separate two isolates; the rule of `docs/methods/07-dedoublonnage.md:14-17` says it does (A12). [D] With `points_threshold = 1`, and every `SFP` read as `S` before the call, AMR gives the answers of that rule on these pairs (A12). Francesco, 2026-11-14: the project reads `I` as `S` for this comparison. `main` has the same effect: `S`/`SFP` is a minor difference (`docs/methods/07-dedoublonnage.md:58`) and `I` is read as `SFP` (`docs/methods/06-donnees-resistance.md:97`). Without that reading, two minor differences separate two isolates (A12). [D] AMR keeps the oldest isolate; the rule keeps the one with the most molecules tested (`docs/methods/07-dedoublonnage.md:23-24`; A12). [D] AMR's window is a number of days after the first isolate, 365 by default (`AMR v3.1.0:R/first_isolate.R:41`, `:132`); chapter 07 uses calendar windows (`docs/methods/07-dedoublonnage.md:56`). [I] The BLSE and carbapenemase flags are not drugs, so AMR does not compare them (M18). These three differences remain, so deduplication stays ORCHIDEE code in the core (decision 2). |

**Reading the matrix [I].** AMR fits three jobs: recognising organisms, giving
every site the same codes, and describing taxa and drugs. It does not fit
three others: deciding what a local antibiotic label means, holding the
corrections, and computing the indicators.

---

## 3. Responsibilities: site adapter, portable contract, core

### 3.1 Principle

**[I]** AMR lives entirely on the site side. This is the boundary already
agreed: the site adapter owns the mappings and the core reads only the site
handoff (`docs/adr/0003-portable-contract-is-the-product.md:3-5`, `:21-26`).

### 3.2 Who does what

| Step | Site adapter (local) | Portable contract (site handoff) | Core |
|---|---|---|---|
| Sort source rows by kind: antibiotic result, assay result, phenotype signal, comment | Does it first, from an approved routing list | Names the kinds | Never sees raw rows |
| Automatic recognition | Runs `as.mo()` and `as.ab()`, pinned, to fill the suggestion column | Carries the AMR version in the manifest | Never runs it |
| Approved mapping | Keeps the site mapping register; a biologist approves each line | Defines the identity fields, their allowed values and the status values | Checks that fields and status are valid; reports counts by status |
| Corrections of AMR defects shared by sites | Applies the shared overlay before showing a suggestion | — | — |
| Taxon groups (Enterobacterales, complexes) | Sends the taxon at the rank reported; never widens or narrows it | Carries taxon code, name and rank | Owns the membership tables |
| Indicator antibiotic groups, SARM rule, `R`/`Ø`/`S` rule, denominators | — | — | Owns them (chapter 08) |
| Result alphabet | Maps local values to `S`, `SFP`, `R` (`docs/methods/06-donnees-resistance.md:80-98`) | `S`, `SFP`, `R` | Uses them as they are |
| Phenotypes | Maps local signals to `blse` and `carbapenemase` (`docs/methods/06-donnees-resistance.md:106-117`) | Two isolate attributes | Applies Note Xa (ADR-0005) |
| Versions | Writes the mapping manifest | Defines its fields | Copies it into the indicator provenance |

Rules that follow:

- **R1.** The core never calls `as.mo()` or `as.ab()`, and never reads a label
  to decide anything.
- **R2.** In the adapter, a label is looked up in this order: the site mapping
  register, then the shared overlay, then AMR. Only the register approves. The
  overlay and AMR only suggest.
- **R3.** The register stays with the site. The handoff carries the identity,
  its status, and the version and checksum of the register. **[I]** Whether a
  copy of the register should travel with the handoff belongs to the open item
  "Common input fields" (`docs/methods/00-audit-qualite.md:583-585`).
- **R4.** The handoff carries the taxon name and rank next to the code, so the
  core can describe a taxon without installing AMR.
- **R5.** `ref/rouen/atb_regex_map.csv` becomes a comparator and a source of
  candidate lines for the Rouen register (P4). **[D]** It is right where AMR is
  wrong on `CLAVENTIN`, `TEICOPLANINE` and `PENICILLINE G` (lines 14, 83, 19).
  It is wrong on `CLOXA` (line 21) and merges `GENTAMICINE FORTE` into
  gentamicin (line 44).

### 3.3 Impact of the GPL-2 licence

Facts:

- **[D]** AMR is under GPL-2 (`AMR v3.1.0:DESCRIPTION:72`). Its authors
  summarise: free to use; a modified or redistributed copy must stay under
  GPL-2, with its source and a record of the changes
  (`AMR v3.1.0:LICENSE:9-24`).
- **[D]** The licence text covers copying, distribution and modification.
  Running the program is not restricted. Its output is covered only when the
  output itself contains a work based on the program
  (`AMR v3.1.0:LICENSE:40-45`).
- **[D]** ORCHIDEE has no licence file on `main` (dossier §8).

Consequences, as a reading and not as legal advice **[I]**:

| Situation | Reading |
|---|---|
| A hospital runs AMR inside its site adapter | Plain use. No duty. |
| The handoff holds AMR codes and names (`TEC`, `B_ESCHR_COLI`) | Output of a run, made of identifiers. Low risk. |
| ORCHIDEE distributes adapter code that loads AMR | The cautious reading is that this code needs a GPL-compatible licence. |
| The core never loads AMR | The core's licence stays a free choice. This is one more reason for rule R1. |
| ORCHIDEE copies AMR's tables into its repository, or edits them | That is redistribution of a part of AMR: GPL-2 applies to those files. The tables also come from outside sources with their own terms (dossier §8). Avoid it: pin AMR by version and checksum instead. |
| ORCHIDEE patches AMR (as the Python trial patched the wrapper, K10) | A distributed patch must be GPL-2 and documented. Avoid it: correct in the overlay. |

**[V:legal]** ORCHIDEE needs a licence choice before any code is handed to
another site or to PDS / HDH. The choice is part of decision 2.

---

## 4. Identity model

### 4.1 Recognition and approval are two columns

**[I]** Each site keeps one **mapping register**: one line per distinct source
label. It holds the suggestion and the approval side by side, and never copies
one into the other without a person.

| Column | Content |
|---|---|
| `source_field` | The local field the label comes from (at Rouen: `IDENTIFICATION` or `LBLANA`). |
| `source_label` | The exact label. |
| `row_kind` | `organism`, `antibiotic_result`, `assay_result`, `phenotype_signal` or `comment`. Set before any recognition. |
| `suggestion` | What the shared overlay or AMR returned, with the AMR version and the uncertain flag. Never edited by hand. |
| `identity` | The approved identity (sections 4.2 and 4.3). Empty until a review. |
| `status` | See below. |
| `approved_by`, `approved_on`, `basis` | Who approved, when, and why. |

Status values:

| Status | Meaning | Feeds indicators? |
|---|---|---|
| `approved` | A person reviewed the line. | Yes |
| `auto` | Organism labels only: AMR recognised the label without an uncertain flag, and nobody reviewed it. | Decision 1 |
| `pending` | A suggestion exists; no review yet. | No. The rows stay in the handoff as unassigned and are counted. |
| `unassigned` | No identity can be given. | No. Visible in the inventory (N6). |
| `not_a_result` | A comment or technical field. | No. Kept locally. |

### 4.2 Organism identity

Fields: `taxon_code` (AMR code), `taxon_name`, `taxon_rank`, and
`reported_taxon_code` with `reported_taxon_name` when the laboratory used a
former name.

Rules:

- **T1. Keep the rank that was reported.** A complex stays a complex; a
  species stays a species. Nothing is narrowed or widened (N7).
- **T2. A group is not part of the identity.** "Enterobacterales" and
  "*Enterobacter cloacae* complex" are membership tables in the core. Each
  table names the document it follows and its version.
- **T3. A label that covers several species and has no AMR taxon gets a local
  taxon declared in the contract**, at rank "species group". A code made by
  `add_custom_microorganisms()` is not portable (A8).
- **T4. Keep the reported name next to the current name.** Indicators use the
  current taxon. A comparison with the SPARES thesaurus can use the reported
  one.

Examples that tell the rules apart:

| Label or name | AMR suggestion [D] | Proposed identity (draft) | What it shows |
|---|---|---|---|
| `Enterobacter complexe cloacae` | Subspecies *E. cloacae cloacae*, flagged (A8) | *E. cloacae* complex, rank species group | The suggestion narrows a complex to a subspecies. The prototype showed the fix (`83eafc0:run.R:182-198`). T1. |
| *Enterobacter roggenkampii* | Species (A8) | Species | It is in the complex for CA-SFM 2025 V1.1 (p. 34, note 3). It is not in the SPF list (SPF p. 2) nor in AMR's group. T2. |
| `Enterobacter nimipressuralis` | *Lelliottia nimipressuralis* (A8) | Current: *Lelliottia*; reported: *Enterobacter* | The SPF list names it inside the complex (SPF p. 2). A rule "genus = Enterobacter" would drop it. T2, T4. |
| `Enterobacter aerogenes` | *Klebsiella aerogenes* (A8) | Current: *Klebsiella*; reported: *Enterobacter* | The thesaurus still lists the former name (SPARES Annexe 5, p. 28). A count by genus changes side. T4. |
| `Staphylococcus argenteus / schweitzeri (ex S. aureus)` | `UNKNOWN` (A8) | A declared local taxon | Two species under one label (dossier §5, K4). [V:bio] Whether SARM counts it. T3. |

### 4.3 Antibiotic-result identity

**[I]** One result is identified by four typed parts and one free part.

| Part | Question it answers | Values (short closed lists, to complete) | When absent |
|---|---|---|---|
| `molecule` | Which substance? | An AMR drug code, or a declared joint identity (decision 6) | Required |
| `test` | What did the laboratory measure? | `susceptibility` (the usual antibiogram result), `high_level`, `screen`, `inhibition`, `combination` | `susceptibility` |
| `formulation` | For which form of the drug is the result read? | `iv`, `oral`, `trometamol` | None |
| `context` | For which clinical reading? | `meningitis`, `cystitis`, `other_contexts` | None |
| `qualifier` | Anything else, kept word for word | Free text, such as `250` or `FORTE` | None |

**[D]** AMR folds molecule and test into one code for a fixed list of cases:
`GEH` is gentamicin with a high-level test (A7). **[I]** The contract keeps the two parts
apart, with a small table that links them to AMR's codes. So the contract does
not depend on AMR having a code for every test.

Examples, with labels from `3e48bdf:prepare:17-56`. Every proposed identity is a
draft; none is approved. The second column shows what AMR returns, errors
included. The third column is the identity this file proposes instead.

| Labels | What AMR returns [D] (A1) | Proposed identity | What a merge would break |
|---|---|---|---|
| `PENI G MENINGITE`, `PENI G AUTRES CONTEXTES` | Penimepicycline; nothing | `PEN` with context `meningitis`; `PEN` with context `other_contexts` | One isolate can hold two different results for one molecule. |
| `AUGMENTIN CYSTITE`, `AUGMENTIN AUTRES CONTEXTES` | Calcium aminosalicylate; nothing | `AMC` with context `cystitis`; `AMC` with context `other_contexts` | The same. The legacy map kept the cystitis reading apart (`ref/rouen/atb_regex_map.csv:5`). |
| `FOSFOMYCINE IV`, `FOSFOMYCINE TROMETAMOL` | Fosfomycin; vancomycin-macromethod | `FOS` with formulation `iv`; `FOS` with formulation `trometamol` | Two different tests of one molecule (`ref/rouen/atb_regex_map.csv:59-60`). |
| `GENTAMICINE`, `GENTAMICINE FORTE` | Gentamicin for both | `GEN`; `GEN` with test `high_level` [V:bio] | High-level results would enter the gentamicin %R (K5). |
| `CLOXA 250`, `CLOXA 500` | Cloxacillin | `CLO`, test `inhibition` [V:bio], qualifier `250` or `500` | It is likely not a treatment result. It is not a SARM marker (fixed input 3). |
| `CLAVENTIN` | Amoxicillin/clavulanic acid (wrong) | `TCC`, ticarcillin/clavulanic acid | AMR repeats the measured error of `docs/findings.md:45-52`. |
| `TEICOPLANINE` | Avoparcin (wrong) | `TEC`, teicoplanin | Teicoplanin is one of the two glycopeptides of the group (SPF p. 3). |
| `AMOXICILLINE / AMPICILLINE` | Amoxicillin/sulbactam | A joint identity "amoxicillin or ampicillin" (decision 6) | The enterococci group lists both molecules (SPF p. 3). |
| `COMMENTAIRE BLSE` | Cefuroxime/metronidazole | Not a result: `phenotype_signal` or `comment` [V:bio] | A comment would become an antibiotic result. |

### 4.4 Two identities and the rule between them

This answers the open item "declare the antibiotic counting identities and
their relationship to result-resolution identities"
(`docs/methods/00-audit-qualite.md:595-597`).

- **Result identity**: the full set of parts in 4.3. It stores results and
  resolves repeated records for one isolate (`CONTEXT.md:280-284`).
- **Counting identity**: what an indicator counts, a molecule or a group of
  molecules for a taxon. A declared rule says which result identities feed it.

**[I]** Two rules are proposed; decision 4 settles them.

1. Only results with `test = susceptibility` enter the antibiotype panel and
   the %R. An assay result is kept, and is used only by a rule that names it.
2. When one molecule has several contexts or formulations, each is its own
   panel entry, and each indicator names the entry it reads.

### 4.5 Rows that are not antibiotic results

**[D]** The prototype keeps seven fields outside molecule matching
(`3e48bdf:prepare:47-53`); `as.ab()` gives each of them a drug code (A1).
**[I]** So the kind of a row is set first, from an approved routing list, and
only `antibiotic_result` and `assay_result` rows are shown to `as.ab()`.
**[V:bio]** Which of these fields carry a BLSE or carbapenemase signal for
`docs/methods/06-donnees-resistance.md:111-112`.

---

## 5. Versioning AMR references and local corrections

### 5.1 Three objects, three versions

| Object | Owner | It changes when | Identified by |
|---|---|---|---|
| AMR reference | AMR authors; pinned by the adapter | A new AMR release is adopted | Package version, checksum of the installed source archive, checksums of the reference tables (AMR ships them in `data-raw/*.md5`) |
| Shared overlay: corrections of AMR defects that every French site would meet | ORCHIDEE, with the adapter tooling, outside the core | A defect is found, or fixed upstream | Its own version and checksum |
| Site mapping register | The site | A label appears, or a review changes a line | Its own version and checksum |

### 5.2 Rules

- **V1. Approved identities are stored values.** They are not recomputed from
  AMR at run time. Upgrading AMR cannot change a result silently.
- **V2. The adapter stops when the AMR version is not the pinned one.** The
  prototype already does this (`83eafc0:run.R:14-17`, `:23`).
- **V3. No hidden settings.** Every argument with a default that changes the
  answer is written out (`keep_synonyms`, `Becker`, `Lancefield`, `language`).
  The adapter checks that the AMR options that change behaviour are unset:
  `AMR_keep_synonyms`, `AMR_guideline`, `AMR_custom_ab`, `AMR_custom_mo`,
  `AMR_mo_source`, `AMR_cleaning_regex`, `AMR_ignore_pattern`, `AMR_locale`
  (`AMR v3.1.0:R/aa_options.R:40-58`).
- **V4. One text encoding, UTF-8.** **[D]** In a non-UTF-8 session, `as.sir()`
  stopped on a value with an accent during the checks of section 1.
- **V5. A mapping manifest travels with the handoff**: AMR version and
  checksums, overlay version, register version, and the count of labels and of
  result rows by status. The indicator table gains a `mapping_version` next to
  `perimeter_version` and `deduplication_hash`
  (`docs/methods/08-indicateurs.md:75`). This serves the rule that every output
  states its mapping versions (`docs/methods/00-audit-qualite.md:338-341`).
- **V6. An upgrade is a reviewed change.** Run the new version on the whole
  register and produce three lists: suggestions that changed, approved codes
  that were renamed or retired, and taxa whose current name or group membership
  changed. A person approves the lists. If an indicator can move, a witness is
  measured first.
- **V7. A short list of fixed labels is checked at every run**, in the manner
  of a tripwire: for example, `TEICOPLANINE` must resolve to `TEC`.
- **V8. Defects are reported to the AMR authors.** The overlay line stays even
  after a fix, as a check.

### 5.3 AMR 3.1.0 against the current version

- **[D]** 3.1.0 is the latest numbered release: the repository's last tag is
  `v3.1.0` (2026-10-16). The current development version is 3.1.0.9021
  (2026-11-09). **[V]** CRAN could not be reached from the environment used
  here, so the CRAN version is not confirmed.

| Area | 3.1.0 → 3.1.0.9021 | Matters for ORCHIDEE? |
|---|---|---|
| Drug table and `as.ab()` | [D] Same table content; same answers on every label of A1 to A4 | No. The teicoplanin and penicillin defects remain (A3). |
| Organism table, groups, breakpoints | [D] Same files (same checksum) | No |
| `intrinsic_resistant` | [D] 62 more lines; complexes now listed (A9; `AMR dev:NEWS.md:35`) | Only if AMR served Test 5.1. It does not (M19). |
| `mo_shortname()` for *Salmonella*; WISCA fix | [D] `AMR dev:NEWS.md:3-6` | No; not used |

**[I]** Recommendation: stay on 3.1.0. Nothing in the development version
helps ORCHIDEE, and one change would move an audit result if AMR were used
for it.

**[D]** Points inside 3.1.0 that the design relies on or guards against: the
new correction hook and its refusal rule (A4); the `guideline` argument, with a
default that is only announced by a message (dossier §6.8); the registry of
organism codes (`AMR v3.1.0:NEWS.md:57`).

---

## 6. Decisions still needed

Seven decisions, ordered by impact. Each gives the alternatives, a
recommendation, and an example where the alternatives give different results.

### Decision 1. What may enter the handoff: approved lines only, or AMR's suggestion unless corrected?

- **A. Allow-list.** Every label needs an approved line. Without one, the
  results stay `pending`: counted by the audit, used by no indicator.
- **B. Deny-list.** AMR's suggestion is used unless a correction exists.
- **C. Mixed.** A for antibiotic and test labels. For organism labels, an
  unflagged suggestion is accepted as `auto`, except when it lands in one of
  the target taxa of the SPF list (SPF p. 2): those need an approved line.

**Recommendation: C.**

**Example.** `TEICOPLANINE`: under B it becomes avoparcin with no warning, and
the glycopeptide group of the enterococci loses one of its two molecules
(SPF p. 3). Under A or C it waits until someone approves `TEC`. `CLAVENTIN`:
under B the 51-isolate error returns (`docs/findings.md:45-52`). For organisms
the risk is lower: every thesaurus name is recognised and the wrong guesses of
A8 were flagged.

**Evidence.** [D] A1, A2, A3, A8, A10. [D] The antibiotic label list is
finite: the prototype's review covers the complete list
(`83eafc0:README:71-73`). [V:data] Its size, and how many result rows each
status would hold in the diagnostic population.

### Decision 2. Is AMR allowed in the core?

- **A. No.** AMR runs in the site adapter only. The core applies ORCHIDEE's own
  rules to contract codes: explicit molecule lists for each group, its own
  `R`/`Ø`/`S` rule, its own counts. ORCHIDEE picks a licence; adapter tooling
  that loads AMR gets a GPL-compatible one.
- **B. Yes.** The core calls AMR's selectors, `sir_combine()`, `resistance()`
  and `mo_order()`.

**Recommendation: A.**

**Examples.** An isolate with cefotaxime `S`, ceftazidime and ceftriaxone
untested: the SPF table renders `S`, so it is in the denominator (SPF p. 2);
`sir_combine()` returns a missing value, so it leaves the denominator (A6). An
*E. coli* resistant to cefixime only: `cephalosporins_3rd()` holds cefixime, so
B counts it as C3G-resistant; the C3G group does not list cefixime (SPF p. 2;
A7). A count of 12 isolates: B hides the rate unless every call sets
`minimum = 0` (A5).

**Evidence.** [D] A5, A6, A7. [I] The licence reading of section 3.3.
[V:legal] The licence choice.

### Decision 3. How is an antibiotic result identified?

- **A. Typed parts**: molecule, test, formulation, context, plus a free
  qualifier (section 4.3).
- **B. Molecule plus one free-text qualifier**, as in the prototype draft
  (`3e48bdf:prepare:17-39`, P7).
- **C. One name per label**, as in the legacy map
  (`amoxicilline_acide_clavulanique_cystite`, `ref/rouen/atb_regex_map.csv:5`).

**Recommendation: A.**

**Example.** "Leave high-level aminoglycoside tests out of gentamicin %R."
Under A the core reads `test = high_level`, at every site. Under B the core has
to read the word `FORTE`, and another word at another site: this is the string
reading the contract forbids (ADR-0003). Under C every site invents its own
names and the core cannot tell that two names share a molecule.

**Evidence.** [D] P7 and K6 in the dossier; A1. [V:bio] The meaning of each
qualifier (section 7).

### Decision 4. When one molecule has several results on an isolate, which one counts?

Two linked rules (section 4.4).

- **Assay results.** A: only `test = susceptibility` enters the antibiotype
  panel and the %R. B: every result of the molecule enters.
- **Contexts and formulations.** A: each is its own panel entry, and each
  indicator names the entry it reads. B: collapse to the molecule, the most
  resistant result wins. C: collapse to the molecule with a fixed order of
  preference.

**Recommendation: A for both.** The entry each indicator reads needs a
biologist.

**Example.** A patient has two isolates of one species. The first holds only
`PENI G MENINGITE` = `R`. The second holds only `PENI G AUTRES CONTEXTES` =
`S`. Under B the two isolates differ by `S`/`R` on penicillin G: a major
discrepancy, so both are counted (`CONTEXT.md:301-304`). Under A no panel entry
is tested in both, so they are compatible and one is retained. The choice
changes the number of isolates, and so every denominator.

**Evidence.** [D] Widening the panel changes which isolates are duplicates
(`CONTEXT.md:286-290`). [D] The amoxicillin/clavulanic acid column is sensitive
to mapping (`docs/findings.md:45-52`). [V:data] How many isolates hold two
contexts of one molecule with different results. [V:bio] Which context each
SPF molecule should read.

### Decision 5. Who defines taxon groups, and from which document?

- **A. The core owns one membership table per group.** Each table names the
  document it follows. AMR supplies the first draft.
- **B. Computed from AMR at run time** (`mo_order()`, `microorganisms.groups`).
- **C. Each site decides in its adapter.**

**Recommendation: A.**

**Already settled (Francesco, 2026-11-13).** The content of two groups: the
whole taxonomic order for "toutes Enterobacterales" (M6), and the six-species
list of SPF p. 2 for the *E. cloacae* complex (Q8). Who owns the tables, A, B
or C, is still open.

**Examples.** *E. roggenkampii*: in the complex for CA-SFM 2025 V1.1 (p. 34,
note 3), outside it for the SPF list (SPF p. 2) and for AMR (A8). Under B the
answer is AMR's and can change with an upgrade. Under C two sites can differ.
*Salmonella*, *Shigella*, *Yersinia*: inside "Enterobacterales" under B (A10),
and inside the indicator of SPF p. 4 on the project reading (Francesco,
2026-11-13; M6). Under A the table states that reading and its source. Under B
it rests on AMR's taxonomy and can move with an upgrade. The label
`Staphylococcus argenteus / schweitzeri (ex S. aureus)`: inside or outside
*S. aureus* for SARM [V:bio].

**Evidence.** [D] A8, A10. [D] `main` leaves species and complex treatment
open (`docs/methods/06-donnees-resistance.md:138-141`; P17).

### Decision 6. What identity do joint and family labels get?

- **A. A declared joint identity** with its member molecules. It satisfies a
  group rule when the group lists all its members.
- **B. Pick one molecule**, as the legacy map does for `NITROFURANES`
  (`ref/rouen/atb_regex_map.csv:58`).
- **C. Leave unassigned** until the meaning is known.

**Recommendation: A for `AMOXICILLINE / AMPICILLINE`; C for `NITROFURANES`,
the class labels and the `ASSO …` labels until a biologist gives their
meaning.**

**Example.** An *E. faecium* whose only beta-lactam result is
`AMOXICILLINE / AMPICILLINE` = `R`. Under A it is `R` for the beta-lactam group
of the enterococci, which lists amoxicilline and ampicilline (SPF p. 3). Under
AMR's suggestion (amoxicillin/sulbactam, A1) neither molecule is documented:
the result is `Ø` and the isolate leaves the denominator.

**Evidence.** [D] A1; SPF Annexe 3 (p. 20) lists the joint antibiotic; the
legacy map already has a joint identity (`ref/rouen/atb_regex_map.csv:2-4`).
[V:bio] The six labels of `3e48bdf:prepare:55-56`.

### Decision 7. Which AMR version, and who keeps the corrections?

- **A. Pin 3.1.0.** Upgrade only through rule V6. ORCHIDEE keeps the shared
  overlay and reports defects to the AMR authors.
- **B. Follow the latest release.**
- **C. Copy AMR's tables into the repository and edit them.**

**Recommendation: A.**

**Example.** The teicoplanin defect is in 3.0.1, 3.1.0 and the development
version (A3): under B it stays, and AMR's own hook cannot fix it (A4). Under C
the fix is easy, but the copied tables fall under GPL-2 and stop following
AMR (section 3.3). Under B, one audit answer changed between two builds less
than a month apart (A9).

**Evidence.** [D] A3, A4, A9; section 5.3.

---

## 7. Verifications that need data, a biologist or an outside answer

| # | Question | Needs | Blocks |
|---|---|---|---|
| Q1 | Review of the full Rouen label lists, organisms and antibiotics, in the **diagnostic** population and for 2022-2024. The prototype used 2024 and all sample types (`83eafc0:README:91-96`, `:176-180`). | data | Decision 1; any witness |
| Q2 | Number of isolates that hold two contexts or formulations of one molecule with different results. | data | Decision 4 |
| Q3 | Is `GENTAMICINE FORTE` a high-level gentamicin test? | bio | Section 4.3 |
| Q4 | What do `CLOXA 250` and `CLOXA 500` measure on Gram-negative species? An AmpC inhibition test is the likely reading (dossier §5, K4). | bio | Section 4.3 |
| Q5 | What do `PIPERA TAZO` (next to `PIPERACILLINE+TAZOBACTAM`), `NORFLO DEPIST RCC FQUINOLONES`, `NITROFURANES`, the two `ASSO …` labels and `CEFINASE` mean? Is `AUTRES CONTEXTES` one reading or several? | bio | Decisions 3, 6 |
| Q6 | Which comment fields carry a BLSE, carbapenemase, SARM or ERG signal? | bio, data | Section 4.5; N13 |
| Q7 | Which context should each SPF molecule read (amoxicillin/clavulanic acid, fosfomycin)? | bio, ext | Decision 4 |
| Q8 | **Closed on 2026-11-13 by Francesco.** "Toutes Enterobacterales" means the whole taxonomic order (M6). The *E. cloacae* complex follows the six-species list of SPF p. 2. The species that only CA-SFM 2025 V1.1 adds (p. 34, note 3: *E. roggenkampii* and three others) stay outside for now. The choice is easy to change later. | none | Nothing |
| Q9 | Does the label `Staphylococcus argenteus / schweitzeri (ex S. aureus)` count as *S. aureus* for SARM? | bio | Decision 5 |
| Q10 | Which identities count as cefoxitine and oxacilline for SARM at a site that reports screening tests (`FOX-S`, `OXA-S`)? Rouen reports only `OXACILLINE` (dossier §5, K4). | bio | Other sites |
| Q11 | Licence of ORCHIDEE, and of adapter tooling that loads AMR. | legal | Decision 2 |
| Q12 | Confirm on the user's machine (R 4.6.1, AMR 3.1.0 from CRAN) that the appendix script prints the same lines. | data-free run | Confidence in section 1 |

---

## 8. Where `main` and the prototype branches disagree

Only the conflicts this design touches. "Better supported" is a judgement
**[I]**, with its reason.

| Topic | `main` | Branch or user | Better supported |
|---|---|---|---|
| Organism mapping base (K1, P1, P3) | Previous ORCHIDEE mappings, improved (`docs/methods/06-donnees-resistance.md:130-133`, `:156`) | AMR plus local corrections (`83eafc0:README:55-56`) | **Branch.** Fixed input 1; A10 adds support. |
| Antibiotic mapping base (K1, P2, P4) | Same `main` lines | AMR, corrected by a finite label review (`83eafc0:README:58-59`) | **The branch's review process, with a narrower role for AMR.** AMR gives the codes and a suggestion. The approved register is the mapping. The legacy map is a comparator that is sometimes right against AMR (rule R5). |
| Result alphabet (K2, P13) | `S`, `SFP`, `R` (`docs/methods/06-donnees-resistance.md:80-98`) | `SFP` and `ZIT` passed as `I` (`83eafc0:run.R:156`) | **`main`.** With AMR out of the core, the conversion to `I` is no longer needed (decision 2). |
| Context and formulation words (K6, P7) | Open (`docs/methods/00-audit-qualite.md:595-597`) | Molecule plus qualifier (`3e48bdf:prepare:15-16`) | **Branch direction**, made stricter by typed parts (decision 3). |
| High-level gentamicin (K5, P8) | Silent | Kept apart, `GEH` as candidate (`3e48bdf:prepare:27-28`) | **Branch**, once Q3 is answered. |
| Complex treatment (P17) | Open | Demonstrated, not applied (`83eafc0:README:172-174`) | **Neither yet.** Decision 5. |
| Natural-resistance reference (N16) | CA-SFM 2025 V1.1, Section 2, pp. 33-39 (`docs/methods/00-audit-qualite.md:270-286`) | Not addressed | **`main`.** AMR's function is not a substitute (M19). |

---

## 9. What this proposal would change elsewhere (not done here)

If the decisions of section 6 are taken, these texts would need an update.
None is edited by this pull request.

- `docs/methods/06-donnees-resistance.md`, section 6, decision 06.8 and Open:
  the mapping base and the identity model.
- `docs/adr/0003-portable-contract-is-the-product.md:31-35`: the sentence on
  the previous mappings.
- `docs/methods/00-audit-qualite.md:595-598`: the counting identities.
- `ref/README.md:3-5`: the status of `ref/rouen/atb_regex_map.csv` (K11).
- `CONTEXT.md`: new terms. Proposed wording:
  - **Automatic recognition**: the identity a tool suggests for a source
    label. Never used as a mapping without approval.
  - **Mapping register**: a site's list of source labels with, for each, the
    suggestion, the approved identity and its status.
  - **Shared overlay**: corrections of the reference tool that apply to every
    site, kept outside the core.
  - **Result identity** and **counting identity**: as in section 4.4.
  - **Taxon group**: a membership table owned by the core, tied to a named
    document.
- `docs/findings.md`: one entry for the teicoplanin defect (A3).
- `docs/methods/tripwire-register.md`: the fixed-label check of rule V7.

---

## Appendix: the check script

`Rscript --vanilla check.R <library with AMR> [file with one Annexe 5 name per line]`.
The Annexe 5 names were taken from the SPARES PDF with `pdftotext -layout`
(pages 28-30), joining names broken over two lines.

<details>
<summary>check.R (105 lines)</summary>

```r
args <- commandArgs(trailingOnly = TRUE)
.libPaths(c(args[1], .libPaths()))
suppressPackageStartupMessages(library(AMR))
cat("AMR", as.character(packageVersion("AMR")), "|", R.version.string, "\n")
q <- function(expr) suppressWarnings(suppressMessages(expr))
ab <- function(x) as.character(q(as.ab(x, language = "fr", info = FALSE)))

# A1: the 34 labels named in prepare-antibiotic-review.R (3e48bdf, lines 17-56)
corrections <- c(TEICOPLANINE="TEC", "PENICILLINE G"="PEN", "PENI G MENINGITE"="PEN", "PENI G AUTRES CONTEXTES"="PEN",
  "AUGMENTIN CYSTITE"="AMC", "AUGMENTIN AUTRES CONTEXTES"="AMC", CLAVENTIN="TCC", "FOSFOMYCINE TROMETAMOL"="FOS",
  "PIPERA TAZO"="TZP", "GENTAMICINE FORTE"="GEH", "GENTAMICINE FORTE."="GEH", "CEFOTAXIME AUTRES CONTEXTES"="CTX",
  "CEFOTAXIME MENINGITE"="CTX", "CETRIAXONE AUTRES CONTEXTES"="CRO", "CEFTRIAXONE MENINGITE"="CRO", "AMOX MENINGITE"="AMX",
  "AMPI AUTRES CONTEXTES"="AMP", "AMOX VO"="AMX", "FOSFOMYCINE IV"="FOS", "CLOXA 250"="CLO", "CLOXA 500"="CLO")
got <- ab(names(corrections))
cat("A1 draft corrections: AMR equals the draft code for", sum(got == corrections, na.rm = TRUE), "of", length(corrections), "\n")
print(data.frame(label = names(corrections), amr = got, draft = unname(corrections), same = !is.na(got) & got == corrections), row.names = FALSE)
non_molecule <- c("Technique ATB", "Commentaire C3G", "COMMENTAIRE SAMR", "COMMENTAIRE BLSE", "COMMENTAIRE CARBA", "COMMENTAIRE ERG", "CEFINASE")
g <- ab(non_molecule); cat("A1 non-molecule fields given a drug code:", sum(!is.na(g)), "of", length(g), ":", paste(non_molecule, g, sep = "=", collapse = "; "), "\n")
unresolved <- c("AMOXICILLINE / AMPICILLINE", "AMPICILLINE/AMOXICILLINE", "NITROFURANES", "NORFLO DEPIST RCC FQUINOLONES", "ASSO AZTRE/CAZA", "ASSO AUGMENTIN/CEFIXIME")
g <- ab(unresolved); cat("A1 unresolved labels given a drug code:", sum(!is.na(g)), "of", length(g), ":", paste(unresolved, g, sep = "=", collapse = "; "), "\n")

cls <- c("C3G", "FLUOROQUINOLONES"); g <- ab(cls); cat("A1 class labels (legacy map patterns, lines 28 and 49):", paste(cls, g, sep = "=", collapse = "; "), "\n")

# A2: plain French names of the molecules in the SPF groups (SPF pp. 2-4)
spf <- c(OFLOXACINE="OFX", LEVOFLOXACINE="LVX", MOXIFLOXACINE="MFX", CIPROFLOXACINE="CIP", CEFOTAXIME="CTX", CEFTAZIDIME="CAZ",
  CEFTRIAXONE="CRO", ERTAPENEME="ETP", IMIPENEME="IPM", MEROPENEME="MEM", CEFOXITINE="FOX", OXACILLINE="OXA", AMOXICILLINE="AMX",
  AMPICILLINE="AMP", VANCOMYCINE="VAN", TEICOPLANINE="TEC", "PIPERACILLINE-TAZOBACTAM"="TZP", CEFEPIME="FEP")
g <- ab(names(spf)); cat("A2 SPF molecules recognised correctly:", sum(g == spf, na.rm = TRUE), "of", length(spf), "; wrong:", paste(names(spf)[is.na(g) | g != spf], g[is.na(g) | g != spf], sep = "=", collapse = "; "), "\n")

# A3: AMR's own French names, mapped back
a <- as.data.frame(AMR::antimicrobials)
fr <- ab_name(a$ab, language = "fr"); back <- ab(fr)
bad <- which(is.na(back) | back != as.character(a$ab))
cat("A3 French-name round trip failures:", length(bad), "of", nrow(a), ":", paste0(fr[bad], " -> ", back[bad], collapse = "; "), "\n")
cat("A3 synonyms of AVO:", paste(unlist(a$synonyms[a$ab == "AVO"]), collapse = ", "), "| synonyms of TEC:", paste(unlist(a$synonyms[a$ab == "TEC"]), collapse = ", "), "\n")

# A4: AMR's own correction hook
for (p in list(c("TEC", "TEICOPLANINE"), c("PEN", "PENICILLINE G"), c("TCC", "CLAVENTIN"))) {
  r <- tryCatch({ q(add_custom_antimicrobial_synonyms(p[1], p[2])); "accepted" }, error = function(e) "refused")
  cat("A4 add synonym", p[2], "->", p[1], ":", r, "; as.ab now gives", ab(p[2]), "\n")
}
clear_custom_antimicrobials()

# A5: result alphabet
cat("A5 as.sir(c('S','SFP','I','R','ZIT')):", paste(as.character(q(as.sir(c("S", "SFP", "I", "R", "ZIT")))), collapse = " "), "\n")
v <- c("R", "R", "R", "I", "I", "S", "S", "S", "S", "S")
cat("A5 resistance() default:", q(resistance(v)), "| minimum=0, EUCAST:", q(resistance(v, minimum = 0, guideline = "EUCAST")), "| minimum=0, CLSI:", q(resistance(v, minimum = 0, guideline = "CLSI")), "\n")

# A6: group rule
ctx <- as.sir(c("R", "S", NA, "S")); caz <- as.sir(c("S", "S", NA, NA)); cro <- as.sir(c(NA, "S", NA, NA))
cat("A6 sir_combine most_resistant (CTX,CAZ,CRO) for R/S/-, S/S/S, -/-/-, S/-/-:", paste(as.character(q(sir_combine(ctx, caz, cro, method = "most_resistant", guideline = "EUCAST"))), collapse = " "), "\n")

# A7: class selectors
n <- function(f) length(q(f()))
cat("A7 selector sizes: cephalosporins_3rd", n(cephalosporins_3rd), "| carbapenems", n(carbapenems), "| fluoroquinolones", n(fluoroquinolones), "| glycopeptides", n(glycopeptides), "\n")
cat("A7 in cephalosporins_3rd():", paste(c("CFM", "CZA", "CPD") %in% as.character(q(cephalosporins_3rd())), collapse = " "), "(CFM, CZA, CPD) | AVO in glycopeptides():", "AVO" %in% as.character(q(glycopeptides())), "\n")
lab <- a[grepl("screening test|-high$|macromethod", a$name), c("ab", "name")]
cat("A7 laboratory-test entries:", nrow(lab), ":", paste(lab$ab, collapse = " "), "\n")

# A8: organisms
mo <- function(x, ...) q(as.mo(x, info = FALSE, ...))
x <- c("Enterobacter complexe cloacae", "Enterobacter cloacae complex", "Staphylococcus argenteus / schweitzeri (ex S. aureus)", "Enterobacter aerogenes", "Enterobacter nimipressuralis", "Enterobacter roggenkampii", "Levures", "Flore polymorphe")
m <- mo(x); u <- mo_uncertainties()
print(data.frame(label = x, mo = as.character(m), name = q(mo_name(m)), rank = q(mo_rank(m)), uncertain = x %in% u$original_input), row.names = FALSE)
grp <- AMR::microorganisms.groups; mem <- grp[grp$mo_group_name == "Enterobacter cloacae complex", ]
cat("A8 AMR members of Enterobacter cloacae complex:", paste(sort(mem$mo_name), collapse = "; "), "\n")
cat("A8 E. roggenkampii in AMR group:", as.character(mo("Enterobacter roggenkampii")) %in% as.character(mem$mo), "| groups in microorganisms.groups:", length(unique(grp$mo_group_name)), "\n")
cat("A8 keep_synonyms=TRUE for Enterobacter aerogenes:", as.character(mo("Enterobacter aerogenes", keep_synonyms = TRUE)), "\n")

q(add_custom_microorganisms(data.frame(genus = "Staphylococcus", species = "argenteus/schweitzeri", stringsAsFactors = FALSE)))
cat("A8 code given by add_custom_microorganisms():", as.character(mo("Staphylococcus argenteus/schweitzeri")), "\n")

# A9: intrinsic resistance
cat("A9 mo_is_intrinsic_resistant: E. cloacae complex + AMC =", q(mo_is_intrinsic_resistant("Enterobacter cloacae complex", ab = "AMC")), "| E. cloacae + AMC =", q(mo_is_intrinsic_resistant("Enterobacter cloacae", ab = "AMC")), "| rows:", nrow(AMR::intrinsic_resistant), "\n")

# A10: SPARES Annexe 5 names (optional second argument: one name per line)
if (length(args) >= 2) {
  x <- readLines(args[2], warn = FALSE); m <- mo(x); u <- mo_uncertainties()
  nm <- q(mo_name(m)); ord <- q(mo_order(m))
  cat("A10 Annexe 5 names:", length(x), "| UNKNOWN:", sum(as.character(m) == "UNKNOWN"), "| flagged uncertain:", sum(x %in% u$original_input),
      "| returned under another name:", sum(tolower(sub(" spp?$", "", x)) != tolower(nm)), "| in order Enterobacterales:", sum(ord == "Enterobacterales"), "\n")
  dup <- split(x, as.character(m)); dup <- dup[lengths(dup) > 1]
  cat("A10 Annexe 5 names sharing one AMR code:", length(dup), "codes:", paste(vapply(dup, paste, "", collapse = " + "), collapse = " | "), "\n")
  cat("A10 Enterobacterales genera:", paste(sort(unique(q(mo_genus(m[ord == "Enterobacterales"])))), collapse = ", "), "\n")
}

# A11: test-code exclusion in first_isolate(), on two invented rows
d <- data.frame(patient = c("P1", "P1"), date = as.Date(c("2024-01-01", "2024-01-05")), mo = mo(c("Escherichia coli", "Escherichia coli")), testcode = c("screen", "diag"))
r <- q(first_isolate(d, col_date = "date", col_patient_id = "patient", col_mo = "mo", col_testcode = "testcode", testcodes_exclude = "screen", method = "episode-based", info = FALSE))
cat("A11 first_isolate() with testcodes_exclude = 'screen':", paste(d$testcode, r, collapse = " | "), "\n")
f11 <- function(d, ...) paste(q(first_isolate(d, col_date = "date", col_patient_id = "patient", col_mo = "mo", method = "episode-based", info = FALSE, ...)), collapse = " ")
e <- rbind(d, d[2, ]); e$date[3] <- as.Date("2024-01-09"); e$specimen <- c("rectal", "blood", "blood")
cat("A11 screening row removed before the call:", f11(d[d$testcode != "screen", ]), "| upper-case codes in the data, exclude 'SCREEN':", f11(transform(d, testcode = toupper(testcode)), col_testcode = "testcode", testcodes_exclude = "SCREEN"), "\n")
cat("A11 rectal, blood, blood with specimen_group = 'blood':", f11(e, col_specimen = "specimen", specimen_group = "blood"), "\n")

# A12: first_isolate() against the duplicate rule of chapter 07, on invented pairs (one patient, E. coli, day 1 and day 5)
mk <- function(...) { r <- list(...); d <- data.frame(patient = c("P1", "P1"), date = as.Date(c("2024-01-01", "2024-01-05"))); d$mo <- mo(c("Escherichia coli", "Escherichia coli")); for (n in names(r)) d[[n]] <- q(as.sir(r[[n]])); d }
fi <- function(d, ...) paste(q(first_isolate(d, col_date = "date", col_patient_id = "patient", col_mo = "mo", info = FALSE, ...)), collapse = " ")
d1 <- mk(AMX = c("S", "R"), CIP = c("S", "S"), GEN = c("S", "S"))
d2 <- mk(AMX = c("S", "I"), CIP = c("S", "I"), GEN = c("S", "S"))
d3 <- mk(AMX = c("S", "S"), CIP = c(NA, "S"), GEN = c(NA, "S"))
cat("A12 one S->R: default", fi(d1), "| points_threshold = 1:", fi(d1, points_threshold = 1), "| keyantimicrobials:", fi(d1, type = "keyantimicrobials"), "\n")
cat("A12 two S->I, points_threshold = 1:", fi(d2, points_threshold = 1), "| same results, second isolate has more molecules tested:", fi(d3), "\n")
d2s <- mk(AMX = c("S", "S"), CIP = c("S", "S"), GEN = c("S", "S"))  # d2 with every I read as S
cat("A12 two S->I read as S, points_threshold = 1:", fi(d2s, points_threshold = 1), "\n")
```

</details>
