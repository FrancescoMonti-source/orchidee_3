# ORCHIDEE v3 — Agent Guidelines

v3 is an independent proposal of a transparent antimicrobial resistance (AMR) surveillance methodology for Santé publique France (SPF), replacing the legacy ConsoRes/SPARES approach and the v1/v2 pipelines. It covers all organisms and all hospital bacteriology streams.

**What this repository contains**: the specification (`CONTEXT.md`, `docs/adr/`, `docs/methods/`), the witness scripts that measure each decision on Rouen data (`docs/worked-examples/`), national and Rouen reference tables (`ref/`), and the citation checker (`tools/citecheck/`). It contains no surveillance engine. The provisional bundles the witnesses read were built by the v2 pipeline in the separate `orchidee` repository; PMSI helpers come from the `redsan` R package.

## Public repository and hospital data

This repository is **public**. Everything committed, and all issue, pull request and commit text, is published.

- Never commit anything under `data/` or `outputs/` (both are ignored), and never paste patient-level rows, identifiers (`PATID`, `EVTID`, `ELTID`, IPP, NDA), birth dates, or sample dates tied to one person.
- Raw free text from the laboratory export can carry identifiers: `NATUREPVT` (graft or tissue-bank numbers) and non-`S`/`I`/`R` values of `STRRES` (staff initials). Never copy raw values; describe them by category.
- Counts measured on hospital data: never describe a patient or a rare record precisely enough to single it out, and write any count of patients or of such records from 1 to 9 as `<10`. Aggregate isolate counts in method witnesses (for example untested isolates of a species over a year) may stay exact. This applies to docs, issues, pull requests, commit messages and agent replies.
- Scripts that read raw hospital data must mask small counts and free text by construction.
- `ADR-0008` (exact counts, no cell suppression) governs the indicator tables a hospital delivers to the national recipient (chapter 09). It does not apply to this repository.

## Architectural Boundaries

- **Portable Contract is the Seam**: Hospitals own their local LIS and data management. Site adapters map local hospital data into the portable contract (site handoff CSVs, `diagnostic_scope`). v3 enforces the contract and never applies fragile string heuristics to raw French free text (`ADR-0003`).
- **Common Input Audit**: Chapter 00 accepts local cleaning, mappings, diagnostic selection and retention of isolates with an antibiogram as completed input preparation. It audits the standardized site handoff before shared hospital perimeter selection and deduplication. Hospitalisation activity keeps its own population. Raw-source audits remain local (`ADR-0003`).
- **Raw Data Ingestion**: The target is that every witness derives directly from local raw files (`data/bact22_24`, `data/pmsi`) or site handoffs. Today most witness scripts still read the provisional `outputs/<run>/bundle_v3/sir_wide.rds` built by the v2 pipeline. This is tolerated until the new ETL is available; then every witness is rerun and its figures updated. Do not add new witnesses on v2 bundles.

## Non-Negotiable Methodological Invariants

1. **Vocabulary Discipline**: Consult `CONTEXT.md` before naming concepts. Never use "strain" when an isolate or counted bacterial population is meant.
2. **Selection Precedes Deduplication**: Any selection on isolates (specimen type, clinical perimeter, diagnostic scope) is an *input* to deduplication, never applied afterwards to deduplicated outputs (`ADR-0004`).
3. **Enzymatic Boundary for Note Xa**: SPARES Note Xa (absent signal = negative, hence denominator = species total) applies *strictly* to enzymatic reflex phenotypes: BLSE and carbapenemases in Enterobacterales and Pseudomonas (SPARES p. 15 and Annexe 6 footnote *a*, p. 31; p. 14 names Enterobacterales only). Antibiogram molecules (e.g. vancomycin in *E. faecium*) divide strictly by tested isolates ($n / N_{\text{tested}}$) (`ADR-0005`).
4. **SARM Precedence**: Cefoxitine is the primary methicillin-resistance marker; oxacilline is the surrogate fallback. Discordances are monitored via `TW-08.1` (`08-indicateurs.md`).
5. **Emergency Isolates and Named Perimeters**: Diagnostic samples (all of them, not only blood cultures) drawn in Emergency (`TA 10`) are handled across three named perimeters evaluated before deduplication: `spares_strict`; `spares_ed24h`, which links a `TA 10` sample followed within 24 hours by an eligible `TA 03/20` inpatient admission to the earliest receiving unit; and the standalone `emergency_ta10` for `%R` and isolate counts (`ADR-0009`).
6. **No Database Cell Suppression**: Indicator tables delivered to the national recipient use tall strata carrying full numerator, denominator, and rate; presentation masking is strictly a UI concern (`ADR-0008`).

## How to Run

Citation check (any machine, Python 3.11+ and poppler's `pdftotext`):

```sh
git config core.hooksPath .githooks                  # once per clone
python -m unittest discover tools/citecheck/tests    # offline tests
python tools/citecheck/citecheck.py --base origin/main
```

Witness scripts (only where the Rouen data are present, i.e. on Francesco's PC):

```sh
Rscript docs/worked-examples/<script>.R
```

- `ORCHIDEE_V3_RUN`: the run folder holding `bundle_v3/` and `site_inputs/` (default `outputs/rouen_stage2_2024`). Some docs still cite the older `outputs/rouen_current`.
- `ORCHIDEE_V3_REPO_ROOT`: the repository root (default: found from the script's location).
- Packages: base R, `readxl`, and `redsan` (required by `sector_returns.R`, optional for `denominator_profiles.R`).

A cloud session has no hospital data: it cannot run the witnesses, and must never invent or estimate their figures.

## Essential References

- **Domain Model & Glossary**: [`CONTEXT.md`](CONTEXT.md)
- **Architecture Decisions**: [`docs/adr/`](docs/adr/) (`ADR-0001` through `ADR-0009`)
- **Methodology Chapters**: [`docs/methods/`](docs/methods/) (Sections 00 through 09, status table in its `README.md`)
- **Tripwire Register**: [`docs/methods/tripwire-register.md`](docs/methods/tripwire-register.md) (exposure, deduplication, indicator and delivery checks)
- **Findings Log**: [`docs/findings.md`](docs/findings.md) (append-only discovery record)
- **Worked Examples & Witness Scripts**: [`docs/worked-examples/`](docs/worked-examples/)
- **Evidence**: [`docs/evidence/`](docs/evidence/) (external facts preserved under version control)

## Citation Check

Every citation in the docs must be checkable. A pre-commit hook (`tools/citecheck/`) blocks added lines where a reference disagrees with Crossref, a block quote is not verbatim in its source PDF, or a claim attributed to a named body (EARS-Net, SPARES, SPF...) has no page or section. CI runs the same check on every pull request. Do not bypass it with `--no-verify`: fix the citation, or, when a sentence only mentions a body, mark the paragraph `<!-- citecheck: ok, <reason> -->`.

## Agent skills

The engineering skills from `mattpocock/skills` are enabled for Claude Code through the project's `.claude/settings.json` (plugin `mattpocock-skills`), so cloud sessions get them too. Other agents (Codex, Antigravity) use the local copies installed with `skills.sh`, recorded in `skills-lock.json`.

- **Issue tracker**: GitHub Issues. See `docs/agents/issue-tracker.md`.
- **Triage labels**: the default canonical vocabulary. See `docs/agents/triage-labels.md`.
- **Domain docs**: a single-context layout. See `docs/agents/domain.md`.
