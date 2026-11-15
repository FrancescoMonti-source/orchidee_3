# Manuale d'uso — Esploratore `NATUREPVT` v2 (`demo.html`)

Questo manuale spiega come leggere e usare `outputs/sample-type-prototype/v2/demo.html`, l'esploratore interattivo dell'audit v2 sulle 8 462 etichette `NATUREPVT` del CHU di Rouen. L'interfaccia del demo è in francese; questo manuale riporta i nomi dei controlli così come appaiono a schermo.

Il file è autonomo: si apre con un doppio clic in qualsiasi browser, senza server e senza connessione. Non contiene `PATID`, `EVTID` né `ELTID`: ogni riga è un'etichetta, identificata dal suo `label_id` (`LBL_0001`…`LBL_8462`).

Per rigenerarlo: `Rscript --vanilla docs/worked-examples/sample-type-prototype/v2_build_deliverables.R`. Se si apre il template (`demo_v2.template.html`) invece del file generato, compare "Aucune donnée injectée".

---

## 1. Cosa c'è dentro, in una frase

Per ogni etichetta `NATUREPVT` presente su almeno un campione con antibiogramma, il demo mostra la classificazione v1 (ereditata dalle famiglie regex), la decisione v2 verificata una per una, il motivo del cambio, e i segnali GLIMS (`TYPEANA`, `SEJUF`, `SEJUM`, `TRI`, specie) che hanno aiutato a decidere.

## 2. Mappa della pagina (dall'alto in basso)

| Zona | Nome a schermo | A cosa serve |
|---|---|---|
| A | Titolo e sottotitolo | Totali globali del run: etichette, campioni, isolati, riclassificate, segnalate, ricontrollate in Fase 2. |
| B | Riquadri KPI + barra di copertura | Totali **della selezione corrente** (cambiano con filtri e vista). |
| C | Percorsi guidati (scenari) | 5 storie cliccabili che impostano vista e filtri per te. |
| D | Exploration 1-à-1 des 8 462 libellés | Pulsanti vista, filtri, ricerca, tabella paginata. |
| E | Inspecteur détaillé du libellé | Scheda completa dell'etichetta selezionata, con `Précédent` / `Suivant`. |
| F | Métadonnées du run v2 (richiudibile, in fondo) | Controlli di integrità e data/ora del run. |

## 3. Le cinque viste

Le viste sono **pre-filtri**: ognuna parte da un sottoinsieme diverso delle 8 462 etichette. I filtri della zona D si applicano **in aggiunta** al pre-filtro della vista.

| Vista | Cosa include | Righe senza filtri |
|---|---|---|
| 1. Audit 1-à-1 | Tutte le etichette | 8 462 |
| 2. Différences v1 → v2 | Etichette con categoria o ruolo cambiati, oppure con stato diverso da `confirmed` | 1 942 (= `v1_vs_v2_diff.csv`) |
| 3. Règles composites LIS | Etichette con `needs_composite_lis_rule = true` oppure con leva diversa da `text_sufficient` | 554 (di cui 458 con `needs_composite_lis_rule = true`) |
| 4. Questions CHU Rouen | Etichette con leva diversa da `text_sufficient`; nell'ispettore compare la sezione richiudibile con i 36 temi trasversali | 554 (= `chu_rouen_questions.csv`) |
| 5. Matrice ONERBA / SPARES | Riepilogo per le 17 categorie `naturepvt_norm`; i filtri sono nascosti, i KPI mostrano il totale globale e l'ispettore espande i 36 temi trasversali | 17 righe |

Nella vista 5, un clic sul nome di una categoria apre la vista 1 filtrata su quella categoria (tutti gli altri filtri vengono azzerati). Il badge `SPARES` segna le due categorie oggi bersaglio (`hemoculture`, `urines`). Sotto la matrice, l'ispettore mostra i temi clinici trasversali emersi dal cross-check.

## 4. I filtri

| Filtro | Valori | Nota |
|---|---|---|
| Catégorie cible v2 | 17 categorie, oppure "Cibles SPARES actuelles" | Filtra sulla categoria **v2**, non su quella v1. |
| Statut vs v1 | `confirmed`, `reclassified`, `flagged` | Vedi §6. |
| Levier de résolution | 5 leve, oppure "Tous avec `needs_composite_lis_rule = true`" | L'ultima voce filtra sul flag booleano, non sulla leva. |
| Rôle | `diagnostic`, `screening_site`, `context_dependent`, `unclassifiable` | Ruolo v2. |
| Confiance | `high`, `medium`, `ambiguous_needs_human_review` | Confidenza v2. |
| Flux Mycologie | vedi §7 | Basato sui conteggi di campioni, non sul testo. |
| Recherche | testo libero | Vedi §5. |

- **Effacer les filtres** azzera i filtri ma **mantiene la vista** corrente.
- **Réinitialiser** riporta tutto allo stato iniziale: vista 1, nessun filtro, ordinamento per numero di campioni decrescente.

## 5. La ricerca

- Cerca una **sottostringa**, senza distinzione tra maiuscole e minuscole, in: `label_id`, testo `NATUREPVT`, famiglia v1, categoria v2 e v1, leva, `SEJUF`, `SEJUM`, `TRI`, top `TYPEANA`, top specie e motivazione v2.
- **Non** cerca nel ruolo né nella confidenza: per quelli usa i filtri.
- Gli accenti contano: `ESCARRE` trova "Escarre", ma `hemoculture` non trova "Hémoculture" nel testo grezzo. Trova però tutte le etichette con categoria `hemoculture`.
- Il placeholder suggerisce `*_MY`, ma l'asterisco viene cercato alla lettera. Per la micologia usa il filtro **Flux Mycologie**, oppure cerca un codice preciso come `AP_MY` o `VO_MY`.
- **Parola chiave speciale `__WS_NL__`**: mostra solo le etichette con doppio spazio o ritorno a capo nel testo grezzo. Sono segnalate nella tabella dai badge `2x espace` e `\n`.

Esempi utili: `LBL_0011`, `CAE`, `BOURSE`, `ESCARRE`, `AMYGDAL`, `BGSTRB`, `BGSTA_R`, `Candida`, un codice `SEJUF`.

## 6. Come leggere la tabella

| Colonna | Significato |
|---|---|
| ID | `label_id` e, sotto, `#rango` per numero di campioni (`#1` = etichetta più frequente). |
| Libellé NATUREPVT brut | Testo esatto come in GLIMS, spazi compresi. Clic → apre l'etichetta nell'ispettore. |
| `v1 → v2` | Se la categoria è cambiata: v1 barrata in rosso sopra, v2 sotto. Altrimenti solo v2. L'ordinamento su questa intestazione ordina per categoria **v1**. |
| Statut | `confirmed` (verde), `reclassified`, `flagged`. |
| Levier LIS | Leva di risoluzione v2. |
| Rôle / Confiance | Ruolo diagnostico/screening e confidenza v2. |
| Éch. | Campioni (antibiogramma) con questa etichetta; sotto, quanti hanno almeno un antibiogramma batterico. |
| `*_MY` | Campioni il cui unico S/I/R è micologico (badge viola se > 0). |
| Signaux GLIMS | `SEJUF` più frequenti e specie più frequenti. |

Un clic sull'intestazione di una colonna ordina in modo decrescente; un secondo clic ordina in modo crescente. A parità di valore, vince l'etichetta con più campioni. La tabella mostra 100 righe per pagina.

**I tre stati rispetto alla v1:**

- `confirmed`: stessa categoria e stesso ruolo della v1, testo sufficiente, nessuna regola composita.
- `reclassified`: categoria **o** ruolo diversi dalla v1.
- `flagged`: stessa categoria e stesso ruolo della v1, ma serve una regola composita LIS, un'esclusione micologica o una domanda al CHU.

**Le cinque leve di risoluzione:**

| Leva | Significato pratico |
|---|---|
| `text_sufficient` | Il testo `NATUREPVT` basta da solo. |
| `filter_typeana` | Serve il codice d'analisi: `BGSTRB`, `BGSTA_R` con o senza `BGCULTAE`, `_R` sistematici, `BGUCYTO`, `BGFA*`, `BGNUML`. |
| `filter_sejuf_tri` | Serve l'unità (`SEJUF`/`SEJUM`) o la disciplina (`TRI`), ad es. `SONDE` in urologia vs cardiologia. |
| `exclude_mycology` | Il problema è il flusso antifungino: i campioni con solo `*_MY` vanno esclusi. |
| `ask_chu_rouen` | Né il testo né i segnali LIS bastano: serve il parere dei microbiologi di Rouen. |

## 7. Il filtro micologia

| Voce | Condizione |
|---|---|
| Tous | Nessun filtro. |
| Avec échantillons `*_MY` uniquement (> 0) | Almeno un campione dell'etichetta ha S/I/R **solo** micologico. |
| 100 % mycologie | Tutti i campioni sono solo micologici, nessun antibiogramma batterico (137 etichette). |
| 100 % ATB bactérien | Nessun campione solo micologico. |

Un campione è considerato "solo micologico" quando tutte le sue righe S/I/R vengono da pannelli antifungini (`*_MY`, `PM_MY*`, `PM_ATF*`) o da un'identificazione fungina (ad es. *Candida*, *Aspergillus*).

## 8. L'ispettore

Si apre sotto la tabella sull'etichetta selezionata. `Précédent` / `Suivant` scorrono le righe **nell'ordine e con i filtri correnti**, anche oltre la pagina visibile.

| Riquadro | Contenuto |
|---|---|
| Baseline v1 (famiglia) | Categoria, ruolo, confidenza v1 e `Source v1` (`family_rule` da regola di famiglia oppure `crosscheck_label_override` da override v1). |
| Décision v2 vérifiée | Categoria, ruolo, confidenza e stato v2. |
| Règle composite LIS | Leva, flag `needs_composite`, e i conteggi di campioni con: `Blood` = flaconi `BGFA*`, `Urine` = `BGUCYTO`/`BGASPU`, `Fluid` = `BGNUML`/`BGEDL`. |
| Volumes & Dépistage | Campioni (batterici / solo `*_MY`), isolati, e la scomposizione screening (vedi sotto). |

Sotto i riquadri si trovano la **motivazione v2**, i top `SEJUF` / `SEJUM` / `TRI`, i top `TYPEANA` (fino a 6, con conteggi) e le top specie (fino a 4).

**Scomposizione screening.** Ogni campione cade in **una sola** classe, con questa precedenza:

1. `_R sys`: presenza di un codice di screening sistematico (`BGBLSE_R`, `BGCARBA_R`, `BGERV_R`, `BGSAMR_R`, `BGABRI_R`, `BGABMR_R`, `BGPYOBMR_R`);
2. `BGSTA_R seul`: `BGSTA_R` senza coltura `BGCULTAE`;
3. `+BGCULTAE`: `BGSTA_R` insieme a `BGCULTAE`;
4. `BGSTRB`;
5. resto (diagnostico standard, non mostrato).

Attenzione: `Fluid` (`BGNUML`/`BGEDL`) compare su tutte le punture sterili (LCR, ascite, pleura, articolazione), non solo sul liquor.

## 9. I percorsi guidati

Un clic su uno scenario applica il passo 1; i pulsanti numerati applicano gli altri passi. Toccare un filtro o una vista a mano fa uscire dal percorso.

| Scenario | Cosa mostra |
|---|---|
| 1. Reclassifications v1 → v2 | Errori ereditati dalle famiglie v1: `CAE` (orecchio, non cieco), `BOURSE PRE PATELLAIRE` (ginocchio, non scroto), `PRE AURICULAIRE`/`STERNAL`, `ESCARRE` → `pus_superficiel` (ONERBA 2001, Cap. II p. 22), `AMYGDALE`. |
| 2. Fuite antifongique `*_MY` | Le 137 etichette solo micologiche, poi tutte quelle con quota micologica, poi la leva `exclude_mycology`. |
| 3. Règles composites | Etichette risolvibili con `TYPEANA` o con `SEJUF`/`TRI`. |
| 4. Cibles SPARES | Verifica delle due categorie bersaglio (`hemoculture`, `urines`; SPARES pp. 14–15) e matrice delle 17 categorie. |
| 5. Questions CHU Rouen | Domande `ask_chu_rouen`, tamponi su siti sterili o profondi, etichette con spazi anomali. |

## 10. KPI e copertura: cosa misurano

- **Libellés filtrés**: righe nella selezione corrente.
- **Échantillons**: somma dei campioni delle etichette selezionate, in % sul totale (51 351). Ogni campione ha una sola etichetta, quindi le somme non contano due volte lo stesso campione.
- **Reclassifiés / Signalés / Questions CHU Rouen**: conteggi nella vista corrente; il totale globale è riportato tra parentesi.
- **Barra di copertura**: quota di campioni e isolati (su 61 423) coperta dalla selezione. Serve a capire quanto pesa un problema: 300 etichette rare possono valere meno di una sola etichetta frequente.

## 11. Ricette rapide

| Domanda | Come fare |
|---|---|
| Quali correzioni pesano di più? | Vista 2, ordina per `Éch.` (ordinamento predefinito). |
| Cosa entra oggi in `hemoculture` per errore micologico? | Vista 1, Catégorie = `hemoculture`, Flux Mycologie = "Avec échantillons `*_MY`". |
| Cosa devo chiedere a Rouen? | Vista 4, Levier = `ask_chu_rouen`; espandi *Thèmes transversaux pour CHU Rouen* in fondo all'ispettore (o apri la Vista 5). |
| Una certa etichetta come è stata decisa? | Cerca il suo `LBL_xxxx` o una parola del testo, poi clicca sulla riga. |
| Etichette incerte ma non segnalate? | Vista 1, Statut = `confirmed`, Confiance = `medium`. |
| Quanto pesa ogni categoria? | Vista 5. |

## 12. Limiti da conoscere

- Le decisioni v2 sono proposte di agenti (Fase 1 su tutte le etichette, Fase 2 su 1 948 etichette prioritarie). Non sono validate dal CHU di Rouen.
- I temi trasversali (vista 4 e 5) sintetizzano le osservazioni dei batch prioritari e rimandano alle fonti ONERBA 2001 (Chapitre II pp. 21–22, Annexe 4 p. 44) e SPARES (pp. 14–15, Annexe 4 p. 27).
- I conteggi riguardano solo i campioni con almeno un risultato S/SFP/I/R/ZIT in `data/bact22_24`, non tutta l'attività del laboratorio.
- Il demo è uno strumento di revisione del prototipo. Il contratto portabile (`ADR-0003`) resta la sede delle regole definitive.
