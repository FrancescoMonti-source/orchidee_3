# ORCHIDEE

Semi-automated surveillance of antimicrobial resistance computed from a
hospital's own data warehouse, producing aggregated indicators for Santé
Publique France.

## Language

**Site**:
A hospital that runs ORCHIDEE against its own data. Rouen is the site that
builds and first operates the product; it holds no privileged position in the
model.
_Avoid_: établissement (when the running hospital is meant), client, partner

**Site handoff**:
The fixed set of files a site produces to feed ORCHIDEE, in which the site has
already translated its local codes into ORCHIDEE's vocabulary. The boundary
between what a hospital owns and what ORCHIDEE owns.
_Avoid_: import, extract, input files

**Site adapter**:
Site-specific code and reference data that turns one hospital's raw exports
into a site handoff. Lives outside the ORCHIDEE core, which never reads it.
_Avoid_: connector, ETL

**Indicator table**:
The primary deliverable: one row per indicator, period and stratum, each
carrying its numerator and denominator alongside the computed value. Reports
are consumers of this table and hold no calculation of their own.
_Avoid_: results, output, report

### The surveillance landscape

**SPARES**:
The French national mission for antimicrobial resistance surveillance in health
establishments. Used alone the word is ambiguous in the source documents, which
apply it to three different things; prefer the qualified forms below.
_Avoid_: using "SPARES" unqualified

**SPARES method**:
The published protocol SPARES defines — inclusion criteria, deduplication rule,
denominators, thesauri. A document ORCHIDEE can read and disagree with in the
open.
_Avoid_: the SPARES algorithm, the SPARES rules

**SPARES perimeter**:
The subset of hospital activity the SPARES method admits: complete and weekly
hospitalisation across the listed sectors, excluding séances, venues,
consultations, passages and HAD. One named perimeter among several ORCHIDEE may
compute, never the only one.
_Avoid_: the perimeter, the scope

**ConsoRes**:
The third-party web platform that today receives hospitals' imports and computes
the SPARES indicators. Its implementation is not reviewable. It is ORCHIDEE's
point of comparison, not its reference.
_Avoid_: the national tool, the reference implementation, the gold standard

**SPF** (Santé Publique France):
The agency that commissioned ORCHIDEE and consumes its indicators, and which
currently treats ConsoRes output as authoritative.
_Avoid_: the agency, the client

**ONERBA**:
The observatory whose methodological recommendations define what a duplicate is.
The origin of the deduplication rule and of the sample-type thesaurus.

**EDSH**:
A hospital's own clinical data warehouse, the source ORCHIDEE reads from and the
reason it can see data national surveillance cannot.
_Avoid_: the warehouse, the datalake

### Resistance measurement

**Isolate**:
One bacterial strain recovered from one patient in one sample and tested against
antibiotics. The unit that indicators count, and the unit deduplication removes.
The French *souche* translates to this term.
_Avoid_: souche (in English text), germ

**Strain**:
A genetically distinct bacterial lineage, which can persist across several
samples and several patients. Not interchangeable with isolate: the same strain
recovered twice gives two isolates, and deduplication exists to collapse them.
_Avoid_: using "strain" where the counted unit is meant

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
Discarding an isolate because the same patient already contributed one of the
same species, same sample type and same antibiotype within the window. Always
relative to a panel and a window; never absolute.
_Avoid_: dédoublonnage (in English text), de-duping, filtering

**Major discrepancy**:
A difference of S↔R or SFP↔R on at least one molecule, which makes two
antibiotypes distinct. A S↔SFP difference is minor and does not.

**Diagnostic sample**:
A sample taken to identify the cause of a suspected infection. Distinguished
from a screening sample, taken to detect colonisation or carriage, which
resistance indicators exclude.
_Avoid_: clinical sample, prélèvement

**SFP** (sensible à forte posologie):
The clinical category between susceptible and resistant, EUCAST's "I". The
surveillance rules place it on the susceptible side: a S/SFP difference is
minor, a SFP/R difference is major, and a reported result of SFP counts as S.

**ZIT** (zone d'incertitude technique):
A CA-SFM measurement caveat meaning the antibiogram could not be read reliably.
A statement about the test, not about the organism. Neither the SPF requirements
nor the SPARES methodology mentions it; only the CA-SFM reference and hospital
exports use it. Treating it as SFP is an ORCHIDEE decision that no external
document prescribes.
_Avoid_: treating ZIT and SFP as the same concept without recording the choice

### Exposure and perimeter

**Exposure**:
The denominator of an incidence density: how much opportunity there was for the
thing being counted to occur. Measured from the site's hospitalisation
intervals, never from an administrative declaration. Carried on its own table
rather than computed inside an indicator, so that one number exists and every
consumer can name the version it divided by.
_Avoid_: activity, volume, JH

**Denominator profile**:
The rule that converts occupied time into exposure. ORCHIDEE's canonical profile
measures occupancy hours and expresses them in days; `midnight_presence` counts
the calendar boundaries a stay crosses, and is derived from the same intervals
for comparability with what SPARES publishes. Two figures computed under
different profiles cannot be added: the sum has no unit.
_Avoid_: counting method, convention

**Population selection**:
Every step that decides which isolates are analysed: the perimeter, the
diagnostic scope, the period. It runs after ingestion and before deduplication,
never after it, because deduplication is not monotone — removing an isolate from
its input can add one to its result. A selection applied afterwards is a
different operation wearing the same name.
_Avoid_: filtering, subsetting, scoping

**Perimeter**:
The single resolved set of units whose activity enters the surveillance. One
object, handed to both the numerator and the denominator. Two independent
selections would each be defensible and their ratio would be a rate of nothing.
_Avoid_: scope, inclusion criteria, filter

**SAE** (Statistique annuelle des établissements de santé):
The annual administrative declaration that SPARES names as the source of
hospitalisation days. ORCHIDEE does not use it: at Rouen it is declared without
an activity filter, so it answers a different question from the one the
indicator asks. It is retained as a recorded figure in the divergence account,
not as a reference.
_Avoid_: official figure, reference denominator

### How decisions are recorded

**Decision register**:
The list of every choice ORCHIDEE makes that its source documents do not make
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
