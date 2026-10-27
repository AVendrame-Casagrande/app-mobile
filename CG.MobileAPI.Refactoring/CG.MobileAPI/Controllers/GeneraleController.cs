using System.Globalization;
using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Servizi generali dell'app mobile (ex mobile/server/query/*.php e log/log.php): versione e changelog,
    /// foto articolo e profilo, situazione ODV, log dell'app.
    /// </summary>
    [Route("api/generale")]
    [ApiController]
    [Authorize]
    public class GeneraleController : MobileControllerBase
    {
        private readonly StorageTool _storage;
        private readonly IConfiguration _config;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="GeneraleController"/>.
        /// </summary>
        public GeneraleController(MyDbContext db2Connection, ILogger<GeneraleController> logger, StorageTool storage, IConfiguration config)
            : base(db2Connection, logger, "GENERALE")
        {
            _storage = storage;
            _config = config;
        }

        /// <summary>
        /// Riga di log inviata dall'app (ex log/log.php, che scriveva su logs_mobile.txt): finisce nei log del servizio.
        /// Accessibile anche senza login (l'app invia log anche prima dell'accesso).
        /// </summary>
        /// <returns><c>ok</c>.</returns>
        [AllowAnonymous]
        [HttpPost("log")]
        public IActionResult Log([FromBody] LogRequest request)
        {
            return Esegui("log", () =>
            {
                var adesso = DateTime.Now;
                _logger.LogInformation("{DataLog} | {OraLog} | {Version} | {Device} | {Log} | {Ip}",
                    adesso.ToString("dd-MM-yyyy", CultureInfo.InvariantCulture),
                    adesso.ToString("HH:mm:ss", CultureInfo.InvariantCulture),
                    request?.version, request?.device, request?.log,
                    HttpContext.Connection.RemoteIpAddress?.ToString());
                return "ok";
            });
        }

        /// <summary>
        /// Ultima versione dell'app e changelog (ex checkVersion.php, chiamato in GET dall'app).
        /// Accessibile anche senza login (verifica aggiornamenti all'avvio).
        /// </summary>
        /// <returns>{ code, changeLog, updateTablet, mandatoryUpdate }.</returns>
        [AllowAnonymous]
        [HttpGet("checkVersion")]
        [HttpPost("checkVersion")]
        public IActionResult CheckVersion()
        {
            return Esegui("checkVersion", () => _db2Connection.DBGENERALE.CheckVersion());
        }

        /// <summary>
        /// Elimina una foto dell'articolo e rinumera le successive (ex deleteFoto.php).
        /// </summary>
        /// <returns><c>success</c> o il messaggio d'errore del PHP.</returns>
        [HttpPost("deleteFoto")]
        public IActionResult DeleteFoto([FromBody] DeleteFotoRequest request)
        {
            return Esegui("deleteFoto", () => _db2Connection.DBGENERALE.DeleteFoto(request, _storage));
        }

        /// <summary>
        /// Situazione delle righe degli ordini di vendita (ex getSituazioneOdv.php).
        /// </summary>
        /// <returns>Lista degli ODV con le righe e il loro stato.</returns>
        [HttpPost("getSituazioneOdv")]
        public IActionResult GetSituazioneOdv([FromBody] GetSituazioneOdvRequest request)
        {
            return Esegui("getSituazioneOdv", () => _db2Connection.DBGENERALE.GetSituazioneOdv(request));
        }

        /// <summary>
        /// Rimuove la foto profilo dell'utente autenticato (ex rimuoviFotoProfilo.php; il codice è preso dal token).
        /// </summary>
        /// <returns><c>updated</c>.</returns>
        [HttpPost("rimuoviFotoProfilo")]
        public IActionResult RimuoviFotoProfilo()
        {
            return Esegui("rimuoviFotoProfilo", () => _db2Connection.DBGENERALE.RimuoviFotoProfilo(Utente));
        }

        /// <summary>
        /// Caricamento foto articolo (ex uploadFoto.php): servizio disattivato nel PHP, risponde sempre <c>uploaded failed</c>.
        /// </summary>
        /// <returns><c>uploaded failed</c>.</returns>
        [HttpPost("uploadFoto")]
        [Consumes("multipart/form-data")]
        public IActionResult UploadFoto([FromForm] UploadFotoRequest request)
        {
            return Esegui("uploadFoto", () => _db2Connection.DBGENERALE.UploadFoto(request));
        }

        /// <summary>
        /// Invia la foto all'FTP delle foto ARM (ex uploadFotoArm.php).
        /// </summary>
        /// <returns><c>uploaded</c> o <c>upload ftp failed</c>.</returns>
        [HttpPost("uploadFotoArm")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadFotoArm([FromForm] UploadFotoArmRequest request)
        {
            return await EseguiAsync("uploadFotoArm", async () =>
            {
                var ftp = _config.GetSection("mobile:FotoArm").Get<FotoArmFtpSettings>() ?? new FotoArmFtpSettings();
                return await _db2Connection.DBGENERALE.UploadFotoArmAsync(request, ftp);
            });
        }

        /// <summary>
        /// Carica la foto profilo dell'utente autenticato (ex uploadFotoProfilo.php; codice e nome portale dal token).
        /// </summary>
        /// <returns><c>uploaded</c> o <c>error</c>.</returns>
        [HttpPost("uploadFotoProfilo")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadFotoProfilo([FromForm] UploadFotoProfiloRequest request)
        {
            return await EseguiAsync("uploadFotoProfilo", async () =>
                await _db2Connection.DBGENERALE.UploadFotoProfiloAsync(request, Utente, NomePortale, _storage));
        }
    }
}
