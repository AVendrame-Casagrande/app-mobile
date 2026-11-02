using System.Data.Odbc;
using System.Globalization;
using System.Net;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;
using ClosedXML.Excel;

namespace CG.MobileAPI.Models
{
    // -----------------------------------------------------------------------------------------------------------------
    // --- Richieste ---------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Richiesta di addArticoloScaffale.php.
    /// </summary>
    public class AddArticoloScaffaleRequest
    {
        /// <summary>Codice dello scaffale.</summary>
        public string? scaffale { get; set; }
        /// <summary>Codice dell'articolo da aggiungere.</summary>
        public string? codiceArticolo { get; set; }
    }

    /// <summary>
    /// Richiesta di deleteArticoloScaffale.php.
    /// </summary>
    public class DeleteArticoloScaffaleRequest
    {
        /// <summary>Codice dello scaffale.</summary>
        public string? scaffale { get; set; }
        /// <summary>Codice dell'articolo da togliere.</summary>
        public string? codiceArticolo { get; set; }
    }

    /// <summary>
    /// Richiesta di addElencoScaffaliToArticolo.php.
    /// </summary>
    public class AddElencoScaffaliToArticoloRequest
    {
        /// <summary>Codice dell'articolo.</summary>
        public string? codiceArticolo { get; set; }
    }

    /// <summary>
    /// Richiesta di checkKanbanGiacenzeMgaut.php.
    /// </summary>
    public class CheckKanbanGiacenzeMgautRequest
    {
        /// <summary>Codice dell'articolo.</summary>
        public string? codiceArticolo { get; set; }
    }

    /// <summary>
    /// Richiesta di selectArticoliScaffale.php.
    /// </summary>
    public class SelectArticoliScaffaleRequest
    {
        /// <summary>Codice dello scaffale.</summary>
        public string? codiceScaffale { get; set; }
    }

    /// <summary>
    /// Richiesta di selectSingoloArticolo.php (kanban).
    /// </summary>
    public class SelectSingoloArticoloKanbanRequest
    {
        /// <summary>Codice dell'articolo.</summary>
        public string? codiceArticolo { get; set; }
        /// <summary>"true" per aggiungere all'articolo l'elenco degli scaffali.</summary>
        public string? addScaffaliPhp { get; set; }
    }

    /// <summary>
    /// Richiesta di selectSingoloScaffale.php.
    /// </summary>
    public class SelectSingoloScaffaleRequest
    {
        /// <summary>Codice dello scaffale.</summary>
        public string? codiceScaffale { get; set; }
        /// <summary>"true" per restituire una sola riga (LIMIT 1).</summary>
        public string? limitPresent { get; set; }
    }

    /// <summary>
    /// Riga del file Excel di ripristino scorte (elementi di <c>arrayRifornimento</c>).
    /// I valori possono arrivare come stringhe o numeri e vengono scritti così come sono.
    /// </summary>
    public class RigaRipristinoScorte
    {
        /// <summary>Codice articolo.</summary>
        public JsonElement? codice { get; set; }
        /// <summary>Descrizione articolo.</summary>
        public JsonElement? descrizione { get; set; }
        /// <summary>Unità di misura.</summary>
        public JsonElement? unitaMisura { get; set; }
        /// <summary>Pezzi per confezione.</summary>
        public JsonElement? qtaConfezione { get; set; }
        /// <summary>Scorta richiesta.</summary>
        [JsonPropertyName("scorta_richiesta")]
        public JsonElement? scorta_richiesta { get; set; }
        /// <summary>Codice scaffale.</summary>
        public JsonElement? scaffale { get; set; }
        /// <summary>Magazzino.</summary>
        public JsonElement? magazzino { get; set; }
    }

    /// <summary>
    /// Richiesta di sendRipristinoScorteEmail.php.
    /// </summary>
    public class SendRipristinoScorteEmailRequest
    {
        /// <summary>Righe da inviare (ex campo JSON <c>arrayRifornimento</c>).</summary>
        public List<RigaRipristinoScorte>? arrayRifornimento { get; set; }
        /// <summary>Nome e cognome dell'utente che invia la richiesta (oggetto e testo della mail).</summary>
        public string? nomeUtente { get; set; }
    }

    /// <summary>
    /// Articolo di una riga di rifornimento.
    /// </summary>
    public class ArticoloRifornimentoKanban
    {
        /// <summary>Codice articolo.</summary>
        public JsonElement? codice { get; set; }
        /// <summary>Codice fornitore.</summary>
        public JsonElement? fornitore { get; set; }
        /// <summary>Pezzi per confezione (PZCONF).</summary>
        public JsonElement? qtaConfezione { get; set; }
    }

    /// <summary>
    /// Scaffale di una riga di rifornimento.
    /// </summary>
    public class ScaffaleRifornimentoKanban
    {
        /// <summary>Codice scaffale.</summary>
        public JsonElement? codice { get; set; }
    }

    /// <summary>
    /// Riga di rifornimento (elementi di <c>listaRifornimenti</c>).
    /// </summary>
    public class RifornimentoKanban
    {
        /// <summary>Articolo.</summary>
        public ArticoloRifornimentoKanban? articolo { get; set; }
        /// <summary>Scaffale.</summary>
        public ScaffaleRifornimentoKanban? scaffale { get; set; }
        /// <summary>Numero di confezioni (QTACONF).</summary>
        public JsonElement? quantita { get; set; }
        /// <summary>Terminale (letto dalla prima riga).</summary>
        public JsonElement? termid { get; set; }
        /// <summary>Identificativo univoco (letto dalla prima riga).</summary>
        public JsonElement? uniqid { get; set; }
    }

    /// <summary>
    /// Richiesta di writeOrdineRifornimento.php.
    /// </summary>
    public class WriteOrdineRifornimentoRequest
    {
        /// <summary>Righe di rifornimento (ex campo JSON <c>listaRifornimenti</c>).</summary>
        public List<RifornimentoKanban>? listaRifornimenti { get; set; }
    }

    /// <summary>
    /// Richiesta (JSON) di dapiws/UpdateArticolo.php.
    /// </summary>
    public class UpdateArticoloRequest
    {
        /// <summary>Codice utente Diapason (ignorato: si usa l'utente del token).</summary>
        public string? username { get; set; }
        /// <summary>Ignorata: si usa la società del token (CSPRO / IMM00).</summary>
        public string? societa { get; set; }
        /// <summary>Codice articolo (stringa, oppure oggetto con la proprietà <c>articolo</c>).</summary>
        public JsonElement? articolo { get; set; }
        /// <summary>Nuovo peso netto (0 o assente = non modificato).</summary>
        public JsonElement? newPesoNetto { get; set; }
        /// <summary>Nuovo peso lordo (0 o assente = non modificato).</summary>
        public JsonElement? newPesoLordo { get; set; }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // --- Data class --------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Accesso ai dati per kanban e scaffali (ex mobile/server/query/kanban) e aggiornamento pesi articolo
    /// (ex mobile/server/dapiws/UpdateArticolo.php).
    /// </summary>
    public class DBKANBAN
    {
        /// <summary>Destinatario della mail di ripristino scorte (ex sendRipristinoScorteEmail.php).</summary>
        public const string DESTINATARIO_RIPRISTINO_SCORTE = "b.jabbari@casagrandegroup.com";

        /// <summary>Cartella dei file Excel di ripristino scorte (ex <c>../../storage/kanban</c>).</summary>
        public const string CARTELLA_RIPRISTINO_SCORTE = "mobile/server/storage/kanban";

        /// <summary>Ambiente della sessione web service Diapason (stesso JSON prodotto dal PHP).</summary>
        private const string DIAP_ENVIRONMENT =
            "{\"encoding\":\"ISO-8859-1\",\"language\":\"I\",\"layout\":\"GMA;\\/;:;,;.;D;D;A;Y\",\"location\":\"pe2:per:se2:ptf:std\"}";

        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBKANBAN"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBKANBAN(MobileConnections conn)
        {
            _conn = conn;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Scaffali ------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Aggiunge un articolo a uno scaffale (ex addArticoloScaffale.php).
        /// </summary>
        /// <returns>"error" se l'articolo è già nello scaffale, altrimenti "ok".</returns>
        public string AddArticoloScaffale(AddArticoloScaffaleRequest request, string societa)
        {
            var scaffale = Obbligatorio(request?.scaffale, "scaffale");
            var codiceArticolo = Obbligatorio(request?.codiceArticolo, "codiceArticolo");

            var presenti = DbHelper.Query(_conn.Db2,
                @"SELECT CSASCKB.ARTICOLO
                  FROM CSASCKB
                  WHERE CSASCKB.SCAFFALE = ? AND CSASCKB.ARTICOLO = ?",
                scaffale, codiceArticolo);

            if (presenti.Count > 0)
            {
                return "error";
            }

            DbHelper.NonQuery(_conn.Db2,
                @"INSERT INTO CSASCKB (SCAFFALE, SOCIETA, ARTICOLO) VALUES(?, ?, ?)",
                scaffale, societa, codiceArticolo);

            return "ok";
        }

        /// <summary>
        /// Elenco degli scaffali in cui è presente un articolo (ex addElencoScaffaliToArticolo.php).
        /// </summary>
        /// <returns>Lista di { codice, descrizione }.</returns>
        public List<Dictionary<string, object?>> AddElencoScaffaliToArticolo(AddElencoScaffaliToArticoloRequest request, string societa)
        {
            var codiceArticolo = Obbligatorio(request?.codiceArticolo, "codiceArticolo");

            var rows = DbHelper.Query(_conn.Db2Modula,
                @"SELECT CSASCKB.SCAFFALE, CSSCFKB.DESCRIZIONE
                  FROM CSASCKB
                  FULL JOIN DBSAITE ON DBSAITE.MITEM = CSASCKB.ARTICOLO
                  FULL JOIN CSSCFKB ON CSASCKB.SCAFFALE = CSSCFKB.CODICE
                  WHERE DBSAITE.MITEM = ? AND DBSAITE.MCOSC = ?
                  ORDER BY SCAFFALE",
                codiceArticolo, societa);

            return rows.Select(r => new Dictionary<string, object?>
            {
                ["codice"] = T(r, "SCAFFALE"),
                ["descrizione"] = T(r, "DESCRIZIONE")
            }).ToList();
        }

        /// <summary>
        /// Giacenza dell'articolo nei magazzini automatici MGAUT00 e MGAUT10 (ex checkKanbanGiacenzeMgaut.php).
        /// </summary>
        /// <returns>Lista di { magazzino, giacenza }.</returns>
        public List<Dictionary<string, object?>> CheckKanbanGiacenzeMgaut(CheckKanbanGiacenzeMgautRequest request, string societa)
        {
            var codiceArticolo = Obbligatorio(request?.codiceArticolo, "codiceArticolo");

            var rows = DbHelper.Query(_conn.Db2,
                @"SELECT MASAMSL.MLLOC, MASAMSL.MALOHQT/100 AS GIACENTE
                  FROM MASAMSL
                  FULL JOIN DBSAITE ON DBSAITE.MITEM = MASAMSL.MALITEM AND DBSAITE.MCOSC = MASAMSL.MAHCOSC
                  FULL JOIN MASAHED ON MASAMSL.MLLOC = MASAHED.MAHMAG AND MASAHED.MAHCOSC = MASAMSL.MAHCOSC
                  WHERE DBSAITE.MITEM = ? AND MASAMSL.MAHCOSC = ?
                    AND (MASAMSL.MLLOC = 'MGAUT00' OR MASAMSL.MLLOC = 'MGAUT10')
                  GROUP BY MASAMSL.MLLOC, MASAMSL.MALOHQT
                  ORDER BY MASAMSL.MLLOC",
                codiceArticolo, societa);

            return rows.Select(r => new Dictionary<string, object?>
            {
                ["magazzino"] = T(r, "MLLOC"),
                ["giacenza"] = Float(T(r, "GIACENTE"))
            }).ToList();
        }

        /// <summary>
        /// Toglie un articolo da uno scaffale (ex deleteArticoloScaffale.php).
        /// </summary>
        /// <returns>"ok".</returns>
        public string DeleteArticoloScaffale(DeleteArticoloScaffaleRequest request)
        {
            var scaffale = Obbligatorio(request?.scaffale, "scaffale");
            var codiceArticolo = Obbligatorio(request?.codiceArticolo, "codiceArticolo");

            DbHelper.NonQuery(_conn.Db2,
                @"DELETE FROM CSASCKB WHERE CSASCKB.SCAFFALE = ? AND CSASCKB.ARTICOLO = ?",
                scaffale, codiceArticolo);

            return "ok";
        }

        /// <summary>
        /// Elenco di tutti gli scaffali (ex selectAllScaffali.php).
        /// </summary>
        /// <returns>Lista di { codice, descrizione, magazzino, societa }.</returns>
        public List<Dictionary<string, object?>> SelectAllScaffali()
        {
            var rows = DbHelper.Query(_conn.Db2,
                "SELECT CODICE, DESCRIZIONE, MAGAZZINO, SOCIETA FROM CSSCFKB ORDER BY CODICE");

            return rows.Select(r => new Dictionary<string, object?>
            {
                ["codice"] = T(r, "CODICE"),
                ["descrizione"] = T(r, "DESCRIZIONE"),
                ["magazzino"] = T(r, "MAGAZZINO"),
                ["societa"] = T(r, "SOCIETA")
            }).ToList();
        }

        /// <summary>
        /// Articoli presenti in uno scaffale (ex selectArticoliScaffale.php).
        /// </summary>
        /// <returns>Lista di { codice, descrizione, fornitore, qtaConfezione, tipo }.</returns>
        public List<Dictionary<string, object?>> SelectArticoliScaffale(SelectArticoliScaffaleRequest request, string societa)
        {
            var codiceScaffale = Obbligatorio(request?.codiceScaffale, "codiceScaffale");

            var rows = DbHelper.Query(_conn.Db2,
                @"SELECT DBSAITE.MITEM AS ARTICOLO, DBSAITE.MPDSC, CSFORKB.QTACONF, ANSADID.ANINCO, DBSAITE.MTYPN
                  FROM DBSAITE
                  FULL JOIN CSFORKB ON DBSAITE.MITEM = CSFORKB.ARTICOLO
                  FULL JOIN ANSADID ON CSFORKB.FORNITORE = ANSADID.ANCOCO
                  FULL JOIN CSASCKB ON DBSAITE.MITEM = CSASCKB.ARTICOLO
                  WHERE CSASCKB.SCAFFALE = ? AND DBSAITE.MCOSC = ?",
                codiceScaffale, societa);

            return rows.Select(r => new Dictionary<string, object?>
            {
                ["codice"] = T(r, "ARTICOLO"),
                ["descrizione"] = T(r, "MPDSC"),
                ["fornitore"] = T(r, "ANINCO"),
                ["qtaConfezione"] = T(r, "QTACONF"),
                ["tipo"] = T(r, "MTYPN")
            }).ToList();
        }

        /// <summary>
        /// Dati kanban di un articolo (fornitore, confezione, trattamento, scorta minima) ed eventualmente gli scaffali
        /// in cui si trova (ex query/kanban/selectSingoloArticolo.php).
        /// </summary>
        /// <returns>L'articolo con <c>listaScaffali</c>; se l'articolo non esiste solo <c>{ listaScaffali: [] }</c>, come il PHP.</returns>
        public Dictionary<string, object?> SelectSingoloArticolo(SelectSingoloArticoloKanbanRequest request, string societa)
        {
            var codiceArticolo = Obbligatorio(request?.codiceArticolo, "codiceArticolo");
            var addScaffali = Vero(request?.addScaffaliPhp);

            var r = DbHelper.QueryFirst(_conn.Db2,
                @"SELECT DBSAITE.MITEM, DBSAITE.MCOSC, DBSAITE.MPDSC,
                         CSFORKB.FORNITORE, CSFORKB.QTACONF, CSFORKB.IMMAGINE,
                         ANSADID.ANINCO, DBSAITE.MTYPN, DBSAITE.MUTMS, CSDBITA.CSTRASU, CSDBITA.CSCOLOR,
                         COALESCE(DBSADAT.MOPSS, 0) AS SCORTA_MINIMA
                  FROM DBSAITE
                  FULL JOIN CSFORKB ON DBSAITE.MITEM = CSFORKB.ARTICOLO AND DBSAITE.MCOSC = CSFORKB.SOCIETA
                  FULL JOIN ANSADID ON CSFORKB.FORNITORE = ANSADID.ANCOCO AND DBSAITE.MCOSC = ANSADID.ANCOSO
                  FULL JOIN CSDBITA ON DBSAITE.MITEM = CSDBITA.CSITEMA AND DBSAITE.MCOSC = CSDBITA.CSCOSCA
                  FULL JOIN DBSADAT ON DBSAITE.MITEM = DBSADAT.MITEM AND DBSAITE.MCOSC = DBSADAT.MCOSC
                  WHERE DBSAITE.MITEM = ? AND DBSAITE.MCOSC = ?",
                codiceArticolo, societa);

            var articolo = new Dictionary<string, object?>();
            if (r != null)
            {
                articolo["codice"] = T(r, "MITEM");
                articolo["societa"] = T(r, "MCOSC");
                articolo["descrizione"] = T(r, "MPDSC");
                articolo["fornitore"] = T(r, "FORNITORE");
                articolo["fornitoreDescrizione"] = T(r, "ANINCO");
                articolo["qtaConfezione"] = T(r, "QTACONF");
                articolo["immagine"] = T(r, "IMMAGINE");
                articolo["tipo"] = T(r, "MTYPN");
                articolo["trattamento"] = T(r, "CSTRASU");
                articolo["colore"] = T(r, "CSCOLOR");
                articolo["unitaMisura"] = T(r, "MUTMS");
                articolo["scorta_minima"] = Float(T(r, "SCORTA_MINIMA")) / 100;
            }

            var listaScaffali = new List<Dictionary<string, object?>>();
            if (addScaffali)
            {
                var scaffali = DbHelper.Query(_conn.Db2,
                    @"SELECT CSASCKB.SCAFFALE, CSSCFKB.DESCRIZIONE, CSSCFKB.MAGAZZINO
                      FROM CSASCKB
                      FULL JOIN DBSAITE ON DBSAITE.MITEM = CSASCKB.ARTICOLO
                      FULL JOIN CSSCFKB ON CSASCKB.SCAFFALE = CSSCFKB.CODICE
                      WHERE DBSAITE.MTYPN = 'N' AND DBSAITE.MITEM = ?
                        AND CSSCFKB.SOCIETA = CSASCKB.SOCIETA
                        AND DBSAITE.MCOSC = CSASCKB.SOCIETA AND DBSAITE.MCOSC = ?
                      ORDER BY CSASCKB.SCAFFALE",
                    codiceArticolo, societa);

                listaScaffali.AddRange(scaffali.Select(s => new Dictionary<string, object?>
                {
                    ["codiceScaffale"] = T(s, "SCAFFALE"),
                    ["descrizioneScaffale"] = T(s, "DESCRIZIONE"),
                    ["magazzinoScaffale"] = T(s, "MAGAZZINO")
                }));
            }
            articolo["listaScaffali"] = listaScaffali;

            return articolo;
        }

        /// <summary>
        /// Celle (articoli) di uno scaffale con i dati dello scaffale (ex selectSingoloScaffale.php).
        /// </summary>
        /// <returns>Lista di { codice, societa, descrizione, magazzino, codiceArticolo, qtaCella }.</returns>
        public List<Dictionary<string, object?>> SelectSingoloScaffale(SelectSingoloScaffaleRequest request)
        {
            var codiceScaffale = Obbligatorio(request?.codiceScaffale, "codiceScaffale");
            var limit = Vero(request?.limitPresent) ? " LIMIT 1" : "";

            var rows = DbHelper.Query(_conn.Db2,
                @"SELECT CSSCFKB.CODICE, CSSCFKB.SOCIETA, CSSCFKB.DESCRIZIONE, CSSCFKB.MAGAZZINO,
                         CSASCKB.ARTICOLO, CSASCKB.QTACELLA
                  FROM CSASCKB
                  JOIN CSSCFKB ON CSASCKB.SCAFFALE = CSSCFKB.CODICE
                  WHERE SCAFFALE = ?" + limit,
                codiceScaffale);

            return rows.Select(r => new Dictionary<string, object?>
            {
                ["codice"] = T(r, "CODICE"),
                ["societa"] = T(r, "SOCIETA"),
                ["descrizione"] = T(r, "DESCRIZIONE"),
                ["magazzino"] = T(r, "MAGAZZINO"),
                ["codiceArticolo"] = T(r, "ARTICOLO"),
                ["qtaCella"] = T(r, "QTACELLA")
            }).ToList();
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Ripristino scorte e ordini di rifornimento --------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Crea il file Excel di ripristino scorte, lo salva in storage/kanban e lo invia via email al
        /// responsabile (ex sendRipristinoScorteEmail.php).
        /// </summary>
        /// <param name="request">Righe e nome dell'utente richiedente.</param>
        /// <param name="storage">Gestione file del web server.</param>
        /// <param name="email">Invio email.</param>
        /// <returns>"1" se la mail è stata inviata (come <c>echo $email->send()</c>).</returns>
        public async Task<string> SendRipristinoScorteEmailAsync(SendRipristinoScorteEmailRequest request, StorageTool storage, EmailTool email)
        {
            var righe = request?.arrayRifornimento ?? throw new MobileException("arrayRifornimento obbligatorio");
            var nomeUtente = request.nomeUtente ?? "";

            byte[] contenuto;
            using (var wb = new XLWorkbook())
            {
                var sheet = wb.Worksheets.Add("Worksheet");
                string[] colonne = { "A", "B", "C", "D", "E", "F", "G" };
                string[] intestazioni = { "Articolo", "Descrizione", "U.M.", "Q.tà Confezione", "Scorta Richiesta", "Scaffale", "Magazzino" };

                for (int c = 0; c < colonne.Length; c++)
                {
                    StileCorpo(sheet.Cell(colonne[c] + "1"));
                    StileCorpo(sheet.Cell(colonne[c] + "3"));

                    var header = sheet.Cell(colonne[c] + "2");
                    header.Value = intestazioni[c];
                    header.Style.Font.Bold = true;
                    header.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                    header.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                    header.Style.Border.OutsideBorderColor = XLColor.Black;
                }

                for (int i = 0; i < righe.Count; i++)
                {
                    var riga = righe[i] ?? new RigaRipristinoScorte();
                    var n = i + 4;
                    JsonElement?[] valori =
                    {
                        riga.codice, null, riga.unitaMisura, riga.qtaConfezione, riga.scorta_richiesta, riga.scaffale, riga.magazzino
                    };
                    for (int c = 0; c < colonne.Length; c++)
                    {
                        var cell = sheet.Cell(colonne[c] + n);
                        if (c == 1)
                        {
                            cell.Value = UcWords(Testo(riga.descrizione));
                        }
                        else
                        {
                            ImpostaValore(cell, valori[c]);
                        }
                        StileCorpo(cell);
                    }
                }

                sheet.Columns(1, colonne.Length).AdjustToContents();

                using var ms = new MemoryStream();
                wb.SaveAs(ms);
                contenuto = ms.ToArray();
            }

            var adesso = DateTime.Now;
            var dataSalvataggio = int.Parse(adesso.ToString("yyyyMMdd", CultureInfo.InvariantCulture));
            var oraSalvataggio = int.Parse(adesso.ToString("HHmmss", CultureInfo.InvariantCulture));
            var filename = $"Ripristino-Scorte-Kanban-{dataSalvataggio}-{oraSalvataggio}.xlsx";

            await storage.SalvaBytesAsync(contenuto, CARTELLA_RIPRISTINO_SCORTE, filename);

            await email.InviaAsync(
                new[] { DESTINATARIO_RIPRISTINO_SCORTE },
                $"Ripristino Scorte Kanban ({nomeUtente})",
                "Hai ricevuto (in allegato) una nuova richiesta di ripristino scorte Kanban da parte di: " + WebUtility.HtmlEncode(nomeUtente),
                new[] { (filename, contenuto) });

            return "1";
        }

        /// <summary>
        /// Scrive gli ordini di rifornimento kanban: una testata CSORKBT per ogni fornitore e una riga CSORKBR per
        /// ogni articolo (ex writeOrdineRifornimento.php).
        /// </summary>
        /// <returns>L'elenco dei fornitori (senza duplicati) a cui è stato creato un ordine.</returns>
        public List<string> WriteOrdineRifornimento(WriteOrdineRifornimentoRequest request, string societa)
        {
            var listaRifornimenti = request?.listaRifornimenti ?? throw new MobileException("listaRifornimenti obbligatorio");

            // Solo rifornimento kanban interno: nessun ordine ai fornitori
            if (listaRifornimenti.Count == 0)
            {
                return new List<string>();
            }

            // Valida tutte le righe prima di scrivere
            var righe = listaRifornimenti.Select((r, i) =>
            {
                if (r?.articolo == null)
                {
                    throw new MobileException($"Riga {i + 1}: articolo mancante");
                }
                return new
                {
                    fornitore = Testo(r.articolo.fornitore),
                    articolo = Testo(r.articolo.codice),
                    qtaconf = Numero(r.quantita, $"Riga {i + 1}: quantita") ?? throw new MobileException($"Riga {i + 1}: quantita obbligatoria"),
                    // Alcuni pezzi per confezione non sono registrati: in quel caso 0
                    pzconf = Numero(r.articolo.qtaConfezione, $"Riga {i + 1}: qtaConfezione") ?? 0m,
                    scaffale = Testo(r.scaffale?.codice)
                };
            }).ToList();

            var listaRifornitori = righe.Select(r => r.fornitore).Distinct().ToList();

            var termid = Testo(listaRifornimenti[0]!.termid);
            var uniqid = Testo(listaRifornimenti[0]!.uniqid);

            var adesso = DateTime.Now;
            var datacreazione = int.Parse(adesso.ToString("yyyyMMdd", CultureInfo.InvariantCulture));
            var oracreazione = int.Parse(adesso.ToString("HHmmss", CultureInfo.InvariantCulture));

            using var conn = new OdbcConnection(_conn.Db2Modula);
            conn.Open();

            // Una testata per ogni fornitore
            foreach (var fornitore in listaRifornitori)
            {
                var odr = Max(conn, "SELECT MAX(ODR) AS ODR FROM CSORKBT") + 1;

                DbHelper.NonQuery(conn, null,
                    @"INSERT INTO CSORKBT
                      (SOCIETA, ODR, FORNITORE, DTCREAZIONE, HRCREAZIONE, STATO, DTID, HRIT, TERMID, UNIQID)
                      VALUES(?, ?, ?, ?, ?, '', ?, ?, ?, ?)",
                    societa, odr, fornitore, datacreazione, oracreazione, datacreazione, oracreazione, termid, uniqid);
            }

            // Una riga per ogni articolo, collegata all'ultima testata del suo fornitore
            foreach (var r in righe)
            {
                var odr = Max(conn, "SELECT MAX(ODR) AS ODR FROM CSORKBT WHERE FORNITORE = ?", r.fornitore);
                var pos = Max(conn, "SELECT MAX(POS) AS POS FROM CSORKBR WHERE CSORKBR.ODR = ?", odr) + 1;

                DbHelper.NonQuery(conn, null,
                    @"INSERT INTO CSORKBR
                      (SOCIETA, ODR, POS, ARTICOLO, QTACONF, PZCONF, SCAFFALE, COMPLETED)
                      VALUES(?, ?, ?, ?, ?, ?, ?, '0')",
                    societa, odr, pos, r.articolo, r.qtaconf, r.pzconf, r.scaffale);
            }

            return listaRifornitori;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Anagrafica articolo (dapiws) ----------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Aggiorna peso netto e/o lordo di un articolo tramite il web service Diapason GFDARTREPV
        /// (ex dapiws/UpdateArticolo.php): login della sessione WS, chiamata CS_DAPIWS_GFDARTREPV_FN, logout.
        /// </summary>
        /// <param name="request">Articolo e nuovi pesi.</param>
        /// <param name="utente">Codice Diapason dell'utente autenticato (usato per la sessione WS).</param>
        /// <param name="societa">Società del token (usata per la sessione WS al posto di quella del body).</param>
        /// <returns>Il messaggio (fault_string) restituito da Diapason.</returns>
        public string UpdateArticolo(UpdateArticoloRequest request, string utente, string societa)
        {
            if (request == null)
            {
                throw new MobileException("Richiesta non valida");
            }
            var codiceArticolo = CodiceArticolo(request.articolo);
            var pesoNetto = Peso(request.newPesoNetto, "newPesoNetto");
            var pesoLordo = Peso(request.newPesoLordo, "newPesoLordo");
            if (string.IsNullOrWhiteSpace(utente))
            {
                throw new MobileException("Utente non valido");
            }

            using var conn = new OdbcConnection(_conn.Db2);
            conn.Open();

            var password = DbHelper.Query(conn, null,
                "SELECT DECRYPT(oper_cod) FROM diapoper WHERE oper_cod = ?", utente)
                .FirstOrDefault()?.Values.FirstOrDefault()?.ToString() ?? "";

            var ticket = DbHelper.Query(conn, null,
                "SELECT CS_SESSIONWS_LOGIN(?, ?, ?, ?) token FROM sysibm.sysdummy1",
                utente, password, societa, DIAP_ENVIRONMENT)
                .FirstOrDefault()?.Values.FirstOrDefault()?.ToString();

            if (ticket == null)
            {
                throw new MobileException("Login alla sessione web service Diapason non riuscito");
            }

            try
            {
                var dati = new Dictionary<string, object> { ["codice_articolo"] = codiceArticolo };
                if (pesoNetto is decimal netto && netto != 0)
                {
                    dati["peso_netto"] = netto;
                }
                if (pesoLordo is decimal lordo && lordo != 0)
                {
                    dati["peso_lordo"] = lordo;
                }
                var wsdata = JsonSerializer.Serialize(new[] { dati });

                var esito = DbHelper.Query(conn, null,
                    "SELECT fault_code, fault_string FROM TABLE(CS_DAPIWS_GFDARTREPV_FN(?, ?))",
                    ticket, wsdata).FirstOrDefault();

                if (esito == null)
                {
                    return "";
                }

                var faultString = (esito.Values.ElementAtOrDefault(1)?.ToString() ?? "").Trim();
                var faultCode = esito.Values.ElementAtOrDefault(0)?.ToString()?.Trim();
                var ok = decimal.TryParse(faultCode, NumberStyles.Number, CultureInfo.InvariantCulture, out var codice) && codice == 0;
                if (!ok)
                {
                    throw new MobileException(faultString);
                }
                return faultString;
            }
            finally
            {
                try
                {
                    DbHelper.Query(conn, null, "SELECT CS_SESSIONWS_LOGOUT(?) token FROM sysibm.sysdummy1", ticket);
                }
                catch (OdbcException)
                {
                    // Il logout non deve cambiare l'esito dell'aggiornamento: la sessione scade comunque
                }
            }
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Funzioni di supporto ------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>Valore della colonna con trim (null diventa "", come Trim(odbc_result(...)) in PHP).</summary>
        private static string T(Dictionary<string, object?> row, string colonna)
        {
            return row.TryGetValue(colonna, out var v) ? (v?.ToString() ?? "").Trim() : "";
        }

        /// <summary>Conversione numerica come <c>(float)</c> in PHP (0 se non numerico).</summary>
        private static double Float(string valore)
        {
            return double.TryParse(valore, NumberStyles.Float, CultureInfo.InvariantCulture, out var d) ? d : 0;
        }

        /// <summary>Controlla un parametro obbligatorio e restituisce il valore.</summary>
        private static string Obbligatorio(string? valore, string nome)
        {
            if (string.IsNullOrWhiteSpace(valore))
            {
                throw new MobileException($"{nome} obbligatorio");
            }
            return valore;
        }

        /// <summary>Interpreta un flag inviato come stringa ("true" / "1").</summary>
        private static bool Vero(string? valore)
        {
            var v = (valore ?? "").Trim();
            return v.Equals("true", StringComparison.OrdinalIgnoreCase) || v == "1";
        }

        /// <summary>Valore JSON come testo, come lo avrebbe scritto PHP in una stringa (null diventa "").</summary>
        private static string Testo(JsonElement? valore)
        {
            if (valore is not JsonElement e)
            {
                return "";
            }
            return e.ValueKind switch
            {
                JsonValueKind.String => e.GetString() ?? "",
                JsonValueKind.Number => e.GetRawText(),
                JsonValueKind.True => "1",
                JsonValueKind.False or JsonValueKind.Null or JsonValueKind.Undefined => "",
                _ => throw new MobileException("Valore non valido: " + e.GetRawText())
            };
        }

        /// <summary>Valore JSON numerico (numero o stringa numerica); null se assente o vuoto.</summary>
        private static decimal? Numero(JsonElement? valore, string nome)
        {
            var testo = Testo(valore).Trim();
            if (testo == "")
            {
                return null;
            }
            if (!decimal.TryParse(testo, NumberStyles.Float, CultureInfo.InvariantCulture, out var d))
            {
                throw new MobileException($"{nome} non valido");
            }
            return d;
        }

        /// <summary>Peso: decimale maggiore o uguale a zero (accetta anche la virgola decimale); null se assente.</summary>
        private static decimal? Peso(JsonElement? valore, string nome)
        {
            var testo = Testo(valore).Trim().Replace(',', '.');
            if (testo == "")
            {
                return null;
            }
            if (!decimal.TryParse(testo, NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out var d) || d < 0)
            {
                throw new MobileException($"{nome} non valido: deve essere un numero maggiore o uguale a zero");
            }
            return d;
        }

        /// <summary>Codice articolo di UpdateArticolo: stringa o oggetto con la proprietà <c>articolo</c>.</summary>
        private static string CodiceArticolo(JsonElement? articolo)
        {
            JsonElement? valore = articolo;
            if (articolo is JsonElement e && e.ValueKind == JsonValueKind.Object)
            {
                valore = e.TryGetProperty("articolo", out var a) ? a : null;
            }
            var codice = Testo(valore).Trim();
            if (codice == "")
            {
                throw new MobileException("articolo obbligatorio");
            }
            return codice;
        }

        /// <summary>MAX(...) di una query sulla connessione aperta (0 se la tabella è vuota).</summary>
        private static long Max(OdbcConnection conn, string sql, params object?[] valori)
        {
            var v = DbHelper.Query(conn, null, sql, valori).FirstOrDefault()?.Values.FirstOrDefault()?.ToString();
            return decimal.TryParse(v, NumberStyles.Float, CultureInfo.InvariantCulture, out var d) ? (long)d : 0;
        }

        /// <summary>Stile delle celle del corpo del foglio (centrate).</summary>
        private static void StileCorpo(IXLCell cell)
        {
            cell.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
        }

        /// <summary>Scrive nella cella un valore JSON: i numeri come numeri, il resto come testo.</summary>
        private static void ImpostaValore(IXLCell cell, JsonElement? valore)
        {
            if (valore is JsonElement e && e.ValueKind == JsonValueKind.Number && e.TryGetDouble(out var d))
            {
                cell.Value = d;
            }
            else
            {
                cell.Value = Testo(valore);
            }
        }

        /// <summary>Come <c>ucwords()</c> di PHP: maiuscola la prima lettera di ogni parola.</summary>
        private static string UcWords(string testo)
        {
            var sb = new StringBuilder(testo.Length);
            var inizioParola = true;
            foreach (var ch in testo)
            {
                sb.Append(inizioParola ? char.ToUpperInvariant(ch) : ch);
                inizioParola = ch is ' ' or '\t' or '\r' or '\n' or '\f' or '\v';
            }
            return sb.ToString();
        }
    }
}
