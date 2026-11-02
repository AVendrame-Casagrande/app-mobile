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
        private readonly DisegniTool _disegni;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="GiacenzeArticoliController"/>.
        /// </summary>
        public GiacenzeArticoliController(MyDbContext db2Connection, ILogger<GiacenzeArticoliController> logger,
            StorageTool storage, EmailTool email, DisegniTool disegni)
            : base(db2Connection, logger, "GIACENZE")
        {
            _storage = storage;
            _email = email;
            _disegni = disegni;
        }

        private DBGIACENZE_ARTICOLI Db => _db2Connection.DBGIACENZE_ARTICOLI;

        /// <summary>URL base di queste azioni visto dal client (per i link a foto e disegni).</summary>
        private string UrlApi => $"{Request.Scheme}://{Request.Host}{Request.PathBase}/api/giacenze";

        /// <summary>Ultimo costo CATT dell'articolo (ex addInfoCostoGiacenzaInventario.php).</summary>
        [HttpPost("addInfoCostoGiacenzaInventario")]
        public IActionResult AddInfoCostoGiacenzaInventario([FromBody] GiacArtAddInfoCostoGiacenzaInventarioRequest request)
        {
            return Esegui("addInfoCostoGiacenzaInventario", () => Db.AddInfoCostoGiacenzaInventario(request, Societa));
        }

        /// <summary>Indica se il magazzino esiste (ex checkMagazzinoExists.php).</summary>
        [HttpPost("checkMagazzinoExists")]
        public IActionResult CheckMagazzinoExists([FromBody] GiacArtCheckMagazzinoRequest request)
        {
            return Esegui("checkMagazzinoExists", () => Db.CheckMagazzinoExists(request, Societa));
        }

        /// <summary>Indica se il magazzino esiste e se ha vani (ex checkMagazzinoExistsAndCheckVani.php).</summary>
        [HttpPost("checkMagazzinoExistsAndCheckVani")]
        public IActionResult CheckMagazzinoExistsAndCheckVani([FromBody] GiacArtCheckMagazzinoRequest request)
        {
            return Esegui("checkMagazzinoExistsAndCheckVani", () => Db.CheckMagazzinoExistsAndCheckVani(request, Societa));
        }

        /// <summary>Righe della lista di inventario e giacenze (ex getInventarioFullQuery.php).</summary>
        [HttpPost("getInventarioFullQuery")]
        public IActionResult GetInventarioFullQuery([FromBody] GiacArtGetInventarioFullQueryRequest request)
        {
            return Esegui("getInventarioFullQuery", () => Db.GetInventarioFullQuery(request, Societa));
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
            return Esegui("getMagazziniVaniPerModificaPrelievi", () => Db.GetMagazziniVaniPerModificaPrelievi(request, Societa));
        }

        /// <summary>Vano preferenziale su MGRICAM (ex getMgricamVanoPreferenziale.php).</summary>
        [HttpPost("getMgricamVanoPreferenziale")]
        public IActionResult GetMgricamVanoPreferenziale([FromBody] GiacArtGetMgricamVanoPreferenzialeRequest request)
        {
            return Esegui("getMgricamVanoPreferenziale", () => Db.GetMgricamVanoPreferenziale(request, Societa));
        }

        /// <summary>PDF disegni e ultimo PDF AO (ex getPdfList.php).</summary>
        [HttpPost("getPdfList")]
        public IActionResult GetPdfList([FromBody] GiacArtGetPdfListRequest request)
        {
            return Esegui("getPdfList", () => Db.GetPdfList(request, Societa, _storage, _disegni, UrlApi));
        }

        /// <summary>Sezioni dei vani di un magazzino MISK (ex getVaniMovimentoSingolo.php).</summary>
        [HttpPost("getVaniMovimentoSingolo")]
        public IActionResult GetVaniMovimentoSingolo([FromBody] GiacArtGetVaniMovimentoSingoloRequest request)
        {
            return Esegui("getVaniMovimentoSingolo", () => Db.GetVaniMovimentoSingolo(request));
        }

        /// <summary>Ricerca articoli per codice o descrizione (ex selectArticoloLike.php).</summary>
        [HttpPost("selectArticoloLike")]
        public IActionResult SelectArticoloLike([FromBody] GiacArtSelectArticoloLikeRequest request)
        {
            return Esegui("selectArticoloLike", () => Db.SelectArticoloLike(request, Societa));
        }

        /// <summary>Dati dell'articolo per i movimenti (ex selectArticoloMagazzini.php).</summary>
        [HttpPost("selectArticoloMagazzini")]
        public IActionResult SelectArticoloMagazzini([FromBody] GiacArtSelectArticoloMagazziniRequest request)
        {
            return Esegui("selectArticoloMagazzini", () => Db.SelectArticoloMagazzini(request, Societa));
        }

        /// <summary>Giacenze del magazzino (ex selectGiacenzeInventario.php).</summary>
        [HttpPost("selectGiacenzeInventario")]
        public IActionResult SelectGiacenzeInventario([FromBody] GiacArtSelectGiacenzeInventarioRequest request)
        {
            return Esegui("selectGiacenzeInventario", () => Db.SelectGiacenzeInventario(request, Societa));
        }

        /// <summary>Scheda dell'articolo (ex selectSingoloArticolo.php). Articolo inesistente: HTTP 404.</summary>
        [HttpPost("selectSingoloArticolo")]
        public Task<IActionResult> SelectSingoloArticolo([FromBody] GiacArtSelectSingoloArticoloRequest request)
        {
            return EseguiAsync("selectSingoloArticolo", async () => await Db.SelectSingoloArticoloAsync(request, Societa, _storage, _disegni, UrlApi));
        }

        /// <summary>
        /// PDF di un disegno dell'archivio di rete. Il link (firmato, con scadenza) arriva da selectSingoloArticolo o
        /// getPdfList: non serve il token, così il PDF si apre anche nel visualizzatore del telefono.
        /// </summary>
        /// <param name="nomeFile">Nome del PDF.</param>
        /// <param name="exp">Scadenza del link (secondi Unix).</param>
        /// <param name="sig">Firma del link.</param>
        [AllowAnonymous]
        [HttpGet("disegno/{nomeFile}")]
        public Task<IActionResult> Disegno(string nomeFile, [FromQuery] long exp, [FromQuery] string? sig)
        {
            return EseguiRispostaAsync("disegno", () =>
            {
                IActionResult risposta;
                try
                {
                    var percorso = _disegni.Percorso(nomeFile, exp, sig);
                    risposta = PhysicalFile(percorso, "application/pdf");
                }
                catch (MobileException ex) when (ex.Code == 403)
                {
                    risposta = StatusCode(403, ResultInfo.Error(ex.Code, ex.Message, null!));
                }
                return Task.FromResult(risposta);
            });
        }

        /// <summary>
        /// Foto ARXivar di un articolo (i link sono in arrayImmagini di selectSingoloArticolo): il jpg viene letto da
        /// ARXivar e inviato direttamente, senza copiarlo nella cartella del server.
        /// </summary>
        /// <param name="docNumber">Numero del documento ARXivar.</param>
        /// <param name="articolo">Codice articolo a cui la foto deve appartenere.</param>
        [HttpGet("fotoArxivar/{docNumber:int}")]
        public Task<IActionResult> FotoArxivar(int docNumber, [FromQuery] string? articolo)
        {
            return EseguiRispostaAsync("fotoArxivar", async () =>
            {
                var contenuto = await Db.GetFotoArxivarFileAsync(articolo, docNumber);
                Response.Headers.CacheControl = "private, max-age=3600";
                return File(contenuto, "image/jpeg");
            });
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
            return EseguiAsync("csusa/send_inventory_email", async () => await Db.SendInventoryEmailAsync(request, _storage, _email));
        }

        /// <summary>Salva una foto di inventario CS USA (ex csusa/upload_inventory_image.php).</summary>
        [HttpPost("csusa/upload_inventory_image")]
        [Consumes("multipart/form-data")]
        public Task<IActionResult> UploadInventoryImage([FromForm] GiacArtUploadFotoRequest request)
        {
            return EseguiAsync("csusa/upload_inventory_image", async () => await Db.UploadInventoryImageAsync(request, _storage));
        }

        /// <summary>Crea l'excel di inventario CS USA (ex csusa/write_inventory_excel.php).</summary>
        [HttpPost("csusa/write_inventory_excel")]
        public Task<IActionResult> WriteInventoryExcel([FromBody] GiacArtWriteInventoryExcelRequest request)
        {
            return EseguiAsync("csusa/write_inventory_excel", async () => await Db.WriteInventoryExcelAsync(request, _storage));
        }
    }
}
