# Worked example: what excluding screening samples is worth

Witness for the decision *"only diagnostic samples enter the resistance
indicators"*.

**Historical witness:** the figures below have not been remeasured for issue
#22. The retained-screening input describes the older witness, not the current
common site handoff. Diagnostic selection now occurs locally before that
handoff and its common audit; the historical comparison does not require the
shared pipeline to receive records removed upstream.

**Slice**: *Escherichia coli*, all sample types (global scope), sampling year
2024. Annual window, grouping by patient, 19-column Annexe 3 *E. coli* list. Built from
`site_inputs/microbiology_observations.rds`, which retains screening rows that
the published bundle drops.

| | Isolate keys | After deduplication |
|---|---|---|
| diagnostic only | 6519 | **5489** |
| including screening | 6883 | **5798** (+5.6 %) |

| Indicator | Diagnostic only | Including screening | Shift |
|---|---|---|---|
| céfotaxime | **16.96 %R** (n=2588) | **25.19 %R** (n=2898) | **+8.23 pp** |
| ertapénème | **0.35 %R** (n=5465) | **1.52 %R** (n=5771) | **x4.3** |
| ofloxacine | 15.93 %R (n=4991) | 18.35 %R (n=5298) | +2.42 pp |
| amoxicilline-ac. clavulanique | 38.90 %R (n=5340) | 40.57 %R (n=5612) | +1.67 pp |
| cotrimoxazole | 29.09 %R (n=5387) | 30.70 %R (n=5684) | +1.61 pp |

This is the largest effect of any decision measured so far - larger than the
window, the panel and the conflict rule combined.

## Why it is so large

Screening is not a random sample of patients. A carriage swab is taken
**because** a patient is suspected of carrying a resistant organism: a transfer
from abroad, a known contact, a unit under outbreak management. The screened
population is enriched in resistance by design.

So including screening does not add noise. It adds a biased sample, and the bias
runs in one direction. The effect is largest exactly where the screening
programme targets: C3G resistance and carbapenem resistance, the two markers
that drive BMR and BHRe policy. Céfotaxime moves 8 points and ertapénème
quadruples.

The SPF requirements make the same point about screening-based indicators in
their long-term section (SPF p. 10): *"le nombre de dépistages faits dépend de la situation
et de la politique de l'hôpital"*.

## Is it just a filter before deduplication?

Mechanically, yes. But three things have to be stated, or they get decided by
accident.

**The order is part of the rule.** Filter, then deduplicate - never the reverse.
If deduplication runs first, a screening isolate can be selected as the
representative for a patient, and the later exclusion then removes that patient
entirely, taking a legitimate diagnostic isolate with it.

**The exclusion applies to the sample, not to the result row.** This is v2's
decision (*"Le dépistage est exclu au niveau du document, pas de la ligne de
résultat"*), and it carries an ordering hazard that v2's own register records:
*"Un marqueur de dépistage porté par une ligne écartée disparaît avec elle"*.
If rows are dropped for any other reason before the screening marker propagates
across the whole sample, a screening sample can re-enter as diagnostic.

**The flag is a proxy for intent, not a property of the sample.** ONERBA (pp. 20-21)
defines the boundary by purpose - *à visée diagnostique* against *à visée écologique*. A
rectal swab is nearly always screening; an ECBU can be either. No sample type
determines the answer on its own, so the classification rests on local codes and
local practice.

## The portability consequence

The site adapter interprets its own codes, applies diagnostic scope and retains
isolates with an antibiogram before supplying the standardized site handoff
(ADR-0003; issue #22). The common audit accepts correct local preparation and
diagnostic selection as input assumptions. It does not revalidate that
classification or calculate screening exclusions from rows it does not receive.
The old `ratb_diagnostic_scope` flag in this witness does not impose an
unselected-screening handoff on sites.

Shared hospital perimeter selection remains downstream of the common audit,
and analysis-specific specimen selection still precedes deduplication. This
historical witness motivates the ordering rule; it does not establish new
measurements or a common raw-data testing interface.
