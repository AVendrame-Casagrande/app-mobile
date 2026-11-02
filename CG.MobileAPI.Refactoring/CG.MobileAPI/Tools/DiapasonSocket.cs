using System.Globalization;
using System.Net.Sockets;
using System.Text;
using CG.MobileAPI.Data;
using Microsoft.Extensions.Options;

namespace CG.MobileAPI.Tools
{
    /// <summary>
    /// Dati di un movimento di magazzino da inviare a Diapason.
    /// </summary>
    public class MovimentoDiapason
    {
        /// <summary>Causale: TNAV2 (inviata come TNAV3), UR1 o UNA.</summary>
        public string Causale { get; set; } = "";
        /// <summary>Società del token (CSPRO / IMM00): la imposta il controller, mai il client. Vuota o non gestita = CSPRO.</summary>
        public string Societa { get; set; } = "";
        /// <summary>Codice utente Diapason.</summary>
        public string Utente { get; set; } = "";
        /// <summary>Articolo.</summary>
        public string Articolo { get; set; } = "";
        /// <summary>Quantità (inviata con la virgola decimale).</summary>
        public string Qta { get; set; } = "";
        /// <summary>Magazzino di origine.</summary>
        public string DaMag { get; set; } = "";
        /// <summary>Vano di origine.</summary>
        public string DaVano { get; set; } = "";
        /// <summary>Magazzino di destinazione (per UNA è il centro di costo).</summary>
        public string AMag { get; set; } = "";
        /// <summary>Vano di destinazione.</summary>
        public string AVano { get; set; } = "";
        /// <summary>ODL.</summary>
        public string Odl { get; set; } = "";
        /// <summary>Commessa.</summary>
        public string Commessa { get; set; } = "";
        /// <summary>Nota (ultimo campo, può contenere spazi).</summary>
        public string Nota { get; set; } = "";
        /// <summary>Fase dell'ODL (vuota = ricavata da cs_fabbmanc_odl_comp).</summary>
        public string Fase { get; set; } = "";
    }

    /// <summary>
    /// Client del server socket Diapason dei movimenti di magazzino (ex api/APIMovMag.php, eseguiAPIMovMag).
    /// </summary>
    public class DiapasonSocket
    {
        private readonly DiapasonSettings _settings;
        private readonly MobileConnections _conn;
        private readonly ILogger<DiapasonSocket> _logger;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DiapasonSocket"/>.
        /// </summary>
        public DiapasonSocket(IOptions<MobileSettings> settings, MobileConnections conn, ILogger<DiapasonSocket> logger)
        {
            _settings = settings.Value.Diapason;
            _conn = conn;
            _logger = logger;
        }

        /// <summary>
        /// Fase dell'ODL per l'articolo (ex abbinamentoFase). Restituisce "?" se non trovata.
        /// </summary>
        public string AbbinamentoFase(string societa, string articolo, string odl)
        {
            const string query = @"SELECT cs_fabbmanc_odl_comp.fase
FROM cs_fabbmanc_odl
FULL JOIN cs_fabbmanc_odl_comp ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero) AND (cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa)
WHERE cs_fabbmanc_odl_comp.articolo = ? AND cs_fabbmanc_odl_comp.societa = ? AND cs_fabbmanc_odl_comp.numero = ?";
            var fase = DbHelper.Scalar(_conn.PgCasagrande, query, articolo, societa, odl);
            return string.IsNullOrEmpty(fase) ? "?" : fase;
        }

        /// <summary>
        /// Esegue il movimento e restituisce la risposta di Diapason senza il codice iniziale
        /// ("200 " / "500 "), oppure "500 ..." in caso di errore di connessione.
        /// </summary>
        public async Task<string> EseguiAsync(MovimentoDiapason m)
        {
            var societa = CodiciSocieta.Normalizza(m.Societa);
            var utente = Campo(m.Utente, "");
            var articolo = Campo(m.Articolo, "");
            var damag = Campo(m.DaMag, "");
            var davano = Campo(m.DaVano, "?");
            var amag = Campo(m.AMag, "?");
            var avano = Campo(m.AVano, "?");
            var odl = Campo(m.Odl, "?");
            var commessa = Campo(m.Commessa, "?");
            var nota = string.IsNullOrWhiteSpace(m.Nota) ? "?" : m.Nota.Trim();
            if (nota.IndexOfAny(new[] { '\r', '\n', '\0' }) >= 0)
            {
                throw new MobileException("La nota contiene caratteri non validi");
            }
            var fase = !string.IsNullOrWhiteSpace(m.Fase) ? Campo(m.Fase, "?") : odl == "?" ? "?" : AbbinamentoFase(societa, articolo, odl);

            var qta = (m.Qta ?? "").Trim().Replace(".", ",");
            if (!decimal.TryParse(qta, NumberStyles.Number, new CultureInfo("it-IT"), out _))
            {
                throw new MobileException("Quantità non valida");
            }
            var datamov = DateTime.Now.ToString("yyyyMMdd");

            var causale = (m.Causale ?? "").Trim();
            string comando = causale switch
            {
                "TNAV2" => $"TNAV3 {societa} {utente} {articolo} {datamov} {qta} {damag} {davano} {amag} {avano} {odl} {fase} {commessa} {nota}",
                "UR1" => $"UR1 {societa} {utente} {articolo} {datamov} {qta} {damag} {davano} {odl} {nota}",
                "UNA" => $"UNA {societa} {utente} {articolo} {datamov} {qta} {damag} {commessa} {amag} {nota}",
                _ => throw new MobileException("Causale non valida")
            };

            var port = _settings.SocketPort;
            _logger.LogInformation("Movimento Diapason ({Port}): {Comando}", port, comando);

            try
            {
                using var client = new TcpClient();
                using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(_settings.SocketTimeoutSeconds));
                await client.ConnectAsync(_settings.SocketHost, port, cts.Token);
                using var stream = client.GetStream();
                var buffer = new byte[2048];

                await ScriviAsync(stream, $"HELO {utente}\r\n", cts.Token);
                await stream.ReadAsync(buffer, cts.Token);

                await ScriviAsync(stream, comando + "\r\n", cts.Token);
                await ScriviAsync(stream, "QUIT\r\n", cts.Token);

                var response = "";
                int letti;
                while ((letti = await stream.ReadAsync(buffer, cts.Token)) > 0)
                {
                    var outStr = Encoding.Latin1.GetString(buffer, 0, letti);
                    _logger.LogInformation("Risposta Diapason: {Risposta}", outStr);
                    if (outStr.StartsWith("200 ") || outStr.StartsWith("500 "))
                    {
                        response = outStr.Substring(4);
                    }
                }
                return response == "" ? "500 Undefined error" : response.Trim();
            }
            catch (Exception ex) when (ex is SocketException || ex is IOException || ex is OperationCanceledException)
            {
                _logger.LogError(ex, "Errore di comunicazione con Diapason");
                return "500 socket failed: " + ex.Message;
            }
        }

        /// <summary>
        /// Valore di un campo del comando: senza spazi né caratteri di controllo (separano i campi), default se vuoto.
        /// </summary>
        private static string Campo(string? valore, string seVuoto)
        {
            var v = (valore ?? "").Trim();
            if (v == "") return seVuoto;
            if (v.Any(c => char.IsWhiteSpace(c) || char.IsControl(c)))
            {
                throw new MobileException($"Valore non valido: '{v}'");
            }
            return v;
        }

        private static Task ScriviAsync(NetworkStream stream, string testo, CancellationToken ct)
        {
            var bytes = Encoding.Latin1.GetBytes(testo);
            return stream.WriteAsync(bytes, 0, bytes.Length, ct);
        }
    }
}
