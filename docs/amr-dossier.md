# AMR integration: evidence dossier

Status: **evidence only**. This file collects what the repository and the AMR
package say about using AMR in ORCHIDEE v3. It does not design anything and it
proposes no solution. A later design step is expected to start from it.

Compiled 2026-11-12 from:

- `main` at `8c6652229f44ad0f58039af30899da373d57eba4` (the decisions taken);
- five candidate branches (listed in section 2);
- GitHub issue #26, the prototype's own log;
- AMR 3.1.0 source, tag `v3.1.0`, and the AMR development version on the
  `main` branch of `github.com/msberends/AMR` (`DESCRIPTION`: `Version:
  3.1.0.9021`, `Date: 2026-11-09`), both fetched on 2026-11-12.

## How to read this file

- **[F]** marks a fact read in a file, commit or issue. It cites where.
- **[I]** marks an inference: my reading, not something a file states.
- A citation `branch@sha:path:line` means: the file as it is at that commit.
  Paths on `main` are cited as `path:line` at `8c66522`.
- AMR citations read `AMR v3.1.0:path:line` (tag `v3.1.0`) or
  `AMR dev:path:line` (GitHub `main`, version 3.1.0.9021).
- No R session was run for this dossier. Statements about what an AMR function
  returns come from its source and documentation, not from execution, unless a
  branch reports a run.
- No hospital-data outputs were read. The branches keep measured counts in
  ignored local folders, and this file repeats none.

---

## 1. Short answers

### Where is the bacteria mapping you accepted?

**[F]** The accepted organism (bacteria) mapping is **AMR's `as.mo()` applied
to every distinct organism label**, plus local corrections. It is not a
committed table.

| What | Where |
|---|---|
| Acceptance recorded | branch `prototype/amr-label-review`, commit `3e48bdf`, `docs/worked-examples/amr-r-prototype/README.md:35-41`; also issue #26, comment of 2026-10-31 ("Accepted direction from the user: AMR will replace the DIY bacterial mapping, with local corrections") |
| Mapping code first written in direct R | branch `prototype/amr-r`, commit `6307a86`, `docs/worked-examples/amr-r-prototype/run.R:43-53` |
| Most complete branch (contains everything) | branch `prototype/amr-demo-ergonomics`, commit `83eafc0`; its `run.R` is identical to `f209fd7` and its `prepare-antibiotic-review.R` is identical to `3e48bdf` (empty `git diff`) |
| The mapped table itself | not in Git. `run.R` writes `outputs/amr-classification-prototype/organism-mapping.csv` (`prototype/amr-classification@f209fd7:docs/worked-examples/amr-r-prototype/run.R:9` and the `write.csv` call further down), and `/outputs/` is ignored (`.gitignore:5`) |

**[I]** So the branch to name is `prototype/amr-label-review` for the
decision, and `prototype/amr-demo-ergonomics` for the latest code. The
actual list of label-to-organism pairs exists only on the machine that ran the
prototype.

### Where is the antibiotics mapping ("good but needs work")?

**[F]** Same stack. AMR's `as.ab()` proposes a molecule for every result label
(`prototype/amr-r@6307a86:docs/worked-examples/amr-r-prototype/run.R:55-64`).
The "needs work" part is a **draft correction review**, written by
`prototype/amr-label-review@3e48bdf:docs/worked-examples/amr-r-prototype/prepare-antibiotic-review.R`.
It lists 21 proposed corrections or qualifiers (lines 17-39), 7 fields kept
outside molecule matching (lines 47-53) and 6 labels whose local meaning is
unknown (lines 55-68). It applies nothing (lines 1-2, 82). Its output,
`outputs/amr-classification-prototype/antibiotic-label-review.md`, is local
and ignored (line 99).

### Where are the v3 needs written down?

**[F]** There is no single "requirements" file. The needs are spread across:

1. `docs/methods/` chapters, which answer SPARES section by section and record
   each choice as a decision (`docs/methods/README.md:3-6`, `:65-76`). For
   AMR, chapters **00**, **06** and **08** matter most.
2. The two external source PDFs that the methods answer: the SPARES method and
   the SPF expression of needs (`docs/methods/README.md:9-10`).
3. `docs/adr/0003-portable-contract-is-the-product.md` (who owns mappings).
4. `CONTEXT.md` (the vocabulary the needs use).
5. Issue #1, the project map, for the planned implementation language and
   modules.

Section 4 lists the needs one by one with their sources.

---

## 2. Branch map

**[F]** The five branches form one straight line, each built on the previous
one. All start from the current `main` (`8c66522`); their merge base with
`main` is `8c66522` for every branch.

```
main 8c66522
 └─ prototype/amr-python          0ebeb94  2026-10-27  Python wrapper trial
     └─ prototype/amr-r           6307a86  2026-10-27  same trial, direct R (deletes the Python files)
         └─ prototype/amr-classification  f209fd7  2026-10-27  adds taxonomy and drug classes
             └─ prototype/amr-label-review     3e48bdf  2026-10-31  records the decision, drafts the antibiotic review
                 └─ prototype/amr-demo-ergonomics  a6069eb, a96cb63, 83eafc0  2026-10-31  demo page usability only
```

Full hashes: `0ebeb94dd8f766479897779dfc75d79d594f76a9`,
`6307a86dfbaafa6484c7592b2b5a0c3d5684ddbf`,
`f209fd7cb0ca5e8a31a6f8f4f55ee377707da23b`,
`3e48bdf0b899050fba56fc6071f07be4747f9512`,
`83eafc02c43dd8ca756bb1d286961b74b91b5413`.

**[F]** No pull request was opened for any of them (the repository's pull
request list holds none). Their history is logged in issue #26 (closed,
2026-10-27, with four later comments up to 2026-10-31).

**[F]** Every branch describes itself as a throwaway site-adapter experiment,
not a surveillance pipeline
(`prototype/amr-python@0ebeb94:docs/worked-examples/amr-python-prototype/README.md:6-8`;
`prototype/amr-demo-ergonomics@83eafc0:docs/worked-examples/amr-r-prototype/README.md:6-10`).

---

## 3. Branch by branch

### 3.1 `prototype/amr-python` (`0ebeb94`)

Files: `docs/worked-examples/amr-python-prototype/` (README, `run.py`,
`run.ps1`, `requirements.txt`, `demo.template.html`).

**Purpose [F].** Test whether AMR for Python can map Rouen's raw labels and
compute a small resistance table with explicit resistant and tested counts
(README:3-4).

**Decisions taken [F].**
- Pin AMR 3.1.0 for both Python and R (`requirements.txt:1`; `run.ps1:24`).
- Read `data/bact22_24` directly, year 2024, results `S`, `SFP`, `I`, `R`,
  `ZIT` (README:29-32; `run.py:51-58`).
- `as_mo()` on every distinct organism label; keep AMR's uncertainty output
  (README:33-35; `run.py:70-78`).
- `as_ab(language="fr")` on every result label, compared with
  `ref/rouen/atb_regex_map.csv` (README:36-37; `run.py:82-87`).
- Small resistance table: 5 exact species names, 7 named antibiotic labels,
  19 declared species-molecule pairs (README:38-46; `run.py:89-101`).
- Keep `GENTAMICINE FORTE` out of the table, although AMR and the legacy map
  both call it gentamicin (README:40-43; `run.py:91-94`).
- Show `as_mo(reference_df=...)` on `Enterobacter complexe cloacae`, without
  applying it (README:47-50; `run.py:141-149`).
- Isolate key `(PATID, ELTID, DLVL)` (README:51-53).
- Map `SFP` and `ZIT` to AMR's `I` and compute with `guideline="EUCAST"`
  (README:54-58; `run.py:118`).
- `resistance(minimum=0)` so small counts stay visible (README:63-65;
  `run.py:131-136`).

**Documented results [F].**
- Verdict: feasible, with AMR as a configurable toolbox in the site adapter;
  suggestions need review; no adoption decision (README:111-114).
- Package counts matched independent arithmetic (README:121-123; the check is
  `run.py:135-136`).
- A Windows bug in the Python wrapper: a Windows path is put into an R string
  without escaping. It crashed R (exit code `-1073741819`) with R 4.5.3 and
  4.6.1. The branch patches the installed `AMR/_engine.py` (README:84-94;
  `run.py:25-32`).
- The Python package is a wrapper around the R package, not a separate
  implementation (README:80-82).

**Open questions [F].** Rates are not surveillance indicators: no diagnostic
selection, no perimeter selection, no deduplication (README:67-72). The
modified dependency "must be accounted for before adopting the wrapper"
(README:93-94).

**Conflicts.** Superseded by `prototype/amr-r` (see 3.2 and conflict K10).

### 3.2 `prototype/amr-r` (`6307a86`)

Files: `docs/worked-examples/amr-r-prototype/` (README, `run.R`, `run.ps1`,
`demo.template.html`). The commit deletes the Python files.

**Purpose [F].** Re-run the same trial directly in R (README:3-4, 7-8).

**Decisions taken [F].**
- Direct R calls, no Python bridge; install AMR 3.1.0 from the CRAN source
  archive if missing and stop otherwise (`run.R:14-17`, `:23`).
- Map **every** distinct non-missing organism label of the selected
  population, with no frequency cut-off (README:35-40; `run.R:43-47`).
- Treat AMR's `UNKNOWN` as unmapped; count missing identifications apart
  (README:44-47; `run.R:50`).
- Read the legacy antibiotic map as UTF-8 so accented labels match
  (README:98-100; `run.R:60`). The legacy map is "a comparator" (README:50).
- Same table, key, `SFP`/`ZIT` handling and `reference_df` demo as 3.1
  (README:54-74; `run.R:67-136`).

**Documented results [F].**
- "Direct R is sufficient for this trial"; resistance table agrees with the
  Python run (README:96-98).
- Mapping suggestions agree after fixing two Python defects: a missing-value
  placeholder counted as a label, and failed mappings shown with the wrong
  status (README:44-47 and 98-99).

**Open questions [F].** Same population caveat (README:76-80).

**Conflicts.** None with `main` beyond those in section 5.

### 3.3 `prototype/amr-classification` (`f209fd7`)

**Purpose [F].** Test whether AMR can add organism and antibiotic
classifications while keeping the mapping uncertainty visible (README:3-4).

**Decisions taken [F].**
- For every mapped organism: `mo_rank`, `mo_type`, `mo_gramstain`,
  `mo_class`, `mo_order`, `mo_family`, `mo_genus`, plus species/complex groups
  from `AMR::microorganisms.groups` (README:62-67; `run.R:55-71`).
- For every mapped drug: `ab_group`, `ab_atc_group1`, `ab_atc_group2` and
  every ATC code via `ab_atc(only_first = FALSE)` (README:69-73;
  `run.R:94-108`).
- Five AMR class selectors with `only_treatable = TRUE`: beta-lactams,
  third-generation cephalosporins, carbapenems, fluoroquinolones,
  aminoglycosides (README:75-79; `run.R:109-119`).
- Show AMR's separate high-level gentamicin entry `GEH` next to `GEN`, without
  applying it (README:87-90; `run.R:120-130`).
- Output folder renamed to `outputs/amr-classification-prototype`
  (`run.R:9`).

**Documented results [F].**
- Verdict: "Classification is feasible as an enrichment of proposed
  identities"; a clear class for a candidate does not validate the mapping
  (README:152-156).
- Some comment labels receive a drug suggestion and inherit its class
  (README:92-95).
- AMR drug group and ATC subgroup can select different labels, because some
  candidates lack ATC data (README:94-95).

**Open questions [F].** Source-field eligibility and mapping review "must
precede adoption of grouped counts" (README:93-94). Adopting `GEH` "requires a
local decision" (README:89-90).

### 3.4 `prototype/amr-label-review` (`3e48bdf`)

**Purpose [F].** Record the chosen direction and draft a review of the
antibiotic label list (commit message; README:35-62).

**Decisions taken [F].**
- "The user chose AMR to replace the DIY bacterial mapping, with a small set
  of local corrections" (README:37-38).
- "Antibiotic mapping will also build on AMR; a finite local label review
  supplies the corrections" (README:40-41).
- The reviewed inputs are `LBLANA` antibiotic or test labels, not sample
  labels; sample-type mapping stays local and is "a settled, separate
  responsibility" (README:43-45).
- Technical and comment fields stay outside molecule matching; context words
  such as `MENINGITE` are kept as a qualifier and never turned into a sample
  type or a screening test (README:57-62).

**Documented results [F].** `prepare-antibiotic-review.R` sorts every label
into five actions (lines 89-90): propose code correction, local meaning
needed, outside molecule matching, retain code with qualifier, retain AMR
candidate. Proposed codes are checked against `AMR::antimicrobials`
(lines 70-71). Examples of proposals (lines 17-39):

| Label | Draft proposal | Note in the script |
|---|---|---|
| `TEICOPLANINE` | `TEC` | correct the molecule (line 18) |
| `PENICILLINE G` | `PEN` | correct the molecule (line 19) |
| `CLAVENTIN` | `TCC` | consistent with the local dictionary; check the trade name (line 24) |
| `GENTAMICINE FORTE`, `GENTAMICINE FORTE.` | `GEH`, qualifier `FORTE` | confirm the local assay (lines 27-28) |
| `CLOXA 250`, `CLOXA 500` | `CLO` | legacy map says oxacillin; clarify surrogate use (lines 37-38) |
| `AUGMENTIN CYSTITE` | `AMC`, qualifier `CYSTITE` | keep the context (line 22) |
| `FOSFOMYCINE IV` / `TROMETAMOL` | `FOS` + qualifier | keep the two tests distinguishable (lines 25, 36) |
| `PIPERA TAZO` | `TZP` | clarify the local test format separately (line 26) |

Kept outside molecule matching (lines 47-48): `Technique ATB`,
`Commentaire C3G`, `COMMENTAIRE SAMR`, `COMMENTAIRE BLSE`,
`COMMENTAIRE CARBA`, `COMMENTAIRE ERG`, `CEFINASE`.

Local meaning needed (lines 55-56): `AMOXICILLINE / AMPICILLINE`,
`AMPICILLINE/AMOXICILLINE`, `NITROFURANES`, `NORFLO DEPIST RCC FQUINOLONES`,
`ASSO AZTRE/CAZA`, `ASSO AUGMENTIN/CEFIXIME`.

**Open questions [F].** All entries are drafts; nothing is applied
(lines 82-83). Compound tests and family names keep an explicit question
(README:61-62). Production integration "is still separate" (issue #26,
2026-10-31 comment).

### 3.5 `prototype/amr-demo-ergonomics` (`a6069eb`, `a96cb63`, `83eafc0`)

**Purpose [F].** Make the demo page easier to use: layout, Previous/Next,
filters, sortable columns (commit messages; README:30-46).

**Decisions taken [F].**
- Vertical layout chosen by the user: controls, selected label, table
  (issue #26, 2026-10-31 second comment; README:30-33).
- "Used in resistance demo" is a separate yes/no column, not a mapping status
  (README:43-45; commit `a96cb63`).
- "Antibiotic mapping status reports whether AMR returned a candidate; it does
  not assign a confidence score or approval" (README:45-46).

**Documented results [F].** No R calculation or mapping changed (issue #26,
same comment; `run.R` and `prepare-antibiotic-review.R` identical to their
`f209fd7` and `3e48bdf` versions).

**Open questions.** None new about mapping.

---

## 4. v3 needs as documented in the repository

Each line is a need the repository states, with its source. The last column
names the AMR functions a reader would look at for it **[I]**; it is a pointer
for the design step, not a choice.

| # | Need | Source on `main` | AMR functions touching it [I] |
|---|---|---|---|
| N1 | Mappings of bacteria and antibiotics belong to the **site adapter**; the core reads only the site handoff and never reads site references | `docs/adr/0003-portable-contract-is-the-product.md:3-5`, `:21-26`; `CONTEXT.md:41-47`; `docs/methods/06-donnees-resistance.md:59-61` | where `as.mo()` / `as.ab()` run |
| N2 | The core consumes **prepared identities**, never local labels | `docs/adr/0003-portable-contract-is-the-product.md:33-34`; `docs/methods/06-donnees-resistance.md:135-137` | `as.mo()`, `as.ab()` output codes |
| N3 | Mapping foundation = the **previous ORCHIDEE mappings, improved**, not assumed correct | `docs/adr/0003-portable-contract-is-the-product.md:31-35`; `docs/methods/06-donnees-resistance.md:130-133`, decision 06.8 at `:156` | see conflict K1 |
| N4 | Still open: exact antibiotic equivalences, species/complex treatment, target lists | `docs/methods/06-donnees-resistance.md:138-141`, `:185-188`; `docs/methods/00-audit-qualite.md:595-598` | `microorganisms.groups`, `reference_df`, `add_custom_antimicrobials()` |
| N5 | Declare antibiotic **counting identities** and how they relate to result-resolution identities | `docs/methods/00-audit-qualite.md:595-597` | `as.ab()` codes vs local qualifiers |
| N6 | Isolates without an assignable taxon stay **visible**; no invented "unknown species" | `docs/methods/06-donnees-resistance.md:137`; `docs/methods/00-audit-qualite.md:359-360`, `:376-377` | `UNKNOWN` code, `mo_failures()` |
| N7 | Use the **declared** species/complex mapping; do not guess equivalence between overlapping labels | `docs/methods/00-audit-qualite.md:393-394`, `:489-490` | `mo_uncertainties()`, `reference_df` |
| N8 | Every audit output states the **mapping versions** used | `docs/methods/00-audit-qualite.md:338-341` | `packageVersion("AMR")`, data set versions |
| N9 | Result alphabet: ternary `S`, `SFP`, `R`; historical `I` and `ZIT` read as `SFP`; `NA` = not tested by default | `docs/methods/06-donnees-resistance.md:80-98`, decision 06.4 at `:152`; `CONTEXT.md:329-343` | `as.sir()` |
| N10 | At indicator time `SFP` counts on the `S` side; group logic: `R` if any molecule R, `Ø` if none documented, `S` otherwise | `docs/methods/08-indicateurs.md:27-32`, decision 08.2 at `:141` | `guideline` argument, `sir_combine()` |
| N11 | %R denominator = **tested** isolates; `Ø` leaves it | `docs/methods/08-indicateurs.md:84-85`, decision 08.4 at `:143` | `count_all()`, `resistance()` |
| N12 | **No cell suppression** in the indicator table | `docs/methods/08-indicateurs.md:123-128`, decision 08.7 at `:146`; ADR-0008 | `minimum` argument of `resistance()` |
| N13 | BLSE and carbapenemase are **isolate attributes**, not antibiotic rows; absent = negative (Note Xa) | `docs/methods/06-donnees-resistance.md:106-117`; `docs/methods/08-indicateurs.md:107-112` | none: AMR treats inputs as antimicrobial columns [I] |
| N14 | SARM: cefoxitine first, oxacilline as fallback; discordance watched by TW-08.1 | `docs/methods/08-indicateurs.md:34-35`, `:168-173`; `docs/methods/tripwire-register.md:48`, `:103-105` | `as.ab()` codes `FOX`, `OXA`, `CLO` (see K4) |
| N15 | Five national indicators, incl. all Enterobacterales with carbapenemase, *K. pneumoniae* C3G-R, *E. faecium* vancomycin-R | `docs/methods/08-indicateurs.md:51-57` | `mo_order()`, `cephalosporins_3rd()` |
| N16 | Natural-resistance audit (Test 5.1) against **CA-SFM 2025 V1.1**, Section 2, pp. 33-39 | `docs/methods/00-audit-qualite.md:270-286`, decision 00.6 at `:530` | `mo_is_intrinsic_resistant()` (EUCAST-based, see 6.6) |
| N17 | Interpretation standard: record the site's declaration by year; no per-row rejection | `docs/methods/06-donnees-resistance.md:122-127` | `as.sir()` is not used to reinterpret (branches) |
| N18 | Isolate key `(PATID, ELTID, isolate_id)`; Rouen's `DLVL` is `isolate_id` | `docs/methods/06-donnees-resistance.md:41-49` | none |
| N19 | Witnesses and pipelines derive from raw files, not v2 bundles | `CLAUDE.md` ("Raw Data Ingestion"); issue #1 notes | n/a |
| N20 | Every v3 choice not made by the sources is a **decision** with a witness, or marked unproven | `docs/methods/README.md:65-76`; `CONTEXT.md:421-431` | n/a |
| N21 | Planned core is **R modules** (`orchidee_audit`, `orchidee_exposure`, `orchidee_dedup`, `orchidee_indicators`) and a Rouen adapter | issue #1, "Not yet specified" | language fit of AMR for R |

**[F]** The SPF needs PDF is the source behind several of these: numerator and
denominator for every indicator (SPF p. 5, cited at
`docs/methods/00-audit-qualite.md:514-516`), and the cefoxitine precedence
(footnote 2 of the SPF table on p. 3, per `docs/findings.md:390`). The target
species list is SPARES Annexe 5, pp. 28-30 (`docs/findings.md:388`).

---

## 5. Conflicts and tensions

For each one: what disagrees, and which version is better supported by the
evidence. "Better supported" is my judgement **[I]**, with the reason given.
`main` is not assumed right.

### K1. Mapping foundation: previous ORCHIDEE mappings vs AMR

- `main` **[F]**: "Local preparation starts from the previous ORCHIDEE
  bacterial and antibiotic mappings and improves them"
  (`docs/methods/06-donnees-resistance.md:130-133`; decision 06.8 at `:156`;
  `docs/adr/0003-portable-contract-is-the-product.md:31-35`). Written in
  commit `1c6ae17`, author date 2026-10-16 (`git blame`).
- Branch **[F]**: AMR replaces the "DIY bacterial mapping"; antibiotic mapping
  builds on AMR (`prototype/amr-label-review@3e48bdf:docs/worked-examples/amr-r-prototype/README.md:37-41`),
  dated 2026-10-31, and recorded as the user's accepted direction in issue
  #26 (2026-10-31).
- **Better supported [I]: the branch, for the direction.** It is later
  (15 days after `main`), explicit, and attributed to the user. `main` was
  never updated. Both agree on the boundary (the site adapter owns mappings).
  Neither side has a witness: decision 06.8 claims "no new measurement or
  dictionary validation" (`:156`), and the branches publish no measured
  comparison.
- Partial overlap **[F]**: for antibiotics, the branches still use the legacy
  map as comparator (`prototype/amr-r@6307a86:.../README.md:48-50`) and some
  draft corrections cite it (`CLAVENTIN`, `prepare-antibiotic-review.R:24`).
  So the antibiotic side is "AMR, checked against the previous dictionary",
  not a clean replacement.

### K2. Result alphabet: `SFP` (main) vs AMR's `I` (branches)

- `main` **[F]**: canonical values `S`, `SFP`, `R`; historical `I` and `ZIT`
  become `SFP` (`docs/methods/06-donnees-resistance.md:80-98`, decision 06.4).
- Branches **[F]**: `SFP` and `ZIT` become AMR's `I`, then `guideline =
  "EUCAST"` (`prototype/amr-r@6307a86:.../run.R:100`, README:66-70). The
  branches say this preserves the chapter 06 choice (README:66-67).
- AMR **[F]**: with `guideline = "EUCAST"`, `I` counts as susceptible; with
  `"CLSI"`, as resistant (`AMR v3.1.0:R/sir.R:176-181`, roxygen section
  *Interpretation of SIR*).
- **Assessment [I].** Same %R arithmetic, so no numeric conflict, as long as
  the `guideline` argument is set to `"EUCAST"` (AMR's `?as.sir`, section
  *Interpretation of SIR*). The conflict is of **names and direction**: `main`
  folds `I` into `SFP`; the branches fold `SFP` into `I`. `main` is better
  supported for the vocabulary (decision 06.4 has a witness; `CONTEXT.md`
  defines `SFP`). The branch choice is a technical adaptation to AMR's
  alphabet, not a recorded decision.
- Related risk [I]: AMR's default `as.sir()` patterns do not recognise `SFP` or
  `ZIT` (see 6.9). The branches never call `as.sir()` directly; they pass
  plain `"S"`, `"I"`, `"R"` strings.

### K3. Small counts: AMR default `minimum = 30` vs no suppression

- `main` **[F]**: no cell suppression; every cell keeps numerator and
  denominator (decision 08.7, `docs/methods/08-indicateurs.md:146`).
- AMR **[F]**: `resistance()` defaults to `minimum = 30` and returns `NA` with
  a warning below it (`AMR v3.1.0:R/proportion.R:36`, `:192-196`).
- Branches **[F]**: set `minimum = 0`
  (`prototype/amr-r@6307a86:.../run.R:114`).
- **Assessment [I].** No conflict in the branches. The AMR default itself
  would conflict with decision 08.7 if left unset.

### K4. `CLOXA 250/500`: cloxacillin (branch) vs oxacillin (legacy map) vs SARM rule

- Legacy map **[F]**: `^cloxa\s*\d+` → `oxacilline`
  (`ref/rouen/atb_regex_map.csv:21`; also `meticilline` → `oxacilline` at `:20`).
- Branch **[F]**: AMR identifies cloxacillin (`CLO`); the draft keeps `CLO`
  and asks to "clarify the assay qualifier and any surrogate use separately"
  (`prepare-antibiotic-review.R:37-38`).
- `main` **[F]**: SARM uses oxacilline as fallback, with a Rouen witness of
  1 093 *S. aureus* tested for oxacilline
  (`docs/methods/08-indicateurs.md:142`, `:171`).
- **Assessment [I].** Unresolved and important. If Rouen's oxacilline column
  comes from `CLOXA` labels (likely, from the regex), then moving them to `CLO`
  would remove the input of decision 08.3 and TW-08.1. Neither source settles
  which identity the laboratory test represents. The branch is better
  supported on chemistry (cloxacillin is the named molecule); `main` is better
  supported on the indicator's current input. Needs a local decision.

### K5. `GENTAMICINE FORTE`: one identity (legacy, AMR default) vs high-level assay `GEH` (branch)

- Legacy map **[F]**: `^gentamicine\b` → `gentamicine`, which also catches
  `GENTAMICINE FORTE` (`ref/rouen/atb_regex_map.csv:44`;
  `prototype/amr-python@0ebeb94:.../README.md:40-43`).
- AMR default **[F]**: `as.ab()` also returns ordinary gentamicin (same
  README lines).
- Branch draft **[F]**: `GEH` with qualifier `FORTE`
  (`prepare-antibiotic-review.R:27-28`). AMR excludes `GEH` from
  `aminoglycosides()` unless `only_treatable = FALSE`
  (`AMR v3.1.0:R/amr_selectors.R:44`).
- `main` **[F]**: silent on high-level aminoglycoside tests.
- **Assessment [I].** The branch is better supported (it keeps a real assay
  difference visible), but it asks for local confirmation. Both AMR's default
  and the legacy map merge the two tests.

### K6. Distinct legacy identities vs AMR molecule + qualifier

- Legacy map **[F]** gives separate identities to `AUGMENTIN CYSTITE`
  (`amoxicilline_acide_clavulanique_cystite`, `:5`), `FOSFOMYCINE IV` and
  `TROMETAMOL` (`fosfomycine_iv`, `fosfomycine_trometamol`, `:59-60`), and
  `PIPERA TAZO` (`piperacilline_tazobactam_ppt85`, `:12`).
- Branch draft **[F]** maps them to one AMR molecule plus a qualifier (`AMC` +
  `CYSTITE`, `FOS` + `IV`/`TROMETAMOL`; lines 22, 25, 36) or to plain `TZP`
  with a separate question (line 26).
- `main` **[F]**: "Declare the antibiotic counting identities, their
  relationship to result-resolution identities" is still open
  (`docs/methods/00-audit-qualite.md:595-597`).
- **Assessment [I].** Not a conflict with a `main` decision, because `main`
  leaves it open. It is a modelling difference between the legacy map and the
  branch. Neither is better supported yet.

### K7. Family or joint labels

- Legacy map **[F]**: `NITROFURANES` → `nitrofurantoine` (`:58`); joint
  amoxicillin/ampicillin labels → `amoxicilline_ampicilline` (`:2-4`).
- Branch draft **[F]**: both need a local meaning before any molecule
  (`prepare-antibiotic-review.R:62-64`).
- **Assessment [I].** The branch is more cautious; the legacy map already made
  a choice. No `main` decision exists.

### K8. Population used by the prototypes

- `main` **[F]**: the handoff holds only diagnostic isolates with an
  antibiogram, selected locally (`docs/methods/06-donnees-resistance.md:59-65`).
- Branches **[F]**: all raw sample types, including possible screening; rates
  are not indicators (`prototype/amr-r@6307a86:.../README.md:76-80`).
- **Assessment [I].** Not a conflict: the branches say so themselves. But no
  branch result can serve as a witness for a `main` decision.

### K9. Classification level vs the national indicators

- `main` **[F]**: indicators for "toutes Enterobacterales" and C3G resistance
  (`docs/methods/08-indicateurs.md:53-55`); the group rule comes from the SPF
  needs, section 1 of "What SPF asks" (`:27-32`).
- Branch **[F]**: uses AMR's `mo_order()` and `cephalosporins_3rd()` as
  exploration (`prototype/amr-classification@f209fd7:.../run.R:56-58`,
  `:111`).
- **Assessment [I].** Not checked anywhere: whether AMR's order
  *Enterobacterales* (current taxonomy) matches SPARES Annexe 5, pp. 28-30, and
  whether AMR's third-generation cephalosporin list matches the SPF group. Open
  question, not a conflict yet.

### K10. Python vs R (branch vs branch)

- `prototype/amr-python` needs a patched dependency on Windows
  (`0ebeb94:.../README.md:84-94`) and had a missing-value bug
  (`prototype/amr-r@6307a86:.../README.md:44-47`).
- `prototype/amr-r` replaces it and calls "Direct R ... sufficient"
  (`6307a86:.../README.md:96-98`); issue #26 says the switch followed the
  user's preference.
- **Better supported [I]: R.** Also consistent with the planned R core
  modules (issue #1). The wrapper bug is still present in the latest Python
  package (see 7.3).

### K11. A tension inside `main` (not caused by the branches)

- **[F]** `ref/README.md:3-5` says the references "do not encode ... ORCHIDEE
  normalization decisions", yet `ref/rouen/atb_regex_map.csv` maps labels to
  normalised antibiotic names.
- **[F]** Chapter 08 witnesses read `outputs/rouen_current/bundle_v3/sir_wide.rds`
  (`docs/methods/08-indicateurs.md:134`), built with v2 mappings
  (`docs/findings.md:287-292`), while `CLAUDE.md` forbids relying on
  `sir_wide.rds`.
- **[I]** Any change of mapping (K1) would move the inputs of these witnesses;
  the CLAVENTIN finding shows one mapping change moved 51 isolates and 20
  denominators (`docs/findings.md:45-52`).

---

## 6. AMR 3.1.0: functions used or relevant

Only functions used by the branches or named in section 4. "Used" lists the
branch that calls it.

### 6.1 `as.mo()` — organism label to AMR organism code

- **Used**: all branches (`prototype/amr-r@6307a86:.../run.R:47`, with
  `language = "en"`).
- **Input [F]**: character vector or data frame; options
  `minimum_matching_score`, `keep_synonyms`, `reference_df`, `ignore_pattern`,
  `cleaning_regex`, `Becker`, `Lancefield`, `only_fungi`, `language`, `info`
  (`AMR v3.1.0:R/mo.R:186-197`).
- **Output [F]**: character vector of class `mo`, codes like
  `B_KLBSL_PNMN` (`R/mo.R:54-70`, `:138`).
- **How it matches [F]**: a published matching score that prefers common human
  pathogens; the threshold depends on input length, domain and pathogenicity
  (`R/mo.R:76`, `:80`).
- **Known limits [F]**:
  - Unmatched input returns `UNKNOWN` with a warning (`R/mo.R:72`), not `NA`.
  - A guess is a guess: uncertain matches are only flagged through
    `mo_uncertainties()` (`R/mo.R:80`).
  - Results are cached per session for the same settings; `mo_reset_session()`
    clears them (`R/mo.R:89`).
  - The `cleaning_regex` default removes text between brackets and words like
    "species" (`R/mo.R:46`).
  - `Becker` and `Lancefield` regroup staphylococci and streptococci when set
    (`R/mo.R:34-37`).
- **3.1.0 changes [F]**: `"X complex"` falls back to `"X"` when the complex is
  not a separate taxon (`AMR v3.1.0:NEWS.md:88`); taxonomy updated to COL
  2026-04-18, LPSN and BacDive of October 2026 (`NEWS.md:100`).
- **Note [F]**: the old `allow_uncertain` argument is not a control in 3.1.0
  (`prototype/amr-python@0ebeb94:.../README.md:99-102`).

### 6.2 `mo_uncertainties()`, `mo_failures()`, `mo_reset_session()`

- **Used**: `mo_uncertainties()` and `mo_reset_session()` in all branches
  (`prototype/amr-r@6307a86:.../run.R:48`, `:129`).
- **Output [F]**: `mo_uncertainties()` returns a data frame with the matching
  score of every guessed name; `mo_failures()` a character vector of values
  that could not be coerced (`AMR v3.1.0:R/mo.R:84-87`).
- **Limit [F]**: only the uncertainties of the last `as.mo()` or `mo_*()` call
  are stored (`R/mo.R:1012`). The branches read them right after `as.mo()`.
  3.1.0 also lists uncertainties of previously coerced input
  (`NEWS.md:86`).

### 6.3 `reference_df`, `set_mo_source()`, `add_custom_microorganisms()`

- **Used**: `reference_df` in all branches, demonstration only
  (`prototype/amr-r@6307a86:.../run.R:127-136`).
- **Input [F]**: a data frame with a column `mo` (valid code or full name) and
  a column of local values (`AMR v3.1.0:R/mo_source.R:42`).
- **Limit [F]**: `set_mo_source()` writes a file only in interactive sessions,
  after user confirmation, by CRAN policy (`R/mo_source.R:42`).
  `add_custom_microorganisms()` exists (`R/custom_microorganisms.R:129`); it
  is not used by any branch.

### 6.4 `mo_*()` property helpers

- **Used** (classification branch onwards): `mo_name`, `mo_rank`, `mo_type`,
  `mo_gramstain`, `mo_class`, `mo_order`, `mo_family`, `mo_genus`
  (`prototype/amr-classification@f209fd7:.../run.R:51`, `:56-58`).
- **Input / output [F]**: an `mo` code or any text that `as.mo()` accepts;
  returns one value per input (`AMR v3.1.0:R/mo_property.R:215`, `:313-355`,
  `:422`, `:491`, `:793`).
- **Relevant, unused [F]**: `mo_is_intrinsic_resistant(x, ab)`
  (`R/mo_property.R:601`) and `mo_group_members()` (`:885`).
- **Limits [F]**:
  - 3.1.0 changed `mo_kingdom()`: bacteria now return a formal kingdom such
    as `"Pseudomonadati"`; `mo_domain()` gives the old `"Bacteria"`
    (`NEWS.md:6`).
  - Properties describe AMR's candidate, not the source label
    (`prototype/amr-classification@f209fd7:.../README.md:62-67`).
  - **[I]** Intrinsic resistance in AMR follows EUCAST Expected Resistant
    Phenotypes (`AMR dev:NEWS.md:288`), while ORCHIDEE Test 5.1 uses CA-SFM
    2025 V1.1, Section 2 (N16). They are different references.

### 6.5 `microorganisms.groups`

- **Used**: classification branch onwards, to list species/complex
  memberships (`f209fd7:.../run.R:67-71`).
- **Relevance [I]**: N4 and N7 (species/complex treatment is open on `main`).

### 6.6 `as.ab()` — result label to AMR drug code

- **Used**: all branches, with `language = "fr"`
  (`prototype/amr-r@6307a86:.../run.R:58`).
- **Input [F]**: character or numeric vector; `flag_multiple_results`,
  `language`, `info` (`AMR v3.1.0:R/ab.R:96-100`).
- **Output [F]**: character vector of class `ab`, EARS-Net style codes such as
  `ERY` (`R/ab.R:40`, `:74`).
- **How it matches [F]**: searches codes, official names, synonyms and brand
  names; corrects common misspellings (`R/ab.R:40-47`).
- **Known limits [F]**:
  - Unknown input returns `NA` with a warning (`R/ab.R:483-488`).
  - Uncertain matches only produce a console message; there is **no**
    `ab_uncertainties()` data frame like `mo_uncertainties()`
    (`R/ab.R:490-512`; the name does not occur in the fetched source).
    This is why the demo's antibiotic status is only "candidate or not"
    (`83eafc0:.../README.md:45-46`).
  - Long regular expressions for brand names "may fail on some systems"
    (`R/ab.R:53`).
- **3.1.0 changes [F]**: `add_custom_antimicrobial_synonyms()` adds local or
  trade names to existing drugs (`NEWS.md:50`); trade names of combinations
  (Tazocin, Timentin, Recarbrio, Exblifep) were corrected (`NEWS.md:119`);
  invalid UTF-8 returns `NA` with a warning (`NEWS.md:116`).
- **Relevant, unused [F]**: `add_custom_antimicrobials()`
  (`R/custom_antimicrobials.R:131`), which must be run in every session
  (`R/custom_antimicrobials.R:36`).

### 6.7 `ab_*()` property helpers and class selectors

- **Used**: `ab_name` (all R branches); `ab_group`, `ab_atc_group1`,
  `ab_atc_group2`, `ab_atc` (classification onwards)
  (`f209fd7:.../run.R:94-108`).
- **Output [F]**: one value per input; `ab_atc(only_first = FALSE)` returns all
  ATC codes (`AMR v3.1.0:R/ab_property.R:200`).
- **Limit [F]**: `ab_group()` returns only the most specific group unless
  `all_groups = TRUE` (`R/ab_property.R:167`, `:179-181`). The branch uses the
  default. In 3.1.0 `antimicrobials$group` became a list (`NEWS.md:118`).
- **Selectors used [F]**: `betalactams()`, `cephalosporins_3rd()`,
  `carbapenems()`, `fluoroquinolones()`, `aminoglycosides()`
  (`R/amr_selectors.R:238-345`). `only_treatable = TRUE` (default) drops
  laboratory-only entries such as `GEH` and `IPE` (`R/amr_selectors.R:44`).

### 6.8 `count_R()`, `count_all()`, `resistance()`

- **Used**: all branches (`prototype/amr-r@6307a86:.../run.R:112-116`).
- **Input [F]**: vectors of results, converted with `as.sir()` internally if
  needed (`AMR v3.1.0:R/proportion.R:35`).
- **Output [F]**: `count_R()` counts `R`, `NWT`, `NS` (`R/count.R:220-223`);
  `count_all()` counts every available result, the same as susceptible plus
  resistant (`R/count.R:40`, `:233`); `NI` (non-interpretable) is excluded
  from the denominator (`R/sir_calc.R:165-166`). `resistance()` returns a
  proportion (`R/proportion.R:192-196`).
- **Limits [F]**:
  - `minimum = 30` by default, giving `NA` below it (`R/proportion.R:36`).
  - Since 3.1.0 the treatment of `I` follows `guideline`; if neither the
    argument nor the `AMR_guideline` option is set, EUCAST is assumed with a
    message (`NEWS.md:28-29`, `:127`).
- **Branch result [F]**: package counts matched hand arithmetic
  (`prototype/amr-r@6307a86:.../README.md:102-103`).

### 6.9 `as.sir()` — not called by any branch

- **Relevance [I]**: N9 (result alphabet).
- **Input [F]**: raw text, MIC or disk values; for text, default patterns
  `S = "^(S|U|1)+$"`, `I = "^(I|2)+$"`, `R = "^(R|3)+$"`, `SDD`, `NI`, `WT`,
  `NWT`, `NS` (`AMR v3.1.0:R/sir.R:520-530`).
- **Output [F]**: an ordered factor of class `sir` with levels `S`, `SDD`,
  `I`, `R`, `NI`, `WT`, `NWT`, `NS` (`R/sir.R:30`).
- **Limits**:
  - **[I]** Read from the code at `R/sir.R:587-606`, not run: `"SFP"` and
    `"ZIT"` match none of the default patterns, so they would become `NA` with
    a "truncated" warning. The patterns are arguments, so they can be changed.
  - **[F]** Values that do not fit become `NA` and are reported in a warning
    (`R/sir.R:636-645`).
  - **[F]** MIC or disk interpretation uses AMR's breakpoint table; since 3.1.0
    EUCAST 2026 is the default (`NEWS.md:33`). The branches do not reinterpret
    measurements (`6307a86:.../README.md:69-70`).

### 6.10 `sir_combine()` — not used

- **[F]** New in 3.1.0: combines several drugs into one result, with
  `method = "most_resistant"` for resistance within a group
  (`AMR v3.1.0:R/sir_combine.R:143`; `NEWS.md:49`).
- **Relevance [I]**: N10 (the group rule of `08-indicateurs.md:27-32`). Whether its handling of untested
  molecules matches the `Ø` rule of decision 08.2 is not checked.

---

## 7. AMR 3.1.0 vs the current release

### 7.1 Which version is current

- **[F]** AMR 3.1.0 is the latest numbered release: tag `v3.1.0`, `DESCRIPTION`
  date 2026-10-16; on PyPI, 3.1.0 was uploaded 2026-10-16 and every later
  upload is a development build (`3.1.0.9002` to `3.1.0.9021`, last on
  2026-11-09).
- **[I]** CRAN could not be reached from this environment, so the CRAN version
  is not confirmed. The branches installed
  `https://cloud.r-project.org/src/contrib/AMR_3.1.0.tar.gz` successfully on
  2026-10-27 (`prototype/amr-r@6307a86:.../run.R:15`), which suggests 3.1.0 was
  the CRAN release then.
- **[F]** The branches pin 3.1.0 and stop on any other version
  (`6307a86:.../run.R:14-17`, `:23`).

### 7.2 Differences 3.1.0 → development 3.1.0.9021 that touch ORCHIDEE

Source: `AMR dev:NEWS.md:1-40` and file diffs between tag and `main`.

- **[F]** `intrinsic_resistant` now lists species groups and complexes,
  adding 62 bug-drug pairs, including the *Enterobacter cloacae* complex with
  amoxicillin and amoxicillin/clavulanic acid. This changes
  `mo_is_intrinsic_resistant()` (`AMR dev:NEWS.md:35`). **[I]** Relevant to
  N16: `docs/methods/00-audit-qualite.md:284` uses this same pair as a Test 5.1
  example.
- **[F]** Breaking: `mo_shortname()` now returns the serovar for *Salmonella*
  (`AMR dev:NEWS.md:6`). Not used by the branches.
- **[F]** Critical WISCA bug fixed (`AMR dev:NEWS.md:3`). Not used by the
  branches.
- **[F]** `as.mo()`: only a console-message layout fix
  (`AMR dev:NEWS.md:33`; `R/mo.R:1147` diff).
- **[F]** No code change in `R/ab.R`, `R/sir.R`, `R/proportion.R`,
  `R/count.R`, `R/sir_calc.R`, `R/ab_property.R`, `R/amr_selectors.R`,
  `R/mo_source.R` beyond two page titles ("Antibiotic" → "Antimicrobial
  Drug").

### 7.3 Python wrapper

- **[F]** The `_engine.py` of the Python wheels 3.1.0 and 3.1.0.9021 is
  identical; line 7 builds `r_lib_path` with `os.path.join` and line 31 puts it
  inside an R string unescaped. **[I]** So the Windows bug reported in 3.1
  still exists in the latest Python build.
- **[F]** If AMR is missing from its library, the wrapper installs the latest
  CRAN version, or GitHub's development version on request, not a pinned one
  (`_engine.py`, functions `_install_cran` and `_install_github`). The branch
  avoided this by pre-installing 3.1.0
  (`prototype/amr-python@0ebeb94:.../run.ps1:24`).

---

## 8. Licence (GPL-2)

- **[F]** `License: GPL-2 | file LICENSE` (`AMR v3.1.0:DESCRIPTION:72`). The
  Python package declares `License: GPL 2` (wheel `METADATA`).
- **[F]** The authors' own summary (`AMR v3.1.0:LICENSE:9-24`): use is allowed
  for commercial and private purposes, not for patent purposes; modifications
  must be released under the same licence when the package is distributed,
  and changes must be documented; distribution requires the source code, the
  licence and the copyright notice; no warranty.
- **[F]** ORCHIDEE has no licence file on `main` (no `LICENSE` at the
  repository root).
- **[I]** Points for the design step, not legal advice:
  - Calling AMR from a site adapter run inside the hospital is "use"; GPL
    duties attach mainly to **distribution**.
  - The Python branch modified an installed AMR file (`_engine.py`). Under the
    authors' summary, a modified copy that is distributed must be released
    under GPL-2 with the change documented.
  - Whether shipping ORCHIDEE code that calls AMR makes ORCHIDEE a derivative
    work under GPL-2 is a legal question the repository does not answer.
  - AMR's reference data (taxonomy, breakpoints) come from external sources
    with their own terms (`R/mo.R:129-137` lists LPSN, MycoBank, GBIF, BacDive,
    SNOMED). Not reviewed here.

---

## 9. Open questions collected

These are questions the evidence leaves open. Each cites where it is raised.
No answer is proposed.

1. Record the K1 decision on `main`? Today 06.8 and ADR-0003 still say
   "previous ORCHIDEE mappings" (K1).
2. Which identity does `CLOXA 250/500` represent, and what feeds the
   oxacilline fallback of 08.3 (K4;
   `prepare-antibiotic-review.R:37-38`)?
3. Is `GENTAMICINE FORTE` the high-level gentamicin test `GEH`
   (`prepare-antibiotic-review.R:27-28`; `f209fd7:.../README.md:89-90`)?
4. Molecule + qualifier or separate identity for context and formulation labels
   (K6; `docs/methods/00-audit-qualite.md:595-597`)?
5. Meaning of the six "local meaning needed" labels
   (`prepare-antibiotic-review.R:55-68`).
6. Handling of the seven technical/comment fields kept outside molecule
   matching (`prepare-antibiotic-review.R:47-53`). Several name phenotypes
   (`COMMENTAIRE BLSE`, `COMMENTAIRE CARBA`, `COMMENTAIRE SAMR`); **[I]** they
   may relate to N13.
7. Species/complex treatment, e.g. *Enterobacter cloacae* complex vs a
   subspecies (`0ebeb94:.../README.md:47-50`;
   `docs/methods/06-donnees-resistance.md:185-188`).
8. Does AMR's order *Enterobacterales* match the species list of SPARES
   Annexe 5, pp. 28-30, and does its C3G list match the group in
   `08-indicateurs.md:27-32` (K9)?
9. How to reconcile AMR's `I` with ORCHIDEE's `SFP` and `ZIT` in data that the
   core reads (K2, 6.9).
10. Which AMR version to pin, given 3.1.0 is pinned and the development
    version changes intrinsic resistance (7.2).
11. Python or R for the adapter: the branches settled on R for the trial; the
    Windows wrapper bug remains (K10, 7.3).
12. Licence position of ORCHIDEE relative to GPL-2 (section 8).
13. No witness exists yet for any mapping change (K1); `main`'s rule says a
    decision without a witness is marked unproven
    (`docs/methods/README.md:75-76`).
14. The prototype population had no diagnostic selection (K8); a witness
    would need the selected population.

---

## 10. Limits of this dossier

- Not read: the ignored local outputs (`outputs/amr-*`), so no statement here
  is about actual Rouen mapping results.
- Not run: R and AMR. Behaviour in 6.9 is read from source.
- Not reached: CRAN and the AMR website; AMR facts come from the GitHub source
  at tag `v3.1.0` and `main`, and from PyPI.
- The `demo.template.html` files were checked only through their commit
  messages and READMEs; they hold no mapping logic of their own according to
  issue #26 (2026-10-31 second comment).
