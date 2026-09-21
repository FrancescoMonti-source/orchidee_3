# Worked example: sample hospitalisation unit attribution and unit-less isolates

Witness for decision 05.1, and the resolution of the unit-less isolate open question
from `03-activites.md`.

**Slice**: *Escherichia coli*, all sample types, diagnostic scope, sampling year
2024. Annual window, grouping by patient, SPARES panel, `ZIT` read as `SFP`.
Built from `bundle_v3/sir_wide.rds` joined to
`site_inputs/microbiology_observations.rds` and
`bundle_v3/sample_scope_reference.rds`. Reproduction:
`unit_attribution_witness.R`.

## The problem

In Rouen's diagnostic isolate extract (`sir_wide.rds`), **3 650 isolates** carry
no hospitalisation unit (`SEJUF = NA`) — 7.5 % of the bundle (1 552 in 2022, 925
in 2023, 1 173 in 2024).

The referential itself is essentially complete (1 153 of 1 159 UFs classified).
100 % of these 3 650 isolates carry a valid `microbiology_SEJUF` in the raw
laboratory export. Attribution failed during the interval join
(`build_chu_sample_hospitalization_unit_attribution`) because:
- **`no_active_interval`**: 3 610 (98.9 %)
- **`multiple_active_unit_pairs`**: 25 (0.7 %)
- **`active_interval_missing_complete_unit_pair`**: 9 (0.2 %)
- **`ambiguous_local_sample_datetime`**: 6 (0.2 %)

## Why interval attribution fails

Evaluating the 3 650 isolates against the establishment structure reveals two
distinct mechanisms:

1. **Non-admissions and ambulatory care: 2 190 isolates (60 %)**
   - TA 10 (urgences): 1 278
   - TA 07 (consultations externes): 447
   - TA 04 (hospitalisation de jour): 164
   - TA 09 (séances): 149
   - TA 11, 19, 23, 26, 32: 152
   These patients were never admitted to complete or weekly hospitalisation. The
   absence of a PMSI stay interval is legitimate: they are out of scope for the
   SPARES perimeter.

2. **Extraction boundaries and timing offsets: 1 456 isolates (40 %)**
   - **632 in USLD** (soins de longue durée; UFs 7163, 7183, 7180, etc.): long-term
     care stays are not captured in the acute PMSI MCO movement extract.
   - **824 in MCO** (Chirurgie 266, Médecine 206, Réanimation 124, SSR 115,
     Pédiatrie 55, Gynécologie 51): predominantly pre-admission sampling (e.g.
     sample taken at 08:30 in the ED before movement registration opens at 15:10)
     or stays omitted from the warehouse export.

## The comparison on E. coli 2024

| | isolates |
|---|---|
| in the extract, all units | 6 519 |
| eligible under PMSI attribution alone (Option A) | 2 868 |
| eligible under fallback to laboratory UF (Option B) | 3 015 (+147) |
| **A — Strict PMSI attribution (v2 today)** | **2 445** |
| **B — Fallback to laboratory ordering UF** | **2 555** |
| difference | **+110, +4.5 %** |
| **patients gained under B** | **93** |

| Molecule | A %R (n) | B %R (n) | shift |
|---|---|---|---|
| amoxicilline-ac. clavulanique | 39,92 (2380) | 40,04 (2485) | +0,12 pp |
| céfotaxime | 14,80 (1372) | 15,82 (1435) | **+1,02 pp** |
| ofloxacine | 14,74 (2245) | 15,48 (2345) | **+0,74 pp** |
| cotrimoxazole | 30,03 (2381) | 29,92 (2490) | −0,11 pp |
| gentamicine | 6,76 (2248) | 6,73 (2348) | −0,03 pp |
| ertapénème | 0,29 (2430) | 0,31 (2540) | +0,02 pp |

## The denominator hazard

Option B adds 110 deduplicated isolates to the numerator, but the PMSI denominator
holds **no corresponding hospital days** for them:
- The 632 USLD isolates would divide by 17 patient-days in 2024.
- Pre-admission MCO isolates would divide by days that only start counting after
  the sample was taken.

Under decision 04.7, the perimeter is one object handed to both numerator and
denominator. Admitting isolates into the numerator whose exposure is absent from
the denominator produces an incidence density of nothing.

Option A is chosen: an isolate without active hospitalisation exposure cannot enter
the numerator. The 2 190 outpatient cases are legitimately excluded; the 1 456
extraction-boundary cases must be resolved at the adapter level (by extracting
USLD movements or aligning admission timestamps), not by patching the attribution
rule with an assumption movement data contradicts.

