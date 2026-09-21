# Validation microbiologique : Règles de tri Dépistage vs Diagnostique (ORCHIDEE / SPARES)

Salut,

Pour le calcul des indicateurs de résistance SPARES dans ORCHIDEE, on doit filtrer strictement les prélèvements de **dépistage de portage** pour ne conserver que les prélèvements **diagnostiques** (infections).

En regardant les données brutes GLIMS (`bact22_24`), on a calé une règle de tri automatique. Peux-tu nous valider les 4 points suivants ?

---

### 1. Bilans BMR / BHRe systématiques (Dépistage)
On classe d'office en **DÉPISTAGE** (à exclure des indicateurs) tout prélèvement contenant l'un de ces 7 codes d'analyses GLIMS :

- `BGBLSE_R` (Recherche BLSE)
- `BGCARBA_R` (Recherche Carba / EPC)
- `BGERV_R` (Recherche ERV / VRE)
- `BGSAMR_R` (Recherche SAMR)
- `BGABRI_R` (Recherche ABRI - *A. baumannii* résistant imipénème)
- `BGABMR_R` (Recherche autres BMR)
- `BGPYOBMR_R` (Recherche Pyo Carba)

*Tu confirmes que ces 7 bilans correspondent à 100 % à du dépistage de colonisation / portage ?*

---

### 2. Le cas `BGSTA_R` (Recherche Staph doré)
Dans les données, `BGSTA_R` est utilisé dans deux contextes très différents :
- Prescrit **seul** (écouvillons nasaux ou cutanés de portage) &rarr; on le classe en **DÉPISTAGE**.
- Prescrit **avec une culture aérobie ordinaire `BGCULTAE`** sur des plaies, escarres ou vésicules (où l'on isole du *S. aureus*, mais aussi parfois du pyo ou du proteus) &rarr; on le conserve en **DIAGNOSTIQUE**.

*Est-ce que cette règle de séparation (seul = portage / avec BGCULTAE = diagnostic de plaie) te paraît cliniquement exacte ?*

---

### 3. Le dépistage prénatal du Streptocoque B (`BGSTRB`)
On a un volume important de `BGSTRB` (écouvillons vaginaux prénataux).
- En pratique pour la surveillance des infections : considères-tu qu'il s'agit d'un **dépistage de portage asymptomatique** (à exclure de SPARES) ?
- Ou doit-on le maintenir comme du **diagnostique** gynécologique ?

---

### 4. Tri par site anatomique (`NATUREPVT`)
Pour les prélèvements qui n'ont pas un des bilans BMR ci-dessus :
- On exclut comme **dépistage** les écouvillons superficiels de gîtes de portage : `Nez`, `Narine`, `Aisselle / Creux axillaire`, `Aine / Pli inguinal`.
- On **maintient impérativement en diagnostique** tout prélèvement purulent ou chirurgical, même s'il mentionne la zone péri-anale : *Abcès marge anale*, *Abcès pararectal*, *Fistule ano-périnéale*, ainsi que tous les *Pus*, *Liquides* et *Biopsies*.

*Tu valides cette distinction ?*
