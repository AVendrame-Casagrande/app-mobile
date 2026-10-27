using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Giacenze - articoli: scheda articolo, magazzini e vani, distinte, PDF disegni, inventario e inventario CS USA
    /// (ex mobile/server/query/giacenze/*.php).
    /// </summary>
    [Route("api/giacenze")]
    [ApiController]
    [Authorize]
    public class GiacenzeArticoliController : MobileControllerBase
    {
        private readonly StorageTool _storage;
        private readonly EmailTool _email;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="GiacenzeArticoliController"/>.
        /// </summary>
        public GiacenzeArticoliController(MyDbContext db2Connection, ILogger<GiacenzeArticoliController> logger,
            StorageTool storage, EmailTool email)
            : base(db2Connection, logger, "GIACENZE")
        {
            _storage = storage;
            _email = email;
        }

        private DBGIACENZE_ARTICOLI Db => _db2Connection.DBGIACENZE_ARTICOLI;

        /// <summary>Ultimo costo CATT dell'articolo (ex addInfoCostoGiacenzaInventario.php).</summary>
        [HttpPost("addInfoCostoGiacenzaInventario")]
        public IActionResult AddInfoCostoGiacenzaInventario([FromBody] GiacArtAddInfoCostoGiacenzaInventarioRequest request)
        {
            return Esegui("addInfoCostoGiacenzaInventario", () => Db.AddInfoCostoGiacenzaInventario(request));
        }

        /// <summary>Indica se il magazzino esiste (ex checkMagazzinoExists.php).</summary>
        [HttpPost("checkMagazzinoExists")]
        public IActionResult CheckMagazzinoExists([FromBody] GiacArtCheckMagazzinoRequest request)
        {
            return Esegui("checkMagazzinoExists", () => Db.CheckMagazzinoExists(request));
        }

        /// <summary>Indica se il magazzino esiste e se ha vani (ex checkMagazzinoExistsAndCheckVani.php).</summary>
        [HttpPost("checkMagazzinoExistsAndCheckVani")]
        public IActionResult CheckMagazzinoExistsAndCheckVani([FromBody] GiacArtCheckMagazzinoRequest request)
        {
            return Esegui("checkMagazzinoExistsAndCheckVani", () => Db.CheckMagazzinoExistsAndCheckVani(request));
        }

        /// <summary>Righe della lista di inventario e giacenze (ex getInventarioFullQuery.php).</summary>
        [HttpPost("getInventarioFullQuery")]
        public IActionResult GetInventarioFullQuery([FromBody] GiacArtGetInventarioFullQueryRequest request)
        {
            return Esegui("getInventarioFullQuery", () => Db.GetInventarioFullQuery(request));
        }

        /// <summary>Distinta in esplosione / implosione (ex getListaDistinte.php).</summary>
        [HttpPost("getListaDistinte")]
        public IActionResult GetListaDistinte([FromBody] GiacArtGetListaDistinteRequest request)
        {
            return Esegui("getListaDistinte", () => Db.GetListaDistinte(request));
        }

        /// <summary>Magazzini e vani con disponibile sufficiente (ex getMagazziniVaniPerModificaPrelievi.php).</summary>
        [HttpPost("getMagazziniVaniPerModificaPrelievi")]
        public IActionResult GetMagazziniVaniPerModificaPrelievi([FromBody] GiacArtGetMagazziniVaniPerModificaPrelieviRequest request)
        {
            return Esegui("getMagazziniVaniPerModificaPrelievi", () => Db.GetMagazziniVaniPerModificaPrelievi(request));
        }

        /// <summary>Vano preferenziale su MGRICAM (ex getMgricamVanoPreferenziale.php).</summary>
        [HttpPost("getMgricamVanoPreferenziale")]
        public IActionResult GetMgricamVanoPreferenziale([FromBody] GiacArtGetMgricamVanoPreferenzialeRequest request)
        {
            return Esegui("getMgricamVanoPreferenziale", () => Db.GetMgricamVanoPreferenziale(request));
        }

        /// <summary>PDF disegni e ultimo PDF AO (ex getPdfList.php).</summary>
        [HttpPost("getPdfList")]
        public IActionResult GetPdfList([FromBody] GiacArtGetPdfListRequest request)
        {
            return Esegui("getPdfList", () => Db.GetPdfList(request, _storage));
        }

        /// <summary>Sezioni dei vani di un magazzino MISK (ex getVaniMovimentoSingolo.php).</summary>
        [HttpPost("getVaniMovimentoSingolo")]
        public IActionResult GetVaniMovimentoSingolo([FromBody] GiacArtGetVaniMovimentoSingoloRequest request)
        {
            return Esegui("getVaniMovimentoSingolo", () => Db.GetVaniMovimentoSingolo(request), request?.societa);
        }

        /// <summary>Ricerca articoli per codice o descrizione (ex selectArticoloLike.php).</summary>
        [HttpPost("selectArticoloLike")]
        public IActionResult SelectArticoloLike([FromBody] GiacArtSelectArticoloLikeRequest request)
        {
            return Esegui("selectArticoloLike", () => Db.SelectArticoloLike(request), request?.societa);
        }

        /// <summary>Dati dell'articolo per i movimenti (ex selectArticoloMagazzini.php).</summary>
        [HttpPost("selectArticoloMagazzini")]
        public IActionResult SelectArticoloMagazzini([FromBody] GiacArtSelectArticoloMagazziniRequest request)
        {
            return Esegui("selectArticoloMagazzini", () => Db.SelectArticoloMagazzini(request), request?.societa);
        }

        /// <summary>Giacenze del magazzino (ex selectGiacenzeInventario.php).</summary>
        [HttpPost("selectGiacenzeInventario")]
        public IActionResult SelectGiacenzeInventario([FromBody] GiacArtSelectGiacenzeInventarioRequest request)
        {
            return Esegui("selectGiacenzeInventario", () => Db.SelectGiacenzeInventario(request));
        }

        /// <summary>Scheda dell'articolo (ex selectSingoloArticolo.php). Articolo inesistente: HTTP 404.</summary>
        [HttpPost("selectSingoloArticolo")]
        public Task<IActionResult> SelectSingoloArticolo([FromBody] GiacArtSelectSingoloArticoloRequest request)
        {
            return EseguiAsync("selectSingoloArticolo", async () => await Db.SelectSingoloArticoloAsync(request, _storage), request?.societa);
        }

        /// <summary>Aggiorna una riga di inventario (ex updateRigaInventario.php).</summary>
        [HttpPost("updateRigaInventario")]
        public IActionResult UpdateRigaInventario([FromBody] GiacArtUpdateRigaInventarioRequest request)
        {
            return Esegui("updateRigaInventario", () => Db.UpdateRigaInventario(request));
        }

        /// <summary>Archivia in ARXivar la foto di un articolo (ex uploadFotoArxivar.php).</summary>
        [HttpPost("uploadFotoArxivar")]
        [Consumes("multipart/form-data")]
        public Task<IActionResult> UploadFotoArxivar([FromForm] GiacArtUploadFotoRequest request)
        {
            return EseguiAsync("uploadFotoArxivar", async () => await Db.UploadFotoArxivarAsync(request, _storage));
        }

        /// <summary>Salva la foto di una riga di inventario (ex uploadFotoInventario.php).</summary>
        [HttpPost("uploadFotoInventario")]
        [Consumes("multipart/form-data")]
        public Task<IActionResult> UploadFotoInventario([FromForm] GiacArtUploadFotoRequest request)
        {
            return EseguiAsync("uploadFotoInventario", async () => await Db.UploadFotoInventarioAsync(request, _storage));
        }

        /// <summary>Invia per email l'excel di inventario CS USA (ex csusa/send_inventory_email.php).</summary>
        [HttpPost("csusa/send_inventory_email")]
        public Task<IActionResult> SendInventoryEmail([FromBody] GiacArtSendInventoryEmailRequest request)
        {
            return EseguiAsync("csusa/send_inventory_email", async () => await Db.SendInventoryEmailAsync(request, _storage, _email), "CSUSA");
        }

        /// <summary>Salva una foto di inventario CS USA (ex csusa/upload_inventory_image.php).</summary>
        [HttpPost("csusa/upload_inventory_image")]
        [Consumes("multipart/form-data")]
        public Task<IActionResult> UploadInventoryImage([FromForm] GiacArtUploadFotoRequest request)
        {
            return EseguiAsync("csusa/upload_inventory_image", async () => await Db.UploadInventoryImageAsync(request, _storage), "CSUSA");
        }

        /// <summary>Crea l'excel di inventario CS USA (ex csusa/write_inventory_excel.php).</summary>
        [HttpPost("csusa/write_inventory_excel")]
        public Task<IActionResult> WriteInventoryExcel([FromBody] GiacArtWriteInventoryExcelRequest request)
        {
            return EseguiAsync("csusa/write_inventory_excel", async () => await Db.WriteInventoryExcelAsync(request, _storage), "CSUSA");
        }
    }
}
