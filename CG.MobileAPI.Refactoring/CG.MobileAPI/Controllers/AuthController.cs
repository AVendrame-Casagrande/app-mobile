using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Login dell'app mobile: verifica la password su Diapason (ex CheckUserDiap.php) e restituisce
    /// l'utente (ex login.php) con il token JWT da usare per tutte le altre chiamate.
    /// </summary>
    [Route("api/auth")]
    [ApiController]
    [Authorize]
    public class AuthController : MobileControllerBase
    {
        private readonly DiapasonExe _diapasonExe;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="AuthController"/>.
        /// </summary>
        public AuthController(MyDbContext db2Connection, ILogger<AuthController> logger, DiapasonExe diapasonExe)
            : base(db2Connection, logger, "AUTH")
        {
            _diapasonExe = diapasonExe;
        }

        /// <summary>
        /// Login con codice utente e password Diapason.
        /// </summary>
        /// <param name="request">Codice utente, password e società.</param>
        /// <returns>L'utente loggato e il token JWT; 401 se le credenziali sono errate.</returns>
        [AllowAnonymous]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestModel request)
        {
            if (request == null || string.IsNullOrWhiteSpace(request.CodiceUtente) || string.IsNullOrEmpty(request.Password))
            {
                return BadRequest(ResultInfo.Error(-1, "Codice utente e password obbligatori", null!));
            }

            var codice = request.CodiceUtente.Trim().ToUpperInvariant();
            if (!string.IsNullOrWhiteSpace(request.Societa) && !CodiciSocieta.IsSelezionabile(request.Societa))
            {
                return BadRequest(ResultInfo.Error(-1, "Società non valida", null!));
            }
            var societa = CodiciSocieta.Normalizza(request.Societa);
            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = ORIGIN,
                ["LOG_USER"] = codice,

                ["LOG_WS_CONTROLLER"] = "AUTH",
                ["LOG_WS_ACTION"] = "Login"
            }))
            {
                try
                {
                    var utente = _db2Connection.DBAUTH.GetUtente(codice);
                    if (utente == null)
                    {
                        _logger.LogWarning("Login fallito: utente {Username} inesistente", codice);
                        return Unauthorized(ResultInfo.Error(-2, "Nome utente o password errati", null!));
                    }

                    var esito = (await _diapasonExe.CheckUserAsync(utente.codiceUtente, request.Password)).Trim();
                    if (esito != DiapasonExe.AUTENTICATO)
                    {
                        _logger.LogWarning("Login fallito per {Username}: {Esito}", codice, esito);
                        return Unauthorized(ResultInfo.Error(-2, "Nome utente o password errati", null!));
                    }

                    // Gli utenti in lingua inglese lavorano su Casagrande USA, qualunque sia la scelta (come la vecchia app).
                    if (utente.language == "E")
                    {
                        societa = CodiciSocieta.CS_USA;
                    }
                    utente.societa = societa;
                    var token = TokenTool.GeneraTokenJwt(utente.codiceUtente, new Dictionary<string, string>
                    {
                        [CLAIM_NOME_PORTALE] = utente.nomePortale,
                        [CLAIM_ACCOUNT_TYPE] = utente.accountType,
                        [CLAIM_SOCIETA] = societa
                    });

                    _logger.LogInformation("L'utente {Username} ha effettuato il login", codice);

                    return Ok(ResultInfo.Success(new LoginResponseModel { utente = utente, token = token }));
                }
                catch (MobileException ex)
                {
                    return BadRequest(ResultInfo.Error(ex.Code, ex.Message, null!));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore nel login di {Username}", codice);
                    return StatusCode(500, ResultInfo.Error(-100, "Errore interno del server", null!));
                }
            }
        }

        /// <summary>
        /// Dati aggiornati dell'utente del token (es. dopo il cambio della foto profilo).
        /// </summary>
        [HttpPost("utente")]
        public IActionResult GetUtente()
        {
            return Esegui("GetUtente", () =>
            {
                var utente = _db2Connection.DBAUTH.GetUtente(Utente) ?? throw new MobileException("Utente non trovato");
                utente.societa = Societa;
                return utente;
            });
        }
    }
}
