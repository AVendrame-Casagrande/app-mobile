namespace CG.MobileAPI.Data
{
    /// <summary>
    /// Società Diapason gestite dall'app mobile. Si sceglie al login (CSPRO / IMM00; gli utenti in lingua inglese
    /// lavorano sempre su CSUSA, come nella vecchia app) e viaggia nel token JWT (claim <c>societa</c>): i controller
    /// la passano alle query al posto del vecchio <c>'CSPRO'</c> fisso.
    /// </summary>
    public static class CodiciSocieta
    {
        /// <summary>Casagrande.</summary>
        public const string CASAGRANDE = "CSPRO";

        /// <summary>IMM.</summary>
        public const string IMM = "IMM00";

        /// <summary>Casagrande USA: assegnata in automatico agli utenti in lingua inglese.</summary>
        public const string CS_USA = "CSUSA";

        /// <summary>Società che si possono scegliere al login.</summary>
        public static readonly IReadOnlyList<string> Selezionabili = new[] { CASAGRANDE, IMM };

        /// <summary>Società ammesse nel token.</summary>
        public static readonly IReadOnlyList<string> Valide = new[] { CASAGRANDE, IMM, CS_USA };

        /// <summary>true se il codice si può scegliere al login.</summary>
        public static bool IsSelezionabile(string? codice) => codice != null && Selezionabili.Contains(codice.Trim().ToUpperInvariant());

        /// <summary>true se il codice è una delle società gestite.</summary>
        public static bool IsValida(string? codice) => codice != null && Valide.Contains(codice.Trim().ToUpperInvariant());

        /// <summary>Codice normalizzato (maiuscolo); Casagrande se vuoto o non gestito.</summary>
        public static string Normalizza(string? codice) =>
            IsValida(codice) ? codice!.Trim().ToUpperInvariant() : CASAGRANDE;
    }
}
