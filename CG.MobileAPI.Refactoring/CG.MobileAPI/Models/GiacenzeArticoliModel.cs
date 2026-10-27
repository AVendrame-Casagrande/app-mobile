using System.Data.Odbc;
using System.Globalization;
using System.Net.Mail;
using System.Text.Json;
using System.Text.RegularExpressions;
using ClosedXML.Excel;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;

namespace CG.MobileAPI.Models
{
    // -----------------------------------------------------------------------------------------------------------------
    // --- Richieste ---------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Richiesta di addInfoCostoGiacenzaInventario.php.
    /// </summary>
    public class GiacArtAddInfoCostoGiacenzaInventarioRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
    }

    /// <summary>
    /// Richiesta di checkMagazzinoExists.php e checkMagazzinoExistsAndCheckVani.php.
    /// </summary>
    public class GiacArtCheckMagazzinoRequest
    {
        /// <summary>Codice magazzino.</summary>
        public string? magazzino { get; set; }
    }

    /// <summary>
    /// Richiesta di getInventarioFullQuery.php.
    /// </summary>
    public class GiacArtGetInventarioFullQueryRequest
    {
        /// <summary>Magazzino / vano della lista di inventario.</summary>
        public string? nome_lista { get; set; }

        /// <summary>Tipo di lista inventario: magazzino, vano_preciso o vano_radice.</summary>
        public string? tipo_lista { get; set; }

        /// <summary>Id della testata della lista (liste_testate).</summary>
        public string? id { get; set; }
    }

    /// <summary>
    /// Richiesta di getListaDistinte.php.
    /// </summary>
    public class GiacArtGetListaDistinteRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? codiceArticolo { get; set; }

        /// <summary>"esplosione" (componenti dell'assieme) o altro valore per l'implosione (assiemi che usano il componente).</summary>
        public string? tipoDistinta { get; set; }

        /// <summary>"true" per restituire solo i codici dei componenti.</summary>
        public string? solamenteCheckFigli { get; set; }
    }

    /// <summary>
    /// Richiesta di getMagazziniVaniPerModificaPrelievi.php.
    /// </summary>
    public class GiacArtGetMagazziniVaniPerModificaPrelieviRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? codiceArticolo { get; set; }

        /// <summary>Quantità del movimento: si restituiscono solo i vani con disponibile maggiore o uguale.</summary>
        public string? qtaMovimento { get; set; }
    }

    /// <summary>
    /// Richiesta di getMgricamVanoPreferenziale.php.
    /// </summary>
    public class GiacArtGetMgricamVanoPreferenzialeRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
    }

    /// <summary>
    /// Richiesta di getPdfList.php.
    /// </summary>
    public class GiacArtGetPdfListRequest
    {
        /// <summary>Codice articolo (usato per cercare il disegno e i PDF AO).</summary>
        public string? codiceArticolo { get; set; }

        /// <summary>Codice disegno (usato direttamente se <see cref="codiceDisegnoIsPreciso"/> è "true").</summary>
        public string? codiceDisegno { get; set; }

        /// <summary>"true" se il codice disegno è già quello giusto, altrimenti viene letto da DBSAITE.DIPRO.</summary>
        public string? codiceDisegnoIsPreciso { get; set; }
    }

    /// <summary>
    /// Richiesta di getVaniMovimentoSingolo.php.
    /// </summary>
    public class GiacArtGetVaniMovimentoSingoloRequest
    {
        /// <summary>Codice magazzino (gestito solo per i magazzini MISK*).</summary>
        public string? magazzino { get; set; }

        /// <summary>Società (non usata dal servizio, come nel PHP).</summary>
        public string? societa { get; set; }
    }

    /// <summary>
    /// Richiesta di selectArticoloLike.php.
    /// </summary>
    public class GiacArtSelectArticoloLikeRequest
    {
        /// <summary>Inizio del codice articolo o della descrizione.</summary>
        public string? inputArticoloDesc { get; set; }

        /// <summary>Società (default CSPRO).</summary>
        public string? societa { get; set; }
    }

    /// <summary>
    /// Richiesta di selectArticoloMagazzini.php.
    /// </summary>
    public class GiacArtSelectArticoloMagazziniRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? codiceArticolo { get; set; }

        /// <summary>Società (default CSPRO).</summary>
        public string? societa { get; set; }
    }

    /// <summary>
    /// Richiesta di selectGiacenzeInventario.php.
    /// </summary>
    public class GiacArtSelectGiacenzeInventarioRequest
    {
        /// <summary>Codice magazzino (cerca anche i vani che iniziano con questo codice).</summary>
        public string? magazzino { get; set; }
    }

    /// <summary>
    /// Richiesta di selectSingoloArticolo.php.
    /// </summary>
    public class GiacArtSelectSingoloArticoloRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? codiceArticolo { get; set; }

        /// <summary>Società (default CSPRO).</summary>
        public string? societa { get; set; }

        /// <summary>"true" per la scheda completa (note, ordini, impegni, prezzi, movimenti, foto, PDF...).</summary>
        public string? needCompleteInfo { get; set; }
    }

    /// <summary>
    /// Richiesta di updateRigaInventario.php.
    /// </summary>
    public class GiacArtUpdateRigaInventarioRequest
    {
        /// <summary>Id della riga (liste_righe.id).</summary>
        public string? id { get; set; }

        /// <summary>Campo da aggiornare: stato, stato_nota, qta, qta_originale, vano, url_foto, decisione,
        /// stato_movimento_decisione, update_movimento_automatico.</summary>
        public string? tipo_modifica { get; set; }

        /// <summary>Nuovo stato.</summary>
        public string? stato { get; set; }

        /// <summary>Quantità modificata.</summary>
        public string? qta_modificata { get; set; }

        /// <summary>Vano modificato.</summary>
        public string? vano_modificato { get; set; }

        /// <summary>Nome della foto.</summary>
        public string? url_foto { get; set; }

        /// <summary>Decisione.</summary>
        public string? decisione { get; set; }

        /// <summary>Stato del movimento di decisione.</summary>
        public string? stato_movimento_decisione { get; set; }

        /// <summary>Quantità originale.</summary>
        public string? qta_originale { get; set; }

        /// <summary>Nota (solo per tipo_modifica = stato_nota).</summary>
        public string? nota { get; set; }

        /// <summary>Esito del movimento automatico (solo per tipo_modifica = update_movimento_automatico).</summary>
        public string? stato_movimento_automatico { get; set; }
    }

    /// <summary>
    /// Upload di una foto (uploadFotoInventario.php, uploadFotoArxivar.php, csusa/upload_inventory_image.php).
    /// </summary>
    public class GiacArtUploadFotoRequest
    {
        /// <summary>La foto (jpg).</summary>
        public IFormFile? file { get; set; }

        /// <summary>Nome del file senza estensione (per ARXivar: il codice articolo).</summary>
        public string? name { get; set; }
    }

    /// <summary>
    /// Riga dell'excel di inventario CS USA (csusa/write_inventory_excel.php). I valori possono essere stringhe o numeri.
    /// </summary>
    public class GiacArtInventoryExcelRiga
    {
        /// <summary>Colonna A.</summary>
        public JsonElement? articolo { get; set; }
        /// <summary>Colonna B (con l'iniziale di ogni parola maiuscola).</summary>
        public JsonElement? descrizione { get; set; }
        /// <summary>Colonna C.</summary>
        public JsonElement? qta { get; set; }
        /// <summary>Colonna D.</summary>
        public JsonElement? note { get; set; }
        /// <summary>Colonna E.</summary>
        public JsonElement? image { get; set; }
        /// <summary>Colonna F.</summary>
        public JsonElement? user { get; set; }
        /// <summary>Colonna G.</summary>
        public JsonElement? data { get; set; }
        /// <summary>Colonna H.</summary>
        public JsonElement? ora { get; set; }
    }

    /// <summary>
    /// Richiesta di csusa/write_inventory_excel.php.
    /// </summary>
    public class GiacArtWriteInventoryExcelRequest
    {
        /// <summary>Righe dell'excel (nel PHP era una stringa JSON).</summary>
        public List<GiacArtInventoryExcelRiga>? csv { get; set; }

        /// <summary>Nome del file senza estensione.</summary>
        public string? filename { get; set; }
    }

    /// <summary>
    /// Richiesta di csusa/send_inventory_email.php.
    /// </summary>
    public class GiacArtSendInventoryEmailRequest
    {
        /// <summary>Indirizzo del destinatario.</summary>
        public string? emailTarget { get; set; }

        /// <summary>Nome del file excel senza estensione (generato da write_inventory_excel).</summary>
        public string? filename { get; set; }
    }

    // -----------------------------------------------------------------------------------------------------------------
    // --- Data class --------------------------------------------------------------------------------------------------
    // -----------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// Accesso ai dati per articoli, magazzini, vani e inventario.
    /// </summary>
    public class DBGIACENZE_ARTICOLI
    {
        // Cartelle relative alla radice del web server (StorageTool) e URL pubblici corrispondenti.
        private const string CARTELLA_FOTO_TECNICO = "applicazioni/tecnico/foto";
        private const string URL_FOTO_TECNICO = "http://app.casagrandegroup.local/applicazioni/tecnico/foto/";
        private const string CARTELLA_DISEGNI = "draw";
        private const string URL_DISEGNI = "http://app.casagrandegroup.local/draw/";
        private const string CARTELLA_AO_SCHEDA = "archive";
        private const string URL_AO_SCHEDA = "http://app.casagrandegroup.local/archive/";
        private const string CARTELLA_AO_PDF_LIST = "archivio_ao";
        private const string URL_AO_PDF_LIST = "http://app.casagrandegroup.local/archivio_ao/";
        private const string CARTELLA_D9 = "archiviod9";
        private const string URL_D9 = "http://app.casagrandegroup.local/archiviod9";
        private const string CARTELLA_INVENTARIO_FOTO = "mobile/server/storage/inventario_foto";
        private const string CARTELLA_ARXIVAR_TEMP = "mobile/server/storage/arxivar/temp";
        private const string CARTELLA_CSUSA_IMMAGINI = "mobile/server/storage/CSUSA/inventory_images";
        private const string CARTELLA_CSUSA_EXCEL = "mobile/server/storage/CSUSA/inventory_excel";

        // Classe documentale ARXivar delle foto ricambi (DM_PROFILE: DOCUMENTTYPE = 2, TIPO2 = 3, AOO CSG).
        private const int ARX_CLASSE_PADRE_FOTO = 2;
        private const int ARX_CLASSE_FOTO = 3;
        private const string ARX_SOCIETA = "CSG";

        private static readonly Regex _spaziMultipli = new(@"\s\s+");
        private static readonly Regex _numeroIniziale = new(@"^\s*[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?");
        private static readonly Regex _numeroCompleto = new(@"^\s*[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\s*$");

        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBGIACENZE_ARTICOLI"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBGIACENZE_ARTICOLI(MobileConnections conn)
        {
            _conn = conn;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Magazzini / vani ----------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Ultimo costo CATT dell'articolo da MVSACPE (ex addInfoCostoGiacenzaInventario.php). 0 se non trovato.
        /// </summary>
        public double AddInfoCostoGiacenzaInventario(GiacArtAddInfoCostoGiacenzaInventarioRequest req)
        {
            var costo = DbHelper.Scalar(_conn.Db2,
                @"SELECT D60STDDB.MVSACPE.COSTUN*0.0001 AS COSTO FROM D60STDDB.MVSACPE
                  WHERE D60STDDB.MVSACPE.CODITM=? AND D60STDDB.MVSACPE.CODCOS='CATT' AND CODSOC='CSPRO'
                  ORDER BY D60STDDB.MVSACPE.DTPERI DESC, D60STDDB.MVSACPE.DTVALI DESC LIMIT 1",
                req.articolo ?? "");
            return PhpFloat(costo);
        }

        /// <summary>
        /// Indica se il magazzino esiste in MASAHED per CSPRO (ex checkMagazzinoExists.php).
        /// </summary>
        public bool CheckMagazzinoExists(GiacArtCheckMagazzinoRequest req)
        {
            return EsisteMagazzino(Obbligatorio(req.magazzino, "magazzino"));
        }

        /// <summary>
        /// Indica se il magazzino esiste e se ha vani (MGRICAM escluso) (ex checkMagazzinoExistsAndCheckVani.php).
        /// Chiavi: magazzinoFound, magazzino_has_vani.
        /// </summary>
        public Dictionary<string, object?> CheckMagazzinoExistsAndCheckVani(GiacArtCheckMagazzinoRequest req)
        {
            var magazzino = Obbligatorio(req.magazzino, "magazzino");

            var haVani = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.MASAHLO.MLHLOC
                  FROM D60STDDB.MASAHLO WHERE MAHMAG=? AND MAHMAG!= 'MGRICAM' LIMIT 1",
                magazzino).Count > 0;

            return new Dictionary<string, object?>
            {
                ["magazzinoFound"] = EsisteMagazzino(magazzino),
                ["magazzino_has_vani"] = haVani
            };
        }

        /// <summary>
        /// Magazzini e vani dell'articolo con disponibile sufficiente per il movimento
        /// (ex getMagazziniVaniPerModificaPrelievi.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetMagazziniVaniPerModificaPrelievi(GiacArtGetMagazziniVaniPerModificaPrelieviRequest req)
        {
            var rows = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALOHQT/100 AS GIACENTE, D60STDDB.MASAMSL.MALLLQT/100 AS IMPEGNATO
                  FROM D60STDDB.MASAMSL
                  FULL JOIN D60STDDB.DBSAITE ON D60STDDB.DBSAITE.MITEM = D60STDDB.MASAMSL.MALITEM AND D60STDDB.DBSAITE.MCOSC = D60STDDB.MASAMSL.MAHCOSC
                  WHERE D60STDDB.DBSAITE.MITEM=?
                  AND D60STDDB.MASAMSL.MLLOC NOT LIKE 'MEF%'
                  AND D60STDDB.MASAMSL.MLLOC NOT LIKE 'MC%'
                  AND D60STDDB.MASAMSL.MLLOC NOT LIKE 'MN%'
                  AND D60STDDB.MASAMSL.MLLOC NOT LIKE 'MGFURG%'
                  AND D60STDDB.MASAMSL.MAHCOSC='CSPRO'
                  GROUP BY D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALOHQT, D60STDDB.MASAMSL.MALLLQT
                  ORDER BY D60STDDB.MASAMSL.MLLOC,D60STDDB.MASAMSL.MALLOC",
                req.codiceArticolo ?? "");

            var lista = new List<Dictionary<string, object?>>();
            foreach (var r in rows)
            {
                var giacente = F(r, "GIACENTE");
                var impegnato = F(r, "IMPEGNATO");
                if (PhpMaggioreUguale(giacente - impegnato, req.qtaMovimento))
                {
                    lista.Add(new Dictionary<string, object?>
                    {
                        ["magazzino"] = S(r, "MLLOC"),
                        ["vano"] = S(r, "MALLOC"),
                        ["giacente"] = giacente,
                        ["impegnato"] = impegnato
                    });
                }
            }
            return lista;
        }

        /// <summary>
        /// Vano preferenziale dell'articolo su MGRICAM, stringa vuota se assente (ex getMgricamVanoPreferenziale.php).
        /// </summary>
        public string GetMgricamVanoPreferenziale(GiacArtGetMgricamVanoPreferenzialeRequest req)
        {
            var vano = DbHelper.Scalar(_conn.Db2,
                @"SELECT D60STDDB.MASAVAN.MVCELLA
                  FROM D60STDDB.MASAVAN
                  WHERE D60STDDB.MASAVAN.MVLOC='MGRICAM' AND D60STDDB.MASAVAN.MVVCOSC='CSPRO' AND D60STDDB.MASAVAN.MVFIRST = '*'
                  AND D60STDDB.MASAVAN.MVVITEM=? LIMIT 1",
                req.articolo ?? "");
            return (vano ?? "").Trim();
        }

        /// <summary>
        /// Sezioni dei vani (scaffale, colonna, ripiano, posizione) di un magazzino MISK per il selettore a rotella
        /// (ex getVaniMovimentoSingolo.php). Chiavi: exists, sezione_1..sezione_4.
        /// </summary>
        public Dictionary<string, object?> GetVaniMovimentoSingolo(GiacArtGetVaniMovimentoSingoloRequest req)
        {
            var magazzino = req.magazzino ?? "";
            var vani = new Dictionary<string, object?>
            {
                ["exists"] = false,
                ["sezione_1"] = new List<string>(),
                ["sezione_2"] = new List<string>(),
                ["sezione_3"] = new List<string>(),
                ["sezione_4"] = new List<string>()
            };

            if (!magazzino.StartsWith("MISK", StringComparison.Ordinal))
            {
                return vani;
            }
            vani["exists"] = true;

            // (posizione, lunghezza) della sezione nel codice vano; le prime tre devono essere numeriche > 0.
            var sezioni = new (int inizio, int lunghezza, bool soloNumeriche)[] { (1, 3, true), (4, 2, true), (6, 2, true), (8, 1, false) };
            for (int i = 0; i < sezioni.Length; i++)
            {
                var (inizio, lunghezza, soloNumeriche) = sezioni[i];
                var rows = DbHelper.Query(_conn.Db2,
                    $@"SELECT DISTINCT SUBSTR(D60STDDB.MASAHLO.MLHLOC,{inizio},{lunghezza}) AS SEZIONE
                       FROM D60STDDB.MASAHLO
                       WHERE D60STDDB.MASAHLO.MAHMAG = ?
                       GROUP BY D60STDDB.MASAHLO.MLHLOC",
                    magazzino);

                var lista = (List<string>)vani["sezione_" + (i + 1)]!;
                foreach (var r in rows)
                {
                    var sezione = S(r, "SEZIONE");
                    if (!soloNumeriche || PhpInt(sezione) > 0)
                    {
                        lista.Add(sezione);
                    }
                }
            }
            return vani;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Inventario ----------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Righe della lista di inventario (DB_1.liste_righe) e giacenze del magazzino / vano
        /// (ex getInventarioFullQuery.php). Chiavi: listaRighe, listaGiacenze.
        /// </summary>
        public Dictionary<string, object?> GetInventarioFullQuery(GiacArtGetInventarioFullQueryRequest req)
        {
            if (!int.TryParse((req.id ?? "").Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var id))
            {
                throw new MobileException("id non valido");
            }

            var righe = DbHelper.Query(_conn.PgDb1,
                "select * from liste_righe where id_lista_testata=? order by articolo,data_inserimento desc, ora_inserimento desc",
                id);

            return new Dictionary<string, object?>
            {
                ["listaRighe"] = righe,
                ["listaGiacenze"] = GetListaGiacenze(req.nome_lista ?? "", "inventario", req.tipo_lista)
            };
        }

        /// <summary>
        /// Giacenze del magazzino (o dei vani che iniziano con il codice) (ex selectGiacenzeInventario.php).
        /// </summary>
        public List<Dictionary<string, object?>> SelectGiacenzeInventario(GiacArtSelectGiacenzeInventarioRequest req)
        {
            return GetListaGiacenze(req.magazzino ?? "", "giacenze", null);
        }

        /// <summary>
        /// Aggiorna un campo di una riga di inventario in DB_1.liste_righe (ex updateRigaInventario.php).
        /// Restituisce "updated", oppure "error" se il tipo di modifica non è previsto o l'UPDATE fallisce.
        /// </summary>
        public string UpdateRigaInventario(GiacArtUpdateRigaInventarioRequest req)
        {
            var id = PhpInt(req.id);
            var stato = PhpInt(req.stato);

            // Le colonne sono scelte da una whitelist (tipo_modifica), i valori sono sempre parametri.
            string set;
            var valori = new List<object?>();
            switch (req.tipo_modifica)
            {
                case "stato":
                    set = "stato=?,decisione=0";
                    valori.Add(stato);
                    break;
                case "stato_nota":
                    set = "stato=?,decisione=0,nota=?";
                    valori.Add(stato);
                    valori.Add(req.nota ?? "");
                    break;
                case "qta":
                    set = "qta_modificata=?";
                    valori.Add(PhpFloat(req.qta_modificata));
                    break;
                case "qta_originale":
                    set = "qta_originale=?";
                    valori.Add(PhpInt(req.qta_originale));
                    break;
                case "vano":
                    set = "vano_modificato=?";
                    valori.Add(req.vano_modificato ?? "");
                    break;
                case "url_foto":
                    set = "url_foto=?";
                    valori.Add(req.url_foto ?? "");
                    break;
                case "decisione":
                    set = "decisione=?";
                    valori.Add(PhpInt(req.decisione));
                    break;
                case "stato_movimento_decisione":
                    set = "stato_movimento_decisione=?";
                    valori.Add(req.stato_movimento_decisione ?? "");
                    break;
                case "update_movimento_automatico":
                    set = "stato=?,stato_movimento_automatico=?";
                    valori.Add(stato);
                    valori.Add((req.stato_movimento_automatico ?? "").Replace("'", "`"));
                    break;
                default:
                    return "error";
            }

            var adesso = DateTime.Now;
            valori.Add(int.Parse(adesso.ToString("yyyyMMdd", CultureInfo.InvariantCulture), CultureInfo.InvariantCulture));
            valori.Add(int.Parse(adesso.ToString("HHmmss", CultureInfo.InvariantCulture), CultureInfo.InvariantCulture));
            valori.Add(id);

            try
            {
                DbHelper.NonQuery(_conn.PgDb1,
                    $"update public.liste_righe set {set}, data_inserimento=?, ora_inserimento=? WHERE id=?",
                    valori.ToArray());
                return "updated";
            }
            catch (OdbcException)
            {
                return "error";
            }
        }

        /// <summary>
        /// Salva la foto di una riga di inventario in storage/inventario_foto (ex uploadFotoInventario.php).
        /// Restituisce "uploaded" o "error".
        /// </summary>
        public async Task<string> UploadFotoInventarioAsync(GiacArtUploadFotoRequest req, StorageTool storage)
        {
            var nome = Obbligatorio(req.name, "name").Replace("/", "-").Replace("*", "-");
            return await storage.SalvaAsync(req.file, CARTELLA_INVENTARIO_FOTO, nome + ".jpg", StorageTool.Immagini)
                ? "uploaded"
                : "error";
        }

        /// <summary>
        /// Archivia in ARXivar la foto di un articolo come documento "Fotografia" della classe foto ricambi
        /// (ex uploadFotoArxivar.php, che la depositava via FTP nella cartella di import di ARXivar).
        /// Restituisce "uploaded" o "error"; stringa vuota se non è stato possibile salvare il file temporaneo.
        /// </summary>
        public async Task<string> UploadFotoArxivarAsync(GiacArtUploadFotoRequest req, StorageTool storage)
        {
            var nome = Obbligatorio(req.name, "name");
            var nomeFile = StorageTool.NomeSicuro(nome + ".jpg");

            if (!await storage.SalvaAsync(req.file, CARTELLA_ARXIVAR_TEMP, nomeFile, StorageTool.Immagini))
            {
                return "";
            }

            try
            {
                var content = new Dictionary<string, JsonElement>
                {
                    ["idDocFather"] = JsonSerializer.SerializeToElement(ARX_CLASSE_PADRE_FOTO),
                    ["idDoc"] = JsonSerializer.SerializeToElement(ARX_CLASSE_FOTO),
                    ["stateValue"] = JsonSerializer.SerializeToElement("VALID"),
                    ["isDocument"] = JsonSerializer.SerializeToElement("N"),
                    ["docFields"] = JsonSerializer.SerializeToElement(new[]
                    {
                        new Dictionary<string, string> { ["nameField"] = "COMBO6_3", ["typeField"] = "COMBO", ["valueField"] = "Fotografia" },
                        new Dictionary<string, string> { ["nameField"] = "TABLE1_3", ["typeField"] = "TABLE", ["valueField"] = nome.Replace("/", "-") }
                    })
                };

                var docNumber = ArxHelper.SendFileToArx(storage.Resolve(CARTELLA_ARXIVAR_TEMP, nomeFile), content);
                return string.IsNullOrEmpty(docNumber) ? "error" : "uploaded";
            }
            finally
            {
                storage.Elimina(CARTELLA_ARXIVAR_TEMP, nomeFile);
            }
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Inventario CS USA ---------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Salva la foto di inventario CS USA in storage/CSUSA/inventory_images (ex csusa/upload_inventory_image.php).
        /// Restituisce "uploaded" o "error".
        /// </summary>
        public async Task<string> UploadInventoryImageAsync(GiacArtUploadFotoRequest req, StorageTool storage)
        {
            var nome = Obbligatorio(req.name, "name").Replace("/", "-").Replace("*", "-").Replace("\"", "_");
            return await storage.SalvaAsync(req.file, CARTELLA_CSUSA_IMMAGINI, nome + ".jpg", StorageTool.Immagini)
                ? "uploaded"
                : "error";
        }

        /// <summary>
        /// Crea l'excel di inventario CS USA in storage/CSUSA/inventory_excel (ex csusa/write_inventory_excel.php,
        /// PhpSpreadsheet → ClosedXML). La riga 2 è l'intestazione. Restituisce il nome del file (senza estensione).
        /// </summary>
        public async Task<string> WriteInventoryExcelAsync(GiacArtWriteInventoryExcelRequest req, StorageTool storage)
        {
            var filename = Obbligatorio(req.filename, "filename");
            var nomeFile = StorageTool.NomeSicuro(filename + ".xlsx");
            var righe = req.csv ?? new List<GiacArtInventoryExcelRiga>();

            using var workbook = new XLWorkbook();
            var sheet = workbook.Worksheets.Add("Worksheet");

            for (int i = 0; i < righe.Count; i++)
            {
                var riga = righe[i];
                var numeroRiga = i + 1;
                var intestazione = numeroRiga == 2;

                ScriviCella(sheet.Cell("A" + numeroRiga), riga.articolo, false, intestazione);
                ScriviCella(sheet.Cell("B" + numeroRiga), riga.descrizione, true, intestazione);
                ScriviCella(sheet.Cell("C" + numeroRiga), riga.qta, false, intestazione);
                ScriviCella(sheet.Cell("D" + numeroRiga), riga.note, false, intestazione);
                ScriviCella(sheet.Cell("E" + numeroRiga), riga.image, false, intestazione);
                ScriviCella(sheet.Cell("F" + numeroRiga), riga.user, false, intestazione);
                ScriviCella(sheet.Cell("G" + numeroRiga), riga.data, false, intestazione);
                ScriviCella(sheet.Cell("H" + numeroRiga), riga.ora, false, intestazione);
            }

            sheet.Columns("A:H").AdjustToContents();

            using var ms = new MemoryStream();
            workbook.SaveAs(ms);
            await storage.SalvaBytesAsync(ms.ToArray(), CARTELLA_CSUSA_EXCEL, nomeFile);

            return filename;
        }

        /// <summary>
        /// Invia per email l'excel di inventario CS USA (ex csusa/send_inventory_email.php, PHPMailer → EmailTool).
        /// Restituisce "1" se inviata, altrimenti "Mailer Error: ..." come il PHP.
        /// </summary>
        public async Task<string> SendInventoryEmailAsync(GiacArtSendInventoryEmailRequest req, StorageTool storage, EmailTool email)
        {
            var destinatario = Obbligatorio(req.emailTarget, "emailTarget");
            var nomeFile = StorageTool.NomeSicuro(Obbligatorio(req.filename, "filename") + ".xlsx");

            // Come PHPMailer: se l'allegato non esiste la mail parte comunque senza allegato.
            var allegati = new List<(string nome, byte[] contenuto)>();
            if (storage.Esiste(CARTELLA_CSUSA_EXCEL, nomeFile))
            {
                allegati.Add((nomeFile, await storage.LeggiAsync(CARTELLA_CSUSA_EXCEL, nomeFile)));
            }

            try
            {
                await email.InviaAsync(new[] { destinatario }, "Inventory Excel", "See attachment", allegati);
                return "1";
            }
            catch (Exception ex) when (ex is SmtpException || ex is FormatException)
            {
                return "Mailer Error: " + ex.Message;
            }
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Articoli ------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Ricerca articoli per inizio codice (o codice contenuto per i fantasma 'D'), altrimenti per inizio descrizione
        /// (ex selectArticoloLike.php). Elementi: codice, descrizione.
        /// </summary>
        public List<Dictionary<string, object?>> SelectArticoloLike(GiacArtSelectArticoloLikeRequest req)
        {
            var input = (req.inputArticoloDesc ?? "").ToUpperInvariant();
            var societa = req.societa ?? "CSPRO";
            var inputSenzaPrimo = input.StartsWith('2') ? input.Substring(1) : input;

            var rows = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.DBSAITE.MITEM, D60STDDB.DBSAITE.MPDSC, D60STDDB.DBSAITE.MCOSC
                  FROM D60STDDB.DBSAITE
                  FULL JOIN D60STDDB.MASAINV ON (D60STDDB.MASAINV.MALITEM = D60STDDB.DBSAITE.MITEM) AND (D60STDDB.MASAINV.MAHCOSC = D60STDDB.DBSAITE.MCOSC)
                  WHERE (D60STDDB.DBSAITE.MITEM LIKE ? OR (D60STDDB.DBSAITE.MITEM LIKE ? AND D60STDDB.DBSAITE.MTYPN = 'D' )) AND D60STDDB.MASAINV.MAHCOSC=?",
                input + "%", "%" + inputSenzaPrimo + "%", societa);

            if (rows.Count == 0)
            {
                rows = DbHelper.Query(_conn.Db2,
                    @"SELECT D60STDDB.DBSAITE.MITEM, D60STDDB.DBSAITE.MPDSC, D60STDDB.DBSAITE.MCOSC
                      FROM D60STDDB.DBSAITE
                      FULL JOIN D60STDDB.MASAINV ON (D60STDDB.MASAINV.MALITEM = D60STDDB.DBSAITE.MITEM) AND (D60STDDB.MASAINV.MAHCOSC = D60STDDB.DBSAITE.MCOSC)
                      WHERE D60STDDB.DBSAITE.MPDSC LIKE ? AND D60STDDB.MASAINV.MAHCOSC=?",
                    input + "%", societa);
            }

            return rows.Select(r => new Dictionary<string, object?>
            {
                ["codice"] = S(r, "MITEM"),
                ["descrizione"] = S(r, "MPDSC")
            }).ToList();
        }

        /// <summary>
        /// Dati dell'articolo per i movimenti: magazzini con giacenza, magazzini possibili, magazzini preferenziali,
        /// mancanti e possibili ODL (ex selectArticoloMagazzini.php).
        /// </summary>
        public Dictionary<string, object?> SelectArticoloMagazzini(GiacArtSelectArticoloMagazziniRequest req)
        {
            var codiceArticolo = req.codiceArticolo ?? "";
            var societa = req.societa ?? "CSPRO";

            // Se l'articolo non esiste il PHP restituiva un oggetto con le sole liste.
            var movimento = new Dictionary<string, object?>();
            var articolo = DbHelper.QueryFirst(_conn.Db2,
                @"SELECT D60STDDB.DBSAITE.MITEM, D60STDDB.DBSAITE.MPDSC, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAITE.MPALLET,
                  D60STDDB.CSDBITA.CSCOLOR
                  FROM D60STDDB.DBSAITE
                  FULL JOIN D60STDDB.MASAINV ON (D60STDDB.MASAINV.MALITEM = D60STDDB.DBSAITE.MITEM) AND (D60STDDB.MASAINV.MAHCOSC = D60STDDB.DBSAITE.MCOSC)
                  FULL JOIN D60STDDB.CSDBITA ON D60STDDB.DBSAITE.MITEM = D60STDDB.CSDBITA.CSITEMA
                  WHERE D60STDDB.DBSAITE.MITEM=? AND D60STDDB.MASAINV.MAHCOSC=?",
                codiceArticolo, societa);
            if (articolo != null)
            {
                movimento["articolo_id"] = S(articolo, "MITEM");
                movimento["descrizioneArticolo"] = SenzaSpaziMultipli(S(articolo, "MPDSC"));
                movimento["unitaMisura"] = S(articolo, "MUTMS");
                movimento["pesoLordoBackup"] = F(articolo, "MPALLET") / 100;
                movimento["colore"] = S(articolo, "CSCOLOR");
            }

            movimento["listaMagazziniArticolo"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALOHQT/100 AS GIACENTE, D60STDDB.MASAMSL.MALLLQT/100 AS IMPEGNATO
                  FROM D60STDDB.DBSAITE
                  FULL JOIN D60STDDB.MASAMSL ON D60STDDB.DBSAITE.MITEM = D60STDDB.MASAMSL.MALITEM
                  FULL JOIN D60STDDB.MASAHED ON D60STDDB.MASAMSL.MLLOC = D60STDDB.MASAHED.MAHMAG
                  WHERE D60STDDB.DBSAITE.MITEM=?
                  AND D60STDDB.MASAMSL.MAHCOSC=?
                  AND D60STDDB.MASAHED.MAHTYMAG='ST'
                  AND D60STDDB.MASAHED.MAHMAG NOT LIKE 'MGAUT%'
                  GROUP BY D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALOHQT, D60STDDB.MASAMSL.MALLLQT ORDER BY D60STDDB.MASAMSL.MLLOC",
                codiceArticolo, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["codice"] = S(r, "MLLOC"),
                    ["vano"] = S(r, "MALLOC"),
                    ["giacente"] = F(r, "GIACENTE"),
                    ["impegnato"] = F(r, "IMPEGNATO")
                }).ToList();

            movimento["listaPossibiliMagazzini"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.MASAHED.MAHMAG
                  FROM D60STDDB.MASAHED
                  WHERE D60STDDB.MASAHED.MAHCOSC=?
                  AND D60STDDB.MASAHED.MAHTYMAG='ST'
                  AND D60STDDB.MASAHED.MAHMAG NOT LIKE 'MGAUT%'
                  ORDER BY D60STDDB.MASAHED.MAHMAG",
                societa)
                .Select(r => new Dictionary<string, object?> { ["codice"] = S(r, "MAHMAG") }).ToList();

            movimento["listaMagazziniPreferenziali"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.MASAHED.MAHMAG, D60STDDB.MASAHED.MAHTYMAG,
                  D60STDDB.MASAVAN.MVCELLA, D60STDDB.MASAVAN.MVVITEM
                  FROM D60STDDB.MASAHED
                  FULL JOIN D60STDDB.MASAVAN ON D60STDDB.MASAHED.MAHMAG = D60STDDB.MASAVAN.MVLOC
                  WHERE D60STDDB.MASAHED.MAHCOSC=?
                  AND D60STDDB.MASAHED.MAHTYMAG='ST'
                  AND D60STDDB.MASAHED.MAHMAG NOT LIKE 'MGAUT%'
                  AND D60STDDB.MASAVAN.MVFIRST = '*'
                  AND D60STDDB.MASAVAN.MVVITEM=?",
                societa, codiceArticolo)
                .Select(r => new Dictionary<string, object?>
                {
                    ["codice"] = S(r, "MAHMAG"),
                    ["vano"] = S(r, "MVCELLA")
                }).ToList();

            var mancanti = DbHelper.Query(_conn.PgCasagrande,
                @"SELECT cs_fabbmanc_odl_comp.numero AS ODL, cs_fabbmanc_odl_comp.magazzino AS mag, cs_fabbmanc_odl_comp.qtares, cs_fabbmanc_odl_comp.giacmag AS trasf, cs_fabbmanc_odl_comp.giacdispo AS da_trasf, cs_fabbmanc_odl_comp.giacdispoext,
                  cs_fabbmanc_odl.articolo as codicepadre, cs_fabbmanc_odl.descarticolo as descpadre, cs_fabbmanc_odl.desccolore, cs_fabbmanc_odl_comp.fase, cs_fabbmanc_odl_comp.pesol
                  FROM cs_fabbmanc_odl
                  FULL JOIN cs_fabbmanc_odl_comp ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero) AND (cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa)
                  WHERE (((cs_fabbmanc_odl_comp.articolo)=?) AND ((cs_fabbmanc_odl_comp.societa)=?))",
                codiceArticolo, societa);

            var listaPossibiliOdl = new List<Dictionary<string, object?>>();
            var listaMancanti = new List<Dictionary<string, object?>>();
            foreach (var m in mancanti)
            {
                listaMancanti.Add(new Dictionary<string, object?>
                {
                    ["odl"] = V(m, "odl"),
                    ["fase"] = V(m, "fase"),
                    ["codicePadre"] = V(m, "codicepadre"),
                    ["descrizionePadre"] = V(m, "descpadre"),
                    ["pesoLordo"] = F(m, "pesol"),
                    ["descrizioneColore"] = V(m, "desccolore") ?? ""
                });

                // Solo se NON è 'verde' nella lista mancanti: possibile ODL.
                if (!PhpUgualeLasco(V(m, "qtares"), V(m, "trasf")))
                {
                    listaPossibiliOdl.Add(new Dictionary<string, object?>
                    {
                        ["odl"] = V(m, "odl"),
                        ["mag"] = V(m, "mag")
                    });
                }
            }
            movimento["listaPossibiliOdl"] = listaPossibiliOdl;
            movimento["listaMancanti"] = listaMancanti;

            return movimento;
        }

        /// <summary>
        /// Componenti (esplosione) o assiemi (implosione) validi oggi per l'articolo (ex getListaDistinte.php).
        /// Con solamenteCheckFigli = true restituisce solo { componente }.
        /// </summary>
        public List<Dictionary<string, object?>> GetListaDistinte(GiacArtGetListaDistinteRequest req)
        {
            var codiceArticolo = req.codiceArticolo ?? "";
            var oggi = int.Parse(DateTime.Now.ToString("yyyyMMdd", CultureInfo.InvariantCulture), CultureInfo.InvariantCulture);
            var esplosione = req.tipoDistinta == "esplosione";

            if (JsonVero(req.solamenteCheckFigli))
            {
                var sqlFigli = esplosione
                    ? @"SELECT D60STDDB.DBSAPRD.SPCOMP AS COMPONENTE
                        FROM D60STDDB.DBSAITE AS DBSAITE_1
                        INNER JOIN (D60STDDB.DBSAPRD INNER JOIN D60STDDB.DBSAITE ON (D60STDDB.DBSAPRD.SPCOMP = D60STDDB.DBSAITE.MITEM) AND (D60STDDB.DBSAPRD.MCOSC = D60STDDB.DBSAITE.MCOSC)) ON (DBSAITE_1.MCOSC = D60STDDB.DBSAPRD.MCOSC) AND (DBSAITE_1.MITEM = D60STDDB.DBSAPRD.MITEM)
                        GROUP BY D60STDDB.DBSAPRD.MITEM, DBSAITE_1.MPDSC, D60STDDB.DBSAPRD.SPSQNO, D60STDDB.DBSAPRD.SPCOMP, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAPRD.SPQTY, D60STDDB.DBSAPRD.SPADDDT, D60STDDB.DBSAPRD.SPDELDT, D60STDDB.DBSAITE.MPDSC, D60STDDB.DBSAITE.DIPRO
                        HAVING (D60STDDB.DBSAPRD.SPADDDT<= ? AND D60STDDB.DBSAPRD.SPDELDT>? AND D60STDDB.DBSAPRD.MITEM = ?)
                        OR (D60STDDB.DBSAPRD.SPADDDT<= ? AND D60STDDB.DBSAPRD.SPDELDT=0 AND D60STDDB.DBSAPRD.MITEM = ?)"
                    : @"SELECT D60STDDB.DBSAPRD.SPCOMP AS COMPONENTE
                        FROM D60STDDB.DBSAPRD
                        INNER JOIN D60STDDB.DBSAITE ON D60STDDB.DBSAPRD.SPCOMP = D60STDDB.DBSAITE.MITEM AND D60STDDB.DBSAPRD.MCOSC = D60STDDB.DBSAITE.MCOSC
                        INNER JOIN D60STDDB.DBSAITE AS DBSAITE_1 ON DBSAITE_1.MCOSC = D60STDDB.DBSAPRD.MCOSC AND D60STDDB.DBSAPRD.MITEM = DBSAITE_1.MITEM
                        GROUP BY D60STDDB.DBSAPRD.MITEM, DBSAITE_1.MPDSC, D60STDDB.DBSAPRD.SPSQNO, D60STDDB.DBSAPRD.SPCOMP, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAPRD.SPQTY, D60STDDB.DBSAPRD.SPADDDT, D60STDDB.DBSAPRD.SPDELDT, D60STDDB.DBSAITE.MPDSC, D60STDDB.DBSAITE.DIPRO
                        HAVING (D60STDDB.DBSAPRD.SPCOMP=? AND D60STDDB.DBSAPRD.SPADDDT<=? AND D60STDDB.DBSAPRD.SPDELDT>?)
                        OR (D60STDDB.DBSAPRD.SPCOMP=? AND D60STDDB.DBSAPRD.SPADDDT<=? AND D60STDDB.DBSAPRD.SPDELDT=0)";

                var valoriFigli = esplosione
                    ? new object?[] { oggi, oggi, codiceArticolo, oggi, codiceArticolo }
                    : new object?[] { codiceArticolo, oggi, oggi, codiceArticolo, oggi };

                return DbHelper.Query(_conn.Db2, sqlFigli, valoriFigli)
                    .Select(r => new Dictionary<string, object?> { ["componente"] = S(r, "COMPONENTE") })
                    .ToList();
            }

            var sql = esplosione
                ? @"SELECT D60STDDB.DBSAPRD.MITEM AS ASSIEME, DBSAITE_1.MPDSC, D60STDDB.DBSAPRD.SPSQNO AS POS, D60STDDB.DBSAPRD.SPCOMP AS COMPONENTE, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAPRD.SPQTY AS QUANTITA, D60STDDB.DBSAITE.MPDSC AS DESCRIZIONE, D60STDDB.DBSAITE.DIPRO AS DISEGNO,
                    COALESCE(MAX(D60STDDB.DBSAMTA.NUMESP), 0) AS EM
                    FROM D60STDDB.DBSAITE AS DBSAITE_1
                    INNER JOIN (D60STDDB.DBSAPRD INNER JOIN D60STDDB.DBSAITE ON (D60STDDB.DBSAPRD.SPCOMP = D60STDDB.DBSAITE.MITEM) AND (D60STDDB.DBSAPRD.MCOSC = D60STDDB.DBSAITE.MCOSC)) ON (DBSAITE_1.MCOSC = D60STDDB.DBSAPRD.MCOSC) AND (DBSAITE_1.MITEM = D60STDDB.DBSAPRD.MITEM)
                    LEFT JOIN D60STDDB.DBSAMTA ON D60STDDB.DBSAPRD.SPCOMP = D60STDDB.DBSAMTA.CODITM
                    GROUP BY D60STDDB.DBSAPRD.MITEM, DBSAITE_1.MPDSC, D60STDDB.DBSAPRD.SPSQNO, D60STDDB.DBSAPRD.SPCOMP, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAPRD.SPQTY, D60STDDB.DBSAPRD.SPADDDT, D60STDDB.DBSAPRD.SPDELDT, D60STDDB.DBSAITE.MPDSC, D60STDDB.DBSAITE.DIPRO, D60STDDB.DBSAPRD.SPMATCH
                    HAVING (D60STDDB.DBSAPRD.SPADDDT<= ? AND D60STDDB.DBSAPRD.SPDELDT>? AND D60STDDB.DBSAPRD.MITEM = ?)
                    OR (D60STDDB.DBSAPRD.SPADDDT<= ? AND D60STDDB.DBSAPRD.SPDELDT=0 AND D60STDDB.DBSAPRD.MITEM = ?)
                    ORDER BY D60STDDB.DBSAPRD.SPSQNO, D60STDDB.DBSAPRD.SPCOMP ASC"
                : @"SELECT D60STDDB.DBSAPRD.MITEM AS ASSIEME, DBSAITE_1.MPDSC, D60STDDB.DBSAPRD.SPSQNO AS POS, D60STDDB.DBSAPRD.SPCOMP AS COMPONENTE, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAPRD.SPQTY AS QUANTITA, D60STDDB.DBSAITE.MPDSC AS DESCRIZIONE, DBSAITE_1.DIPRO AS DISEGNO,
                    COALESCE(MAX(D60STDDB.DBSAMTA.NUMESP), 0) AS EM
                    FROM D60STDDB.DBSAPRD
                    INNER JOIN D60STDDB.DBSAITE ON D60STDDB.DBSAPRD.SPCOMP = D60STDDB.DBSAITE.MITEM AND D60STDDB.DBSAPRD.MCOSC = D60STDDB.DBSAITE.MCOSC
                    INNER JOIN D60STDDB.DBSAITE AS DBSAITE_1 ON DBSAITE_1.MCOSC = D60STDDB.DBSAPRD.MCOSC AND D60STDDB.DBSAPRD.MITEM = DBSAITE_1.MITEM
                    LEFT JOIN D60STDDB.DBSAMTA ON D60STDDB.DBSAPRD.MITEM = D60STDDB.DBSAMTA.CODITM
                    GROUP BY D60STDDB.DBSAPRD.MITEM, DBSAITE_1.DIPRO, DBSAITE_1.MPDSC, D60STDDB.DBSAPRD.SPSQNO, D60STDDB.DBSAPRD.SPCOMP, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAPRD.SPQTY, D60STDDB.DBSAPRD.SPADDDT, D60STDDB.DBSAPRD.SPDELDT, D60STDDB.DBSAITE.MPDSC, D60STDDB.DBSAPRD.SPMATCH
                    HAVING (D60STDDB.DBSAPRD.SPCOMP=? AND D60STDDB.DBSAPRD.SPADDDT<=? AND D60STDDB.DBSAPRD.SPDELDT>?)
                    OR (D60STDDB.DBSAPRD.SPCOMP=? AND D60STDDB.DBSAPRD.SPADDDT<=? AND D60STDDB.DBSAPRD.SPDELDT=0)
                    ORDER BY D60STDDB.DBSAPRD.SPSQNO, D60STDDB.DBSAPRD.MITEM ASC";

            var valori = esplosione
                ? new object?[] { oggi, oggi, codiceArticolo, oggi, codiceArticolo }
                : new object?[] { codiceArticolo, oggi, oggi, codiceArticolo, oggi };

            return DbHelper.Query(_conn.Db2, sql, valori)
                .Select(r => new Dictionary<string, object?>
                {
                    ["assieme"] = S(r, "ASSIEME"),
                    ["descrizioneAssieme"] = SenzaSpaziMultipli(S(r, "MPDSC")),
                    ["componente"] = S(r, "COMPONENTE"),
                    ["descrizioneComponente"] = SenzaSpaziMultipli(S(r, "DESCRIZIONE")),
                    ["pos"] = S(r, "POS"),
                    ["mutms"] = S(r, "MUTMS"),
                    ["qta"] = F(r, "QUANTITA"),
                    ["disegno"] = S(r, "DISEGNO"),
                    // Come nel PHP: stringa per l'esplosione, intero per l'implosione.
                    ["em"] = esplosione ? S(r, "EM") : PhpInt(S(r, "EM"))
                }).ToList();
        }

        /// <summary>
        /// Elenco dei PDF del disegno (archivio disegni) e dell'ultimo PDF AO dell'articolo (ex getPdfList.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetPdfList(GiacArtGetPdfListRequest req, StorageTool storage)
        {
            var codiceArticolo = req.codiceArticolo ?? "";
            var codiceDisegno = req.codiceDisegno;

            // Senza un codice disegno preciso lo si legge dall'anagrafica articolo.
            if (!JsonVero(req.codiceDisegnoIsPreciso))
            {
                var row = DbHelper.QueryFirst(_conn.Db2,
                    @"SELECT D60STDDB.DBSAITE.DIPRO
                      FROM D60STDDB.DBSAITE
                      WHERE D60STDDB.DBSAITE.MITEM=? AND D60STDDB.DBSAITE.MCOSC='CSPRO'",
                    codiceArticolo);
                if (row != null)
                {
                    codiceDisegno = S(row, "DIPRO");
                }
            }

            var pdf = GetDisegniPdf(codiceDisegno, storage);

            // Ultimo PDF AO dell'articolo.
            var articoloLink = codiceArticolo.Replace("/", "-");
            var fileAo = ElencaFile(storage, CARTELLA_AO_PDF_LIST, "AO_*" + articoloLink + "*.pdf");
            if (fileAo.Count > 0)
            {
                var numeroFoglio = fileAo.Count - 1;
                pdf.Add(new Dictionary<string, object?>
                {
                    ["url"] = URL_AO_PDF_LIST + fileAo[^1],
                    ["tipoPdf"] = "AO",
                    ["numeroFoglioPdf"] = numeroFoglio,
                    ["numeroFoglioPdfDisplay"] = numeroFoglio.ToString(CultureInfo.InvariantCulture)
                });
            }

            return pdf;
        }

        /// <summary>
        /// Scheda dell'articolo (ex selectSingoloArticolo.php): dati base e magazzini; con needCompleteInfo anche note,
        /// ordini di acquisto (con dettagli confermati), ODL, impegni ODL/ODV, prezzi, movimenti degli ultimi 2 anni,
        /// fabbisogni, magazzino/vano preferenziale, mancanti, foto (ARXivar e archivio tecnico) e PDF (disegni, AO, D9).
        /// Solleva <see cref="MobileException"/> (codice 404) se l'articolo non esiste.
        /// </summary>
        public async Task<Dictionary<string, object?>> SelectSingoloArticoloAsync(GiacArtSelectSingoloArticoloRequest req, StorageTool storage)
        {
            var codiceArticolo = req.codiceArticolo ?? "";
            var societa = req.societa ?? "CSPRO";

            // --- QUERY 0: informazioni base (vale l'ultima riga, come nel PHP) ---
            var base0 = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.DBSAITE.MITEM, D60STDDB.DBSAITE.MPDSC, D60STDDB.DBSAITE.MCOSC, D60STDDB.DBSAITE.MTYPN, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAITE.MWEIGHT, D60STDDB.DBSAITE.MPALLET, D60STDDB.DBSAITE.TIPOMAT, D60STDDB.DBSAITE.DIPRO,
                  D60STDDB.MASAINV.MALQT/100 AS IMPEGNATO_TOTALE, D60STDDB.MASAINV.MAVAL/100 AS DISPONIBILE_TOTALE, D60STDDB.MASAINV.MOHTQ/100 AS GIACENTE_TOTALE, D60STDDB.MASAINV.MPRPQ/100 AS IN_ORDINE_PRD, D60STDDB.MASAINV.MPUPQ/100 AS IN_ORDINE_ACQ, D60STDDB.MASAINV.MRLD AS ULTIMO_VERSAMENTO, D60STDDB.MASAINV.MILD AS ULTIMO_CONSUMO,
                  D60STDDB.CSDBITA.CSCOLOR, D60STDDB.CSDBITA.CSTRASU
                  FROM D60STDDB.DBSAITE
                  FULL JOIN D60STDDB.MASAINV ON (D60STDDB.MASAINV.MALITEM = D60STDDB.DBSAITE.MITEM) AND (D60STDDB.MASAINV.MAHCOSC = D60STDDB.DBSAITE.MCOSC)
                  FULL JOIN D60STDDB.MASAMSL ON D60STDDB.DBSAITE.MITEM = D60STDDB.MASAMSL.MALITEM
                  FULL JOIN D60STDDB.CSDBITA ON D60STDDB.DBSAITE.MITEM = D60STDDB.CSDBITA.CSITEMA
                  WHERE D60STDDB.DBSAITE.MITEM=? AND D60STDDB.MASAINV.MAHCOSC=?",
                codiceArticolo, societa).LastOrDefault();

            if (base0 == null)
            {
                throw new MobileException("Articolo non trovato", 404);
            }

            var articolo = new Dictionary<string, object?>
            {
                ["codice"] = S(base0, "MITEM"),
                ["codiceDisegno"] = S(base0, "DIPRO"),
                ["classificaUNI"] = S(base0, "TIPOMAT"),
                ["descrizione"] = S(base0, "MPDSC"),
                ["societa"] = S(base0, "MCOSC"),
                ["tipoArticolo"] = S(base0, "MTYPN"),
                ["unitaMisura"] = S(base0, "MUTMS"),
                ["pesoLordo"] = F(base0, "MPALLET") / 100,
                ["pesoNetto"] = F(base0, "MWEIGHT") / 100,
                ["disponibileTotale"] = F(base0, "DISPONIBILE_TOTALE"),
                ["impegnatoTotale"] = F(base0, "IMPEGNATO_TOTALE"),
                ["giacenteTotale"] = F(base0, "GIACENTE_TOTALE"),
                ["inOrdineProduzione"] = F(base0, "IN_ORDINE_PRD"),
                ["inOrdineAcquisto"] = F(base0, "IN_ORDINE_ACQ"),
                ["ultimoVersamento"] = F(base0, "ULTIMO_VERSAMENTO"),
                ["ultimoConsumo"] = F(base0, "ULTIMO_CONSUMO"),
                ["trattamento"] = S(base0, "CSTRASU"),
                ["colore"] = S(base0, "CSCOLOR")
            };

            // --- QUERY 1: magazzini ---
            articolo["listaMagazzini"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALOHQT/100 AS GIACENTE, D60STDDB.MASAMSL.MALLLQT/100 AS IMPEGNATO, D60STDDB.MASAHED.MAHTYMAG AS CATEGORIA
                  FROM D60STDDB.MASAMSL
                  FULL JOIN D60STDDB.DBSAITE ON D60STDDB.DBSAITE.MITEM = D60STDDB.MASAMSL.MALITEM AND D60STDDB.DBSAITE.MCOSC = D60STDDB.MASAMSL.MAHCOSC
                  FULL JOIN D60STDDB.MASAHED ON D60STDDB.MASAMSL.MLLOC = D60STDDB.MASAHED.MAHMAG AND D60STDDB.MASAHED.MAHCOSC = D60STDDB.MASAMSL.MAHCOSC
                  WHERE D60STDDB.DBSAITE.MITEM=? AND D60STDDB.MASAMSL.MAHCOSC=?
                  GROUP BY D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALOHQT, D60STDDB.MASAMSL.MALLLQT, D60STDDB.MASAHED.MAHTYMAG
                  ORDER BY D60STDDB.MASAMSL.MLLOC",
                codiceArticolo, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["codice"] = S(r, "MLLOC"),
                    ["vano"] = S(r, "MALLOC"),
                    ["impegnato"] = F(r, "IMPEGNATO"),
                    ["giacente"] = F(r, "GIACENTE"),
                    ["categoria"] = S(r, "CATEGORIA")
                }).ToList();

            if (!JsonVero(req.needCompleteInfo))
            {
                return articolo;
            }

            // --- QUERY 2: note ---
            articolo["listaNote"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.DBSAITX.PPUSER AS CODICE, D60STDDB.DBSAITX.PPTXTC AS TIPO_NOTA, D60STDDB.DBSAITX.PPSEQT AS RIGA, D60STDDB.DBSAITX.PPCOMM AS NOTA, D60STDDB.DBSAITE.MPDSC
                  FROM D60STDDB.DBSAITX FULL JOIN D60STDDB.DBSAITE ON D60STDDB.DBSAITX.PPUSER = D60STDDB.DBSAITE.MITEM
                  WHERE D60STDDB.DBSAITX.PPUSER=?
                  AND (D60STDDB.DBSAITX.PPTXTC='IT' OR D60STDDB.DBSAITX.PPTXTC='IA')
                  AND D60STDDB.DBSAITX.PPCOMM NOT LIKE 'END%' AND D60STDDB.DBSAITE.MCOSC=?
                  ORDER BY D60STDDB.DBSAITX.PPUSER, D60STDDB.DBSAITX.PPTXTC, D60STDDB.DBSAITX.PPSEQT",
                codiceArticolo, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["tipoNota"] = S(r, "TIPO_NOTA"),
                    ["nota"] = (V(r, "NOTA") ?? "").Trim(' ', '\t', '\n', '\r', '\0', '\x0B', '@')
                }).ToList();

            // --- QUERY 3: ordini di acquisto ---
            var listaOrdini = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.OFSAOSC.PSSUPNO AS FORNITORE, D60STDDB.ANSADID.ANINCO AS RAGIONE_SOCIALE, D60STDDB.OFSAOSC.PSORDNO AS NUMERO_ORDINE, D60STDDB.OFSAOSC.PSITEM AS ARTICOLO, (D60STDDB.OFSAOSC.PSORQTY-D60STDDB.OFSAOSC.PSDLQTY)/100 AS QTA_IN_ORDINE, D60STDDB.OFSAOSC.PSDESDT AS DATA_CONSEGNA, D60STDDB.OFSAOSC.PSORDLN, D60STDDB.OFSAOSC.PSLINO
                  FROM D60STDDB.OFSALIN FULL JOIN ((D60STDDB.OFSAOSC FULL JOIN D60STDDB.ANSADID ON (D60STDDB.ANSADID.ANCOSO = D60STDDB.OFSAOSC.PSCOSC) AND (D60STDDB.OFSAOSC.PSSUPNO = D60STDDB.ANSADID.ANCOCO))
                  FULL JOIN D60STDDB.DBSAITE ON (D60STDDB.OFSAOSC.PSCOSC = D60STDDB.DBSAITE.MCOSC) AND (D60STDDB.OFSAOSC.PSITEM = D60STDDB.DBSAITE.MITEM)) ON (D60STDDB.OFSALIN.POORDLN = D60STDDB.OFSAOSC.PSORDLN) AND (D60STDDB.OFSALIN.POCOSC = D60STDDB.OFSAOSC.PSCOSC) AND (D60STDDB.OFSALIN.POORDNO = D60STDDB.OFSAOSC.PSORDNO)
                  WHERE (((D60STDDB.OFSAOSC.PSITEM)=?) AND ((D60STDDB.OFSAOSC.PSCOSC)=?) AND ((D60STDDB.OFSALIN.POCOSC)=?) AND ((D60STDDB.OFSAOSC.PSSTATUS)='F' Or (D60STDDB.OFSAOSC.PSSTATUS)='R' Or (D60STDDB.OFSAOSC.PSSTATUS)='P') AND ((D60STDDB.OFSAOSC.PSAMEND)=0) AND ((D60STDDB.OFSALIN.POAMEND)=0))
                  ORDER BY D60STDDB.OFSAOSC.PSDESDT",
                codiceArticolo, societa, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["azienda"] = SenzaSpaziMultipli(S(r, "RAGIONE_SOCIALE")),
                    ["numeroOrdine"] = S(r, "NUMERO_ORDINE"),
                    ["qtaInOrdine"] = F(r, "QTA_IN_ORDINE"),
                    ["dataConsegna"] = F(r, "DATA_CONSEGNA"),
                    ["pos"] = F(r, "PSORDLN"),
                    ["sched"] = F(r, "PSLINO")
                }).ToList();
            articolo["listaOrdini"] = listaOrdini;

            // --- QUERY 3.5: ordini di lavoro ---
            articolo["listaOrdiniOdl"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.SOSAVRT.VRTORNO, D60STDDB.SOSAVRT.VRTITEM, D60STDDB.SOSAVRT.VRTPDSC, D60STDDB.SOSAVRT.VRTUM, D60STDDB.SOSAVRT.VRTCURQ/100 AS QTA, D60STDDB.SOSAVRT.VRTSTAT, D60STDDB.SOSAVRT.VRTRESP, D60STDDB.SOSAVRT.VRTEBED AS INIZIO, D60STDDB.SOSAVRT.VRTDUED AS CONSEGNA, D60STDDB.SOSAVRT.VRTSHLOC
                  FROM D60STDDB.SOSAVRT
                  WHERE D60STDDB.SOSAVRT.VRTSOC=? AND D60STDDB.SOSAVRT.VRTITEM=? AND D60STDDB.SOSAVRT.VRTTYPE='M' AND D60STDDB.SOSAVRT.VRTSTAT<'90'
                  ORDER BY D60STDDB.SOSAVRT.VRTDUED",
                societa, codiceArticolo)
                .Select(r => new Dictionary<string, object?>
                {
                    ["codiceOrdine"] = S(r, "VRTORNO"),
                    ["statoOrdine"] = S(r, "VRTSTAT"),
                    ["qta"] = F(r, "QTA"),
                    ["dataInizio"] = F(r, "INIZIO"),
                    ["dataConsegna"] = F(r, "CONSEGNA"),
                    ["magazzino"] = S(r, "VRTSHLOC"),
                    ["responsabileOrdine"] = S(r, "VRTRESP")
                }).ToList();

            // --- QUERY 4: impegni ODL ---
            articolo["listaImpegniOdl"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.SOSACPN.SOCDLOC AS mag, D60STDDB.SOSACPN.SOCDATE AS fabb, D60STDDB.SOSACPN.SOCQDEL/100 AS imp, D60STDDB.SOSACPN.SOCQMOVD/100 AS copertura, D60STDDB.SOSACPN.VRTORNO AS odl, D60STDDB.SOSACPN.SOCMAOP AS fase,
                  D60STDDB.SOSAVRT.VRTITEM AS padre, D60STDDB.SOSAVRT.VRTPDSC AS descr, D60STDDB.SOSAVRT.VRTTYPE AS t, D60STDDB.SOSACPN.SOCPIOS AS stato_comp
                  FROM (D60STDDB.SOSAVRT FULL JOIN D60STDDB.SOSACPN ON (D60STDDB.SOSAVRT.VRTSOC = D60STDDB.SOSACPN.VRTSOC) AND (D60STDDB.SOSAVRT.VRTORNO = D60STDDB.SOSACPN.VRTORNO))
                  FULL JOIN D60STDDB.DBSAITE ON (D60STDDB.SOSACPN.VRTSOC = D60STDDB.DBSAITE.MCOSC) AND (D60STDDB.SOSACPN.SOCPKEY = D60STDDB.DBSAITE.MITEM)
                  WHERE (((D60STDDB.SOSACPN.SOCPKEY)=?) AND ((D60STDDB.SOSAVRT.VRTSTAT)<'90') AND ((D60STDDB.SOSACPN.VRTSOC)=?) AND ((D60STDDB.SOSACPN.SOCPIOS)<'90'))
                  ORDER BY D60STDDB.SOSACPN.SOCDATE, D60STDDB.SOSACPN.SOCDLOC, D60STDDB.SOSACPN.SOCPKEY",
                codiceArticolo, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["odl"] = S(r, "ODL"),
                    ["magazzino"] = S(r, "MAG"),
                    ["data"] = F(r, "FABB"),
                    ["impegnato"] = F(r, "IMP"),
                    ["copertura"] = F(r, "COPERTURA"),
                    ["fase"] = S(r, "FASE"),
                    ["padre"] = S(r, "PADRE"),
                    ["descrizione"] = S(r, "DESCR"),
                    ["tipologia"] = S(r, "T"),
                    ["stato"] = S(r, "STATO_COMP")
                }).ToList();

            // --- QUERY 5: impegni ODV ---
            articolo["listaImpegniOdv"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.OCSASCD.OCCORDN AS ORDINE, D60STDDB.OCSASCD.OCCITEM AS ARTICOLO, D60STDDB.OCSASCD.OCCPRDT AS DATA_CONS, D60STDDB.OCSASCD.OCCIMQT/100 AS IMPEGNATA, D60STDDB.OCSASCD.OCCSTAT AS STATO, D60STDDB.ANSADID.ANINCO
                  FROM (D60STDDB.OCSASCD FULL JOIN D60STDDB.OCSAORH ON (D60STDDB.OCSASCD.OCCAMND = D60STDDB.OCSAORH.OCHAMND) AND (D60STDDB.OCSASCD.OCCCOSC = D60STDDB.OCSAORH.OCHCOSC) AND (D60STDDB.OCSASCD.OCCORDN = D60STDDB.OCSAORH.OCHORDN))
                  FULL JOIN D60STDDB.ANSADID ON (D60STDDB.OCSAORH.OCHCOSC = D60STDDB.ANSADID.ANCOSO) AND (D60STDDB.OCSAORH.OCHCLII = D60STDDB.ANSADID.ANCOCO)
                  WHERE (((D60STDDB.OCSASCD.OCCITEM)=?) AND ((D60STDDB.OCSASCD.OCCAMND)=0) AND ((D60STDDB.OCSASCD.OCCCOSC)=?) AND ((D60STDDB.OCSASCD.OCCSTAT)='R' Or (D60STDDB.OCSASCD.OCCSTAT)='F') AND ((D60STDDB.ANSADID.ANCOSO)=?) AND ((D60STDDB.OCSAORH.OCHCOSC)=?))
                  ORDER BY D60STDDB.OCSASCD.OCCPRDT, D60STDDB.ANSADID.ANINCO",
                codiceArticolo, societa, societa, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["odv"] = S(r, "ORDINE"),
                    ["impegnato"] = F(r, "IMPEGNATA"),
                    ["dataConsegna"] = F(r, "DATA_CONS"),
                    ["azienda"] = S(r, "ANINCO"),
                    ["stato"] = S(r, "STATO")
                }).ToList();

            // --- QUERY 6: prezzi ---
            articolo["listaPrezzi"] = DbHelper.Query(_conn.Db2,
                @"SELECT D60STDDB.ANSADID.ANINCO AS ragione_sociale, D60STDDB.OFSAQUO.SQQC AS TQ, D60STDDB.OFSAQUO.SQCURRC AS VALUTA, D60STDDB.OFSAQUO.SQIUM AS UM, D60STDDB.OFSAQUO.SQNPR/10000 AS prezzo_netto, D60STDDB.OFSAQUO.SQMATF AS tf, D60STDDB.OFSAQUO.SQESD AS inizio, D60STDDB.OFSAQUO.SQDQV AS fine
                  FROM D60STDDB.OFSAQUO FULL JOIN D60STDDB.ANSADID ON (D60STDDB.ANSADID.ANCOSO = D60STDDB.OFSAQUO.SQCOSC) AND (D60STDDB.OFSAQUO.SQSUPNO = D60STDDB.ANSADID.ANCOCO)
                  WHERE (((D60STDDB.OFSAQUO.SQITMNO)=?) AND ((D60STDDB.OFSAQUO.SQQC)<>'P' Or (D60STDDB.OFSAQUO.SQQC)='G') AND ((D60STDDB.OFSAQUO.SQMATF)<>'E') AND ((D60STDDB.OFSAQUO.SQDQV)>20192202) AND ((D60STDDB.OFSAQUO.SQCOSC)=?) AND ((D60STDDB.ANSADID.ANCOSO)=?))
                  ORDER BY D60STDDB.OFSAQUO.SQESD, D60STDDB.ANSADID.ANINCO DESC",
                codiceArticolo, societa, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["azienda"] = S(r, "RAGIONE_SOCIALE"),
                    ["tq"] = S(r, "TQ"),
                    ["tf"] = S(r, "TF"),
                    ["valuta"] = S(r, "VALUTA"),
                    ["unitaMisura"] = S(r, "UM"),
                    ["prezzoNetto"] = F(r, "PREZZO_NETTO"),
                    ["dataInizio"] = F(r, "INIZIO")
                }).ToList();

            // --- QUERY 7: movimenti degli ultimi 2 anni (ordinati per data versamento) ---
            var dataLimite = int.Parse(DateTime.Now.ToString("yyyyMMdd", CultureInfo.InvariantCulture), CultureInfo.InvariantCulture) - 20000;
            articolo["listaMovimenti"] = DbHelper.Query(_conn.Db2,
                @"SELECT
                  D60STDDB.MASATRN.TRNITM, D60STDDB.MASATRN.TNBOL AS BOLLA, D60STDDB.MASATRN.TPARE, D60STDDB.MASATRN.TDTVER, D60STDDB.MASATRN.TTRAN, D60STDDB.MASATRN.TQUAN/100 AS QTA, D60STDDB.MASATRN.TMAG, D60STDDB.MASATRN.TLOC, D60STDDB.MASATRN.TCHNU, D60STDDB.MASATRN.TMACO, D60STDDB.MASATRN.TUSCO, D60STDDB.MASATRN.TTRAN, D60STDDB.MASATRN.TORNUOR, D60STDDB.MASATRN.TRNI, D60STDDB.MASATRN.TUSDES,D60STDDB.MASATRN.TRESP,
                  DBSAITE_1.MPDSC, D60STDDB.ANSADID.ANINCO, D60STDDB.MASATRN.TRDATE
                  FROM (D60STDDB.MASATRN FULL JOIN D60STDDB.DBSAITE ON (D60STDDB.MASATRN.TRNSOC = D60STDDB.DBSAITE.MCOSC) AND (D60STDDB.MASATRN.TRNITM = D60STDDB.DBSAITE.MITEM))
                  FULL JOIN D60STDDB.DBSAITE AS DBSAITE_1 ON (D60STDDB.MASATRN.TPARE = DBSAITE_1.MITEM) AND (D60STDDB.MASATRN.TRNSOC = DBSAITE_1.MCOSC)
                  FULL JOIN D60STDDB.ANSADID ON D60STDDB.MASATRN.TCHNU = D60STDDB.ANSADID.ANCOCO
                  WHERE (((D60STDDB.MASATRN.TRNITM)=?) AND ((D60STDDB.MASATRN.TDTVER)>?) AND ((D60STDDB.MASATRN.TMACO)<>'MV') AND ((D60STDDB.MASATRN.TRNSOC)=?) AND ((D60STDDB.DBSAITE.MCOSC)=?) AND ((D60STDDB.ANSADID.ANCOSO=? OR D60STDDB.ANSADID.ANCOSO IS NULL)))
                  ORDER BY D60STDDB.MASATRN.TDTVER DESC, D60STDDB.MASATRN.TMACO ASC",
                codiceArticolo, dataLimite, societa, societa, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["riferimento"] = S(r, "TORNUOR"),
                    ["magazzino"] = S(r, "TMAG"),
                    ["movCausale"] = S(r, "TMACO"),
                    ["movValore"] = S(r, "TUSCO"),
                    ["movStorno"] = S(r, "TTRAN"),
                    ["quantita"] = F(r, "QTA"),
                    ["data"] = F(r, "TDTVER"),
                    ["data_integer"] = PhpInt(S(r, "TDTVER")),
                    ["codiceFornitore"] = S(r, "TCHNU"),
                    ["descrizioneFornitore"] = S(r, "ANINCO"),
                    ["codicePadre"] = S(r, "TPARE"),
                    ["descrizionePadre"] = S(r, "MPDSC"),
                    ["trni"] = S(r, "TRNI"),
                    ["bolla"] = S(r, "BOLLA"),
                    ["nota"] = S(r, "TUSDES"),
                    ["responsabile"] = S(r, "TRESP"),
                    ["vano"] = S(r, "TLOC"),
                    ["ora"] = PhpSubstr(S(r, "TRDATE"), 8)
                }).ToList();

            // --- QUERY 8: fabbisogni ---
            articolo["listaFabbisogni"] = DbHelper.Query(_conn.Db2,
                @"SELECT DISTINCT D60STDDB.PMSAGRQ.GRITEM AS ARTICOLO, D60STDDB.PMSAGRQ.GRDUEDT AS DATA_FABB, D60STDDB.PMSAGRQ.GRPARENT AS GRUPPO, D60STDDB.PMSAGRQ.GRQTTOT/100 AS FABB,
                  D60STDDB.DBSAITE.MPDSC AS GRUPPO_DESC
                  FROM D60STDDB.PMSAGRQ
                  FULL JOIN D60STDDB.DBSAITE ON D60STDDB.PMSAGRQ.GRPARENT = D60STDDB.DBSAITE.MITEM
                  WHERE (((D60STDDB.PMSAGRQ.GRITEM)=?) AND ((D60STDDB.PMSAGRQ.GRSOC)=?) AND ((D60STDDB.PMSAGRQ.GRNUPLAN)=1))
                  ORDER BY DATA_FABB, FABB",
                codiceArticolo, societa)
                .Select(r => new Dictionary<string, object?>
                {
                    ["data"] = F(r, "DATA_FABB"),
                    ["impegnato"] = F(r, "FABB"),
                    ["codicePadre"] = S(r, "GRUPPO"),
                    ["descrizionePadre"] = SenzaSpaziMultipli(S(r, "GRUPPO_DESC"))
                }).ToList();

            // --- QUERY 9: magazzino / vano preferenziale (prima MISK*, poi qualsiasi) ---
            articolo["magazzinoVanoPreferenziale"] =
                GetMagazzinoVanoPreferenziale(codiceArticolo, true, societa)
                ?? GetMagazzinoVanoPreferenziale(codiceArticolo, false, societa);

            // --- QUERY 10: mancanti (PostgreSQL casagrande) ---
            articolo["listaMancanti"] = DbHelper.Query(_conn.PgCasagrande,
                @"SELECT cs_fabbmanc_odl_comp.numero AS ODL, cs_fabbmanc_odl_comp.magazzino AS mag, cs_fabbmanc_odl_comp.articolo, cs_fabbmanc_odl_comp.fase, cs_fabbmanc_odl_comp.stato, cs_fabbmanc_odl_comp.fabbdate AS data_fabb, cs_fabbmanc_odl_comp.pickautorizzato, cs_fabbmanc_odl_comp.picklanciato, cs_fabbmanc_odl_comp.pickconcluso, cs_fabbmanc_odl_comp.statopick, cs_fabbmanc_odl_comp.qtatot, cs_fabbmanc_odl_comp.qtares, cs_fabbmanc_odl_comp.qtafab, cs_fabbmanc_odl_comp.giacmag AS trasf, cs_fabbmanc_odl_comp.giacdispo AS da_trasf, cs_fabbmanc_odl_comp.giacdispoext, cs_fabbmanc_odl_comp.qtaiodl AS in_odl, cs_fabbmanc_odl_comp.qtaisoda AS in_oda, cs_fabbmanc_odl_comp.qtaisrda AS in_rda,
                  cs_fabbmanc_odl.articolo as articolo2, cs_fabbmanc_odl.descarticolo as descarticolo2, cs_fabbmanc_odl.tipoodl, cs_fabbmanc_odl.desccolore, cs_fabbmanc_odl_comp.pesol
                  FROM cs_fabbmanc_odl
                  FULL JOIN cs_fabbmanc_odl_comp ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero) AND (cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa)
                  WHERE (((cs_fabbmanc_odl_comp.articolo)=?) AND ((cs_fabbmanc_odl_comp.societa)=?))
                  ORDER BY cs_fabbmanc_odl_comp.fabbdate desc, cs_fabbmanc_odl_comp.stato",
                codiceArticolo, societa)
                .Select(m => new Dictionary<string, object?>
                {
                    ["odl"] = V(m, "odl"),
                    ["mag"] = V(m, "mag"),
                    ["articolo"] = V(m, "articolo"),
                    ["fase"] = V(m, "fase"),
                    ["stato"] = V(m, "stato"),
                    ["data_fabb"] = F(m, "data_fabb"),
                    ["pickautorizzato"] = V(m, "pickautorizzato"),
                    ["picklanciato"] = V(m, "picklanciato"),
                    ["pickconcluso"] = V(m, "pickconcluso"),
                    ["statopick"] = V(m, "statopick"),
                    ["qtatot"] = F(m, "qtatot"),
                    ["qtares"] = F(m, "qtares"),
                    ["qtafab"] = F(m, "qtafab"),
                    ["trasf"] = F(m, "trasf"),
                    ["da_trasf"] = F(m, "da_trasf"),
                    ["giacdispoext"] = F(m, "giacdispoext"),
                    ["in_odl"] = F(m, "in_odl"),
                    ["in_oda"] = F(m, "in_oda"),
                    ["in_rda"] = F(m, "in_rda"),
                    ["articolo2"] = V(m, "articolo2"),
                    ["descarticolo2"] = V(m, "descarticolo2"),
                    ["tipoodl"] = V(m, "tipoodl"),
                    ["descrizioneColore"] = V(m, "desccolore") ?? "",
                    ["pesoLordo"] = F(m, "pesol")
                }).ToList();

            // --- QUERY 11: date / quantità confermate degli ordini di acquisto (cs_fabbmanc_risp_soda2) ---
            foreach (var ordine in listaOrdini)
            {
                ordine["dettagliOrdine"] = DbHelper.Query(_conn.PgCasagrande,
                    "select dtconf, qtaconf, note from cs_fabbmanc_risp_soda2 where numero=? AND pos=? AND sched=? AND societa=?",
                    (string)ordine["numeroOrdine"]!,
                    PhpFloatToString((double)ordine["pos"]!),
                    PhpFloatToString((double)ordine["sched"]!),
                    societa)
                    .Select(d => new Dictionary<string, object?>
                    {
                        ["dataConfermata"] = V(d, "dtconf"),
                        ["qtaConfermata"] = V(d, "qtaconf"),
                        ["note"] = V(d, "note")
                    }).ToList();
            }

            // --- Foto: ARXivar (max 10 jpg) + archivio tecnico <articolo>_<n>.jpg/.jpeg ---
            var articoloLink = codiceArticolo.Replace("/", "-");
            var immagini = await GetFotoArxivarAsync(articoloLink, storage);
            for (int numeroFoto = 1; ; numeroFoto++)
            {
                var nome = articoloLink + "_" + numeroFoto;
                if (EsisteFile(storage, CARTELLA_FOTO_TECNICO, nome + ".jpg"))
                {
                    immagini.Add(URL_FOTO_TECNICO + nome + ".jpg");
                }
                else if (EsisteFile(storage, CARTELLA_FOTO_TECNICO, nome + ".jpeg"))
                {
                    immagini.Add(URL_FOTO_TECNICO + nome + ".jpeg");
                }
                else
                {
                    break;
                }
            }
            articolo["arrayImmagini"] = immagini;

            // --- PDF: disegni (codice disegno, altrimenti classifica UNI), ultimo AO, archivio D9 ---
            var codicePdf = (string)articolo["codiceDisegno"]!;
            if (codicePdf == "")
            {
                codicePdf = (string)articolo["classificaUNI"]!;
            }
            var arrayPdf = codicePdf != "" ? GetDisegniPdf(codicePdf, storage) : new List<Dictionary<string, object?>>();

            var ultimoAo = GetUltimoPdfAo(articoloLink, storage);
            if (ultimoAo != null)
            {
                arrayPdf.Add(ultimoAo);
            }

            arrayPdf.AddRange(GetArchivioD9(articoloLink, storage));
            articolo["arrayPdfFile"] = arrayPdf;

            return articolo;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Funzioni condivise --------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>Ex shared_functions/getListaGiacenze.php.</summary>
        private List<Dictionary<string, object?>> GetListaGiacenze(string magazzino, string sezione, string? tipoListaInventario)
        {
            var condizione = "D60STDDB.MASAMSL.MLLOC=?";
            var valori = new List<object?> { magazzino };
            var orderBy = "D60STDDB.MASAMSL.MALITEM";

            if (sezione == "giacenze")
            {
                condizione = "D60STDDB.MASAMSL.MLLOC=? OR D60STDDB.MASAMSL.MALLOC LIKE ?";
                valori = new List<object?> { magazzino, magazzino + "%" };
            }
            else if (sezione == "inventario")
            {
                switch (tipoListaInventario)
                {
                    case "magazzino":
                        orderBy = "D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALITEM";
                        break;
                    case "vano_preciso":
                        condizione = "D60STDDB.MASAMSL.MALLOC=?";
                        break;
                    case "vano_radice":
                        condizione = "D60STDDB.MASAMSL.MALLOC LIKE ?";
                        valori = new List<object?> { magazzino + "%" };
                        orderBy = "D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALITEM";
                        break;
                }
            }

            var rows = DbHelper.Query(_conn.Db2,
                $@"SELECT D60STDDB.MASAMSL.MALITEM, D60STDDB.DBSAITE.MUTMS, D60STDDB.DBSAITE.MPDSC, D60STDDB.MASAMSL.MALLLQT*0.01 AS IMPEGNATO, D60STDDB.MASAINV.MAVAL*0.01 AS DISPONIBILE,
                   D60STDDB.MASAINV.MOHTQ*0.01 AS GIACENTE_TOT, D60STDDB.MASAINV.MPRPQ*0.01 AS IN_ORDINE_PRD, D60STDDB.MASAINV.MPUPQ*0.01 AS IN_ORDINE_ACQ,
                   D60STDDB.MASAINV.MRLD AS ULTIMO_VERSAMENTO, D60STDDB.MASAINV.MILD AS ULTIMO_CONSUMO, D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALOHQT*0.01 AS QTA_GIAC, D60STDDB.MASAMSL.MALLOC, D60STDDB.DBSAITE.MTYPN
                   FROM D60STDDB.DBSAITE INNER JOIN (D60STDDB.MASAMSL INNER JOIN D60STDDB.MASAINV ON (D60STDDB.MASAMSL.MAHCOSC = D60STDDB.MASAINV.MAHCOSC) AND (D60STDDB.MASAMSL.MALITEM = D60STDDB.MASAINV.MALITEM)) ON (D60STDDB.DBSAITE.MCOSC = D60STDDB.MASAMSL.MAHCOSC) AND (D60STDDB.DBSAITE.MITEM = D60STDDB.MASAMSL.MALITEM)
                   GROUP BY D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALITEM, D60STDDB.DBSAITE.MPDSC, D60STDDB.MASAMSL.MALLLQT*0.01, D60STDDB.MASAINV.MAVAL*0.01, D60STDDB.MASAINV.MOHTQ*0.01, D60STDDB.MASAINV.MPRPQ*0.01, D60STDDB.MASAINV.MPUPQ*0.01, D60STDDB.MASAINV.MRLD, D60STDDB.MASAINV.MILD, D60STDDB.MASAMSL.MALOHQT*0.01, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MAHCOSC, D60STDDB.DBSAITE.MTYPN, D60STDDB.DBSAITE.MUTMS
                   HAVING D60STDDB.MASAMSL.MALOHQT*0.01>0 AND ({condizione}) AND D60STDDB.MASAMSL.MAHCOSC='CSPRO' AND D60STDDB.DBSAITE.MTYPN != 'N'
                   ORDER BY {orderBy}",
                valori.ToArray());

            return rows.Select(r => new Dictionary<string, object?>
            {
                ["articolo"] = S(r, "MALITEM"),
                ["descrizione"] = S(r, "MPDSC"),
                ["impegnato"] = F(r, "IMPEGNATO"),
                ["disponibile"] = F(r, "DISPONIBILE"),
                ["giacente_tot"] = F(r, "GIACENTE_TOT"),
                ["qta_giacente"] = F(r, "QTA_GIAC"),
                ["in_ordine_prd"] = F(r, "IN_ORDINE_PRD"),
                ["in_ordine_acq"] = F(r, "IN_ORDINE_ACQ"),
                ["ultimoVersamento"] = F(r, "ULTIMO_VERSAMENTO"),
                ["ultimoConsumo"] = F(r, "ULTIMO_CONSUMO"),
                ["um"] = S(r, "MUTMS"),
                ["magazzino"] = S(r, "MLLOC"),
                ["vano"] = S(r, "MALLOC"),
                ["url_foto"] = ""
            }).ToList();
        }

        private bool EsisteMagazzino(string magazzino)
        {
            return DbHelper.Query(_conn.Db2,
                @"SELECT DISTINCT D60STDDB.MASAHED.MAHMAG
                  FROM D60STDDB.MASAHED
                  WHERE D60STDDB.MASAHED.MAHCOSC='CSPRO' AND D60STDDB.MASAHED.MAHMAG=?",
                magazzino).Count > 0;
        }

        /// <summary>Ex getMagazzinoVanoPreferenziale di selectSingoloArticolo.php; null se non c'è.</summary>
        private Dictionary<string, object?>? GetMagazzinoVanoPreferenziale(string codiceArticolo, bool soloMisk, string societa)
        {
            var filtroMisk = soloMisk ? "AND D60STDDB.MASAHED.MAHMAG LIKE 'MISK%'" : "";
            var row = DbHelper.QueryFirst(_conn.Db2,
                $@"SELECT D60STDDB.MASAHED.MAHMAG, D60STDDB.MASAVAN.MVCELLA
                   FROM D60STDDB.MASAHED
                   FULL JOIN D60STDDB.MASAVAN ON D60STDDB.MASAHED.MAHMAG = D60STDDB.MASAVAN.MVLOC
                   WHERE D60STDDB.MASAHED.MAHCOSC=?
                   AND D60STDDB.MASAHED.MAHTYMAG='ST'
                   {filtroMisk}
                   AND D60STDDB.MASAVAN.MVCELLA NOT LIKE '**%'
                   AND D60STDDB.MASAHED.MAHDISP = 'Y'
                   AND D60STDDB.MASAVAN.MVFIRST = '*'
                   AND D60STDDB.MASAVAN.MVVITEM=?
                   LIMIT 1",
                societa, codiceArticolo);

            return row == null ? null : new Dictionary<string, object?>
            {
                ["magazzino"] = S(row, "MAHMAG"),
                ["vano"] = S(row, "MVCELLA")
            };
        }

        /// <summary>
        /// Ex query/giacenze/shared/getDisegniPdf.php: PDF dell'archivio disegni il cui nome inizia con il codice disegno
        /// (fogli -F01, -F02... o foglio con lettera), in ordine di nome.
        /// </summary>
        private static List<Dictionary<string, object?>> GetDisegniPdf(string? codiceDisegno, StorageTool storage)
        {
            var lista = new List<Dictionary<string, object?>>();
            var articoloLink = (codiceDisegno ?? "").Replace("/", "-").Trim();
            if (articoloLink == "")
            {
                return lista;
            }

            var files = ElencaFile(storage, CARTELLA_DISEGNI, articoloLink + "*.*")
                .Where(f => f.EndsWith("pdf", StringComparison.OrdinalIgnoreCase))
                .OrderBy(f => f, StringComparer.Ordinal)
                .ToList();

            foreach (var nome in files)
            {
                var url = URL_DISEGNI + nome;

                // Parte del nome dopo il codice disegno, es. "-F01.pdf".
                var codicePdf = nome.StartsWith(articoloLink, StringComparison.OrdinalIgnoreCase) ? nome.Substring(articoloLink.Length) : nome;
                object numeroFoglioPdf = PhpInt(PhpSubstr(codicePdf, 2, 3));
                var numeroFoglioPdfDisplay = PhpSubstr(codicePdf, 1, 3);

                var match = Regex.Match(nome, @"-([a-zA-Z0-9]+)-([a-zA-Z0-9]+)\.pdf$", RegexOptions.IgnoreCase);
                if (match.Success)
                {
                    numeroFoglioPdf = match.Groups[1].Value;
                    numeroFoglioPdfDisplay = match.Groups[2].Value;
                }
                if (!Regex.IsMatch(numeroFoglioPdfDisplay, @"^F\d\d$", RegexOptions.IgnoreCase))
                {
                    numeroFoglioPdfDisplay = "F00";
                }

                lista.Add(new Dictionary<string, object?>
                {
                    ["url"] = url,
                    ["short_url"] = url.Substring(0, url.Length - 4),
                    ["numeroFoglioPdf"] = numeroFoglioPdf,
                    ["tipoPdf"] = "disegno",
                    ["numeroFoglioPdfDisplay"] = numeroFoglioPdfDisplay.ToUpperInvariant()
                });
            }
            return lista;
        }

        /// <summary>
        /// Ultimo PDF AO_*&lt;articolo&gt;*.pdf dell'archivio AO, ordinato per le due cifre dopo "AO_&lt;articolo&gt;_"
        /// (sezione "QUERY SPECIAL 2B" di selectSingoloArticolo.php); null se non ce ne sono.
        /// </summary>
        private static Dictionary<string, object?>? GetUltimoPdfAo(string articoloLink, StorageTool storage)
        {
            var prefisso = "AO_" + articoloLink;
            var files = ElencaFile(storage, CARTELLA_AO_SCHEDA, "AO_*" + articoloLink + "*.pdf")
                .OrderBy(f => f, StringComparer.Ordinal)
                .Where(f => f.Contains(prefisso, StringComparison.Ordinal))
                .OrderBy(f => PhpSubstr(f, f.IndexOf(prefisso, StringComparison.Ordinal) + prefisso.Length + 1, 2), StringComparer.Ordinal)
                .ToList();

            if (files.Count == 0)
            {
                return null;
            }

            var numeroFoglio = files.Count - 1;
            return new Dictionary<string, object?>
            {
                ["url"] = URL_AO_SCHEDA + files[^1],
                ["tipoPdf"] = "AO",
                ["numeroFoglioPdf"] = numeroFoglio,
                ["numeroFoglioPdfDisplay"] = numeroFoglio.ToString(CultureInfo.InvariantCulture)
            };
        }

        /// <summary>
        /// File dell'archivio D9 (sezione "QUERY SPECIAL 3B" di selectSingoloArticolo.php): contenuto (ricorsivo) delle
        /// cartelle *&lt;articolo&gt;* e file sparsi *&lt;articolo&gt;* nella radice; esclusi cartelle e file .db.
        /// numeroFoglioPdf è la posizione nell'elenco completo (cartelle comprese), come nel PHP.
        /// </summary>
        private static List<Dictionary<string, object?>> GetArchivioD9(string articoloLink, StorageTool storage)
        {
            var lista = new List<Dictionary<string, object?>>();
            var pattern = PatternSicuro(articoloLink);
            var radice = storage.Resolve(CARTELLA_D9);
            if (pattern == null || !Directory.Exists(radice))
            {
                return lista;
            }

            var elementi = new List<string>();
            var cartelle = Directory.GetDirectories(radice, "*" + pattern + "*").OrderBy(d => d, StringComparer.Ordinal).ToList();

            // Contenuto diretto delle cartelle dell'articolo, poi ricorsivamente le sottocartelle.
            elementi.AddRange(cartelle.SelectMany(Directory.GetFileSystemEntries).OrderBy(e => e, StringComparer.Ordinal));
            foreach (var sotto in cartelle.SelectMany(Directory.GetDirectories).OrderBy(d => d, StringComparer.Ordinal))
            {
                AggiungiRicorsivo(sotto, elementi);
            }

            // File sparsi nella radice dell'archivio.
            elementi.AddRange(Directory.GetFileSystemEntries(radice, "*" + pattern + "*"));

            for (int i = 0; i < elementi.Count; i++)
            {
                var percorso = elementi[i];
                var estensione = Path.GetExtension(percorso).TrimStart('.');
                if (!File.Exists(percorso) || estensione == "db")
                {
                    continue;
                }

                var relativo = Path.GetRelativePath(radice, percorso).Replace('\\', '/');
                lista.Add(new Dictionary<string, object?>
                {
                    ["url"] = URL_D9 + "/" + relativo,
                    ["tipoPdf"] = "D9",
                    ["numeroFoglioPdf"] = i + 1,
                    ["numeroFoglioPdfDisplay"] = Path.GetFileName(percorso),
                    ["estensione"] = estensione
                });
            }
            return lista;
        }

        private static void AggiungiRicorsivo(string cartella, List<string> elementi)
        {
            elementi.AddRange(Directory.GetFileSystemEntries(cartella).OrderBy(e => e, StringComparer.Ordinal));
            foreach (var sotto in Directory.GetDirectories(cartella).OrderBy(d => d, StringComparer.Ordinal))
            {
                AggiungiRicorsivo(sotto, elementi);
            }
        }

        /// <summary>
        /// Foto ARXivar dell'articolo (classe foto ricambi, COMBO6_3 = 'Fotografia', TABLE1_3 = articolo), al massimo 10 jpg:
        /// vengono copiate nell'archivio foto del tecnico se mancanti; quelle non VALID vengono rimosse e non restituite
        /// (ex connectArx.php + query su ARCHDB.dbo.DM_PROFILE di selectSingoloArticolo.php).
        /// </summary>
        private static async Task<List<string>> GetFotoArxivarAsync(string articoloLink, StorageTool storage)
        {
            var urls = new List<string>();

            var content = new Dictionary<string, JsonElement>
            {
                ["idDocFather"] = JsonSerializer.SerializeToElement(ARX_CLASSE_PADRE_FOTO),
                ["idDoc"] = JsonSerializer.SerializeToElement(ARX_CLASSE_FOTO),
                ["societa"] = JsonSerializer.SerializeToElement(ARX_SOCIETA),
                ["searchFields"] = JsonSerializer.SerializeToElement(new[]
                {
                    new ArxSearchElement("COMBO6_3", "string", "Fotografia", 3, false),
                    new ArxSearchElement("TABLE1_3", "string", articoloLink, 3, false)
                }),
                // Colonne restituite, nell'ordine: numero documento, stato, nome file.
                ["selectFields"] = JsonSerializer.SerializeToElement(new[]
                {
                    new ArxSelectElement("DOCNUMBER", true, "asc", 0),
                    new ArxSelectElement("STATO", true, "", 1),
                    new ArxSelectElement("FILENAME", true, "", 2)
                })
            };

            List<List<string>> documenti;
            try
            {
                documenti = await ArxHelper.GetArxData(content);
            }
            catch (Exception)
            {
                // Come nel PHP: se ARXivar non risponde la scheda viene restituita senza le sue foto.
                return urls;
            }

            var trovati = documenti
                .Where(d => d.Count >= 3 && int.TryParse(d[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out _))
                .Select(d => (docNumber: int.Parse(d[0], CultureInfo.InvariantCulture), stato: d[1], fileName: d[2]))
                .OrderBy(d => d.docNumber);

            var conteggio = 0;
            foreach (var (docNumber, stato, fileName) in trovati)
            {
                var estensione = Path.GetExtension(fileName).ToLowerInvariant();
                if (estensione != ".jpg" && estensione != ".jpeg")
                {
                    continue;
                }
                if (++conteggio > 10)
                {
                    break;
                }

                var nomeFoto = articoloLink + "_arx" + docNumber + estensione;
                if (stato != "VALID")
                {
                    EliminaFile(storage, CARTELLA_FOTO_TECNICO, nomeFoto);
                    continue;
                }

                if (!EsisteFile(storage, CARTELLA_FOTO_TECNICO, nomeFoto))
                {
                    try
                    {
                        var contenuto = (await ArxHelper.GetArxFiles(docNumber)).FirstOrDefault();
                        if (contenuto != null)
                        {
                            await storage.SalvaBytesAsync(contenuto, CARTELLA_FOTO_TECNICO, nomeFoto);
                        }
                    }
                    catch (Exception)
                    {
                        // Come la copy() del PHP: se la copia fallisce il link viene comunque restituito.
                    }
                }
                urls.Add(URL_FOTO_TECNICO + nomeFoto);
            }
            return urls;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Helper --------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        private static string Obbligatorio(string? valore, string nome)
        {
            if (string.IsNullOrWhiteSpace(valore))
            {
                throw new MobileException($"Parametro '{nome}' obbligatorio");
            }
            return valore;
        }

        /// <summary>Valore della colonna (ricerca senza distinzione maiuscole/minuscole) come stringa, o null.</summary>
        private static string? V(Dictionary<string, object?> row, string colonna)
        {
            if (row.TryGetValue(colonna, out var v))
            {
                return v?.ToString();
            }
            foreach (var kv in row)
            {
                if (string.Equals(kv.Key, colonna, StringComparison.OrdinalIgnoreCase))
                {
                    return kv.Value?.ToString();
                }
            }
            return null;
        }

        /// <summary>trim(odbc_result(...)).</summary>
        private static string S(Dictionary<string, object?> row, string colonna) => (V(row, colonna) ?? "").Trim();

        /// <summary>(float)trim(odbc_result(...)).</summary>
        private static double F(Dictionary<string, object?> row, string colonna) => PhpFloat(V(row, colonna));

        private static string SenzaSpaziMultipli(string s) => _spaziMultipli.Replace(s, " ");

        /// <summary>Cast (float) di PHP: prefisso numerico della stringa, 0 se assente.</summary>
        private static double PhpFloat(string? s)
        {
            var m = _numeroIniziale.Match(s ?? "");
            return m.Success && double.TryParse(m.Value.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var d) ? d : 0;
        }

        /// <summary>Cast (int) di PHP.</summary>
        private static int PhpInt(string? s)
        {
            var d = Math.Truncate(PhpFloat(s));
            return d > int.MaxValue || d < int.MinValue ? 0 : (int)d;
        }

        /// <summary>Conversione float → stringa di PHP (10.0 → "10").</summary>
        private static string PhpFloatToString(double d) => d.ToString("R", CultureInfo.InvariantCulture);

        /// <summary>substr() di PHP 8 (stringa vuota oltre la fine).</summary>
        private static string PhpSubstr(string s, int start, int? lunghezza = null)
        {
            if (start < 0 || start >= s.Length) return "";
            var len = Math.Min(lunghezza ?? s.Length - start, s.Length - start);
            return len <= 0 ? "" : s.Substring(start, len);
        }

        /// <summary>Valore "vero" di json_decode($campo) usato come booleano.</summary>
        private static bool JsonVero(string? s)
        {
            var t = (s ?? "").Trim();
            if (t == "true") return true;
            if (_numeroCompleto.IsMatch(t)) return PhpFloat(t) != 0;
            if (t.Length >= 2 && t[0] == '"' && t[^1] == '"')
            {
                var interno = t.Substring(1, t.Length - 2);
                return interno != "" && interno != "0";
            }
            return false;
        }

        /// <summary>Confronto PHP 8 <c>$numero &gt;= $stringa</c>.</summary>
        private static bool PhpMaggioreUguale(double numero, string? s)
        {
            if (_numeroCompleto.IsMatch(s ?? ""))
            {
                return numero >= PhpFloat(s);
            }
            return string.CompareOrdinal(PhpFloatToString(numero), s ?? "") >= 0;
        }

        /// <summary>Confronto lasco PHP <c>==</c> tra due valori letti da PostgreSQL.</summary>
        private static bool PhpUgualeLasco(string? a, string? b)
        {
            if (a != null && b != null && _numeroCompleto.IsMatch(a) && _numeroCompleto.IsMatch(b))
            {
                return PhpFloat(a) == PhpFloat(b);
            }
            return (a ?? "") == (b ?? "");
        }

        /// <summary>Toglie dai codici usati nei pattern di ricerca file i caratteri jolly; null se contengono percorsi.</summary>
        private static string? PatternSicuro(string s)
        {
            if (s.Contains('\\') || s.Contains('/') || s.Contains("..")) return null;
            return s.Replace("*", "").Replace("?", "");
        }

        /// <summary>storage.Elenca con pattern costruito dal codice articolo; vuoto se il pattern non è valido.</summary>
        private static List<string> ElencaFile(StorageTool storage, string cartella, string pattern)
        {
            if (pattern.Contains('\\') || pattern.Contains('/') || pattern.Contains("..") || pattern.Count(c => c == '?') > 0)
            {
                return new List<string>();
            }
            try
            {
                return storage.Elenca(cartella, pattern);
            }
            catch (ArgumentException)
            {
                return new List<string>();
            }
        }

        private static bool EsisteFile(StorageTool storage, string cartella, string nome)
        {
            try
            {
                return storage.Esiste(cartella, nome);
            }
            catch (MobileException)
            {
                // Nome non valido per il file system (caratteri speciali nel codice articolo).
                return false;
            }
        }

        private static void EliminaFile(StorageTool storage, string cartella, string nome)
        {
            try
            {
                storage.Elimina(cartella, nome);
            }
            catch (MobileException)
            {
                // Nome non valido: il file non può esistere.
            }
        }

        /// <summary>
        /// Scrive un valore nella cella come faceva PhpSpreadsheet (stringhe numeriche → numeri) con lo stile del PHP:
        /// centrato, e in grassetto con bordo sottile per l'intestazione.
        /// </summary>
        private static void ScriviCella(IXLCell cella, JsonElement? valore, bool ucwords, bool intestazione)
        {
            if (valore is { } v)
            {
                switch (v.ValueKind)
                {
                    case JsonValueKind.Number:
                        cella.Value = v.GetDouble();
                        break;
                    case JsonValueKind.String:
                        var s = v.GetString() ?? "";
                        if (ucwords)
                        {
                            s = Regex.Replace(s, @"(^|[ \t\r\n\f\v])(\S)", m => m.Groups[1].Value + m.Groups[2].Value.ToUpperInvariant());
                        }
                        if (_numeroCompleto.IsMatch(s) && !(s.Trim().Length > 1 && s.Trim()[0] == '0' && s.Trim()[1] != '.'))
                        {
                            cella.Value = PhpFloat(s);
                        }
                        else
                        {
                            cella.Value = s;
                        }
                        break;
                    case JsonValueKind.True:
                    case JsonValueKind.False:
                        cella.Value = v.GetBoolean();
                        break;
                    case JsonValueKind.Null:
                    case JsonValueKind.Undefined:
                        break;
                    default:
                        cella.Value = v.GetRawText();
                        break;
                }
            }

            cella.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
            if (intestazione)
            {
                cella.Style.Font.Bold = true;
                cella.Style.Border.OutsideBorder = XLBorderStyleValues.Thin;
                cella.Style.Border.OutsideBorderColor = XLColor.Black;
            }
        }
    }
}
