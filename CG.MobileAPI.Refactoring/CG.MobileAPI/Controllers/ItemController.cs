using System.Text.Json;
using System.Text.Json.Nodes;
using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Controller per la gestione delle operazioni sugli articoli.
    /// </summary>
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ItemController : ControllerBase
    {
        private readonly MyDbContext _db2Connection;
        private readonly ILogger<ItemController> _logger;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="ItemController"/>.
        /// </summary>
        /// <param name="db2Connection">Il contesto di database per l'accesso ai dati.</param>
        public ItemController(MyDbContext db2Connection, ILogger<ItemController> logger)
        {
            _db2Connection = db2Connection;
            _logger = logger;
        }

        /// <summary>
        /// Esegue l'esplosione scalare di un articolo.
        /// </summary>
        /// <param name="request">Il modello contenente le informazioni necessarie, come l'identificativo dell'articolo, la versione del listino, il codice TL e il codice società.</param>
        /// <returns>Un oggetto IActionResult contenente il risultato dell'operazione.</returns>
        [HttpPost("getEsplosioneScalare")]
        public IActionResult GetEsplosioneScalare([FromBody] ItemESRequestModel request)
        {
            Console.WriteLine($"Richiesta ricevuta in data {DateTime.Now.ToString("dd-MM-yyyy HH:mm:ss")}");

            if (request == null)
            {
                return BadRequest("Il codice articolo è nullo.");
            }

            var societa = request.CodiceSocieta;
            var requester = request.Requester;
            var username = request.RequesterUser;
            var activePage = request.ActivePage;

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetEsplosioneScalare"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetEsplosioneScalareArticolo(
                        articolo: request.ArticoloId,
                        request.CodiceSocieta);

                    _logger.LogInformation("L'utente {Username} ha richiesto l'esplosione scalare di un articolo", username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore nella richiesta dell'esplosione scalare da parte di {Username}", username);
                    return StatusCode(-100, ex);
                }
            }
        }

        [HttpPost("getEsplosioneScalareR")]
        public IActionResult GetEsplosioneScalareR([FromBody] ItemESRequestModel request)
        {
            Console.WriteLine($"Richiesta ricevuta in data {DateTime.Now.ToString("dd-MM-yyyy HH:mm:ss")}");

            if (request == null)
            {
                return BadRequest("Il codice articolo è nullo.");
            }

            var societa = request.CodiceSocieta;
            var requester = request.Requester;
            var username = request.RequesterUser;
            var activePage = request.ActivePage;

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetEsplosioneScalareR"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetEsplosioneScalareR(request.VersioneListino, request.CodiceTL, request.ArticoloId, request.TipoEsplosione, request.CodiceSocieta);

                    _logger.LogInformation("L'utente {Username} ha richiesto l'esplosione scalare di un articolo", username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore nella richiesta dell'esplosione scalare da parte di {Username}", username);
                    return StatusCode(-100, ex);
                }
            }
        }

        [HttpPost("getArticoloMatricoleRilevate")]
        public IActionResult GetArticoloMatricoleRilevate([FromBody] Dictionary<string, object> request)
        {
            Console.WriteLine($"Richiesta ricevuta in data {DateTime.Now.ToString("dd-MM-yyyy HH:mm:ss")}");

            if (request == null)
            {
                return BadRequest("Il codice articolo è nullo.");
            }

            var societa = request["REQUESTER_CODSOC"].ToString();
            var requester = request["REQUESTER"].ToString();
            var username = request["REQUESTER_USER"].ToString();
            var activePage = request["REQUESTER_PAGE"].ToString();
            var articoloPadre = request["CODICE_ARTICOLO"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetEsplosioneScalare"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetArticoloMatricoleRilevate(articoloPadre, societa);

                    _logger.LogInformation("L'utente {Username} ha richiesto l'esplosione scalare di un articolo", username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore nella richiesta dell'esplosione scalare da parte di {Username}", username);
                    return StatusCode(-100, ex);
                }
            }
        }

        /// <summary>
        /// Recupera le informazioni dettagliate di un articolo.
        /// </summary>
        /// <param name="request">Il modello contenente l'identificativo dell'articolo e il codice società.</param>
        /// <returns>Un oggetto IActionResult contenente le informazioni dell'articolo.</returns>
        [HttpPost("getInfoArticolo")]
        public IActionResult GetInfoArticolo([FromBody] ItemESRequestModel request)
        {
            if (request == null)
            {
                return BadRequest("Il codice articolo è nullo.");
            }

            var societa = request.CodiceSocieta;
            var requester = request.Requester;
            var username = request.RequesterUser;

            var activePage = request.ActivePage;

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetInfoArticolo"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetInfoArticolo(request.ArticoloId, request.CodiceSocieta);

                    _logger.LogInformation("Informazioni articolo {articoloID} richieste da utente {username}", request.ArticoloId, username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante estrazione info articolo {articoloId} da utente {username}", request.ArticoloId, username);

                    return StatusCode(-100, ex);
                }
            }
        }

        [AllowAnonymous]
        [HttpPost("getPrezzoArticolo")]
        public IActionResult GetPrezzoArticolo([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null)
            {
                return BadRequest("Il codice articolo è nullo.");
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            string codiceArticolo = request["CODICE_ARTICOLO"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetPrezzoArticolo"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetPrezzoArticolo(codiceArticolo, societa);

                    _logger.LogInformation("Prezzo articolo {articoloID} richieste da utente {username}", codiceArticolo, username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante estrazione prezzo articolo {articoloId} da utente {username}", codiceArticolo, username);

                    return StatusCode(-100, ex);
                }
            }
        }

        /// <summary>
        /// Recupera una lista di articoli in base alla descrizione.
        /// </summary>
        /// <param name="request">Il modello contenente la descrizione dell'articolo e il codice società.</param>
        /// <returns>Un oggetto IActionResult contenente la lista degli articoli trovati.</returns>
        [HttpPost("getDescArticolo")]
        public IActionResult GetDescArticolo([FromBody] ItemESRequestModel request)
        {
            if (request == null)
            {
                return BadRequest("La descrizione articolo è nulla.");
            }

            var societa = request.CodiceSocieta;
            var requester = request.Requester;
            var username = request.RequesterUser;

            var activePage = request.ActivePage;

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetDescArticolo"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetDescArticolo(request.Description, request.CodiceSocieta);

                    _logger.LogInformation("Descrizione articolo {id} richiesta da {username}", request.ArticoloId, username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante estrazione descrizione articolo {id} richiesta da {username}", request.ArticoloId, username);

                    return StatusCode(-100, ex);
                }
            }
        }

        /// <summary>
        /// Recupera le foto associate a un articolo da Arxivar.
        /// </summary>
        /// <param name="request"></param>
        /// <returns></returns>
        [HttpPost("getFotoArticolo")]
        public async Task<IActionResult> GetFotoArticolo([FromBody] Dictionary<string, dynamic> request)
        {

            if (request == null || !request.ContainsKey("REQUESTER_CODSOC") || !request.ContainsKey("REQUESTER") || !request.ContainsKey("REQUESTER_USER")
                || !request.ContainsKey("idArticolo") || !request.ContainsKey("SocArx"))
            {
                return BadRequest("Request vuoto o con valori paziali");
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();
            string idArticolo = request["idArticolo"];
            string societaArx = request["SocArx"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetFotoArticolo"
            }))
            {

                try
                {
                    if (request[""])
                    {

                    }

                    Dictionary<string, JsonElement> searchingVal = new()
                    {
                        { "idDocFather", JsonSerializer.SerializeToElement(2) }, // Classe documentale 1FORDOR
                        { "idDoc", JsonSerializer.SerializeToElement(3) }, // Tipo documento 1FORDOR
                        { "searchFields", JsonSerializer.SerializeToElement(new ArxSearchElement[] { new ArxSearchElement("TABLE1_3", "string", idArticolo, 3, false) }) }, // Ricerca il numero di documento
                        { "selectFields", JsonSerializer.SerializeToElement(new ArxSelectElement[] { new ArxSelectElement("DOCNUMBER", true, "asc", 0) }) }, // Seleziona il nome del file
                        { "societa", JsonSerializer.SerializeToElement(societaArx) } // Società 
                    };


                    //Esegue la ricerca dei documenti in ARXivar
                    List<List<string>> documents = await ArxHelper.GetArxData(searchingVal);

                    // Assegno gli Id che possiedono un documento
                    List<int> systemIds = new List<int>();
                    foreach (List<string> document in documents)
                    {
                        systemIds.Add(int.Parse(document[0]));
                    }

                    var response = await ArxHelper.GetArxFiles(systemIds);

                    // Percorso della cartella sul Desktop
                    string desktopPath = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
                    string cartellaDestinazione = System.IO.Path.Combine(desktopPath, "ImmaginiSalvate");

                    // Crea la cartella se non esiste
                    if (!Directory.Exists(cartellaDestinazione))
                    {
                        Directory.CreateDirectory(cartellaDestinazione);
                    }

                    int i = 0;
                    foreach (byte[] imageData in response)
                    {
                        // Percorso completo del file
                        string percorsoCompleto = System.IO.Path.Combine(cartellaDestinazione, "Immagine" + i + ".jpg");

                        // Converte l'array di byte in immagine
                        using (MemoryStream ms = new MemoryStream(imageData))
                        using (System.Drawing.Image image = System.Drawing.Image.FromStream(ms))
                        {
                            image.Save(percorsoCompleto); // Salvataggio automatico con estensione corretta da nomeFile
                        }
                        i++;
                    }

                    _logger.LogInformation("L'utente {usr} ha richiesto le foto da Arxivar per l'articolo {id}", username, idArticolo);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante la richiesta delle foto da Arxivar dell'utente {usr} per l'articolo {id}", username, idArticolo);

                    return StatusCode(-100, ex);
                }
            }
        }

        [HttpPost("getAllArticoli")]
        public IActionResult GetAllArticoli([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetArticoli"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetArticoliSocieta(societa, all: true);

                    _logger.LogInformation("Estratti gli articoli della società {societa} dall'utente {codusr}", societa, username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante estrazione articoli società {codSoc} da utente {username}", societa, username);

                    return StatusCode(500, ex);
                }
            }
        }

        [HttpPost("getArticoli")]
        public IActionResult GetArticoli([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetArticoli"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetArticoliSocieta(societa);

                    _logger.LogInformation("Estratti gli articoli della società {societa} dall'utente {codusr}", societa, username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante estrazione articoli società {codSoc} da utente {username}", societa, username);

                    return StatusCode(500, ex);
                }
            }
        }

        [HttpPost("getMatricole")]
        public IActionResult GetMatricole([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetArticoli"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetMatricole(societa);

                    _logger.LogInformation("Estratti le matricole della società {societa} dall'utente {codusr}", societa, username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante estrazione matricole società {codSoc} da utente {username}", societa, username);

                    return StatusCode(500, ex);
                }
            }
        }

        [HttpPost("getItemsTranslation")]
        public IActionResult GetItemsTranslation([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            var righeElem = (JsonElement)request["RIGHE"];

            var righe = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(righeElem.GetRawText());
            var lingua = request["LINGUA"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetItemsTranslation"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetArticoliTraduzioni(righe, lingua);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    return StatusCode(500, ex);
                }
            }

        }

        [HttpPost("getItemsFMInfo")]
        public IActionResult GetItemsFMInfo([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "getItemsFMInfo"
            }))
            {
                try
                {
                    var response = new Dictionary<string, object>()
                    {
                        ["FM_LIST"] = _db2Connection.DBSAITE.GetItemsFM(societa),
                        ["LISTA_PRIOR"] = _db2Connection.DBSAITE.GetFmPrior(societa)
                    };

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    return StatusCode(500, ex);
                }
            }

        }

        [HttpPost("savePriorFm")]
        public IActionResult SavePriorFm([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "getItemsFMInfo"
            }))
            {
                try
                {
                    var righeElem = (JsonElement)request["LISTA_PRIOR"];
                    var righe = JsonSerializer.Deserialize<List<Dictionary<string, object>>>(righeElem.GetRawText());

                    var response = _db2Connection.DBSAITE.SavePriorFM(societa, righe);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    return StatusCode(500, ex);
                }
            }

        }

        [HttpPost("getTabellaSconti")]
        public IActionResult GetTabellaSconti([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "getTabellaSconti"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetTabellaSconti(societa);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    return StatusCode(500, ex);
                }
            }

        }

        [HttpPost("getMacchine")]
        public IActionResult GetMacchine([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetMacchine"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetArticoliMacchina(societa);

                    _logger.LogInformation("Estratti gli articoli macchina della società {societa} dall'utente {codusr}", societa, username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante estrazione articoli macchina società {codSoc} da utente {username}", societa, username);

                    return StatusCode(500, ex);
                }
            }
        }

        [HttpPost("getNations")]
        public IActionResult GetNations([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "GetNations"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetNationCode();

                    _logger.LogInformation("Estratte le nazioni dall'utente {codusr}", username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante l'estrazione delle nazioni da utente {username}", username);

                    return StatusCode(500, ex);
                }
            }
        }

        [AllowAnonymous]
        [HttpPost("getArticoloComponentiUsura")]
        public IActionResult GetArticoloComponentiUsura([FromBody] Dictionary<string, dynamic> request)
        {
            if (request == null || !request.ContainsKey("REQUESTER_CODSOC"))
            {
                return BadRequest(ResultInfo.Error(400, "Dati mancanti", new Dictionary<string, dynamic> { }));
            }

            string societa = request["REQUESTER_CODSOC"].ToString();
            string requester = request["REQUESTER"].ToString();
            string username = request["REQUESTER_USER"].ToString();
            string activePage = request["REQUESTER_PAGE"].ToString();

            string articolo = request["ARTICOLO"].ToString();
            string frequenza = request["FREQ"].ToString();

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = societa,
                ["LOG_ORIGIN"] = requester,
                ["LOG_USER"] = username,
                
                ["LOG_WS_CONTROLLER"] = "ITEM",
                ["LOG_WS_ACTION"] = "getArticoloComponentiUsura"
            }))
            {
                try
                {
                    var response = _db2Connection.DBSAITE.GetArticoloComponentiUsura(articolo, frequenza, societa);

                    _logger.LogInformation("Estrazione componenti usura articolo {codArt} da parte dell'utente {codusr}", articolo, username);

                    return Ok(ResultInfo.Success(response));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore durante estrazione componenti usura articolo {codArt} da parte dell'utente {codusr}", articolo, username);

                    return StatusCode(500, ex);
                }
            }
        }
    }
}
