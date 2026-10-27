using System.Net;
using System.Net.Mail;
using CG.MobileAPI.Data;
using Microsoft.Extensions.Options;

namespace CG.MobileAPI.Tools
{
    /// <summary>
    /// Invio email (ex PHPMailer + shared/setPhpEmailAuth.php).
    /// </summary>
    public class EmailTool
    {
        private readonly SmtpSettings _settings;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="EmailTool"/>.
        /// </summary>
        public EmailTool(IOptions<MobileSettings> settings)
        {
            _settings = settings.Value.Smtp;
        }

        /// <summary>
        /// Invia una email HTML.
        /// </summary>
        /// <param name="destinatari">Indirizzi dei destinatari.</param>
        /// <param name="oggetto">Oggetto.</param>
        /// <param name="corpoHtml">Corpo HTML.</param>
        /// <param name="allegati">Allegati facoltativi (nome file, contenuto).</param>
        /// <param name="cc">Indirizzi in copia facoltativi.</param>
        public async Task InviaAsync(IEnumerable<string> destinatari, string oggetto, string corpoHtml,
            IEnumerable<(string nome, byte[] contenuto)>? allegati = null, IEnumerable<string>? cc = null)
        {
            if (string.IsNullOrWhiteSpace(_settings.Host))
            {
                throw new InvalidOperationException("mobile:Smtp:Host non configurato");
            }

            using var msg = new MailMessage
            {
                From = new MailAddress(_settings.From, _settings.FromName),
                Subject = oggetto,
                Body = corpoHtml,
                IsBodyHtml = true
            };
            foreach (var d in destinatari.Where(d => !string.IsNullOrWhiteSpace(d)))
            {
                msg.To.Add(new MailAddress(d.Trim()));
            }
            foreach (var d in (cc ?? Enumerable.Empty<string>()).Where(d => !string.IsNullOrWhiteSpace(d)))
            {
                msg.CC.Add(new MailAddress(d.Trim()));
            }
            if (msg.To.Count == 0)
            {
                throw new MobileException("Nessun destinatario");
            }
            foreach (var (nome, contenuto) in allegati ?? Enumerable.Empty<(string, byte[])>())
            {
                msg.Attachments.Add(new Attachment(new MemoryStream(contenuto), nome));
            }

            using var client = new SmtpClient(_settings.Host, _settings.Port) { EnableSsl = _settings.EnableSsl };
            if (!string.IsNullOrEmpty(_settings.User))
            {
                client.Credentials = new NetworkCredential(_settings.User, _settings.Password);
            }
            await client.SendMailAsync(msg);
        }
    }
}
