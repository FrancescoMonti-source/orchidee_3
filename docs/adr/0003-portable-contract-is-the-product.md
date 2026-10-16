# The portable contract is the product; Rouen is one site

The ORCHIDEE core reads only the site handoff. Site-specific references and
adapters - including every file under `ref/rouen/` - live outside the core, and
the core must not be able to read them. Rouen builds and first operates the
product, and holds no privileged position in the model.

## Why

Rouen is the implementing site, so Rouen assumptions are the ones most likely to
leak into shared code, and a directory boundary alone does not stop that. Other
hospitals supply their own mappings as run inputs; they never replace Rouen's
references.

## Consequences

- A hospital is onboarded by producing the handoff files, not by adding code.
- Anything the core needs must be expressible in the handoff. If a Rouen
  reference turns out to be necessary to the core, that is a defect in the
  contract, not a reason to read the file.
- The site adapter owns cleaning, antibiotic and bacterial mappings,
  diagnostic classification and selection, and retention of isolates with an
  antibiogram. Chapter 00 audits this prepared site handoff, accepting correct
  local preparation and diagnostic selection as input assumptions (issue #22).
  The common audit does not revalidate local decisions, read raw comments or
  recover records removed upstream, including screening records.
- The previous ORCHIDEE antibiotic and bacterial mappings are the foundation
  for improvement, not a declaration that every existing entry is correct.
  The common audit consumes prepared identities rather than interpreting
  local labels; unresolved equivalences, species/complex groupings and target
  lists remain mapping decisions. No dictionary changes are implemented here.
- Hospital perimeter selection remains shared and follows the common audit.
  Local diagnostic and antibiogram selection does not authorise additional
  local perimeter exclusions. Analysis-specific specimen selection precedes
  deduplication; Emergency linkage decisions remain unchanged.
- Hospitalisation activity retains its own population, including relevant
  activity from patients without cultures or antibiograms.
- Native raw-data auditing remains local; sites do not converge on Rouen's
  raw schema. Existing provenance qualifications in reviewed Suites 1–5 remain
  intact. The current audit records findings only and activates no automatic
  blocking, correction, quarantine or exclusion.
