# ORCHIDEE methods

This document answers the SPARES methodology section by section, in the same
order, so the two can be read side by side. Where ORCHIDEE does what SPARES
does, the section says so and stops. Where it differs, the section states the
difference, the reason, and the witness that measures it.
<!-- citecheck: ok, describes how this document is organised; states nothing about the content of SPARES -->

Source: `docs/Methodologie SPARES we need to reproduce and improve upon.pdf`
and `docs/Expression de besoins SPF.pdf`.

Scope: **RATB only**. The consumption sections of the SPARES methodology are
listed for completeness and marked out of scope; they belong to the CATB
project, which shares the establishment structure, the perimeter and the
patient-day denominator (see `04-donnees-activite.md`).

## Status

| SPARES section | ORCHIDEE section | Status |
|---|---|---|
| Traitement des données (contrôle qualité pré-vol) | [00](00-audit-qualite.md) | **Suites 1–5 reviewed and retained; Suite 6 revised, with open details identified** |
| Période de surveillance | [01](01-periode-surveillance.md) | **settled** |
| Établissements inclus / exclus | [02](02-etablissements.md) | **settled** |
| Activités incluses / exclues | [03](03-activites.md) | **settled** |
| Données d'activité | [04](04-donnees-activite.md) | **settled** |
| Structure de l'établissement | [05](05-structure.md) | **settled** |
| Données de résistance bactérienne | [06](06-donnees-resistance.md) | **resistance rules retained; input boundary clarified; mapping details open** |
| Dédoublonnage | [07](07-dedoublonnage.md) | **settled** |
| Construction des indicateurs | [08](08-indicateurs.md) | **settled** |
| Analyse et diffusion | [09](09-diffusion.md) | **settled** |
| Données de consommation (ATB / ATF) | — | out of scope |

`not started` means no decision has been taken, not that the section is empty of
questions. `partial` means some decisions are settled and the section names what
is still open.

## Cross-cutting catalogs

Chapter 00 audits the prepared site handoff after local cleaning, antibiotic
and bacterial mappings, diagnostic selection and retention of isolates with an
antibiogram. Correct local preparation is accepted. Shared hospital perimeter
selection and analysis-specific specimen selection follow the audit and precede
deduplication. Hospitalisation activity keeps its own population, including
relevant activity from patients without cultures or antibiograms. Suite 6's
remaining counting and presentation choices stay explicitly open; no executable
audit or automatic response is activated by this documentation revision.

- [audit-checkpoints-deferred.md](audit-checkpoints-deferred.md) - Archived
  discussions, historical figures and the superseded raw-only specification.
  Chapter 00 restores the reviewed Suites 1–5 and retained Suite 6 decisions;
  unresolved proposals and historical figures remain distinguished from them.
- [tripwire-register.md](tripwire-register.md) - The unified catalog of all 9
  dynamic pipeline tripwires (TW-04.1 through TW-09.2), their mathematical trigger
  thresholds, action policies, and empirical Rouen baselines.


## Where else things are written down

- `../findings.md` - an append-only log of what was discovered while writing
  this document, newest last, each entry pointing here or to a worked example.
  It is a log, not an index: nothing depends on it and it never claims to be
  complete, so it cannot drift out of step with the sections.
- `../worked-examples/` - the measurements a witness cites, with their
  reproduction scripts.
- `../evidence/` - external facts preserved because their original location was
  not under version control.
- `../adr/` - decisions whose reach is wider than one section.

## How a section is written

Each section has the same four parts:

1. **What SPARES says** — quoted, not paraphrased, so a reader can check it. <!-- citecheck: ok, names the section that quotes SPARES; the quotes carry their own pages -->
2. **What ORCHIDEE does** — in enough detail to implement without choosing.
3. **Decisions** — every choice where SPARES was silent, vague, or where ORCHIDEE decided to do things cleanly and differently. Each choice records the question, the chosen answer, the alternative, and its witness:
   - **Witness**: the empirical proof measured from real hospital data showing what difference the choice makes versus the alternative.
   - **Unproven**: the choice and rationale are stated, but an empirical script has not yet been run on real hospital data to measure the exact numerical delta.
   - **Settled**: the decision is locked and backed by a real numerical witness (or verified zero divergence).
4. **Open** — what is not yet decided, and what would settle it.

Part 3 is the point of the whole document. A decision with no witness is marked
`unproven` and counted; it is not hidden.
