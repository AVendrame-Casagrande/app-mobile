namespace CG.MobileAPI.Models
{
    /// <summary>
    /// Changelog dell'app mobile per versione (dati statici, ex query/checkVersion.php).
    /// Per pubblicare una nuova versione: aggiungere la voce in <see cref="Versioni"/> e aggiornare
    /// <see cref="VersioneCorrente"/> e <see cref="ChiaveVersioneCorrente"/>.
    /// </summary>
    public static class GeneraleChangelog
    {
        /// <summary>Ultima versione pubblicata (campo <c>code</c> della risposta).</summary>
        public const string VersioneCorrente = "2.0.16";

        /// <summary>Chiave in <see cref="Versioni"/> del changelog della versione corrente.</summary>
        public const string ChiaveVersioneCorrente = "v2016";

        /// <summary>DEPRECATO: serviva ai vecchi RuggedPad con Android 5.0 (campo <c>updateTablet</c>).</summary>
        public const bool UpdateTablet = false;

        /// <summary>Se true l'utente è obbligato ad aggiornare, altrimenti l'app si chiude (campo <c>mandatoryUpdate</c>).</summary>
        public const bool MandatoryUpdate = false;

        /// <summary>Note di rilascio per versione (chiave = nome della proprietà del PHP, es. <c>v2016</c>).</summary>
        public static readonly IReadOnlyDictionary<string, string[]> Versioni = new Dictionary<string, string[]>
        {
            // stringa singola nel PHP
            ["v0028"] = new[]
            {
                "Test Implementazione changeLog",
            },
            ["v0029"] = new[]
            {
                "1: Le ricerche dell'Articolo e Movimento non si perdono passando da una pagina all'altra",
                "2: Quando passi da una pagina all'altra (ES: da Magazzini dell'Articolo passi a Movimento): tieni premuto la tab corrente (ES: Movimento) per passare rapidamente alla Tab precedente e vice-versa",
                "3: Aggiunto Elenco pre-Impostato di ODL su Esecuzione Movimento",
                "4: Aggiunta di Filtri su Movimento ( Visualizzazione ) per Magazzini e Causali",
                "5: Aggiunta del Responsabile del Movimento ( Visualizzazione )",
                "6: Aggiunta Change Log per ogni nuova Versione",
            },
            ["v0030"] = new[]
            {
                "1: Scelto un ODL su Movimento, il Magazzino è aggiunto automaticamente. Scelto un Magazzino, ho gli ODL solo per quel MAG",
                "2: Visualizzazione icona quando puoi passare da una TAB all'altra tenendola premuta",
                "3: Divisione Lista - Input per ODL",
                "4: Termine Visualizzazione Foto + LINK se cliccate",
                "5: Impostazione Account ID - necessita Permessi Utente Avanzato",
                "6: Fix Minori",
            },
            ["v0031"] = new[]
            {
                "1: Miglioramento scelta automatica per Vano Preferenziale e Visualizzazione con *",
                "2: Una volta effettuato un Movimento: premendo il pulsante 'Visualizza' dal Popup, potrai subito vedere l'elenco dei movimenti Aggiornati",
                "3: Fix pulsante SALVA: si disattiva solo premendolo manualmente, non più in automatico se cambi sezione (PS: il template viene generato solo dopo un movimento eseguito)",
                "4: Popup di conferma se un Utente con più privilegi clicca su 'Utente Standard'",
            },
            ["v0032"] = new[]
            {
                "1: Aggiunta Sezione Disegni PDF ( La sezione Disegni si carica a parte e bisogna aspettare un po')",
                "2: ATTENZIONE: Aprire un PDF online su Android richiede una APP apposita. Consiglio: usare Google Drive. I terminali al 90% non potranno aprirli perchè non hanno un PDF Reader - devo installarlo",
            },
            ["v0033"] = new[]
            {
                "1: Ora il Disegno visualizzato è sempre l'ultimo",
                "2: ATTENZIONE: Ricordo che serve sempre un PDF Reader online",
            },
            ["v0034"] = new[]
            {
                "1: Aggiunta la possibilità di stampare l'Etichetta a Movimento Eseguito con successo ( pulsante stampa On / Off ) dalle stampanti Zebra Qln320. Le stampanti verranno distribuite a breve",
                "2: Tutti gli account dei dispositivi sono stati RESETTATI. Ognuno deve effettuare il Login con il proprio codice Utente (es: CTM...)",
                "3: Query Disegni Velocizzate (da 5 - 6+ secondi a 20 millisecondi) e miglioramenti delle performance anche per le Query Foto",
            },
            ["v0035"] = new[]
            {
                "1: Associazione Stampante Etichette ai Terminali: Attenzione: Bisogna essere loggati con l'utente associato alla stampante su cui si vuole stampare (valutare un eventuale 'stampa da..' se si vuole stampare in un'altra stampante?",
            },
            ["v0036"] = new[]
            {
                "1: Disabilitare il Pulsante 'Stampa' nella sezione Movimento disabilita effettivamente la Stampa",
                "2: Premendo i pulsanti T o N del cambio tastiera, il campo verrà messo ( o rimesso ) in Focus",
                "3: Miglioramento della funzione WebViewCheck Android, leggero aumento delle prestazioni durante l'avvio dell'app",
            },
            ["v0037"] = new[]
            {
                "1: onDeviceReady Fix ( Fix per la 'Verifica Versione..' di alcuni Dispositivi es: Redmi6A )",
                "2: MOVIMENTO: Ora è presente un pulsante LINK per aprire direttamente i Dettagli dell'Articolo",
                "3: MOVIMENTO: Aggiunti gli Impegni sulla Lista Magazzini Origine",
            },
            ["v0038"] = new[]
            {
                "1: Se stai movimentando un Articolo su un Magazzino MISK, ora è RICHIESTO il Vano",
                "2: Ora è possibile stampare le Etichette come quelle stampante con il Movimento, su Cerca Articolo -> Mancanti. E' possibile Stampare solo quelli 'Verdi'",
                "3: Ora è Possibile Stampare anche l' Etichetta della SCHEDA dell' Articolo. Premi il Pulsante Stampa su Scheda",
                "4: Miglioramento Performance Stampante. Dopo la Prima Etichetta stampata, il dispositivo ricorda il suo MAC Address e stampa molto più velocemente",
                "5: AGGIUNTA ( A GRANDE RICHIESTA ) di SNAKE. Riuscirai ad arrivare ad almeno 100 Punti?",
            },
            ["v0039"] = new[]
            {
                "1: Aggiunta di 'Dettagli Ordine di Acquisto' premendo su un Ordine di Acquisto",
            },
            ["v0040"] = new[]
            {
                "1: Snake è scappato via.. :(",
                "2: Aggiunta sezione 'Cambio ODL' ( In Sviluppo )",
            },
            ["v0041"] = new[]
            {
                "1: Fix Click da Magazzini (da Cerca) a Movimento",
                "2: Aggiunta Data alle Etichette",
                "3: Possibilità di Stampare più Etichette dopo una Stampa ( non richiede riconfigurazione stampanti )",
            },
            ["v0042"] = new[]
            {
                "1: Tenendo Premuto il Pulsante Cerca ( 🔎 ) il Codice e la Pagina dell' Articolo vengono Resettati",
            },
            ["v0043"] = new[]
            {
                "1: Terminata sezione CAMBIO ODL. Al momento la API non è Attiva ( Non Modifica il Database ) ma la Stampa di Etichette SI ( Per fare delle prove )",
                "2: Rientri: sul CAMBIO ODL c'è la possibilità di fare i Rientri. Le Etichette non vengono stampate durante un Rientro ( E la API è Disabilitata anche qui )",
            },
            ["v0044"] = new[]
            {
                "1: Aggiunti alcuni Magazzini aggiuntivi su Movimento ( Sarà possibile personalizzarli in Futuro )",
                "2: Quando effettui un Movimento, viene registrato l'Operatore che l'ha eseguito ( e non più DIAP60 )",
                "3A: Aggiunta sezione Stampa Etichetta Verniciature (completa al 100%). Stampa una Etichetta ( Parzialmente Personalizzabile ) partendo dal Magazzino",
                "3B: PS: Questa Etichetta non viene stampata dalle Zebra Portatili, ma da una stampante Fissa che verrà installata a Breve",
                "4: Aggiunta Possiblità di Stampare per Articoli o per Quantità su 'Cambio Attribuzione ODL'. La sezione richiede ancora delle modifiche prima di essere operativa",
            },
            ["v0045"] = new[]
            {
                "1: CAMBIO ODL: La sezione è COMPLETATA ( è Possibile cambiare l'Ordine di Lavoro o fare dei Rientri tramite l'APP )",
                "2: Miglioramento Sezione Stampa Etichette Verniciatura. Installazione Stampante in Settimana",
                "3: Rimossa sezione Chat erroneamente inclusa precedentemente",
            },
            ["v0046"] = new[]
            {
                "1: Nella sezione 'Cambio ODL' ed 'Etichetta Verniciatura' : vicino agli ODL, vengono visualizzati il Padre e la Descrizione",
                "2: Le lettere Accentate nelle etichette con Nota Libera vengono rimpiazzate con lettere non accentate ( Risolve problemi di compatibilità con i Font della Stampante )",
                "3: Aggiunta Sezione 'Vano' tra i dettagli della Lista Movimenti ( Sezione Cerca )",
                "4: Nella Sezione 'Movimento' è ora possibile Filtrare / Personalizzare i Magazzini visualizzati. La scelta viene Memorizzata nel Dispositivo",
            },
            ["v0047"] = new[]
            {
                "1: Reimpaginazione APP",
                "2: Sezione Crea Lista --> Esporta in Excel. Carica un file Excel su 10.8.198.8/mobile/excel visualizzabile da PC",
            },
            ["v0048"] = new[]
            {
                "1: Crea Lista: Download Excel su Dispositivo e Popup che chiede la Quantità di Articoli",
                "2: Predisposizione Accesso Fotocamera per Android 5.1 ( Funzione non ancora attiva )",
            },
            ["v0049"] = new[]
            {
                "1: Piccoli Miglioramenti Crea Lista",
                "2: Inizio Sezioni: Mancanti da Prelevare e Prelievi",
            },
            ["v0050"] = new[]
            {
                "1: Ottimizzazioni Fotocamera",
                "2: Servizio in Background per ricevere Notifiche",
            },
            ["v0051"] = new[]
            {
                "1: Lista: Genera un txt Spaziato --> Codice Qta",
            },
            ["v0052"] = new[]
            {
                "1: Vani Visualizzati correttamente alla fine dei Movimenti e nella Etichetta",
            },
            ["v0053"] = new[]
            {
                "1: Sezione Mancanti Completata. Possibilità di visualizzare i Mancanti ed effettuare il Movimento del mancante, poi stampare le Etichette ( Testare Funzionamento )",
                "2: Sezione Mancanti da Mag Automatici: Possibilità di confermare se è un Mancante o no, poi inviare una lista in txt ( importabile in excel ) direttamente a Visintin",
                "3: FOTO ! Finalmente dalla sezione Cerca -> Foto è ora possibile CARICARE delle nuove foto ( premendo il tasto fotocamera a dx ). Possibilità di eliminarle nella prossima build",
                "4: Modificati alcuni permessi di Visualizzazione per gli Utenti Standard",
            },
            ["v0054"] = new[]
            {
                "1: Aggiornamento indirizzo IP per Stampante etichette Produzione",
            },
            ["v0055"] = new[]
            {
                "1: Aggiunta Sezione Prelievi ( Come Mancanti ma non filtra lo statoPick a Y )",
                "2: Possibilità di Eliminare una Foto",
                "3: Pulsante Indietro / Home sulla sezione Foto della Scheda Articolo",
                "4: Fix Visualizzazione Foto decentrata su alcuni Dispositivi",
                "5: Schermata principale differente in base al tipo di Utente ( Se ci fossero problemi: ri-effettuare il Login )",
                "6: Cambiamento nomi di alcune Sezioni",
            },
            ["v0056"] = new[]
            {
                "1: Aggiunta selezione ODL nella Sezione Prelievi",
            },
            ["v0057"] = new[]
            {
                "1: Versione Casagrande USA ( Si attiva effettuando il Login come utente USA ). Traduzione Italiano-Inglese. Possibilità di Movimento BLOCCATA",
                "2: Premere 'T' o 'N' per cambiare input non fa chiudere la Tastiera",
                "3: Fix minori per alcuni dispositivi Android",
            },
            ["v0058"] = new[]
            {
                "1: Fix tasto Cerca per alcune sezioni",
            },
            ["v0059"] = new[]
            {
                "1: Aggiunta del passaggio del parametro Società ('CSPRO', 'CSUSA' ecc..) per le API di movimentazione",
            },
            ["v0060"] = new[]
            {
                "1: Quando viene eseguito il prelievo di un mancante, poi non viene più visualizzato nella lista ( fino a nuovo aggiornamento )",
                "2: NUOVA FUNZIONE: Cronologia. Ora viene salvata la cronologia delle ricerche (max 8). Tenendone schiacciata una si può Eliminare la singola ricerca ( utile anche per memorizzare solo determinati magazzini )",
            },
            ["v0061"] = new[]
            {
                "1: Risolto il problema del bug visuale 'checkout_box' ( icone non sempre visualizzate correttamente )",
                "2: Aggiunta pulsante Info per la Descrizione Fasi ( su Stampa Etichetta ). Descrizione Fase ora anche su popup dei Mancanti e Prelievi",
                "3: Risolto un bug che rendeva impossibile aprire alcune sezioni dopo aver premuto 'Visualizza' dopo un Movimento",
            },
            ["v0062"] = new[]
            {
                "1: Risolto il problema del caricamento 'Infinito' dopo aver eseguito il movimento di 1 Mancante",
                "2: Ora in qualsiasi Movimento si possono inviare numeri decimali",
            },
            ["v0063"] = new[]
            {
                "1: Aggiunta Distinte ( Esplosione / Implosione ) su Cerca Articolo",
                "2: Ora le Etichette stampate dalle stampanti Zebra ( portatili ) stampano anche il Codice dell'operatore",
            },
            ["v0064"] = new[]
            {
                "1: Migliorato il 'Popup' dei Mancanti e Prelievi ( Aggiunta di: Bolla, Fornitore e Disegni - quando presenti )",
                "2: La Info della Distinta singola viene aperta automaticamente. Ordinamento Crescente per esplosioni e Decrescente per Implosioni",
                "3: Pulizia codice della Pagina Principale ( Migliora prestazioni ed eventuali errori di visualizzazione swipando )",
            },
            ["v0065"] = new[]
            {
                "1: Inserimento della Chat Interna",
                "2: Inizia una nuova chat digitando il codice dell'operatore",
                "3: Controlla se il tuo messaggio è stato letto (spunta V verde)",
                "3: Ricevi una notifica ad ogni nuovo messaggio (se impostato su Android: anche quando la app è aperta)",
                "4: Usa il pulsante 'Rispondi' dalle notifiche (solo per Android 6+) per rispondere velocemente ad un messaggio",
                "5: DISCLAIMER: La Chat è in fase di BETA e potrebbe presentare alcuni bug. Verrà migliorata man mano",
                "6: Risolto un bug che bloccava l'applicazione in caso di credenziali errate",
            },
            ["v0066"] = new[]
            {
                "1: Risolto un problema che indicava i messaggi sempre come letti al riavvio",
                "2: Risolti alcuni problemi di formattazione",
                "3: Risolto un problema che faceva scomparire le nuove chat appena create",
                "4: Risolti altri problemi minori con la chat",
            },
            ["v0067"] = new[]
            {
                "1: Miglioramenti per la Chat ( Risolto il problema spam messaggi )",
                "2: Aggiunto un LOG per DEBUG al Server sui Movimenti dei Mancanti (per risolvere il problema del blocco mancanti dopo il primo invio)",
            },
            ["v0068"] = new[]
            {
                "1: FIX per il Caricamento INFINITO dopo aver eseguito il movimento di 1 mancante ( il fix è attivo dal primo aggiornamento dei mancanti dalla sua installazione )",
            },
            ["v0069"] = new[]
            {
                "1: MOVIMENTI: Ora funzionano i Movimenti con la cifra decimale ( es: 10.2 )",
                "2: CHAT: Notifiche: ora le notifiche arrivano sempre. Vengono evidenziati i nuovi messaggi nella Pagina Principale, nella Pagina Chat e nei Badge dell'APP",
                "3: CHAT: Possibilità di invio di E-Mail all'utente, se entrambi gli utenti possiedono un indirizzo E-Mail aziendale ( configurato nel dispositivo ad es: su Gmail )",
                "4: CHAT: L'inizio di una nuova chat può essere effettuata solo tramite Nome ( Potrebbe generare bug se il nome utente non è univoco )",
            },
            ["v0070"] = new[]
            {
                "1: CAMBIO ODL: Risolto un problema durante il CAMBIO ODL tra magazzini diversi",
            },
            ["v0071"] = new[]
            {
                "1: FOTO ARM funzionante. Caricamento da Camera e ricerca con filtri",
            },
            ["v0072"] = new[]
            {
                "1: FEEDBACK: Nuovo pulsante per Inviare un Feedback Rapido sull'applicazione.",
                "2: CHAT: Aggiunta la chat anche per gli utenti standard e produzione",
                "3: FOTO ARM: Miglioramento sezione ed ordinamento per data più recente",
                "4: Ristrutturazione grafica di alcune sezioni",
            },
            // uguale a v0072 - Build fallimentare -> si passa alla 0074
            ["v0073"] = new[]
            {
                "1: FEEDBACK: Nuovo pulsante per Inviare un Feedback Rapido sull'applicazione.",
                "2: CHAT: Aggiunta la chat anche per gli utenti standard e produzione",
                "3: FOTO ARM: Miglioramento sezione ed ordinamento per data più recente",
                "4: Ristrutturazione grafica di alcune sezioni",
            },
            ["v0074"] = new[]
            {
                "1: Aggiunta del Movimento Singolo anche per gli Utenti Produzione",
                "2: Pagina per assegnare un Impegno ODL completata (sezione Odl) per gli Utenti Produzione",
                "3: In futuro: > invio email in automatico > lista impegni nella pagina Impegni ODL > Possibilità di aggiungere un articolo anche in un odl vuoto",
                "4: Miglioramento CHAT. Ora non dovrebbe più avere comportamenti anomali, tipo messaggi doppi ( testatela ). Aggiunta funzione 'Elimina messaggio' tenendolo premuto ( utile anche nel caso ci fossero ancora problemi )",
            },
            ["v0075"] = new[]
            {
                "1: IMPEGNO ODL: Ristrutturazione sezione con nuove Query. Aggiunta l'operazione DEL oltre che ADD",
                "2: Fix errori ed ottimizzazione del codice ( Movimenti per Utente Avanzato, constructor() assente su Foto Arm ecc.. )",
                "3: Fix Proporzioni per tablet 10/16 , TOP menu al 100% per tablet, rimozione scrollbar dalla versione Desktop",
                "4: Fix selezione Chat per utenti multipli: Popup per la selezione di 1 Utente univoco",
                "5: Aggiunta del campo descrizione 'Colore' sui Mancanti",
            },
            ["v0076"] = new[]
            {
                "1: IMPEGNO ODL: Fix per la visualizzazione di Errore anche in caso di Successo",
                "2: IMPEGNO ODL: Aggiunto un pulsante Info per visualizzare tutti gli di Articoli dell'ODL",
                "3: IMPEGNO ODL: Ora su DEL c'è un popup pre-impostato per facilitare la Selezione dell'articolo",
                "4: IMPEGNO ODL: Ora invia automaticamente una e-Mail al responsabile ODL che avvisa dell' aggiunta / cancellazione di un Articolo",
                "5: CERCA ( Stampa Etichetta Articolo ): ora è possibile aggiungere una Nota opzionale",
                "6: CERCA ( Stampa Etichetta Articolo ): fix per la stampa di Articoli senza Mag.Preferenziale ( Fixa la stampa di Targhette )",
                "7: MEMORY LEAK: Fix per occupazione memoria eccessiva delle Ultime Ricerche. Necessitava anche un Reset delle stesse :(",
            },
            ["v0077"] = new[]
            {
                "1: IMPEGNO ODL: ora invia correttamente le e-Mail al responsabile odl ( non invia e-Mail a se stessi )",
                "2: ACCESSIBILITA: ora la dimensione dei Font dell'applicazione non varia più a seconda del dispositivo. Fanno eccezione i Dialog Android",
                "3: RISTAMPA ETICHETTE: Fix per un possibile problema durante la ristampa delle etichette nei Mancanti e Prelievi",
                "4: LOG: Eliminato il fastidioso Popup: 'Log inviato' ( anche perchè non vengono inviati solo errori ) e aggiunta di nuovi LOG",
            },
            ["v0078"] = new[]
            {
                "1: KANBAN: Aggiunta Sezione Scaffale ( vecchia grafica da aggiornare. Solo in visualizzazione per ora )",
                "2: ETICHETTE: Possibilità di Ristampare se la stampa Fallisce",
            },
            ["v0079"] = new[]
            {
                "0: KANBAN: Miglioramento sezione Scaffali e possibilità di aggiungere / rimuovere Articoli dagli Scaffali",
                "1: IMPEGNO ODL: Nella E-Mail inviata ora vengono anche riportati: Codice Padre, Descrizione Padre e Descrizione dell'Articolo aggiunto",
                "2: PROFILO: Selezione tra Homepage Standard ed una personalizzata ( Homepage Personalizzata non ancora implementata )",
                "3: Aggiunta delle MISSIONI ( inattive ). Ora la homepage contiene fino a 16 slots di icone",
            },
            ["v0080"] = new[]
            {
                "1: ATTIVITA: Nuova Sezione per visualizzare ed assegnare le Attività",
            },
            ["v0081"] = new[]
            {
                "1: ATTIVITA: Creare o Completare una Attività riporta il testo di quella Attività nel messaggio. Aggiunta di 1 Commento per quando si completa",
                "2: ATTIVITA: Filtri migliorati",
                "3: ATTIVITA: Elenco Utenti migliorato ed aggiunta dei CTM",
                "4: CHAT: Fix per Invalid Date per orari inferiori alle 10:00:00",
            },
            ["v0082"] = new[]
            {
                "1: ATTIVITA: Aggiunta della sezione DEST. SPEC. su Attività con possibilità di visualizzare le Bolle e segnarle come completate",
                "2: Le Attività su DEST. SPEC. sono ordinate per nome Fornitore e filtrabili per Destinatario",
            },
            ["v0083"] = new[]
            {
                "1: ATTIVITA: Miglioramento query di DEST. SPEC.",
            },
            ["v0084"] = new[]
            {
                "1: MOVIMENTI: Ora la sezione si chiama Magazzino ed è stata ampliata per contenere 12 icone ( Per utenti Magazzino / Avanzati )",
                "1: GIACENZE INVENTARIO: Nuova sezione dentro Magazzino. Ordinamento personalizzabile per Articolo o Desc. Filtro per Vano ( prossimamente )",
            },
            ["v0085"] = new[]
            {
                "1: Aggiunta di nuovi LOGS",
                "2: GIACENZE INVENTARIO: Aggiunto un Filtro per Vani ( valutare prestazioni dei terminali quando si cerca  magazzini capienti come MISK001 senza filtro vani )",
            },
            ["v0086"] = new[]
            {
                "1: GIACENZE INVENTARIO: Aggiunta dei Prezzi e Link Articolo su Popup",
            },
            ["v0087"] = new[]
            {
                "1: SITUAZIONE ODL: Nuova sezione di visualizzazione per gli Utenti Produzione ( Si entra con ordine di lavoro o padre )",
                "2: Aggiunta di ulteriori LOGS e fix minori in varie sezioni",
            },
            ["v0088"] = new[]
            {
                "1: CHAT: Ora è più facile mandare un messaggio --> C'è una LISTA UTENTI per iniziare una nuova CHAT",
                "2: CHAT: Possibilità di Nascondere sia i messaggi inviati che quelli ricevuti tenendo premuto un mess ( Non li elimina per l'altro utente, li nasconde e basta )",
                "3: CHAT: Possibilità di Nascondere un'intera conversazione con un utente, tenendo premuta la chat ( come Whatsapp )",
                "4: CHAT: Risolto un bug che rendeva la Chat inaccessibile dopo aver Eliminato / Nascosto l'ultimo messaggio della Chat",
                "5: Situazione ODL: Popup per Nonni ODL multipli",
            },
            ["v0089"] = new[]
            {
                "1: CERCA: Risolto un problema di Visualizzazione e ricerca sulle Implosioni ed Esplosioni",
                "2: CERCA E PDF: Aggiunti i PDF dell' Archivio_AO. I PDF ora vengono sempre visualizzati correttamente anche nelle Implosioni / Esplosioni / Mancanti",
                "3: RIENTRI: Nuova sezione del Magazzino per effettuare dei Rientri sul MIRC001 ( Il movimento effettivo non è stato ancora testato - provatelo? )",
                "4: SITUAZIONE ODL: Ricerca per Padre o ODL Parziale, e Popup per ODL Multipli",
            },
            ["v0090"] = new[]
            {
                "1: STAMPA ETICHETTE: Ora si può scrivere un ODL MANUALE sulle etichette",
            },
            ["v0091"] = new[]
            {
                "1: MANCANTI: Ora c'è una sezione INVIATI per vedere tutti i Movimenti Mancanti già inviati, il loro stato, eseguire il Rinvio o la Ristampa",
                "2: MANCANTI: Quando si effettua il Movimento di un mancante, esso non viene più visualizzato da nessun dispositivo, fino a nuovo aggiornamento dei mancanti",
                "3: MANCANTI: Il Filtro non si resetta se si Aggiorna la Ricerca sullo stesso Magazzino",
                "4: GIACENZE: Ora ha una nuova Icona ed il filtro è Case Insensitive ( Es: 2000210A o 2000210a è lo stesso )",
                "5: SITUAZIONE ODL: Questa sezione degli Utenti Produzione è accessibile ora anche agli Utenti Magazzino",
                "6: RIENTRI MAGAZZINO: Query migliorata e possibilità di personalizzare la Q.tà del Rientro",
                "7: CHAT: Se non si legge un Messaggio entro 1 Ora - viene inviata una E-Mail come promemoria",
                "8: CHAT: La lista delle conversazioni è ora in ordine corretto",
                "9: Fix minori",
            },
            ["v0092"] = new[]
            {
                "1: Aggiunta la sezione Accettazione Materiali ( Magazzino )",
                "2: MANCANTI: Il movimento viene bloccato se si prova ad effettuare un movimento con il Database non aggiornato",
                "2: Pulsanti rapidi per tornare indietro dopo aver ricercato un Articolo da: Movimento Singolo / Giacenze / Accettazione",
                "3: Aggiunta di Logs per chi usa la versione Web",
            },
            ["v0093"] = new[]
            {
                "1: FIX URGENTE: Errore nell'invio dei Mancanti",
                "2: Sezione Accettazione - miglioramenti",
            },
            ["v0094"] = new[]
            {
                "1: FIX URGENTE: Rimosso Popup perenne che diceva -Database non Aggiornato- durante la ricerca di mancanti",
            },
            ["v0095"] = new[]
            {
                "1: CHAT: Quando un messaggio viene letto senza Internet, esso verrà marcato come Letto appena ci si riconnette",
                "2: MANCANTI: Risolto un problema che non marcava correttamente un Movimento come Errato in casi estremamente rari",
                "3: Fix ed Aggiornamenti Minori",
            },
            ["v0096"] = new[]
            {
                "1: CHAT: Popup interno quando arriva un nuovo messaggio",
                "2: CHAT: Eliminare, ricevere un Messaggio o ricevere una Notifica di Lettura non cancella il testo già scritto ( Nessuno se ne era accorto? )",
                "3: KANBAN: Miglioramento Pagina SCAFFALI con Dati Aggiuntivi e Query più veloci( ed Elenco Scaffali per Articolo, quando cliccato )",
                "4: KANBAN: Miglioramento Pagina CERCA ( Grafica, Storico e Link alla Scheda Articolo )",
            },
            ["v0097"] = new[]
            {
                "1: *NEW* CHAT FOTO: Ora è possibile inviare delle FOTO dalla chat",
                "2: CHAT: Altri miglioramenti e Fix",
            },
            ["v0098"] = new[]
            {
                "1: CHAT: Popup meno aggressivo quando si riceve un messaggio",
            },
            ["v0099"] = new[]
            {
                "1: NOTIFICHE: Sospensione app in background ed attivazione del Servizio Notifiche (Per Android >= 8)",
                "2: XIAIOMI: Sugli Xiaiomi si possono personalizzare le Notifiche dentro: Notifiche e Barre di stato > Notifiche app > Casagrande",
            },
            ["v0100"] = new[]
            {
                "0: ATTENZIONE: Questa versione comporta numerosi cambiamenti lato Server. Non si potranno più vedere le Foto senza aggiornarla",
                "1: CAMBIO ODL: Ora è presente nella sezione Produzione ( e in visualizzazione anche per gli utenti Produzione )",
                "2: RIENTRI: Ora sono visibili anche per gli utenti Produzione",
                "3: PRELIEVI: Ora sono di nuovo funzionanti e condividono le stesse funzionalità dei MANCANTI",
                "4: Supporto per Tablet 10 pollici con Webview Crosswalk",
                "5: Fix, Aggiornamenti minori e cambiamenti di alcune API del server",
            },
            ["v0101"] = new[]
            {
                "1: Risolto un problema di conflitto tra Mancanti e Prelievi",
            },
            ["v0102"] = new[]
            {
                "1: FOTO: Ora tutte le Foto si possono caricare anche dalla GALLERIA",
                "2: ACCETTAZIONE: Ora si possono Stampare le Etichette. Premendo su una Bolla o Fornitore, si filtra per esso",
                "3: STAMPA: Possibilità di fare una Etichetta Libera se nel Magazzino cercato non ci sono ODL",
                "4: GUIDA: Nuova Sezione con il Tutorial su come usare l'App, più altre Guide in generale",
                "5: PROFILO: Per fare il Login ora è necessaria anche la Password di Diapason",
                "6: Fix ed Aggiornamenti minori, nuovi Logs, gestione della Batteria negli Xiaiomi migliorata",
            },
            ["v0103"] = new[]
            {
                "1: CHAT: Casagrande Group => Chat di Gruppo in cui tutti possono scrivere e leggere i messaggi",
                "2: PROFILO: Aggiunta delle Opzioni. Modalità VOCE ( Beta, funziona solo su Scheda Articolo per ora ) ed Evidenzia Testo ( come su Diapason )",
                "3: Da Mancanti e Prelievi: ora c'è la possibilità di andare su --> Situazione ODL e tornare Indietro",
                "4: ACCETTAZIONE: Controllo Captcha per stampare 30 o più etichette",
                "5: Etichette Verniciatura: Il numero delle Etichette stampate coincide con la quantità selezionata ( la stampa delle etichette è leggermente più lenta ). Migliorate le proporzioni dell'Etichetta",
                "6: Aggiunta dei TOAST Nativi di Android ( Piccoli messaggi che compaiono in basso, utili per ricevere informazioni senza Popup invasivi )",
                "7: La tastiera cambia automaticamente da N a T a seconda della sezione",
                "8: Miglioramenti App in Background",
            },
            // 103 -> 104: Aggiunto Native Spinner
            ["v0104"] = new[]
            {
                "1: Risolto un problema che impediva la stampa delle Etichette in Accettazione",
                "2: Miglioramento nell'ordinamento dei Movimenti su Scheda Articolo",
                "3: Aggiunta della sezione Inventario ( Ancora in fase di Sviluppo )",
                "4: Aggiunta di Spinner nativi Android per caricare alcune sezioni",
                "5: Fix minori",
            },
            ["v0105"] = new[]
            {
                "1: INVENTARIO - Sezione Magazzino: OPERATIVO!",
            },
            // 105 -> 106: Cambiato BarcodeScanner Plugin da Cordova Barcode Scanner a Phonegap Barcode Scanner (Barcode Scanner piu opzioni)
            ["v0106"] = new[]
            {
                "0: INVENTARIO: Possibilità di Aggiungere un Articolo Manuale dai CONFERMATI",
                "1: INVENTARIO: Possibilità di Completare una Lista ( E quindi Archiviarla ) oppure di Eliminarla",
                "2: INVENTARIO: Possibilità di Eliminare una Riga Confermata facendola tornare nelle Giacenze",
                "3: INVENTARIO: Se una Lista viene Eliminata o Archiviata, gli Utenti che la stanno utilizzando verranno Notificati",
                "4: Barcode Scanner: Ora è Verticale invece che Orizzontale e più veloce",
            },
            ["v0107"] = new[]
            {
                "1: PROFILO: Ora si può caricare una Foto Profilo",
                "1: INVENTARIO: Fix minori",
            },
            ["v0108"] = new[]
            {
                "1: MANCANTI: Dopo la corretta Ri-Esecuzione di 1 Mancante, il suo Stato viene correttamente visualizzato con la spunta Verde",
                "2: CERCA ( Movimenti ): Ordinamento migliorato. Viene anche visualizzata l'ora, invece che la Data, se la Data è Oggi ",
                "3: CHAT: Ora è possibile scaricare una Foto Ricevuta sul telefono ( cartella: Download )",
                "4: INVENTARIO: Filtro per Utente e Fix minori",
                "5: FOTO PROFILO: Supporto API per la visualizzazione delle Foto Profilo anche sul Portale WEB",
            },
            ["v0109"] = new[]
            {
                "1: CREA LISTA ( USA ): Creazione File .CSV ed apertura del File tramite sistema Android",
            },
            ["v0110"] = new[]
            {
                "1: INVENTARIO: Miglioramenti Sostanziali nei controlli ed Aggiornamento API ( senza questo update l'inventario non funziona )",
                "1: PRELIEVO: Divisione per FASI | Click su FASE ===> Seleziona Tutto | Supporto per Magazzino MGIS001",
            },
            ["v0111"] = new[]
            {
                "1: INVENTARIO: La funzione Cambia Foto funziona correttamente | Supporto per i caratteri speciali nel nome della Foto ( * e / )",
                "2: INVENTARIO: Solo i pezzi Conformi possono avere la Quantità  Modificata | Controllo univocità degli Articoli migliorato",
                "3: Supporto per Tablet Android con ROM modificata 5.1 Arancione con codice rlk6735m_65c_1_l1",
            },
            ["v0112"] = new[]
            {
                "1: INVENTARIO: Non è più possibile modificare la Q.tà di un Articolo aggiunto manualmente",
                "2: INVENTARIO: Ora è possibile rimuovere una Foto scattata per l'inventario",
                "3: MANCANTI: Ora è possibile segnare manualmente un movimento errato ( X ) come completato",
                "4: FOTO PROFILO: Ora è possibile rimuovere la Foto Profilo",
            },
            // La 0113 non esiste è stata una release sbagliata
            ["v0114"] = new[]
            {
                "0: ZEBRA PORTATILE: Ora è richiesta la configurazione del MAC ADDRESS per farla funzionare ( migliora le prestazioni e la versatilità futura )",
                "1: MANCANTI: Ora il Sistema dovrebbe intercettare quei rari casi di Invio doppio dei Mancanti che intasa la TAB degli Inviati",
                "2: INVENTARIO: Il sistema ti guida in tutte sue le casistiche se aggiungi un pezzo Rosso o Arancione",
                "3: INVENTARIO: Nello Stato di un Articolo ora si può aggiungere anche una Nota ( Opzionale )",
                "4: INVENTARIO: Ora si può FILTRARE sia per Vano che per Articolo",
                "5: INVENTARIO: Le Foto di un Articolo scattate in stato Conforme vengono automaticamente aggiunte alle Foto di Cerca Articolo",
                "6: INVENTARIO: Ora vengono visualizzate anche le Liste Chiuse. Possono essere riaperte tenendole premute",
            },
            ["v0115"] = new[]
            {
                "1: Fix dei Messaggi di Errore dei Mancanti. Premere più volte sul tasto Invia fa uscire sempre e solo 1 Popup ( evita l'invio multiplo per errore )",
            },
            ["v0116"] = new[]
            {
                "1: L'utente Ospite ha la funzione CERCA ( Anche per Casagrande USA )",
                "2: Aggiornamento per i Tablet",
            },
            ["v0117"] = new[]
            {
                "1: INVENTARIO: Ora è possibile filtrare per Articolo anche prima di Caricare una Lista",
                "2: Liste di Prelievo MGAUT ( In sviluppo )",
            },
            ["v0118"] = new[]
            {
                "1: Supporto per la versione Desktop con Monitor Touch",
                "2: SITUAZIONE ODL: Nuova TAB con il Riassunto degli Ordini di Acquisto e di Lavoro",
                "3: MANCANTI / PRELIEVI: Ora è presente un Link Rapido per visualizzare gli Articoli",
                "4: LISTE DI PRELIEVO per MGAUT00/10 completate. Aggiungi Articoli alle Liste da: Prelievi ( Automaticamente ) o Cerca ( da Magazzini ) o dalla sezione MGAUT ( manualmente )",
                "5: ACCETTAZIONI: Ora è possibile creare una Lista di Carico da questa sezione e filtrare solo per quelle caricate",
                "6:  -> L'invio vero e proprie delle Liste di Prelievo e Carico verrà aggiunto con la prossima release, per ora non invia ancora niente al Database, ma potete fare delle prove di usabilità",
            },
            // 118 -> 119: Aggiornati tutti i Plugin (es: i dialogs ora hanno la barra contestuale sotto negli xiaiomi) + Aggiunto (finalmente) il Mitico Wheel Selector nativo Android
            ["v0119"] = new[]
            {
                "1: PRELIEVI / MANCANTI: Non è più possibile fare i Movimenti da MGIS001",
                "2: LISTE MGIS001: Ora è possibile effettuare i Movimenti MGIS001 da questa nuova Sezione ( cliccando su una Lista di Prelievo )",
                "3: RIENTRI: Query migliorata ( Alcuni Articoli non venivano visualizzati )",
                "4: Miglioramenti per Android Nativo ( Es: aggiunta del componente wheel spinner ed aggiornamenti vari)",
            },
            ["v0120"] = new[]
            {
                "1: CSUSA ( Inventory ): The Inventory section was Significantly Improved",
                "2: LISTE MGIS001: Premendo su una Riga si ottengono Informazioni aggiuntive",
            },
            ["v0121"] = new[]
            {
                "1: IMPEGNO ODL: Aggiunta la funzione per Aggiornare la Quantità di un Articolo ( UPD )",
                "2: MANCANTI: Aggiunta la possibilità di eseguire comunque un Movimento Mancante anche se il Database non era Aggiornato",
                "3: MANCANTI: Se ci sono stati Errori nei Movimenti di OGGI essi vengono segnalati nella Tab INVIATI",
                "4: SITUAZIONE ODL: Nuova sezione ( TUTTI ) che visualizza tutte le altre sezioni, inclusi i MANCANTI",
                "5: GIACENZE: Ora si possono ricercare le Giacenze anche per VANO",
                "6: INVENTARIO: Fix per la freccetta in basso quando si Conferma / Rimuove un Articolo",
                "7: CERCA: Gli Impegni ( Da Ordini di Lavoro ) in stato 10 o inferiore sono visualizzati in Grigio, mentre gli altri sono in Verde",
            },
            ["v0122"] = new[]
            {
                "1: MGIS001: Possibilità di Confermare una Riga della Lista come Trasferita cliccandoci sopra",
                "2: INVENTARIO: Ristrutturazione totale in corso. Sarà impossibile accederci finchè la nuova versione non sarà completata",
            },
            // Cambiati i seguenti file nel PLUGIN.XML di crpyt file (30% piu leggero) - Yes Tablet
            // <file regex="node_modules" /> <file regex="cordova-js-src" /><file regex="plugins" />
            ["v0123"] = new[]
            {
                "1: INVENTARIO: Ristrutturazione Inventario. Creazione Liste per Vano e Lista Unificata",
                "2: LISTE MGIS001: Le liste MGIS001 ora sono visualizzate correttamente",
                "3: ANDROID: Ottimizzazioni e Riduzione del peso dell'applicazione del 30% ( circa )",
                "4: SITUAZIONE ODL: Cliccando sul BOX del padre, esso si nasconde per ingrandire la Lista della sezione TUTTI",
                "5: Fix ed aggiunte minori e miglioramenti visuali",
            },
            // Yes Tablet
            ["v0124"] = new[]
            {
                "1: CAMBIO ODL: Fix della Query di Trasferimento",
                "2: INVENTARIO: Possibilità ( per alcuni utenti ) di confermare una lista intera con 1 click",
            },
            // No Tablet
            ["v0125"] = new[]
            {
                "1: SITUAZIONE ODL: Materiale in Ricarico non più visualizzato e Miglioramenti nelle visualizzazioni delle Q.tà",
                "2: IMPEGNO ODL: Quando viene aggiunto un Articolo ad un ODL, anche Visentin riceve una e-mail in CC, e viene visualizzato il Nome Utente inviante",
            },
            // No Tablet
            ["v0126"] = new[]
            {
                "1: IMPEGNO ODL: Aggiungere un Articolo invia una Attività a m.vicenzi ( in futuro non manderà più una E-Mail a Visentin ). Modificare o Rimuovere un Articolo aggiorna quell'Attività",
                "2: CHAT: Se si va a capo inserendo un messaggio, esso poi verrà visualizzato correttamente",
                "3: WEB CLIENT: Aggiunta delle Notifiche Desktop nella version Web usando HTTPS ( Cliccare su Consenti Notifiche quando appare )",
                "4: Aggiunta di funzioni a scopo statistico",
            },
            // Yes Tablet
            ["v0127"] = new[]
            {
                "1: MANCANTI / PRELIEVI: Quando non c'è Nessun Risultato, viene comunque visualizzata la schermata per accedere agli Inviati",
                "2: LISTE MGIS001: Pulsante per Visualizzare / Nascondere gli Articoli di una Lista",
                "3: CERCA: Da IMP -> Mancanti -> Popup -> Ora c'è un Link all' ODL",
                "4: Aggiornamento, Riduzione ed Eliminazione di alcuni Moduli e Plugin ( APP circa 3MB più leggera )",
                "5: WEB CLIENT: Utilizzo di HTTPS per le Notifiche, e aggiunta di API per l'accesso a tutte le funzioni AJAX tramite HTTPS",
            },
            // Yes Tablet
            ["v0128"] = new[]
            {
                "1: LISTE MGIS001: Ora i Movimenti vengono effettuati in maniera ASINCRONA ( Sono fino a 20 volte più veloci rispetto a prima )",
                "2: PROFILO+: Ora il Sistema aggiorna automaticamente il Profilo Utente in Background quando necessario ( Risolve alcuni crash dell'APP ad es. negli Impegni ODL ed Attività )",
                "3: IMPEGNO ODL: Risolto un Bug che causava un Caricamento Infinito dopo l'Invio di un Impegno",
                "4: IMPEGNO ODL: Risolto un Bug per il quale non sempre arrivava una E-Mail in CC a Visentin",
                "5: IMPEGNO ODL: Risolto un Bug nei LOGS delle statistiche che riportava Magazzino: Nessuno se era il primo inserimento di quell' ODL",
            },
            // No Tablet
            ["v0129"] = new[]
            {
                "1: LISTE MGIS001: Aggiunta la Lista dello Storico dei Prelievi effettuati",
                "2: MANCANTI: Aggiunta di Logs per risolvere il bug dell'invio Multiplo dei Mancanti",
            },
            // No Tablet
            ["v0130"] = new[]
            {
                "1: LISTE MGIS001: Salvataggio ( nello Storico ) anche delle Righe Confermate Manualmente",
                "2: MANCANTI: Risolto ( spero ) un BUG che inviava più Mancanti ( uguali ) insieme ( premendo più volte il tasto Invia )",
            },
            // Yes Tablet
            ["v0131"] = new[]
            {
                "1 - Liste MGIS001 ➔ Risolto il problema 'CODICE VANO OBBLIGATORIO' per le Liste MGIS001 ( con destinazione MGRICAM ) senza vano di Default",
                "2 - Liste MGIS001 ➔  Visualizzazione corretta degli Errori nel Popup. Inoltre gli Storici con Errori vengono colorati in Rosso",
                "3 - Web Client / Tablets ➔ Fix delle proporzioni di alcuni Popup ( Chat, Storico MGIS001, ecc.. )",
                "4 - Altri Fix minori",
            },
            // No Tablet
            ["v0132"] = new[]
            {
                "1 - Liste MGIS001 ➔ Se il Salvataggio nello Storico Fallisce, il Sistema chiede se vuoi ritentare il Salvataggio",
            },
            // No Tablet
            // 1.32 rilasciato per sbaglio acerbo ( Sovrapposizioni di Alert esteticamente sgradevoli )
            ["v0133"] = new[]
            {
                "1 - Liste MGIS001 ➔ Se il Salvataggio nello Storico Fallisce, il Sistema chiede se vuoi ritentare il Salvataggio",
            },
            // Yes Tabletle
            ["v0134"] = new[]
            {
                "1 - PRELIEVI: Ora è possibile Modificare sia il Magazzino che il Vano di Origine",
                "2 - CHAT: Aggiunta del Gruppo Magazzino! Supporto per la creazione di qualsiasi altro Gruppo ( A richiesta )",
                "3 - CHAT: Vicino ai messaggi ora viene mostrata la Data o l'Ora di Invio",
                "4 - CHAT: Possibilità ( nei Gruppi ) premendo l'icona ✔️vicino ad un messaggio di vedere chi ha letto il messaggio",
                "5 - CHAT: Il numero dei Messaggi Non Letti per i Gruppi ora è più accurato",
                "6 - CHAT: Grafica e Colori dei Messaggi migliorati, specialmente nei dispositivi m698 ( Palmari magazzino )",
                "7 - WEB / DESKTOP: Rimosso il supporto per cambiare TAB trascinando con il mouse",
                "8 - CERCA ( Movimenti ) ➔ Aggiunti Padre e Descrizione Padre che non comparivano ( su alcuni Movimenti )",
            },
            // Yes Tablet
            ["v0135"] = new[]
            {
                "1 - ACCETTAZIONE: Possibilità di Creare ed Inviare una Lista di Carico per MGAUT00 o MGAUT10 ( Beta )",
                "2 - MGAUT: Ora è possibile Inviare una Lista di Prelievo da MGAUT00 o MGAUT10 ( Beta )",
                "3 - CHAT: Possibilità di iniziare una Chat Privata premendo sulla freccia vicino al Messaggio di un utente di un Gruppo",
            },
            // Yes Tablet
            ["v0136"] = new[]
            {
                "1 - ACCETTAZIONE: Ora è possibile visualizzare i Mancanti e i Dettagli Articolo nella Lista di Carico",
            },
            // Yes Tablet
            ["v0137"] = new[]
            {
                "1 - ACCETTAZIONE: Miglioramento della Query per la Visualizzazione dei Dati",
                "2 - ACCETTAZIONE: Aggiunta dei Magazzini MG00020 e MGPUL01 e Filtro per Magazzino",
                "3 - ACCETTAZIONE: Possibilità di visualizzare i Mancanti di un Articolo con Magazzino e Q.tà Mancante",
                "4 - ACCETTAZIONE: Possibilità di Aggiungere un Articolo dalla Lista delle Accettazioni",
                "5 - ACCETTAZIONE: Riordinamento per ultimo Articolo inserito",
                "6 - MGIS001: Le Liste vengono visualizzate come sul foglio ( es. 1001302970_0010_2 ) e dopo i Movimenti viene visualizzato il nome della Lista",
                "7 - MANCANTI / PRELIEVI: Ora si possono visualizzare anche i Mancanti Non Critici",
                "8 - PRELIEVI: Possibilità di modificare ( temporaneamente ) il Magazzino o il Vano anche negli Storici",
                "9 - KANBAN: Ora vengono Visualizzati e si possono Aggiungere agli scaffali anche gli Articoli diversi dal Tipo N",
            },
            // Yes Tablet
            // uguale a v0137 - Uguale quasi alla 0.137 ma con qualche accorgimento (Kanban e visual Q.tà mancanti)
            ["v0138"] = new[]
            {
                "1 - ACCETTAZIONE: Miglioramento della Query per la Visualizzazione dei Dati",
                "2 - ACCETTAZIONE: Aggiunta dei Magazzini MG00020 e MGPUL01 e Filtro per Magazzino",
                "3 - ACCETTAZIONE: Possibilità di visualizzare i Mancanti di un Articolo con Magazzino e Q.tà Mancante",
                "4 - ACCETTAZIONE: Possibilità di Aggiungere un Articolo dalla Lista delle Accettazioni",
                "5 - ACCETTAZIONE: Riordinamento per ultimo Articolo inserito",
                "6 - MGIS001: Le Liste vengono visualizzate come sul foglio ( es. 1001302970_0010_2 ) e dopo i Movimenti viene visualizzato il nome della Lista",
                "7 - MANCANTI / PRELIEVI: Ora si possono visualizzare anche i Mancanti Non Critici",
                "8 - PRELIEVI: Possibilità di modificare ( temporaneamente ) il Magazzino o il Vano anche negli Storici",
                "9 - KANBAN: Ora vengono Visualizzati e si possono Aggiungere agli scaffali anche gli Articoli diversi dal Tipo N",
            },
            // Yes Tablet
            ["v0139"] = new[]
            {
                "1 - ACCETTAZIONE: Nuovo Pulsante Target per selezionare tutti gli Articoli Visualizzati (max 30)",
                "2 - ACCETTAZIONE: Conferma della Q.tà anche nell'Aggiunta degli Articoli via Codice / Scanner",
                "3 - ACCETTAZIONE: Stampa del Foglio dopo l'invio di una Lista di Carico",
                "4 - ACCETTAZIONE ( WEB ): Ora è possibile filtrare anche per i Mancanti",
            },
            // No Tablet
            ["v0141"] = new[]
            {
                "1 - WEB / RASPBERRY: Aggiunta della Tastiera Virtuale ed ottimizzazioni varie",
                "2 - DOCUMENTI: Nuova sezione contenente diverse procedure ( Per tutti gli Utenti )",
                "3 - Alcune sezioni ora sono disponibili anche per gli Utenti Standard ed Ospite",
            },
            // Yes Tablet
            ["v0142"] = new[]
            {
                "1 - SITUAZIONE ODL: Nascosti gli Articoli di tipo D ( Documenti )",
                "2 - IMPEGNI ODL: Ora vengono visualizzate le Q.tà nella Lista degli Articoli e viene proposta la Q.tà corrente su UPD",
                "3 - WEB / RASPBERRY: Possibilità di cambiare il layout della tastiera tenendo premuto 'N' o 'T'",
                "4 - WEB / RASPBERRY: Possibilità di Filtrare su Situazione ODL senza digitare",
                "5 - MGAUT: Dalla sezione 0027 si possono inviare Liste di Prelievo per la Fase 0027",
                "6 - MGAUT: Nuova sezione MGAUT02 per vedere le Liste in Sospeso su MGAUT02",
                "7 - ACCETTAZIONE: Nuovo Popup per una visualizzazione migliore dei Mancanti",
            },
            // No Tablet
            ["v0143"] = new[]
            {
                "1 - MGAUT02: Ora è possibile cliccare le Liste per espanderle",
                "2 - LISTE 0027: Dopo l'invio di una Lista, la schermata viene subito aggiornata nascondendo la Lista inviata",
                "3 - CHAT: Ora viene visualizzato il nome di chi ha inviato un Messaggio di Gruppo nel Popup",
                "4 - Bugfix, Fix grafici e minori",
            },
            // No Tablet
            ["v0144"] = new[]
            {
                "1 - IMPEGNO ODL: Non viene più mandata una e-mail a Visentin",
                "2 - LISTE 0027: Accesso Limitato al CMA006",
                "3 - LISTE 0027: Le attività del CMA006 vengono automaticamente completate inviando una Lista ( Beta )",
            },
            // Yes Tablet
            ["v0145"] = new[]
            {
                "1 - MOVIMENTO LIBERO: Ora si può aggiungere una NOTA al Movimento Singolo",
                "2 - WEB: Supporto per il Touch con il Mouse nella versione Web (es: tenere schiacciato con il mouse un Messaggio, o il pulsante Cerca 🔎 ecc..",
                "3 - LISTE 0027: Bugfix vari per le attività del CMA006 completate automaticamente",
            },
            // Yes Tablet
            ["v0146"] = new[]
            {
                "1 - ACCETTAZIONE: Gestione migliore di alcuni Articoli presenti in più Magazzini diversi ( es: MIRC001 e MG00020 )",
                "2 - MOVIMENTO LIBERO: Ora si può aggiungere una NOTA al Movimento Singolo",
                "3 - WEB: Supporto per il Touch con il Mouse nella versione Web (es: tenere schiacciato con il mouse un Messaggio, o il pulsante Cerca 🔎 ecc..",
                "4 - LISTE 0027: Bugfix vari per le attività del CMA006, che ora vengono completate automaticamente",
            },
            // Yes Tablet
            ["v0147"] = new[]
            {
                "1 - LISTE 0027: Introdotto il Nuovo Sistema in Tempo Reale",
                "2 - LISTE 0027: Cliccando su una Riga di una Lista si possono vedere i Dettagli ( Incluse le Fasi diverse dalla 0027 e la loro Q.tà)",
                "3 - LISTE 0027: Ora il Sistema si Aggiorna automaticamente una volta inviata una Lista di Prelievo",
                "4 - ACCETTAZIONE: Ora il Sistema si Aggiorna automaticamente una volta inviata una Lista di Carico",
                "5 - CHAT: Aggiunta del Gruppo Produzione",
            },
            // Yes Tablet
            ["v0148"] = new[]
            {
                "1 - PROFILO / CHAT: Disattivando le Notifiche di Gruppo, vengono disattivate le Notifiche da tutti i Gruppi ( Non solo di Casagrande Group )",
                "2 - LISTE 0027: La Query per le Liste 0027 è stata notevolmente migliorata",
                "3 - LISTE 0027: Aggiunta di Info, Fix minori e grafici",
                "4 - ATTIVITA: Miglioramenti nella Modifica delle Attività ( Mostra anche la precedente nel messaggio e solo il creatore può modificarla )",
                "5 - Fix minori su alcuni Popup",
            },
            // Yes Tablet
            ["v0149"] = new[]
            {
                "1 - ACCETTAZIONE: Aggiunta la possibilità di Ristampare una vecchia Lista di Carico",
                "2 - LISTE MGAUT: Ora sono disponibili anche per gli Utenti Produzione ( CPR )",
            },
            // Yes Tablet
            ["v0150"] = new[]
            {
                "1 - IMPEGNO ODL: Ora è disponibile anche per le Fasi 003x ( oltre che per la 0027 )",
            },
            // No Tablet
            ["v0151"] = new[]
            {
                "1 - IMPEGNO ODL: Accesso alle Fasi 003x limitato al CPR013",
            },
            // Yes Tablet
            ["v0152"] = new[]
            {
                "1 - LISTE MGAUT ( MGIS ): Ora c'è la possibilità di modificare il magazzino di partenza per i trasferimenti da MGIS001 a MGAUT01",
                "2 - LISTE MGAUT e CARICO: Ora le liste vengono create con il Nome Utente ( n.cognome ) e non con il Codice Operatore",
            },
            // No Tablet
            ["v0153"] = new[]
            {
                "1 - LISTE MGAUT00/10: Ora l'APP non si blocca più dopo aver inviato una lista di Prelievo",
            },
            // No Tablet
            ["v0154"] = new[]
            {
                "1 - Sezione MGIS001: Ora i trasferimenti funzionano solo da MGAUT01 e la sezione è stata rinominata",
            },
            // No Tablet
            ["v0155"] = new[]
            {
                "1 - LISTE MGAUT00/10: Reset delle Liste una volta inviate",
            },
            // No Tablet
            ["v0156"] = new[]
            {
                "1 - PRELIEVI / MANCANTI: I magazzini MEF, MC, MN e MGFURG non vengono più visualizzati",
                "2 - PRELIEVI / MANCANTI: I magazzini MISP001 e MISP002 ora vengono solo visualizzati ( non è più possibile effettuare movimenti )",
                "3 - LISTE 0027: Fix minori",
            },
            // Yes Tablet
            ["v0157"] = new[]
            {
                "1 - KANBAN: Se l'Articolo ha Giacenze su MGAUT00 o MGAUT10, l'operatore viene allertato ( e viene richiesta una conferma per aggiungere l'Articolo )",
            },
            // No Tablet
            ["v0158"] = new[]
            {
                "1 - PRELIEVI: La modifica del Magazzino / Vano non è più un input manuale, ma è guidata con un Popup di selezione",
                "2 - MGAUT01: Ora la riga selezionata viene anche colorata in viola, per evidenziare meglio la selezione",
            },
            // No Tablet
            ["v0159"] = new[]
            {
                "1 - IMPEGNO ODL: Prima di poter fare un Impegno, il sistema controlla che l'Articolo abbia abbastanza Giacenza ( su MGAUT00 / MGAUT10 / MISK )",
            },
            // Yes Tablet
            ["v0160"] = new[]
            {
                "1 - CHAT: Ora è possibile inoltrare un Messaggio fino ad altri 3 Utenti ( Android ) o ad un singolo Utente ( Web ). Tieni premuto un messaggio per inoltrarlo!",
                "2 - VELOCITA 0027: Nuova sezione! ( Produzione ). Premendo su questa sezione, il Sistema fornirà una MEDIA di quanto un pezzo impiegherà ad essere disponibile dopo essere stato Impegnato",
                "3 - IMPEGNO ODL: Al termine di un Impegno, l' Utente potrà anche visualizzare il Tempo di Attesa medio per quel Magazzino",
                "4 - MGAUT02: Le liste -Non Inviate- vengono evidenziate in Arancione",
            },
            // No Tablet
            ["v0161"] = new[]
            {
                "1 - PRELIEVI: Ora il Sistema accetta anche i Magazzini MISP001 e MISP002 ( Per gli OR e gli OM )",
            },
            // No Tablet
            ["v0162"] = new[]
            {
                "1 - LISTE MGAUT: Rinnovata l'interfaccia e la procedura per compilare le liste di Prelievo",
                "2 - LISTE MGAUT: Il sistema ora accetta Prelievi ODV",
                "3 - LISTE MGAUT: Ora è possibile inserire una Nota ( opzionale ) inviando una lista, che verrà applicata a tutti i Movimenti di quella lista ( anche nella sezione Liste 0027 )",
            },
            // No Tablet
            ["v0163"] = new[]
            {
                "1 - Hotfix per i Prelievi Inviati che non si aggiornano",
            },
            // No Tablet
            ["v0164"] = new[]
            {
                "1 - MGAUT: Aggiunta l'opzione Prelievo Immediato ( ODV ): Se il Sistema non trova nessun ODV ( su Prelievo ODV ) si può utilizzare questa opzione ( che viene aggiornata in tempo reale )",
                "2 - VELOCITA 0027: Ora vengono visualizzate sia le Ore che i Minuti",
                "3 - Fix Minori",
            },
            // Yes Tablet
            ["v0165"] = new[]
            {
                "1 - NUOVA SEZIONE: Situazione Odv ( dal Menu Principale ) -> ulteriori miglioramenti con il prossimo update",
                "2 - ATTIVITA: Supporto per la creazione di attività per ACEMA",
                "3 - DOCUMENTI: Aggiunta del documento - Attribuzione Materiali -",
                "4 - Fix, aggiunte e cambiamenti minori in varie sezioni",
            },
            // No Tablet
            ["v0166"] = new[]
            {
                "1 - SITUAZIONE ODV: Aggiunto Filtro Target e l'opzione Espandi / Minimizza Liste",
                "2 - SITUAZIONE ODV: Aggiunto Pulsante Conversione in PDF per stampare la Lista ( sia da APP che da WEB )",
                "3 - VELOCITA 0027: il Sabato e la Domenica ora sono escluse dal conteggio, in quanto non lavorativi",
                "4 - Alcuni plugin vengono caricati localmente invece che online ( velocizza leggermente l'avvio dell' APP Android e corregge alcuni errori )",
            },
            // Yes Tablet
            ["v0167"] = new[]
            {
                "1 - MATERIALI IN ARRIVO: Nuova Sezione ( di visualizzazione ) dentro AVVISI ( MAT.A )",
                "2 - RIENTRI: Ora dalla sezione Magazzino -> Rientri si può effettuare un Movimento di Magazzino al MG00020 o al MGPUL01 ( cliccando su un Articolo )",
                "3 - SITUAZIONE ODV: Popup con INFO aggiuntive cliccando su INFO TESTATA dell'ordine. Popup con INFO aggiuntive cliccando anche su una RIGA dell'ordine",
                "4 - FASE 0027: Risolto un problema ( sporadico ) che non auto-completava alcune attività. Si verificava quando veniva inserito il primo Articolo in una fase 0027 ( Magazzino: Nessuno )",
                "5 - Bolle Destinazione Specifica ( D.SPEC ): Query velocizzata ( si scarica più velocemente )",
                "6 - Fix per il doppio Popup su MGAUT00/10, alla pressione multipla del tasto Invia ( poteva causare un invio di liste doppie, lato Android client )",
            },
            // Yes Tablet
            ["v0168"] = new[]
            {
                "1 - CREA LISTA LIBERA: Direttamente da Casagrande U.S.A., ora anche qui è disponibile questa sezione ( su: Magazzino ) per creare una Lista Libera e generare un Excel ( infatti per ora è tradotta solo al 50% )",
                "2 - CHAT: All'apertura dell'APP ( e ogni volta che si torna sul Menu Principale ) il Sistema ti notifica se hai Chat private non lette ( leggetele )",
            },
            // Yes Tablet
            ["v0169"] = new[]
            {
                "1 - LISTE ODV: Ora nelle liste ODV vengono passati ( oltre ai numeri riga ) anche i numeri della scomposizione della riga ( altrimenti alcune liste non potevano essere passate )",
                "2 - ATTIVITA ( ACEMA ): Ora tutti gli Utenti possono visualizzare le Attività di ACEMA. I CTM002 e CTM005 possono anche chiudere queste attività",
            },
            // Yes Tablet
            ["v0170"] = new[]
            {
                "1 - Attività: Fix e miglioramenti minori ( scadenza OGGI inclusiva, visualizzazione dell'emoji timer se l'attività ha scadenza ecc.. )",
                "2 - Aggiunta di ulteriori Logs",
                "3 - Pulizia del codice",
            },
            // Yes Tablet
            ["v0171"] = new[]
            {
                "1 - CERCA ARTICOLO: Nella sotto-sezione Disegni: ora vengono elencati anche tutti i File dell'ufficio tecnico - per quell'Articolo ( sotto: Documenti non ufficiali )",
                "2 - ATTIVITA: I CTM002 e CTM005 ora possono correttamente chiudere le Attività",
            },
            // Yes Tablet
            ["v0172"] = new[]
            {
                "1 - ATTIVITA: Modifiche sul codice per la gestione della Scadenza ( Allineamento con Display ACEMA )",
                "2 - ATTIVITA: Ora non si possono più chiudere le Attività con Scadenza",
            },
            // Yes Tablet
            ["v0173"] = new[]
            {
                "1 - LISTE MGAUT: Fix dell' ERRORE 500 durante l'invio di una Lista di Prelievo ( nel caso sia stato inserito un A CAPO nella Nota Opzionale )",
                "2 - LISTE MGAUT: Aggiunta la possibilità di impostare anche il VANO, quando il Magazzino di Destinazione è gestito a vani ( es: MISK001 ). MGRICAM è escluso ( viene usato il vano di default per ogni articolo )",
            },
            // Yes Tablet
            ["v0174"] = new[]
            {
                "1 - LISTE MGAUT ( Solo per le Liste ODV pre-compilate automaticamente con la Bolla ) => Cliccando su un Articolo della Lista MGAUT10, ora è possibile spostarlo nella Lista MGAUT00 ( se ha abbastanza Giacenza )",
                "2 - CAMBIO ODL: Ora vengono sempre esclusi i Magazzini Automatici dai Movimenti per il Cambio ODL ( Risolve l'errore sporadico: OPERATORE NON ABILITATO )",
                "3 - CAMBIO ODL: La Lista degli ODL ( per scegliere il nuovo ODL ) ora è ordinata in modo ascendente",
                "4 - SITUAZIONE ODV: Ora vengono visualizzate anche le Date di Consegna degli ODA e degli ODL ( anche nel PDF che viene scaricato )",
            },
            // No Tablet
            ["v0175"] = new[]
            {
                "1 - IMPEGNO ODL: Aggiunta la possibilità di fare gli Impegni ( negativi ) anche per la Fase 0065",
            },
            // No Tablet
            ["v0176"] = new[]
            {
                "1 - Abilitazioni extra alla sezione Kanban",
            },
            // No Tablet
            ["v0177"] = new[]
            {
                "1 - Stampa Etichetta ( Scheda Articolo ): Fix per la posizione della Nota libera. Inoltre ora può contenere solo 40 caratteri invece che 60, però il carattere è stato ingrandito",
                "2 - Lo Storico MGAUT01 viene visualizzato sempre, anche quando non ci sono più Liste",
                "3 - Eliminato il Popup RISTAMPA dai Mancanti e dai Prelievi",
                "4 - Numerosi Fix minori",
            },
            // No Tablet
            ["v0178"] = new[]
            {
                "1 - LISTE MGAUT01: Se il Magazzino di Destinazione ( di una lista di Prelievo ODL ) è un MISK, viene richiesto il vano",
                "2 - MANCANTI: Quando si passa dai Mancanti alla Ricerca Articolo / ODL, la selezione degli Articoli rimane salvata quando si torna indietro",
                "3 - MOVIMENTO SINGOLO: Ora vengono visualizzati anche i Magazzini senza Giacenza ma con Impegni ( come su Cerca Articolo )",
            },
            // Yes Tablet
            ["v0179"] = new[]
            {
                "1 - SITUAZIONE ODV: Risolti alcuni Bug di visualizzazione e del PDF generato ( ora è in linea con la Versione Web )",
                "2 - LISTE MGAUT01: Fixato un possibile bug che chiedeva una seconda volta il vano per il MISK ( anche se era già stato impostato )",
                "3 - Pulizia del codice",
            },
            // Yes Tablet
            ["v0180"] = new[]
            {
                "1 - LISTA DI PRE-CARICO: Nuova Sezione ( Abbinata anche ad Impegno ODL ) per creare delle Liste di Pre-Carico dalla Fase 0065 ( Oppure Libere ). Accesso consentito solo ad alcuni Utenti.",
                "2 - ACCETTAZIONE: Possibilità di Visualizzare ed Importare le Liste di Pre-Carico, e di Completarle",
                "3 - ATTIVITA: Ora generare una Lista di Pre-Carico crea una Attività, mentre inviare una Lista di Carico ( Importando dal Pre-Carico ) la completa",
                "4 - ATTIVITA: Tenendo schiaccata una Attività, o da 'Copia Codice' cliccando un'Attività: Ora puoi copiare nella clipboard uno o più Codici contenuti in essa. Aggiunto un pulsante -Info- nella schermata Attività per spiegare cosa si può fare.",
                "5 - FASE 0027: Ora La Fase 0034 segue lo stesso procedimento della Fase 0027, ma per il materiale elettrico. La sezione è stata rinominata da 0027 a: 27/34",
                "6 - PROFILO: nuova opzione per Attivare / Disattivare il Popup Ristampa ( Solo per i CTM )",
            },
            // Yes Tablet
            ["v0181"] = new[]
            {
                "1 - PRE-CARICO: Migliorata la Visualizzazione delle Liste Create / Completate con le eventuali modifiche",
                "2 - PRE-CARICO: Aggiunti i CPR010 e CPR011 alla nuova sezione",
                "3 - PRE-CARICO: Gestione degli EN-X completa",
                "4 - PRE-CARICO: Possibilità di Visualizzare / Riscaricare il PDF / Modificare ( non ancora attivo ) / Eliminare ( non ancora attivo ) le Liste ancora aperte",
                "5 - PRE-CARICO (accettazione): Ora è possibile importare Liste Multiple. Ora si vede il nome della Lista a cui l'Articolo appartiene",
                "6 - PRE-CARICO (accettazione): Movimenti Automatici verso il MIRC quando richiesto",
                "7 - PRE-CARICO (accettazione): Ristrutturazione delle API, del Database del Precarico e numerosi Fix Minori,",
            },
            // Yes Tablet
            ["v0182"] = new[]
            {
                "1 - PRE-CARICO: Ora è possibile MODIFICARE ed ELIMINARE una lista ancora Aperta",
                "2 - PRE-CARICO: Quando digiti un ODL valido come nome della lista, vengono anche inseriti Padre + Descrizione nel PDF",
                "3 - PRE-CARICO: Fix Minori ( Invalid Date, Nome del PDF, Testo delle Attività, gestione di -Nessun Magazzino- rilevato da Impegno ODL, ed altri dettagli minori )",
                "4 - IMPEGNO ODL: Aggiunta del Pulsante Barcode per aggiungere un Articolo",
            },
            // Yes Tablet
            ["v0183"] = new[]
            {
                "1 - PRE-CARICO: Aggiunta del Barcode per aggiungere un Articolo ( E fix minori per lo Scanner Barcode )",
                "2 - PRE-CARICO: Possibilità di segnare un Precarico ( già Caricato ) come Revisionato",
                "3 - ACCETTAZIONE: le Liste di Pre-Carico ora vengono sempre aggiornate prima di essere aperte ( Nel caso fossero state modificate - vedi versione precedente )",
                "4 - ATTIVITA: Fix pulsante 'Copia Codice' su Attività",
                "5 - MOVIMENTO: Il Pulsante SALVA sui Movimenti, ora ricorda anche: ODL e NOTA per i Movimenti successivi",
                "6 - RICERCHE: Lo Storico delle Ricerche è passato da 8 a 15 ( con scroll per vedere quelli più vecchi )",
                "7 - GIACENZE: Migliorata la visualizzazione del Popup cliccando sul Singolo Articolo",
                "8 - Vari Fix Minori",
            },
            // Yes Tablet
            ["v0184"] = new[]
            {
                "1 - PRE-CARICO: Aggiunta di Trasferimenti (se disponibili) per gli Articoli aggiunti manualmente",
                "2 - Fix e miglioramenti grafici minori",
            },
            // Yes Tablet
            ["v0185"] = new[]
            {
                "1 - ACCETTAZIONE: Fix di alcuni Bug nell'Importazione / Aggiunta di una Lista di Pre-Carico ( es. Articolo presente in più magazzini ) ed aggiunta del simbolo ⚠️ se la q.tà della Lista è superiore alla Giacenza + Warning se si preme invia",
                "2 - PRE-CARICO: Ora anche Modificando una Lista ( Importandola ) il Sistema propone i Trasferimenti di Magazzino",
                "3 - IMPEGNO ODL: (Ri)Aggiunta del Barcode su ADD per aggiungere un Articolo tramite Barcode",
                "4 - MGAUT: Le Tab 27/34 e AUT02 sono state invertite",
                "5 - Fix Minori",
            },
            // No Tablet
            ["v0186"] = new[]
            {
                "1 - KANBAN: La sezione CERCA ARTICOLO KANBAN ora è disponibile per tutti i CPR.",
                "2 - CERCA ARTICOLO KANBAN: Visualizzazione dell'Elenco degli Scaffali per Articolo migliorata.",
            },
            // No Tablet
            ["v0187"] = new[]
            {
                "1 - PRE-CARICO (storico): Le quantità EN-X vengono visualizzate ( nello storico ) anche nel caso di Righe Rimosse",
                "2 - PRE-CARICO (storico): Se la Q.tà di un Articolo è stata modificata a 0 e caricata, essa viene considerata come [riga_rimossa] invece che [qta_modificata] nello storico",
            },
            // Yes Tablet
            ["v0188"] = new[]
            {
                "1 - SITUAZIONE ODL: Ora gli Articoli in Transito ( su MGAUT02 e MGAUT01 ) vengono considerati IN PRELIEVO e non MANCANTI",
                "2 - MOVIMENTO SINGOLO: Il Popup con lo Stato Movimento è stato cambiato e reso più leggibile. Ora è visualizzata anche una scritta SUCCESSO in VERDE, oppure ERRORE in ROSSO. Premendo Indietro: ri-visualizzi l'articolo",
                "3 - MOVIMENTO SINGOLO: Attivando lo Scanner ( integrato negli m698 ) viene distrutto anche il Popup di Movimento ( e altri fix minori )",
                "4 - RISTAMPA ( OPZIONI ): Quando l'opzione [ ristampa ] viene disabilitata, non si riceverà più l'Alert: [ Vuoi Ristampare? ]",
                "5 - Pulizia vecchi script PHP",
            },
            // No Tablet
            ["v0189"] = new[]
            {
                "1 - LISTE PRE-CARICO: Se nel nome di una Lista di Pre-Carico c'è un carattere / , esso viene sostituito con il carattere _ ( evita crash nella generazione del PDF )",
                "2 - MANCANTI / PRELIEVO: Aggiunta del Filtro Blacklist ( Sia su Mancanti che Prelievi ) per non visualizzare più certi Magazzini. Questa Preferenza rimane attiva anche alla chiusura dell'app",
                "3 - MOVIMENTO SINGOLO: Visualizzazione del NUOVO Popup di Errore anche in caso di Errore di Rete, o del Server",
                "4 - Aggiunta la proprietà webClientVersion per tenere traccia della versione Web nei Logs",
            },
            // Yes Tablet
            ["v0190"] = new[]
            {
                "1 - LISTE PRE-CARICO: Eliminando una lista di Pre-Carico, si elimina sempre anche l'Attività associata",
                "2 - CARICO ACCETTAZIONI: Se importando una Lista di Pre-Carico viene trovato un Mancante, esso verrà visualizzato in Rosso",
                "3 - SITUAZIONE ODV: Un Articolo in Transito ( MGAUT02 o MGAUT01 ) viene considerato da Prelevare ( ed In Transito ) invece che Mancante",
            },
            // Yes Tablet
            ["v0191"] = new[]
            {
                "1 - LISTE MGAUT: Ora tutte le Liste vengono caricate con il Codice Utente di Diapason invece che con il Nome Portale ( codice interno )",
                "2 - ACCETTAZIONE: Ora è presente anche il Magazzino MIMO004, e si può anche filtrare per esso",
            },
            // No Tablet
            ["v0192"] = new[]
            {
                "1 - Bugfix: L'opzione del Profilo [ Popup Ristampa Etichetta ] ora viene salvata correttamente nel dispositivo",
                "2 - PRELIEVO MANUALE: Se il Magazzino di Destinazione è MGH0001, viene pre-impostato il vano UFFICIO come vano di Default",
            },
            // Yes Tablet
            ["v0193"] = new[]
            {
                "1 - ACCETTAZIONE: Gli ultimi Articoli caricati vengono visualizzati in cima alla lista ( gli elementi vengono inseriti con .unshift invece che .push )",
                "2 - ACCETTAZIONE: Invertite l'icona [ Stampa / Aggiungi ] con quella [ Mov / Q.tà ] => evita di cliccare per sbaglio la freccia e scorrere la lista invece che aggiungere un Articolo ) ",
                "3 - ACCETTAZIONE: Aggiunto un Popup di Conferma quando si preme X su un elemento della Lista di Carico",
                "4 - IMPEGNO ODL: Rimossa la schermata di Conferma (che non faceva proseguire con l'impegno) quando si faceva l'UPD di un Articolo (caso raro)",
            },
            // Yes Tablet
            ["v0194"] = new[]
            {
                "1 - LISTE / IMPEGNI 0027: Ora l'Utente che ha fatto un impegno viene notificato quando l'Articolo è arrivato al Magazzino MGAUT01, invece che al MGAUT02",
                "2 - ACCETTAZIONE: Adesso per entrare nella sezione ACCETTAZIONE, e creare una LISTA DI CARICO, devi specificare il Magazzino di Ricerca. Check addizionali per le Liste di Pre-Carico (MG00020 e MGPUL01)",
                "3 - ACCETTAZIONE: Le informazioni presenti nella LISTA DI CARICO sono state riordinate, in modo da non premere più le freccie in modo accidentale",
            },
            // No Tablet
            ["v0195"] = new[]
            {
                "1 - IMPEGNO ODL: Ora le Attività inviate con Magazzino: Nessuno sono state fixate ( Vengono inviate con il Magazzino corretto ). Con il Magazzino corretto, esse possono essere caricate dalla sezione 27/34. Risolve inoltre il problema del DEL che non cancellava quelle Attività",
                "2 - MGAUT 27/34: Ora tenendo premuto il pulsante 27/34: viene forzato il caricamento di tutte le Liste di Prelievo 27/34 dalle Attività (c'è scritto anche su Info)",
                "3 - OTTIMIZZAZIONI (lato server): Ora la maggior parte delle Query sono più veloci (Fino a 3 volte più veloci)",
            },
            // No Tablet
            ["v0196"] = new[]
            {
                "1 - IMPEGNO ODL ( Hotfix ): Se il Magazzino di Destinazione è Nessuno ( e non viene nemmeno Rilevato automaticamente ): verrà richiesto l'Input del Magazzino all'Utente",
                "2 - INVENTARIO: Nuova Versione ( Beta ) => Da Terminare e Debuggare ( Quindi non testata al 100% )",
            },
            // Yes Tablet
            ["v0197"] = new[]
            {
                "1 - INVENTARIO: Numerosi Bugfix",
            },
            // No Tablet
            ["v0198"] = new[]
            {
                "1 - IMPEGNO ODL: Ora anche negli Impegni ODL per la Fase 0034 c'è il check della Giacenza su: MGAUT00/10 o MISK",
                "2 - IMPEGNO ODL: La Fase 0027 / 0034 ora viene gestita in modo prioritario SOLAMENTE se l'impegno viene eseguito da APP ( non da Diapason ). Inoltre ora viene creata una Attività anche quando si fa un UPD.",
                "3 - MGAUT 27/34: Ora le Liste vengono caricate solo dalle Attività",
                "4 - RIENTRI: Aggiunta la possibilità di effettuare un Movimento verso MGB180",
            },
            // No Tablet
            ["v0199"] = new[]
            {
                "1 - STAMPE ETICHETTE: Fix per la Data nella Stampa delle Etichette",
                "2 - Altri fix minori",
            },
            // No Tablet (hotfix)
            ["v1000"] = new[]
            {
                "HOTFIX [ INVENTARIO ] => Ora è possibile aggiungere Articoli non trovati nelle Liste: [ Vano - Radice ]",
                "1 - PRELIEVI / MANCANTI: Fix delle descrizioni per alcuni Articoli che (raramente) facevano crashare il programma durante la scrittura negli storici",
                "2 - MGAUT02: Ora vengono segnate anche le qtà confermate di ogni singolo articolo (aiuta ad identificare eventuali errori nelle liste)",
                "3 - CERCA: Abilitazione al Listino per tutti i CAP%",
                "4 - CERCA: La lista delle Esplosioni / Implosioni ora sono ordinate per POS",
                "5 - MGAUT 27/34: Se non ci sono liste attive, ora viene visualizzata la scritta: Non ci sono Liste ( invece di un Alert bloccante )",
                "6 - MGAUT 27/34: Fix ( non testato ) per quando viene inviata una Lista quando il server è offline ( ricorsione )",
            },
            // Yes Tablet (hotfix)
            ["v1001"] = new[]
            {
                "HOTFIX [ INVENTARIO ] => Funzionalità offline dell'inventario. Se sei offline: le seguenti richieste verranno salvate e riprese quando torni online: Conferma Articolo, Rimuovi dai Confermati, Modifica Quantità, Aggiungi Articolo ( non trovato ) e Carica Foto",
                "HOTFIX [ INVENTARIO ] => Ora viene visualizzato chi ha creato la lista",
                "HOTFIX [ INVENTARIO ] => Rimuovi dai confermati NON resetta più lo scroll tornando in cima alla lista",
                "HOTFIX [ INVENTARIO ] => Filtro per Articolo (anche parziale) all'interno dell'inventario (nel caso servisse cercare uno o più articoli specifici)",
                "HOTFIX [ INVENTARIO ] => Le FRECCE (per tornare all'inizio della Lista, oppure per arrivare in fondo alla lista) non sono più cliccabili",
                "+ Rimozione di alcune API vecchie",
            },
            // Yes Tablet
            ["v1002"] = new[]
            {
                "Aggiornamento per supportare il nuovo magazzino virtuale MGAUT03",
            },
            // Yes Tablet
            ["v1003"] = new[]
            {
                "1 - È stato creato un nuovo tipo di Utente nell'app => Utente Qualità",
                "2 - PRE-CARICO: Gli Utenti Qualità sono stati abilitati al Pre-carico, con Magazzino di Default MGCQ001, EN-W invece che EN-X, ed alcune restrizioni",
                "3 - QUALITA: Nuova sezione per la gestione dei codici R ( dentro Produzione ) per gli Utenti Qualità",
                "4 - ACCETTAZIONE: Se un codice R ( con bolla ) non è stato Confermato dal Controllo Qualità, la riga apparirà in Arancione (altrimenti: in Verde)",
                "5 - IMPEGNO ODL: Check aggiuntivo per gli Impegni ODL con Magazzino Destinazione: Nessuno",
                "6 - EVIDENZIA TESTO: Ora cambiare il Tipo Tastiera da N a T o viceversa non evidenzia più tutto il testo, quando l'opzione Evidenzia Testo è attiva",
            },
            // Yes Tablet
            ["v1004"] = new[]
            {
                "1 - LOGIN: Il Popup è stato cambiato e ora il campo Password è criptato",
                "2 - PRE-CARICO: Miglioramenti specifici per gli Utenti Qualità ( Es: aggiunta Articolo da lista pre-popolata, arm obbligatori ecc )",
                "3 - PRE-CARICO: Tutti gli utenti generici ora possono accedere e creare delle Liste (con limitazioni). Vengono registrate come CPR006",
                "4 - ACCETTAZIONE: Possibilità di Stampare le Etichette anche sulla stampante Booster tramite Popup",
                "5 - LISTE 0027/34: Se il Magazzino di Origine è null (perchè è stato creato un impegno da giacenza MISK) non viene visualizzato nella Lista 27/34 (va gestito manualmente)",
                "6 - IMPEGNO ODL: Check estremamente migliorato (per gli Impegni ODL con Magazzino Destinazione: Nessuno)",
                "7 - Fix minori e grafici",
            },
            // No Tablet
            ["v1005"] = new[]
            {
                "1 - MANCANTI CODICI CC: Nuova sezione ( M. CC ) dentro Attività => visualizza tutti i codici CC mancanti",
                "2 - PRELIEVI: Se si entra in un Magazzino che non ha ordini, si può comunque consultare lo storico (cioè gli Inviati)",
                "3 - PRE-CARICO: Fix minori ed aggiunta del Popup ARM per gli Utenti CQC",
            },
            // Yes Tablet
            ["v1006"] = new[]
            {
                "1 - MODALITA MONITOR TOUCH: Attivando questa opzione dal profilo ( bisogna essere loggati con un utente ) la APP si attiverà in modalità Monitor Touch (cioè senza tastiera)",
                "2 - MANCANTI CODICI CC: Ora è presente un Link a Cerca Articolo",
                "3 - PRE-CARICO: Eliminato il Popup che chiedeva Arm/Nota e inserito Popup per la quantità",
            },
            // Yes Tablet
            ["v1007"] = new[]
            {
                "1 - ACCETTAZIONE: Se viene rimosso un articolo dalla lista di Pre-Carico, esso verrà visualizzato in Rosso. C'è la possibilità di ri-aggiungerlo rapidamente",
                "2 - ACCETTAZIONE: Ora si possono inviare liste di carico (da importazione pre-carico) anche se tutti gli articoli della lista sono rimossi (cioè rossi)",
                "2 - QUALITA: Fix per i nomi delle liste di Pre-Carico per gli Utenti Qualità",
            },
            // Yes Tablet
            ["v1008"] = new[]
            {
                "1 - PRE-CARICO (Qualità): Quando si aggiunge un Articolo alla Lista ( con + ), la Q.tà viene messa come EN-V (e segnata in viola)",
                "2 - PRE-CARICO (Qualità): Fix minori (max-length per il nome della lista a 10, en-v invece che en-w ecc..)",
            },
            // Yes Tablet
            ["v1009"] = new[]
            {
                "1 - Introduzione dell'aggiornamento obbligatorio (verrà utilizzato quando dovrò cambiare il Server)",
            },
            // Yes Tablet ( Next generation Update ) => cambio server
            ["v1100"] = new[]
            {
                "1 - Cambio del Server da 10.O.2.37/mobile a 10.O.1.22/mobile e trasferimento del server 10.O.2.148",
            },
            // ??? Tablet ( After CRASH )
            ["v1117"] = new[]
            {
                "1 - Versione 1.1.17 dell'APP (ricaricata in modalità provvisoria)",
            },
            // Yes Tablet
            ["v2001"] = new[]
            {
                "1 - Versione 2.0.1 dell'APP (funzioni ripristinate all'80%)",
            },
            // No Tablet
            ["v2002"] = new[]
            {
                "1 - Kanban (rifornimento): La lista di rifornimento Kanban ora viene salvata nel dispositivo (localStorage) e non viene più persa al riavvio dell'app",
                "2 - Chat Stream: diminuita la quantità di risorse utilizzata dall'API della chat (ora viene passato l'utente collegato come parametro)",
                "3 - Aggiunta di barre di scorrimento laterali (versione WEB)",
                "4 - Aumento della velocità della Query D.SPE (Destinazione Specifica) su Attività",
                "5 - Fix minori",
            },
            // 26/11/2021 | No Tablet
            ["v2003"] = new[]
            {
                "1 - HOTFIX: Fix per i Toast Android (facevano crashare i telefoni con Android versione 11+)",
            },
            // 21/01/2022 (Tablet con WebView modificato eliminato => ora updateTablet è deprecato)
            ["v2004"] = new[]
            {
                "1 - Ristrutturazione del codice dei Movimenti MGAUT01 (ora funzionano in Background)",
                "2 - Riabilitazione degli IMPEGNI ODL",
                "3 - Fix minori",
            },
            // 27/01/2022
            ["v2005"] = new[]
            {
                "1 - Estensione delle Liste in Background anche ai Prelievi e Mancanti",
                "2 - Miglioramenti e Fix minori per le Liste in Background",
                "3 - Fix aggiornamento APP",
            },
            // 28/01/2022
            ["v2006"] = new[]
            {
                "1 - Le Etichette dei Prelievi e Mancanti ora vengono stampate all'invio dei Movimenti (invece che alla fine)",
            },
            // 01/02/2022
            ["v2007"] = new[]
            {
                "1 - Fix del Popup [Movimenti Bloccati] su Prelievi e Mancanti",
                "2 - Se 1 solo Articolo di una lista Prelievi o Mancanti da Errore, viene subito visualizzata l'icona ⚠️ nella tab INVIATI",
                "3 - Miglioramento e Pulizia del codice della Stampa delle Etichette (Zebra Bluetooth)",
                "4 - Aggiunta degli Impegni MISK nella sezione 27/34 (in arancione)",
            },
            // 02/02/2022
            ["v2008"] = new[]
            {
                "1 - Miglioramenti alla funzione Movimento Singolo (Non da più errore in caso di disconnessione - come le liste in background)",
            },
            // 23/02/2022
            ["v2009"] = new[]
            {
                "1 - Lo scroll della Lista viene salvato quando fai l'invio di un Prelievo o di un Mancante",
                "2 - Nel popup Prelievi e Mancanti, il Codice Articolo e l'ODL vengono visualizzati come cliccabli (risolve il problema di accessibilità della clessidra)",
            },
            // 08/03/2022
            ["v2010"] = new[]
            {
                "1 - La gestione dei permessi della sezione Pre-Carico è stata cambiata da Client-Side a Server-Side (e aggiunta del CPR026)",
            },
            // 06/04/2022
            ["v2011"] = new[]
            {
                "1 - Aggiunta la possibilità di Caricare una Foto (da Cerca Articolo) direttamente su Arxivar",
                "2 - Aggiunta la sezione -Pallinatura- per: scattare una Foto (ed editarla con Annotium) ed inviarla alla cartella /pallinatura/n.cognome",
            },
            // 07/04/2022
            ["v2012"] = new[]
            {
                "1 - Eliminato il pulsante [Storico] della Pallinatura. Ora i bottoni sono: [Fotocamera] [Galleria] e [Upload]",
                "2 - Se cerchi un codice articolo (senza internet) il sistema ti avvisa che non hai nessuna connessione ad internet",
            },
            // 13/04/2022
            ["v2013"] = new[]
            {
                "1 - PALLINATURA: Aggiunta la possibilità di scattare una Foto ed editarla con Google Foto (o di aprire direttamente la Galleria di Google Foto)",
            },
            // 10/04/2026
            ["v2015"] = new[]
            {
                "1 - Cambiato il peso lordo con il peso netto e la gestione della pagina Accettazione",
            },
            // 29/05/2026
            ["v2016"] = new[]
            {
                "1 - Fix impegni odl: aggiunta articolo non funzionava più",
            },
        };
    }
}
