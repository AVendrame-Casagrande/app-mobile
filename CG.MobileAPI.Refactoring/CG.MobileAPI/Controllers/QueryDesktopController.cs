using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Servizi ex mobile/server/queryDesktop: verifiche magazzino/vano e generazione PDF da HTML.
    /// </summary>
    [Route("api/queryDesktop")]
    [ApiController]
    [Authorize]
    public class QueryDesktopController : MobileControllerBase
    {
        private readonly StorageTool _storage;
        private readonly IConfiguration _config;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="QueryDesktopController"/>.
        /// </summary>
        public QueryDesktopController(MyDbContext db2Connection, ILogger<QueryDesktopController> logger, StorageTool storage, IConfiguration config)
            : base(db2Connection, logger, "QUERYDESKTOP")
        {
            _storage = storage;
            _config = config;
        }

        /// <summary>Indirizzo pubblico del web server per gli URL dei PDF generati.</summary>
        private string UrlPubblico => _config["mobile:Storage:PublicBaseUrl"] is { Length: > 0 } url ? url : DBGENERALE.UrlPubblicoPredefinito;

        /// <summary>
        /// Indica se il magazzino esiste (ex queryDesktop/giacenze/checkMagazzinoExists.php).
        /// </summary>
        /// <returns>true / false.</returns>
        [HttpPost("giacenze/checkMagazzinoExists")]
        public IActionResult CheckMagazzinoExists([FromBody] CheckMagazzinoExistsRequest request)
        {
            return Esegui("checkMagazzinoExists", () => _db2Connection.DBGENERALE.CheckMagazzinoExists(request, Societa));
        }

        /// <summary>
        /// Indica se il vano esiste (ex queryDesktop/giacenze/checkVanoExists.php).
        /// </summary>
        /// <returns>true / false.</returns>
        [HttpPost("giacenze/checkVanoExists")]
        public IActionResult CheckVanoExists([FromBody] CheckVanoExistsRequest request)
        {
            return Esegui("checkVanoExists", () => _db2Connection.DBGENERALE.CheckVanoExists(request, Societa));
        }

        /// <summary>
        /// Converte una tabella HTML in PDF e lo salva nello storage (ex queryDesktop/giacenze/convertPDF.php).
        /// </summary>
        /// <returns>L'URL del PDF, oppure <c>error_pdf</c> se la conversione fallisce.</returns>
        [HttpPost("giacenze/convertPDF")]
        public async Task<IActionResult> ConvertPdf([FromBody] ConvertPdfRequest request)
        {
            return await EseguiAsync("convertPDF", async () =>
            {
                try
                {
                    return await _db2Connection.DBGENERALE.ConvertPdfAsync(request, _storage, UrlPubblico);
                }
                catch (Exception ex) when (ex is not MobileException)
                {
                    _logger.LogError(ex, "Errore nella generazione del PDF {Filename}", request.filename);
                    return "error_pdf";
                }
            });
        }

        /// <summary>
        /// Converte un documento HTML in PDF e lo salva nello storage (ex queryDesktop/modifiche_tecniche/createPDF.php).
        /// </summary>
        /// <returns>L'URL del PDF, oppure <c>error_pdf</c> se la conversione fallisce.</returns>
        [HttpPost("modifiche_tecniche/createPDF")]
        public async Task<IActionResult> CreatePdf([FromBody] CreatePdfRequest request)
        {
            return await EseguiAsync("createPDF", async () =>
            {
                try
                {
                    return await _db2Connection.DBGENERALE.CreatePdfAsync(request, _storage, UrlPubblico);
                }
                catch (Exception ex) when (ex is not MobileException)
                {
                    _logger.LogError(ex, "Errore nella generazione del PDF {Filename}", request.filename);
                    return "error_pdf";
                }
            });
        }
    }
}
