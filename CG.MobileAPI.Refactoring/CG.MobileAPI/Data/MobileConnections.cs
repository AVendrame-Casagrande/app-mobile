namespace CG.MobileAPI.Data
{
    /// <summary>
    /// Stringhe di connessione usate dai servizi dell'app mobile (ex PHP mobile/server).
    /// Sono tutte connessioni ODBC: i marker dei parametri sono posizionali (<c>?</c>).
    /// </summary>
    public class MobileConnections
    {
        /// <summary>DB2 Diapason, utente MDII (ex <c>odbc_connect("DIAPASON2", "MDII", ...)</c>).</summary>
        public string Db2 { get; set; } = "";

        /// <summary>DB2 Diapason, utente MODULA (ex <c>odbc_connect("DIAPASON2", "MODULA", ...)</c>).</summary>
        public string Db2Modula { get; set; } = "";

        /// <summary>Replica DB2 MDIIReplica (ex DBGetARMListMobile.php).</summary>
        public string Db2Replica { get; set; } = "";

        /// <summary>PostgreSQL 10.8.198.6 / casagrande (tabelle cs_*: fabbisogni, ODL, ODV, prelievi MGAUT, ...).</summary>
        public string PgCasagrande { get; set; } = "";

        /// <summary>PostgreSQL 10.8.198.8 / DB_1 (chat, avvisi, liste, storico movimenti, api_sse_responses, ...).</summary>
        public string PgDb1 { get; set; } = "";

        /// <summary>PostgreSQL 10.8.198.49 / casagrande (copia di sviluppo, usata solo da selectSingoloArticolo).</summary>
        public string PgCasagrandeDev { get; set; } = "";
    }
}
