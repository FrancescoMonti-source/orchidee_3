# Worked example: screening keyword hazards and phenotype absent-signal validity

Witness for decisions **06.5 (Resistance phenotypes)** and **06.7 (Screening contract)**.

**Slice**: Complete hospital microbiology, Rouen 2024 (`data/bact22_24`, 1,786,368 rows; 9,586 *Escherichia coli* diagnostic isolates).
**Witness script**: `docs/worked-examples/phenotypes_screening_witness.R`.

---

## 1. The screening keyword hazard: why `"recherche"` fails

A recurring intuition in hospital data exploration is to identify screening samples via text searches on analysis labels (`LBLANA`) or sample descriptions (`NATUREPVT`) containing `"recherche"`, `"dépistage"`, or `"rectal"`.

Across 2024 raw laboratory data (1.78M rows):
- Matching `"recherche"` catches **80,700 rows across 118 distinct laboratory test types**.
- While it captures carriage screening batteries (`BGSAMR_R` "RECHERCHE SAMR", `BGBLSE_R` "RECHERCHE BLSE", `BGCARBA_R` "RECHERCHE CARBA"), it simultaneously catches thousands of high-acuity diagnostic orders:

| Lab order label (`LBLANA`) | Clinical reality | 2024 rows caught |
|---|---|---|
| `RECHERCHE GONOCOQUE` | Sexually transmitted diagnostic swab | **6,231** |
| `Recherche de l'antigène Gdh` | *Clostridioides difficile* diagnostic stool test | **16,609** |
| `Recherche du gène tcdA` / `toxines C.diff` | *C. difficile* toxin diagnostic | **2,360** |
| `Recherche d'hématozoaire par frottis mince` | Malaria diagnostic blood film | **2,519** |
| `Recherche de bilharzies`, `cryptosporidies`, `LPV`, `mecA` | Diagnostic parasitology & molecular confirmation | > 1,500 |

Similarly, filtering on sample nature containing `"rectal"` catches invasive surgical collections (e.g. `Liquide ABCES PARARECTAL`, `Biopsie RECTAL`, `Liquide PARA RECTAL DROIT`) which are diagnostic surgical abscesses from acute inpatients.

### Conclusion for 06.7
In French medical biology, `"Recherche de [X]"` is the universal order naming convention for both carriage screening and targeted infectious diagnostics.

**Core ORCHIDEE must never attempt keyword guessing on analysis or sample descriptions.** Screening identification is strictly a site adapter responsibility, outputting the sample-level boolean `diagnostic_scope = TRUE / FALSE` (ADR 0003).

---

## 2. Phenotype absent-signal validity (SPARES Note Xa)

SPARES specifies that Enterobacterales isolates are characterized by resistance phenotypes (BLSE, carbapenemase), noting (Note Xa):
> *"En l'absence de mention d'un phénotype de résistance BLSE ou carbapénémase, celui-ci est considéré comme négatif."*

We tested whether an absent phenotype signal in raw LIS exports reliably indicates a negative phenotype, or whether it reflects missing data.

Across all 9,586 *Escherichia coli* diagnostic isolates in 2024, cross-tabulating the LIS ESBL confirmatory test (`BLSE.BLSE1`: `R` = positive, `S` = confirmed negative) against 3rd-generation cephalosporin resistance (`C3G_R`: cefotaxime, ceftriaxone, or ceftazidime resistant):

| BLSE Test in LIS | C3G Susceptible | C3G Resistant | Total isolates |
|---|---|---|---|
| **ABSENT** (no test row) | **8,636** (99.55 %) | 42 (4.6 %) | 8,678 (90.5 %) |
| **S** (explicitly negative) | 32 (0.37 %) | 110 (12.1 %) | 142 (1.5 %) |
| **R** (explicitly positive) | 7 (0.08 %) | **759** (83.3 %) | 766 (8.0 %) |
| **Total** | **8,675** | **911** | **9,586** |

### Findings
1. **Absence is wild-type**: Among 8,675 C3G-susceptible isolates, **8,636 (99.55 %)** have no BLSE row whatsoever. Routine hospital bacteriology does not run or document phenotypic ESBL confirmation when the screening cephalosporin disk is fully susceptible.
2. **Positives are captured**: 99.1 % of positive BLSE tests (759/766) coincide with C3G resistance. The 110 C3G-resistant isolates with `BLSE == S` represent non-ESBL resistance mechanisms (AmpC hyperproduction, cephalosporinases).

### Conclusion for 06.5
Treating an absent phenotype signal as negative (`FALSE`) is clinically exact, reflects routine laboratory workflow, and adheres 100% to SPARES Note Xa without creating missing-data leakage.

