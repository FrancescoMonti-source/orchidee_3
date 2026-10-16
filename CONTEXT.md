# ORCHIDEE v3 — antimicrobial resistance

An independent methodology proposal (v3) for the antimicrobial resistance strand
of ORCHIDEE: semi-automated surveillance of resistance computed from a
hospital's own data warehouse, producing aggregated indicators for Santé
Publique France. Nobody commissioned v3; its decisions are its author's. This
glossary is written for the author and the agents.

## Language

**Site**:
A hospital that runs v3 against its own data. Rouen is the site that
builds and first operates the product; it holds no privileged position in the
model.
_Avoid_: établissement (when the running hospital is meant), client, partner

**Semantic mapping** (*mise en correspondance sémantique*):
A documented correspondence between a source label or code and a defined
category or concept, such as a specimen category, bacterial taxon or antibiotic
identity. It classifies recorded information; it does not by itself define
eligibility for a surveillance analysis.

**Common input audit** (*audit des données standardisées en entrée*):
Examination of the site handoff at the point where sites converge on a shared
representation, after local cleaning, mappings, diagnostic selection and
retention of isolates with an antibiogram, and before shared hospital perimeter
selection and deduplication. It assesses the prepared data's structure and
coherence, accepting correct local preparation as an input assumption. It does
not revalidate diagnostic classification or recover records removed upstream.
Hospitalisation activity keeps its own population, including relevant activity
from patients without a culture or antibiogram.

**Site handoff**:
The fixed set of files a site produces to feed v3, in which the site has
already translated its local codes into v3's vocabulary. Its microbiology data
contain diagnostic isolates with an antibiogram, selected by the site adapter.
The shared hospital perimeter is applied later. The boundary between what a
hospital owns and what v3 owns.
_Avoid_: import, extract, input files

**Site adapter**:
Site-specific code and reference data that turns one hospital's raw exports
into a site handoff. It owns cleaning, antibiotic and bacterial mappings,
diagnostic classification and selection, and retention of isolates with an
antibiogram. Lives outside the v3 core, which never reads it. Local preparation
does not authorise additional local hospital perimeter exclusions.
_Avoid_: connector, ETL

**Indicator table**:
The primary deliverable: one row per indicator, period and stratum, each
carrying its numerator and denominator alongside the computed value. Reports
are consumers of this table and hold no calculation of their own.
_Avoid_: results, output, report

**Delivery bundle**:
The versioned package a site transmits: its indicator tables, unmasked, with the
exposure denominators and a record of how they were produced. Its contents and
format are a chapter 09 design, not settled.
_Avoid_: submission, export zip, payload

### The surveillance landscape

**ORCHIDEE**:
Organisation d'un Réseau de Centres Hospitaliers Impliqués Dans la surveillance
Épidémiologique et la réponse aux Émergences: SPF's network of university
hospitals producing surveillance indicators from their data warehouses,
organised in thematic working groups. Antimicrobial resistance is one of them;
this project is an independent proposal for its methodology, not official
ORCHIDEE work.
_Avoid_: ORCHIDEE alone for this project (say v3), or v3 for the network

**SPARES** (Surveillance et Prévention de l'Antibiorésistance en Établissements
de Santé):
The national mission, run by a consortium of CPias and CRAtb (SPARES p. 2), that
surveils antibiotic consumption and bacterial resistance in health
establishments (SPARES p. 8). It has its own method, which among other things
defines a perimeter (SPARES pp. 9-10); the source
documents use the bare word for all three, so use the qualified forms below.
_Avoid_: using "SPARES" unqualified

**SPARES method**:
The published protocol SPARES defines — inclusion criteria (pp. 9-10),
deduplication rule (pp. 10-11), denominators (p. 13), thesauri (pp. 27-30).
A document v3 can read and disagree with in the open.
_Avoid_: the SPARES algorithm, the SPARES rules <!-- citecheck: ok, the Avoid line lists discouraged phrases and claims nothing; the definition above carries its pages -->

**SPARES perimeter**:
The subset of hospital activity the SPARES method admits (SPARES pp. 9-10): complete and weekly
hospitalisation across the listed sectors, excluding séances, venues,
consultations, passages and HAD. One named perimeter among several v3 may
compute, never the only one.
_Avoid_: the perimeter, the scope

**ConsoRes**:
The third-party web platform that today receives hospitals' imports and computes
the SPARES indicators. Its implementation is not reviewable. It is v3's
point of comparison, not its reference.
_Avoid_: the national tool, the reference implementation, the gold standard

**Divergence account**:
A one-time retrospective reconciliation monograph comparing v3 against
ConsoRes on a benchmark surveillance period (Rouen 2024), decomposing the gap
into an additive waterfall of named methodological decisions to demonstrate
validity to SPF. A transition proof, not an annual pipeline routine.
_Avoid_: annual reconciliation, ConsoRes report


**SPF** (Santé Publique France):
The national public-health agency that coordinates ORCHIDEE and consumes the
surveillance indicators. It commissioned this project up to v2; v3 is a
methodology proposed to it. It currently uses ConsoRes output as its reference.
_Avoid_: the agency, the client

**PDS / HDH** (Plateforme des données de santé / Health Data Hub):
The French national health data platform, a partner of the ORCHIDEE consortium.
As the project team understands it, each working group develops and tests its
pipeline locally and with a few partner sites, then HDH takes it over and
industrialises it. No published source states this role yet.
_Avoid_: data lake, platform

**ONERBA**:
The observatory whose methodological recommendations define what a duplicate
(ONERBA recommendations, Chapter III, pp. 25-27). The origin of the deduplication
rule and of the sample-type thesaurus (Chapter II, pp. 21-22, and Annex 4, p. 44).

**EDSH**:
A hospital's own clinical data warehouse, the source v3 reads from and the
reason it can see data national surveillance cannot.
_Avoid_: the warehouse, the datalake

**GLIMS**:
The laboratory information system (LIS / SIL) of the CHU de Rouen bacteriology
laboratory, sold by Clinisys (formerly MIPS). The source of Rouen's raw
bacteriology export. A Rouen fact, not part of the model.

### Resistance measurement

#### English–French terminology

| English term used here | French term | Meaning |
|---|---|---|
| Species | Espèce bactérienne | Bacterial classification, such as *Escherichia coli*. |
| Patient–species pair | Couple patient–espèce | One patient considered together with one bacterial species when counting isolates within a stated population, period and specimen scope. |
| Sample / specimen | Prélèvement / échantillon | Material collected from a patient on a particular sampling occasion. |
| Sample type | Type / nature de prélèvement | The category of sample, such as urine or blood culture. |
| Isolate | Isolat; also called *souche* in source passages | An individual bacterial recovery recorded for a sample, before deciding whether it duplicates another recovery. |
| Strain | Souche au sens de lignée biologique | A bacterial lineage that can persist across samples and patients. |
| Antibiotype panel | Panel d'antibiotiques | The set of antibiotics on which the profile is read. |
| Antibiotype | Antibiotype | The susceptibility results across that panel. |
| Antibiogram | Antibiogramme | The susceptibility examination and, by extension, its results or report carrying the antibiotype. |
| Antibiotic-result record | Ligne de résultat de sensibilité à un antibiotique | One recorded result for one antibiotic attached to an isolate. |
| Compatible isolates | Isolats compatibles pour le dédoublonnage | Two isolates that satisfy the operational comparison rule. |
| Retained isolate | Isolat conservé après dédoublonnage | The isolate selected from a duplicate group to contribute its results to an analysis. |
| Deduplication mapping | Table de correspondance du dédoublonnage | For each analysis, a link from every input isolate to the retained isolate of its duplicate group. |

The French word *souche* needs context. In its biological sense it refers to a
lineage. The SPARES method also calls individual recoveries *souches*, defines
duplicates through patient, species, antibiotype, period and sample type, and
compares resistance phenotypes (SPARES pp. 10-11 and 14-15). Its phrase
« pour une même souche » introduces the counting rule on p. 16. Our operational
reading of that phrase is documented as an inference in
`docs/methods/07-dedoublonnage.md`: compatible isolates may be grouped for an
analysis, without establishing that they belong to one biological lineage.

For example, two samples from the same patient can each yield an *E. coli*
isolate. There are two isolates before deduplication. If they form one duplicate
group under the declared rules, one retained isolate contributes to that
analysis. Their matching antibiotypes alone do not establish a shared lineage.
Incomplete antibiotypes can make grouping ambiguous; the grouping rule remains
necessary alongside the pairwise comparison rule.

**Species**:
A bacterial classification, such as *Escherichia coli*. Several isolates can
belong to the same species, including isolates recovered from the same sample.

**Patient–species pair**:
One patient considered together with one bacterial species when counting isolates
within a stated population, period and specimen scope. Two or more isolates for
that pair means at least two isolates of that species recorded for that patient;
it does not establish infection episodes or membership of a duplicate group.
_Avoid_: repeated pair, episode, duplicate group (when this descriptive pair is meant)

**Sample / specimen**:
Material collected from one patient on a particular sampling occasion and
identified in the laboratory data. One sample can yield several isolates.

**Sample type**:
The category assigned to a sample, such as urine or blood culture. It describes
the sample, while species describes the recovered bacteria.

**Isolate**:
A separately recorded bacterial recovery from one sample of one patient, with
its species identification and associated antibiotic susceptibility results.
It exists before deciding whether it duplicates another recovery. A sample can
contain several separately recorded isolates of the same species. Deduplication
selects retained isolates for an analysis; it does not create the original
isolates or establish their biological lineage.
_Avoid_: souche (in English text), strain, germ

**Isolate identifier (`isolate_id`)**:
The laboratory's identifier distinguishing separately recorded isolates within a
sample. The full isolate key is `(PATID, ELTID, isolate_id)`; the `isolate_id`
value alone can recur in other samples. Historical witness files call this field
`souche_id`, and Rouen's raw GLIMS export calls it `DLVL`. These names are mapped
to `isolate_id` when preparing v3 data. Deduplication preserves the original
isolate key for each retained isolate. Whether an isolate is retained or is a
duplicate is a property of the analysis, not a change to its identity.

**Strain**:
A bacterial lineage, which can persist across several samples and several
patients and can change over time. Not interchangeable with isolate: the same
strain recovered twice gives two isolates. Nothing in the surveillance data can
establish it; deduplication compares isolates instead.
_Avoid_: using "strain" where the counted unit is meant

**Compatible isolates**:
Two isolates of the same patient and species with no major discrepancy on any
molecule tested in both, and the same resistance phenotypes. What the sources
call « même souche » or « même antibiotype » is given this operational reading
in chapter 07, with the source locators and the limits of that inference.
Compatibility is a relation between two isolates, not a class: A compatible with
B and B compatible with C does not make A compatible with C.
_Avoid_: same antibiotype, same souche, identical

**Duplicate group**:
Isolates of one patient and species in the window (and in one sample type, for
an analysis by sample type), every two of which are compatible. It has one
retained isolate. The sources define compatibility, not the groups: where a
bridging isolate allows more than one grouping, a v3 rule picks one.
_Avoid_: operational souche, antibiotype group, clone, episode

**Duplicate**:
An isolate of a duplicate group formed across sample types that is not its
retained isolate. Excluded from analyses across sample types.
_Avoid_: doublon (in English text), repeat isolate

**Sample-type duplicate**:
An isolate of a duplicate group formed within one sample type that is not its
retained isolate. Excluded from analyses by sample type. It is not necessarily
a duplicate, nor the reverse: the two groupings can retain different isolates.
_Avoid_: doublon prélèvement (in English text)

**Retained isolate**:
The one isolate kept for a duplicate group. It alone carries the group's
results into the indicators. It keeps its original isolate identifier; the
qualifier "retained" describes its role in that analysis.
_Avoid_: representative, survivor

**Retention rule**:
How the retained isolate of a duplicate group is chosen: the isolate with more
molecules tested; if the counts are equal, the oldest.
_Avoid_: survivor rule, tie-break

**Bridging isolate**:
An isolate compatible with two isolates that are not compatible with each other,
because it has no result for the molecule that separates them. It is why
compatibility alone does not decide the duplicate groups.
_Avoid_: non-transitivity, chaining

**Orphaned result**:
A molecule result carried only by isolates that are not retained, so that no
retained isolate reports that molecule for the patient. The cost of the
retention rule.

**Antibiotype**:
An isolate's pattern of S / SFP / R results across a declared set of molecules.
Not a property of the isolate alone: it exists only relative to a panel.
_Avoid_: resistance profile, susceptibility pattern

**Antibiogram**:
The antibiotic susceptibility examination and, by extension, its results or
report. The antibiotype is the susceptibility pattern read from those results
on a declared panel.

An individual antibiotic `NA` means not tested unless other source information
explicitly establishes otherwise. Source-comment interpretation belongs to the
site adapter. An individual `NA` does not remove an isolate already supplied
with an antibiogram; it is distinct from an absent enzymatic phenotype signal.

**Antibiotic-result record**:
One record carrying a susceptibility result for one antibiotic attached to an
isolate. Several such records describe one isolate's antibiogram. Repeated
records for the same isolate and antibiotic require an explicit resolution rule;
counting records does not count isolates.

**Antibiotype panel**:
The set of molecules an antibiotype is read on. Widening it changes which
isolates are duplicates, and therefore changes indicators on molecules the panel
never touched.
_Avoid_: the antibiotic list, the columns

**Deduplication**:
Keeping the retained isolate of each duplicate group and discarding the others:
groups formed within one sample type for an analysis by sample type (discarding
sample-type duplicates), across all sample types for the global analysis
(discarding duplicates). Always within one patient and one species: isolates of
different species never affect each other. Always relative to a panel and a
window; never absolute.
_Avoid_: dédoublonnage (in English text), de-duping, filtering

**Major discrepancy**:
A difference of S↔R or SFP↔R on at least one molecule tested in both isolates,
which makes them not compatible. A S↔SFP difference is minor and does not. A
blank result is never a difference.

**Deduplication mapping**:
A local audit table saved alongside the retained isolates for an analysis. Each
input isolate appears once and points to the original key of its group's
retained isolate; retained isolates point to themselves. The analysis reference
identifies the exact input version, population selection and deduplication
rules. This preserves group membership without requiring a separate group
identifier. See `docs/methods/07-dedoublonnage.md`, Deduplication audit output.

**Diagnostic sample**:
A sample taken to identify the cause of a suspected infection (the sources'
« prélèvement à visée diagnostique »). The only samples resistance indicators
include. Each site classifies its samples and applies diagnostic selection
before the site handoff; the common audit accepts that local decision.
_Avoid_: clinical sample, prélèvement

**Screening sample**:
A sample taken to detect colonisation or carriage rather than to diagnose an
infection (the sources' « prélèvement à visée écologique »: recherche de
colonisation, portage, dépistage). The site adapter excludes it before supplying
the microbiology handoff. The common audit does not receive screening rows to
reclassify them or calculate their excluded count.
_Avoid_: surveillance sample, prélèvement écologique (in English text)

**SFP** (sensible à forte posologie):
The clinical category between susceptible and resistant. It replaced the former
intermediate category, which surveillance grouped with resistant, from the 2020
version of the bacteriology reference; resistance rates before and after the
change are not comparable. The surveillance rules place it on the susceptible
side: a S/SFP difference is minor, a SFP/R difference is major, and a reported
result of SFP counts as S.

**ZIT** (zone d'incertitude technique):
A CA-SFM measurement caveat meaning the antibiogram could not be read reliably.
A statement about the test, not about the organism. Neither the SPF requirements (searched in full, pp. 1-21) nor the SPARES
methodology (searched in full, pp. 1-31) mentions it; only the CA-SFM reference and hospital
exports use it. Treating it as SFP is a v3 decision that no external
document prescribes.
_Avoid_: treating ZIT and SFP as the same concept without recording the choice

**Resistance phenotype (BLSE, Carbapenemase)**:
An enzymatic resistance mechanism (BLSE, carbapenemase) in Enterobacterales and
*Pseudomonas*, found by a confirmation test that a sentinel result triggers. The
sources record it only when found and read no record as absent. That reading
holds only when the sentinel molecules were tested, and an export shows what was
reported, not what was tested, so it cannot always tell the two apart. An
attribute of the isolate, not a molecule of the antibiotype panel.
_Avoid_: treating phenotypes as molecules during deduplication

### Exposure and perimeter

**Exposure**:
The denominator of an incidence density: how much opportunity there was for the
thing being counted to occur. Measured from the site's hospitalisation
intervals, never from an administrative declaration. Carried on its own table
rather than computed inside an indicator, so that one number exists and every
consumer can name the version it divided by.
_Avoid_: activity, volume, JH

**Denominator profile**:
The rule that converts occupied time into exposure. v3's canonical profile
measures occupancy hours and expresses them in days; midnight presence counts
the calendar boundaries a stay crosses, and is derived from the same intervals
for comparability with the hospitalisation days SPARES divides by, which it takes
from the SAE (SPARES p. 13). Two figures computed under
different profiles cannot be added: the sum has no unit.
_Avoid_: counting method, convention

**Population selection**:
Every step that decides which isolates are analysed. Diagnostic selection and
retention of isolates with an antibiogram occur locally before the common input
audit. The shared pipeline subsequently applies the hospital perimeter, period
and analysis-specific specimen restrictions before deduplication. Selection
never follows deduplication, because it is not monotone — removing an isolate from
its input can add one to its result. A selection applied afterwards is a
different operation wearing the same name.
_Avoid_: filtering, subsetting, scoping

**Perimeter**:
The single resolved set of units whose activity enters the surveillance. One
object, handed to both the numerator and the denominator. Two independent
selections would each be defensible and their ratio would be a rate of nothing.
_Avoid_: scope, inclusion criteria, filter

**Hospitalisation unit attribution**:
Deciding which clinical unit an isolate belongs to: the unit whose stay interval
contains the sample time. A sample outside every stay interval is not
attributed to a ward; an emergency isolate is the case that matters. It is never
attributed from the ordering laboratory's unit code when the intervals
contradict it.
_Avoid_: unit mapping (when sample attribution is meant), sample location

**Emergency isolate**:
An isolate from a diagnostic sample drawn in the emergency department, usually
before any admission, so it cannot have been acquired in a ward. SPARES
attributes a sample to the unit at the time of sampling and excludes emergency
activity (SPARES pp. 10, 15), so on a literal reading it drops these isolates; v3 keeps them. Whether they are linked to
the stay that follows or kept as their own stratum is open (chapter 05).
_Avoid_: pre-admission linkage (names one of the open options)

**Structure snapshot**:
The annual version of the establishment's structural referential (UFs, TAs,
DEs, domains) valid for a given campaign year. Constant across the surveillance
period so that unit eligibility remains stable throughout deduplication.
_Avoid_: dynamic structure, live hierarchy

**SAE** (Statistique annuelle des établissements de santé):
The annual administrative declaration that SPARES names as the source of
hospitalisation days (SPARES p. 13). v3 does not use it: the figure comes from the
hospital administration, cannot be reproduced from the site's own data, and is
not restricted to the activity SPARES admits. v3 measures exposure from
the site's stay data instead.
_Avoid_: official figure, reference denominator

### How decisions are recorded

**Decision register**:
The list of every choice v3 makes that its source documents do not make
for it. One line per choice: the question, the answer, the alternative, and the
witness.
_Avoid_: methods doc, spec notes

**Witness**:
A number from real data that proves a decision matters. You compute the
indicator twice, once each way, and record both results. If the two numbers are
the same, the decision is inert and the line is deleted.
_Avoid_: example, test case

**Tripwire**:
An automatic check on a statement that is true today, which fails on the day it
stops being true. It is what you use instead of a parameter when you believe two
readings agree and want to be told when they diverge. Cheaper than running both
readings forever, and unlike trusting the assumption, it tells you.
_Avoid_: assertion, guard, sanity check

**Unproven**:
The state of a register line whose witness has not been found yet, usually
because the effect only appears on data another hospital holds. A legal state.
The count of unproven lines is published and is expected to fall over time.
_Avoid_: TODO, open question

**Post-flight audit**:
Automated quality verification applied to the generated indicator table prior to
delivery or diffusion. Distinguishes fatal invariant violations that halt
delivery from microbiological or epidemiological tripwires that record warnings.
A chapter 09 design, not settled.
_Avoid_: sanity check, output filter

