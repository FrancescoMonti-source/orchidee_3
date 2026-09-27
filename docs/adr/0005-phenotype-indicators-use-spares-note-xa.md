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
  susceptible isolates never carry positive phenotype flags.

## Known weakness

The argument above holds only when the screening molecules were tested. An
isolate with no third-generation cephalosporin result could not have triggered a
BLSE confirmation, so its absent signal means *unknown*, not *negative*. The
flag still reads `FALSE`, and the same reading enters deduplication, where the
source also counts a blank phenotype cell as absent. There, it keeps apart two
isolates that the antibiotic rule, which never counts a blank result as a
difference, would treat as duplicates.

Measured at Rouen, eligible perimeter: 0, 2 and 0 pairs of isolates in 2022,
2023 and 2024 are kept apart only by a BLSE flag whose negative side had no
third-generation cephalosporin tested
(`docs/worked-examples/incomplete-antibiotypes.md`). The fix would be a third
state, *not assessable*, which needs a list of marker molecules per species and
changes the phenotype indicators as well as deduplication. Not done: the effect
is at most 2 isolates in three years at one site. A site whose panels often omit
third-generation cephalosporins would see more.

