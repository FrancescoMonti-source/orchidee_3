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
