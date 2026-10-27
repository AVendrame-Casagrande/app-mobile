using System.Data.Odbc;
using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;

namespace CG.MobileAPI.Models
{
    // =================================================================================================================
    // --- Convertitore JSON --------------------------------------------------------------------------------------------
    // =================================================================================================================

    /// <summary>
    /// Legge un valore JSON scalare (stringa, numero, booleano) come stringa, come faceva PHP con i campi di
    /// <c>json_decode</c> interpolati nelle query: le righe delle liste di pre-carico arrivano con le quantità numeriche.
    /// </summary>
    public class ProduzioneStringaFlessibileConverter : JsonConverter<string?>
    {
        /// <inheritdoc/>
        public override bool HandleNull => true;

        /// <inheritdoc/>
        public override string? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            switch (reader.TokenType)
            {
                case JsonTokenType.String:
                    return reader.GetString();
                case JsonTokenType.Number:
                    using (var numero = JsonDocument.ParseValue(ref reader))
                    {
                        return numero.RootElement.GetRawText();
                    }
                case JsonTokenType.True:
                    return "1";
                case JsonTokenType.False:
                    return "";
                case JsonTokenType.Null:
                    return null;
                default:
                    reader.Skip();
                    return null;
            }
        }

        /// <inheritdoc/>
        public override void Write(Utf8JsonWriter writer, string? value, JsonSerializerOptions options)
        {
            if (value == null) writer.WriteNullValue();
            else writer.WriteStringValue(value);
        }
    }

    // =================================================================================================================
    // --- Richieste ----------------------------------------------------------------------------------------------------
    // =================================================================================================================

    /// <summary>Richiesta di getTipoArticolo.</summary>
    public class GetTipoArticoloRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? codice { get; set; }
    }

    /// <summary>Richiesta di UpdateSOSACPN (impegno su Diapason).</summary>
    public class UpdateSosacpnRequest
    {
        /// <summary>Parametri di ConSOSACPN.exe: "ambiente funzione odl articolo fase [qta]" (es. "P ADD 123 ART 0027 5").</summary>
        public string? parametri { get; set; }
    }

    /// <summary>Richiesta di addArticoliImpegnoOdl.</summary>
    public class AddArticoliImpegnoOdlRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
        /// <summary>Magazzino (inviato dal client ma non usato, come nel PHP).</summary>
        public string? magazzino { get; set; }
    }

    /// <summary>Richiesta di checkImpegnoGiacenzaArticolo.</summary>
    public class CheckImpegnoGiacenzaArticoloRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? codiceArticolo { get; set; }
    }

    /// <summary>Richiesta di confirmDeleteQualita.</summary>
    public class ConfirmDeleteQualitaRequest
    {
        /// <summary>Articolo (codice R).</summary>
        public string? articolo { get; set; }
        /// <summary>Numero bolla.</summary>
        public string? bolla { get; set; }
        /// <summary>Nome della foto (senza estensione).</summary>
        public string? url_foto { get; set; }
        /// <summary>'confirm' oppure 'delete'.</summary>
        public string? action { get; set; }
        /// <summary>Ignorato: l'utente che conferma è quello del token.</summary>
        public string? utente_conferma { get; set; }
    }

    /// <summary>Chiave di una lista di pre-carico (odl, fase, sequenza).</summary>
    public class ListaPrecaricoKeyRequest
    {
        /// <summary>Numero ODL.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? fase { get; set; }
        /// <summary>Sequenza della lista.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? sequenza { get; set; }
    }

    /// <summary>Richiesta di getListaNonni.</summary>
    public class GetListaNonniRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
    }

    /// <summary>Richiesta di getPrestazioniMagazzino.</summary>
    public class GetPrestazioniMagazzinoRequest
    {
        /// <summary>Magazzino.</summary>
        public string? magazzino { get; set; }
    }

    /// <summary>Richiesta di getQualitaArrivi.</summary>
    public class GetQualitaArriviRequest
    {
        /// <summary>Società (default CSPRO).</summary>
        public string? societa { get; set; }
        /// <summary>Inizio del codice articolo.</summary>
        public string? art { get; set; }
        /// <summary>Parte della ragione sociale del fornitore.</summary>
        public string? ragSoc { get; set; }
        /// <summary>Data di arrivo (yyyyMMdd).</summary>
        public string? dataArr { get; set; }
    }

    /// <summary>Richiesta di getStoriaPrecarico (l'utente è quello del token).</summary>
    public class GetStoriaPrecaricoRequest
    {
        /// <summary>Ignorato: si usa il codice dell'utente autenticato.</summary>
        public string? utente { get; set; }
    }

    /// <summary>Riga di una lista di pre-carico inviata dal client (upload/modifica).</summary>
    public class RigaListaPrecaricoRequest
    {
        /// <summary>Articolo.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? articolo { get; set; }
        /// <summary>Descrizione articolo.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? descrizione { get; set; }
        /// <summary>Unità di misura.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? um { get; set; }
        /// <summary>Quantità.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? qta { get; set; }
        /// <summary>Quantità ENX.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? qta_enx { get; set; }
        /// <summary>Nota.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? nota { get; set; }
    }

    /// <summary>Richiesta di modifyListaPrecarico.</summary>
    public class ModifyListaPrecaricoRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
        /// <summary>Sequenza della lista.</summary>
        public string? sequenza { get; set; }
        /// <summary>Nuove righe della lista.</summary>
        public List<RigaListaPrecaricoRequest>? newListaPrecarico { get; set; }
    }

    /// <summary>Richiesta di returnMagazzinoFromImpegnoOdl.</summary>
    public class ReturnMagazzinoFromImpegnoOdlRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
    }

    /// <summary>Richiesta di selectImpegniOdl (le fasi visibili dipendono dall'utente del token).</summary>
    public class SelectImpegniOdlRequest
    {
        /// <summary>ODL, articolo padre o magazzino da cercare.</summary>
        public string? codiceOdl_Padre_Mag { get; set; }
        /// <summary>Fase (vuota = fasi abilitate per l'utente).</summary>
        public string? fase { get; set; }
        /// <summary>Ignorato: si usa il codice dell'utente autenticato.</summary>
        public string? utente { get; set; }
    }

    /// <summary>Richiesta di selectSituazioneCheckOdl.</summary>
    public class SelectSituazioneCheckOdlRequest
    {
        /// <summary>Parte del numero ODL o dell'articolo padre.</summary>
        public string? odl_padre { get; set; }
    }

    /// <summary>Richiesta di selectSituazioneOdl.</summary>
    public class SelectSituazioneOdlRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
    }

    /// <summary>Richiesta di sendImpegniEmail.</summary>
    public class SendImpegniEmailRequest
    {
        /// <summary>Destinatario (può essere vuoto: allora la mail va solo ai destinatari fissi).</summary>
        public string? emailTarget { get; set; }
        /// <summary>Titolo.</summary>
        public string? titolo { get; set; }
        /// <summary>Messaggio HTML.</summary>
        public string? messaggio { get; set; }
        /// <summary>Nome e cognome dell'utente (aggiunto all'oggetto).</summary>
        public string? nomeUtente { get; set; }
    }

    /// <summary>Riga caricata dal magazzino (updateListaPrecarico).</summary>
    public class RigaCaricoPrecaricoRequest
    {
        /// <summary>Numero ODL della lista.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? odl { get; set; }
        /// <summary>Fase della lista.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? fase { get; set; }
        /// <summary>Sequenza della lista.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? sequenza { get; set; }
        /// <summary>Articolo.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? articolo { get; set; }
        /// <summary>Descrizione articolo.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? descrizione { get; set; }
        /// <summary>Unità di misura.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? umis { get; set; }
        /// <summary>Quantità caricata.</summary>
        [JsonConverter(typeof(ProduzioneStringaFlessibileConverter))]
        public string? qta { get; set; }
    }

    /// <summary>Richiesta di updateListaPrecarico (l'utente di completamento è quello del token).</summary>
    public class UpdateListaPrecaricoRequest
    {
        /// <summary>Righe caricate (di una o più liste).</summary>
        public List<RigaCaricoPrecaricoRequest>? righe { get; set; }
        /// <summary>Liste di pre-carico da completare.</summary>
        public List<ListaPrecaricoKeyRequest>? liste_precarico { get; set; }
        /// <summary>Ignorato: si usa il codice dell'utente autenticato.</summary>
        public string? utente { get; set; }
    }

    /// <summary>Richiesta di updateListaPrecaricoSegnaComeRevisionata.</summary>
    public class UpdateListaPrecaricoSegnaComeRevisionataRequest
    {
        /// <summary>Id della testata.</summary>
        public string? id { get; set; }
    }

    /// <summary>Richiesta di uploadFotoPallinatura (multipart).</summary>
    public class UploadFotoPallinaturaRequest
    {
        /// <summary>Foto.</summary>
        public IFormFile? file { get; set; }
        /// <summary>Nome del file senza estensione.</summary>
        public string? name { get; set; }
        /// <summary>Ignorato: la cartella è quella del nome portale dell'utente del token.</summary>
        public string? nome_utente { get; set; }
    }

    /// <summary>Richiesta di uploadFotoQualita (multipart).</summary>
    public class UploadFotoQualitaRequest
    {
        /// <summary>Foto.</summary>
        public IFormFile? file { get; set; }
        /// <summary>Nome del file senza estensione (articolo_bolla).</summary>
        public string? name { get; set; }
    }

    /// <summary>Richiesta di uploadListaPrecarico (l'utente di creazione è quello del token).</summary>
    public class UploadListaPrecaricoRequest
    {
        /// <summary>Ignorato: si usa il codice dell'utente autenticato.</summary>
        public string? utente { get; set; }
        /// <summary>Numero ODL (o 'PRE-CARICO').</summary>
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
        /// <summary>Magazzino.</summary>
        public string? magazzino { get; set; }
        /// <summary>Articolo padre.</summary>
        public string? padre { get; set; }
        /// <summary>Descrizione del padre.</summary>
        public string? padre_descrizione { get; set; }
        /// <summary>Righe della lista.</summary>
        public List<RigaListaPrecaricoRequest>? listaPrecarico { get; set; }
    }

    /// <summary>Richiesta di writeInserimentoFase0027 / deleteInserimentoFase0027.</summary>
    public class InserimentoFase0027Request
    {
        /// <summary>Articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Articolo padre.</summary>
        public string? padre { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
        /// <summary>Magazzino.</summary>
        public string? magazzino { get; set; }
        /// <summary>Responsabile dell'impegno.</summary>
        public string? responsabile { get; set; }
        /// <summary>Quantità impegnata.</summary>
        public string? qta { get; set; }
    }

    // =================================================================================================================
    // --- Accesso ai dati ----------------------------------------------------------------------------------------------
    // =================================================================================================================

    /// <summary>
    /// Accesso ai dati per produzione, impegno ODL, pre-carico e qualità.
    /// </summary>
    public class DBPRODUZIONE
    {
        /// <summary>Destinatari fissi (ex addBCC) degli alert delle fasi 0027.</summary>
        public static readonly string[] DestinatariFissiImpegni =
        {
            "r.pizzinat@casagrandegroup.com",
            "v.favaro@casagrandegroup.com",
            "m.demarchi@casagrandegroup.com",
            "m.mucignat@casagrandegroup.com",
            "e.celant@casagrandegroup.com"
        };

        /// <summary>Cartella delle foto qualità (relativa alla root del web server).</summary>
        public const string CARTELLA_FOTO_QUALITA = "mobile/server/storage/qualita_foto";

        /// <summary>Cartella delle foto di pallinatura (una sottocartella per nome portale).</summary>
        public const string CARTELLA_PALLINATURA = "mobile/server/storage/pallinatura";

        private static readonly Regex _parametriSosacpn =
            new(@"^[PT] (ADD|REP|DEL) \S{1,30} \S{1,40} \S{1,10}( -?[0-9]+([.,][0-9]+)?([eE][-+]?[0-9]+)?)?$");

        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBPRODUZIONE"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBPRODUZIONE(MobileConnections conn)
        {
            _conn = conn;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Impegno ODL ---------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Tipo articolo (MTYPN) da DBSAITE (ex casagrande-app-web/getTipoArticolo.php).
        /// Restituisce <c>{tipoArticolo}</c> oppure <c>{error: "Nessun risultato"}</c>.
        /// </summary>
        public Dictionary<string, object?> GetTipoArticolo(string? codice)
        {
            var row = DbHelper.QueryFirst(_conn.Db2,
                "SELECT MTYPN FROM D60STDDB.DBSAITE WHERE MITEM = ? AND MCOSC = 'CSPRO'",
                codice ?? "");
            if (row == null)
            {
                return new Dictionary<string, object?> { ["error"] = "Nessun risultato" };
            }
            return new Dictionary<string, object?> { ["tipoArticolo"] = T(row["MTYPN"]) };
        }

        /// <summary>
        /// Controlla che i parametri di UpdateSOSACPN abbiano la forma usata dall'app
        /// ("P|T ADD|REP|DEL odl articolo fase [qta]"), così il servizio non può essere usato per comandi arbitrari.
        /// </summary>
        public static string ValidaParametriSosacpn(string? parametri)
        {
            var p = (parametri ?? "").Trim();
            var m = _parametriSosacpn.Match(p);
            if (!m.Success)
            {
                throw new MobileException("Parametri non validi");
            }
            var conQta = m.Groups[2].Success;
            if (m.Groups[1].Value == "DEL" ? conQta : !conQta)
            {
                throw new MobileException("Parametri non validi");
            }
            return p;
        }

        /// <summary>
        /// Articoli già impegnati sull'ODL nella fase (ex query/produzione/addArticoliImpegnoOdl.php).
        /// </summary>
        public List<Dictionary<string, object?>> AddArticoliImpegnoOdl(AddArticoliImpegnoOdlRequest request)
        {
            const string query = @"SELECT D60STDDB.SOSACPN.SOCPKEY, D60STDDB.SOSACPN.SOCRQTY*0.01 AS QTA, D60STDDB.SOSAVPN.VPNMAOP AS FASE, D60STDDB.DBSAITE.MPDSC AS DESCRIZIONE, D60STDDB.DBSAITE.MUTMS AS UM
FROM D60STDDB.SOSACPN
FULL JOIN D60STDDB.SOSAVPN ON D60STDDB.SOSAVPN.VPNMAOP = D60STDDB.SOSACPN.SOCMAOP AND D60STDDB.SOSACPN.VRTSOC = D60STDDB.SOSAVPN.VRTSOC AND D60STDDB.SOSACPN.VRTORNO = D60STDDB.SOSAVPN.VRTORNO
FULL JOIN D60STDDB.SOSAVRT ON D60STDDB.SOSAVPN.VRTSOC = D60STDDB.SOSAVRT.VRTSOC AND D60STDDB.SOSAVPN.VRTORNO = D60STDDB.SOSAVRT.VRTORNO
FULL JOIN D60STDDB.DBSAITE ON D60STDDB.DBSAITE.MITEM = D60STDDB.SOSACPN.SOCPKEY AND D60STDDB.DBSAITE.MCOSC = D60STDDB.SOSAVRT.VRTSOC
WHERE D60STDDB.SOSAVPN.VRTORNO=? AND D60STDDB.SOSAVPN.VPNMAOP=? AND D60STDDB.SOSAVPN.VPNSTAT<'90' AND D60STDDB.SOSAVRT.VRTSTAT>'10' AND D60STDDB.SOSAVRT.VRTSTAT<'90' AND D60STDDB.SOSAVPN.VRTSOC='CSPRO'
ORDER BY D60STDDB.SOSAVPN.VPNMAOP, D60STDDB.SOSACPN.SOCPKEY";

            var lista = new List<Dictionary<string, object?>>();
            foreach (var row in DbHelper.Query(_conn.Db2, query, request.odl ?? "", request.fase ?? ""))
            {
                var articolo = T(row["SOCPKEY"]);
                if (articolo == "") continue;

                lista.Add(new Dictionary<string, object?>
                {
                    ["codice"] = articolo,
                    ["qta"] = F(row["QTA"]),
                    ["fase"] = T(row["FASE"]),
                    ["descrizione"] = T(row["DESCRIZIONE"]),
                    ["um"] = T(row["UM"])
                });
            }
            return lista;
        }

        /// <summary>
        /// Disponibilità dell'articolo nei magazzini MGAUT00, MGAUT10 e MISK* (ex query/produzione/checkImpegnoGiacenzaArticolo.php).
        /// </summary>
        public List<Dictionary<string, object?>> CheckImpegnoGiacenzaArticolo(string? codiceArticolo)
        {
            const string query = @"SELECT
D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALOHQT/100 AS GIACENTE, D60STDDB.MASAMSL.MALLLQT/100 AS IMPEGNATO
FROM D60STDDB.MASAMSL
FULL JOIN D60STDDB.DBSAITE ON D60STDDB.DBSAITE.MITEM = D60STDDB.MASAMSL.MALITEM AND D60STDDB.DBSAITE.MCOSC = D60STDDB.MASAMSL.MAHCOSC
WHERE D60STDDB.DBSAITE.MITEM=?
AND (D60STDDB.MASAMSL.MLLOC='MGAUT00' OR D60STDDB.MASAMSL.MLLOC='MGAUT10' OR D60STDDB.MASAMSL.MLLOC LIKE 'MISK%')
GROUP BY D60STDDB.MASAMSL.MLLOC, D60STDDB.MASAMSL.MALLOC, D60STDDB.MASAMSL.MALOHQT, D60STDDB.MASAMSL.MALLLQT
ORDER BY D60STDDB.MASAMSL.MLLOC,D60STDDB.MASAMSL.MALLOC";

            return DbHelper.Query(_conn.Db2, query, codiceArticolo ?? "")
                .Select(row => new Dictionary<string, object?>
                {
                    ["magazzino"] = T(row["MLLOC"]),
                    ["vano"] = T(row["MALLOC"]),
                    ["disponibile"] = F(row["GIACENTE"]) - F(row["IMPEGNATO"])
                })
                .ToList();
        }

        /// <summary>
        /// Magazzino di destinazione dell'ODL nella fase, 'Nessuno' se non c'è (ex query/produzione/returnMagazzinoFromImpegnoOdl.php).
        /// </summary>
        public string ReturnMagazzinoFromImpegnoOdl(ReturnMagazzinoFromImpegnoOdlRequest request)
        {
            const string query = @"SELECT DISTINCT D60STDDB.SOSACPN.SOCDLOC
FROM D60STDDB.SOSACPN
FULL JOIN D60STDDB.SOSAVPN ON D60STDDB.SOSAVPN.VPNMAOP = D60STDDB.SOSACPN.SOCMAOP AND D60STDDB.SOSACPN.VRTSOC = D60STDDB.SOSAVPN.VRTSOC AND D60STDDB.SOSACPN.VRTORNO = D60STDDB.SOSAVPN.VRTORNO
WHERE D60STDDB.SOSACPN.SOCDLOC IS NOT NULL AND D60STDDB.SOSACPN.SOCDLOC != '' AND D60STDDB.SOSAVPN.VPNMAOP=? AND D60STDDB.SOSAVPN.VRTORNO=? AND D60STDDB.SOSAVPN.VRTSOC='CSPRO' LIMIT 1";

            var magazzino = "Nessuno";
            foreach (var row in DbHelper.Query(_conn.Db2, query, request.fase ?? "", request.odl ?? ""))
            {
                magazzino = T(row["SOCDLOC"]);
            }
            return magazzino;
        }

        /// <summary>
        /// ODL/fasi su cui l'utente può impegnare, cercando il codice come ODL, poi come padre, poi come magazzino
        /// (ex query/produzione/selectImpegniOdl.php). Le fasi visibili dipendono dal codice utente.
        /// </summary>
        public List<Dictionary<string, object?>> SelectImpegniOdl(string? codiceOdlPadreMag, string? fase, string utente)
        {
            var codice = codiceOdlPadreMag ?? "";
            var lista = GetListaImpegniOdl(codice, "odl", fase ?? "", utente);
            if (lista.Count == 0)
            {
                lista = GetListaImpegniOdl(codice, "Padre", fase ?? "", utente);
            }
            if (lista.Count == 0)
            {
                lista = GetListaImpegniOdl(codice, "Magazzino", fase ?? "", utente);
            }
            return lista;
        }

        private List<Dictionary<string, object?>> GetListaImpegniOdl(string codice, string tipoCodice, string fase, string utente)
        {
            var whereQuery = tipoCodice switch
            {
                "odl" => "AND D60STDDB.SOSAVPN.VRTORNO=?",
                "Padre" => "AND D60STDDB.SOSAVRT.VRTITEM=?",
                _ => "AND D60STDDB.SOSACPN.SOCDLOC=?"
            };

            var valori = new List<object?>();

            // Tutti gli utenti hanno accesso solo alla Fase 0027
            var whereFase = "D60STDDB.SOSAVPN.VPNMAOP='0027'";
            var prefisso = utente.Length >= 3 ? utente.Substring(0, 3) : utente;

            if (utente == "CPR011" || utente == "CAM015" || utente == "CAP" || utente == "CAP001" || prefisso == "CMA" || prefisso == "CTM")
            {
                whereFase = "(D60STDDB.SOSAVPN.VPNMAOP='0027' OR D60STDDB.SOSAVPN.VPNMAOP='0065' OR D60STDDB.SOSAVPN.VPNMAOP='0066' OR D60STDDB.SOSAVPN.VPNMAOP='0067' OR D60STDDB.SOSAVPN.VPNMAOP='0068' OR D60STDDB.SOSAVPN.VPNMAOP='0069' OR D60STDDB.SOSAVPN.VPNMAOP LIKE '003%')";
            }
            else if (utente == "CPR010" || utente == "CPR026" || utente == "CPR017")
            {
                // Fabbro, Cattaruzza e da Pieve hanno accesso anche alla 0065 (e simili)
                whereFase = "(D60STDDB.SOSAVPN.VPNMAOP='0027' OR D60STDDB.SOSAVPN.VPNMAOP='0065' OR D60STDDB.SOSAVPN.VPNMAOP='0066' OR D60STDDB.SOSAVPN.VPNMAOP='0067' OR D60STDDB.SOSAVPN.VPNMAOP='0068' OR D60STDDB.SOSAVPN.VPNMAOP='0069')";
            }
            else if (utente == "CPR013")
            {
                // Solo il CPR013 accede alla 003x (materiale elettrico) e solo a quella
                whereFase = "D60STDDB.SOSAVPN.VPNMAOP LIKE '003%'";
            }

            if (fase != "")
            {
                whereFase = "D60STDDB.SOSAVPN.VPNMAOP=?";
                valori.Add(fase);
            }
            valori.Add(codice);

            var query = $@"SELECT DISTINCT D60STDDB.SOSAVPN.VRTORNO, D60STDDB.SOSAVRT.VRTITEM, D60STDDB.SOSAVPN.VPNMAOP, D60STDDB.SOSAVPN.VPNDESC, D60STDDB.SOSAVPN.VPNSTAT, D60STDDB.SOSAVRT.VRTPDSC, D60STDDB.SOSAVRT.VRTRESP, D60STDDB.SOSAVRT.VRTSTAT, D60STDDB.SOSAVRT.VRTRESP,
	COALESCE(D60STDDB.SOSACPN.SOCDLOC, D60STDDB.RESABRT.BRTPHLI) SOCDLOC, COALESCE(D60STDDB.SOSACPN.SOCDLOC, D60STDDB.RESABRT.BRTPHLI) SOCDLOC
    FROM D60STDDB.SOSACPN
    FULL JOIN D60STDDB.SOSAVPN ON D60STDDB.SOSAVPN.VPNMAOP = D60STDDB.SOSACPN.SOCMAOP AND D60STDDB.SOSACPN.VRTSOC = D60STDDB.SOSAVPN.VRTSOC AND D60STDDB.SOSACPN.VRTORNO = D60STDDB.SOSAVPN.VRTORNO
    FULL JOIN D60STDDB.SOSAVRT ON D60STDDB.SOSAVPN.VRTSOC = D60STDDB.SOSAVRT.VRTSOC AND D60STDDB.SOSAVPN.VRTORNO = D60STDDB.SOSAVRT.VRTORNO
	FULL JOIN D60STDDB.RESABRT ON RESABRT.BRTSOC=SOSAVPN.VRTSOC AND RESABRT.BRTBKEY=SOSAVPN.VPNPCNO
    WHERE {whereFase} AND D60STDDB.SOSAVPN.VPNSTAT<'90' AND D60STDDB.SOSAVRT.VRTSTAT>'10' AND D60STDDB.SOSAVRT.VRTSTAT<'90' AND D60STDDB.SOSAVPN.VRTSOC='CSPRO' {whereQuery}
    ORDER BY D60STDDB.SOSAVPN.VRTORNO,D60STDDB.SOSAVPN.VPNMAOP";

            return DbHelper.Query(_conn.Db2, query, valori.ToArray())
                .Select(row => new Dictionary<string, object?>
                {
                    ["odl"] = T(row["VRTORNO"]),
                    ["padre"] = T(row["VRTITEM"]),
                    ["mag_des"] = T(row["SOCDLOC"]),
                    ["desc_padre"] = T(row["VRTPDSC"]),
                    ["fase"] = T(row["VPNMAOP"]),
                    ["desc_fase"] = T(row["VPNDESC"]),
                    ["responsabile"] = T(row["VRTRESP"]),
                    ["tipoRicerca"] = tipoCodice
                })
                .ToList();
        }

        /// <summary>
        /// Oggetto ("titolo (nomeUtente)") della mail di impegno (ex query/produzione/sendImpegniEmail.php).
        /// </summary>
        public static string OggettoEmailImpegni(SendImpegniEmailRequest request) => $"{request.titolo} ({request.nomeUtente})";

        // -------------------------------------------------------------------------------------------------------------
        // --- Permessi ------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Sezioni di produzione abilitate per l'utente (ex query/produzione/checkPermessiSezioniProduzione.php).
        /// </summary>
        public static Dictionary<string, object?> CheckPermessiSezioniProduzione(string utente)
        {
            return new Dictionary<string, object?>
            {
                // de Marchi / Fabbro / Mucignat / Cattaruzza
                ["pre_carico"] = utente == "CPR006" || utente == "CPR010" || utente == "CPR011" || utente == "CPR026",
                // T.Perin ed E.Cattaruzza
                ["pallinatura"] = utente == "CPR009" || utente == "CPR026"
            };
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Situazione ODL ------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// ODL di primo livello (nonni) dell'ODL (ex query/produzione/getListaNonni.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetListaNonni(string? odl)
        {
            const string query = @"select cs_fabbmanc_odl_odl1liv.num1liv as odl, cs_fabbmanc_odl.articolo as padre, cs_fabbmanc_odl.descarticolo as descpadre from cs_fabbmanc_odl_odl1liv
inner join cs_fabbmanc_odl on cs_fabbmanc_odl_odl1liv.num1liv = cs_fabbmanc_odl.numero
where cs_fabbmanc_odl_odl1liv.numero=?";

            return DbHelper.Query(_conn.PgCasagrande, query, odl ?? "")
                .Select(row => new Dictionary<string, object?>
                {
                    ["odl"] = row["odl"],
                    ["padre"] = row["padre"],
                    ["descPadre"] = row["descpadre"]
                })
                .ToList();
        }

        /// <summary>
        /// ODL con componenti critici il cui numero o articolo padre contiene il testo (ex query/produzione/selectSituazioneCheckOdl.php).
        /// </summary>
        public List<Dictionary<string, object?>> SelectSituazioneCheckOdl(string? odlPadre)
        {
            const string query = @"SELECT distinct cs_fabbmanc_odl_comp.numero, cs_fabbmanc_odl.duedate
FROM cs_fabbmanc_odl
INNER JOIN cs_fabbmanc_odl_comp ON cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero AND cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa
WHERE (cs_fabbmanc_odl.articolo LIKE ? OR cs_fabbmanc_odl_comp.numero LIKE ?) AND cs_fabbmanc_odl_comp.iscritico='1' AND cs_fabbmanc_odl_comp.tipoarticolo<>'N'
ORDER BY cs_fabbmanc_odl.duedate asc";

            var like = "%" + (odlPadre ?? "") + "%";
            return DbHelper.Query(_conn.PgCasagrande, query, like, like)
                .Select(row => new Dictionary<string, object?>
                {
                    ["odl"] = row["numero"],
                    ["scadenza"] = row["duedate"]
                })
                .ToList();
        }

        /// <summary>
        /// Situazione dei componenti critici dell'ODL, con note e data di conferma dell'OdA (ex query/produzione/selectSituazioneOdl.php).
        /// </summary>
        public List<Dictionary<string, object?>> SelectSituazioneOdl(string? odl)
        {
            const string query = @"SELECT cs_fabbmanc_odl_comp.tipoarticolo, cs_fabbmanc_odl_comp.numero, cs_fabbmanc_odl_comp.magazzino, cs_fabbmanc_odl_comp.articolo, cs_fabbmanc_odl_comp.fase, cs_fabbmanc_odl_comp.stato, cs_fabbmanc_odl_comp.fabbdate, cs_fabbmanc_odl_comp.statopick, cs_fabbmanc_odl_comp.descarticolo, cs_fabbmanc_odl_comp.qtares , cs_fabbmanc_odl_comp.giacmag,
cs_fabbmanc_odl_dispo.magdispo, cs_fabbmanc_odl_comp.umis, cs_fabbmanc_odl.articolo as padre, cs_fabbmanc_odl.descarticolo as descpadre, cs_fabbmanc_odl.qtares as qtarespadre, cs_fabbmanc_odl.stato as statopadre, cs_odaschedule.psdesdt, cs_fabbmanc_odl_comp_impsoda.numsoda, cs_fabbmanc_odl_comp_impsoda.statosoda, cs_soggetti.aninco,
cs_fabbmanc_odl_dispo.giacdispo, cs_fabbmanc_odl_comp_impsoda.qtaimp, cs_fabbmanc_odl_comp.qtaiodl, cs_fabbmanc_odl_comp_impodl.numodl, cs_fabbmanc_odl2.duedate, cs_fabbmanc_odl_comp.giactransit,
cs_odaschedule.pslino, cs_odaschedule.psordln, cs_odaschedule.psordno, cs_fabbmanc_odl_stransfer.magto as magdispotransit
FROM cs_fabbmanc_odl
INNER JOIN cs_fabbmanc_odl_comp ON cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero AND cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa
LEFT JOIN cs_fabbmanc_odl_comp_impsoda ON cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_odl_comp_impsoda.articolo AND cs_fabbmanc_odl_comp.numero = cs_fabbmanc_odl_comp_impsoda.numero AND cs_fabbmanc_odl_comp.societa = cs_fabbmanc_odl_comp_impsoda.societa
LEFT JOIN cs_odaschedule ON cs_fabbmanc_odl_comp_impsoda.societa = cs_odaschedule.pscosc AND cs_fabbmanc_odl_comp_impsoda.schedsoda = cs_odaschedule.pslino AND cs_fabbmanc_odl_comp_impsoda.possoda = cs_odaschedule.psordln AND cs_fabbmanc_odl_comp_impsoda.numsoda = cs_odaschedule.psordno
LEFT JOIN cs_fabbmanc_odl_comp_impodl ON cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp_impodl.societa AND cs_fabbmanc_odl_comp_impodl.numero = cs_fabbmanc_odl_comp.numero and cs_fabbmanc_odl_comp_impodl.articolo = cs_fabbmanc_odl_comp.articolo
LEFT JOIN cs_fabbmanc_odl_dispo ON cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_odl_dispo.articolo AND cs_fabbmanc_odl_comp.magazzino = cs_fabbmanc_odl_dispo.magazzino AND cs_fabbmanc_odl_comp.numero = cs_fabbmanc_odl_dispo.numero AND cs_fabbmanc_odl_comp.societa = cs_fabbmanc_odl_dispo.societa
LEFT JOIN cs_soggetti ON cs_odaschedule.pscosc = cs_soggetti.ancoso AND cs_odaschedule.pssupno = cs_soggetti.ancoco
LEFT JOIN cs_fabbmanc_odl as cs_fabbmanc_odl2 ON cs_fabbmanc_odl_comp_impodl.numodl = cs_fabbmanc_odl2.numero
LEFT JOIN cs_fabbmanc_odl_stransfer on cs_fabbmanc_odl.numero = cs_fabbmanc_odl_stransfer.numero and cs_fabbmanc_odl_comp.fase = cs_fabbmanc_odl_stransfer.fasecodl and cs_fabbmanc_odl_comp.stato = cs_fabbmanc_odl_stransfer.statocodl and cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_odl_stransfer.articolo
WHERE cs_fabbmanc_odl_comp.numero=? AND cs_fabbmanc_odl_comp.iscritico='1' AND cs_fabbmanc_odl_comp.tipoarticolo<>'N' AND cs_fabbmanc_odl_comp.tipoarticolo<>'D'
ORDER BY cs_fabbmanc_odl_comp.numero, cs_fabbmanc_odl_comp.fase, cs_fabbmanc_odl_comp.articolo";

            const string queryRisposta = @"SELECT cs_fabbmanc_risp_soda2.dtconf, cs_fabbmanc_risp_soda2.note
        FROM cs_fabbmanc_risp_soda2
        WHERE cs_fabbmanc_risp_soda2.societa='CSPRO' AND cs_fabbmanc_risp_soda2.sched=? AND cs_fabbmanc_risp_soda2.pos=? AND cs_fabbmanc_risp_soda2.numero=?";

            using var conn = new OdbcConnection(_conn.PgCasagrande);
            conn.Open();

            var lista = new List<Dictionary<string, object?>>();
            foreach (var row in DbHelper.Query(conn, null, query, odl ?? ""))
            {
                // Note e data di conferma della risposta all'OdA (vince l'ultima riga, come nel PHP)
                object? dtconf = "";
                object? note = "";
                foreach (var risp in DbHelper.Query(conn, null, queryRisposta,
                             (decimal)F(row["pslino"]), (decimal)F(row["psordln"]), S(row["psordno"])))
                {
                    dtconf = risp["dtconf"];
                    note = risp["note"];
                }

                lista.Add(new Dictionary<string, object?>
                {
                    ["odl"] = row["numero"],
                    ["magazzino"] = row["magazzino"],
                    ["articolo"] = row["articolo"],
                    ["fase"] = row["fase"],
                    ["stato"] = row["stato"],
                    ["dataPadre"] = F(row["fabbdate"]),
                    ["statoPick"] = row["statopick"],
                    ["descArticolo"] = row["descarticolo"],
                    ["qtaRes"] = F(row["qtares"]),
                    ["giacMagazzino"] = F(row["giacmag"]),
                    ["giacDispo"] = F(row["giacdispo"]),
                    ["magazzinoDispo"] = row["magdispo"],
                    ["magazzinoTransitoDispo"] = row["magdispotransit"],
                    ["inTransito"] = F(row["giactransit"]),
                    ["um"] = row["umis"],
                    ["padre"] = row["padre"],
                    ["descPadre"] = row["descpadre"],
                    ["qtaResPadre"] = F(row["qtarespadre"]),
                    ["statoPadre"] = row["statopadre"],
                    ["dataOrdine"] = F(row["psdesdt"]),
                    ["oda"] = row["numsoda"],
                    ["statosoda"] = row["statosoda"],
                    ["odaImp"] = F(row["qtaimp"]),
                    ["odlImp"] = F(row["qtaiodl"]),
                    ["odlFiglio"] = row["numodl"],
                    ["dataOdlFiglio"] = F(row["duedate"]),
                    ["fornitore"] = row["aninco"],
                    ["note"] = note,
                    ["dtconf"] = dtconf,
                    ["tipoarticolo"] = row["tipoarticolo"]
                });
            }
            return lista;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Prestazioni ---------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Magazzini con inserimenti fase 0027 completati nell'ultimo mese (ex query/produzione/getMagazziniPrestazioniSelect.php).
        /// </summary>
        public List<object?> GetMagazziniPrestazioniSelect()
        {
            return DbHelper.Query(_conn.PgDb1,
                    "select distinct magazzino from inserimenti_fase_0027 where data_inserimento >= ? and data_completamento > 0 order by magazzino",
                    DataUnMeseFa())
                .Select(row => row["magazzino"])
                .ToList();
        }

        /// <summary>
        /// Inserimenti fase 0027 completati nell'ultimo mese nel magazzino (ex query/produzione/getPrestazioniMagazzino.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetPrestazioniMagazzino(string? magazzino)
        {
            return DbHelper.Query(_conn.PgDb1,
                "select articolo, data_inserimento, ora_inserimento, data_completamento, ora_completamento from inserimenti_fase_0027 where data_inserimento >= ? and data_completamento > 0 and magazzino = ?",
                DataUnMeseFa(), magazzino ?? "");
        }

        /// <summary>
        /// Data yyyyMMdd di un mese fa calcolata come nel PHP (-100, a gennaio -8900).
        /// </summary>
        private static int DataUnMeseFa()
        {
            var oggi = DateTime.Now;
            var data = DataIntera(oggi);
            return oggi.Month == 1 ? data - 8900 : data - 100;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Qualità -------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Codici R ricondizionati arrivati nei magazzini MIRC, con lo stato di conferma qualità (ex query/produzione/getQualita.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetQualita()
        {
            // Confermati: per (articolo, bolla) vince l'ultima riga, come nel ciclo del PHP
            var confermati = new Dictionary<(string, string), Dictionary<string, object?>>();
            foreach (var c in DbHelper.Query(_conn.PgDb1, "select * from public.conferme_qualita_codici_r"))
            {
                confermati[(S(c["articolo"]), S(c["bolla"]))] = c;
            }

            const string query = @"SELECT D60STDDB.MASATRN.TDTVER, D60STDDB.MASATRN.TTRAN, D60STDDB.MASATRN.TRDATE, D60STDDB.CSDBITA.CSCOLOR, D60STDDB.MASATRN.TCHNU AS FORN, D60STDDB.MASATRN.TNBOL AS BOLLA, D60STDDB.MASAMSL.MALITEM AS ARTICOLO, D60STDDB.DBSAITE.MPDSC AS DESCRIZIONE, D60STDDB.MASAMSL.MLLOC AS MAGAZZINO, D60STDDB.MASAMSL.MALLOC AS VANO, D60STDDB.MASAMSL.MALOHQT*0.01 AS QTA_GIAC, D60STDDB.MASAMSL.MALDTVE AS DATA_MOV, D60STDDB.MASATRN.TMACO AS TIPO_MOV, D60STDDB.MASATRN.TUSCO AS MOV, D60STDDB.MASATRN.TQUAN/100 AS QTA_MOV, D60STDDB.MASATRN.TORNUOR AS ORDINE, D60STDDB.ANSADID.ANINCO, D60STDDB.DBSAITE.MPALLET/100 AS PESO_LORDO, D60STDDB.DBSAITE.DIPRO, D60STDDB.DBSAITE.MUTMS, D60STDDB.CSDBITA.CSTRASU
FROM D60STDDB.MASATRN
INNER JOIN D60STDDB.DBSAITE ON D60STDDB.DBSAITE.MITEM = D60STDDB.MASATRN.TRNITM AND D60STDDB.DBSAITE.MCOSC = D60STDDB.MASATRN.TRNSOC
INNER JOIN D60STDDB.MASAMSL ON D60STDDB.MASATRN.TMAG = D60STDDB.MASAMSL.MLLOC AND D60STDDB.MASATRN.TRNSOC = D60STDDB.MASAMSL.MAHCOSC AND D60STDDB.MASATRN.TRNITM = D60STDDB.MASAMSL.MALITEM
LEFT JOIN D60STDDB.ANSADID ON D60STDDB.MASATRN.TRNSOC = D60STDDB.ANSADID.ANCOSO AND D60STDDB.MASATRN.TCHNU = D60STDDB.ANSADID.ANCOCO
LEFT JOIN D60STDDB.CSDBITA ON D60STDDB.DBSAITE.MITEM = D60STDDB.CSDBITA.CSITEMA
WHERE D60STDDB.DBSAITE.MITEM LIKE 'R%' AND TRIM(BOTH FROM D60STDDB.MASATRN.TNBOL) != '' AND D60STDDB.MASAMSL.MLLOC LIKE 'MIRC%' AND D60STDDB.MASATRN.TMACO = 'EA'
AND D60STDDB.MASAMSL.MAHCOSC='CSPRO' AND D60STDDB.MASATRN.TRNSOC='CSPRO' AND D60STDDB.DBSAITE.MCOSC='CSPRO' AND D60STDDB.DBSAITE.MCOSC='CSPRO'
ORDER BY D60STDDB.MASAMSL.MALITEM ASC";

            var lista = new List<Dictionary<string, object?>>();
            foreach (var row in DbHelper.Query(_conn.Db2, query))
            {
                var articolo = T(row["ARTICOLO"]);
                var bolla = T(row["BOLLA"]);

                object? id = 0;
                object? urlFoto = "";
                var confermato = false;
                object? utenteConferma = "";
                if (confermati.TryGetValue((articolo, bolla), out var c))
                {
                    id = c["id"];
                    urlFoto = c["url_foto"];
                    confermato = true;
                    utenteConferma = c["utente_conferma"];
                }

                lista.Add(new Dictionary<string, object?>
                {
                    ["articolo"] = articolo,
                    ["codiceDisegno"] = T(row["DIPRO"]),
                    ["pesoLordo"] = F(row["PESO_LORDO"]),
                    ["descrizione"] = T(row["DESCRIZIONE"]),
                    ["magazzino"] = T(row["MAGAZZINO"]),
                    ["vano"] = T(row["VANO"]),
                    ["qtaGiacenza"] = F(row["QTA_GIAC"]),
                    ["dataMovimentoInteger"] = I(row["DATA_MOV"]),
                    ["tipoMovimento"] = T(row["TIPO_MOV"]),
                    ["movimento"] = T(row["MOV"]),
                    ["qtaMovimento"] = F(row["QTA_MOV"]),
                    ["ordine"] = T(row["ORDINE"]),
                    ["bolla"] = bolla,
                    // Elimina gli spazi bianchi multipli anche all'interno
                    ["fornitore"] = Regex.Replace(T(row["ANINCO"]), @"\s\s+", " "),
                    ["colore"] = T(row["CSCOLOR"]),
                    ["um"] = T(row["MUTMS"]),
                    ["trattamento"] = T(row["CSTRASU"]),
                    ["id"] = id,
                    ["url_foto"] = urlFoto,
                    ["confermato"] = confermato,
                    ["utente_conferma"] = utenteConferma
                });
            }
            return lista;
        }

        /// <summary>
        /// Arrivi di merce filtrati per articolo, ragione sociale e data (ex query/produzione/getQualitaArrivi.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetQualitaArrivi(GetQualitaArriviRequest request)
        {
            var societa = string.IsNullOrEmpty(request.societa) ? "CSPRO" : request.societa;
            var valori = new List<object?> { societa };
            var filtri = new StringBuilder();

            if (!string.IsNullOrEmpty(request.art))
            {
                filtri.Append(" AND dat.RICODART LIKE ?");
                valori.Add(request.art + "%");
            }
            if (!string.IsNullOrEmpty(request.ragSoc))
            {
                filtri.Append(" AND did.ANINCO LIKE ?");
                valori.Add("%" + request.ragSoc + "%");
            }
            if (!string.IsNullOrEmpty(request.dataArr)
                && decimal.TryParse(request.dataArr.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var dataArr))
            {
                filtri.Append(" AND dat.RIRIPDT = ?");
                valori.Add(dataArr);
            }

            var query = $@"SELECT
	did.ANINCO AS RAGIONE_SOCIALE,
	dat.RICOFOR AS COD_FORNITORE,
	dat.RIRIPDT AS DATA,
	Sum(dat.RITQEXI/100) AS QTA,
	MIN(dat.RIDELUM) AS UM,
	dat.RICODART AS ARTICOLO,
	ite.MPDSC AS DESCRIZIONE_ARTICOLO,
	ite.MTYPN AS TIPO,
	dac.RFNRORD AS ORDINE,
	dat.RIDTXAB AS DATA_BOLLA,
	dat.RIDLVNO AS NUMERO_BOLLA
FROM D60STDDB.RMSADAT dat
INNER JOIN ANSADID did ON
	dat.RICOSC = did.ANCOSO AND
	dat.RICOFOR = did.ANCOCO
INNER JOIN DBSAITE ite ON
	ite.MCOSC = dat.RICOSC AND
	dat.RICODART = ite.MITEM
INNER JOIN D60STDDB.RMSADAC dac ON
dat.RICOSC = dac.RICOSC AND
dat.RIRIPNO = dac.RIRIPNO
WHERE dat.RISTAT3 <> 'D' AND dat.RICOSC=?{filtri}
GROUP BY
	did.ANINCO,
	dat.RICOFOR,
	dat.RIRIPDT,
	dat.RICODART,
	ite.MPDSC,
	ite.MTYPN,
	dac.RFNRORD,
	dat.RISTAT3,
	dat.RICOSC,
	dat.RIDTXAB,
	dat.RIDLVNO
ORDER BY did.ANINCO, dat.RICOFOR";

            return DbHelper.Query(_conn.Db2, query, valori.ToArray())
                .Select(row => new Dictionary<string, object?>
                {
                    ["ragioneSociale"] = Regex.Replace(T(row["RAGIONE_SOCIALE"]), @"\p{P}", ""),
                    ["fornitore"] = T(row["COD_FORNITORE"]),
                    ["dataArrivo"] = T(row["DATA"]),
                    ["qta"] = FormatNumero(row["QTA"]),
                    ["um"] = T(row["UM"]),
                    ["articolo"] = T(row["ARTICOLO"]),
                    ["descrizione"] = Regex.Replace(T(row["DESCRIZIONE_ARTICOLO"]), @"\p{P}", ""),
                    ["tipoArticolo"] = T(row["TIPO"]),
                    ["ordine"] = T(row["ORDINE"]),
                    ["dataBolla"] = T(row["DATA_BOLLA"]),
                    ["bolla"] = T(row["NUMERO_BOLLA"])
                })
                .ToList();
        }

        /// <summary>
        /// Conferma (inserisce e restituisce l'id) o elimina la conferma qualità di articolo/bolla
        /// (ex query/produzione/confirmDeleteQualita.php). Restituisce 0 se non è stato inserito nulla.
        /// </summary>
        public long ConfirmDeleteQualita(ConfirmDeleteQualitaRequest request, string utenteConferma)
        {
            if (request.action == "confirm")
            {
                var oggi = DateTime.Now;
                var id = DbHelper.Scalar(_conn.PgDb1,
                    @"insert into conferme_qualita_codici_r (articolo, bolla, url_foto, utente_conferma, data_conferma, ora_conferma)
    values (?, ?, ?, ?, ?, ?) returning id",
                    request.articolo ?? "", request.bolla ?? "", request.url_foto ?? "", utenteConferma, DataIntera(oggi), OraIntera(oggi));
                return I(id);
            }

            if (request.action == "delete")
            {
                DbHelper.NonQuery(_conn.PgDb1,
                    "delete from conferme_qualita_codici_r where articolo=? and bolla=?",
                    request.articolo ?? "", request.bolla ?? "");
            }
            return 0;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Pre-carico ----------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Crea una nuova lista di pre-carico (testata + righe) e restituisce la sequenza assegnata
        /// (ex query/produzione/uploadListaPrecarico.php).
        /// </summary>
        public int UploadListaPrecarico(UploadListaPrecaricoRequest request, string utente)
        {
            var odl = request.odl ?? "";
            var fase = request.fase ?? "";
            var righe = (request.listaPrecarico ?? new List<RigaListaPrecaricoRequest>())
                .Select(r => new
                {
                    r.articolo,
                    descrizione = (r.descrizione ?? "").Replace("'", "`"),
                    r.um,
                    qta = Decimale(r.qta, "qta"),
                    qta_enx = Decimale(r.qta_enx, "qta_enx"),
                    r.nota
                })
                .ToList();

            var oggi = DateTime.Now;

            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();
            using var tx = conn.BeginTransaction();

            var sequenza = 0;
            foreach (var row in DbHelper.Query(conn, tx,
                         "select sequenza from public.precarico_testate where odl=? and fase =? order by sequenza desc limit 1", odl, fase))
            {
                sequenza = (int)I(row["sequenza"]);
            }
            sequenza += 1;

            DbHelper.NonQuery(conn, tx,
                @"insert into public.precarico_testate (odl, fase, sequenza, magazzino, padre, padre_descrizione, data_creazione, ora_creazione, utente_creazione) values
    (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                odl, fase, sequenza, request.magazzino ?? "", request.padre ?? "", request.padre_descrizione ?? "",
                DataIntera(oggi), OraIntera(oggi), utente);

            foreach (var r in righe)
            {
                DbHelper.NonQuery(conn, tx,
                    @"insert into public.precarico_righe (odl, fase, sequenza, articolo, descrizione, um, qta, qta_caricata, qta_enx, nota) values
    (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    odl, fase, sequenza, r.articolo ?? "", r.descrizione, r.um ?? "", r.qta, r.qta, r.qta_enx, r.nota ?? "");
            }

            tx.Commit();
            return sequenza;
        }

        /// <summary>
        /// Aggiorna una lista di pre-carico non ancora completata confrontando le righe del DB con quelle inviate:
        /// aggiorna qta/nota, elimina le righe tolte e inserisce quelle nuove (ex query/produzione/modifyListaPrecarico.php).
        /// </summary>
        public string ModifyListaPrecarico(ModifyListaPrecaricoRequest request)
        {
            var odl = request.odl ?? "";
            var fase = request.fase ?? "";
            var sequenza = Intero(request.sequenza, "sequenza");
            var nuove = request.newListaPrecarico ?? new List<RigaListaPrecaricoRequest>();

            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();
            using var tx = conn.BeginTransaction();

            var righeDB = DbHelper.Query(conn, tx,
                "select * from precarico_righe where odl=? and fase=? and sequenza=? order by id", odl, fase, sequenza);

            // Righe aggiornate o rimosse
            foreach (var rigaDB in righeDB)
            {
                var articoloDB = S(rigaDB["articolo"]);
                var presente = false;

                foreach (var nuova in nuove.Where(n => n.articolo == articoloDB))
                {
                    DbHelper.NonQuery(conn, tx,
                        "update precarico_righe set qta=?, qta_enx=?, nota=? where articolo=? and odl=? and fase=? and sequenza=?",
                        Decimale(nuova.qta, "qta"), Decimale(nuova.qta_enx, "qta_enx"), nuova.nota ?? "", articoloDB, odl, fase, sequenza);
                    presente = true;
                }

                if (!presente)
                {
                    DbHelper.NonQuery(conn, tx,
                        "delete from precarico_righe where articolo=? and odl=? and fase=? and sequenza=?",
                        articoloDB, odl, fase, sequenza);
                }
            }

            // Righe aggiunte
            foreach (var nuova in nuove)
            {
                if (righeDB.Any(r => S(r["articolo"]) == nuova.articolo))
                {
                    continue;
                }

                var qta = Decimale(nuova.qta, "qta");
                DbHelper.NonQuery(conn, tx,
                    @"insert into public.precarico_righe (odl, fase, sequenza, articolo, descrizione, um, qta, qta_caricata, qta_enx, nota) values
        (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    odl, fase, sequenza, nuova.articolo ?? "", (nuova.descrizione ?? "").Replace("'", "`"), nuova.um ?? "",
                    qta, qta, Decimale(nuova.qta_enx, "qta_enx"), nuova.nota ?? "");
            }

            tx.Commit();
            return "updated";
        }

        /// <summary>
        /// Completa le liste di pre-carico caricate dal magazzino, segnando le righe modificate, rimosse e aggiunte
        /// (ex query/produzione/updateListaPrecarico.php).
        /// </summary>
        public string UpdateListaPrecarico(UpdateListaPrecaricoRequest request, string utente)
        {
            var righe = request.righe ?? new List<RigaCaricoPrecaricoRequest>();
            var liste = request.liste_precarico ?? new List<ListaPrecaricoKeyRequest>();

            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();
            using var tx = conn.BeginTransaction();

            foreach (var lista in liste)
            {
                var odl = lista.odl ?? "";
                var fase = lista.fase ?? "";
                var sequenza = Intero(lista.sequenza, "sequenza");
                var listaModificata = false;

                // Righe del carico appartenenti a questa lista
                var righeLista = righe
                    .Where(r => (r.odl ?? "") == odl && (r.fase ?? "") == fase && StessaSequenza(r.sequenza, lista.sequenza))
                    .ToList();

                var righeDB = DbHelper.Query(conn, tx,
                    "select * from precarico_righe where odl=? and fase=? and sequenza=? order by id", odl, fase, sequenza);

                // Quantità modificate o righe rimosse
                foreach (var rigaDB in righeDB)
                {
                    var qtaDB = F(rigaDB["qta"]);
                    var qtaDBPiuEnx = qtaDB + F(rigaDB["qta_enx"]);
                    var id = (int)I(rigaDB["id"]);
                    var presente = false;

                    foreach (var riga in righeLista)
                    {
                        var qtaCarico = F(riga.qta);
                        if (S(rigaDB["articolo"]) != riga.articolo) continue;

                        presente = true;
                        if (qtaDB != qtaCarico || qtaDBPiuEnx != qtaCarico)
                        {
                            if (qtaDBPiuEnx != qtaCarico)
                            {
                                listaModificata = true;
                            }
                            DbHelper.NonQuery(conn, tx,
                                "update precarico_righe set qta_caricata=?, azione_riga='qta_modificata' where id=?", qtaCarico, id);
                        }
                    }

                    // Se non l'ho trovato => è stato rimosso
                    if (!presente)
                    {
                        listaModificata = true;
                        DbHelper.NonQuery(conn, tx, "update precarico_righe set azione_riga='riga_rimossa' where id=?", id);
                    }
                }

                // Righe aggiunte manualmente dal magazziniere
                foreach (var riga in righeLista)
                {
                    if (righeDB.Any(r => S(r["articolo"]) == riga.articolo))
                    {
                        continue;
                    }

                    var qtaCarico = F(riga.qta);
                    DbHelper.NonQuery(conn, tx,
                        @"insert into public.precarico_righe (odl, fase, sequenza, articolo, descrizione, um, qta, qta_caricata, azione_riga) values
        (?, ?, ?, ?, ?, ?, ?, ?, 'riga_aggiunta')",
                        odl, fase, sequenza, riga.articolo ?? "", (riga.descrizione ?? "").Replace("'", "`"), riga.umis ?? "", qtaCarico, qtaCarico);
                    listaModificata = true;
                }

                // Testata completata (e modificata se il carico differisce dal pre-carico)
                var oggi = DateTime.Now;
                var modificato = listaModificata ? "true" : "false";
                DbHelper.NonQuery(conn, tx,
                    $"update precarico_testate set completato=true, utente_completamento=?, data_completamento=?, ora_completamento=?, modificato={modificato} where odl=? and fase =? and sequenza=?",
                    utente, DataIntera(oggi), OraIntera(oggi), odl, fase, sequenza);
            }

            tx.Commit();
            return "updated";
        }

        /// <summary>
        /// Segna come revisionata la testata di pre-carico (ex query/produzione/updateListaPrecaricoSegnaComeRevisionata.php).
        /// </summary>
        public string UpdateListaPrecaricoSegnaComeRevisionata(string? id)
        {
            DbHelper.NonQuery(_conn.PgDb1, "update precarico_testate set revisionato=true where id=?", Intero(id, "id"));
            return "updated";
        }

        /// <summary>
        /// Elimina testata e righe della lista di pre-carico (ex query/produzione/eliminaListaPrecarico.php).
        /// </summary>
        public string EliminaListaPrecarico(ListaPrecaricoKeyRequest request)
        {
            var odl = request.odl ?? "";
            var fase = request.fase ?? "";
            var sequenza = Intero(request.sequenza, "sequenza");

            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();
            using var tx = conn.BeginTransaction();
            DbHelper.NonQuery(conn, tx, "delete from precarico_testate where odl=? and fase=? and sequenza=?", odl, fase, sequenza);
            DbHelper.NonQuery(conn, tx, "delete from precarico_righe where odl=? and fase=? and sequenza=?", odl, fase, sequenza);
            tx.Commit();
            return "deleted";
        }

        /// <summary>
        /// Liste di pre-carico create dall'utente negli ultimi due mesi o non ancora completate, con le righe
        /// (ex query/produzione/getStoriaPrecarico.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetStoriaPrecarico(string utente)
        {
            var oggi = DateTime.Now;
            int dataCorrente;
            if (oggi.Month == 1)
            {
                // Dal 1 novembre dell'anno scorso
                dataCorrente = (oggi.Year - 1) * 10000 + 1101;
            }
            else if (oggi.Month == 2)
            {
                // Dal 1 dicembre dell'anno scorso
                dataCorrente = (oggi.Year - 1) * 10000 + 1201;
            }
            else
            {
                // -2 mesi
                dataCorrente = DataIntera(oggi) - 200;
            }

            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();

            var storico = DbHelper.Query(conn, null,
                @"select * from precarico_testate
where utente_creazione=? and (data_creazione > ? or completato is False)
order by data_creazione desc, ora_creazione desc",
                utente, dataCorrente);

            foreach (var testata in storico)
            {
                var righe = DbHelper.Query(conn, null,
                    @"select * from precarico_righe
    where odl=? and fase=? and sequenza=?
    order by id",
                    S(testata["odl"]), S(testata["fase"]), (int)I(testata["sequenza"]));

                foreach (var riga in righe)
                {
                    riga["listaRientriTrasferimenti"] = new List<object>();
                }
                testata["righe"] = righe;
            }
            return storico;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Utilità -------------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>Valore come stringa ("" se NULL).</summary>
        private static string S(object? v) => v?.ToString() ?? "";

        /// <summary>trim() del valore.</summary>
        private static string T(object? v) => S(v).Trim();

        /// <summary>(float) di PHP: 0 se il valore non è numerico.</summary>
        private static double F(object? v) =>
            double.TryParse(S(v).Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var d) ? d : 0;

        /// <summary>(int) di PHP: parte intera, 0 se il valore non è numerico.</summary>
        private static long I(object? v) => (long)Math.Truncate(F(v));

        /// <summary>Numero formattato con al massimo 10 decimali, senza zeri finali (formatNumero di getQualitaArrivi.php).</summary>
        private static string FormatNumero(object? v) =>
            Math.Round((decimal)F(v), 10).ToString("0.##########", CultureInfo.InvariantCulture);

        /// <summary>Data intera yyyyMMdd.</summary>
        private static int DataIntera(DateTime d) => d.Year * 10000 + d.Month * 100 + d.Day;

        /// <summary>Ora intera HHmmss.</summary>
        private static int OraIntera(DateTime d) => d.Hour * 10000 + d.Minute * 100 + d.Second;

        /// <summary>Intero obbligatorio della richiesta.</summary>
        private static int Intero(string? valore, string campo)
        {
            if (!int.TryParse((valore ?? "").Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var n))
            {
                throw new MobileException($"Parametro '{campo}' non valido");
            }
            return n;
        }

        /// <summary>Quantità della richiesta: vuota = 0, non numerica = errore.</summary>
        private static decimal Decimale(string? valore, string campo)
        {
            if (string.IsNullOrWhiteSpace(valore)) return 0;
            if (!decimal.TryParse(valore.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var d))
            {
                throw new MobileException($"Parametro '{campo}' non valido");
            }
            return d;
        }

        /// <summary>
        /// Registra un impegno in fase 0027 per le statistiche delle prestazioni di magazzino (ex query/produzione/writeInserimentoFase0027.php).
        /// </summary>
        /// <returns>'uploaded'.</returns>
        public string WriteInserimentoFase0027(InserimentoFase0027Request r)
        {
            const string query = @"insert into public.inserimenti_fase_0027 (articolo, odl, padre, fase, magazzino, responsabile, data_inserimento, ora_inserimento, qta)
values (?, ?, ?, ?, ?, ?, ?, ?, ?)";
            var adesso = DateTime.Now;
            DbHelper.NonQuery(_conn.PgDb1, query, r.articolo ?? "", r.odl ?? "", r.padre ?? "", r.fase ?? "", r.magazzino ?? "",
                r.responsabile ?? "", int.Parse(adesso.ToString("yyyyMMdd")), int.Parse(adesso.ToString("HHmmss")), Decimale(r.qta, "qta"));
            return "uploaded";
        }

        /// <summary>
        /// Elimina l'ultimo impegno in fase 0027 di articolo, ODL e magazzino (ex query/produzione/deleteInserimentoFase0027.php).
        /// </summary>
        /// <returns>'deleted'.</returns>
        public string DeleteInserimentoFase0027(InserimentoFase0027Request r)
        {
            const string query = @"delete from public.inserimenti_fase_0027 where id = (
select id from public.inserimenti_fase_0027 where articolo = ? and odl = ? and magazzino = ?
order by data_inserimento desc, ora_inserimento desc limit 1)";
            DbHelper.NonQuery(_conn.PgDb1, query, r.articolo ?? "", r.odl ?? "", r.magazzino ?? "");
            return "deleted";
        }

        /// <summary>Confronto "loose" di PHP (<c>!=</c>) tra due sequenze: numerico se entrambe numeriche.</summary>
        private static bool StessaSequenza(string? a, string? b)
        {
            if (decimal.TryParse((a ?? "").Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var da)
                && decimal.TryParse((b ?? "").Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var db))
            {
                return da == db;
            }
            return (a ?? "") == (b ?? "");
        }
    }
}
