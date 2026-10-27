namespace CG.MobileAPI.Tools
{
    /// <summary>
    /// Errore applicativo previsto (parametri non validi, risorsa inesistente, ...): il messaggio viene restituito al
    /// client in <c>ResultInfo.Message</c> con HTTP 400, senza dettagli interni.
    /// </summary>
    public class MobileException : Exception
    {
        /// <summary>Codice d'errore restituito in <c>ResultInfo.Code</c>.</summary>
        public int Code { get; }

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="MobileException"/>.
        /// </summary>
        /// <param name="message">Messaggio per il client.</param>
        /// <param name="code">Codice d'errore (default -1).</param>
        public MobileException(string message, int code = -1) : base(message)
        {
            Code = code;
        }
    }
}
