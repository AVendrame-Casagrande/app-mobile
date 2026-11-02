namespace CG.MobileAPI.Data
{
    /// <summary>
    /// Impostazioni dei servizi dell'app mobile (sezione <c>mobile</c> di config.json).
    /// </summary>
    public class MobileSettings
    {
        /// <summary>Server Diapason (socket movimenti e eseguibili).</summary>
        public DiapasonSettings Diapason { get; set; } = new();

        /// <summary>Cartelle dei file (foto, pdf, storage).</summary>
        public StorageSettings Storage { get; set; } = new();

        /// <summary>Server SMTP (ex shared/setPhpEmailAuth.php).</summary>
        public SmtpSettings Smtp { get; set; } = new();
    }

    /// <summary>
    /// Impostazioni per Diapason.
    /// </summary>
    public class DiapasonSettings
    {
        /// <summary>Host del server socket dei movimenti (cas-mlx-01).</summary>
        public string SocketHost { get; set; } = "10.8.198.6";

        /// <summary>Porta del socket in produzione.</summary>
        public int SocketPortProd { get; set; } = 7788;

        /// <summary>Porta del socket in test.</summary>
        public int SocketPortTest { get; set; } = 7799;

        /// <summary>Timeout del socket in secondi.</summary>
        public int SocketTimeoutSeconds { get; set; } = 120;

        /// <summary>
        /// Percorso di ConCheckUser.exe sul server dell'API. Se valorizzato l'eseguibile viene lanciato in locale
        /// (senza shell); altrimenti si chiama <see cref="CheckUserUrl"/>.
        /// </summary>
        public string CheckUserExePath { get; set; } = "";

        /// <summary>URL di CheckUserDiap.php sul server Diapason (10.0.2.1).</summary>
        public string CheckUserUrl { get; set; } = "http://10.0.2.1/applicazioni/diapason/CheckUserDiap.php";

        /// <summary>Percorso di ConSOSACPN.exe sul server dell'API (vuoto = si usa <see cref="SosacpnUrl"/>).</summary>
        public string SosacpnExePath { get; set; } = "";

        /// <summary>URL di UpdateSOSACPN.php sul server Diapason (10.0.2.1).</summary>
        public string SosacpnUrl { get; set; } = "http://10.0.2.1/applicazioni/produzione/UpdateSOSACPN.php";

        /// <summary>
        /// Ambiente Diapason di test: lo imposta Program.cs da <c>configuration:isTest</c>, insieme alle connection string.
        /// Il client non sceglie più l'ambiente.
        /// </summary>
        public bool IsTest { get; set; }

        /// <summary>Ambiente per gli eseguibili Diapason (ConCheckUser / ConSOSACPN): "T" in test, "P" in produzione.</summary>
        public string Ambiente => IsTest ? "T" : "P";

        /// <summary>Porta del socket dei movimenti per l'ambiente corrente.</summary>
        public int SocketPort => IsTest ? SocketPortTest : SocketPortProd;
    }

    /// <summary>
    /// Impostazioni per i file.
    /// </summary>
    public class StorageSettings
    {
        /// <summary>
        /// Radice del web server app.casagrandegroup.local (es. <c>\\server\htdocs</c>). I percorsi del PHP
        /// vanno espressi relativi a questa cartella: <c>mobile/server/storage/chat_foto</c>, <c>applicazioni/tecnico/foto</c>.
        /// </summary>
        public string WebRoot { get; set; } = "";

        /// <summary>Dimensione massima di un file caricato, in MB.</summary>
        public int MaxUploadMb { get; set; } = 20;

        /// <summary>
        /// Archivio di rete dei PDF dei disegni (es. <c>\\csg-fs-cld-01\Archivio3d</c>). L'utente con cui gira l'API
        /// deve poterlo leggere.
        /// </summary>
        public string ArchivioDisegni { get; set; } = "";

        /// <summary>Validità in minuti dei link ai disegni restituiti all'app.</summary>
        public int LinkDisegniMinuti { get; set; } = 60;
    }

    /// <summary>
    /// Impostazioni del server SMTP.
    /// </summary>
    public class SmtpSettings
    {
        /// <summary>Host SMTP.</summary>
        public string Host { get; set; } = "";

        /// <summary>Porta SMTP.</summary>
        public int Port { get; set; } = 25;

        /// <summary>Abilita SSL/TLS.</summary>
        public bool EnableSsl { get; set; }

        /// <summary>Utente (vuoto = nessuna autenticazione).</summary>
        public string User { get; set; } = "";

        /// <summary>Password.</summary>
        public string Password { get; set; } = "";

        /// <summary>Mittente.</summary>
        public string From { get; set; } = "";

        /// <summary>Nome visualizzato del mittente.</summary>
        public string FromName { get; set; } = "App Mobile Casagrande";
    }
}
