# ORCHIDEE V3 — Agent Guidelines

ORCHIDEE V3 establishes a transparent, national-level antimicrobial resistance (AMR) surveillance methodology to propose to Santé publique France (SPF), superseding legacy ConsoRes/SPARES and V1/V2 pipelines. V3 is an open, generalized surveillance engine operating across all organisms and hospital bacteriology streams.

## Architectural Boundaries

- **Portable Contract is the Seam**: Hospitals own their local LIS and data management. Site adapters map local hospital data into the portable contract (`data/site_handoff/` CSVs, `diagnostic_scope`). Core ORCHIDEE enforces the contract and never applies fragile string heuristics to raw French free text (`ADR-0003`).
- **Raw Data Ingestion**: All pipelines and witnesses derive directly from local raw files (`data/bact22_24`, `data/pmsi`) and site handoffs. Never rely on legacy V2 intermediate bundles (`sir_wide.rds`).

## Non-Negotiable Methodological Invariants

1. **Vocabulary Discipline**: Consult `CONTEXT.md` before naming concepts. Never use "strain" when an isolate or counted bacterial population is meant.
2. **Selection Precedes Deduplication**: Any selection on isolates (specimen type, clinical perimeter, diagnostic scope) is an *input* to deduplication, never a post-filter on deduplicated outputs (`ADR-0004`).
3. **Enzymatic Boundary for Note Xa**: SPARES Note Xa (absent signal = negative, denominator = species total) applies *strictly* to enzymatic reflex phenotypes (BLSE and carbapenemases in Enterobacterales). Antibiogram molecules (e.g. vancomycin in *E. faecium*) divide strictly by tested isolates ($n / N_{\text{tested}}$) (`ADR-0005`).
4. **SARM Precedence**: Cefoxitine is the primary methicillin-resistance marker; oxacilline is the surrogate fallback. Discordances are monitored via `TW-08.1` (`08-indicateurs.md`).
5. **Emergency Pre-Admission Linkage**: Blood cultures drawn in Emergency (TA 10) link to an acute inpatient stay if admitted within 24 hours, attributed to the initial admitting unit (`ADR-0009`).
6. **No Database Cell Suppression**: Indicator tables use tall strata carrying full numerator, denominator, and rate; presentation masking is strictly a UI concern (`ADR-0008`).

## Essential References

- **Domain Model & Glossary**: [`CONTEXT.md`](CONTEXT.md)
- **Architecture Decisions**: [`docs/adr/`](docs/adr/) (`ADR-0001` through `ADR-0009`)
- **Methodology Chapters**: [`docs/methods/`](docs/methods/) (Sections 00 through 08)
- **Tripwire Register**: [`docs/methods/tripwire-register.md`](docs/methods/tripwire-register.md) (TW-04.1 to TW-08.1)
- **Findings Log**: [`docs/findings.md`](docs/findings.md) (append-only discovery record)
- **Worked Examples & Code**: [`docs/worked-examples/`](docs/worked-examples/)

## Agent skills

### Issue tracker

Issues are tracked in this repository's GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

The default canonical label vocabulary is used. See `docs/agents/triage-labels.md`.

### Domain docs

This repository uses a single-context domain-document layout. See `docs/agents/domain.md`.
