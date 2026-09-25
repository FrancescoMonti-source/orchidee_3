# 09 - Analysis and diffusion

Status: **settled**. Four decisions, two tripwires, zero unproven. Two follow-ups under Open.

---

## What SPARES says

> L'analyse des données est réalisée par la mission nationale SPARES. Elle débute par un
> contrôle de cohérence et de plausibilité de l'ensemble de la base de données.
>
> Les résultats font l'objet d'un rapport national annuel et de restitutions régionales et
> locales destinées aux établissements participants. Ils alimentent également la surveillance
> européenne (EARS-Net, GLASS).

---

## What SPF and PDS ask

Santé publique France (SPF) and the Plateforme des données de santé (PDS / Health Data Hub)
require reliable, standardized transmission of AMR indicators across participating healthcare
establishments. Indicators feed national epidemiological surveillance, international reporting,
and local infection-prevention steering, while strictly complying with statistical disclosure
control (SDC) regulations for external diffusion.

---

## What ORCHIDEE does

### 1. Statistical Disclosure Control Boundary (Unmasked Delivery to PDS)
- Core ORCHIDEE computes and delivers **100 % unmasked indicator tables** (`ADR-0008`), preserving exact numerators, denominators, testing coverage, and exposure days across all strata.
- Individual hospitals do **not** apply cell suppression or presentation masking ($n < 5$ or $n < 10$).
- Statistical disclosure control (primary and secondary/complementary suppression) and public visualizations are strictly the operational responsibility of the national receiving infrastructure (**PDS / HDH**) and **SPF** at the national diffusion tier.
- This prevents algebraic distortion, preserves additivity across strata, and eliminates redundant, divergent masking logic across hundreds of hospital sites.

### 2. Delivery Bundle Architecture
Deliveries to PDS / HDH are packaged as self-contained, immutable release bundles (`.tar.gz` or `.zip`):
$$\text{ORCHIDEE\_}\langle\text{FINESS}\rangle\text{\_}\langle\text{YEAR}\rangle\text{\_}\langle\text{GRAIN}\rangle\text{\_}\langle\text{RUN\_ID}\rangle\text{.tar.gz}$$
The bundle contains:
1. `indicators.parquet`: Primary strongly-typed, compressed columnar table of unmasked indicators (`ADR-0008`).
2. `indicators.csv.gz`: Compressed CSV fallback for universal inspection without Parquet tooling.
3. `exposure.parquet` and `exposure.csv.gz`: Stratified exposure days and midnight presences (`ADR-0006`).
4. `manifest.json`: Machine-readable metadata recording `site_id` (FINESS juridique), campaign year, temporal grain, pipeline git commit SHA, `structure_snapshot_hash`, run timestamp, and the post-flight audit ledger.

### 3. Two-Tier Post-Flight Quality Audit
Before packaging a delivery bundle, ORCHIDEE runs automated post-flight verification on the generated indicator table:
- **Fatal Structural Invariants (Hard Block)**:
  - $N_{\text{num}} \le N_{\text{den}}$ and $\text{rate} \in [0.0, 1.0]$.
  - Exposure days $> 0$ for all active hospital sectors.
  - Zero unmapped functional units (`SEJUF`) or invalid FINESS codes.
  - Foreign-key referential integrity between `indicators` and `exposure`.
  *Action*: Any fatal violation halts delivery packaging immediately.
- **Microbiological and Epidemiological Tripwires (Soft Warning)**:
  - **EUCAST Exceptional Phenotypes (`TW-09.1`)**: Detects isolates violating EUCAST intrinsic resistance or exceptional resistance rules (e.g. vancomycin-resistant *S. aureus*, ampicillin-susceptible *K. pneumoniae*).
  - **Surge / Outbreak Anomaly (`TW-09.2`)**: Detects abrupt year-over-year rate jumps ($> 3\times$ increase with $N_{\text{tested}} \ge 30$).
  *Action*: Non-blocking warnings recorded in `manifest.json` (`status = "FLAGGED"`), alerting hospital biologists and PDS/SPF without halting batch submission during real clinical outbreaks.

### 4. Turnkey Local Hospital Feedback Dashboard
- ORCHIDEE bundles an out-of-the-box, parameterized Quarto HTML report that directly consumes the unmasked indicator table.
- Generates a standalone, interactive dashboard for local hospital teams (EOH / CLIN and bacteriology), including AMR trend lines, sector breakdowns, statistical process control, and pre-/post-flight quality audit summaries.
- Advanced hospital sites remain fully empowered to bypass the template and feed the raw unmasked tables directly into their local enterprise BI platforms (PowerBI, Metabase, etc.).

---

## Decisions

| # | Decision | Chosen | Alternative | Witness |
|---|---|---|---|---|
| 09.1 | Privacy masking boundary | 100 % unmasked indicator upload to PDS; masking ($n < 5$) performed nationally by PDS/SPF | site-level cell suppression | protects database additivity; eliminates distributed masking code across hospitals; conforms to ADR-0008 |
| 09.2 | Delivery bundle architecture | self-contained immutable package with Parquet, CSV fallback, and `manifest.json` | bare CSV files or live database API | offline execution across hospital firewalls; complete historical auditability and cryptographic reproducibility |
| 09.3 | Post-flight audit tiering | fatal structural breaches hard-block packaging; microbiological/epidemiological tripwires log warnings in manifest | all checks block, or pure ledger | prevents corrupt data delivery without suppressing surveillance reporting during genuine biological outbreaks |
| 09.4 | Local hospital feedback deliverable | turnkey static Quarto HTML report consuming unmasked indicator table | headless tables only, or live Shiny app | zero-maintenance, serverless clinical steering for hospital hygiene teams, while preserving custom BI freedom |

Unproven: **0 of 4**.

---

## Notes & Tripwires

### 09.1 note — the PDS / HDH architectural boundary

The Plateforme des données de santé (PDS / Health Data Hub) operates as the technical receiving
and aggregation backbone on behalf of Santé publique France. Transferring unmasked tall indicator
tables to PDS places statistical disclosure control (SDC) where it belongs: at the national aggregation
point where multi-center data is merged and external visualizations are published.

### 09.3 tripwire (TW-09.1) — EUCAST exceptional and aberrant phenotypes

**Statement**: Zero unquarantined isolates display biologically aberrant resistance phenotypes
contradicting EUCAST expert rules and intrinsic resistance guidelines (cataloged as `TW-09.1` in
`tripwire-register.md`).
**Today**: Rouen 2024 records **0** exceptional phenotypes (0 VRSA, 0 ampicillin-susceptible
*K. pneumoniae*, 0 colistin-susceptible *P. mirabilis*).

The tripwire triggers if any unquarantined isolate exhibits an exceptional resistance profile,
logging a soft warning in the delivery `manifest.json` for validation by the hospital medical biologist.

### 09.3 tripwire (TW-09.2) — temporal surge and outbreak detection

**Statement**: In routine hospital surveillance, annual resistance proportions on stable sample
volumes ($N_{\text{tested}} \ge 30$) do not experience $> 3\times$ relative increases (cataloged as
`TW-09.2` in `tripwire-register.md`).
**Today**: Stable resistance trajectories at Rouen between 2022 and 2024.

The tripwire triggers if an indicator exhibits a $> 3\times$ year-over-year surge, flagging the
stratum in `manifest.json` as a potential clinical outbreak or testing panel artifact.

---

## Open

- **2024 Transition Monograph (Divergence Account)**: An ad hoc, one-time reconciliation study
  explaining the exact numerical delta between ConsoRes 2024 and ORCHIDEE 2024 across a structured
  waterfall of named methodological decisions (movement-derived exposure, emergency pre-admission
  linkage, rolling refractory window, Note Xa reflex denominator). To be formalized in
  `docs/worked-examples/2024-consores-divergence-account.md`.
- **Microbiologist Consultation for Biological Rules**: Collaboration with hospital medical
  biologists to expand and fine-tune the catalog of EUCAST expert rules and intrinsic resistance
  profiles incorporated into `TW-09.1`.
