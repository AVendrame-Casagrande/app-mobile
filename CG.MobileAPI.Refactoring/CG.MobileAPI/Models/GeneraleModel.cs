using System.Globalization;
using System.Net;
using System.Text;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;
using iText.Html2pdf;
using iText.Kernel.Geom;
using iText.Kernel.Pdf;
using iText.StyledXmlParser.Resolver.Resource;

namespace CG.MobileAPI.Models
{
    // -----------------------------------------------------------------------------------------------------------------
    // --- Richieste ---------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Richiesta di log/log.php: riga di log inviata dall'app.
    /// </summary>
    public class LogRequest
    {
        /// <summary>Testo del log.</summary>
        public string? log { get; set; }
        /// <summary>Dispositivo che invia il log.</summary>
        public string? device { get; set; }
        /// <summary>Versione dell'app.</summary>
        public string? version { get; set; }
    }

    /// <summary>
    /// Richiesta di deleteFoto.php: elimina la foto n. <see cref="intFoto"/> dell'articolo.
    /// </summary>
    public class DeleteFotoRequest
    {
        /// <summary>Codice articolo (<c>/</c> diventa <c>-</c> nel nome del file).</summary>
        public string? articolo { get; set; }
        /// <summary>Indice (da 1) della foto da eliminare.</summary>
        public string? intFoto { get; set; }
    }

    /// <summary>
    /// Richiesta di getSituazioneOdv.php.
    /// </summary>
    public class GetSituazioneOdvRequest
    {
        /// <summary>Numero (o prefisso del numero) dell'ordine di vendita.</summary>
        public string? or_om { get; set; }
    }

    /// <summary>
    /// Richiesta di uploadFoto.php (multipart). Il servizio è disattivato: risponde sempre <c>uploaded failed</c>.
    /// </summary>
    public class UploadFotoRequest
    {
        /// <summary>Foto (ignorata).</summary>
        public IFormFile? file { get; set; }
        /// <summary>Codice articolo (ignorato).</summary>
        public string? name { get; set; }
    }

    /// <summary>
    /// Richiesta di uploadFotoArm.php (multipart): foto da inviare all'FTP delle foto ARM.
    /// </summary>
    public class UploadFotoArmRequest
    {
        /// <summary>Foto JPG.</summary>
        public IFormFile? file { get; set; }
        /// <summary>Nome del file senza estensione (codice articolo / numero).</summary>
        public string? name { get; set; }
    }

    /// <summary>
    /// Richiesta di uploadFotoProfilo.php (multipart). Codice e nome portale sono presi dal token.
    /// </summary>
    public class UploadFotoProfiloRequest
    {
        /// <summary>Foto JPG del profilo.</summary>
        public IFormFile? file { get; set; }
    }

    /// <summary>
    /// Richiesta di queryDesktop/giacenze/checkMagazzinoExists.php.
    /// </summary>
    public class CheckMagazzinoExistsRequest
    {
        /// <summary>Codice magazzino.</summary>
        public string? magazzino { get; set; }
    }

    /// <summary>
    /// Richiesta di queryDesktop/giacenze/checkVanoExists.php.
    /// </summary>
    public class CheckVanoExistsRequest
    {
        /// <summary>Codice vano.</summary>
        public string? vano { get; set; }
    }

    /// <summary>
    /// Richiesta di queryDesktop/giacenze/convertPDF.php: tabella HTML da convertire in PDF.
    /// </summary>
    public class ConvertPdfRequest
    {
        /// <summary>HTML della tabella.</summary>
        public string? table { get; set; }
        /// <summary>Nome del file senza estensione.</summary>
        public string? filename { get; set; }
        /// <summary>Titolo dell'intestazione; alcuni valori cambiano impaginazione e cartella di destinazione.</summary>
        public string? magazzino { get; set; }
        /// <summary>Sezione chiamante (non usata dal servizio).</summary>
        public string? sezione { get; set; }
    }

    /// <summary>
    /// Richiesta di queryDesktop/modifiche_tecniche/createPDF.php: HTML da convertire in PDF.
    /// </summary>
    public class CreatePdfRequest
    {
        /// <summary>HTML del documento.</summary>
        public string? html { get; set; }
        /// <summary>Nome di un foglio di stile nella cartella queryDesktop/modifiche_tecniche (es. invoice_letter.css), o vuoto.</summary>
        public string? css { get; set; }
        /// <summary>Nome del file PDF (con estensione).</summary>
        public string? filename { get; set; }
        /// <summary>Inviato dal client ma non usato dal servizio.</summary>
        public string? different_destination { get; set; }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // --- Risposte / impostazioni -------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Risposta di checkVersion.php: ultima versione dell'app e note di rilascio.
    /// </summary>
    public class CheckVersionResponse
    {
        /// <summary>Ultima versione pubblicata (es. 2.0.16): il client la confronta con la propria.</summary>
        [JsonPropertyName("code")]
        public string code { get; set; } = "";

        /// <summary>Note di rilascio della versione pubblicata.</summary>
        [JsonPropertyName("changeLog")]
        public string[] changeLog { get; set; } = Array.Empty<string>();

        /// <summary>DEPRECATO (vecchi tablet Android 5.0).</summary>
        [JsonPropertyName("updateTablet")]
        public bool updateTablet { get; set; }

        /// <summary>Aggiornamento obbligatorio.</summary>
        [JsonPropertyName("mandatoryUpdate")]
        public bool mandatoryUpdate { get; set; }
    }

    /// <summary>
    /// Server FTP delle foto ARM (sezione <c>mobile:FotoArm</c> della configurazione).
    /// </summary>
    public class FotoArmFtpSettings
    {
        /// <summary>Host FTP.</summary>
        public string Host { get; set; } = "";
        /// <summary>Utente FTP.</summary>
        public string User { get; set; } = "";
        /// <summary>Password FTP.</summary>
        public string Password { get; set; } = "";
    }

    // -----------------------------------------------------------------------------------------------------------------
    // --- Data class --------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Accesso ai dati per versione, foto, ODV e servizi generali (mobile/server/query e queryDesktop).
    /// </summary>
    public class DBGENERALE
    {
        /// <summary>Indirizzo pubblico del web server usato per gli URL dei PDF se non configurato (<c>mobile:Storage:PublicBaseUrl</c>).</summary>
        public const string UrlPubblicoPredefinito = "http://app.casagrandegroup.local";

        /// <summary>Cartella delle foto articolo (ex ../../../applicazioni/tecnico/foto).</summary>
        private const string CARTELLA_FOTO_ARTICOLI = "applicazioni/tecnico/foto";

        /// <summary>Cartella delle foto profilo (ex ../../server/storage/foto_profilo).</summary>
        private const string CARTELLA_FOTO_PROFILO = "mobile/server/storage/foto_profilo";

        /// <summary>Cartella degli script queryDesktop/giacenze (base per i percorsi relativi nell'HTML dei PDF).</summary>
        private const string CARTELLA_QD_GIACENZE = "mobile/server/queryDesktop/giacenze";

        /// <summary>Cartella degli script queryDesktop/modifiche_tecniche (fogli di stile e immagini dei PDF).</summary>
        private const string CARTELLA_QD_MODIFICHE_TECNICHE = "mobile/server/queryDesktop/modifiche_tecniche";

        private static readonly Regex _spaziMultipli = new(@"\s\s+");

        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBGENERALE"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBGENERALE(MobileConnections conn)
        {
            _conn = conn;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Versione ------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Ultima versione dell'app con il relativo changelog (ex checkVersion.php).
        /// </summary>
        public CheckVersionResponse CheckVersion()
        {
            return new CheckVersionResponse
            {
                code = GeneraleChangelog.VersioneCorrente,
                changeLog = GeneraleChangelog.Versioni[GeneraleChangelog.ChiaveVersioneCorrente],
                updateTablet = GeneraleChangelog.UpdateTablet,
                mandatoryUpdate = GeneraleChangelog.MandatoryUpdate
            };
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Foto articolo -------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Elimina la foto n. intFoto dell'articolo e rinumera le successive (ex deleteFoto.php).
        /// Restituisce <c>success</c> oppure <c>error deleting the file ...</c> / <c>error renaming the file ...</c>.
        /// </summary>
        public string DeleteFoto(DeleteFotoRequest request, StorageTool storage)
        {
            if (string.IsNullOrWhiteSpace(request.articolo))
            {
                throw new MobileException("Articolo obbligatorio");
            }
            if (!int.TryParse(request.intFoto?.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var intFoto))
            {
                throw new MobileException("intFoto non valido");
            }

            var articolo = request.articolo.Replace("/", "-");
            var numeroFoto = GetNumeroFoto(storage, CARTELLA_FOTO_ARTICOLI, articolo);

            // Es.: cancello 96117117_3, rinomino 96117117_4 in 96117117_3, poi 96117117_5 in _4 ecc.
            for (var i = 1; i <= numeroFoto; i++)
            {
                var filename = $"{articolo}_{i}.jpg";

                if (i == intFoto)
                {
                    if (!storage.Elimina(CARTELLA_FOTO_ARTICOLI, filename))
                    {
                        return "error deleting the file " + filename;
                    }
                }
                else if (i > intFoto)
                {
                    if (!storage.Rinomina(CARTELLA_FOTO_ARTICOLI, filename, $"{articolo}_{i - 1}.jpg"))
                    {
                        return "error renaming the file " + filename;
                    }
                }
            }

            return "success";
        }

        /// <summary>
        /// Caricamento della foto articolo (ex uploadFoto.php). Il servizio PHP è disattivato (la logica è commentata)
        /// e risponde sempre <c>uploaded failed</c>: il comportamento è mantenuto.
        /// </summary>
        public string UploadFoto(UploadFotoRequest request)
        {
            return "uploaded failed";
        }

        /// <summary>
        /// Invia la foto all'FTP delle foto ARM (ex uploadFotoArm.php). Se il nome esiste già viene aggiunto
        /// un suffisso <c>_n</c>. Restituisce <c>uploaded</c> oppure <c>upload ftp failed</c>.
        /// </summary>
        public async Task<string> UploadFotoArmAsync(UploadFotoArmRequest request, FotoArmFtpSettings ftp)
        {
            if (request.file == null || request.file.Length == 0)
            {
                throw new MobileException("File mancante");
            }
            if (string.IsNullOrWhiteSpace(request.name))
            {
                throw new MobileException("Nome obbligatorio");
            }
            if (string.IsNullOrWhiteSpace(ftp.Host))
            {
                throw new InvalidOperationException("mobile:FotoArm:Host non configurato");
            }

            var name = StorageTool.NomeSicuro(request.name);
            var credenziali = new NetworkCredential(ftp.User, ftp.Password);
            var filename = name + ".jpg";

            // Stesso pattern del PHP ("<name>*..jpg") per l'elenco dei file già presenti
            var presenti = await FtpElencaAsync(ftp.Host, name + "*..jpg", credenziali);
            if (presenti.Count > 0)
            {
                var n = 0;
                while (presenti.Contains(filename))
                {
                    n++;
                    filename = $"{name}_{n}.jpg";
                }
            }

            return await FtpCaricaAsync(ftp.Host, filename, request.file, credenziali) ? "uploaded" : "upload ftp failed";
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Foto profilo --------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Registra la foto profilo in public.utenti_info (insert o update) e salva il file <c>codice.jpg</c>
        /// in mobile/server/storage/foto_profilo (ex uploadFotoProfilo.php). Restituisce <c>uploaded</c> o <c>error</c>.
        /// </summary>
        /// <param name="request">La foto.</param>
        /// <param name="codice">Codice Diapason dell'utente autenticato.</param>
        /// <param name="nomePortale">Nome portale dell'utente autenticato.</param>
        /// <param name="storage">Accesso ai file del web server.</param>
        public async Task<string> UploadFotoProfiloAsync(UploadFotoProfiloRequest request, string codice, string nomePortale, StorageTool storage)
        {
            if (request.file == null || request.file.Length == 0)
            {
                throw new MobileException("File mancante");
            }

            var recordExists = DbHelper.Query(_conn.PgDb1,
                "select codice from public.utenti_info where codice = ?", codice).Count > 0;

            if (!recordExists)
            {
                DbHelper.NonQuery(_conn.PgDb1,
                    "insert into public.utenti_info (codice, immagine, nome_portale) values (?, ?, ?)",
                    codice, codice, nomePortale);
            }
            else
            {
                DbHelper.NonQuery(_conn.PgDb1,
                    "update public.utenti_info set immagine = ? where codice = ?", codice, codice);
            }

            var salvato = await storage.SalvaAsync(request.file, CARTELLA_FOTO_PROFILO, codice + ".jpg", StorageTool.Immagini);
            return salvato ? "uploaded" : "error";
        }

        /// <summary>
        /// Rimuove la foto profilo dell'utente (immagine = '') in public.utenti_info (ex rimuoviFotoProfilo.php).
        /// Restituisce <c>updated</c>.
        /// </summary>
        /// <param name="codice">Codice Diapason dell'utente autenticato.</param>
        public string RimuoviFotoProfilo(string codice)
        {
            DbHelper.NonQuery(_conn.PgDb1, "update public.utenti_info set immagine = '' where codice = ?", codice);
            return "updated";
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Situazione ODV ------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Situazione delle righe degli ordini di vendita il cui numero inizia per or_om, raggruppate per ordine,
        /// con lo stato di ogni riga (disponibile, disponibile_prel, in_oda, in_odl, mancante) (ex getSituazioneOdv.php
        /// e getSituazioneOdvIMM.php). Le righe sono filtrate per la società del token: la variante IMM filtrava
        /// cs_fabbmanc_rodv.societa (e ripeteva la società su ogni join, condizioni già implicate dai join per societa),
        /// quella Casagrande non filtrava affatto.
        /// </summary>
        /// <param name="request">Numero ordine.</param>
        /// <param name="societa">Società del token.</param>
        public List<Dictionary<string, object?>> GetSituazioneOdv(GetSituazioneOdvRequest request, string societa)
        {
            if (string.IsNullOrWhiteSpace(request.or_om))
            {
                throw new MobileException("Numero ordine obbligatorio");
            }

            const string query = @"select cs_fabbmanc_rodv.numero, cs_fabbmanc_rodv.pos, cs_fabbmanc_odv.cliente, cs_fabbmanc_odv.nomecliente,
cs_fabbmanc_odv.causale, cs_fabbmanc_rodv.articolo, cs_fabbmanc_rodv.descarticolo, cs_fabbmanc_odv.dtcons,
cs_fabbmanc_rodv.umis, cs_fabbmanc_rodv.giactransit, cs_fabbmanc_rodv.qtaape, cs_fabbmanc_rodv.qtaiodl, cs_fabbmanc_rodv.qtaisoda, cs_fabbmanc_rodv.qtaisrda,
cs_fabbmanc_rodv.qtafab, cs_fabbmanc_rodv.giacmag, cs_fabbmanc_rodv_dispo.giacdispo, cs_fabbmanc_rodv.giacdispoint,
cs_fabbmanc_rodv.giacdispoext, cs_fabbmanc_rodv_dispo.bolladtlastdispo, cs_fabbmanc_rodv_dispo.nomefornlastdispo,
cs_fabbmanc_rodv_impsoda.numsoda, cs_odaschedule.psdesdt, cs_soggetti.aninco, cs_fabbmanc_rodv.magazzino, cs_fabbmanc_rodv_dispo.magdispo,
cs_fabbmanc_rodv_impodl.numodl, cs_fabbmanc_rodv_impsrda.numsrda, cs_fabbmanc_odl.duedate
from ((((((cs_fabbmanc_rodv left join cs_fabbmanc_rodv_dispo on (cs_fabbmanc_rodv.seq = cs_fabbmanc_rodv_dispo.seq) AND (cs_fabbmanc_rodv.pos = cs_fabbmanc_rodv_dispo.pos) and (cs_fabbmanc_rodv.numero = cs_fabbmanc_rodv_dispo.numero) and (cs_fabbmanc_rodv.societa = cs_fabbmanc_rodv_dispo.societa))
left join cs_fabbmanc_rodv_impsoda on (cs_fabbmanc_rodv.seq = cs_fabbmanc_rodv_impsoda.seq) and (cs_fabbmanc_rodv.pos = cs_fabbmanc_rodv_impsoda.pos) and (cs_fabbmanc_rodv.numero = cs_fabbmanc_rodv_impsoda.numero) and (cs_fabbmanc_rodv.societa = cs_fabbmanc_rodv_impsoda.societa))
left join cs_odaschedule on (cs_fabbmanc_rodv_impsoda.schedsoda = cs_odaschedule.pslino) and (cs_fabbmanc_rodv_impsoda.possoda = cs_odaschedule.psordln) and (cs_fabbmanc_rodv_impsoda.numsoda = cs_odaschedule.psordno) and (cs_fabbmanc_rodv_impsoda.societa = cs_odaschedule.pscosc))
left join cs_odatestata on (cs_fabbmanc_rodv_impsoda.numsoda = cs_odatestata.phordno) and (cs_fabbmanc_rodv_impsoda.societa = cs_odatestata.phcosc))
left join cs_soggetti on (cs_odatestata.phsupno = cs_soggetti.ancoco) and (cs_odatestata.phcosc = cs_soggetti.ancoso))
left join cs_fabbmanc_rodv_impodl on (cs_fabbmanc_rodv.seq = cs_fabbmanc_rodv_impodl.seq) and (cs_fabbmanc_rodv.pos = cs_fabbmanc_rodv_impodl.pos) and (cs_fabbmanc_rodv.numero = cs_fabbmanc_rodv_impodl.numero) and (cs_fabbmanc_rodv.societa = cs_fabbmanc_rodv_impodl.societa))
left join cs_fabbmanc_rodv_impsrda on (cs_fabbmanc_rodv.seq = cs_fabbmanc_rodv_impsrda.seq) and (cs_fabbmanc_rodv.pos = cs_fabbmanc_rodv_impsrda.pos) and (cs_fabbmanc_rodv.numero = cs_fabbmanc_rodv_impsrda.numero) and (cs_fabbmanc_rodv.societa = cs_fabbmanc_rodv_impsrda.societa)
left join cs_fabbmanc_odl on (cs_fabbmanc_rodv_impodl.numodl = cs_fabbmanc_odl.numero) and (cs_fabbmanc_rodv_impodl.societa = cs_fabbmanc_odl.societa)
inner join cs_fabbmanc_odv on cs_fabbmanc_odv.societa = cs_fabbmanc_rodv.societa and cs_fabbmanc_odv.numero = cs_fabbmanc_rodv.numero
where cs_fabbmanc_rodv.societa = ? and cs_fabbmanc_rodv.numero like ?
and cs_fabbmanc_odv.causale != 'J' and cs_fabbmanc_odv.causale != 'L' and cs_fabbmanc_odv.causale != 'N'
order by cs_fabbmanc_rodv.numero, cs_fabbmanc_rodv.pos";

            var rows = DbHelper.Query(_conn.PgCasagrande, query, societa, request.or_om + "%");

            var listaOdv = new List<Dictionary<string, object?>>();
            Dictionary<string, object?>? odvCorrente = null;
            string? numeroCorrente = null;

            foreach (var row in rows)
            {
                var giacmag = PhpFloat(row["giacmag"]);
                var giacdispo = PhpFloat(row["giacdispoint"]); // come nel PHP: giacdispo = giacdispoint
                var qtaiodl = PhpFloat(row["qtaiodl"]);
                var qtaisoda = PhpFloat(row["qtaisoda"]);
                var giactransit = PhpFloat(row["giactransit"]);
                var numero = row["numero"]?.ToString();

                if (odvCorrente == null || numero != numeroCorrente)
                {
                    numeroCorrente = numero;
                    odvCorrente = new Dictionary<string, object?>
                    {
                        ["bolladtlastdispo"] = PhpInt(row["bolladtlastdispo"]),
                        ["causale"] = row["causale"],
                        ["dtcons"] = PhpInt(row["dtcons"]),
                        ["cliente"] = row["cliente"],
                        ["nomecliente"] = _spaziMultipli.Replace(row["nomecliente"]?.ToString() ?? "", " "),
                        ["nomefornlastdispo"] = row["nomefornlastdispo"],
                        ["numero"] = numero,
                        ["magazzino"] = row["magazzino"],
                        ["righe"] = new List<Dictionary<string, object?>>()
                    };
                    listaOdv.Add(odvCorrente);
                }

                var impegnato = PhpFloat(row["qtaape"]);
                var statoOdv = new List<string>();
                object? magdispo = row["magdispo"];
                double qtaMancanteRiga = 0;

                if (giacmag > 0)
                {
                    statoOdv.Add("disponibile");
                }

                var giacdispoRiga = giacdispo;
                if (giacdispo > 0 || giactransit > 0)
                {
                    if (giactransit > 0 && giacdispo > 0)
                    {
                        magdispo = "Mag. Multipli";
                    }
                    if (giactransit > 0 && giacdispo <= 0)
                    {
                        magdispo = "In Transito";
                    }

                    giacdispoRiga += giactransit;
                    statoOdv.Add("disponibile_prel");
                }

                if (qtaisoda > 0)
                {
                    statoOdv.Add("in_oda");
                }

                if (qtaiodl > 0)
                {
                    statoOdv.Add("in_odl");
                }

                var qtaMancante = impegnato - (qtaisoda + qtaiodl + giacdispo + giacmag + giactransit);
                if (qtaMancante > 0)
                {
                    statoOdv.Add("mancante");
                    qtaMancanteRiga = qtaMancante;
                }

                var riga = new Dictionary<string, object?>
                {
                    ["articolo"] = row["articolo"],
                    ["descarticolo"] = _spaziMultipli.Replace(row["descarticolo"]?.ToString() ?? "", " "),
                    ["giacdispo"] = giacdispoRiga,
                    ["giacdispoext"] = PhpFloat(row["giacdispoext"]),
                    ["giacmag"] = giacmag,
                    ["magazzino"] = row["magazzino"],
                    ["magdispo"] = magdispo,
                    ["giactransit"] = giactransit,
                    ["numodl"] = row["numodl"],
                    ["duedate"] = row["duedate"],
                    ["numsoda"] = row["numsoda"],
                    ["aninco"] = row["aninco"],
                    ["numsrda"] = row["numsrda"],
                    ["pos"] = PhpInt(row["pos"]),
                    ["psdesdt"] = PhpInt(row["psdesdt"]),
                    ["qtaape"] = impegnato,
                    ["qtafab"] = PhpFloat(row["qtafab"]),
                    ["qtaiodl"] = qtaiodl,
                    ["qtaisoda"] = qtaisoda,
                    ["qtaisrda"] = PhpFloat(row["qtaisrda"]),
                    ["qta_mancante"] = qtaMancanteRiga,
                    ["umis"] = row["umis"],
                    ["stato_odv"] = statoOdv
                };

                ((List<Dictionary<string, object?>>)odvCorrente["righe"]!).Add(riga);
            }

            return listaOdv;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- queryDesktop/giacenze -----------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Indica se il magazzino esiste in MASAHED per la società del token
        /// (ex queryDesktop/giacenze/checkMagazzinoExists.php e checkMagazzinoExistsIMM.php).
        /// </summary>
        /// <param name="request">Codice magazzino.</param>
        /// <param name="societa">Società del token.</param>
        public bool CheckMagazzinoExists(CheckMagazzinoExistsRequest request, string societa)
        {
            if (request.magazzino == null)
            {
                throw new MobileException("Magazzino obbligatorio");
            }

            return DbHelper.Query(_conn.Db2,
                @"SELECT DISTINCT MASAHED.MAHMAG
FROM MASAHED
WHERE MASAHED.MAHCOSC = ? AND MASAHED.MAHMAG = ?", societa, request.magazzino).Count > 0;
        }

        /// <summary>
        /// Indica se il vano esiste in MASAHLO (ex queryDesktop/giacenze/checkVanoExists.php e checkVanoExistsIMM.php).
        /// La versione Casagrande non filtrava la società, la variante IMM sì (MASAHLO.MAHCOSC='IMM00'): il filtro
        /// è applicato solo per IMM, così per Casagrande il comportamento resta quello del PHP.
        /// </summary>
        /// <param name="request">Codice vano.</param>
        /// <param name="societa">Società del token.</param>
        public bool CheckVanoExists(CheckVanoExistsRequest request, string societa)
        {
            if (request.vano == null)
            {
                throw new MobileException("Vano obbligatorio");
            }

            if (societa == CodiciSocieta.IMM)
            {
                return DbHelper.Query(_conn.Db2,
                    @"SELECT DISTINCT MASAHLO.MLHLOC
FROM MASAHLO WHERE MASAHLO.MAHCOSC = ? AND MASAHLO.MLHLOC = ?", societa, request.vano).Count > 0;
            }

            return DbHelper.Query(_conn.Db2,
                @"SELECT DISTINCT MASAHLO.MLHLOC
FROM MASAHLO WHERE MASAHLO.MLHLOC = ?", request.vano).Count > 0;
        }

        /// <summary>
        /// Converte la tabella HTML in un PDF A4 con intestazione (titolo, data, pagina/pagine), lo salva in
        /// mobile/server/storage/converted_pdf (o conto_lavoro) e restituisce l'URL del file
        /// (ex queryDesktop/giacenze/convertPDF.php, che usava mPDF).
        /// </summary>
        /// <param name="request">Tabella, nome file e titolo.</param>
        /// <param name="storage">Accesso ai file del web server.</param>
        /// <param name="urlPubblico">Indirizzo pubblico del web server (es. http://app.casagrandegroup.local).</param>
        public async Task<string> ConvertPdfAsync(ConvertPdfRequest request, StorageTool storage, string urlPubblico)
        {
            if (string.IsNullOrWhiteSpace(request.filename))
            {
                throw new MobileException("Nome file obbligatorio");
            }

            var magazzino = request.magazzino ?? "";
            var nomeFile = StorageTool.NomeSicuro(request.filename + ".pdf");

            var orizzontale = false;
            var fontSize = 10;
            var marginRight = 2;

            switch (magazzino)
            {
                case "Piano_Ordini":
                    orizzontale = true;
                    fontSize = 7;
                    marginRight = 6;
                    break;

                case "Articoli_Nuovi":
                    marginRight = 4;
                    fontSize = 8;
                    break;
            }

            var intestazione = "font-family: serif; font-size: 8pt; color: #000000; font-style: italic; font-weight: bold; vertical-align: bottom;";
            var css = new StringBuilder()
                .Append("@page { size: A4").Append(orizzontale ? " landscape" : "").Append("; ")
                .Append(CultureInfo.InvariantCulture, $"margin: 12mm {marginRight}mm 6mm 6mm; ")
                .Append("@top-left { content: ").Append(CssStringa(magazzino)).Append("; text-decoration: underline; ").Append(intestazione).Append(" } ")
                .Append("@top-right { content: ").Append(CssStringa(DateTime.Now.ToString("d-MM-yyyy", CultureInfo.InvariantCulture) + "    "))
                .Append(" counter(page) \"/\" counter(pages); ").Append(intestazione).Append(" } } ")
                .Append(CultureInfo.InvariantCulture, $"body {{ font-size: {fontSize}pt; }}")
                .ToString();

            var html = $"<html><head><meta charset=\"utf-8\"><style>{css}</style></head><body>{request.table ?? ""}</body></html>";
            var pdf = GeneraPdf(html, orizzontale ? PageSize.A4.Rotate() : PageSize.A4, storage, CARTELLA_QD_GIACENZE, urlPubblico);

            var cartella = magazzino == "Invio_Materiale_Conto_Lavoro" || magazzino == "Lista_Articoli_NO_Magazzini_Auto"
                ? "conto_lavoro"
                : "converted_pdf";

            await storage.SalvaBytesAsync(pdf, "mobile/server/storage/" + cartella, nomeFile);

            return $"{urlPubblico.TrimEnd('/')}/mobile/server/storage/{cartella}/{nomeFile}";
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- queryDesktop/modifiche_tecniche -------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Converte l'HTML (con l'eventuale foglio di stile) in un PDF A4, lo salva in
        /// mobile/server/storage/modifiche_tecniche e restituisce l'URL del file
        /// (ex queryDesktop/modifiche_tecniche/createPDF.php, che usava mPDF).
        /// </summary>
        /// <param name="request">HTML, foglio di stile e nome file.</param>
        /// <param name="storage">Accesso ai file del web server.</param>
        /// <param name="urlPubblico">Indirizzo pubblico del web server (es. http://app.casagrandegroup.local).</param>
        public async Task<string> CreatePdfAsync(CreatePdfRequest request, StorageTool storage, string urlPubblico)
        {
            if (string.IsNullOrWhiteSpace(request.filename))
            {
                throw new MobileException("Nome file obbligatorio");
            }

            var nomeFile = StorageTool.NomeSicuro(request.filename);
            if (!nomeFile.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
            {
                throw new MobileException("Il nome file deve avere estensione .pdf");
            }

            // Il PHP faceva file_get_contents($css): qui solo fogli .css della cartella dello script
            var foglioStile = "";
            if (!string.IsNullOrEmpty(request.css))
            {
                var nomeCss = StorageTool.NomeSicuro(request.css);
                if (!nomeCss.EndsWith(".css", StringComparison.OrdinalIgnoreCase))
                {
                    throw new MobileException("Foglio di stile non valido");
                }
                if (storage.Esiste(CARTELLA_QD_MODIFICHE_TECNICHE, nomeCss))
                {
                    foglioStile = Encoding.UTF8.GetString(await storage.LeggiAsync(CARTELLA_QD_MODIFICHE_TECNICHE, nomeCss));
                }
            }

            // Margini di default di mPDF con margin_top = 6
            var html = "<html><head><meta charset=\"utf-8\"><style>@page { size: A4; margin: 6mm 15mm 16mm 15mm; } "
                       + foglioStile.Replace("</style", "", StringComparison.OrdinalIgnoreCase)
                       + $"</style></head><body>{request.html ?? ""}</body></html>";

            var pdf = GeneraPdf(html, PageSize.A4, storage, CARTELLA_QD_MODIFICHE_TECNICHE, urlPubblico);

            await storage.SalvaBytesAsync(pdf, "mobile/server/storage/modifiche_tecniche", nomeFile);

            return $"{urlPubblico.TrimEnd('/')}/mobile/server/storage/modifiche_tecniche/{nomeFile}";
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Funzioni private ----------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Numero di foto consecutive <c>articolo_1.jpg</c>, <c>articolo_2.jpg</c>, ... presenti nella cartella;
        /// i <c>.jpeg</c> vengono rinominati in <c>.jpg</c> (ex shared_functions/getNumeroFoto.php).
        /// </summary>
        private static int GetNumeroFoto(StorageTool storage, string cartella, string articolo)
        {
            var numeroFoto = 1;
            while (true)
            {
                var nome = $"{articolo}_{numeroFoto}";
                if (storage.Esiste(cartella, nome + ".jpg"))
                {
                    numeroFoto++;
                }
                else if (storage.Esiste(cartella, nome + ".jpeg"))
                {
                    storage.Rinomina(cartella, nome + ".jpeg", nome + ".jpg");
                    numeroFoto++;
                }
                else
                {
                    break;
                }
            }
            return numeroFoto - 1;
        }

        /// <summary>
        /// Converte l'HTML in PDF con pdfHTML. Le risorse (immagini, CSS) vengono lette solo dal disco del web server:
        /// percorsi relativi alla cartella dello script PHP originale e URL dell'host pubblico (mappati sul disco).
        /// Ogni altro indirizzo viene ignorato, così l'HTML del client non può far fare richieste ad altri server.
        /// </summary>
        private static byte[] GeneraPdf(string html, PageSize formato, StorageTool storage, string cartellaBase, string urlPubblico)
        {
            var dirBase = storage.Resolve(cartellaBase);
            var props = new ConverterProperties()
                .SetBaseUri(dirBase.TrimEnd(System.IO.Path.DirectorySeparatorChar) + System.IO.Path.DirectorySeparatorChar)
                .SetResourceRetriever(new RisorseWebServer(storage, urlPubblico));

            using var ms = new MemoryStream();
            using (var writer = new PdfWriter(ms))
            using (var documento = new PdfDocument(writer))
            {
                documento.SetDefaultPageSize(formato);
                HtmlConverter.ConvertToPdf(html, documento, props);
            }
            return ms.ToArray();
        }

        /// <summary>Stringa CSS tra virgolette (per <c>content</c>), con caratteri speciali neutralizzati.</summary>
        private static string CssStringa(string valore)
        {
            var sb = new StringBuilder("\"");
            foreach (var c in valore)
            {
                if (c == '"' || c == '\\' || c < 0x20 || c == '<' || c == '>')
                {
                    sb.Append('\\').Append(((int)c).ToString("x", CultureInfo.InvariantCulture)).Append(' ');
                }
                else
                {
                    sb.Append(c);
                }
            }
            return sb.Append('"').ToString();
        }

        /// <summary>Conversione numerica come il cast <c>(float)</c> di PHP (prefisso numerico, altrimenti 0).</summary>
        private static double PhpFloat(object? valore)
        {
            var m = Regex.Match(valore?.ToString()?.Trim() ?? "", @"^[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?");
            return m.Success ? double.Parse(m.Value, NumberStyles.Float, CultureInfo.InvariantCulture) : 0;
        }

        /// <summary>Conversione numerica come il cast <c>(int)</c> di PHP (prefisso numerico troncato, altrimenti 0).</summary>
        private static long PhpInt(object? valore)
        {
            var d = PhpFloat(valore);
            return d >= long.MaxValue || d <= long.MinValue ? 0 : (long)Math.Truncate(d);
        }

        /// <summary>Elenco dei nomi sull'FTP (NLST); lista vuota se il server non trova nulla (come ftp_nlist = false).</summary>
        private static async Task<List<string>> FtpElencaAsync(string host, string pattern, NetworkCredential credenziali)
        {
#pragma warning disable SYSLIB0014 // FtpWebRequest: unico client FTP del framework, nessun pacchetto aggiuntivo
            var req = (FtpWebRequest)WebRequest.Create($"ftp://{host}/{pattern}");
#pragma warning restore SYSLIB0014
            req.Method = WebRequestMethods.Ftp.ListDirectory;
            req.Credentials = credenziali;
            try
            {
                using var resp = (FtpWebResponse)await req.GetResponseAsync();
                using var reader = new StreamReader(resp.GetResponseStream());
                var elenco = new List<string>();
                string? riga;
                while ((riga = await reader.ReadLineAsync()) != null)
                {
                    if (riga.Trim() != "") elenco.Add(riga.Trim());
                }
                return elenco;
            }
            catch (WebException)
            {
                return new List<string>();
            }
        }

        /// <summary>Carica il file sull'FTP in modalità binaria; false se il trasferimento fallisce (come ftp_put).</summary>
        private static async Task<bool> FtpCaricaAsync(string host, string filename, IFormFile file, NetworkCredential credenziali)
        {
#pragma warning disable SYSLIB0014
            var req = (FtpWebRequest)WebRequest.Create($"ftp://{host}/{Uri.EscapeDataString(filename)}");
#pragma warning restore SYSLIB0014
            req.Method = WebRequestMethods.Ftp.UploadFile;
            req.Credentials = credenziali;
            req.UseBinary = true;
            try
            {
                await using (var dest = await req.GetRequestStreamAsync())
                await using (var src = file.OpenReadStream())
                {
                    await src.CopyToAsync(dest);
                }
                using var resp = (FtpWebResponse)await req.GetResponseAsync();
                return true;
            }
            catch (WebException)
            {
                return false;
            }
        }

        /// <summary>
        /// Resource retriever di pdfHTML limitato ai file del web server: file locali sotto la radice e URL
        /// dell'host pubblico (letti dal disco). Gli altri indirizzi restituiscono null (risorsa ignorata).
        /// </summary>
        private sealed class RisorseWebServer : IResourceRetriever
        {
            private readonly StorageTool _storage;
            private readonly Uri? _pubblico;

            public RisorseWebServer(StorageTool storage, string urlPubblico)
            {
                _storage = storage;
                Uri.TryCreate(urlPubblico, UriKind.Absolute, out _pubblico);
            }

            public Stream? GetInputStreamByUrl(Uri url)
            {
                var bytes = GetByteArrayByUrl(url);
                return bytes == null ? null : new MemoryStream(bytes);
            }

            public byte[]? GetByteArrayByUrl(Uri url)
            {
                try
                {
                    string relativo;
                    if (url.IsFile)
                    {
                        var radice = System.IO.Path.GetDirectoryName(_storage.Resolve("_"))!;
                        relativo = System.IO.Path.GetRelativePath(radice, url.LocalPath);
                    }
                    else if (_pubblico != null
                             && (url.Scheme == Uri.UriSchemeHttp || url.Scheme == Uri.UriSchemeHttps)
                             && string.Equals(url.Host, _pubblico.Host, StringComparison.OrdinalIgnoreCase))
                    {
                        relativo = Uri.UnescapeDataString(url.AbsolutePath).TrimStart('/');
                    }
                    else
                    {
                        return null;
                    }

                    // Resolve impedisce di uscire dalla radice del web server
                    var percorso = _storage.Resolve(relativo);
                    return File.Exists(percorso) ? File.ReadAllBytes(percorso) : null;
                }
                catch (MobileException)
                {
                    return null;
                }
            }
        }
    }
}
