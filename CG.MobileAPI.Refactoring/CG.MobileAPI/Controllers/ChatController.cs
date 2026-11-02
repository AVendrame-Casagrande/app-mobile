using System.Text.Json;
using CG.MobileAPI.Data;
using CG.MobileAPI.Models;
using CG.MobileAPI.Tools;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace CG.MobileAPI.Controllers
{
    /// <summary>
    /// Chat dell'app mobile (ex mobile/server/query/chat/*.php): messaggi privati e di gruppo, stream SSE,
    /// foto e promemoria email.
    /// </summary>
    [Route("api/chat")]
    [ApiController]
    [Authorize]
    public class ChatController : MobileControllerBase
    {
        /// <summary>Intervallo di polling dello stream (sleep(60) del PHP).</summary>
        private static readonly TimeSpan INTERVALLO_STREAM = TimeSpan.FromSeconds(60);

        /// <summary>Durata massima dello stream (set_time_limit(600) del PHP); poi il client si riconnette.</summary>
        private static readonly TimeSpan DURATA_STREAM = TimeSpan.FromMinutes(10);

        /// <summary>Attesa prima del promemoria email (sleep(1800) del PHP).</summary>
        private static readonly TimeSpan ATTESA_PROMEMORIA = TimeSpan.FromMinutes(30);

        private readonly StorageTool _storage;
        private readonly EmailTool _email;

        /// <summary>
        /// Inizializza una nuova istanza del <see cref="ChatController"/>.
        /// </summary>
        public ChatController(MyDbContext db2Connection, ILogger<ChatController> logger, StorageTool storage, EmailTool email)
            : base(db2Connection, logger, "CHAT")
        {
            _storage = storage;
            _email = email;
        }

        private static long ParseId(string? valore, string campo)
        {
            if (!long.TryParse(valore?.Trim(), out var id))
            {
                throw new MobileException($"Parametro '{campo}' mancante o non valido");
            }
            return id;
        }

        /// <summary>
        /// Stream SSE dei messaggi di oggi dell'utente e dei gruppi (ex ChatStream.php): un evento ogni 60 secondi
        /// (<c>id:</c> vuoto + <c>data:</c> con l'array JSON delle righe di public.chat, <c>false</c> se non ce ne sono)
        /// per al massimo 10 minuti. L'utente è quello del token; il parametro <c>utente</c> in query string è ignorato.
        /// </summary>
        [HttpGet("ChatStream")]
        public async Task ChatStream()
        {
            var utente = Utente;
            var abort = HttpContext.RequestAborted;

            Response.Headers["Content-Type"] = "text/event-stream";
            Response.Headers["Cache-Control"] = "no-cache";

            using (_logger.BeginScope(new Dictionary<string, object>
            {
                ["LOG_CODSOC"] = Societa,
                ["LOG_ORIGIN"] = ORIGIN,
                ["LOG_USER"] = utente,
                ["LOG_WS_CONTROLLER"] = "CHAT",
                ["LOG_WS_ACTION"] = "ChatStream"
            }))
            {
                _logger.LogInformation("L'utente {Username} ha aperto ChatStream", utente);
                var fine = DateTime.UtcNow + DURATA_STREAM;
                try
                {
                    while (!abort.IsCancellationRequested && DateTime.UtcNow < fine)
                    {
                        var messaggi = _db2Connection.DBCHAT.GetMessaggiStream(utente);
                        var json = messaggi.Count == 0 ? "false" : JsonSerializer.Serialize(messaggi);

                        await Response.WriteAsync("id:\n" + "data:" + json + "\n\n", abort);
                        await Response.Body.FlushAsync(abort);

                        await Task.Delay(INTERVALLO_STREAM, abort);
                    }
                }
                catch (OperationCanceledException)
                {
                    // client disconnesso
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Errore in ChatStream per {Username}", utente);
                }
            }
        }

        /// <summary>
        /// Elimina un messaggio (ex deleteMessage.php). Restituisce "deleted" o "error".
        /// </summary>
        [HttpPost("deleteMessage")]
        public IActionResult DeleteMessage([FromBody] ChatIdRequest request)
        {
            return Esegui("deleteMessage", () => _db2Connection.DBCHAT.DeleteMessage(ParseId(request?.id, "id")));
        }

        /// <summary>
        /// Messaggi dell'ultimo anno dell'utente autenticato e dei suoi gruppi (ex getAllChats.php).
        /// </summary>
        [HttpPost("getAllChats")]
        public IActionResult GetAllChats([FromBody] GetAllChatsRequest? request)
        {
            return Esegui("getAllChats", () => _db2Connection.DBCHAT.GetAllChats(Utente));
        }

        /// <summary>
        /// Gruppi chat dell'utente autenticato (ex getElencoGruppiChat.php).
        /// </summary>
        [HttpPost("getElencoGruppiChat")]
        public IActionResult GetElencoGruppiChat([FromBody] GetElencoGruppiChatRequest? request)
        {
            return Esegui("getElencoGruppiChat", () => _db2Connection.DBCHAT.GetElencoGruppiChat(Utente));
        }

        /// <summary>
        /// Elenco di tutti gli utenti (ex getUsersList.php).
        /// </summary>
        [HttpPost("getUsersList")]
        public IActionResult GetUsersList()
        {
            return Esegui("getUsersList", () => _db2Connection.DBCHAT.GetUsersList());
        }

        /// <summary>
        /// Nomi degli utenti di un gruppo (ex getUsersListGroup.php).
        /// </summary>
        [HttpPost("getUsersListGroup")]
        public IActionResult GetUsersListGroup([FromBody] GetUsersListGroupRequest request)
        {
            return Esegui("getUsersListGroup", () => _db2Connection.DBCHAT.GetUsersListGroup(request?.group));
        }

        /// <summary>
        /// Codici degli utenti che hanno letto un messaggio di gruppo (ex getUtentiLetturaMessaggioGruppo.php).
        /// </summary>
        [HttpPost("getUtentiLetturaMessaggioGruppo")]
        public IActionResult GetUtentiLetturaMessaggioGruppo([FromBody] GetUtentiLetturaMessaggioGruppoRequest request)
        {
            return Esegui("getUtentiLetturaMessaggioGruppo",
                () => _db2Connection.DBCHAT.GetUtentiLetturaMessaggioGruppo(ParseId(request?.idMessaggio, "idMessaggio")));
        }

        /// <summary>
        /// Nasconde un messaggio ricevuto o inviato (ex hideMessage.php). Restituisce "hided" o "error".
        /// </summary>
        [HttpPost("hideMessage")]
        public IActionResult HideMessage([FromBody] HideMessageRequest request)
        {
            return Esegui("hideMessage", () => _db2Connection.DBCHAT.HideMessage(ParseId(request?.id, "id"), request?.tipo));
        }

        /// <summary>
        /// Promemoria email (ex setEmailChatReminder.php): dopo 30 minuti, se il messaggio non è stato letto, invia
        /// una email al destinatario. Il PHP teneva aperta la richiesta per 30 minuti; qui il controllo è pianificato
        /// in background e la risposta è immediata ("scheduled"). Il mittente è l'utente autenticato.
        /// </summary>
        [HttpPost("setEmailChatReminder")]
        public IActionResult SetEmailChatReminder([FromBody] SetEmailChatReminderRequest request)
        {
            return Esegui("setEmailChatReminder", () =>
            {
                var messaggio = request?.message ?? throw new MobileException("Parametro 'message' mancante");
                var idInserted = ParseId(request.id_inserted, "id_inserted");
                var senderId = Utente;
                var oraCreazione = DateTime.Now.ToString("HH:mm:ss");
                var db = _db2Connection.DBCHAT;
                var logger = _logger;
                var email = _email;

                _ = Task.Run(async () =>
                {
                    try
                    {
                        await Task.Delay(ATTESA_PROMEMORIA);
                        var esito = await db.SetEmailChatReminderAsync(email, idInserted, senderId, messaggio.receiverid,
                            messaggio.messaggio, messaggio.tipo_messaggio, oraCreazione);
                        logger.LogInformation("Promemoria chat {Id} di {Username}: '{Esito}'", idInserted, senderId, esito);
                    }
                    catch (Exception ex)
                    {
                        logger.LogError(ex, "Errore nel promemoria email del messaggio chat {Id} di {Username}", idInserted, senderId);
                    }
                });

                return "scheduled";
            });
        }

        /// <summary>
        /// Segna come letti dei messaggi privati (ex updateMessagesRead.php). Restituisce gli id ricevuti.
        /// </summary>
        [HttpPost("updateMessagesRead")]
        public IActionResult UpdateMessagesRead([FromBody] UpdateMessagesReadRequest request)
        {
            return Esegui("updateMessagesRead", () => _db2Connection.DBCHAT.UpdateMessagesRead(
                request?.idMessaggiLetti ?? throw new MobileException("Parametro 'idMessaggiLetti' mancante")));
        }

        /// <summary>
        /// Segna come letti dall'utente autenticato dei messaggi di gruppo (ex updateMessagesReadGruppo.php).
        /// Restituisce gli id ricevuti.
        /// </summary>
        [HttpPost("updateMessagesReadGruppo")]
        public IActionResult UpdateMessagesReadGruppo([FromBody] UpdateMessagesReadGruppoRequest request)
        {
            return Esegui("updateMessagesReadGruppo", () => _db2Connection.DBCHAT.UpdateMessagesReadGruppo(
                request?.idMessaggiLetti ?? throw new MobileException("Parametro 'idMessaggiLetti' mancante"), Utente));
        }

        /// <summary>
        /// Carica la foto di un messaggio chat come &lt;name&gt;.jpg (ex upload_foto.php). Restituisce "uploaded" o "error".
        /// </summary>
        [HttpPost("upload_foto")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> UploadFoto([FromForm] UploadFotoChatRequest request)
        {
            return await EseguiAsync("upload_foto", async () =>
            {
                if (string.IsNullOrWhiteSpace(request?.name))
                {
                    throw new MobileException("Parametro 'name' mancante");
                }
                return await _db2Connection.DBCHAT.UploadFotoAsync(_storage, request.file, request.name);
            });
        }

        /// <summary>
        /// Invia un messaggio (ex writeMessage.php) e restituisce l'id inserito. Il mittente è l'utente autenticato,
        /// il destinatario quello della richiesta.
        /// </summary>
        [HttpPost("writeMessage")]
        public IActionResult WriteMessage([FromBody] WriteMessageRequest request)
        {
            return Esegui("writeMessage", () =>
            {
                var messaggio = request?.message ?? throw new MobileException("Parametro 'message' mancante");
                if (string.IsNullOrWhiteSpace(messaggio.receiverid))
                {
                    throw new MobileException("Destinatario mancante");
                }
                return _db2Connection.DBCHAT.WriteMessage(messaggio, Utente);
            });
        }
    }
}
