# 05 - Establishment structure

Status: **not started**.

## What SPARES says

A structure file is loaded before any activity, consumption or resistance data.
Per unite fonctionnelle: code and label UF, optional service and pole, code
discipline d'equipement (DE), code type d'activite (TA).

> Il est indispensable de s'assurer de la coherence stricte entre la
> codification des UF utilisee par l'administration, la pharmacie et le
> laboratoire.

## Open

- That coherence requirement is the joint on which everything else rests, and
  nothing verifies it. What does ORCHIDEE check, and what does it refuse?
- A sample's unit is the hospitalisation unit active at the sampling time,
  derived from the intervals. What happens when attribution is ambiguous or
  absent? v2 assigns `NA` and drops the sample from the perimeter rather than
  attaching it at random. Confirm, and measure how many samples this loses.
- Structure changes between years. Is the structure versioned per period, and
  what happens to a unit created, merged or closed mid-year?
