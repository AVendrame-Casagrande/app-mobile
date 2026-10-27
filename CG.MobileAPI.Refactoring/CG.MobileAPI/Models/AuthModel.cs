using CG.MobileAPI.Data;

namespace CG.MobileAPI.Models
{
    /// <summary>
    /// Richiesta di login dell'app mobile.
    /// </summary>
    public class LoginRequestModel
    {
        /// <summary>Codice utente Diapason (es. CTM006).</summary>
        public string CodiceUtente { get; set; } = "";

        /// <summary>Password Diapason.</summary>
        public string Password { get; set; } = "";

        /// <summary>Ambiente Diapason per la verifica password (default "P").</summary>
        public string Ambiente { get; set; } = "P";
    }

    /// <summary>
    /// Utente loggato (stessi campi restituiti da login.php).
    /// </summary>
    public class UtenteLoggatoModel
    {
        /// <summary>Codice utente Diapason.</summary>
        public string codiceUtente { get; set; } = "";
        /// <summary>Nome e cognome.</summary>
        public string nomeUtente { get; set; } = "";
        /// <summary>Email.</summary>
        public string emailUtente { get; set; } = "";
        /// <summary>Parte locale dell'email.</summary>
        public string nomePortale { get; set; } = "";
        /// <summary>Lingua (I / E ...).</summary>
        public string language { get; set; } = "";
        /// <summary>Tipo di account.</summary>
        public string accountType { get; set; } = "Utente Standard";
        /// <summary>Nome del file della foto profilo.</summary>
        public string immagine { get; set; } = "";
        /// <summary>Gruppi chat (sempre vuoto, come nel PHP).</summary>
        public List<object> elencoGruppiChat { get; set; } = new();
        /// <summary>Sempre false (il login istantaneo non è più supportato).</summary>
        public bool instantLogin { get; set; }
    }

    /// <summary>
    /// Risposta del login: utente e token JWT da inviare nell'header Authorization.
    /// </summary>
    public class LoginResponseModel
    {
        /// <summary>Utente loggato.</summary>
        public UtenteLoggatoModel utente { get; set; } = new();
        /// <summary>Token JWT (Bearer).</summary>
        public string token { get; set; } = "";
    }

    /// <summary>
    /// Accesso ai dati per login e profilo utente.
    /// </summary>
    public class DBAUTH
    {
        private static readonly string[] _avanzati = { "CPR002", "CAP", "CAM015", "CAP001", "CCC", "CPR026" };

        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBAUTH"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBAUTH(MobileConnections conn)
        {
            _conn = conn;
        }

        /// <summary>
        /// Legge l'utente da D60STDDB.DIAPOPER e calcola tipo account e nome portale (ex query/login.php).
        /// Restituisce null se l'utente non esiste.
        /// </summary>
        public UtenteLoggatoModel? GetUtente(string codiceUtente)
        {
            var row = DbHelper.QueryFirst(_conn.Db2,
                "SELECT OPER_COD, OPER_ANAG, OPER_MAIL, OPER_LING FROM D60STDDB.DIAPOPER WHERE OPER_COD = ?",
                codiceUtente.Trim());
            if (row == null)
            {
                return null;
            }

            var codice = (row["OPER_COD"]?.ToString() ?? "").Trim();
            var email = (row["OPER_MAIL"]?.ToString() ?? "").Trim();
            return new UtenteLoggatoModel
            {
                codiceUtente = codice,
                nomeUtente = (row["OPER_ANAG"]?.ToString() ?? "").Trim(),
                emailUtente = email,
                nomePortale = email.Split('@')[0],
                language = (row["OPER_LING"]?.ToString() ?? "").Trim(),
                accountType = GetAccountType(codice),
                immagine = GetProfileImage(codice)
            };
        }

        /// <summary>
        /// Tipo di account in base al prefisso del codice utente (regole di login.php).
        /// </summary>
        public static string GetAccountType(string codice)
        {
            var prefisso = codice.Length >= 3 ? codice.Substring(0, 3) : codice;
            if (_avanzati.Contains(codice) || prefisso == "CIT") return "Utente Avanzato";
            if (prefisso == "CQC") return "Utente Qualità";
            if (prefisso == "CPR") return "Utente Produzione";
            if (prefisso == "CTM" || prefisso == "CRI" || prefisso == "CMA") return "Utente Magazzino";
            return "Utente Standard";
        }

        /// <summary>
        /// Foto profilo dell'utente (ex shared_functions/getProfileImage.php).
        /// </summary>
        public string GetProfileImage(string codice)
        {
            return DbHelper.Scalar(_conn.PgDb1, "SELECT immagine FROM public.utenti_info WHERE codice = ?", codice) ?? "";
        }
    }
}
