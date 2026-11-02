using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using CG.MobileAPI.Data;
using Microsoft.Extensions.Options;

namespace CG.MobileAPI.Tools
{
    /// <summary>
    /// PDF dei disegni nell'archivio di rete (es. <c>\\csg-fs-cld-01\Archivio3d</c>), letti direttamente dall'API
    /// invece che dalla cartella <c>draw</c> del web server.
    /// I link restituiti all'app sono firmati e scadono: si aprono anche con il visualizzatore PDF del telefono,
    /// che non ha il token di login.
    /// </summary>
    public class DisegniTool
    {
        private static readonly Regex _codiceValido = new(@"^[A-Za-z0-9._\- ]{1,60}$");
        private static readonly Regex _nomeValido = new(@"^[A-Za-z0-9._\- ]{1,200}\.pdf$", RegexOptions.IgnoreCase);

        private readonly StorageSettings _settings;
        private readonly byte[] _chiave;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DisegniTool"/>.
        /// </summary>
        public DisegniTool(IOptions<MobileSettings> settings)
        {
            _settings = settings.Value.Storage;
            // Chiave dei link derivata da quella dei token JWT, con uno scopo diverso.
            _chiave = SHA256.HashData(Encoding.UTF8.GetBytes("disegni|" + TokenTool.CryptedKey));
        }

        /// <summary>
        /// Nomi dei PDF il cui nome inizia con il codice disegno, in ordine di nome (vuoto se il codice non è valido
        /// o l'archivio non è raggiungibile).
        /// </summary>
        public List<string> Cerca(string codiceDisegno)
        {
            if (!_codiceValido.IsMatch(codiceDisegno) || codiceDisegno.Contains(".."))
            {
                return new List<string>();
            }
            try
            {
                // Ricerca filtrata dal file server: Directory.GetFiles leggerebbe tutto l'archivio (oltre un minuto).
                return RicercaFile.Elenca(Archivio(), codiceDisegno + "*.pdf")
                    .Where(f => f.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
                    .ToList();
            }
            catch (IOException)
            {
                return new List<string>();
            }
            catch (UnauthorizedAccessException)
            {
                return new List<string>();
            }
        }

        /// <summary>
        /// Link firmato all'azione che restituisce il PDF, valido per <see cref="StorageSettings.LinkDisegniMinuti"/> minuti.
        /// </summary>
        /// <param name="urlAzione">URL dell'azione, es. https://host/api/giacenze/disegno.</param>
        /// <param name="nomeFile">Nome del PDF nell'archivio.</param>
        public string Link(string urlAzione, string nomeFile)
        {
            var scadenza = DateTimeOffset.UtcNow.AddMinutes(_settings.LinkDisegniMinuti).ToUnixTimeSeconds();
            return $"{urlAzione}/{Uri.EscapeDataString(nomeFile)}?exp={scadenza}&sig={Firma(nomeFile, scadenza)}";
        }

        /// <summary>
        /// Percorso del PDF se il link è valido (firma corretta, non scaduto) e il file esiste; altrimenti
        /// <see cref="MobileException"/> (403 per link non valido o scaduto, 404 per file inesistente).
        /// </summary>
        public string Percorso(string nomeFile, long scadenza, string? firma)
        {
            if (!_nomeValido.IsMatch(nomeFile) || nomeFile.Contains("..") || Path.GetFileName(nomeFile) != nomeFile)
            {
                throw new MobileException("Nome file non valido", 404);
            }
            var attesa = Encoding.ASCII.GetBytes(Firma(nomeFile, scadenza));
            if (firma == null
                || !CryptographicOperations.FixedTimeEquals(attesa, Encoding.ASCII.GetBytes(firma))
                || DateTimeOffset.UtcNow.ToUnixTimeSeconds() > scadenza)
            {
                throw new MobileException("Link scaduto o non valido: riapri la scheda dell'articolo", 403);
            }
            var percorso = Path.Combine(Archivio(), nomeFile);
            if (!File.Exists(percorso))
            {
                throw new MobileException("Disegno non trovato", 404);
            }
            return percorso;
        }

        private string Archivio()
        {
            if (string.IsNullOrWhiteSpace(_settings.ArchivioDisegni))
            {
                throw new InvalidOperationException("mobile:Storage:ArchivioDisegni non configurato");
            }
            return _settings.ArchivioDisegni;
        }

        private string Firma(string nomeFile, long scadenza)
        {
            var hash = HMACSHA256.HashData(_chiave, Encoding.UTF8.GetBytes($"{nomeFile}|{scadenza}"));
            return Convert.ToHexString(hash).ToLowerInvariant();
        }
    }
}
