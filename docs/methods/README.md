# ORCHIDEE methods

This document answers the SPARES methodology section by section, in the same
order, so the two can be read side by side. Where ORCHIDEE does what SPARES
does, the section says so and stops. Where it differs, the section states the
difference, the reason, and the witness that measures it.

Source: `docs/Methodologie SPARES we need to reproduce and improve upon.pdf`
and `docs/Expression de besoins SPF.pdf`.

Scope: **RATB only**. The consumption sections of the SPARES methodology are
listed for completeness and marked out of scope; they belong to the CATB
project, which shares the establishment structure, the perimeter and the
patient-day denominator (see `04-donnees-activite.md`).

## Status

| SPARES section | ORCHIDEE section | Status |
|---|---|---|
| Période de surveillance | [01](01-periode-surveillance.md) | not started |
| Établissements inclus / exclus | [02](02-etablissements.md) | not started |
| Activités incluses / exclues | [03](03-activites.md) | **settled** |
| Données d'activité | [04](04-donnees-activite.md) | **settled** |
| Structure de l'établissement | [05](05-structure.md) | not started |
| Données de résistance bactérienne | [06](06-donnees-resistance.md) | **partial** |
| Dédoublonnage | [07](07-dedoublonnage.md) | **settled** |
| Construction des indicateurs | [08](08-indicateurs.md) | **partial** |
| Analyse et diffusion | [09](09-diffusion.md) | not started |
| Données de consommation (ATB / ATF) | — | out of scope |

`not started` means no decision has been taken, not that the section is empty of
questions. `partial` means some decisions are settled and the section names what
is still open.

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

1. **What SPARES says** - quoted, not paraphrased, so a reader can check it.
2. **What ORCHIDEE does** - in enough detail to implement without choosing.
3. **Decisions** - every choice SPARES leaves open, with the alternative and its
   witness. See `CONTEXT.md` for what witness, tripwire and unproven mean.
4. **Open** - what is not yet decided, and what would settle it.

Part 3 is the point of the whole document. A decision with no witness is marked
`unproven` and counted; it is not hidden.
