namespace CG.MobileAPI.Data
{
    /// <summary>
    /// Carica le impostazioni di configurazione per l'applicazione.
    /// </summary>
    public class ConfigurationLoader
    {
        /// <summary>
        /// Ottiene o imposta un valore che indica se l'applicazione è in modalità di test.
        /// </summary>
        public bool IsTest { get; set; }

        /// <summary>
        /// Ottiene o imposta il numero di thread da utilizzare nelle operazioni parallele.
        /// </summary>
        public int NumberOfThreads { get; set; }

        public bool Verbose { get; set; }

        public string HeavyBaseUrl { get; set; }
    }
}
