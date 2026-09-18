# Worked example: what excluding screening samples is worth

Witness for the decision *"only diagnostic samples enter the resistance
indicators"*.

**Slice**: *Escherichia coli*, all sample types (global scope), sampling year
2024. Annual window, grouping by patient, SPARES panel. Built from
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
their long-term section: *"le nombre de dépistages faits dépend de la situation
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

**The flag is a proxy for intent, not a property of the sample.** ONERBA defines
the boundary by purpose - *à visée diagnostique* against *à visée écologique*. A
rectal swab is nearly always screening; an ECBU can be either. No sample type
determines the answer on its own, so the classification rests on local codes and
local practice.

## The portability consequence

The site handoff carries `ratb_diagnostic_scope` as a boolean, so each site
classifies its own samples. That is correct - only the site can read its own
analysis codes - but it means **the highest-impact decision in the resistance
pipeline is delegated to the site, and nothing in the contract makes two sites
agree.**

Two hospitals with identical epidemiology and different screening-coding
practice will publish céfotaxime resistance rates that differ by several points.
The site contract must therefore state the boundary in clinical terms, and the
site's classification must be published as an auditable count, not accepted
silently.
