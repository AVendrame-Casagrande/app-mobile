using System.Diagnostics;
using System.Text.RegularExpressions;
using CG.MobileAPI.Data;
using Microsoft.Extensions.Options;

namespace CG.MobileAPI.Tools
{
    /// <summary>
    /// Esecuzione degli eseguibili Diapason (ex CheckUserDiap.php e UpdateSOSACPN.php sul server 10.0.2.1).
    /// I PHP originali passavano i parametri a <c>shell_exec</c> senza controlli (command injection): qui l'eseguibile
    /// viene lanciato senza shell con argomenti separati, oppure, se non è presente sul server dell'API, si chiama il
    /// vecchio PHP solo con parametri validati.
    /// </summary>
    public class DiapasonExe
    {
        /// <summary>Risposta di ConCheckUser.exe per credenziali corrette.</summary>
        public const string AUTENTICATO = "0000 AUTENTICATO!";

        private static readonly Regex _codice = new(@"^[A-Za-z0-9_.\-]{1,30}$");
        private static readonly Regex _parametriSosacpn = new(@"^[A-Za-z0-9_.,;:/\- ]{1,500}$");
        private static readonly char[] _metaShell = { '&', '|', '<', '>', '^', '"', '%', '`', '\r', '\n', '\0' };

        private readonly DiapasonSettings _settings;
        private readonly IHttpClientFactory _httpFactory;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DiapasonExe"/>.
        /// </summary>
        public DiapasonExe(IOptions<MobileSettings> settings, IHttpClientFactory httpFactory)
        {
            _settings = settings.Value.Diapason;
            _httpFactory = httpFactory;
        }

        /// <summary>
        /// Verifica utente e password su Diapason. Restituisce l'output di ConCheckUser.exe
        /// (<see cref="AUTENTICATO"/> se le credenziali sono corrette).
        /// </summary>
        public async Task<string> CheckUserAsync(string ambiente, string utente, string pwd)
        {
            if (!_codice.IsMatch(ambiente) || !_codice.IsMatch(utente))
            {
                throw new MobileException("Ambiente o utente non validi");
            }
            if (string.IsNullOrEmpty(pwd) || pwd.Length > 100 || pwd.Any(char.IsWhiteSpace))
            {
                throw new MobileException("Password non valida");
            }

            if (!string.IsNullOrWhiteSpace(_settings.CheckUserExePath))
            {
                return await RunAsync(_settings.CheckUserExePath, ambiente, utente, pwd);
            }

            // Il PHP remoto passa ancora la password alla shell: si bloccano i caratteri che cmd.exe interpreta.
            if (pwd.IndexOfAny(_metaShell) >= 0)
            {
                throw new MobileException("La password contiene caratteri non supportati dal server Diapason");
            }
            return await PostAsync(_settings.CheckUserUrl, new Dictionary<string, string>
            {
                ["ambiente"] = ambiente,
                ["utente"] = utente,
                ["pwd"] = pwd
            });
        }

        /// <summary>
        /// Aggiorna SOSACPN su Diapason (ex UpdateSOSACPN.php). Restituisce l'output dell'eseguibile.
        /// </summary>
        public async Task<string> UpdateSosacpnAsync(string parametri)
        {
            if (!_parametriSosacpn.IsMatch(parametri ?? ""))
            {
                throw new MobileException("Parametri non validi");
            }

            if (!string.IsNullOrWhiteSpace(_settings.SosacpnExePath))
            {
                return await RunAsync(_settings.SosacpnExePath, parametri!.Split(' ', StringSplitOptions.RemoveEmptyEntries));
            }
            return await PostAsync(_settings.SosacpnUrl, new Dictionary<string, string> { ["parametri"] = parametri! });
        }

        private static async Task<string> RunAsync(string exe, params string[] args)
        {
            var psi = new ProcessStartInfo(exe)
            {
                UseShellExecute = false,
                RedirectStandardOutput = true,
                CreateNoWindow = true,
                WorkingDirectory = Path.GetDirectoryName(exe) ?? ""
            };
            foreach (var a in args)
            {
                psi.ArgumentList.Add(a);
            }

            using var process = Process.Start(psi) ?? throw new InvalidOperationException($"Impossibile avviare {exe}");
            var output = await process.StandardOutput.ReadToEndAsync();
            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(60));
            await process.WaitForExitAsync(cts.Token);
            return output;
        }

        private async Task<string> PostAsync(string url, Dictionary<string, string> data)
        {
            var client = _httpFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(60);
            using var response = await client.PostAsync(url, new FormUrlEncodedContent(data));
            response.EnsureSuccessStatusCode();
            return await response.Content.ReadAsStringAsync();
        }
    }
}
