# Resistance phenotype indicators use SPARES Note Xa species-wide denominators

Enzymatic resistance phenotype indicators (BLSE, Carbapenemase) treat unrecorded
confirmatory tests as negative (`FALSE`), and divide by the total deduplicated
population of that bacterial species, strictly implementing SPARES Note Xa.

## Why

In routine hospital bacteriology, confirmatory phenotype testing (such as double-disk
synergy or PCR) is reflex testing triggered only when an isolate exhibits resistance
or decreased susceptibility to screening markers (e.g. 3rd generation cephalosporins).
Wild-type susceptible isolates do not undergo confirmatory testing and carry no record
in the laboratory information system.

Dividing positive cases only by explicit test rows creates an extreme ascertainment
bias: on Rouen 2024 data, 186 *E. coli* isolates are BLSE-positive out of 224 explicit
phenotype test records, yielding an artificial resistance proportion of **83.04 %**.
Under SPARES Note Xa, an absent record is negative, and the denominator is the full
deduplicated species population (2 445 isolates), yielding the true epidemiological
rate of **7.61 %** (+75.4 pp distortion avoided; `Finding 18`).

## Consequences

- Phenotype columns (`blse`, `carbapenemase`) are logical flags (`TRUE` / `FALSE`),
  never tri-state with missing values in deduplicated tables.
- The denominator for phenotype proportions is `total_isolates` of that species,
  matching the national SPARES and ONERBA benchmark.
- Pre-flight audit tripwire `TW-06.1` asserts biological plausibility, ensuring that
  susceptible strains never carry positive phenotype flags.
