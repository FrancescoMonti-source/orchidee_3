# 02 - Establishments included and excluded

Status: **settled**. Four decisions, four witnesses, zero unproven. Zero open.

---

## What SPARES says

> Sont inclus tous les établissements de santé publics et privés ayant une activité
> d'hospitalisation complète et/ou d'hospitalisation de semaine, ainsi que les EHPAD
> disposant d'une pharmacie à usage intérieur (PUI).
>
> Sont exclus : les structures d'hospitalisation à domicile (HAD), les centres de
> dialyse ambulatoire, les maisons d'enfants à caractère sanitaire spécialisé (MECSS).

---

## What SPF asks

SPF requires indicators at the establishment level, allowing comparison and aggregation
across health establishments nationally, and raises the perimeter of attached residential
facilities as an open inquiry.

---

## What ORCHIDEE does

### 1. Inpatient Perimeter and Residential Care Boundary
- **Included**: All healthcare units with complete or weekly inpatient hospitalisation (`CODE_TA ∈ {03, 20}`) within eligible clinical sectors (Medicine, Surgery, Intensive Care, Rehabilitation, Long-term Care, Pediatrics, Obstetrics; see `03-activites.md`).
- **Excluded**:
  - Residential elderly nursing homes (**EHPAD**), whether standalone or attached to a hospital group, are **excluded from acute hospital surveillance**. Residential colonisation and carriage profiles belong to community/geriatric surveillance (such as the national PRIMO mission) and must not be confounded with acute hospital bacteremias and ICU incidence densities.
  - Hospitalisation at home (**HAD**), ambulatory dialysis, and **MECSS** are excluded.

### 2. Multi-Site Identification via Functional Units (UF)
In routine hospital data warehouses (such as Rouen's EDSH), individual clinical rows carry the functional unit code (`SEJUF`), but do not carry a bare establishment identification number:
- ORCHIDEE runs against the hospital group's clinical data warehouse as a unified execution representing the legal entity (**FINESS juridique**, e.g. `760780248` for CHU de Rouen).
- Physical geographic sites (**FINESS géographique**, e.g. Hôpital Charles-Nicolle `760000399`, Hôpital de Bois-Guillaume `760000407`, etc.) are resolved automatically by mapping the functional unit through the annual structural snapshot:
  $$\text{SEJUF} \longrightarrow \text{finess\_geo}$$
- Data is **never split into artificial separate database extracts**. Instead, physical site identity is modeled as a native stratum dimension within the single **tall indicator table** (`ADR-0008`):
  - `stratum_dimension = "overall"`: represents the whole hospital group (*FINESS juridique*).
  - `stratum_dimension = "finess_geo"`: represents the site-specific indicator for that physical campus (*FINESS géographique*).

### 3. Patient Movements and Inter-Site Transfers
When patients transfer between physical campuses within the hospital group:
- Isolate attribution strictly follows the functional unit where the sample was collected at the sample timestamp (`SEJUF` $\rightarrow$ `finess_geo`), in accordance with `ADR-0006` and `ADR-0009`.
- Exposure days ($JH$) accumulate in the clinical unit where the patient physically resided.
- Transferring between physical sites requires no retrospective heuristics: each campus receives the bacteremic events and exposure days that occurred during the patient's presence on that campus.

---

## Decisions

All witnesses measured on real Rouen data (`data/bact22_24`, `data/pmsi`, `ref/rouen/establishment_structure_2025.xlsx`).

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 02.1 | Residential care (EHPAD) | excluded from acute surveillance | pooled with acute hospital | prevents chronic elderly carriage from distorting acute inpatient resistance rates; EHPAD reported to PRIMO |
| 02.2 | Data warehouse scope | unified run over legal establishment (*FINESS juridique*) | partition extract by physical site | eliminates operational ETL duplication; whole hospital group processed in one pass |
| 02.3 | Multi-site granularity | stratum dimension in tall indicator table (`finess_geo`) | separate files per physical campus | single deliverable answers both whole-group reporting and site-specific benchmarking (`ADR-0008`) |
| 02.4 | Inter-site transfers | strict unit attribution at sample timestamp | assign to originating campus | preserves physical bed exposure linkage; transfer events bounded by `SEJUF` movement intervals |

Unproven: **0 of 4**.

---

## Open

None. Chapter 02 is settled.
