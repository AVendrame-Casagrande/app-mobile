using System.Data.Odbc;
using System.Globalization;
using System.Net;
using System.Text.Json.Serialization;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;

namespace CG.MobileAPI.Models
{
    // -----------------------------------------------------------------------------------------------------------------
    // --- Richieste ---------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Messaggio chat inviato dal client (oggetto Message dell'app, serializzato nel campo <c>message</c>).
    /// Contiene solo i campi letti dal server.
    /// </summary>
    public class MessaggioChatModel
    {
        /// <summary>Codice Diapason del mittente (ignorato in scrittura: si usa l'utente del token).</summary>
        [JsonPropertyName("senderid")]
        public string? senderid { get; set; }

        /// <summary>Codice Diapason del destinatario o codice del gruppo (CSGROUP, GRUPPO_MAGAZZINO, ...).</summary>
        [JsonPropertyName("receiverid")]
        public string? receiverid { get; set; }

        /// <summary>Testo del messaggio.</summary>
        [JsonPropertyName("messaggio")]
        public string? messaggio { get; set; }

        /// <summary>Tipo di messaggio (normale, foto, avviso_completato, ...).</summary>
        [JsonPropertyName("tipo_messaggio")]
        public string? tipo_messaggio { get; set; }

        /// <summary>Nome del file della foto (messaggi di tipo foto).</summary>
        [JsonPropertyName("url_foto")]
        public string? url_foto { get; set; }
    }

    /// <summary>
    /// Richiesta con l'id di un messaggio (ex deleteMessage.php).
    /// </summary>
    public class ChatIdRequest
    {
        /// <summary>Id del messaggio.</summary>
        public string? id { get; set; }
    }

    /// <summary>
    /// Richiesta di getAllChats.php. Il campo <c>codiceUtente</c> è ignorato: si usa l'utente del token.
    /// </summary>
    public class GetAllChatsRequest
    {
        /// <summary>Codice utente (ignorato, si usa l'utente autenticato).</summary>
        public string? codiceUtente { get; set; }
    }

    /// <summary>
    /// Richiesta di getElencoGruppiChat.php. Il campo <c>utente</c> è ignorato: si usa l'utente del token.
    /// </summary>
    public class GetElencoGruppiChatRequest
    {
        /// <summary>Codice utente (ignorato, si usa l'utente autenticato).</summary>
        public string? utente { get; set; }
    }

    /// <summary>
    /// Richiesta di getUsersListGroup.php.
    /// </summary>
    public class GetUsersListGroupRequest
    {
        /// <summary>Codice del gruppo (GRUPPO_MAGAZZINO / GRUPPO_PRODUZIONE).</summary>
        public string? group { get; set; }
    }

    /// <summary>
    /// Richiesta di getUtentiLetturaMessaggioGruppo.php.
    /// </summary>
    public class GetUtentiLetturaMessaggioGruppoRequest
    {
        /// <summary>Id del messaggio di gruppo.</summary>
        public string? idMessaggio { get; set; }
    }

    /// <summary>
    /// Richiesta di hideMessage.php.
    /// </summary>
    public class HideMessageRequest
    {
        /// <summary>Id del messaggio.</summary>
        public string? id { get; set; }

        /// <summary>"ricevuto" o "inviato".</summary>
        public string? tipo { get; set; }
    }

    /// <summary>
    /// Richiesta di setEmailChatReminder.php.
    /// </summary>
    public class SetEmailChatReminderRequest
    {
        /// <summary>Messaggio inviato (ex campo JSON <c>message</c>).</summary>
        public MessaggioChatModel? message { get; set; }

        /// <summary>Id del messaggio inserito da writeMessage.</summary>
        public string? id_inserted { get; set; }
    }

    /// <summary>
    /// Richiesta di updateMessagesRead.php.
    /// </summary>
    public class UpdateMessagesReadRequest
    {
        /// <summary>Id dei messaggi letti (ex campo JSON <c>idMessaggiLetti</c>).</summary>
        public List<long>? idMessaggiLetti { get; set; }
    }

    /// <summary>
    /// Richiesta di updateMessagesReadGruppo.php. Il campo <c>codiceUtente</c> è ignorato: si usa l'utente del token.
    /// </summary>
    public class UpdateMessagesReadGruppoRequest
    {
        /// <summary>Id dei messaggi di gruppo letti (ex campo JSON <c>idMessaggiLetti</c>).</summary>
        public List<long>? idMessaggiLetti { get; set; }

        /// <summary>Codice utente (ignorato, si usa l'utente autenticato).</summary>
        public string? codiceUtente { get; set; }
    }

    /// <summary>
    /// Richiesta multipart di upload_foto.php.
    /// </summary>
    public class UploadFotoChatRequest
    {
        /// <summary>La foto (campo <c>file</c>).</summary>
        public IFormFile? file { get; set; }

        /// <summary>Nome del file senza estensione (verrà aggiunto ".jpg").</summary>
        public string? name { get; set; }
    }

    /// <summary>
    /// Richiesta di writeMessage.php.
    /// </summary>
    public class WriteMessageRequest
    {
        /// <summary>Messaggio da inviare (ex campo JSON <c>message</c>).</summary>
        public MessaggioChatModel? message { get; set; }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // --- Data class --------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Accesso ai dati per chat (ex mobile/server/query/chat/*.php, tabella public.chat su DB_1).
    /// </summary>
    public class DBCHAT
    {
        /// <summary>Cartella delle foto della chat (ex ../../storage/chat_foto/).</summary>
        public const string CARTELLA_FOTO = "mobile/server/storage/chat_foto";

        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBCHAT"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBCHAT(MobileConnections conn)
        {
            _conn = conn;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Gruppi (ex shared_functions/isInGruppo.php) -------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        private static string Prefisso(string codice) => codice.Length >= 3 ? codice.Substring(0, 3) : codice;

        private static bool IsInGruppoMagazzino(string codiceUtente)
        {
            var p = Prefisso(codiceUtente);
            return p == "CTM" || p == "CMA" || codiceUtente == "CAM015" || codiceUtente == "CAP001";
        }

        private static bool IsInGruppoProduzione(string codiceUtente)
        {
            return Prefisso(codiceUtente) == "CPR" || codiceUtente == "CAM015" || codiceUtente == "CAP001";
        }

        private static int DataOggi() => int.Parse(DateTime.Now.ToString("yyyyMMdd", CultureInfo.InvariantCulture));

        private static int OraOra() => int.Parse(DateTime.Now.ToString("HHmmss", CultureInfo.InvariantCulture));

        private static double ToFloat(object? v) =>
            double.TryParse(v?.ToString(), NumberStyles.Float, CultureInfo.InvariantCulture, out var d) ? d : 0;

        // -------------------------------------------------------------------------------------------------------------
        // --- Metodi pubblici -----------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Messaggi di oggi inviati o letti che riguardano l'utente o i gruppi (ex query di ChatStream.php).
        /// Le colonne sono quelle di public.chat, con i valori come stringhe (come pg_fetch_all).
        /// </summary>
        /// <param name="utente">Codice Diapason dell'utente.</param>
        public List<Dictionary<string, object?>> GetMessaggiStream(string utente)
        {
            var data = DataOggi();
            return DbHelper.Query(_conn.PgDb1, @"
                select * from public.chat
                where (chat.data_invio = ? or chat.data_lettura = ?)
                and (receiverid = ? or senderid = ? or receiverid='CSGROUP' or receiverid='GRUPPO_MAGAZZINO' or receiverid='GRUPPO_PRODUZIONE') and senderid != receiverid
                order by chat.data_invio asc, chat.ora_invio asc",
                data, data, utente, utente);
        }

        /// <summary>
        /// Elimina un messaggio (ex deleteMessage.php). Restituisce "deleted" o "error".
        /// </summary>
        /// <param name="id">Id del messaggio.</param>
        public string DeleteMessage(long id)
        {
            try
            {
                DbHelper.NonQuery(_conn.PgDb1, "delete from public.chat where id=?", id);
                return "deleted";
            }
            catch (OdbcException)
            {
                return "error";
            }
        }

        /// <summary>
        /// Messaggi dell'ultimo anno che coinvolgono l'utente o i suoi gruppi, esclusi quelli nascosti (ex getAllChats.php).
        /// </summary>
        /// <param name="codiceUtente">Codice Diapason dell'utente.</param>
        public List<Dictionary<string, object?>> GetAllChats(string codiceUtente)
        {
            var orGruppoMagazzino = IsInGruppoMagazzino(codiceUtente) ? "or receiverid='GRUPPO_MAGAZZINO'" : "";
            var orGruppoProduzione = IsInGruppoProduzione(codiceUtente) ? "or receiverid='GRUPPO_PRODUZIONE'" : "";

            var dataChat = DataOggi() - 10000; // solo le chat dell'ultimo anno

            var righe = DbHelper.Query(_conn.PgDb1,
                $"select * from public.chat where (receiverid=? or senderid=? or receiverid='CSGROUP' {orGruppoMagazzino} {orGruppoProduzione}) " +
                "and senderid != receiverid and data_invio >= ? order by data_invio desc, ora_invio desc",
                codiceUtente, codiceUtente, dataChat);

            var lista = new List<Dictionary<string, object?>>();
            foreach (var r in righe)
            {
                var senderid = r["senderid"]?.ToString();
                var receiverid = r["receiverid"]?.ToString();

                // Messaggi nascosti dall'utente (come mittente o come destinatario)
                if (senderid == codiceUtente && r["nascosto_inviato"]?.ToString() == "t") continue;
                if (receiverid == codiceUtente && r["nascosto_ricevuto"]?.ToString() == "t") continue;

                var lettori = (r["messaggio_gruppo_utenti_lettura"]?.ToString() ?? "").Split(',');
                var lettoIfMessaggioGruppo = lettori.Contains(codiceUtente);

                lista.Add(new Dictionary<string, object?>
                {
                    ["id"] = r["id"],
                    ["senderid"] = senderid,
                    ["receiverid"] = receiverid,
                    ["messaggio"] = r["messaggio"],
                    ["letto"] = r["letto"],
                    ["data_invio"] = ToFloat(r["data_invio"]),
                    ["ora_invio"] = ToFloat(r["ora_invio"]),
                    ["data_lettura"] = ToFloat(r["data_lettura"]),
                    ["ora_lettura"] = ToFloat(r["ora_lettura"]),
                    ["tipo_messaggio"] = r["tipo_messaggio"],
                    ["nascosto_ricevuto"] = r["nascosto_ricevuto"],
                    ["nascosto_inviato"] = r["nascosto_inviato"],
                    ["url_foto"] = r["url_foto"],
                    ["letto_if_messaggio_gruppo"] = lettoIfMessaggioGruppo
                });
            }
            return lista;
        }

        /// <summary>
        /// Gruppi chat dell'utente: CSGROUP più magazzino / produzione se ne fa parte (ex getElencoGruppiChat.php).
        /// </summary>
        /// <param name="utente">Codice Diapason dell'utente.</param>
        public List<Dictionary<string, object?>> GetElencoGruppiChat(string utente)
        {
            var elenco = new List<Dictionary<string, object?>>
            {
                new() { ["codice"] = "CSGROUP", ["nome"] = "Casagrande Group", ["portale"] = "csgroup" }
            };

            if (IsInGruppoMagazzino(utente))
            {
                // "portale" corrisponde anche al nome dell'immagine nell'app
                elenco.Add(new() { ["codice"] = "GRUPPO_MAGAZZINO", ["nome"] = "Gruppo Magazzino", ["portale"] = "gruppo_magazzino" });
            }

            if (IsInGruppoProduzione(utente))
            {
                elenco.Add(new() { ["codice"] = "GRUPPO_PRODUZIONE", ["nome"] = "Gruppo Produzione", ["portale"] = "gruppo_produzione" });
            }

            return elenco;
        }

        /// <summary>
        /// Elenco di tutti gli utenti Diapason con tipo account, nome portale e immagine profilo (ex getUsersList.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetUsersList()
        {
            // Immagini profilo (public.utenti_info): vale l'ultima riga trovata per codice, come nel PHP
            var immagini = new Dictionary<string, object?>();
            foreach (var r in DbHelper.Query(_conn.PgDb1, "select * from public.utenti_info"))
            {
                var codice = r.GetValueOrDefault("codice")?.ToString();
                if (codice != null)
                {
                    immagini[codice] = r.GetValueOrDefault("immagine");
                }
            }

            var righe = DbHelper.Query(_conn.Db2,
                @"SELECT DIAPOPER.OPER_COD,DIAPOPER.OPER_ANAG,DIAPOPER.OPER_MAIL,DIAPOPER.OPER_LING
                  FROM DIAPOPER ORDER BY DIAPOPER.OPER_COD ASC");

            var lista = new List<Dictionary<string, object?>>();
            foreach (var r in righe)
            {
                var codiceUtente = (r["OPER_COD"]?.ToString() ?? "").Trim();
                var prefisso = Prefisso(codiceUtente);

                var accountType = "Utente Standard";
                if (prefisso == "CTM" || prefisso == "CRI" || prefisso == "CMA") accountType = "Utente Magazzino";
                if (prefisso == "CPR") accountType = "Utente Produzione";
                if (prefisso == "CQC") accountType = "Utente Qualità";
                if (codiceUtente == "CAP" || codiceUtente == "CAP001" || codiceUtente == "CAM015") accountType = "Utente Avanzato";

                var emailUtente = (r["OPER_MAIL"]?.ToString() ?? "").Trim();

                // strtok($email, '@'): salta i '@' iniziali e restituisce false se non resta nulla
                var resto = emailUtente.TrimStart('@');
                object nomePortale = resto.Length == 0 ? false : resto.Split('@')[0];

                lista.Add(new Dictionary<string, object?>
                {
                    ["codiceUtente"] = codiceUtente,
                    ["nomeUtente"] = (r["OPER_ANAG"]?.ToString() ?? "").Trim(),
                    ["emailUtente"] = emailUtente,
                    ["nomePortale"] = nomePortale,
                    ["accountType"] = accountType,
                    ["language"] = (r["OPER_LING"]?.ToString() ?? "").Trim(),
                    ["immagine"] = immagini.TryGetValue(codiceUtente, out var img) ? img : ""
                });
            }
            return lista;
        }

        /// <summary>
        /// Nomi (OPER_ANAG) degli utenti che fanno parte del gruppo, in ordine alfabetico (ex getUsersListGroup.php).
        /// </summary>
        /// <param name="group">GRUPPO_MAGAZZINO o GRUPPO_PRODUZIONE; per altri valori la lista è vuota.</param>
        public List<string> GetUsersListGroup(string? group)
        {
            Func<string, bool>? appartiene = group switch
            {
                "GRUPPO_MAGAZZINO" => IsInGruppoMagazzino,
                "GRUPPO_PRODUZIONE" => IsInGruppoProduzione,
                _ => null
            };

            var lista = new List<string>();
            if (appartiene == null) return lista;

            var righe = DbHelper.Query(_conn.Db2,
                @"SELECT DIAPOPER.OPER_COD, DIAPOPER.OPER_ANAG
                  FROM DIAPOPER ORDER BY DIAPOPER.OPER_ANAG ASC");

            foreach (var r in righe)
            {
                var codiceUtente = (r["OPER_COD"]?.ToString() ?? "").Trim();
                if (appartiene(codiceUtente))
                {
                    lista.Add((r["OPER_ANAG"]?.ToString() ?? "").Trim());
                }
            }
            return lista;
        }

        /// <summary>
        /// Codici degli utenti che hanno letto un messaggio di gruppo (ex getUtentiLetturaMessaggioGruppo.php).
        /// L'elenco in DB termina con una virgola: l'ultimo elemento vuoto viene tolto.
        /// </summary>
        /// <param name="idMessaggio">Id del messaggio.</param>
        public List<string> GetUtentiLetturaMessaggioGruppo(long idMessaggio)
        {
            var righe = DbHelper.Query(_conn.PgDb1,
                "select messaggio_gruppo_utenti_lettura from public.chat where id=?", idMessaggio);

            if (righe.Count == 0) return new List<string>();

            var elenco = (righe[^1]["messaggio_gruppo_utenti_lettura"]?.ToString() ?? "").Split(',').ToList();
            if (elenco.Count >= 2)
            {
                elenco.RemoveAt(elenco.Count - 1);
            }
            return elenco;
        }

        /// <summary>
        /// Nasconde un messaggio ricevuto o inviato (ex hideMessage.php). Restituisce "hided" o "error".
        /// </summary>
        /// <param name="id">Id del messaggio.</param>
        /// <param name="tipo">"ricevuto" o "inviato".</param>
        public string HideMessage(long id, string? tipo)
        {
            var colonna = tipo switch
            {
                "ricevuto" => "nascosto_ricevuto",
                "inviato" => "nascosto_inviato",
                _ => null
            };
            if (colonna == null) return "error";

            try
            {
                DbHelper.NonQuery(_conn.PgDb1, $"update public.chat set {colonna}=true where id=?", id);
                return "hided";
            }
            catch (OdbcException)
            {
                return "error";
            }
        }

        /// <summary>
        /// Promemoria email (ex setEmailChatReminder.php): se il messaggio non è ancora stato letto invia una email
        /// al destinatario. Da chiamare dopo l'attesa di 30 minuti.
        /// Restituisce "message has been read" se letto, "1" se l'email è stata inviata, "" se non c'è un indirizzo.
        /// </summary>
        /// <param name="email">Servizio di invio email.</param>
        /// <param name="idInserted">Id del messaggio.</param>
        /// <param name="senderId">Codice Diapason del mittente.</param>
        /// <param name="receiverId">Codice Diapason del destinatario.</param>
        /// <param name="messaggio">Testo del messaggio.</param>
        /// <param name="tipoMessaggio">Tipo del messaggio.</param>
        /// <param name="oraCreazione">Ora della richiesta (H:i:s), mostrata nel testo dell'email.</param>
        public async Task<string> SetEmailChatReminderAsync(EmailTool email, long idInserted, string senderId, string? receiverId,
            string? messaggio, string? tipoMessaggio, string oraCreazione)
        {
            // Se non c'è la riga vale come letto (data_lettura iniziale = 1, come nel PHP)
            var righe = DbHelper.Query(_conn.PgDb1, "select data_lettura from chat where chat.id=?", idInserted);
            double dataLettura = 1;
            if (righe.Count > 0)
            {
                dataLettura = ToFloat(righe[^1]["data_lettura"]);
            }
            if (dataLettura > 0)
            {
                return "message has been read";
            }

            var nomeInviante = (DbHelper.Query(_conn.Db2,
                    "SELECT DIAPOPER.OPER_ANAG FROM DIAPOPER WHERE DIAPOPER.OPER_COD=?", senderId)
                .LastOrDefault()?["OPER_ANAG"]?.ToString() ?? "").Trim();

            var emailTarget = (DbHelper.Query(_conn.Db2,
                    "SELECT DIAPOPER.OPER_MAIL FROM DIAPOPER WHERE DIAPOPER.OPER_COD=?", receiverId ?? "")
                .LastOrDefault()?["OPER_MAIL"]?.ToString() ?? "").Trim();

            if (emailTarget == "")
            {
                return ""; // PHPMailer senza destinatario: send() falliva
            }

            var testo = tipoMessaggio == "foto" ? $"{nomeInviante} ti ha inviato una Foto!" : messaggio ?? "";

            var corpo = WebUtility.HtmlEncode($"Nuovo Messaggio inviato da {nomeInviante} alle ore {oraCreazione} \n\n {testo}")
                .Replace("\n", "<br>");

            await email.InviaAsync(new[] { emailTarget }, $"Nuovo Messaggio Chat in Sospeso ( {nomeInviante} )", corpo);
            return "1";
        }

        /// <summary>
        /// Segna come letti i messaggi indicati con data e ora correnti (ex updateMessagesRead.php).
        /// Restituisce gli stessi id ricevuti.
        /// </summary>
        /// <param name="idMessaggiLetti">Id dei messaggi.</param>
        public List<long> UpdateMessagesRead(List<long> idMessaggiLetti)
        {
            var dataLettura = DataOggi();
            var oraLettura = OraOra();

            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();
            foreach (var id in idMessaggiLetti)
            {
                DbHelper.NonQuery(conn, null,
                    "update public.chat set letto=true, data_lettura=?, ora_lettura=? WHERE id=?",
                    dataLettura, oraLettura, id);
            }
            return idMessaggiLetti;
        }

        /// <summary>
        /// Aggiunge l'utente all'elenco dei lettori (messaggio_gruppo_utenti_lettura, "COD1,COD2,") dei messaggi di
        /// gruppo indicati, se non c'è già (ex updateMessagesReadGruppo.php). Restituisce gli stessi id ricevuti.
        /// </summary>
        /// <param name="idMessaggiLetti">Id dei messaggi di gruppo.</param>
        /// <param name="codiceUtente">Codice Diapason dell'utente che ha letto.</param>
        public List<long> UpdateMessagesReadGruppo(List<long> idMessaggiLetti, string codiceUtente)
        {
            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();
            foreach (var id in idMessaggiLetti)
            {
                var righe = DbHelper.Query(conn, null,
                    "select messaggio_gruppo_utenti_lettura from public.chat where id=?", id);
                if (righe.Count == 0) continue;

                var attuale = righe[^1]["messaggio_gruppo_utenti_lettura"]?.ToString() ?? "";
                if (attuale.Split(',').Contains(codiceUtente)) continue;

                DbHelper.NonQuery(conn, null,
                    "update public.chat set messaggio_gruppo_utenti_lettura=? where id=?",
                    attuale + codiceUtente + ",", id);
            }
            return idMessaggiLetti;
        }

        /// <summary>
        /// Salva la foto della chat come &lt;name&gt;.jpg in storage/chat_foto (ex upload_foto.php).
        /// Restituisce "uploaded" o "error".
        /// </summary>
        /// <param name="storage">Servizio di gestione file.</param>
        /// <param name="file">La foto.</param>
        /// <param name="name">Nome del file senza estensione.</param>
        public async Task<string> UploadFotoAsync(StorageTool storage, IFormFile? file, string name)
        {
            return await storage.SalvaAsync(file, CARTELLA_FOTO, name + ".jpg", StorageTool.Immagini)
                ? "uploaded"
                : "error";
        }

        /// <summary>
        /// Inserisce un messaggio con data e ora correnti e restituisce l'id inserito (ex writeMessage.php).
        /// </summary>
        /// <param name="messaggio">Messaggio (destinatario, testo, tipo, foto).</param>
        /// <param name="senderId">Codice Diapason del mittente.</param>
        public string WriteMessage(MessaggioChatModel messaggio, string senderId)
        {
            return DbHelper.Scalar(_conn.PgDb1,
                @"insert into public.chat (senderid, receiverid, messaggio, data_invio, ora_invio, tipo_messaggio, url_foto)
                  values (?, ?, ?, ?, ?, ?, ?) returning id",
                senderId, messaggio.receiverid ?? "", messaggio.messaggio ?? "", DataOggi(), OraOra(),
                messaggio.tipo_messaggio ?? "", messaggio.url_foto ?? "") ?? "";
        }
    }
}
