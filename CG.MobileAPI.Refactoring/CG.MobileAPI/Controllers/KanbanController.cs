using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Kanban: scaffali, articoli degli scaffali, ripristino scorte e ordini di rifornimento
    /// (ex mobile/server/query/kanban).
    /// </summary>
    [Route("api/kanban")]
    [ApiController]
    [Authorize]
    public class KanbanController : MobileControllerBase
    {
        private readonly StorageTool _storage;
        private readonly EmailTool _email;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="KanbanController"/>.
        /// </summary>
        public KanbanController(MyDbContext db2Connection, ILogger<KanbanController> logger, StorageTool storage, EmailTool email)
            : base(db2Connection, logger, "KANBAN")
        {
            _storage = storage;
            _email = email;
        }

        /// <summary>
        /// Aggiunge un articolo a uno scaffale (ex addArticoloScaffale.php).
        /// </summary>
        /// <returns>"error" se l'articolo è già nello scaffale, altrimenti "ok".</returns>
        [HttpPost("addArticoloScaffale")]
        public IActionResult AddArticoloScaffale([FromBody] AddArticoloScaffaleRequest request)
        {
            return Esegui("addArticoloScaffale", () => _db2Connection.DBKANBAN.AddArticoloScaffale(request, Societa));
        }

        /// <summary>
        /// Elenco degli scaffali di un articolo (ex addElencoScaffaliToArticolo.php).
        /// </summary>
        [HttpPost("addElencoScaffaliToArticolo")]
        public IActionResult AddElencoScaffaliToArticolo([FromBody] AddElencoScaffaliToArticoloRequest request)
        {
            return Esegui("addElencoScaffaliToArticolo", () => _db2Connection.DBKANBAN.AddElencoScaffaliToArticolo(request, Societa));
        }

        /// <summary>
        /// Giacenza dell'articolo in MGAUT00 / MGAUT10 (ex checkKanbanGiacenzeMgaut.php).
        /// </summary>
        [HttpPost("checkKanbanGiacenzeMgaut")]
        public IActionResult CheckKanbanGiacenzeMgaut([FromBody] CheckKanbanGiacenzeMgautRequest request)
        {
            return Esegui("checkKanbanGiacenzeMgaut", () => _db2Connection.DBKANBAN.CheckKanbanGiacenzeMgaut(request, Societa));
        }

        /// <summary>
        /// Toglie un articolo da uno scaffale (ex deleteArticoloScaffale.php).
        /// </summary>
        [HttpPost("deleteArticoloScaffale")]
        public IActionResult DeleteArticoloScaffale([FromBody] DeleteArticoloScaffaleRequest request)
        {
            return Esegui("deleteArticoloScaffale", () => _db2Connection.DBKANBAN.DeleteArticoloScaffale(request));
        }

        /// <summary>
        /// Elenco di tutti gli scaffali (ex selectAllScaffali.php, chiamato in GET dai client).
        /// </summary>
        [HttpPost("selectAllScaffali")]
        [HttpGet("selectAllScaffali")]
        public IActionResult SelectAllScaffali()
        {
            return Esegui("selectAllScaffali", () => _db2Connection.DBKANBAN.SelectAllScaffali());
        }

        /// <summary>
        /// Articoli presenti in uno scaffale (ex selectArticoliScaffale.php).
        /// </summary>
        [HttpPost("selectArticoliScaffale")]
        public IActionResult SelectArticoliScaffale([FromBody] SelectArticoliScaffaleRequest request)
        {
            return Esegui("selectArticoliScaffale", () => _db2Connection.DBKANBAN.SelectArticoliScaffale(request, Societa));
        }

        /// <summary>
        /// Dati kanban di un articolo, con gli scaffali se richiesto (ex query/kanban/selectSingoloArticolo.php).
        /// </summary>
        [HttpPost("selectSingoloArticolo")]
        public IActionResult SelectSingoloArticolo([FromBody] SelectSingoloArticoloKanbanRequest request)
        {
            return Esegui("selectSingoloArticolo", () => _db2Connection.DBKANBAN.SelectSingoloArticolo(request, Societa));
        }

        /// <summary>
        /// Celle di uno scaffale (ex selectSingoloScaffale.php).
        /// </summary>
        [HttpPost("selectSingoloScaffale")]
        public IActionResult SelectSingoloScaffale([FromBody] SelectSingoloScaffaleRequest request)
        {
            return Esegui("selectSingoloScaffale", () => _db2Connection.DBKANBAN.SelectSingoloScaffale(request));
        }

        /// <summary>
        /// Invia via email l'Excel di ripristino scorte kanban (ex sendRipristinoScorteEmail.php).
        /// </summary>
        /// <returns>"1" se la mail è stata inviata.</returns>
        [HttpPost("sendRipristinoScorteEmail")]
        public Task<IActionResult> SendRipristinoScorteEmail([FromBody] SendRipristinoScorteEmailRequest request)
        {
            return EseguiAsync("sendRipristinoScorteEmail",
                async () => await _db2Connection.DBKANBAN.SendRipristinoScorteEmailAsync(request, _storage, _email));
        }

        /// <summary>
        /// Scrive gli ordini di rifornimento ai fornitori (ex writeOrdineRifornimento.php).
        /// </summary>
        /// <returns>L'elenco dei fornitori a cui è stato creato un ordine.</returns>
        [HttpPost("writeOrdineRifornimento")]
        public IActionResult WriteOrdineRifornimento([FromBody] WriteOrdineRifornimentoRequest request)
        {
            return Esegui("writeOrdineRifornimento", () => _db2Connection.DBKANBAN.WriteOrdineRifornimento(request, Societa));
        }
    }
}
