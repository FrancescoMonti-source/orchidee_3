# Evidence

Measurements that an argument in the specification rests on, preserved here
because their original location was not under version control.

- `2026-08-02_amc_remapping_cascade.txt` — measured effect of correcting the
  CLAVENTIN → amoxicilline-acide clavulanique mapping in the v2 pipeline
  (commit `95d3b9e`, repo `orchidee`). One source row changed; 51 isolates
  disappeared from the deduplicated global scope and the denominators of 20
  antibiotic columns moved with them. Produced by
  `outputs/_analysis/compare_panels.R`, in a gitignored directory.
