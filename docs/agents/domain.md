# Domain Docs

How agents should consume and contribute to ORCHIDEE V3's domain documentation and architecture.

## Before exploring or modifying, read these

- **`CONTEXT.md`** at the repo root: defines the single-context domain glossary and mandatory terminology.
- **`docs/adr/`**: read ADRs that touch the area you are about to work in (`ADR-0001` through `ADR-0009`).
- **`docs/methods/`**: read the corresponding methodological specification (Sections 00 through 08).
- **`docs/methods/tripwire-register.md`**: review the dynamic tripwires that guard data quality and invariant violations.
- **`docs/findings.md`**: read the append-only record of empirical discoveries.

If a concept or decision is missing, proceed silently and rely on `/domain-modeling` (reached via `/grill-with-docs`) to capture it lazily as decisions crystallize.

## Repository Domain Structure

```
/
├── AGENTS.md                                  ← agent guidelines & non-negotiable invariants
├── CONTEXT.md                                 ← single source of truth for domain vocabulary
├── data/
│   ├── bact22_24                              ← raw bacteriology extract (protected, ignored)
│   ├── pmsi                                   ← raw hospitalisation movements (protected, ignored)
│   └── site_handoff/                          ← benchmark handoff contract CSVs
├── docs/
│   ├── adr/                                   ← Architecture Decision Records (0001–0009)
│   ├── agents/                                ← agent governance and skills configuration
│   ├── findings.md                            ← chronological findings ledger
│   ├── methods/                               ← method chapters (00 to 08, tripwire register)
│   └── worked-examples/                       ← narrative worked examples and R witness scripts
└── ref/                                       ← national reference tables (DE, ONERBA, etc.)
```

## Use the Glossary's Vocabulary

When naming any domain concept (in code, documentation, issue titles, commit messages, or hypotheses):
- Use the exact canonical terms defined in `CONTEXT.md`.
- Never use forbidden synonyms (e.g., avoid using "strain" when an isolate or counted bacterial population is meant).
- If a concept is absent from `CONTEXT.md`, propose its definition rather than inventing ad-hoc vocabulary.

## Flag ADR Conflicts

If your proposal or finding contradicts an existing ADR, surface the conflict explicitly rather than silently overriding it:

> _Contradicts ADR-0005 (phenotype indicators use SPARES Note Xa), but worth reopening because…_
