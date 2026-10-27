using System.Diagnostics;
using System.Text.Json;
using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Movimenti di magazzino verso Diapason (ex mobile/server/api): movimento singolo, invio multiplo in background
    /// con esito via SSE, liste del magazzino automatico ed elenco ARM.
    /// </summary>
    [Route("api/movimenti")]
    [ApiController]
    [Authorize]
    public class MovimentiController : MobileControllerBase
    {
        /// <summary>Intervallo di controllo dello stream SSE (ex sleep(5)).</summary>
        private static readonly TimeSpan INTERVALLO_SSE = TimeSpan.FromSeconds(5);

        /// <summary>Durata massima dello stream SSE (ex set_time_limit(3600)).</summary>
        private static readonly TimeSpan DURATA_MAX_SSE = TimeSpan.FromHours(1);

        private readonly DiapasonSocket _diapasonSocket;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly MobileSettings _settings;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="MovimentiController"/>.
        /// </summary>
        public MovimentiController(MyDbContext db2Connection, ILogger<MovimentiController> logger, DiapasonSocket diapasonSocket,
            IServiceScopeFactory scopeFactory, IOptions<MobileSettings> settings)
            : base(db2Connection, logger, "MOVIMENTI")
        {
            _diapasonSocket = diapasonSocket;
            _scopeFactory = scopeFactory;
            _settings = settings.Value;
        }

        /// <summary>
        /// Esegue un movimento singolo su Diapason con l'utente del token (ex api/APIMovMagMobileApp.php).
        /// </summary>
        /// <param name="request">Dati del movimento.</param>
        /// <returns>La risposta di Diapason (es. "0043I IL MOVIMENTO DI MAGAZZINO E'STATO ESEGUITO").</returns>
        [HttpPost("APIMovMagMobileApp")]
        public Task<IActionResult> APIMovMagMobileApp([FromBody] APIMovMagMobileAppRequest request)
        {
            return EseguiAsync("APIMovMagMobileApp",
                async () => await _db2Connection.DBMOVIMENTI.APIMovMagMobileAppAsync(request, Utente, _diapasonSocket),
                request?.societa);
        }

        /// <summary>
        /// Elenco delle ARM degli ultimi due anni (ex api/DBGetARMListMobile.php).
        /// </summary>
        /// <returns>Lista di { numero, causale, cliente, data }, <c>null</c> se vuota.</returns>
        [HttpPost("DBGetARMListMobile")]
        public IActionResult DBGetARMListMobile()
        {
            return Esegui("DBGetARMListMobile", () => _db2Connection.DBMOVIMENTI.DBGetARMListMobile());
        }

        /// <summary>
        /// Invia una lista di prelievo / carico al magazzino automatico con l'utente del token
        /// (ex api/WriteListaMagazzinoAutomatico.php).
        /// </summary>
        /// <param name="request">Dati della lista.</param>
        /// <returns>La risposta del socket ("200 ..." = lista creata), "error" o "500 ...".</returns>
        [HttpPost("WriteListaMagazzinoAutomatico")]
        public Task<IActionResult> WriteListaMagazzinoAutomatico([FromBody] WriteListaMagazzinoAutomaticoRequest request)
        {
            return EseguiAsync("WriteListaMagazzinoAutomatico",
                async () => await _db2Connection.DBMOVIMENTI.WriteListaMagazzinoAutomaticoAsync(request, Utente, _settings.Diapason, _logger));
        }

        /// <summary>
        /// Avvia in background i movimenti di una lista con l'utente del token e risponde subito "ok"
        /// (ex api/WriteMovimentiMultipliAPI.php). L'avanzamento si segue con <see cref="MovimentiMagazzinoSSE"/>
        /// usando lo stesso <c>id_api</c>.
        /// </summary>
        /// <param name="request">Dati generali (id_api, nome_lista, sezione) e movimenti.</param>
        /// <returns>"ok".</returns>
        [HttpPost("WriteMovimentiMultipliAPI")]
        public IActionResult WriteMovimentiMultipliAPI([FromBody] WriteMovimentiMultipliAPIRequest request)
        {
            return Esegui("WriteMovimentiMultipliAPI", () =>
            {
                _db2Connection.DBMOVIMENTI.ValidaMovimentiMultipli(request);

                var utente = Utente;
                var logger = _logger;
                var scopeFactory = _scopeFactory;

                _ = Task.Run(async () =>
                {
                    using var logScope = logger.BeginScope(new Dictionary<string, object>
                    {
                        ["LOG_CODSOC"] = "CSPRO",
                        ["LOG_ORIGIN"] = ORIGIN,
                        ["LOG_USER"] = utente,
                        ["LOG_WS_CONTROLLER"] = "MOVIMENTI",
                        ["LOG_WS_ACTION"] = "WriteMovimentiMultipliAPI"
                    });
                    try
                    {
                        using var scope = scopeFactory.CreateScope();
                        var db = scope.ServiceProvider.GetRequiredService<MyDbContext>();
                        var socket = scope.ServiceProvider.GetRequiredService<DiapasonSocket>();
                        await db.DBMOVIMENTI.WriteMovimentiMultipliAPIAsync(request, utente, socket, logger);
                        logger.LogInformation("Invio multiplo {IdApi} completato", request.dataObject?.id_api);
                    }
                    catch (Exception ex)
                    {
                        logger.LogError(ex, "Errore nell'invio multiplo {IdApi} ({Sezione}) di {Username}",
                            request.dataObject?.id_api, request.dataObject?.sezione, utente);
                    }
                });

                return "ok";
            });
        }

        /// <summary>
        /// Stream SSE dello stato di un invio multiplo (ex api/MovimentiMagazzinoSSE.php): ogni 5 secondi invia
        /// l'evento <c>ping</c> con la riga di api_sse_responses (se esiste). Termina dopo un'ora o quando il client
        /// si disconnette.
        /// </summary>
        /// <param name="id">L'id_api dell'invio.</param>
        [HttpGet("MovimentiMagazzinoSSE")]
        public async Task MovimentiMagazzinoSSE([FromQuery] string? id)
        {
            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = "CSPRO",
                ["LOG_ORIGIN"] = ORIGIN,
                ["LOG_USER"] = Utente,
                ["LOG_WS_CONTROLLER"] = "MOVIMENTI",
                ["LOG_WS_ACTION"] = "MovimentiMagazzinoSSE"
            }))
            {
                if (string.IsNullOrWhiteSpace(id))
                {
                    Response.StatusCode = StatusCodes.Status400BadRequest;
                    await Response.WriteAsJsonAsync(ResultInfo.Error(-1, "id obbligatorio", null!));
                    return;
                }

                Response.Headers.ContentType = "text/event-stream";
                Response.Headers.CacheControl = "no-cache";

                var ct = HttpContext.RequestAborted;
                var durata = Stopwatch.StartNew();
                try
                {
                    while (!ct.IsCancellationRequested && durata.Elapsed < DURATA_MAX_SSE)
                    {
                        var riga = _db2Connection.DBMOVIMENTI.GetApiSseResponse(id);
                        if (riga != null)
                        {
                            var apiResponse = JsonSerializer.Serialize(riga);
                            await Response.WriteAsync("event: ping\nid:\ndata:" + apiResponse + "\n\n", ct);
                            await Response.Body.FlushAsync(ct);
                        }

                        await Task.Delay(INTERVALLO_SSE, ct);
                    }
                }
                catch (OperationCanceledException) when (ct.IsCancellationRequested)
                {
                    // client disconnesso
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore nello stream SSE dell'invio {IdApi}", id);
                }
            }
        }
    }
}
