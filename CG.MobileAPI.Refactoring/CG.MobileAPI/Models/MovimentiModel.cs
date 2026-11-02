using System.Globalization;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;

namespace CG.MobileAPI.Models
{
    // -----------------------------------------------------------------------------------------------------------------
    // --- Richieste ---------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Richiesta di un movimento singolo di magazzino (ex api/APIMovMagMobileApp.php).
    /// L'utente Diapason che esegue il movimento è quello del token (il campo <c>id</c> del PHP non è più usato).
    /// </summary>
    public class APIMovMagMobileAppRequest
    {
        /// <summary>Articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Causale: TNAV2, UR1 o UNA.</summary>
        public string? causale { get; set; }
        /// <summary>Magazzino di origine.</summary>
        public string? damag { get; set; }
        /// <summary>Magazzino di destinazione (nei movimenti UNA è il centro di costo).</summary>
        public string? amag { get; set; }
        /// <summary>Quantità.</summary>
        public string? qta { get; set; }
        /// <summary>Vano di origine.</summary>
        public string? davano { get; set; }
        /// <summary>Vano di destinazione.</summary>
        public string? avano { get; set; }
        /// <summary>ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Commessa.</summary>
        public string? commessa { get; set; }
        /// <summary>Nota.</summary>
        public string? nota { get; set; }
        /// <summary>Fase dell'ODL (vuota = ricavata dall'ODL).</summary>
        public string? fase { get; set; }
        /// <summary>Ignorato: la società del movimento è quella del token (ex campo societa di APIMovMagMobileApp[IMM].php).</summary>
        public string? societa { get; set; }
    }

    /// <summary>
    /// Riga di una lista per il magazzino automatico (elemento di <c>listaPrelievi</c>).
    /// </summary>
    public class RigaListaMagazzinoAutomatico
    {
        /// <summary>Articolo.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? articolo { get; set; }
        /// <summary>Quantità (numero o stringa).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? qta { get; set; }
        /// <summary>Unità di misura.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? umis { get; set; }
        /// <summary>Vano di prelievo (PRELMAN / PRELODL / PRELKAN; vuoto = "?").</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? vanoto { get; set; }
        /// <summary>Posizione dell'ODV (solo PRELODV).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? pos { get; set; }
        /// <summary>Sequenza nella posizione dell'ODV (solo PRELODV).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? seq { get; set; }
    }

    /// <summary>
    /// Richiesta di invio di una lista al magazzino automatico (ex api/WriteListaMagazzinoAutomatico.php).
    /// L'utente Diapason è quello del token (il campo <c>utente</c> del PHP non è più usato).
    /// </summary>
    public class WriteListaMagazzinoAutomaticoRequest
    {
        /// <summary>PRELMAN, PRELODL, PRELODV, PRELKAN, CAR o CARPRT.</summary>
        public string? tipo_interfaccia { get; set; }
        /// <summary>Magazzino di origine.</summary>
        public string? magazzino_origine { get; set; }
        /// <summary>Magazzino di destinazione (per CARPRT è l'id di carico).</summary>
        public string? magazzino_destinazione { get; set; }
        /// <summary>ODL (o ODV / magazzino KANBAN).</summary>
        public string? odl { get; set; }
        /// <summary>Fase (o scaffale KANBAN).</summary>
        public string? fase { get; set; }
        /// <summary>Nota (opzionale).</summary>
        public string? nota { get; set; }
        /// <summary>Righe della lista (ex JSON nel campo <c>listaPrelievi</c>).</summary>
        public List<RigaListaMagazzinoAutomatico>? listaPrelievi { get; set; }
    }

    /// <summary>
    /// Dati generali dell'invio multiplo (ex campo JSON <c>dataObject</c>).
    /// </summary>
    public class DataObjectMovimentiMultipli
    {
        /// <summary>Id dell'invio, chiave di api_sse_responses (lo stesso usato dallo stream SSE).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? id_api { get; set; }
        /// <summary>Nome della lista.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? nome_lista { get; set; }
        /// <summary>Sezione: mgaut01, prelievi, mancanti o mov_singolo.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))]
        public string? sezione { get; set; }
    }

    /// <summary>
    /// Movimento dell'invio multiplo (elemento di <c>movimenti</c>, classe MovimentoAPI dell'app).
    /// I valori possono arrivare come numeri o stringhe: sono letti come stringhe, come faceva PHP.
    /// </summary>
    public class MovimentoMultiplo
    {
        /// <summary>Causale (TNAV2, UR1, UNA).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? causale { get; set; }
        /// <summary>Ignorato: la società del movimento è quella del token.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? societa { get; set; }
        /// <summary>Articolo.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? articolo { get; set; }
        /// <summary>Quantità.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? qta { get; set; }
        /// <summary>Magazzino di origine.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? damag { get; set; }
        /// <summary>Vano di origine.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? davano { get; set; }
        /// <summary>Magazzino di destinazione.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? amag { get; set; }
        /// <summary>Vano di destinazione.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? avano { get; set; }
        /// <summary>ODL.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? odl { get; set; }
        /// <summary>Commessa.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? commessa { get; set; }
        /// <summary>Nota.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? nota { get; set; }

        /// <summary>Riferimento prelievo (mgaut01).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? rifprel { get; set; }
        /// <summary>Sotto-riferimento prelievo (mgaut01; è anche la fase inviata a Diapason).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? subrifprel { get; set; }
        /// <summary>Sequenza prelievo (mgaut01, numerica).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? seqprel { get; set; }
        /// <summary>Sequenza (mgaut01, numerica).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? seq { get; set; }

        /// <summary>Data run (prelievi / mancanti, numerica).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? dtrun { get; set; }
        /// <summary>Ora run (prelievi / mancanti, numerica).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? hrrun { get; set; }
        /// <summary>Articolo padre.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? padre { get; set; }
        /// <summary>Descrizione del padre.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? des_padre { get; set; }
        /// <summary>Descrizione dell'articolo.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? descarticolo { get; set; }
        /// <summary>Peso lordo.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? pesol { get; set; }
        /// <summary>Descrizione del colore.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? desccolore { get; set; }
        /// <summary>Fase.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? fase { get; set; }
        /// <summary>Data fabbisogno (yyyyMMdd).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? fabbdate_integer { get; set; }
        /// <summary>Fornitore dell'ultima disponibilità.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? nomefornlastdispo { get; set; }
        /// <summary>Numero bolla dell'ultima disponibilità.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? bollanolastdispo { get; set; }
        /// <summary>Data bolla dell'ultima disponibilità.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? bolladtlastdispo { get; set; }
        /// <summary>Descrizione della fase.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? descrizionefase { get; set; }
        /// <summary>Unità di misura.</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? umis { get; set; }
        /// <summary>Posizione (numerica).</summary>
        [JsonConverter(typeof(MovimentiValoreConverter))] public string? pos { get; set; }
    }

    /// <summary>
    /// Richiesta di esecuzione di più movimenti in background (ex api/WriteMovimentiMultipliAPI.php).
    /// L'utente dei movimenti è quello del token (i campi <c>utente</c> del PHP non sono più usati).
    /// </summary>
    public class WriteMovimentiMultipliAPIRequest
    {
        /// <summary>Dati generali (ex JSON nel campo <c>dataObject</c>).</summary>
        public DataObjectMovimentiMultipli? dataObject { get; set; }
        /// <summary>Movimenti (ex JSON nel campo <c>movimenti</c>).</summary>
        public List<MovimentoMultiplo>? movimenti { get; set; }
    }

    /// <summary>
    /// Legge un valore JSON scalare (stringa, numero, booleano, null) come stringa, come faceva PHP con
    /// <c>json_decode</c> + interpolazione: i numeri decimali con la rappresentazione più breve, true = "1", false = "".
    /// </summary>
    public class MovimentiValoreConverter : JsonConverter<string?>
    {
        /// <inheritdoc/>
        public override bool HandleNull => true;

        /// <inheritdoc/>
        public override string? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            switch (reader.TokenType)
            {
                case JsonTokenType.String:
                    return reader.GetString();
                case JsonTokenType.Number:
                    if (reader.TryGetInt64(out var intero)) return intero.ToString(CultureInfo.InvariantCulture);
                    return reader.GetDouble().ToString(CultureInfo.InvariantCulture);
                case JsonTokenType.True:
                    return "1";
                case JsonTokenType.False:
                    return "";
                case JsonTokenType.Null:
                    return null;
                default:
                    throw new JsonException("Valore scalare atteso");
            }
        }

        /// <inheritdoc/>
        public override void Write(Utf8JsonWriter writer, string? value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value);
        }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // --- Data class --------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Accesso ai dati per movimenti di magazzino verso Diapason.
    /// </summary>
    public class DBMOVIMENTI
    {
        /// <summary>Risposta di Diapason a un movimento eseguito correttamente.</summary>
        public const string MOVIMENTO_ESEGUITO = "0043I IL MOVIMENTO DI MAGAZZINO E'STATO ESEGUITO";

        /// <summary>Risposta iniziale in api_sse_responses (lista già completata da un altro operatore).</summary>
        private const string DEFAULT_RESPONSE = "Questa Lista è già stata completata da un altro operatore";

        private static readonly string[] SEZIONI = { "mgaut01", "prelievi", "mancanti", "mov_singolo" };

        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBMOVIMENTI"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBMOVIMENTI(MobileConnections conn)
        {
            _conn = conn;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- APIMovMagMobileApp --------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Esegue un movimento singolo su Diapason (ex api/APIMovMagMobileApp.php) e restituisce la risposta di Diapason.
        /// </summary>
        /// <param name="request">Dati del movimento.</param>
        /// <param name="utente">Codice Diapason dell'utente che esegue il movimento.</param>
        /// <param name="societa">Società del token (CSPRO / IMM00; sostituisce anche APIMovMagMobileAppIMM.php).</param>
        /// <param name="socket">Client del socket Diapason.</param>
        public async Task<string> APIMovMagMobileAppAsync(APIMovMagMobileAppRequest request, string utente, string societa, DiapasonSocket socket)
        {
            if (request == null) throw new MobileException("Richiesta non valida");

            var risposta = await socket.EseguiAsync(new MovimentoDiapason
            {
                Causale = (request.causale ?? "").Trim(),
                Societa = societa,
                Utente = utente,
                Articolo = request.articolo ?? "",
                Qta = request.qta ?? "",
                DaMag = (request.damag ?? "").Trim(),
                DaVano = (request.davano ?? "").Trim(),
                AMag = (request.amag ?? "").Trim(),
                AVano = (request.avano ?? "").Trim(),
                Odl = (request.odl ?? "").Trim(),
                Commessa = (request.commessa ?? "").Trim(),
                Nota = (request.nota ?? "").Trim(),
                Fase = (request.fase ?? "").Trim()
            });
            return risposta.Trim();
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- DBGetARMListMobile --------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Elenco delle ARM degli ultimi due anni dalla replica MDIIReplica (ex api/DBGetARMListMobile.php).
        /// Chiavi: numero ("/" sostituiti da "_"), causale, cliente, data (intero). <c>null</c> se non ci sono ARM.
        /// </summary>
        public List<Dictionary<string, object?>>? DBGetARMListMobile()
        {
            var dataCorrente = int.Parse(DateTime.Now.ToString("yyyyMMdd", CultureInfo.InvariantCulture)) - 20000; // -2 anni

            const string query = @"SELECT TBLARM.ID_ARM AS NUMERO, TBLCAUSALIARM.DESCRIZIONE AS CAUSALE, TBLARM.ID_CLIENTE AS CLIENTE, TBLARM.DATACR AS DATA
FROM ARMMANAGER.dbo.TBLARM
INNER JOIN ARMMANAGER.dbo.TBLCAUSALIARM ON TBLARM.ID_CAUSALE = TBLCAUSALIARM.ID_CausaleARM and TBLCAUSALIARM.LINGUA='I'
WHERE TBLARM.DATACR > ?";

            var elenco = new List<Dictionary<string, object?>>();
            foreach (var row in DbHelper.Query(_conn.Db2Replica, query, dataCorrente))
            {
                elenco.Add(new Dictionary<string, object?>
                {
                    ["numero"] = Valore(row, "NUMERO").Trim().Replace("/", "_"),
                    ["causale"] = Valore(row, "CAUSALE").Trim(),
                    ["cliente"] = Valore(row, "CLIENTE").Trim(),
                    ["data"] = PhpInt(Valore(row, "DATA"))
                });
            }

            // Come json_encode di un array mai inizializzato
            return elenco.Count == 0 ? null : elenco;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- WriteListaMagazzinoAutomatico ---------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Invia una lista di prelievo / carico al magazzino automatico tramite il socket Diapason
        /// (ex api/WriteListaMagazzinoAutomatico.php). Restituisce la risposta del socket ("200 ..." = lista creata),
        /// "error" se il socket si chiude senza risposta utile, "500 ..." se la connessione fallisce.
        /// </summary>
        /// <param name="request">Dati della lista.</param>
        /// <param name="utente">Codice Diapason dell'utente che crea la lista.</param>
        /// <param name="societa">Società del token.</param>
        /// <param name="settings">Impostazioni del socket Diapason.</param>
        /// <param name="logger">Logger (al posto del file PrelieviLogs).</param>
        public async Task<string> WriteListaMagazzinoAutomaticoAsync(WriteListaMagazzinoAutomaticoRequest request, string utente,
            string societa, DiapasonSettings settings, ILogger logger)
        {
            if (request == null) throw new MobileException("Richiesta non valida");

            societa = CampoSocket(societa, "societa");
            var tipo = request.tipo_interfaccia ?? "";
            var nota = request.nota ?? "";
            var lista = request.listaPrelievi ?? new List<RigaListaMagazzinoAutomatico>();

            // I campi sono separati da spazi e le righe da CRLF: niente spazi o caratteri di controllo nei valori
            utente = CampoSocket(utente, "utente");
            var magOri = CampoSocket(request.magazzino_origine, "magazzino_origine");
            var magDes = CampoSocket(request.magazzino_destinazione, "magazzino_destinazione");
            var odl = CampoSocket(request.odl, "odl");
            var fase = CampoSocket(request.fase, "fase");
            if (nota.IndexOfAny(new[] { '\r', '\n', '\0' }) >= 0) throw new MobileException("La nota contiene caratteri non validi");

            var port = settings.SocketPort;

            // --- STARTUP + HEADER ---
            var sb = new StringBuilder();
            sb.Append("HELO ").Append(utente).Append("\r\n");

            switch (tipo)
            {
                case "PRELMAN":
                    sb.Append($"PRELMANNEW {societa} {utente} {magOri} {magDes} {nota}\r\n");
                    break;
                case "PRELODL":
                    sb.Append($"PRELODLNEW {societa} {utente} {magOri} {magDes} {odl} {fase} {nota}\r\n");
                    break;
                case "PRELODV":
                    sb.Append($"PRELODVNEW {societa} {utente} {magOri} {magDes} {odl} {nota}\r\n");
                    break;
                case "PRELKAN":
                    sb.Append($"PRELKANNEW {societa} {utente} {magOri} {magDes} {fase} {nota}\r\n");
                    break;
                case "CAR":
                    sb.Append($"CARNEW {societa} {utente} {magOri} {magDes}\r\n");
                    break;
                case "CARPRT":
                    sb.Append($"CARPRT {societa} {magDes}\r\n"); // per convenzione magazzino_destinazione è l'id di carico
                    break;
            }

            // --- BODY ---
            foreach (var riga in lista)
            {
                if (riga == null) continue;
                var articolo = CampoSocket(riga.articolo, "articolo");
                var qta = CampoSocket(riga.qta, "qta").Replace(".", ","); // per gestire i decimali
                var umis = CampoSocket(riga.umis, "umis");

                switch (tipo)
                {
                    case "PRELMAN":
                    case "PRELODL":
                    case "PRELKAN":
                        var vanoto = CampoSocket(riga.vanoto, "vanoto");
                        if (vanoto == "") vanoto = "?";
                        sb.Append($"{tipo}ROW {articolo} {qta} {umis} {vanoto}\r\n");
                        break;
                    case "PRELODV":
                        var pos = CampoSocket(riga.pos, "pos");
                        var seq = CampoSocket(riga.seq, "seq");
                        sb.Append($"{tipo}ROW {pos} {seq} {articolo} {qta} {umis}\r\n");
                        break;
                    case "CAR":
                        sb.Append($"CARROW {articolo} {qta} {umis}\r\n");
                        break;
                }
            }

            // --- END ---
            if (tipo == "CARPRT") sb.Append("QUIT\r\n");
            else sb.Append(tipo).Append("END\r\nQUIT\r\n");

            var comando = sb.ToString();
            logger.LogInformation("Lista magazzino automatico ({Port}):\n{Comando}", port, comando);

            // --- SOCKET WRITE / READ ---
            var response = "error";
            try
            {
                using var client = new TcpClient();
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(settings.SocketTimeoutSeconds));
                await client.ConnectAsync(settings.SocketHost, port, cts.Token);
                using var stream = client.GetStream();

                var bytes = Encoding.Latin1.GetBytes(comando);
                await stream.WriteAsync(bytes, cts.Token);

                var buffer = new byte[2048];
                int letti;
                while ((letti = await stream.ReadAsync(buffer, cts.Token)) > 0)
                {
                    var outStr = Encoding.Latin1.GetString(buffer, 0, letti);
                    logger.LogInformation("Risposta magazzino automatico: {Risposta}", outStr);

                    if (!outStr.StartsWith("2"))
                    {
                        response = outStr;
                        break;
                    }

                    // T è per Test, senno non c'è
                    if (outStr.StartsWith("200 TMAN") || outStr.StartsWith("200 MAN") ||
                        outStr.StartsWith("200 TC") || outStr.StartsWith("200 C") ||
                        outStr.StartsWith("200 TODL") || outStr.StartsWith("200 ODL") ||
                        outStr.StartsWith("200 TODV") || outStr.StartsWith("200 ODV") ||
                        outStr.StartsWith("200 TKAN") || outStr.StartsWith("200 KAN") ||
                        tipo == "CARPRT")
                    {
                        response = outStr;
                        break;
                    }
                }
            }
            catch (Exception ex) when (ex is SocketException || ex is IOException || ex is OperationCanceledException)
            {
                logger.LogError(ex, "Errore di comunicazione con il magazzino automatico");
                return "500 socket_create() failed: reason: " + ex.Message + "\n";
            }

            return response;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- WriteMovimentiMultipliAPI -------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Controlla la richiesta di WriteMovimentiMultipliAPI prima di avviare il lavoro in background
        /// (i campi numerici che il PHP inseriva direttamente nell'SQL devono essere numeri).
        /// </summary>
        public void ValidaMovimentiMultipli(WriteMovimentiMultipliAPIRequest request)
        {
            if (request?.dataObject == null || request.movimenti == null) throw new MobileException("Richiesta non valida");
            var d = request.dataObject;
            if (string.IsNullOrWhiteSpace(d.id_api)) throw new MobileException("id_api obbligatorio");
            if (!SEZIONI.Contains(d.sezione)) throw new MobileException("Sezione non valida");
            if (request.movimenti.Any(m => m == null)) throw new MobileException("Movimento non valido");

            foreach (var m in request.movimenti)
            {
                switch (d.sezione)
                {
                    case "mgaut01":
                        Numero(m.seqprel, "seqprel");
                        Numero(m.seq, "seq");
                        break;
                    case "prelievi":
                    case "mancanti":
                        Numero(m.dtrun, "dtrun");
                        Numero(m.hrrun, "hrrun");
                        Numero(m.pos, "pos");
                        break;
                }
            }
        }

        /// <summary>
        /// Esegue i movimenti dell'invio multiplo (ex api/WriteMovimentiMultipliAPI.php, parte in background):
        /// marca le righe come trasferite / registra lo storico a seconda della sezione, crea la riga di
        /// api_sse_responses e la aggiorna dopo ogni movimento (letta da MovimentiMagazzinoSSE).
        /// Va chiamato dopo <see cref="ValidaMovimentiMultipli"/>.
        /// </summary>
        /// <param name="request">Dati generali e movimenti.</param>
        /// <param name="utente">Codice Diapason dell'utente che esegue i movimenti.</param>
        /// <param name="societa">Società del token (catturata prima di avviare il job in background).</param>
        /// <param name="socket">Client del socket Diapason.</param>
        /// <param name="logger">Logger per gli errori dei singoli movimenti.</param>
        public async Task WriteMovimentiMultipliAPIAsync(WriteMovimentiMultipliAPIRequest request, string utente,
            string societa, DiapasonSocket socket, ILogger logger)
        {
            var d = request.dataObject!;
            var idApi = d.id_api ?? "";
            var nomeLista = d.nome_lista ?? "";
            var sezione = d.sezione ?? "";
            var movimenti = request.movimenti!;

            var movimentiReali = new List<MovimentoMultiplo>();

            switch (sezione)
            {
                // Se il movimento non è già partito (es. 2 persone hanno premuto insieme) lo segno come trasferito
                // e lo aggiungo ai movimenti da fare (se darà errore tornerà trasferito = '0')
                case "mgaut01":
                    foreach (var m in movimenti)
                    {
                        const string querySelect = @"select trasferito from prelautop
where articolo = ? and rifprel = ? and subrifprel = ? and seqprel = ? and seq = ?";
                        var righe = DbHelper.Query(_conn.PgCasagrande, querySelect, ChiavePrelautop(m));
                        if (righe.Count == 0) continue;

                        var trasferito = righe[^1]["trasferito"]?.ToString();
                        if (trasferito == "0")
                        {
                            AggiornaTrasferito(m, "1");
                            movimentiReali.Add(m);
                        }
                    }
                    break;

                // stato_mov: '0' = invio in corso | '1' = errore | '2' = inviato con successo
                case "prelievi":
                case "mancanti":
                    var dataSalvataggio = DataInt();
                    var oraSalvataggio = OraInt();
                    foreach (var m in movimenti)
                    {
                        const string queryStoria = @"insert into storia_mov_mancanti (id_api_sse_responses, odl, padre, desc_padre, articolo, desc_articolo, mag_ori, mag_des, peso_lordo, qta, fase, utente_mov, data_mov, data_salvataggio, ora_salvataggio, dtrun, hrrun, desc_colore, fornitore, bolla_numero, bolla_data, desc_fase, um, vano, pos, sezione) values
(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                        DbHelper.NonQuery(_conn.PgDb1, queryStoria,
                            idApi, m.odl ?? "", m.padre ?? "", m.des_padre ?? "", m.articolo ?? "", m.descarticolo ?? "",
                            m.damag ?? "", m.amag ?? "", PhpFloat(m.pesol), PhpFloat(m.qta), m.fase ?? "", utente,
                            PhpInt(m.fabbdate_integer), dataSalvataggio, oraSalvataggio, Numero(m.dtrun, "dtrun"), Numero(m.hrrun, "hrrun"),
                            m.desccolore ?? "", m.nomefornlastdispo ?? "", m.bollanolastdispo ?? "", m.bolladtlastdispo ?? "",
                            m.descrizionefase ?? "", m.umis ?? "", m.davano ?? "", Numero(m.pos, "pos"), sezione);
                        movimentiReali.Add(m);
                    }
                    break;

                case "mov_singolo":
                    movimentiReali.AddRange(movimenti);
                    break;
            }

            // --- api_sse_responses: segno che ho iniziato i movimenti ---
            var dataInserimento = DataInt();
            const string queryInsert = @"insert into api_sse_responses (id, sezione, movimenti_totali, nome_lista, data_inserimento, ora_inserimento, utente, response) values
(?, ?, ?, ?, ?, ?, ?, ?)";
            DbHelper.NonQuery(_conn.PgDb1, queryInsert, idApi, sezione, movimentiReali.Count, nomeLista, dataInserimento, OraInt(), utente, DEFAULT_RESPONSE);

            // --- Movimenti veri e propri (se falliscono => rimetto trasferito = '0' o equivalente) ---
            var sseResponse = new StringBuilder();
            var riepilogo = "";
            var amag = "";
            var numeroErrori = 0;

            for (var i = 0; i < movimentiReali.Count; i++)
            {
                var m = movimentiReali[i];
                var articolo = m.articolo ?? "";
                amag = m.amag ?? "";

                string rispostaApi;
                try
                {
                    rispostaApi = (await socket.EseguiAsync(new MovimentoDiapason
                    {
                        Causale = m.causale ?? "",
                        Societa = societa,
                        Utente = utente,
                        Articolo = articolo,
                        Qta = m.qta ?? "",
                        DaMag = m.damag ?? "",
                        DaVano = m.davano ?? "",
                        AMag = amag,
                        AVano = m.avano ?? "",
                        Odl = m.odl ?? "",
                        Commessa = m.commessa ?? "",
                        Nota = m.nota ?? "",
                        Fase = m.subrifprel ?? "" // 20260216 - errore TNAV3: manca abbinamento fase
                    })).Trim();
                }
                catch (Exception ex)
                {
                    // Un movimento con dati non validi non blocca gli altri: diventa un errore nel riepilogo
                    logger.LogError(ex, "Movimento {Articolo} dell'invio {IdApi} non eseguito", articolo, idApi);
                    rispostaApi = ex is MobileException ? ex.Message : "500 " + ex.Message;
                }

                var movimentiCompletati = i + 1;
                var trasferitoStatus = "✔️";

                if (rispostaApi != MOVIMENTO_ESEGUITO)
                {
                    trasferitoStatus = "❌";
                    numeroErrori++;

                    switch (sezione)
                    {
                        case "mgaut01":
                            AggiornaTrasferito(m, "0");
                            break;
                        case "prelievi":
                        case "mancanti":
                            UpdatePrelieviMancantiStorico(m, 1, sezione);
                            break;
                    }
                }
                else
                {
                    switch (sezione)
                    {
                        case "prelievi":
                        case "mancanti":
                            UpdatePrelieviMancantiStorico(m, 2, sezione);
                            break;

                        case "mgaut01":
                            // Fase 0027 movimentata con successo => registro il completamento (per la media dei tempi)
                            if (m.subrifprel == "0027")
                            {
                                const string query0027 = @"update inserimenti_fase_0027 set data_completamento = ?, ora_completamento = ?
where articolo = ? and odl = ? and data_completamento = 0";
                                DbHelper.NonQuery(_conn.PgDb1, query0027, DataInt(), OraInt(), articolo, m.rifprel ?? "");
                            }
                            break;
                    }
                }

                sseResponse.Append($"\n{trasferitoStatus} {articolo} ( {m.qta} ) ➔ {rispostaApi}\n");

                // Ultimo movimento
                if (i == movimentiReali.Count - 1)
                {
                    var iText = numeroErrori == 1 ? "e" : "i";
                    riepilogo = $"I Movimenti sono stati Completati con {numeroErrori} Error{iText} ( su {movimentiReali.Count} ). Riepilogo:\n{sseResponse}";

                    // Nel caso del movimento singolo basta la risposta standard dell'API
                    if (sezione == "mov_singolo") riepilogo = rispostaApi;
                }

                const string queryUpdateSse = "update api_sse_responses set response = ?, movimenti_completati = ? where id = ?";
                DbHelper.NonQuery(_conn.PgDb1, queryUpdateSse, riepilogo, movimentiCompletati, idApi);
            }

            // --- Storico (mgaut01) ---
            if (sezione == "mgaut01")
            {
                if (riepilogo == "") riepilogo = DEFAULT_RESPONSE;

                const string queryStorico = @"insert into storico_mov_mgis001 (utente, data, ora, nome_lista, riepilogo_movimento, errori, magazzino_destinazione) values
(?, ?, ?, ?, ?, ?, ?)";
                DbHelper.NonQuery(_conn.PgDb1, queryStorico, utente, dataInserimento, OraInt(), nomeLista, riepilogo, numeroErrori, amag);
            }
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- MovimentiMagazzinoSSE -----------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Stato di un invio multiplo (ex query di api/MovimentiMagazzinoSSE.php): la riga di api_sse_responses
        /// con le colonne del DB, o <c>null</c> se non esiste.
        /// </summary>
        public Dictionary<string, object?>? GetApiSseResponse(string id)
        {
            return DbHelper.QueryFirst(_conn.PgDb1, "select * from api_sse_responses where id = ?", id);
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Funzioni di supporto ------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>Aggiorna lo stato del movimento nello storico mancanti / prelievi (ex updatePrelieviMancantiStorico).</summary>
        private void UpdatePrelieviMancantiStorico(MovimentoMultiplo m, int statoMov, string sezione)
        {
            const string query = @"update storia_mov_mancanti set stato_mov = ?, data_salvataggio = ?, ora_salvataggio = ?
where articolo = ? and odl = ? and fase = ? and dtrun = ? and hrrun = ? and sezione = ?";
            DbHelper.NonQuery(_conn.PgDb1, query, statoMov, DataInt(), OraInt(), m.articolo ?? "", m.odl ?? "", m.fase ?? "",
                Numero(m.dtrun, "dtrun"), Numero(m.hrrun, "hrrun"), sezione);
        }

        /// <summary>Imposta il campo trasferito della riga di prelautop del movimento (mgaut01).</summary>
        private void AggiornaTrasferito(MovimentoMultiplo m, string trasferito)
        {
            const string query = @"update prelautop set trasferito = ?
where articolo = ? and rifprel = ? and subrifprel = ? and seqprel = ? and seq = ?";
            DbHelper.NonQuery(_conn.PgCasagrande, query, new object?[] { trasferito }.Concat(ChiavePrelautop(m)).ToArray());
        }

        /// <summary>Valori della chiave di prelautop: articolo, rifprel, subrifprel, seqprel, seq.</summary>
        private static object?[] ChiavePrelautop(MovimentoMultiplo m)
        {
            return new object?[] { m.articolo ?? "", m.rifprel ?? "", m.subrifprel ?? "", Numero(m.seqprel, "seqprel"), Numero(m.seq, "seq") };
        }

        /// <summary>Data corrente come intero yyyyMMdd (ex (int)date("Ymd")).</summary>
        private static int DataInt() => int.Parse(DateTime.Now.ToString("yyyyMMdd", CultureInfo.InvariantCulture));

        /// <summary>Ora corrente come intero HHmmss (ex (int)date("His")).</summary>
        private static int OraInt() => int.Parse(DateTime.Now.ToString("HHmmss", CultureInfo.InvariantCulture));

        /// <summary>
        /// Valore numerico che il PHP inseriva direttamente nell'SQL: deve essere un numero.
        /// </summary>
        private static object Numero(string? valore, string campo)
        {
            var v = (valore ?? "").Trim();
            if (long.TryParse(v, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out var intero)) return intero;
            if (decimal.TryParse(v, NumberStyles.Float, CultureInfo.InvariantCulture, out var dec)) return dec;
            throw new MobileException($"Valore non numerico nel campo {campo}: '{v}'");
        }

        /// <summary>Conversione (float) di PHP: numero iniziale della stringa, 0 se non numerica.</summary>
        private static decimal PhpFloat(string? valore)
        {
            var v = (valore ?? "").Trim();
            var fine = 0;
            while (fine < v.Length && (char.IsDigit(v[fine]) || (fine == 0 && (v[fine] == '-' || v[fine] == '+')) || v[fine] == '.' || v[fine] == 'e' || v[fine] == 'E'))
            {
                fine++;
            }
            for (var len = fine; len > 0; len--)
            {
                if (decimal.TryParse(v.Substring(0, len), NumberStyles.Float, CultureInfo.InvariantCulture, out var d)) return d;
            }
            return 0;
        }

        /// <summary>Conversione (int) di PHP: intero iniziale della stringa (parte decimale troncata), 0 se non numerica.</summary>
        private static long PhpInt(string? valore)
        {
            var d = PhpFloat(valore);
            if (d > long.MaxValue || d < long.MinValue) return 0;
            return (long)decimal.Truncate(d);
        }

        /// <summary>Valore di una colonna (nome senza distinzione maiuscole/minuscole) come stringa, "" se NULL o assente.</summary>
        private static string Valore(Dictionary<string, object?> row, string colonna)
        {
            foreach (var kv in row)
            {
                if (string.Equals(kv.Key, colonna, StringComparison.OrdinalIgnoreCase)) return kv.Value?.ToString() ?? "";
            }
            return "";
        }

        /// <summary>
        /// Campo di un comando del socket del magazzino automatico: i campi sono separati da spazi e le righe da CRLF,
        /// quindi non sono ammessi spazi interni né caratteri di controllo. Restituisce il valore senza spazi iniziali
        /// e finali ("" se null).
        /// </summary>
        private static string CampoSocket(string? valore, string campo)
        {
            var v = (valore ?? "").Trim();
            if (v.Any(c => char.IsWhiteSpace(c) || char.IsControl(c)))
            {
                throw new MobileException($"Valore non valido nel campo {campo}: '{v}'");
            }
            return v;
        }
    }
}
