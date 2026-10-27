using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Chiamate ai web service Diapason (ex mobile/server/dapiws).
    /// </summary>
    [Route("api/dapiws")]
    [ApiController]
    [Authorize]
    public class DapiwsController : MobileControllerBase
    {
        /// <summary>
        /// Inizializza una nuova istanza del <see cref="DapiwsController"/>.
        /// </summary>
        public DapiwsController(MyDbContext db2Connection, ILogger<DapiwsController> logger)
            : base(db2Connection, logger, "DAPIWS")
        {
        }

        /// <summary>
        /// Aggiorna peso netto e/o lordo di un articolo in anagrafica Diapason (ex dapiws/UpdateArticolo.php).
        /// La sessione web service viene aperta con l'utente del token, non con il campo <c>username</c>.
        /// </summary>
        /// <param name="request">Società, articolo e nuovi pesi (JSON).</param>
        /// <returns>Il messaggio di Diapason; HTTP 400 con il messaggio se Diapason restituisce un errore.</returns>
        [HttpPost("UpdateArticolo")]
        public IActionResult UpdateArticolo([FromBody] UpdateArticoloRequest request)
        {
            return Esegui("UpdateArticolo", () => _db2Connection.DBKANBAN.UpdateArticolo(request, Utente), request?.societa);
        }
    }
}
