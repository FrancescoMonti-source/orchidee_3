# Manuale d'uso — Esploratore `NATUREPVT` v2 (`demo.html`)

Questo manuale spiega come leggere e usare `outputs/sample-type-prototype/v2/demo.html`, l'esploratore dell'audit v2 sulle 8 462 etichette `NATUREPVT` del CHU di Rouen. L'interfaccia è in francese; qui trovi i nomi esatti dei comandi così come compaiono a schermo.

Il file è autonomo: si apre con un doppio clic in qualsiasi browser, senza server né connessione. Non contiene `PATID`, `EVTID` né `ELTID`: ogni etichetta è identificata dal suo `label_id` (`LBL_0001`…`LBL_8462`).

Per rigenerarlo: `Rscript --vanilla docs/worked-examples/sample-type-prototype/v2_build_deliverables.R`. Se si apre il template (`demo_v2.template.html`) invece del file generato, compare "Aucune donnée injectée".

---

## 1. Come è organizzata la pagina (dall'alto in basso)

1. **Intestazione, Relecteur e Import/Export**: titolo, riepilogo numerico, campo `Relecteur` (opzionale, salvato in locale) e pulsanti **Exporter la sélection (.csv)** (scarica le righe filtrate correnti con la bozza di regola SIL), **Importer avis…** (ricarica un CSV di revisione già esportato) ed **Exporter mes avis** (appare appena salvi almeno una decisione o nota).
2. **Schede di lavoro (6 tab)**: ciascuna mostra il conteggio delle righe (che si aggiorna in formato `filtrate / totali` quando attivi un filtro).
3. **Barra di sintesi e copertura**: 5 riquadri riepilogativi sulla selezione corrente (*Libellés affichés*, *Prélèvements couverts*, *Écarts vs v1 (Cat./Rôle)*, *Règle SIL requise*, *Avis CHU Rouen requis*) con evidenziazione gialla quando restano campioni `*_MY` da escludere o segnalazioni senza cambio di categoria.
4. **Parcours rapides**: barra di avvio rapido con 5 percorsi cliccabili su casi concreti.
5. **Barra di ricerca e filtri**: ricerca testuale + categoria + azione richiesta + `Effacer filtres` (pulisce i filtri rimanendo nella scheda corrente) + `Réinitialiser` (torna alla vista iniziale). Gli altri filtri e il selettore righe per pagina (`25 / 50 / 100`) stanno sotto `+ Filtres avancés`.
6. **Area di lavoro affiancata**: a **sinistra** la tabella a 4 colonne; a **destra** (fissa durante lo scorrimento su desktop, o ancorata in basso su schermi stretti) la **Fiche détaillée** dell'etichetta o del tema selezionato.
7. **À propos de l'audit v2, glossaire SIL & contrôles d'intégrité** (pannello richiudibile in fondo): obiettivo (`ADR-0003`), glossario delle sigle GLIMS e metriche del run.

## 2. Le sei schede di lavoro

| Scheda a schermo | Cosa mostra | Righe senza filtri |
|---|---|---|
| `Tous les libellés` | Tutte le etichette | 8 462 |
| `Corrigés ou signalés vs v1` | Etichette con categoria/ruolo cambiati oppure segnalate | 1 942 (= `v1_vs_v2_diff.csv`) |
| `Règles SIL à appliquer` | Etichette con regola composita, azione oltre al testo o campioni `*_MY` da purgare | 620 (554 non risolte dal solo testo + 66 `text_sufficient` con campioni `*_MY`) |
| `Avis CHU Rouen & SIL` | Tutte le 620 etichette con azione SIL/micologia o domanda Rouen, con pulsante rapido in cima **Filtrer : avis Rouen stricts (164)** | 620 (= `chu_rouen_questions.csv`) |
| `Thèmes transversaux` | I 104 temi trasversali emersi dal cross-check, con esempi `LBL_xxxx` cliccabili | 104 temi |
| `Vue par catégorie (17)` | Riepilogo per le 17 categorie ONERBA / SPARES a sinistra e anteprima temi trasversali a destra | 17 categorie |

Nella scheda **Vue par catégorie (17)**, un clic sul nome di una categoria apre subito `Tous les libellés` filtrata su quella categoria (con pulsante **← Retour aux catégories** per tornare indietro). Il badge `SPARES` indica le due categorie oggi bersaglio (`hemoculture`, `urines`).

## 3. Ricerca e filtri

In primo piano trovi sempre:

- **Ricerca libera**: cerca una sottostringa (senza distinzione tra maiuscole e minuscole) in `label_id`, testo `NATUREPVT`, famiglia v1, categoria v2/v1, azione, `SEJUF`, `SEJUM`, `TRI`, `TYPEANA`, germi e motivazione v2. Gli accenti contano sul testo grezzo (`ESCARRE` trova "Escarre", mentre `hemoculture` trova la categoria `hemoculture`).
- **Catégorie cible v2**: le 17 categorie con etichetta leggibile ONERBA, più *Cibles SPARES actuelles (hémocultures + urines)*.
- **Action requise** (`resolution_lever`):

| Etichetta nel menu | Codice sottostante | Significato pratico |
|---|---|---|
| *Texte suffisant* | `text_sufficient` | Il testo `NATUREPVT` basta per la categoria (nelle schede SIL/Rouen restano le 66 etichette con campioni `*_MY` da escludere). |
| *Filtrer par analyse (TYPEANA)* | `filter_typeana` | Serve il codice d'analisi: `BGSTRB`, `BGSTA_R` con/senza `BGCULTAE`, `_R`, `BGUCYTO`, `BGFA*`, `BGNUML`. |
| *Filtrer par unité / discipline* | `filter_sejuf_tri` | Serve l'unità (`SEJUF`/`SEJUM`) o la disciplina (`TRI`), ad es. `SONDE` in urologia vs cardiologia. |
| *Exclure la mycologie (\*_MY)* | `exclude_mycology` | I campioni con solo antifungigramma `*_MY` vanno esclusi dal flusso batterico. |
| *Demander l'avis du CHU de Rouen* | `ask_chu_rouen` | Né il testo né i segnali SIL bastano: serve il parere locale di Rouen. |
| *Toutes les règles composites SIL* | flag `comp` | Tutte le etichette con `needs_composite_lis_rule = true` (458 righe). |

Con **`+ Filtres avancés`** compaiono:

- **Statut par rapport à la v1**: *Confirmé* (`confirmed`), *Corrigé* (`reclassified`), *Signalé* (`flagged`).
- **Rôle clinique**: *Diagnostique*, *Dépistage*, *Dépend du contexte*, *Inclassable*.
- **Niveau de confiance**: *Élevée*, *Moyenne*, *Revue humaine requise*.
- **Flux mycologie (`*_MY`)**: *Contient des prélèvements `*_MY` seuls (> 0)*, *100 % mycologie `*_MY` (0 ATB bactérien)* (137 etichette), *100 % bactériologie (0 `*_MY`)*.
- **Casella anomalie di testo**: *Uniquement anomalies de saisie (doubles espaces / retours à la ligne)* (equivalente anche alla ricerca `__WS_NL__`).
- **Lignes par page**: `25`, `50` (predefinito) o `100`.

## 4. Tabella, sincronizzazione e scheda dettaglio

La tabella mostra **4 colonne** (*Libellé brut*, *Catégorie (v1 → v2)* — con eventuale cambio di ruolo evidenziato subito sotto —, *Action & Statut*, *Prélèvements* con dettaglio `bact.` e `*_MY`).

- Cliccando `← Précédent` / `Suivant →` nella scheda a destra, la tabella a sinistra scorre automaticamente sulla riga attiva e cambia pagina se necessario; viceversa, cambiando pagina con `Page suiv. →`, la scheda si aggiorna sulla prima riga della nuova pagina.
- **Règle SIL suggérée**: sulle etichette con regola SIL appare un riquadro con pseudo-regola copiabile tramite **Copier la règle**.
- **Volumétrie & marqueurs du SIL**: i contatori a `0` restano attenuati visivamente mentre i segnali attivi (> 0) sono evidenziati con descrizione al passaggio del mouse.
- **Barra di revisione fissa, coda e scorciatoie da tastiera**: in cima alla scheda a destra trovi sempre visibili `✓ Valider v2`, `✎ Autre cat.` e `? Incertain` (con scelta categoria e nota che si aprono solo quando servono), l'opzione `Avancer auto` e i tasti rapidi (`↓`/`↑` o `j`/`k` per cambiare riga, `A`/`V` per validare, `C` per cambiare categoria, `I` per incertain, `Suppr` per cancellare, `Échap` per uscire dal campo di testo). Sopra la tabella a sinistra, la barra di avanzamento e i filtri (`Tous`, `À revoir`, `Validés`, `Reclassés`, `Incertains`) permettono di lavorare la coda fino a zero e di esportare/reimportare il CSV delle decisioni (con controllo automatico se il testo `NATUREPVT` o la proposta `v2_cat` cambiano in una rigenerazione).

## 5. I 5 percorsi guidati (`Parcours rapides`)

1. **Erreurs corrigées (v1 → v2)**: collisioni nascoste dalle famiglie v1 (`CAE`, `BOURSE PRE PATELLAIRE`, `PRE AURICULAIRE`/`STERNAL`, `AMYGDALE`, `ESCARRE` → `pus_superficiel` per ONERBA 2001, Chapitre II p. 22).
2. **Fuite antifongique (`*_MY`)**: le 137 etichette 100 % micologiche e tutti i campioni con S/I/R solo da pannelli `*_MY` / `PM_MY*` / `PM_ATF*`.
3. **Règles du SIL**: casi risolti dai codici d'analisi (`TYPEANA`) o da `SEJUF`/`TRI`.
4. **Cibles SPARES**: controllo sulle due categorie SPARES (`hemoculture`, `urines`; SPARES pp. 14–15).
5. **Questions CHU Rouen**: le 164 etichette `ask_chu_rouen`, tamponi su siti profondi e anomalie di spaziatura.

## 6. Limiti da ricordare

- Le decisioni v2 sono proposte generate dagli agenti (Fase 1 su tutte le 8 462 etichette, Fase 2 su 1 948 etichette prioritarie) in attesa di validazione da parte del CHU di Rouen.
- Le motivazioni di dettaglio (*Pourquoi cette décision ?*) e i testi dei 104 temi trasversali nei dati JSON del prototipo restano in inglese; l'interfaccia segnala `(EN)` accanto a tali sezioni.
- I temi trasversali sintetizzano le osservazioni dei batch prioritari e rimandano alle fonti ONERBA 2001 (Chapitre II pp. 21–22, Annexe 4 p. 44) e SPARES (pp. 14–15, Annexe 4 p. 27).
- I conteggi riguardano solo i campioni con almeno un risultato `S`/`SFP`/`I`/`R`/`ZIT` in `data/bact22_24`, non tutta l'attività del laboratorio.
- Il demo è uno strumento di revisione del prototipo; il contratto portabile (`ADR-0003`) resta la sede delle regole definitive.
