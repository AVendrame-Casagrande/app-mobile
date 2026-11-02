using System.Collections.Concurrent;
using System.Globalization;
using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Attività / avvisi dell'app mobile (ex query/avvisi/*.php): attività tra utenti (CSAVVMAG),
    /// bolle a destinazione specifica, attività legate agli impegni ODL, mancanti CC e materiale in arrivo.
    /// </summary>
    [Route("api/avvisi")]
    [ApiController]
    [Authorize]
    public class AvvisiController : MobileControllerBase
    {
        /// <summary>Risposta di startScriptCompletaAvviso0027Mgaut01 quando il controllo prosegue in background.</summary>
        public const string SCRIPT_IN_ATTESA = "in_attesa";

        /// <summary>Intervallo tra due controlli del trasferimento su MGAUT01 (sleep(60) del PHP).</summary>
        private static readonly TimeSpan INTERVALLO_CONTROLLO_0027 = TimeSpan.FromMinutes(1);

        /// <summary>Numero massimo di controlli (counter_ricorsione &gt; 6000 = circa 4+ giorni).</summary>
        private const int MAX_RICORSIONI_0027 = 6000;

        /// <summary>Job 0027 in corso, per non avviarne due sulla stessa attività.</summary>
        private static readonly ConcurrentDictionary<string, byte> _jobs0027 = new();

        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IHostApplicationLifetime _lifetime;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="AvvisiController"/>.
        /// </summary>
        public AvvisiController(MyDbContext db2Connection, ILogger<AvvisiController> logger,
            IServiceScopeFactory scopeFactory, IHostApplicationLifetime lifetime)
            : base(db2Connection, logger, "AVVISI")
        {
            _scopeFactory = scopeFactory;
            _lifetime = lifetime;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Attività ------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Attività visibili all'utente (ex selectAllAvvisi.php).
        /// </summary>
        [HttpPost("selectAllAvvisi")]
        public IActionResult SelectAllAvvisi([FromBody] SelectAllAvvisiRequest request)
        {
            return Esegui("SelectAllAvvisi", () =>
                _db2Connection.DBAVVISI.SelectAllAvvisi(request?.utente_creazione_portale ?? ""));
        }

        /// <summary>
        /// Singola attività per chiave timest/utente (ex selectSingoloAvviso.php); <c>[]</c> se non esiste.
        /// </summary>
        [HttpPost("selectSingoloAvviso")]
        public IActionResult SelectSingoloAvviso([FromBody] SelectSingoloAvvisoRequest request)
        {
            return Esegui("SelectSingoloAvviso", () => _db2Connection.DBAVVISI.SelectSingoloAvviso(
                Obbligatorio(request?.timest, "timest"),
                Obbligatorio(request?.utente, "utente")));
        }

        /// <summary>
        /// Crea un'attività (ex uploadAvviso.php). Restituisce il numero di righe inserite.
        /// </summary>
        [HttpPost("uploadAvviso")]
        public IActionResult UploadAvviso([FromBody] UploadAvvisoRequest request)
        {
            return Esegui("UploadAvviso", () => _db2Connection.DBAVVISI.UploadAvviso(
                Obbligatorio(request?.timest, "timest"),
                Obbligatorio(request?.utente, "utente"),
                request?.avviso ?? "",
                request?.dest ?? "",
                request?.urgente ?? "",
                (int)PhpIntOpzionale(request?.scadenza)));
        }

        /// <summary>
        /// Modifica un'attività (ex modificaAvviso.php). Restituisce il numero di righe aggiornate.
        /// </summary>
        [HttpPost("modificaAvviso")]
        public IActionResult ModificaAvviso([FromBody] ModificaAvvisoRequest request)
        {
            return Esegui("ModificaAvviso", () => _db2Connection.DBAVVISI.ModificaAvviso(
                Obbligatorio(request?.timest, "timest"),
                Obbligatorio(request?.utente, "utente"),
                request?.avviso ?? "",
                request?.dest ?? "",
                request?.urgente ?? "",
                Intero(request?.scadenza, "scadenza")));
        }

        /// <summary>
        /// Completa un'attività (ex completaAvviso.php). Restituisce il numero di righe aggiornate.
        /// </summary>
        [HttpPost("completaAvviso")]
        public IActionResult CompletaAvviso([FromBody] CompletaAvvisoRequest request)
        {
            return Esegui("CompletaAvviso", () => _db2Connection.DBAVVISI.CompletaAvviso(
                Obbligatorio(request?.timest, "timest"),
                Obbligatorio(request?.utente, "utente"),
                Obbligatorio(request?.dest, "dest")));
        }

        /// <summary>
        /// Elimina un'attività (ex eliminaAvviso.php). Restituisce il numero di righe eliminate.
        /// </summary>
        [HttpPost("eliminaAvviso")]
        public IActionResult EliminaAvviso([FromBody] EliminaAvvisoRequest request)
        {
            return Esegui("EliminaAvviso", () => _db2Connection.DBAVVISI.EliminaAvviso(
                Obbligatorio(request?.timest, "timest"),
                Obbligatorio(request?.utente, "utente")));
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Attività 0027 → MGAUT01 ---------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Porta l'attività 0027 ad ATTIVO='2' e la completa (con messaggio chat 'avviso_completato' al creatore)
        /// quando l'articolo dell'ODL entra su MGAUT01 (ex startScriptCompletaAvviso0027Mgaut01.php).
        /// <para>
        /// Il primo controllo è fatto subito: se il trasferimento c'è già, l'attività è completata e la risposta è
        /// l'id del messaggio chat, come nel PHP. Altrimenti la risposta è <c>in_attesa</c> e il controllo prosegue
        /// in background ogni minuto fino a 6000 volte (circa 4+ giorni), invece di tenere aperta la richiesta.
        /// L'utente completante (mittente del messaggio) è quello del token.
        /// </para>
        /// </summary>
        [HttpPost("startScriptCompletaAvviso0027Mgaut01")]
        public IActionResult StartScriptCompletaAvviso0027Mgaut01([FromBody] StartScriptCompletaAvviso0027Mgaut01Request request)
        {
            return Esegui("StartScriptCompletaAvviso0027Mgaut01", () =>
            {
                var job = new Job0027
                {
                    Articolo = Obbligatorio(request?.articolo_avviso, "articolo_avviso"),
                    Odl = Obbligatorio(request?.odl_avviso, "odl_avviso"),
                    Timest = Obbligatorio(request?.timest_avviso, "timest_avviso"),
                    UtenteCompletante = Utente,
                    UtenteAvviso = Obbligatorio(request?.utente_avviso, "utente_avviso"),
                    UtenteAvvisoDiapason = Obbligatorio(request?.utente_avviso_diapason, "utente_avviso_diapason"),
                    Dest = Obbligatorio(request?.dest_avviso, "dest_avviso"),
                    ChatText = request?.chat_text ?? "",
                    Societa = Societa,
                    DataOraCreazione = long.Parse(DateTime.Now.ToString("yyyyMMddHHmmss"), CultureInfo.InvariantCulture)
                };

                var chiave = string.Join("|", job.Timest, job.UtenteAvviso, job.Dest, job.Articolo, job.Odl);
                if (_jobs0027.ContainsKey(chiave))
                {
                    _logger.LogInformation("SCRIPT => completa Attività 0027 | GIÀ ATTIVO | Articolo: {Articolo} | ODL: {Odl} | ID Attività: {Timest}",
                        job.Articolo, job.Odl, job.Timest);
                    return SCRIPT_IN_ATTESA;
                }

                var avvisi = _db2Connection.DBAVVISI;

                // L'attività non è più visibile al destinatario, ma ancora a chi l'ha creata
                avvisi.ImpostaAttivitaSemiCompletata(job.Timest, job.UtenteAvviso, job.Dest);

                // Controllo 0: se il trasferimento c'è già completo subito e rispondo con l'id del messaggio
                if (avvisi.VerificaTrasferimentoMgaut01(job.Articolo, job.Odl, job.DataOraCreazione, job.Societa))
                {
                    return Completa0027(avvisi, job, 0, _logger);
                }

                if (!_jobs0027.TryAdd(chiave, 0))
                {
                    return SCRIPT_IN_ATTESA;
                }

                _logger.LogInformation("SCRIPT => completa Attività 0027 | ATTIVATO | Articolo: {Articolo} | ODL: {Odl} | ID Attività: {Timest} | Ricorsione (in minuti) N: 0 | Utente: {Utente}",
                    job.Articolo, job.Odl, job.Timest, job.UtenteCompletante);

                var logger = _logger;
                var scopeFactory = _scopeFactory;
                var arresto = _lifetime.ApplicationStopping;

                _ = Task.Run(async () =>
                {
                    try
                    {
                        await ControllaTrasferimentoMgaut01Async(scopeFactory, logger, job, arresto);
                    }
                    finally
                    {
                        _jobs0027.TryRemove(chiave, out _);
                    }
                });

                return SCRIPT_IN_ATTESA;
            });
        }

        /// <summary>
        /// Controllo periodico in background (ricorsione con sleep(60) del PHP): un nuovo scope / MyDbContext per
        /// ogni controllo, interrotto dopo <see cref="MAX_RICORSIONI_0027"/> controlli o all'arresto dell'API.
        /// </summary>
        private static async Task ControllaTrasferimentoMgaut01Async(IServiceScopeFactory scopeFactory, ILogger logger,
            Job0027 job, CancellationToken arresto)
        {
            using var logScope = logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = job.Societa,
                ["LOG_ORIGIN"] = ORIGIN,
                ["LOG_USER"] = job.UtenteCompletante,
                ["LOG_WS_CONTROLLER"] = "AVVISI",
                ["LOG_WS_ACTION"] = "StartScriptCompletaAvviso0027Mgaut01"
            });

            for (var counter = 1; ; counter++)
            {
                try
                {
                    await Task.Delay(INTERVALLO_CONTROLLO_0027, arresto);
                }
                catch (OperationCanceledException)
                {
                    logger.LogWarning("SCRIPT => completa Attività 0027 | INTERROTTO (arresto API) | Articolo: {Articolo} | ODL: {Odl} | ID Attività: {Timest} | Ricorsione (in minuti) N: {Counter} | Utente: {Utente}",
                        job.Articolo, job.Odl, job.Timest, counter - 1, job.UtenteCompletante);
                    return;
                }

                if (counter > MAX_RICORSIONI_0027)
                {
                    logger.LogError("MEGA ERRORE SCRIPT 0027 ( TIMEOUT 4+ GIORNI) | !ATTENZIONE! | counter_ricorsione > 6000 | Articolo: {Articolo} | ODL: {Odl} | ID Attività: {Timest} | Ricorsione (in minuti) N: {Counter} | Utente: {Utente}",
                        job.Articolo, job.Odl, job.Timest, counter, job.UtenteCompletante);
                    return;
                }

                try
                {
                    using var scope = scopeFactory.CreateScope();
                    var avvisi = scope.ServiceProvider.GetRequiredService<MyDbContext>().DBAVVISI;

                    if (avvisi.VerificaTrasferimentoMgaut01(job.Articolo, job.Odl, job.DataOraCreazione, job.Societa))
                    {
                        Completa0027(avvisi, job, counter, logger);
                        return;
                    }
                }
                catch (Exception ex)
                {
                    // Come nel PHP un errore della query di controllo non ferma lo script: si riprova al giro dopo.
                    // Un errore nel completamento invece lo termina.
                    logger.LogError(ex, "SCRIPT => completa Attività 0027 | ERRORE | Articolo: {Articolo} | ODL: {Odl} | ID Attività: {Timest} | Ricorsione (in minuti) N: {Counter}",
                        job.Articolo, job.Odl, job.Timest, counter);
                    if (ex is CompletamentoException)
                    {
                        return;
                    }
                }
            }
        }

        /// <summary>
        /// Completa l'attività 0027, invia il messaggio chat e scrive il log; restituisce l'id del messaggio.
        /// </summary>
        private static string Completa0027(DBAVVISI avvisi, Job0027 job, int counter, ILogger logger)
        {
            string idMessaggio;
            try
            {
                idMessaggio = avvisi.CompletaAttivita0027(job.Timest, job.UtenteAvviso, job.Dest,
                    job.UtenteCompletante, job.UtenteAvvisoDiapason, job.ChatText);
            }
            catch (Exception ex)
            {
                throw new CompletamentoException(ex);
            }

            logger.LogInformation("SCRIPT => completa Attività 0027 | COMPLETATO | Articolo: {Articolo} | ODL: {Odl} | ID Attività: {Timest} | Ricorsione (in minuti) N: {Counter} | Utente: {Utente} | Messaggio chat: {IdMessaggio}",
                job.Articolo, job.Odl, job.Timest, counter, job.UtenteCompletante, idMessaggio);

            return idMessaggio;
        }

        /// <summary>Parametri di un job 0027.</summary>
        private sealed class Job0027
        {
            public string Articolo { get; init; } = "";
            public string Odl { get; init; } = "";
            public string Timest { get; init; } = "";
            public string UtenteCompletante { get; init; } = "";
            public string UtenteAvviso { get; init; } = "";
            public string UtenteAvvisoDiapason { get; init; } = "";
            public string Dest { get; init; } = "";
            public string ChatText { get; init; } = "";
            /// <summary>Società del token, catturata prima di avviare il job in background.</summary>
            public string Societa { get; init; } = CodiciSocieta.CASAGRANDE;
            public long DataOraCreazione { get; init; }
        }

        /// <summary>Errore durante il completamento dell'attività 0027 (termina il job).</summary>
        private sealed class CompletamentoException : Exception
        {
            public CompletamentoException(Exception inner) : base("Errore nel completamento dell'attività 0027", inner) { }
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Attività per sezione ------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Collega un'attività a una sezione dell'app (ex writeAttivitaSezione.php). Restituisce 'uploaded'.
        /// </summary>
        [HttpPost("writeAttivitaSezione")]
        public IActionResult WriteAttivitaSezione([FromBody] WriteAttivitaSezioneRequest request)
        {
            return Esegui("WriteAttivitaSezione", () => _db2Connection.DBAVVISI.WriteAttivitaSezione(
                Obbligatorio(request?.timest, "timest"),
                Obbligatorio(request?.utente, "utente"),
                request?.sezione ?? "",
                request?.articolo ?? "",
                request?.odl ?? "",
                request?.fase ?? "",
                Numero(request?.qta, "qta"),
                request?.magazzino ?? "",
                request?.custom_variable ?? ""));
        }

        /// <summary>
        /// Chiavi dell'attività legata a un impegno ODL; con operazione UPD aggiorna la quantità
        /// (ex getAttivitaKeysFromImpegnoOdl.php). <c>null</c> se non esiste.
        /// </summary>
        [HttpPost("getAttivitaKeysFromImpegnoOdl")]
        public IActionResult GetAttivitaKeysFromImpegnoOdl([FromBody] GetAttivitaKeysFromImpegnoOdlRequest request)
        {
            return Esegui("GetAttivitaKeysFromImpegnoOdl", () =>
            {
                var operazione = request?.operazione ?? "";
                double? qta = operazione == "UPD" ? Numero(request?.qta, "qta") : null;

                return _db2Connection.DBAVVISI.GetAttivitaKeysFromImpegnoOdl(
                    request?.sezione ?? "",
                    request?.articolo ?? "",
                    request?.odl ?? "",
                    request?.fase ?? "",
                    request?.magazzino ?? "",
                    qta,
                    operazione);
            });
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Bolle a destinazione specifica --------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Bolle a destinazione specifica dell'ultimo anno non completate (ex selectAllAvvisiSpeciali.php).
        /// </summary>
        [HttpPost("selectAllAvvisiSpeciali")]
        public IActionResult SelectAllAvvisiSpeciali()
        {
            return Esegui("SelectAllAvvisiSpeciali", () => _db2Connection.DBAVVISI.SelectAllAvvisiSpeciali(Societa));
        }

        /// <summary>
        /// Righe non completate di una bolla a destinazione specifica (ex addInfoAvvisoSpeciale.php).
        /// </summary>
        [HttpPost("addInfoAvvisoSpeciale")]
        public IActionResult AddInfoAvvisoSpeciale([FromBody] AddInfoAvvisoSpecialeRequest request)
        {
            return Esegui("AddInfoAvvisoSpeciale", () =>
                _db2Connection.DBAVVISI.AddInfoAvvisoSpeciale(Obbligatorio(request?.id, "id"), Societa));
        }

        /// <summary>
        /// Completa le righe di una bolla a destinazione specifica (ex completaAvvisoSpeciale.php).
        /// L'utente completante scritto nella nota è quello del token.
        /// </summary>
        [HttpPost("completaAvvisoSpeciale")]
        public IActionResult CompletaAvvisoSpeciale([FromBody] CompletaAvvisoSpecialeRequest request)
        {
            return Esegui("CompletaAvvisoSpeciale", () =>
            {
                var riga = Intero(request?.riga, "riga");
                if (riga < 0 || riga > 999999)
                {
                    throw new MobileException("Parametro riga non valido");
                }

                return _db2Connection.DBAVVISI.CompletaAvvisoSpeciale(
                    Obbligatorio(request?.id, "id"),
                    request?.bolla ?? "",
                    Utente,
                    (int)riga,
                    Societa);
            });
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Mancanti / materiale in arrivo --------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Componenti CC mancanti con ODA e fornitore (ex getMancantiCC.php).
        /// </summary>
        [HttpPost("getMancantiCC")]
        public IActionResult GetMancantiCC()
        {
            return Esegui("GetMancantiCC", () => _db2Connection.DBAVVISI.GetMancantiCC(Societa));
        }

        /// <summary>
        /// Bolle fornitore non ancora scaricate con i relativi articoli (ex getMaterialeInArrivo.php).
        /// </summary>
        [HttpPost("getMaterialeInArrivo")]
        public IActionResult GetMaterialeInArrivo()
        {
            return Esegui("GetMaterialeInArrivo", () => _db2Connection.DBAVVISI.GetMaterialeInArrivo(Societa));
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Validazione input ---------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        private static string Obbligatorio(string? valore, string nome)
        {
            if (string.IsNullOrWhiteSpace(valore))
            {
                throw new MobileException($"Parametro {nome} obbligatorio");
            }
            return valore;
        }

        private static long Intero(string? valore, string nome)
        {
            if (!long.TryParse(valore?.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var n))
            {
                throw new MobileException($"Parametro {nome} non valido");
            }
            return n;
        }

        private static double Numero(string? valore, string nome)
        {
            if (!double.TryParse(valore?.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var n))
            {
                throw new MobileException($"Parametro {nome} non valido");
            }
            return n;
        }

        /// <summary>(int) di PHP su un campo facoltativo: 0 se mancante o non numerico.</summary>
        private static long PhpIntOpzionale(string? valore)
        {
            return double.TryParse(valore?.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var d)
                && d is <= int.MaxValue and >= int.MinValue
                ? (long)Math.Truncate(d)
                : 0;
        }
    }
}
