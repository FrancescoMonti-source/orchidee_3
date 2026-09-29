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

**Site handoff**:
The fixed set of files a site produces to feed v3, in which the site has
already translated its local codes into v3's vocabulary. The boundary
between what a hospital owns and what v3 owns.
_Avoid_: import, extract, input files

**Site adapter**:
Site-specific code and reference data that turns one hospital's raw exports
into a site handoff. Lives outside the v3 core, which never reads it.
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
The national mission, run by a consortium of CPias and CRAtb, that surveils
antibiotic consumption and bacterial resistance in health establishments. It
has its own method, which among other things defines a perimeter; the source
documents use the bare word for all three, so use the qualified forms below.
_Avoid_: using "SPARES" unqualified

**SPARES method**:
The published protocol SPARES defines — inclusion criteria, deduplication rule,
denominators, thesauri. A document v3 can read and disagree with in the
open.
_Avoid_: the SPARES algorithm, the SPARES rules

**SPARES perimeter**:
The subset of hospital activity the SPARES method admits: complete and weekly
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

**Isolate**:
The bacteria of one species recovered from one sample of one patient and tested
against antibiotics. The unit that indicators count, and the unit deduplication
removes. The source documents call it *souche*; their « même souche » is a
relation between two isolates (see Compatible isolates), not the same strain.
_Avoid_: souche (in English text), strain, germ

**Strain**:
A bacterial lineage, which can persist across several samples and several
patients and can change over time. Not interchangeable with isolate: the same
strain recovered twice gives two isolates. Nothing in the surveillance data can
establish it; deduplication compares isolates instead.
_Avoid_: using "strain" where the counted unit is meant

**Compatible isolates**:
Two isolates of the same patient and species with no major discrepancy on any
molecule tested in both, and the same resistance phenotypes. What the sources
mean by « même souche » or « même antibiotype » between two isolates. A relation
between two isolates, not a class: A compatible with B and B compatible with C
does not make A compatible with C.
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
results into the indicators.
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

**Diagnostic sample**:
A sample taken to identify the cause of a suspected infection (the sources'
« prélèvement à visée diagnostique »). The only samples resistance indicators
include. Each site decides which of its sample types are diagnostic; v3
does not decide it for them.
_Avoid_: clinical sample, prélèvement

**Screening sample**:
A sample taken to detect colonisation or carriage rather than to diagnose an
infection (the sources' « prélèvement à visée écologique »: recherche de
colonisation, portage, dépistage). Resistance indicators exclude it.
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
A statement about the test, not about the organism. Neither the SPF requirements
nor the SPARES methodology mentions it; only the CA-SFM reference and hospital
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
for comparability with what SPARES publishes. Two figures computed under
different profiles cannot be added: the sum has no unit.
_Avoid_: counting method, convention

**Population selection**:
Every step that decides which isolates are analysed: the perimeter, the
diagnostic samples, the period. It runs after ingestion and before deduplication,
never after it, because deduplication is not monotone — removing an isolate from
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
activity, so it drops these isolates; v3 keeps them. Whether they are linked to
the stay that follows or kept as their own stratum is open (chapter 05).
_Avoid_: pre-admission linkage (names one of the open options)

**Structure snapshot**:
The annual version of the establishment's structural referential (UFs, TAs,
DEs, domains) valid for a given campaign year. Constant across the surveillance
period so that unit eligibility remains stable throughout deduplication.
_Avoid_: dynamic structure, live hierarchy

**SAE** (Statistique annuelle des établissements de santé):
The annual administrative declaration that SPARES names as the source of
hospitalisation days. v3 does not use it: the figure comes from the
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

