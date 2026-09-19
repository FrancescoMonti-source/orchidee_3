# Evidence

Measurements that an argument in the specification rests on, preserved here
because their original location was not under version control.

- `2026-08-02_amc_remapping_cascade.txt` — measured effect of correcting the
  CLAVENTIN → amoxicilline-acide clavulanique mapping in the v2 pipeline
  (commit `95d3b9e`, repo `orchidee`). One source row changed; 51 isolates
  disappeared from the deduplicated global scope and the denominators of 20
  antibiotic columns moved with them. Produced by
  `outputs/_analysis/compare_panels.R`, in a gitignored directory.
- `2024_consores_rouen_denominator.md` — the JH denominator ConsoRes used for
  CHU Rouen in 2024 (589 397), transcribed from the published report, against
  ORCHIDEE's perimeter-correct 355 246. Kept as the receipt for a 40 %
  divergence ORCHIDEE will be asked to justify, not as a reference.
