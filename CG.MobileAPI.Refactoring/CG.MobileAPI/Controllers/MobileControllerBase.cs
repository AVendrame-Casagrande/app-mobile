using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Base dei controller dell'app mobile: apre lo scope di log (CGWS_LOGS) e restituisce il risultato
    /// nella busta <see cref="ResultInfo"/>, come i controller dello scheletro.
    /// </summary>
    public abstract class MobileControllerBase : ControllerBase
    {
        /// <summary>Valore di LOG_ORIGIN per le richieste dell'app mobile.</summary>
        public const string ORIGIN = "APP_MOBILE";

        /// <summary>Claim JWT con il nome portale (parte locale dell'email) dell'utente.</summary>
        public const string CLAIM_NOME_PORTALE = "nomePortale";

        /// <summary>Claim JWT con il tipo di account (Utente Standard / Magazzino / Produzione / Qualità / Avanzato).</summary>
        public const string CLAIM_ACCOUNT_TYPE = "accountType";

        /// <summary>Il contesto di database.</summary>
        protected readonly MyDbContext _db2Connection;

        /// <summary>Il logger.</summary>
        protected readonly ILogger _logger;

        private readonly string _controllerName;

        /// <summary>
        /// Inizializza la base del controller.
        /// </summary>
        /// <param name="db2Connection">Il contesto di database.</param>
        /// <param name="logger">Il logger.</param>
        /// <param name="controllerName">Valore di LOG_WS_CONTROLLER (es. "GIACENZE").</param>
        protected MobileControllerBase(MyDbContext db2Connection, ILogger logger, string controllerName)
        {
            _db2Connection = db2Connection;
            _logger = logger;
            _controllerName = controllerName;
        }

        /// <summary>Codice Diapason dell'utente autenticato (claim Name del token).</summary>
        protected string Utente => User?.Identity?.Name ?? "";

        /// <summary>Nome portale dell'utente autenticato.</summary>
        protected string NomePortale => User?.FindFirst(CLAIM_NOME_PORTALE)?.Value ?? "";

        /// <summary>Tipo di account dell'utente autenticato.</summary>
        protected string AccountType => User?.FindFirst(CLAIM_ACCOUNT_TYPE)?.Value ?? "";

        /// <summary>
        /// Esegue l'azione nello scope di log e restituisce <c>Ok(ResultInfo.Success(dati))</c>.
        /// <see cref="MobileException"/> diventa HTTP 400 (404 se il suo Code è 404) con il suo messaggio, ogni altro errore HTTP 500 con codice -100.
        /// </summary>
        /// <param name="action">Valore di LOG_WS_ACTION.</param>
        /// <param name="azione">Funzione che restituisce i dati.</param>
        /// <param name="societa">Società della richiesta (LOG_CODSOC).</param>
        protected IActionResult Esegui(string action, Func<object?> azione, string? societa = null)
        {
            return EseguiAsync(action, () => Task.FromResult(azione()), societa).GetAwaiter().GetResult();
        }

        /// <summary>
        /// Versione asincrona di <see cref="Esegui"/>.
        /// </summary>
        protected async Task<IActionResult> EseguiAsync(string action, Func<Task<object?>> azione, string? societa = null)
        {
            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = string.IsNullOrWhiteSpace(societa) ? "CSPRO" : societa,
                ["LOG_ORIGIN"] = ORIGIN,
                ["LOG_USER"] = Utente,

                ["LOG_WS_CONTROLLER"] = _controllerName,
                ["LOG_WS_ACTION"] = action
            }))
            {
                try
                {
                    var response = await azione();

                    _logger.LogInformation("L'utente {Username} ha eseguito {Action}", Utente, action);

                    return Ok(ResultInfo.Success(response!));
                }
                catch (MobileException ex)
                {
                    _logger.LogWarning("Richiesta {Action} rifiutata per {Username}: {Message}", action, Utente, ex.Message);
                    // Code 404 = risorsa inesistente (es. articolo non trovato): HTTP 404 come facevano i PHP.
                    return ex.Code == 404
                        ? NotFound(ResultInfo.Error(ex.Code, ex.Message, null!))
                        : BadRequest(ResultInfo.Error(ex.Code, ex.Message, null!));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore in {Action} da parte di {Username}", action, Utente);
                    return StatusCode(500, ResultInfo.Error(-100, "Errore interno del server", null!));
                }
            }
        }
    }
}
