# Domain Docs

How agents should consume and contribute to ORCHIDEE V3's domain documentation and architecture.

## Before exploring or modifying

Read the reading list in `AGENTS.md` (Essential References), then the ADRs and the method chapter that touch the area you are about to work in.

If a concept or decision is missing, do not invent ad-hoc vocabulary: propose a definition for `CONTEXT.md` or a new ADR, and say so in your reply. The `domain-modeling` and `grill-with-docs` skills help capture it as decisions crystallize.

## Repository Domain Structure

```
/
├── AGENTS.md                                  ← agent guidelines & non-negotiable invariants (CLAUDE.md links here)
├── CONTEXT.md                                 ← single source of truth for domain vocabulary
├── data/                                      ← local hospital inputs, ignored by Git, never committed
├── outputs/                                   ← local run bundles and measurements, ignored by Git
├── docs/
│   ├── adr/                                   ← Architecture Decision Records (0001–0009)
│   ├── agents/                                ← agent conventions (this file, issue tracker, labels)
│   ├── evidence/                              ← external facts preserved under version control
│   ├── findings.md                            ← chronological findings ledger
│   ├── methods/                               ← method chapters (00 to 09, tripwire register)
│   └── worked-examples/                       ← narrative worked examples and R witness scripts
├── ref/                                       ← reference tables (consores/ TA-DE codes, rouen/ unit structure)
└── tools/citecheck/                           ← citation checker run by the pre-commit hook and CI
```

## Use the Glossary's Vocabulary

When naming any domain concept (in code, documentation, issue titles, commit messages, or hypotheses):
- Use the exact canonical terms defined in `CONTEXT.md`.
- Never use forbidden synonyms (e.g., avoid using "strain" when an isolate or counted bacterial population is meant).

## Flag ADR Conflicts

If your proposal or finding contradicts an existing ADR, surface the conflict explicitly rather than silently overriding it:

> _Contradicts ADR-0005 (phenotype indicators use SPARES Note Xa), but worth reopening because…_
