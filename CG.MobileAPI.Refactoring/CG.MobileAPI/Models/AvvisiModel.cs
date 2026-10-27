using System.Data.Odbc;
using System.Globalization;
using System.Text.RegularExpressions;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;

namespace CG.MobileAPI.Models
{
    // -----------------------------------------------------------------------------------------------------------------
    // --- Richieste ---------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Richiesta di addInfoAvvisoSpeciale.php.
    /// </summary>
    public class AddInfoAvvisoSpecialeRequest
    {
        /// <summary>Numero ordine (RFNRORD) della bolla a destinazione specifica.</summary>
        public string? id { get; set; }
    }

    /// <summary>
    /// Richiesta di completaAvviso.php: chiave dell'attività da completare.
    /// </summary>
    public class CompletaAvvisoRequest
    {
        /// <summary>Timestamp (ID) dell'attività.</summary>
        public string? timest { get; set; }
        /// <summary>Utente (nome portale, minuscolo) che ha creato l'attività.</summary>
        public string? utente { get; set; }
        /// <summary>Destinatario dell'attività.</summary>
        public string? dest { get; set; }
    }

    /// <summary>
    /// Richiesta di completaAvvisoSpeciale.php. L'utente completante è quello del token.
    /// </summary>
    public class CompletaAvvisoSpecialeRequest
    {
        /// <summary>Numero ordine (RFNRORD).</summary>
        public string? id { get; set; }
        /// <summary>Numero bolla.</summary>
        public string? bolla { get; set; }
        /// <summary>Numero di righe dell'ordine da completare (1..riga).</summary>
        public string? riga { get; set; }
    }

    /// <summary>
    /// Richiesta di eliminaAvviso.php.
    /// </summary>
    public class EliminaAvvisoRequest
    {
        /// <summary>Timestamp (ID) dell'attività.</summary>
        public string? timest { get; set; }
        /// <summary>Utente che ha creato l'attività.</summary>
        public string? utente { get; set; }
    }

    /// <summary>
    /// Richiesta di getAttivitaKeysFromImpegnoOdl.php.
    /// </summary>
    public class GetAttivitaKeysFromImpegnoOdlRequest
    {
        /// <summary>Sezione (es. impegno_odl).</summary>
        public string? sezione { get; set; }
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
        /// <summary>Magazzino.</summary>
        public string? magazzino { get; set; }
        /// <summary>Nuova quantità (usata solo con operazione UPD).</summary>
        public string? qta { get; set; }
        /// <summary>Operazione (UPD aggiorna la quantità dell'attività trovata).</summary>
        public string? operazione { get; set; }
    }

    /// <summary>
    /// Richiesta di modificaAvviso.php.
    /// </summary>
    public class ModificaAvvisoRequest
    {
        /// <summary>Timestamp (ID) dell'attività.</summary>
        public string? timest { get; set; }
        /// <summary>Utente che ha creato l'attività.</summary>
        public string? utente { get; set; }
        /// <summary>Testo dell'attività.</summary>
        public string? avviso { get; set; }
        /// <summary>Destinatario.</summary>
        public string? dest { get; set; }
        /// <summary>Urgente ('0' / '1').</summary>
        public string? urgente { get; set; }
        /// <summary>Scadenza (yyyyMMdd).</summary>
        public string? scadenza { get; set; }
    }

    /// <summary>
    /// Richiesta di selectAllAvvisi.php.
    /// </summary>
    public class SelectAllAvvisiRequest
    {
        /// <summary>Nome portale dell'utente: vede anche le proprie attività con ATTIVO='2'.</summary>
        public string? utente_creazione_portale { get; set; }
    }

    /// <summary>
    /// Richiesta di selectSingoloAvviso.php.
    /// </summary>
    public class SelectSingoloAvvisoRequest
    {
        /// <summary>Timestamp (ID) dell'attività.</summary>
        public string? timest { get; set; }
        /// <summary>Utente che ha creato l'attività.</summary>
        public string? utente { get; set; }
    }

    /// <summary>
    /// Richiesta di startScriptCompletaAvviso0027Mgaut01.php. L'utente completante è quello del token.
    /// </summary>
    public class StartScriptCompletaAvviso0027Mgaut01Request
    {
        /// <summary>Articolo dell'attività 0027.</summary>
        public string? articolo_avviso { get; set; }
        /// <summary>ODL dell'attività 0027.</summary>
        public string? odl_avviso { get; set; }
        /// <summary>Timestamp (ID) dell'attività.</summary>
        public string? timest_avviso { get; set; }
        /// <summary>Utente (nome portale, minuscolo) che ha creato l'attività.</summary>
        public string? utente_avviso { get; set; }
        /// <summary>Codice Diapason del creatore dell'attività (destinatario del messaggio chat).</summary>
        public string? utente_avviso_diapason { get; set; }
        /// <summary>Destinatario dell'attività.</summary>
        public string? dest_avviso { get; set; }
        /// <summary>Testo del messaggio chat inviato al completamento.</summary>
        public string? chat_text { get; set; }
    }

    /// <summary>
    /// Richiesta di uploadAvviso.php.
    /// </summary>
    public class UploadAvvisoRequest
    {
        /// <summary>Timestamp (ID) dell'attività.</summary>
        public string? timest { get; set; }
        /// <summary>Utente creatore (nome portale).</summary>
        public string? utente { get; set; }
        /// <summary>Testo dell'attività.</summary>
        public string? avviso { get; set; }
        /// <summary>Destinatario.</summary>
        public string? dest { get; set; }
        /// <summary>Urgente ('0' / '1').</summary>
        public string? urgente { get; set; }
        /// <summary>Scadenza (yyyyMMdd); 0 = nessuna scadenza (20701231).</summary>
        public string? scadenza { get; set; }
    }

    /// <summary>
    /// Richiesta di writeAttivitaSezione.php.
    /// </summary>
    public class WriteAttivitaSezioneRequest
    {
        /// <summary>Timestamp (ID) dell'attività.</summary>
        public string? timest { get; set; }
        /// <summary>Utente creatore dell'attività.</summary>
        public string? utente { get; set; }
        /// <summary>Sezione (es. impegno_odl).</summary>
        public string? sezione { get; set; }
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
        /// <summary>Quantità.</summary>
        public string? qta { get; set; }
        /// <summary>Magazzino.</summary>
        public string? magazzino { get; set; }
        /// <summary>Variabile libera (es. tipo prelievo).</summary>
        public string? custom_variable { get; set; }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // --- Data class --------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Accesso ai dati per attività / avvisi (ex query/avvisi/*.php).
    /// Le risposte usano dizionari per mantenere le stesse chiavi JSON dei PHP.
    /// </summary>
    public class DBAVVISI
    {
        /// <summary>Scadenza usata quando l'attività non ne ha una (uploadAvviso.php).</summary>
        public const int SCADENZA_NESSUNA = 20701231;

        private static readonly Regex _spaziMultipli = new(@"\s\s+", RegexOptions.Compiled);
        private static readonly Regex _spazi = new(@"\s", RegexOptions.Compiled);

        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBAVVISI"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBAVVISI(MobileConnections conn)
        {
            _conn = conn;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Attività (D60STDDB.CSAVVMAG) ----------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Attività visibili (ex selectAllAvvisi.php): attive ('1') oppure semi-completate ('2') create dall'utente,
        /// non completate, con destinatario, non cancellate e non scadute.
        /// </summary>
        public List<Dictionary<string, object?>> SelectAllAvvisi(string utenteCreazionePortale)
        {
            var dataCorrente = int.Parse(DateTime.Now.ToString("yyyyMMdd"));

            var rows = DbHelper.Query(_conn.Db2,
                @"SELECT * FROM D60STDDB.CSAVVMAG
                  WHERE (D60STDDB.CSAVVMAG.ATTIVO='1' OR (D60STDDB.CSAVVMAG.ATTIVO='2' AND lower(D60STDDB.CSAVVMAG.UTENTE) = ?))
                  AND D60STDDB.CSAVVMAG.COMPLETATO='0' AND D60STDDB.CSAVVMAG.DEST != '' AND D60STDDB.CSAVVMAG.AVVISO != ?
                  AND D60STDDB.CSAVVMAG.SCADENZA >= ?
                  ORDER BY D60STDDB.CSAVVMAG.URGENTE DESC, D60STDDB.CSAVVMAG.SCADENZA DESC, D60STDDB.CSAVVMAG.TIMEST DESC",
                utenteCreazionePortale, "Attività cancellata", dataCorrente);

            return rows.Select(r => new Dictionary<string, object?>
            {
                ["timest"] = Str(r, "TIMEST"),
                ["avviso"] = Str(r, "AVVISO").Replace("'", "`"),
                ["utente"] = Str(r, "UTENTE"),
                ["attivo"] = Str(r, "ATTIVO"),
                ["urgente"] = Str(r, "URGENTE"),
                ["dest"] = Str(r, "DEST"),
                ["scadenza"] = PhpFloat(Str(r, "SCADENZA"))
            }).ToList();
        }

        /// <summary>
        /// Singola attività per chiave (ex selectSingoloAvviso.php).
        /// Se non esiste restituisce una lista vuota (il PHP stampava <c>[]</c>).
        /// </summary>
        public object SelectSingoloAvviso(string timest, string utente)
        {
            var r = DbHelper.QueryFirst(_conn.Db2,
                "SELECT * FROM D60STDDB.CSAVVMAG WHERE TIMEST=? AND UTENTE=? ORDER BY D60STDDB.CSAVVMAG.TIMEST DESC LIMIT 1",
                timest, utente);

            if (r == null)
            {
                return new List<object>();
            }

            return new Dictionary<string, object?>
            {
                ["timest"] = Str(r, "TIMEST"),
                ["avviso"] = Str(r, "AVVISO"),
                ["utente"] = Str(r, "UTENTE"),
                ["attivo"] = Str(r, "ATTIVO"),
                ["urgente"] = Str(r, "URGENTE"),
                ["dest"] = Str(r, "DEST"),
                ["scadenza"] = PhpFloat(Str(r, "SCADENZA")),
                ["completato"] = Str(r, "COMPLETATO")
            };
        }

        /// <summary>
        /// Crea una nuova attività (ex uploadAvviso.php). Scadenza 0 = nessuna scadenza; dall'utente vengono tolti
        /// gli spazi (fix "produzione gen"). Restituisce il numero di righe inserite.
        /// </summary>
        public int UploadAvviso(string timest, string utente, string avviso, string dest, string urgente, int scadenza)
        {
            if (scadenza == 0)
            {
                scadenza = SCADENZA_NESSUNA;
            }

            utente = _spazi.Replace(utente, "");

            return DbHelper.NonQuery(_conn.Db2Modula,
                @"INSERT INTO D60STDDB.CSAVVMAG (TIMEST, AVVISO, UTENTE, ATTIVO, URGENTE, DEST, SCADENZA, COMPLETATO)
                  VALUES(?, ?, ?, '1', ?, ?, ?, '0')",
                timest, avviso, utente, urgente, dest, scadenza);
        }

        /// <summary>
        /// Modifica testo, scadenza, urgenza e destinatario di un'attività (ex modificaAvviso.php).
        /// Restituisce il numero di righe aggiornate.
        /// </summary>
        public int ModificaAvviso(string timest, string utente, string avviso, string dest, string urgente, long scadenza)
        {
            return DbHelper.NonQuery(_conn.Db2Modula,
                @"UPDATE D60STDDB.CSAVVMAG SET D60STDDB.CSAVVMAG.AVVISO=?, D60STDDB.CSAVVMAG.SCADENZA=?, D60STDDB.CSAVVMAG.URGENTE=?, D60STDDB.CSAVVMAG.DEST=?
                  WHERE D60STDDB.CSAVVMAG.TIMEST=? AND lower(D60STDDB.CSAVVMAG.UTENTE)=?",
                avviso, scadenza, urgente, dest, timest, utente);
        }

        /// <summary>
        /// Completa un'attività (ex completaAvviso.php). Restituisce il numero di righe aggiornate.
        /// </summary>
        public int CompletaAvviso(string timest, string utente, string dest)
        {
            return DbHelper.NonQuery(_conn.Db2Modula,
                @"UPDATE D60STDDB.CSAVVMAG SET D60STDDB.CSAVVMAG.COMPLETATO='1'
                  WHERE D60STDDB.CSAVVMAG.TIMEST = ? AND lower(D60STDDB.CSAVVMAG.UTENTE) = ? AND D60STDDB.CSAVVMAG.DEST = ?",
                timest, utente, dest);
        }

        /// <summary>
        /// Elimina un'attività (ex eliminaAvviso.php). Restituisce il numero di righe eliminate.
        /// </summary>
        public int EliminaAvviso(string timest, string utente)
        {
            return DbHelper.NonQuery(_conn.Db2Modula,
                "DELETE FROM D60STDDB.CSAVVMAG WHERE D60STDDB.CSAVVMAG.TIMEST=? AND D60STDDB.CSAVVMAG.UTENTE=?",
                timest, utente);
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Attività 0027 → MGAUT01 (startScriptCompletaAvviso0027Mgaut01.php) ---------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Porta l'attività ad ATTIVO='2': il destinatario non la vede più, chi l'ha creata sì
        /// (prima parte di startScriptCompletaAvviso0027Mgaut01.php).
        /// </summary>
        public int ImpostaAttivitaSemiCompletata(string timest, string utente, string dest)
        {
            return DbHelper.NonQuery(_conn.Db2Modula,
                @"UPDATE D60STDDB.CSAVVMAG SET D60STDDB.CSAVVMAG.ATTIVO='2'
                  WHERE D60STDDB.CSAVVMAG.TIMEST = ? AND lower(D60STDDB.CSAVVMAG.UTENTE) = ? AND D60STDDB.CSAVVMAG.DEST = ?",
                timest, utente, dest);
        }

        /// <summary>
        /// Verifica se l'articolo dell'ODL è entrato (ET-A) su MGAUT01 dopo l'avvio dello script
        /// (controllo periodico di startScriptCompletaAvviso0027Mgaut01.php).
        /// </summary>
        /// <param name="articolo">Articolo dell'attività.</param>
        /// <param name="odl">ODL dell'attività.</param>
        /// <param name="dataOraCreazione">Data e ora di avvio dello script, numerico yyyyMMddHHmmss.</param>
        public bool VerificaTrasferimentoMgaut01(string articolo, string odl, long dataOraCreazione)
        {
            var rows = DbHelper.Query(_conn.Db2Modula,
                @"SELECT TRNITM
                  FROM D60STDDB.MASATRN
                  WHERE D60STDDB.MASATRN.TRNITM = ?
                  AND D60STDDB.MASATRN.TORNUOR = ?
                  AND D60STDDB.MASATRN.TRDATE >= ? AND
                  D60STDDB.MASATRN.TMACO='ET' AND D60STDDB.MASATRN.TUSCO ='A'
                  AND D60STDDB.MASATRN.TMAG = 'MGAUT01'
                  AND D60STDDB.MASATRN.TRNSOC = 'CSPRO'",
                articolo, odl, dataOraCreazione);
            return rows.Count > 0;
        }

        /// <summary>
        /// Completa l'attività 0027 e invia al creatore il messaggio chat di tipo 'avviso_completato'
        /// (parte finale di startScriptCompletaAvviso0027Mgaut01.php). Restituisce l'id del messaggio chat.
        /// </summary>
        public string CompletaAttivita0027(string timest, string utente, string dest, string utenteCompletanteDiapason,
            string utenteAvvisoDiapason, string chatText)
        {
            CompletaAvviso(timest, utente, dest);

            var adesso = DateTime.Now;
            var datacreazione = int.Parse(adesso.ToString("yyyyMMdd"));
            var oracreazione = int.Parse(adesso.ToString("HHmmss"));

            return DbHelper.Scalar(_conn.PgDb1,
                @"insert into public.chat (senderid, receiverid, messaggio, data_invio, ora_invio, tipo_messaggio, url_foto)
                  values (?, ?, ?, ?, ?, 'avviso_completato', '') returning id",
                utenteCompletanteDiapason, utenteAvvisoDiapason, chatText, datacreazione, oracreazione) ?? "";
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Attività per sezione (public.attivita_sezioni) ---------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Collega un'attività a una sezione dell'app, es. un impegno ODL (ex writeAttivitaSezione.php).
        /// Restituisce 'uploaded'.
        /// </summary>
        public string WriteAttivitaSezione(string timest, string utente, string sezione, string articolo, string odl,
            string fase, double qta, string magazzino, string customVariable)
        {
            DbHelper.NonQuery(_conn.PgDb1,
                @"insert into public.attivita_sezioni (timest, utente, sezione, articolo, odl, fase, qta, magazzino, custom_variable)
                  values (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                timest, utente, sezione, articolo, odl, fase, qta, magazzino, customVariable);

            return "uploaded";
        }

        /// <summary>
        /// Chiavi (timest, utente, custom_variable) dell'ultima attività legata all'impegno ODL; con operazione 'UPD'
        /// aggiorna anche la quantità (ex getAttivitaKeysFromImpegnoOdl.php). Restituisce null se non ci sono attività.
        /// </summary>
        public Dictionary<string, object?>? GetAttivitaKeysFromImpegnoOdl(string sezione, string articolo, string odl,
            string fase, string magazzino, double? qta, string operazione)
        {
            var r = DbHelper.QueryFirst(_conn.PgDb1,
                @"select timest,utente,custom_variable from public.attivita_sezioni
                  where sezione=? and articolo=? and odl=? and fase=? and magazzino=? order by timest desc limit 1",
                sezione, articolo, odl, fase, magazzino);

            var timest = r?["timest"]?.ToString() ?? "";
            var utente = r?["utente"]?.ToString() ?? "";

            if (operazione == "UPD")
            {
                if (qta == null)
                {
                    throw new MobileException("Quantità non valida");
                }

                DbHelper.NonQuery(_conn.PgDb1,
                    @"update public.attivita_sezioni set qta=?
                      where timest=? and utente=? and sezione=? and articolo=? and odl=? and fase=? and magazzino=?",
                    qta.Value, timest, utente, sezione, articolo, odl, fase, magazzino);
            }

            if (r == null)
            {
                return null;
            }

            return new Dictionary<string, object?>
            {
                ["timest"] = r["timest"],
                ["utente"] = r["utente"],
                ["custom_variable"] = r["custom_variable"]
            };
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Bolle a destinazione specifica (avvisi speciali, note D60STDDB.OFSAOTX) --------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Bolle a destinazione specifica dell'ultimo anno non ancora completate, ordinate per data
        /// (ex selectAllAvvisiSpeciali.php).
        /// </summary>
        public List<Dictionary<string, object?>> SelectAllAvvisiSpeciali()
        {
            // -1 anno: solo le bolle dell'ultimo anno
            var data = int.Parse(DateTime.Now.ToString("yyyyMMdd")) - 10000;

            using var conn = new OdbcConnection(_conn.Db2);
            conn.Open();

            var rows = DbHelper.Query(conn, null,
                @"SELECT a.RIRIPNO, PTUSER, POAMEND, POSTAT1,RFNRORD,RIDEST,RICOFOR,ANINCO,RIDLVNO,RIDTXAB,RICODART,MPDSC,RIDELUM,RIDLVQT/100 AS QTA,D60STDDB.OfSAOTX.PTCOMM,RFNRPOS
                  FROM D60STDDB.rmsadat a
                  INNER JOIN D60STDDB.DBSAITE b ON a.RICODART=b.mitem AND a.RICOSC=b.mcosc
                  INNER JOIN D60STDDB.ansadid c ON a.ricofor=c.ancoco AND a.RICOSC=c.ancoso
                  INNER JOIN D60STDDB.rmsadac d ON a.RIRIPNO=d.RIRIPNO AND a.RICOSC=d.ricosc
                  INNER JOIN D60STDDB.OFSALIN ON RFNRORD=POORDNO AND RFNRPOS=POORDLN
                  inner JOIN D60STDDB.OfSAOTX ON ptcosc=a.ricosc AND ptuser LIKE RFNRORD CONCAT '000000%' AND pttxtc='IM' AND ptseqt=1
                  WHERE a.RICOSC='CSPRO' AND RITSTLAV='N' AND mtypn<>'N' AND POAMEND=0 AND RIDTXAB>?
                  ORDER BY RFNRORD ASC, RFNRPOS DESC",
                data);

            // Righe già completate (nota IM con PTCOMM che inizia per '#', vedi CompletaAvvisoSpeciale)
            var completati = DbHelper.Query(conn, null,
                "SELECT PTUSER FROM D60STDDB.OFSAOTX WHERE PTCOSC='CSPRO' AND PTTXTC='IM' AND PTSEQT=1 AND PTFUNC = '===' AND LEFT(PTCOMM, 1) = '#' ORDER BY PTUSER")
                .Select(c => Str(c, "PTUSER"))
                .ToList();

            var lista = new List<Dictionary<string, object?>>();
            var lastOrdine = "";

            foreach (var r in rows)
            {
                var ordine = Str(r, "RFNRORD");

                // Per ogni ordine tengo solo la prima riga (RFNRPOS DESC = versione più recente)
                if (lastOrdine == ordine)
                {
                    continue;
                }

                var riga = Str(r, "RFNRPOS");
                lastOrdine = ordine;

                var completato = completati.Any(c =>
                    c.StartsWith(ordine, StringComparison.Ordinal) &&
                    PhpInt(c.Length > 3 ? c[^3..] : c) == PhpInt(riga));

                if (!completato)
                {
                    lista.Add(new Dictionary<string, object?>
                    {
                        ["id"] = ordine,
                        ["bolla"] = Str(r, "RIDLVNO"),
                        ["com"] = Str(r, "PTCOMM"),
                        ["fornitoreDesc"] = Str(r, "ANINCO"),
                        ["data"] = PhpFloat(Str(r, "RIDTXAB")),
                        ["riga"] = PhpFloat(Str(r, "RFNRPOS")),
                        ["articolo"] = Str(r, "RICODART"),
                        ["descrizione"] = Str(r, "MPDSC"),
                        ["qta"] = PhpFloat(Str(r, "QTA")),
                        ["stato"] = Str(r, "POSTAT1")
                    });
                }
            }

            // Ordina per DATA ASC
            return lista.OrderBy(a => (double)a["data"]!).ToList();
        }

        /// <summary>
        /// Righe (note CSPRO/IT) di una bolla a destinazione specifica non ancora completate
        /// (ex addInfoAvvisoSpeciale.php).
        /// </summary>
        public List<Dictionary<string, object?>> AddInfoAvvisoSpeciale(string id)
        {
            var prefisso = id + "000";

            using var conn = new OdbcConnection(_conn.Db2);
            conn.Open();

            var rows = DbHelper.Query(conn, null,
                "SELECT PTUSER,PTCOMM FROM D60STDDB.OFSAOTX WHERE PTUSER LIKE ? AND PTCOSC='CSPRO' AND PTTXTC='IT' AND PTSEQT=1",
                prefisso + "%");

            var lista = new List<Dictionary<string, object?>>();

            foreach (var r in rows)
            {
                var ptuser = Str(r, "PTUSER");

                // Se esiste la nota IM '#...' la riga è già stata completata: non la mostro
                var completata = DbHelper.Query(conn, null,
                    "SELECT PTUSER FROM D60STDDB.OFSAOTX WHERE PTUSER=? AND PTCOSC='CSPRO' AND PTTXTC='IM' AND PTSEQT=1 AND PTFUNC = '===' AND LEFT(PTCOMM, 1) = '#'",
                    ptuser).Count > 0;

                if (!completata)
                {
                    lista.Add(new Dictionary<string, object?>
                    {
                        ["ptuser"] = ptuser,
                        ["ptcomm"] = Str(r, "PTCOMM")
                    });
                }
            }

            return lista;
        }

        /// <summary>
        /// Completa le righe 1..riga di una bolla a destinazione specifica aggiungendo, dove manca, la nota IM
        /// <c>#utente#data#bolla</c> (ex completaAvvisoSpeciale.php).
        /// Restituisce <c>completata</c> seguito da <c>| PTUSER</c> per ogni riga già completata e <c>| n</c>
        /// (righe inserite) per ogni riga completata ora.
        /// </summary>
        public string CompletaAvvisoSpeciale(string id, string bolla, string utente, int riga)
        {
            var datacreazione = DateTime.Now.ToString("yyyyMMdd");
            var newPtcomText = "#" + utente + "#" + datacreazione + "#" + bolla;

            var response = "completata";

            using var conn = new OdbcConnection(_conn.Db2Modula);
            conn.Open();

            for (var i = 1; i <= riga; i++)
            {
                // La testata dell'ordine ha la nota IM PTSEQT=1; nelle righe la nota IM la aggiungo io per dire che è completata
                var esistenti = DbHelper.Query(conn, null,
                    "SELECT PTUSER FROM D60STDDB.OFSAOTX WHERE PTUSER LIKE ? AND PTCOSC='CSPRO' AND PTSEQT=1 AND PTTXTC='IM' AND PTFUNC = '===' AND LEFT(PTCOMM, 1) = '#'",
                    id + "%" + i + "%");

                foreach (var e in esistenti)
                {
                    response += " | " + Str(e, "PTUSER");
                }

                if (esistenti.Count == 0)
                {
                    // ID + numero riga su 6 cifre
                    var idToInsert = id + i.ToString(CultureInfo.InvariantCulture).PadLeft(6, '0');

                    var inserite = DbHelper.NonQuery(conn, null,
                        "INSERT INTO D60STDDB.OFSAOTX (PTUSER, PTCOSC, PTTXTC, PTSEQT, PTCOMM, PTFUNC) VALUES(?, 'CSPRO', 'IM', 1, ?, '===')",
                        idToInsert, newPtcomText);

                    response += " | " + inserite;
                }
            }

            return response;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Mancanti / materiale in arrivo (PostgreSQL casagrande) --------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Componenti CC mancanti degli ODL con l'eventuale ODA e fornitore (ex getMancantiCC.php).
        /// Restituisce le righe della query così come sono.
        /// </summary>
        public List<Dictionary<string, object?>> GetMancantiCC()
        {
            // coalesce => sostituisce eventuali NULL con "" (stringa vuota)
            return DbHelper.Query(_conn.PgCasagrande,
                @"select cs_fabbmanc_odl.numero as odl, cs_fabbmanc_odl_comp.articolo, cast(cs_fabbmanc_odl_comp.qtatot AS float) as qta, cs_fabbmanc_odl_comp.ismancvero, cs_fabbmanc_odl_comp.descarticolo, cs_fabbmanc_odl.articolo as padre, cs_fabbmanc_odl.descarticolo as desc_padre,
                  coalesce(cs_fabbmanc_oda_impcodl.numero, '') as oda, coalesce(cs_fabbmanc_oda.nomefornitore, '') as fornitore, coalesce(cs_fabbmanc_oda.fornitore, '') as codice_fornitore
                  from cs_fabbmanc_odl_comp
                  inner join cs_fabbmanc_odl ON cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero
                  and cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa
                  left join cs_fabbmanc_oda_impcodl ON cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_oda_impcodl.articolo
                  and cs_fabbmanc_odl_comp.seq = cs_fabbmanc_oda_impcodl.seqodl
                  and cs_fabbmanc_odl_comp.societa = cs_fabbmanc_oda_impcodl.societa
                  left join cs_fabbmanc_oda on cs_fabbmanc_oda_impcodl.numero = cs_fabbmanc_oda.numero
                  and cs_fabbmanc_oda_impcodl.pos = cs_fabbmanc_oda.pos and cs_fabbmanc_oda_impcodl.sched = cs_fabbmanc_oda.sched
                  and cs_fabbmanc_oda_impcodl.societa = cs_fabbmanc_oda.societa
                  where cs_fabbmanc_odl_comp.articolo like 'CC%' and cs_fabbmanc_odl_comp.ismancvero != '0'
                  and cs_fabbmanc_odl_comp.societa = 'CSPRO'
                  order by cs_fabbmanc_oda.nomefornitore, cs_fabbmanc_odl_comp.articolo");
        }

        /// <summary>
        /// Bolle fornitore non ancora scaricate con i relativi articoli e il numero di mancanti
        /// (ex getMaterialeInArrivo.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetMaterialeInArrivo()
        {
            var rows = DbHelper.Query(_conn.PgCasagrande,
                @"SELECT cs_bolleriga.bolladt, cs_bolleriga.bollano, cs_soggetti.aninco, cs_bolleriga.pbitem, cs_articoli.mpdsc, cs_bolleriga.pbdlqty, cs_bolleriga.ismancante
                  FROM cs_bolleriga
                  INNER JOIN cs_articoli ON cs_articoli.mcosc = cs_bolleriga.pbcosc AND cs_bolleriga.pbitem = cs_articoli.mitem
                  INNER JOIN cs_soggetti ON cs_bolleriga.pbsupno = cs_soggetti.ancoco
                  WHERE cs_soggetti.ancoso='CSPRO' AND cs_bolleriga.blscaricata='0' AND cs_articoli.mcosc='CSPRO' AND cs_bolleriga.pbcosc='CSPRO'
                  ORDER BY cs_bolleriga.bolladt, cs_bolleriga.bollano, cs_bolleriga.pbitem");

            var lista = new List<Dictionary<string, object?>>();
            Dictionary<string, object?>? bollaCorrente = null;
            long? numeroBollaCorrente = null;

            foreach (var r in rows)
            {
                var bollaNumero = PhpInt(r["bollano"]?.ToString());
                var isMancante = r["ismancante"]?.ToString() == "1";

                if (bollaNumero != numeroBollaCorrente || bollaCorrente == null)
                {
                    numeroBollaCorrente = bollaNumero;
                    bollaCorrente = new Dictionary<string, object?>
                    {
                        ["bolla"] = bollaNumero,
                        ["data"] = PhpInt(r["bolladt"]?.ToString()),
                        ["fornitore"] = _spaziMultipli.Replace(r["aninco"]?.ToString() ?? "", " "),
                        ["listaArticoli"] = new List<Dictionary<string, object?>>(),
                        ["nArticoliMancanti"] = 0
                    };
                    lista.Add(bollaCorrente);
                }

                if (isMancante)
                {
                    bollaCorrente["nArticoliMancanti"] = (int)bollaCorrente["nArticoliMancanti"]! + 1;
                }

                ((List<Dictionary<string, object?>>)bollaCorrente["listaArticoli"]!).Add(new Dictionary<string, object?>
                {
                    ["articolo"] = r["pbitem"],
                    ["descrizione"] = _spaziMultipli.Replace(r["mpdsc"]?.ToString() ?? "", " "),
                    ["qta"] = PhpFloat(r["pbdlqty"]?.ToString()),
                    ["ismancante"] = isMancante
                });
            }

            return lista;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Helper ---------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>Valore della colonna come stringa con trim (Trim(odbc_result(...)) del PHP).</summary>
        private static string Str(Dictionary<string, object?> row, string colonna)
        {
            return (row.TryGetValue(colonna, out var v) ? v?.ToString() ?? "" : "").Trim();
        }

        /// <summary>Conversione <c>(float)</c> di PHP: 0 se la stringa non è numerica.</summary>
        private static double PhpFloat(string? valore)
        {
            return double.TryParse((valore ?? "").Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var d) ? d : 0;
        }

        /// <summary>Conversione <c>(int)</c> di PHP: parte intera, 0 se la stringa non è numerica.</summary>
        private static long PhpInt(string? valore)
        {
            var d = PhpFloat(valore);
            return d is > long.MaxValue or < long.MinValue ? 0 : (long)Math.Truncate(d);
        }
    }
}
