using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Giacenze: liste di inventario, prelievi MGAUT / Automha, mancanti, accettazioni e storico movimenti
    /// (ex mobile/server/query/giacenze/*.php).
    /// </summary>
    [Route("api/giacenze")]
    [ApiController]
    [Authorize]
    public class GiacenzeListeController : MobileControllerBase
    {
        private DBGIACENZE_LISTE Db => _db2Connection.DBGIACENZE_LISTE;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="GiacenzeListeController"/>.
        /// </summary>
        public GiacenzeListeController(MyDbContext db2Connection, ILogger<GiacenzeListeController> logger)
            : base(db2Connection, logger, "GIACENZE")
        {
        }

        // ----- ACCETTAZIONI ------------------------------------------------------------------------------------------

        /// <summary>Testate di precarico non completate con le righe (ex accettazione_get_precarico.php).</summary>
        [HttpPost("accettazione_get_precarico")]
        public IActionResult AccettazioneGetPrecarico()
            => Esegui("accettazione_get_precarico", () => Db.AccettazioneGetPrecarico());

        /// <summary>
        /// Accettazioni di un magazzino e mancanti collegati (ex selectAccettazioni.php).
        /// HTTP 404 se non ci sono movimenti, come nel PHP.
        /// </summary>
        [HttpPost("selectAccettazioni")]
        public IActionResult SelectAccettazioni([FromBody] SelectAccettazioniRequest request)
        {
            var trovate = true;
            var esito = Esegui("selectAccettazioni", () =>
            {
                var risultato = Db.SelectAccettazioni(request, Societa);
                trovate = risultato != null;
                return risultato;
            });

            return trovate ? esito : NotFound(ResultInfo.Error(404, "Nessuna accettazione trovata", null!));
        }

        // ----- STAMPA VERNICIATURA / ODL -----------------------------------------------------------------------------

        /// <summary>Fasi e padre di un ODL per la stampa verniciatura (ex addInfoOdlStampaVern.php).</summary>
        [HttpPost("addInfoOdlStampaVern")]
        public IActionResult AddInfoOdlStampaVern([FromBody] AddInfoOdlStampaVernRequest request)
            => Esegui("addInfoOdlStampaVern", () => Db.AddInfoOdlStampaVern(request, Societa));

        /// <summary>Fasi e padre di un ODL per la stampa verniciatura libera (ex addInfoOdlStampaVernLibera.php).</summary>
        [HttpPost("addInfoOdlStampaVernLibera")]
        public IActionResult AddInfoOdlStampaVernLibera([FromBody] AddInfoOdlStampaVernLiberaRequest request)
            => Esegui("addInfoOdlStampaVernLibera", () => Db.AddInfoOdlStampaVernLibera(request, Societa));

        /// <summary>Descrizione e colore di un padre per la stampa verniciatura libera (ex addInfoPadreStampaVernLibera.php).</summary>
        [HttpPost("addInfoPadreStampaVernLibera")]
        public IActionResult AddInfoPadreStampaVernLibera([FromBody] AddInfoPadreStampaVernLiberaRequest request)
            => Esegui("addInfoPadreStampaVernLibera", () => Db.AddInfoPadreStampaVernLibera(request, Societa));

        /// <summary>Codice e descrizione del padre di un ODL (ex addPadreDescrizioneFixToMovimento.php).</summary>
        [HttpPost("addPadreDescrizioneFixToMovimento")]
        public IActionResult AddPadreDescrizioneFixToMovimento([FromBody] AddPadreDescrizioneFixToMovimentoRequest request)
            => Esegui("addPadreDescrizioneFixToMovimento", () => Db.AddPadreDescrizioneFixToMovimento(request, Societa));

        /// <summary>Fasi di un ODL con destinazione non automatica (ex validateOdlSelectFasi.php).</summary>
        [HttpPost("validateOdlSelectFasi")]
        public IActionResult ValidateOdlSelectFasi([FromBody] ValidateOdlSelectFasiRequest request)
            => Esegui("validateOdlSelectFasi", () => Db.ValidateOdlSelectFasi(request, Societa));

        /// <summary>Cambio ODL: ricerca per ODL, padre o magazzino (ex selectCambioOdl.php).</summary>
        [HttpPost("selectCambioOdl")]
        public IActionResult SelectCambioOdl([FromBody] SelectCambioOdlRequest request)
            => Esegui("selectCambioOdl", () => Db.SelectCambioOdl(request, Societa));

        /// <summary>ODL (e ODV) con destinazione il magazzino indicato (ex getOdlListFromMagDest.php).</summary>
        [HttpPost("getOdlListFromMagDest")]
        public IActionResult GetOdlListFromMagDest([FromBody] GetOdlListFromMagDestRequest request)
            => Esegui("getOdlListFromMagDest", () => Db.GetOdlListFromMagDest(request, Societa));

        // ----- MANCANTI / RIENTRI ------------------------------------------------------------------------------------

        /// <summary>Conteggio mancanti critici per magazzino e data-log (ex countMancantiSearchPage.php).</summary>
        [HttpPost("countMancantiSearchPage")]
        public IActionResult CountMancantiSearchPage()
            => Esegui("countMancantiSearchPage", () => Db.CountMancantiSearchPage(Societa));

        /// <summary>Ultimo data-log dei mancanti (ex getLatestDtrunHrrun.php).</summary>
        [HttpPost("getLatestDtrunHrrun")]
        public IActionResult GetLatestDtrunHrrun()
            => Esegui("getLatestDtrunHrrun", () => Db.GetLatestDtrunHrrun());

        /// <summary>Mancanti / prelievi di un magazzino di impegno (ex selectMancantiDaMag.php).</summary>
        [HttpPost("selectMancantiDaMag")]
        public IActionResult SelectMancantiDaMag([FromBody] SelectMancantiDaMagRequest request)
            => Esegui("selectMancantiDaMag", () => Db.SelectMancantiDaMag(request, Societa));

        /// <summary>Rientri di un magazzino (ex selectRientri.php).</summary>
        [HttpPost("selectRientri")]
        public IActionResult SelectRientri([FromBody] SelectRientriRequest request)
            => Esegui("selectRientri", () => Db.SelectRientri(request));

        // ----- STORICO MOVIMENTI -------------------------------------------------------------------------------------

        /// <summary>Storico movimenti mancanti (ex getStoriaMovimento.php).</summary>
        [HttpPost("getStoriaMovimento")]
        public IActionResult GetStoriaMovimento([FromBody] GetStoriaMovimentoRequest request)
            => Esegui("getStoriaMovimento", () => Db.GetStoriaMovimento(request));

        /// <summary>Movimenti mancanti di oggi dell'utente (ex getStoriaMovimentoOggi.php).</summary>
        [HttpPost("getStoriaMovimentoOggi")]
        public IActionResult GetStoriaMovimentoOggi([FromBody] GetStoriaMovimentoOggiRequest request)
            => Esegui("getStoriaMovimentoOggi", () => Db.GetStoriaMovimentoOggi(request));

        /// <summary>Aggiorna lo stato di un movimento mancanti (ex updateStatoStoriaMovimento.php).</summary>
        [HttpPost("updateStatoStoriaMovimento")]
        public IActionResult UpdateStatoStoriaMovimento([FromBody] UpdateStatoStoriaMovimentoRequest request)
            => Esegui("updateStatoStoriaMovimento", () => Db.UpdateStatoStoriaMovimento(request));

        /// <summary>Storico movimenti MGIS001 dell'ultimo mese (ex getStoriaPrelieviMgis001.php).</summary>
        [HttpPost("getStoriaPrelieviMgis001")]
        public IActionResult GetStoriaPrelieviMgis001([FromBody] GetStoriaPrelieviMgis001Request request)
            => Esegui("getStoriaPrelieviMgis001", () => Db.GetStoriaPrelieviMgis001(request));

        /// <summary>Registra un movimento MGIS001 a nome dell'utente autenticato (ex writeStoriaMovMgis001.php).</summary>
        [HttpPost("writeStoriaMovMgis001")]
        public IActionResult WriteStoriaMovMgis001([FromBody] WriteStoriaMovMgis001Request request)
            => Esegui("writeStoriaMovMgis001", () => Db.WriteStoriaMovMgis001(request, Utente));

        // ----- LISTE INVENTARIO --------------------------------------------------------------------------------------

        /// <summary>Liste di inventario non chiuse (ex getElencoListe.php).</summary>
        [HttpPost("getElencoListe")]
        public IActionResult GetElencoListe()
            => Esegui("getElencoListe", () => Db.GetElencoListe());

        /// <summary>Crea una lista di inventario a nome dell'utente autenticato (ex writeLista.php).</summary>
        [HttpPost("writeLista")]
        public IActionResult WriteLista([FromBody] WriteListaRequest request)
            => Esegui("writeLista", () => Db.WriteLista(request, Utente, Societa));

        /// <summary>Cambia lo stato di una lista; utente di chiusura = utente autenticato (ex cambiaStatoLista.php).</summary>
        [HttpPost("cambiaStatoLista")]
        public IActionResult CambiaStatoLista([FromBody] CambiaStatoListaRequest request)
            => Esegui("cambiaStatoLista", () => Db.CambiaStatoLista(request, Utente));

        /// <summary>Elimina una riga di lista (ex eliminaRiga.php).</summary>
        [HttpPost("eliminaRiga")]
        public IActionResult EliminaRiga([FromBody] EliminaRigaRequest request)
            => Esegui("eliminaRiga", () => Db.EliminaRiga(request));

        /// <summary>Scrive una riga di inventario a nome dell'utente autenticato (ex writeRigaLista.php).</summary>
        [HttpPost("writeRigaLista")]
        public IActionResult WriteRigaLista([FromBody] WriteRigaListaRequest request)
            => Esegui("writeRigaLista", () => Db.WriteRigaLista(request, Utente));

        // ----- PRELIEVI MGAUT / AUTOMHA ------------------------------------------------------------------------------

        /// <summary>Padre e fasi di un ODL per il prelievo MGAUT (ex checkOdlListaPrelievoMgautAndGetFasi.php).</summary>
        [HttpPost("checkOdlListaPrelievoMgautAndGetFasi")]
        public IActionResult CheckOdlListaPrelievoMgautAndGetFasi([FromBody] CheckOdlListaPrelievoMgautAndGetFasiRequest request)
            => Esegui("checkOdlListaPrelievoMgautAndGetFasi", () => Db.CheckOdlListaPrelievoMgautAndGetFasi(request));

        /// <summary>Dati ODV per il prelievo MGAUT (ex checkOdvListaPrelievoMgaut.php).</summary>
        [HttpPost("checkOdvListaPrelievoMgaut")]
        public IActionResult CheckOdvListaPrelievoMgaut([FromBody] CheckOdvListaPrelievoMgautRequest request)
            => Esegui("checkOdvListaPrelievoMgaut", () => Db.CheckOdvListaPrelievoMgaut(request, Societa));

        /// <summary>Cancella (logicamente) una lista di prelievo Automha (ex deleteListaPrelievo.php).</summary>
        [HttpPost("deleteListaPrelievo")]
        public IActionResult DeleteListaPrelievo([FromBody] DeleteListaPrelievoRequest request)
            => Esegui("deleteListaPrelievo", () => Db.DeleteListaPrelievo(request));

        /// <summary>Segna come trasferita una riga Automha (ex updateAutomhaTrasferito.php).</summary>
        [HttpPost("updateAutomhaTrasferito")]
        public IActionResult UpdateAutomhaTrasferito([FromBody] UpdateAutomhaTrasferitoRequest request)
            => Esegui("updateAutomhaTrasferito", () => Db.UpdateAutomhaTrasferito(request));

        /// <summary>Righe di prelievo MGAUT00 / MGAUT10 non uscite (ex getListaMgaut02.php).</summary>
        [HttpPost("getListaMgaut02")]
        public IActionResult GetListaMgaut02()
            => Esegui("getListaMgaut02", () => Db.GetListaMgaut02());

        /// <summary>True se l'articolo dell'attività 0027 è ancora da visualizzare (ex getListaPrelievi0027FromAttivitaCheckScript.php).</summary>
        [HttpPost("getListaPrelievi0027FromAttivitaCheckScript")]
        public IActionResult GetListaPrelievi0027FromAttivitaCheckScript([FromBody] GetListaPrelievi0027FromAttivitaCheckScriptRequest request)
            => Esegui("getListaPrelievi0027FromAttivitaCheckScript", () => Db.GetListaPrelievi0027FromAttivitaCheckScript(request, Societa));

        /// <summary>Righe da trasferire su MGIS001 (ex getListaTrasferimentiMgis001.php).</summary>
        [HttpPost("getListaTrasferimentiMgis001")]
        public IActionResult GetListaTrasferimentiMgis001()
            => Esegui("getListaTrasferimentiMgis001", () => Db.GetListaTrasferimentiMgis001(Societa));

        /// <summary>ODV contenuti in una prebolla (ex mgaut_prel_immediato_get_odv_from_prebolla.php).</summary>
        [HttpPost("mgaut_prel_immediato_get_odv_from_prebolla")]
        public IActionResult MgautPrelImmediatoGetOdvFromPrebolla([FromBody] MgautPrelImmediatoGetOdvFromPrebollaRequest request)
            => Esegui("mgaut_prel_immediato_get_odv_from_prebolla", () => Db.MgautPrelImmediatoGetOdvFromPrebolla(request, Societa));

        /// <summary>Righe di prebolla di un ODV con giacenze MGAUT (ex mgaut_prel_immediato_get_righe_from_odv.php).</summary>
        [HttpPost("mgaut_prel_immediato_get_righe_from_odv")]
        public IActionResult MgautPrelImmediatoGetRigheFromOdv([FromBody] MgautPrelImmediatoGetRigheFromOdvRequest request)
            => Esegui("mgaut_prel_immediato_get_righe_from_odv", () => Db.MgautPrelImmediatoGetRigheFromOdv(request, Societa));

        /// <summary>Articoli ODL/fase prelevabili da MGAUT (ex mgaut_prel_odl_get_articoli.php).</summary>
        [HttpPost("mgaut_prel_odl_get_articoli")]
        public IActionResult MgautPrelOdlGetArticoli([FromBody] MgautPrelOdlGetArticoliRequest request)
            => Esegui("mgaut_prel_odl_get_articoli", () => Db.MgautPrelOdlGetArticoli(request, Societa));

        /// <summary>Magazzini di destinazione ODL per un articolo MGAUT (ex mgaut_prel_odl_get_magazzini.php).</summary>
        [HttpPost("mgaut_prel_odl_get_magazzini")]
        public IActionResult MgautPrelOdlGetMagazzini([FromBody] MgautPrelOdlGetMagazziniRequest request)
            => Esegui("mgaut_prel_odl_get_magazzini", () => Db.MgautPrelOdlGetMagazzini(request, Societa));

        /// <summary>ODL prelevabili da MGAUT per un magazzino di destinazione (ex mgaut_prel_odl_get_odl.php).</summary>
        [HttpPost("mgaut_prel_odl_get_odl")]
        public IActionResult MgautPrelOdlGetOdl([FromBody] MgautPrelOdlGetOdlRequest request)
            => Esegui("mgaut_prel_odl_get_odl", () => Db.MgautPrelOdlGetOdl(request, Societa));

        /// <summary>Articoli ODV prelevabili da MGAUT (ex mgaut_prel_odv_get_articoli.php).</summary>
        [HttpPost("mgaut_prel_odv_get_articoli")]
        public IActionResult MgautPrelOdvGetArticoli([FromBody] MgautPrelOdvGetArticoliRequest request)
            => Esegui("mgaut_prel_odv_get_articoli", () => Db.MgautPrelOdvGetArticoli(request, Societa));

        /// <summary>Magazzini di destinazione ODV per un articolo MGAUT (ex mgaut_prel_odv_get_magazzini.php).</summary>
        [HttpPost("mgaut_prel_odv_get_magazzini")]
        public IActionResult MgautPrelOdvGetMagazzini([FromBody] MgautPrelOdvGetMagazziniRequest request)
            => Esegui("mgaut_prel_odv_get_magazzini", () => Db.MgautPrelOdvGetMagazzini(request, Societa));

        /// <summary>ODV prelevabili da MGAUT per un magazzino di destinazione (ex mgaut_prel_odv_get_odv.php).</summary>
        [HttpPost("mgaut_prel_odv_get_odv")]
        public IActionResult MgautPrelOdvGetOdv([FromBody] MgautPrelOdvGetOdvRequest request)
            => Esegui("mgaut_prel_odv_get_odv", () => Db.MgautPrelOdvGetOdv(request, Societa));
    }
}
