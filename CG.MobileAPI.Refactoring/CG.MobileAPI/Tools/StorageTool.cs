using System.Text.RegularExpressions;
using CG.MobileAPI.Data;
using Microsoft.Extensions.Options;

namespace CG.MobileAPI.Tools
{
    /// <summary>
    /// Lettura e scrittura dei file sotto la radice del web server (ex move_uploaded_file / unlink dei PHP).
    /// Tutti i percorsi sono relativi a <see cref="StorageSettings.WebRoot"/> e non possono uscirne.
    /// </summary>
    public class StorageTool
    {
        /// <summary>Estensioni ammesse per le foto.</summary>
        public static readonly string[] Immagini = { ".jpg", ".jpeg", ".png" };

        private static readonly Regex _nomeValido = new(@"^[A-Za-z0-9 _.,()+\-]{1,250}$");

        private readonly StorageSettings _settings;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="StorageTool"/>.
        /// </summary>
        public StorageTool(IOptions<MobileSettings> settings)
        {
            _settings = settings.Value.Storage;
        }

        /// <summary>
        /// Rende un nome file sicuro come facevano i PHP (<c>/</c> e <c>\</c> diventano <c>-</c>) e lo valida.
        /// </summary>
        public static string NomeSicuro(string nome)
        {
            var n = (nome ?? "").Replace("/", "-").Replace("\\", "-").Trim();
            if (!_nomeValido.IsMatch(n) || n.Trim('.') == "")
            {
                throw new MobileException($"Nome file non valido: '{nome}'");
            }
            return n;
        }

        /// <summary>
        /// Percorso assoluto per un percorso relativo alla radice; solleva un errore se esce dalla radice.
        /// </summary>
        public string Resolve(params string[] parti)
        {
            if (string.IsNullOrWhiteSpace(_settings.WebRoot))
            {
                throw new InvalidOperationException("mobile:Storage:WebRoot non configurato");
            }
            var root = Path.GetFullPath(_settings.WebRoot);
            var full = Path.GetFullPath(Path.Combine(new[] { root }.Concat(parti).ToArray()));
            if (!full.StartsWith(root.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
            {
                throw new MobileException("Percorso non valido");
            }
            return full;
        }

        /// <summary>
        /// Salva un file caricato in <paramref name="cartella"/> con nome <paramref name="nomeFile"/>.
        /// Controlla dimensione ed estensione. Se <paramref name="creaCartella"/> è false e la cartella non esiste
        /// restituisce false (come move_uploaded_file).
        /// </summary>
        public async Task<bool> SalvaAsync(IFormFile? file, string cartella, string nomeFile, string[] estensioni, bool creaCartella = false)
        {
            if (file == null || file.Length == 0)
            {
                throw new MobileException("File mancante");
            }
            if (file.Length > _settings.MaxUploadMb * 1024L * 1024L)
            {
                throw new MobileException("File troppo grande");
            }
            var nome = NomeSicuro(nomeFile);
            if (!estensioni.Contains(Path.GetExtension(nome).ToLowerInvariant()))
            {
                throw new MobileException("Tipo di file non ammesso");
            }

            var dir = Resolve(cartella);
            if (!Directory.Exists(dir))
            {
                if (!creaCartella) return false;
                Directory.CreateDirectory(dir);
            }

            var path = Resolve(cartella, nome);
            await using var fs = new FileStream(path, FileMode.Create, FileAccess.Write);
            await file.CopyToAsync(fs);
            return true;
        }

        /// <summary>
        /// Scrive dei byte in un file (es. PDF o Excel generati).
        /// </summary>
        public async Task SalvaBytesAsync(byte[] contenuto, string cartella, string nomeFile)
        {
            var dir = Resolve(cartella);
            Directory.CreateDirectory(dir);
            await File.WriteAllBytesAsync(Resolve(cartella, NomeSicuro(nomeFile)), contenuto);
        }

        /// <summary>Indica se il file esiste.</summary>
        public bool Esiste(string cartella, string nomeFile) => File.Exists(Resolve(cartella, NomeSicuro(nomeFile)));

        /// <summary>Indica se la cartella esiste.</summary>
        public bool CartellaEsiste(string cartella) => Directory.Exists(Resolve(cartella));

        /// <summary>Elimina il file se esiste; restituisce true se è stato eliminato.</summary>
        public bool Elimina(string cartella, string nomeFile)
        {
            var path = Resolve(cartella, NomeSicuro(nomeFile));
            if (!File.Exists(path)) return false;
            File.Delete(path);
            return true;
        }

        /// <summary>Rinomina un file nella stessa cartella; restituisce false se l'origine non esiste.</summary>
        public bool Rinomina(string cartella, string da, string a)
        {
            var src = Resolve(cartella, NomeSicuro(da));
            if (!File.Exists(src)) return false;
            File.Move(src, Resolve(cartella, NomeSicuro(a)), true);
            return true;
        }

        /// <summary>Nomi dei file nella cartella che corrispondono al pattern (vuoto se la cartella non esiste).</summary>
        public List<string> Elenca(string cartella, string pattern = "*")
        {
            var dir = Resolve(cartella);
            if (!Directory.Exists(dir)) return new List<string>();
            return Directory.GetFiles(dir, pattern).Select(Path.GetFileName).OfType<string>().OrderBy(f => f).ToList();
        }

        /// <summary>Legge un file.</summary>
        public Task<byte[]> LeggiAsync(string cartella, string nomeFile) => File.ReadAllBytesAsync(Resolve(cartella, NomeSicuro(nomeFile)));
    }
}
