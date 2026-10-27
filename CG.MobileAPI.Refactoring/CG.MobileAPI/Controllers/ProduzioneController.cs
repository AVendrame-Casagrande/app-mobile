using System.Net.Mail;
using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Servizi di produzione: impegno ODL, situazione ODL, pre-carico, qualità, pallinatura e prestazioni
    /// (ex mobile/server/query/produzione, getTipoArticolo.php e UpdateSOSACPN.php di Diapason).
    /// </summary>
    [Route("api/produzione")]
    [ApiController]
    [Authorize]
    public class ProduzioneController : MobileControllerBase
    {
        private readonly DiapasonExe _diapasonExe;
        private readonly StorageTool _storage;
        private readonly EmailTool _email;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="ProduzioneController"/>.
        /// </summary>
        public ProduzioneController(MyDbContext db2Connection, ILogger<ProduzioneController> logger,
            DiapasonExe diapasonExe, StorageTool storage, EmailTool email)
            : base(db2Connection, logger, "PRODUZIONE")
        {
            _diapasonExe = diapasonExe;
            _storage = storage;
            _email = email;
        }

        private DBPRODUZIONE Db => _db2Connection.DBPRODUZIONE;

        // -------------------------------------------------------------------------------------------------------------
        // --- Impegno ODL ---------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Tipo articolo (MTYPN) di un codice (ex casagrande-app-web/.../ImpegnoOdl/getTipoArticolo.php).
        /// </summary>
        /// <returns><c>{tipoArticolo}</c> oppure <c>{error}</c>.</returns>
        [HttpPost("getTipoArticolo")]
        public IActionResult GetTipoArticolo([FromBody] GetTipoArticoloRequest request)
        {
            return Esegui("GetTipoArticolo", () => Db.GetTipoArticolo(request.codice));
        }

        /// <summary>
        /// Impegno su Diapason con ConSOSACPN.exe (ex [10.0.2.1]/applicazioni/produzione/UpdateSOSACPN.php).
        /// I parametri devono avere la forma "P|T ADD|REP|DEL odl articolo fase [qta]".
        /// </summary>
        /// <returns>L'output dell'eseguibile ('0000 OPERAZIONE ESEGUITA' se riuscito).</returns>
        [HttpPost("updateSOSACPN")]
        public async Task<IActionResult> UpdateSOSACPN([FromBody] UpdateSosacpnRequest request)
        {
            return await EseguiAsync("UpdateSOSACPN", async () =>
            {
                var parametri = DBPRODUZIONE.ValidaParametriSosacpn(request.parametri);
                return await _diapasonExe.UpdateSosacpnAsync(parametri);
            });
        }

        /// <summary>
        /// Articoli già impegnati sull'ODL nella fase (ex query/produzione/addArticoliImpegnoOdl.php).
        /// </summary>
        [HttpPost("addArticoliImpegnoOdl")]
        public IActionResult AddArticoliImpegnoOdl([FromBody] AddArticoliImpegnoOdlRequest request)
        {
            return Esegui("AddArticoliImpegnoOdl", () =>
            {
                if (string.IsNullOrWhiteSpace(request.fase)) throw new MobileException("Fase obbligatoria");
                return Db.AddArticoliImpegnoOdl(request);
            });
        }

        /// <summary>
        /// Disponibilità dell'articolo in MGAUT00, MGAUT10 e MISK* (ex query/produzione/checkImpegnoGiacenzaArticolo.php).
        /// </summary>
        [HttpPost("checkImpegnoGiacenzaArticolo")]
        public IActionResult CheckImpegnoGiacenzaArticolo([FromBody] CheckImpegnoGiacenzaArticoloRequest request)
        {
            return Esegui("CheckImpegnoGiacenzaArticolo", () =>
            {
                if (string.IsNullOrWhiteSpace(request.codiceArticolo)) throw new MobileException("Codice articolo obbligatorio");
                return Db.CheckImpegnoGiacenzaArticolo(request.codiceArticolo);
            });
        }

        /// <summary>
        /// Magazzino di destinazione dell'ODL nella fase, 'Nessuno' se assente (ex query/produzione/returnMagazzinoFromImpegnoOdl.php).
        /// </summary>
        [HttpPost("returnMagazzinoFromImpegnoOdl")]
        public IActionResult ReturnMagazzinoFromImpegnoOdl([FromBody] ReturnMagazzinoFromImpegnoOdlRequest request)
        {
            return Esegui("ReturnMagazzinoFromImpegnoOdl", () => Db.ReturnMagazzinoFromImpegnoOdl(request));
        }

        /// <summary>
        /// ODL/fasi su cui impegnare, cercando per ODL, padre o magazzino (ex query/produzione/selectImpegniOdl.php).
        /// Le fasi visibili dipendono dall'utente del token.
        /// </summary>
        [HttpPost("selectImpegniOdl")]
        public IActionResult SelectImpegniOdl([FromBody] SelectImpegniOdlRequest request)
        {
            return Esegui("SelectImpegniOdl", () => Db.SelectImpegniOdl(request.codiceOdl_Padre_Mag, request.fase, Utente));
        }

        /// <summary>
        /// Email di notifica dell'impegno al responsabile e ai destinatari fissi (ex query/produzione/sendImpegniEmail.php).
        /// </summary>
        /// <returns>"1" se inviata.</returns>
        [HttpPost("sendImpegniEmail")]
        public async Task<IActionResult> SendImpegniEmail([FromBody] SendImpegniEmailRequest request)
        {
            return await EseguiAsync("SendImpegniEmail", async () =>
            {
                var target = (request.emailTarget ?? "").Trim();
                if (target != "" && !MailAddress.TryCreate(target, out _))
                {
                    throw new MobileException("Indirizzo email non valido");
                }

                var oggetto = DBPRODUZIONE.OggettoEmailImpegni(request);
                var corpo = request.messaggio ?? "";

                // Il PHP metteva i destinatari fissi in BCC: EmailTool non gestisce il BCC, quindi il destinatario
                // riceve la sua copia e i destinatari fissi una copia separata (non vedono e non sono visti dal destinatario).
                if (target != "")
                {
                    await _email.InviaAsync(new[] { target }, oggetto, corpo);
                }
                await _email.InviaAsync(DBPRODUZIONE.DestinatariFissiImpegni, oggetto, corpo);
                return "1";
            });
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Permessi ------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Sezioni pre-carico e pallinatura abilitate per l'utente del token (ex query/produzione/checkPermessiSezioniProduzione.php).
        /// </summary>
        /// <returns><c>{pre_carico, pallinatura}</c>.</returns>
        [HttpPost("checkPermessiSezioniProduzione")]
        public IActionResult CheckPermessiSezioniProduzione()
        {
            return Esegui("CheckPermessiSezioniProduzione", () => DBPRODUZIONE.CheckPermessiSezioniProduzione(Utente));
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Situazione ODL ------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// ODL di primo livello dell'ODL (ex query/produzione/getListaNonni.php).
        /// </summary>
        [HttpPost("getListaNonni")]
        public IActionResult GetListaNonni([FromBody] GetListaNonniRequest request)
        {
            return Esegui("GetListaNonni", () => Db.GetListaNonni(request.odl));
        }

        /// <summary>
        /// ODL con componenti critici che contengono il testo nel numero o nel padre (ex query/produzione/selectSituazioneCheckOdl.php).
        /// </summary>
        [HttpPost("selectSituazioneCheckOdl")]
        public IActionResult SelectSituazioneCheckOdl([FromBody] SelectSituazioneCheckOdlRequest request)
        {
            return Esegui("SelectSituazioneCheckOdl", () => Db.SelectSituazioneCheckOdl(request.odl_padre));
        }

        /// <summary>
        /// Situazione dei componenti critici dell'ODL (ex query/produzione/selectSituazioneOdl.php).
        /// </summary>
        [HttpPost("selectSituazioneOdl")]
        public IActionResult SelectSituazioneOdl([FromBody] SelectSituazioneOdlRequest request)
        {
            return Esegui("SelectSituazioneOdl", () => Db.SelectSituazioneOdl(request.odl));
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Prestazioni ---------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Magazzini con inserimenti fase 0027 nell'ultimo mese (ex query/produzione/getMagazziniPrestazioniSelect.php).
        /// </summary>
        [HttpPost("getMagazziniPrestazioniSelect")]
        public IActionResult GetMagazziniPrestazioniSelect()
        {
            return Esegui("GetMagazziniPrestazioniSelect", () => Db.GetMagazziniPrestazioniSelect());
        }

        /// <summary>
        /// Inserimenti fase 0027 dell'ultimo mese nel magazzino (ex query/produzione/getPrestazioniMagazzino.php).
        /// </summary>
        [HttpPost("getPrestazioniMagazzino")]
        public IActionResult GetPrestazioniMagazzino([FromBody] GetPrestazioniMagazzinoRequest request)
        {
            return Esegui("GetPrestazioniMagazzino", () => Db.GetPrestazioniMagazzino(request.magazzino));
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Qualità -------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Codici R ricondizionati nei magazzini MIRC con lo stato di conferma (ex query/produzione/getQualita.php).
        /// </summary>
        [HttpPost("getQualita")]
        public IActionResult GetQualita()
        {
            return Esegui("GetQualita", () => Db.GetQualita());
        }

        /// <summary>
        /// Arrivi di merce filtrati (ex query/produzione/getQualitaArrivi.php).
        /// </summary>
        [HttpPost("getQualitaArrivi")]
        public IActionResult GetQualitaArrivi([FromBody] GetQualitaArriviRequest request)
        {
            return Esegui("GetQualitaArrivi", () => Db.GetQualitaArrivi(request), request.societa);
        }

        /// <summary>
        /// Conferma o elimina la conferma qualità di articolo/bolla (ex query/produzione/confirmDeleteQualita.php).
        /// L'utente che conferma è quello del token.
        /// </summary>
        /// <returns>L'id della conferma inserita, 0 altrimenti.</returns>
        [HttpPost("confirmDeleteQualita")]
        public IActionResult ConfirmDeleteQualita([FromBody] ConfirmDeleteQualitaRequest request)
        {
            return Esegui("ConfirmDeleteQualita", () => Db.ConfirmDeleteQualita(request, Utente));
        }

        /// <summary>
        /// Foto del controllo qualità in storage/qualita_foto (ex query/produzione/uploadFotoQualita.php).
        /// </summary>
        /// <returns>'uploaded' oppure 'error'.</returns>
        [HttpPost("uploadFotoQualita")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadFotoQualita([FromForm] UploadFotoQualitaRequest request)
        {
            return await EseguiAsync("UploadFotoQualita", async () =>
            {
                if (string.IsNullOrWhiteSpace(request.name)) throw new MobileException("Nome foto obbligatorio");
                var nome = request.name.Replace("/", "_").Replace("*", "_") + ".jpg";
                var ok = await _storage.SalvaAsync(request.file, DBPRODUZIONE.CARTELLA_FOTO_QUALITA, nome, StorageTool.Immagini);
                return ok ? "uploaded" : "error";
            });
        }

        /// <summary>
        /// Foto di pallinatura nella cartella storage/pallinatura/{nome portale} dell'utente del token
        /// (ex query/produzione/uploadFotoPallinatura.php). La cartella non viene creata: se manca l'utente non è abilitato.
        /// </summary>
        /// <returns>'uploaded' oppure 'error'.</returns>
        [HttpPost("uploadFotoPallinatura")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadFotoPallinatura([FromForm] UploadFotoPallinaturaRequest request)
        {
            return await EseguiAsync("UploadFotoPallinatura", async () =>
            {
                if (string.IsNullOrWhiteSpace(request.name)) throw new MobileException("Nome foto obbligatorio");
                if (string.IsNullOrWhiteSpace(NomePortale)) return "error";

                var cartella = DBPRODUZIONE.CARTELLA_PALLINATURA + "/" + StorageTool.NomeSicuro(NomePortale);
                var ok = await _storage.SalvaAsync(request.file, cartella, request.name + ".jpg", StorageTool.Immagini, creaCartella: false);
                return ok ? "uploaded" : "error";
            });
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Pre-carico ----------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Crea una nuova lista di pre-carico; l'utente di creazione è quello del token (ex query/produzione/uploadListaPrecarico.php).
        /// </summary>
        /// <returns>La sequenza assegnata alla lista.</returns>
        [HttpPost("uploadListaPrecarico")]
        public IActionResult UploadListaPrecarico([FromBody] UploadListaPrecaricoRequest request)
        {
            return Esegui("UploadListaPrecarico", () =>
            {
                if (string.IsNullOrWhiteSpace(request.odl) || string.IsNullOrWhiteSpace(request.fase))
                {
                    throw new MobileException("ODL e fase obbligatori");
                }
                return Db.UploadListaPrecarico(request, Utente);
            });
        }

        /// <summary>
        /// Modifica una lista di pre-carico non ancora completata (ex query/produzione/modifyListaPrecarico.php).
        /// </summary>
        /// <returns>'updated'.</returns>
        [HttpPost("modifyListaPrecarico")]
        public IActionResult ModifyListaPrecarico([FromBody] ModifyListaPrecaricoRequest request)
        {
            return Esegui("ModifyListaPrecarico", () => Db.ModifyListaPrecarico(request));
        }

        /// <summary>
        /// Completa le liste di pre-carico caricate dal magazzino; l'utente di completamento è quello del token
        /// (ex query/produzione/updateListaPrecarico.php).
        /// </summary>
        /// <returns>'updated'.</returns>
        [HttpPost("updateListaPrecarico")]
        public IActionResult UpdateListaPrecarico([FromBody] UpdateListaPrecaricoRequest request)
        {
            return Esegui("UpdateListaPrecarico", () => Db.UpdateListaPrecarico(request, Utente));
        }

        /// <summary>
        /// Segna come revisionata una lista di pre-carico (ex query/produzione/updateListaPrecaricoSegnaComeRevisionata.php).
        /// </summary>
        /// <returns>'updated'.</returns>
        [HttpPost("updateListaPrecaricoSegnaComeRevisionata")]
        public IActionResult UpdateListaPrecaricoSegnaComeRevisionata([FromBody] UpdateListaPrecaricoSegnaComeRevisionataRequest request)
        {
            return Esegui("UpdateListaPrecaricoSegnaComeRevisionata", () => Db.UpdateListaPrecaricoSegnaComeRevisionata(request.id));
        }

        /// <summary>
        /// Elimina una lista di pre-carico (ex query/produzione/eliminaListaPrecarico.php).
        /// </summary>
        /// <returns>'deleted'.</returns>
        [HttpPost("eliminaListaPrecarico")]
        public IActionResult EliminaListaPrecarico([FromBody] ListaPrecaricoKeyRequest request)
        {
            return Esegui("EliminaListaPrecarico", () => Db.EliminaListaPrecarico(request));
        }

        /// <summary>
        /// Liste di pre-carico dell'utente del token, recenti o non completate, con le righe (ex query/produzione/getStoriaPrecarico.php).
        /// </summary>
        [HttpPost("getStoriaPrecarico")]
        public IActionResult GetStoriaPrecarico([FromBody] GetStoriaPrecaricoRequest? request)
        {
            return Esegui("GetStoriaPrecarico", () => Db.GetStoriaPrecarico(Utente));
        }
    
        /// <summary>
        /// Registra un impegno in fase 0027 (ex query/produzione/writeInserimentoFase0027.php).
        /// </summary>
        /// <returns>'uploaded'.</returns>
        [HttpPost("writeInserimentoFase0027")]
        public IActionResult WriteInserimentoFase0027([FromBody] InserimentoFase0027Request request)
        {
            return Esegui("WriteInserimentoFase0027", () => Db.WriteInserimentoFase0027(request));
        }

        /// <summary>
        /// Elimina l'ultimo impegno in fase 0027 di articolo, ODL e magazzino (ex query/produzione/deleteInserimentoFase0027.php).
        /// </summary>
        /// <returns>'deleted'.</returns>
        [HttpPost("deleteInserimentoFase0027")]
        public IActionResult DeleteInserimentoFase0027([FromBody] InserimentoFase0027Request request)
        {
            return Esegui("DeleteInserimentoFase0027", () => Db.DeleteInserimentoFase0027(request));
        }
    }
}
