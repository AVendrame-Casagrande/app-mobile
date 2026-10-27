namespace CG.MobileAPI.Models
{
    /// <summary>
    /// Rappresenta il risultato di un'operazione, includendo un codice, un messaggio e dati opzionali.
    /// </summary>
    public class ResultInfo
    {
        /// <summary>
        /// Ottiene o imposta il codice del risultato. Un valore pari a 0 indica solitamente successo.
        /// </summary>
        public int Code { get; set; }

        /// <summary>
        /// Ottiene o imposta il messaggio associato al risultato.
        /// </summary>
        public string Message { get; set; }

        /// <summary>
        /// Ottiene o imposta i dati correlati al risultato.
        /// </summary>
        public object Data { get; set; }

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="ResultInfo"/> con il codice, il messaggio e i dati specificati.
        /// </summary>
        /// <param name="codice">Il codice del risultato.</param>
        /// <param name="messaggio">Il messaggio descrittivo del risultato.</param>
        /// <param name="info">I dati associati al risultato.</param>
        public ResultInfo(int codice, string messaggio, object info)
        {
            Code = codice;
            Message = messaggio;
            Data = info;
        }

        /// <summary>
        /// Crea una nuova istanza di <see cref="ResultInfo"/> che rappresenta un'operazione andata a buon fine.
        /// </summary>
        /// <param name="data">I dati relativi al risultato positivo.</param>
        /// <returns>Una nuova istanza di <see cref="ResultInfo"/> con codice 0 e messaggio "Successo".</returns>
        public static ResultInfo Success(object data)
        {
            return new ResultInfo(0, "Successo", data);
        }

        /// <summary>
        /// Crea una nuova istanza di <see cref="ResultInfo"/> che rappresenta un'operazione fallita.
        /// </summary>
        /// <param name="errorNumber">Il codice di errore.</param>
        /// <param name="errMsg">Il messaggio descrittivo dell'errore.</param>
        /// <param name="data">Dati aggiuntivi relativi all'errore (non utilizzati nel valore restituito).</param>
        /// <returns>Una nuova istanza di <see cref="ResultInfo"/> con il codice e il messaggio di errore specificati.</returns>
        public static ResultInfo Error(int errorNumber, string errMsg, object data)
        {
            return new ResultInfo(errorNumber, errMsg, data);
        }
    }
}
