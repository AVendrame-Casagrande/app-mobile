using System;
using System.ComponentModel;
using System.Data.Odbc;
using System.Net.Mime;
using System.Net.Sockets;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Text.RegularExpressions;
using System.Threading;
using Abletech.WebApi.Client.Arxivar.Model;
using CG.MobileAPI.Data;
using iText.StyledXmlParser.Jsoup.Nodes;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory;

namespace CG.MobileAPI.Models
{
    /// <summary>
    /// Modello per la richiesta POST del servizio.
    /// </summary>
    public class ItemESRequestModel
    {
        /// <summary>
        /// Ottiene o imposta l'identificativo dell'articolo.
        /// </summary>
        public string ArticoloId { get; set; }

        /// <summary>
        /// Ottiene o imposta la descrizione dell'articolo.
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// Ottiene o imposta il codice TL.
        /// </summary>
        public string CodiceTL { get; set; }

        /// <summary>
        /// Ottiene o imposta la versione del listino.
        /// </summary>
        public string VersioneListino { get; set; }

        /// <summary>
        /// Ottiene o imposta il codice della società.
        /// </summary>
        public string CodiceSocieta { get; set; }

        /// <summary>
        /// Ottiene o imposta il nome dell'origine della richiesta
        /// </summary>
        [JsonPropertyName("REQUESTER")]
        public string Requester { get; set; }

        /// <summary>
        /// Ottiene o imposta il nome del utente che sta facendo la richiesta.
        /// </summary>
        [JsonPropertyName("REQUESTER_USER")]
        public string RequesterUser { get; set; }

        /// <summary>
        /// Ottiene o imposta la pagina da dove viene fatta  che sta facendo la richiesta.
        /// </summary>
        [JsonPropertyName("REQUESTER_PAGE")]
        public string ActivePage { get; set; }

        /// <summary>
        /// Ottiene o imposta il percorso del file foto associato all'articolo.
        /// </summary>
        public string FileFoto { get; set; }

        /// <summary>
        /// Ottiene o imposta il nome del file foto associato all'articolo.
        /// </summary>
        public string FileFotoName { get; set; }

        [JsonPropertyName("TIPO_ESPLOSIONE")]
        public string? TipoEsplosione { get; set; }

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="ItemESRequestModel"/>.
        /// </summary>
        /// <param name="articoloId">Identificativo dell'articolo.</param>
        /// <param name="description">Descrizione dell'articolo.</param>
        /// <param name="codiceTL">Codice TL.</param>
        /// <param name="versioneListino">Versione del listino.</param>
        /// <param name="codiceSocieta">Codice della società (default "CSPRO").</param>
        /// <param name="fileFoto">Percorso del file foto associato all'articolo.</param>
        /// <param name="fileFotoName">Nome del file foto associato all'articolo.</param>"
        public ItemESRequestModel(string articoloId = "", string description = "", string codiceTL = "", string versioneListino = "", string codiceSocieta = "CSPRO", string fileFoto = "", string fileFotoName = "", string requesterUser = "", string requester = "", string? tipoEsplosione = null)
        {
            ArticoloId = articoloId;
            Description = description;
            CodiceTL = codiceTL;
            VersioneListino = versioneListino;
            CodiceSocieta = codiceSocieta;
            FileFoto = fileFoto;
            FileFotoName = fileFotoName;
            RequesterUser = requesterUser;
            Requester = requester;
            TipoEsplosione = tipoEsplosione;
        }
    }

    /// <summary>
    /// Modello descrittivo di un articolo per l'estrazione dell'esplosione scalare.
    /// </summary>
    public class ItemModel
    {
        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="ItemModel"/>.
        /// </summary>
        /// <param name="id">Identificativo dell'articolo.</param>
        /// <param name="desc">Descrizione dell'articolo.</param>
        /// <param name="comp">Codice del componente principale.</param>
        /// <param name="nota">Note associate all'articolo.</param>
        /// <param name="qta">Quantità dell'articolo.</param>
        /// <param name="level">Livello gerarchico dell'articolo.</param>
        /// <param name="children">Eventuali figli (componenti) dell'articolo.</param>
        public ItemModel(string id = "", string desc = "", string comp = "", string nota = "", float qta = 0, int level = 0, List<ItemChildModel>? children = null)
        {
            ID = id;
            Description = desc;
            Component = comp;
            Note = nota;
            Qta = qta;
            Level = level;
            Children = children ?? new List<ItemChildModel>();
        }

        /// <summary>
        /// Ottiene o imposta l'identificativo dell'articolo.
        /// </summary>
        public string ID { get; set; }

        /// <summary>
        /// Ottiene o imposta la descrizione dell'articolo.
        /// </summary>
        public string Description { get; set; }

        /// <summary>
        /// Ottiene o imposta il codice del componente principale.
        /// </summary>
        public string Component { get; set; }

        /// <summary>
        /// Ottiene o imposta le note associate all'articolo.
        /// </summary>
        public string Note { get; set; }

        /// <summary>
        /// Ottiene o imposta la quantità dell'articolo.
        /// </summary>
        public float Qta { get; set; }

        /// <summary>
        /// Ottiene o imposta il livello gerarchico dell'articolo.
        /// </summary>
        public int Level { get; set; }

        /// <summary>
        /// Ottiene o imposta la lista dei figli (componenti) dell'articolo.
        /// </summary>
        public List<ItemChildModel> Children { get; set; }

    }

    /// <summary>
    /// Modello descrittivo dei figli dell'esplosione scalare.
    /// </summary>
    public class ItemChildModel
    {
        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="ItemChildModel"/>.
        /// </summary>
        /// <param name="csitem">Codice dell'articolo figlio.</param>
        /// <param name="mpdsc">Descrizione breve dell'articolo figlio.</param>
        /// <param name="ppcomm">Note o commento aggiuntivo.</param>
        /// <param name="csqta500">Quantità 500.</param>
        /// <param name="csqta1000">Quantità 1000.</param>
        /// <param name="csqta2000">Quantità 2000.</param>
        /// <param name="pnetto">Prezzo netto.</param>
        /// <param name="plordo">Prezzo lordo.</param>
        /// <param name="mcladog">Codice MCLADOG.</param>
        /// <param name="prezzo">Prezzo finale.</param>
        public ItemChildModel(string csitem, string mpdsc, string ppcomm, int csqta250, int csqta500, int csqta750, int csqta1000, int csqta2000, float pnetto, float plordo, string mcladog, float prezzo)
        {
            CSITEM = csitem;
            MPDSC = mpdsc;
            PPCOMM = ppcomm;
            CSQTA250 = csqta250;
            CSQTA500 = csqta500;
            CSQTA750 = csqta750;
            CSQTA1000 = csqta1000;
            CSQTA2000 = csqta2000;
            PNETTO = pnetto;
            PLORDO = plordo;
            MCLADOG = mcladog;
            PREZZO = prezzo;
        }

        /// <summary>
        /// Ottiene o imposta il codice dell'articolo figlio.
        /// </summary>
        public string CSITEM { get; set; }

        /// <summary>
        /// Ottiene o imposta la descrizione breve dell'articolo figlio.
        /// </summary>
        public string MPDSC { get; set; }

        /// <summary>
        /// Ottiene o imposta il commento o note aggiuntive.
        /// </summary>
        public string PPCOMM { get; set; }

        public int CSQTA250 { get; set; }

        /// <summary>
        /// Ottiene o imposta la quantità per il range 500.
        /// </summary>
        public int CSQTA500 { get; set; }

        /// <summary>
        /// Ottiene o imposta la quantità per il range 750.
        /// </summary>
        public int CSQTA750 { get; set; }

        /// <summary>
        /// Ottiene o imposta la quantità per il range 1000.
        /// </summary>
        public int CSQTA1000 { get; set; }

        /// <summary>
        /// Ottiene o imposta la quantità per il range 2000.
        /// </summary>
        public int CSQTA2000 { get; set; }

        /// <summary>
        /// Ottiene o imposta il prezzo netto.
        /// </summary>
        public float PNETTO { get; set; }

        /// <summary>
        /// Ottiene o imposta il prezzo lordo.
        /// </summary>
        public float PLORDO { get; set; }

        /// <summary>
        /// Ottiene o imposta il prezzo finale.
        /// </summary>
        public float PREZZO { get; set; }

        /// <summary>
        /// Ottiene o imposta il codice MCLADOG.
        /// </summary>
        public string MCLADOG { get; set; }
    }

    /// <summary>
    /// Modello informativo per un articolo.
    /// </summary>
    public class ItemInfoModel
    {
        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="ItemInfoModel"/>.
        /// </summary>
        /// <param name="mitem">Identificativo dell'articolo.</param>
        /// <param name="mpdsc">Descrizione dell'articolo.</param>
        /// <param name="mstait">Stato dell'articolo.</param>
        /// <param name="mtypn">Tipo dell'articolo.</param>
        /// <param name="mutms">Codice relativo all'unità di misura.</param>
        /// <param name="mweight">Peso dell'articolo.</param>
        /// <param name="mforcd">Codice fornitore.</param>
        /// <param name="mbread">Larghezza.</param>
        /// <param name="mheight">Altezza.</param>
        /// <param name="mpallet">Dimensione del pallet.</param>
        public ItemInfoModel(string mitem, string mpdsc, string mstait, string mtypn, string mutms, int mweight, string mforcd, int mbread, int mheight, int mpallet)
        {
            MITEM = mitem;
            MPDSC = mpdsc;
            MSTAIT = mstait;
            MTYPN = mtypn;
            MUTMS = mutms;
            MWEIGHT = mweight;
            MFORCD = mforcd;
            MBREAD = mbread;
            MHEIGHT = mheight;
            MPALLET = mpallet;
        }

        /// <summary>
        /// Ottiene o imposta l'identificativo dell'articolo.
        /// </summary>
        public string MITEM { get; set; }

        /// <summary>
        /// Ottiene o imposta la descrizione dell'articolo.
        /// </summary>
        public string MPDSC { get; set; }

        /// <summary>
        /// Ottiene o imposta lo stato dell'articolo.
        /// </summary>
        public string MSTAIT { get; set; }

        /// <summary>
        /// Ottiene o imposta il tipo dell'articolo.
        /// </summary>
        public string MTYPN { get; set; }

        /// <summary>
        /// Ottiene o imposta l'unità di misura o codice correlato.
        /// </summary>
        public string MUTMS { get; set; }

        /// <summary>
        /// Ottiene o imposta il peso dell'articolo.
        /// </summary>
        public int MWEIGHT { get; set; }

        /// <summary>
        /// Ottiene o imposta il codice fornitore.
        /// </summary>
        public string MFORCD { get; set; }

        /// <summary>
        /// Ottiene o imposta la larghezza.
        /// </summary>
        public int MBREAD { get; set; }

        /// <summary>
        /// Ottiene o imposta l'altezza.
        /// </summary>
        public int MHEIGHT { get; set; }

        /// <summary>
        /// Ottiene o imposta la dimensione del pallet.
        /// </summary>
        public int MPALLET { get; set; }
    }

    /// <summary>
    /// Classe per l'accesso ai dati e le operazioni relative agli articoli e alle relative esplosioni scalari.
    /// </summary>
    public class DBSAITE
    {
        private string _connectionStringT;
        private string _connectionStringP;
        private string _connectionStringB;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBSAITE"/>.
        /// </summary>
        /// <param name="connectionStringT">Stringa di connessione per la linea T.</param>
        /// <param name="connectionStringP">Stringa di connessione per la linea P.</param>
        /// <param name="connectionStringB">Stringa di connessione per la linea B.</param>
        public DBSAITE(string connectionStringT, string connectionStringP, string connectionStringB)
        {
            _connectionStringT = connectionStringT;
            _connectionStringP = connectionStringP;
            _connectionStringB = connectionStringB;
        }

        /// <summary>
        /// Esegue l'estrazione dell'esplosione scalare per l'articolo specificato, arricchendo il modello con i dati dei componenti.
        /// </summary>
        /// <param name="versione">Versione del listino.</param>
        /// <param name="tipolistino">Tipo di listino.</param>
        /// <param name="articolo">Identificativo dell'articolo (obbligatorio).</param>
        /// <param name="societa">Codice della società (default "CSPRO").</param>
        /// <returns>Una lista di <see cref="ItemModel"/> contenente i dati dell'esplosione scalare.</returns>
        /// <exception cref="Exception">Lancia un'eccezione se l'articolo non è stato specificato.</exception>
        public List<ItemModel> GetEsplosioneScalareR(string versione, string tipolistino, string? articolo = null, string tipoRicerca = "O", string societa = "CSPRO")
        {
            List<ItemModel> returnList = new List<ItemModel>();

            using (OdbcConnection conn = new OdbcConnection(_connectionStringP))
            {
                List<ItemModel> response = new List<ItemModel>();
                int date = DateTime.Now.Date.Year * 10000 + DateTime.Now.Date.Month * 100 + DateTime.Now.Date.Day;

                string query = "WITH DB (LEVEL, MITEM, SPCOMP, SPQTY, SPPHAN, SPSQNO, CHIAVE, SPPON, MCOSC) AS " +
                    "(    SELECT 1, ROOT.MITEM, ROOT.SPCOMP, ROOT.SPQTY, ROOT.SPPHAN, ROOT.SPSQNO,  " +
                    "     TRIM(ROOT.MITEM) CONCAT '.' CONCAT TRIM(ROOT.SPSQNO) CONCAT '.' CONCAT  TRIM(ROOT.SPCOMP) AS" +
                    $"    CHIAVE, ROOT.SPPON, '{societa}' FROM D60STDDB.DBSAPRD ROOT  WHERE ROOT.MITEM = '{articolo}' AND" +
                    $"    SPADDDT <= INTEGER(REPLACE(SUBSTR(TO_CHAR(CURRENT DATE), 1, 10), '-', '')) AND ROOT.MCOSC = '{societa}'" +
                    "     AND (SPDELDT = 0 OR SPDELDT > INTEGER(REPLACE(SUBSTR(TO_CHAR(CURRENT DATE), 1, 10), '-', '')))" +
                    "     UNION ALL" +
                    "     SELECT PARENT.LEVEL + 1, CHILD.MITEM, CHILD.SPCOMP, CHILD.SPQTY, CHILD.SPPHAN, CHILD.SPSQNO,	" +
                    "     CAST(CASE WHEN TRIM(CHILD.SPSQNO) = '' THEN TRIM(PARENT.CHIAVE) CONCAT '.' CONCAT" +
                    "     '0000' CONCAT '.' CONCAT TRIM(CHILD.SPCOMP) ELSE TRIM(PARENT.CHIAVE) CONCAT '.' CONCAT TRIM(CHILD.SPSQNO)" +
                    $"    CONCAT '.' CONCAT TRIM(CHILD.SPCOMP) END AS CHAR(200)) AS CHIAVE, CHILD.SPPON, '{societa}' FROM" +
                    "     DB PARENT, DBSAPRD CHILD WHERE 1 = 1" +
                    $"    AND PARENT.SPCOMP = CHILD.MITEM and CHILD.SPDELDT = 0 and CHILD.MCOSC = '{societa}'" +
                    ")" +
                    " SELECT A.MITEM,MPDSC,SPCOMP,COALESCE(PPCOMM, ''),SPQTY, LEVEL FROM DB A" +
                    " INNER JOIN DBSAITE b ON a.SPCOMP = b.MITEM AND b.MCOSC = a.MCOSC" +
                    " LEFT JOIN DBSAITX c ON a.SPCOMP = PPUSER AND c.MCOSC = a.MCOSC AND C.PPTXTC = 'IC' AND C.PPSEQT = 1";

                using (OdbcCommand command = new OdbcCommand(query, conn))
                {
                    command.Connection.Open();

                    using (OdbcDataReader reader = DbHelper.ExecuteQuerySharedConn(command))
                    {
                        while (reader.Read())
                        {
                            ItemModel art = new ItemModel(
                                reader.GetString(0).Trim(),
                                reader.GetString(1).Trim(),
                                reader.GetString(2).Trim(),
                                reader.GetString(3).Trim(),
                                reader.GetFloat(4),
                                reader.GetInt32(5)
                            );
                            response.Add(art);
                        }
                    }

                    var count = 0;

                    if (tipoRicerca == "O" || tipoRicerca == "R")
                    {
                        foreach (var item in response)
                        {
                            command.CommandText = "SELECT CSITEM,MPDSC,COALESCE(PPCOMM, ''),CSQTA500,CSQTA1000,CSQTA2000, CSIMPGDB ,MPALLET/100 AS PLORDO,MCLADOG FROM CSDBGRR a " +
                                                  " INNER JOIN DBSAITE b ON CSITEM=MITEM AND b.MCOSC=CSMCOSC " +
                                                  " INNER JOIN MASAINV d ON CSITEM=d.MALITEM AND d.MAHCOSC=CSMCOSC " +
                                                  " LEFT JOIN DBSAITX c ON CSITEM=PPUSER AND c.MCOSC=CSMCOSC AND PPTXTC='IC' AND PPSEQT = 1 " +
                                                  $" WHERE CSGRUPPO='{item.Component}' AND CSMCOSC= '{societa}'";

                            using (OdbcDataReader reader = DbHelper.ExecuteQuerySharedConn(command))
                            {
                                while (reader.Read())
                                {
                                    var csItem = reader.GetString(0).Trim();
                                    float prezzo = 0.0f;
                                    versione = versione == "" ? "0" : versione;

                                    query = $"SELECT OLQNEPR/10000 AS PREZZO FROM OCSAQUO WHERE OLQTYPE='{tipolistino}' AND OLQKEYL='CRI' AND OLQITEM= '{csItem}' AND OLQVERL={versione} AND OLQCOSC='{societa}'";

                                    using (OdbcDataReader reader2 = DbHelper.ExecuteQuery(_connectionStringP, query))
                                    {
                                        if (reader2.Read())
                                        {
                                            prezzo = reader2.GetFloat(0);
                                        }
                                    }

                                    ItemChildModel art = new ItemChildModel(
                                        csItem,
                                        reader.GetString(1).Trim(),
                                        "",
                                        0,
                                        reader.GetInt32(3),
                                        0,
                                        reader.GetInt32(4),
                                        reader.GetInt32(5),
                                        reader.GetFloat(6),//dbimp
                                        reader.GetFloat(7),
                                        reader.GetString(8).Trim(),
                                        prezzo
                                    );

                                    item.Children.Add(art);
                                    count++;
                                }
                            }

                            if (item.Children.Count > 0)
                            {
                                returnList.Add(item);
                            }
                        }
                    }
                    else
                    {
                        query = $"SELECT * FROM CS_DISTINTA_SCALARE_USURA5_V V" +
                                $" WHERE V.RADICE = '{articolo}'" +
                                $" AND V.SOC = '{societa}' ORDER BY V.CHIAVE";
                        var allRicambiSuggeriti = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

                        response.Reverse();

                        foreach (var item in response)
                        {
                            int indx = response.IndexOf(item);
                            var ricambi = allRicambiSuggeriti.Where(element => element["MITEM"].ToString().Trim() == item.Component.Trim() && (int.Parse(element["LEVEL"].ToString().Trim()) - 1) == item.Level && element["CHIAVE"].ToString().Trim().Contains(item.ID.ToString().Trim())).ToList();

                            foreach (var itemChild in ricambi)
                            {
                                versione = versione == "" ? "0" : versione;

                                query = $"SELECT OLQNEPR/10000 AS PREZZO FROM OCSAQUO WHERE OLQTYPE='{tipolistino}' AND OLQKEYL='CRI' AND OLQITEM= '{itemChild["SPCOMP"].ToString().Trim()}' AND OLQVERL={versione} AND OLQCOSC='{societa}'";
                                var prezziList = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

                                double prezzo = 0;

                                if (prezziList.Count > 0)
                                {
                                    prezzo = double.Parse(prezziList[0]["PREZZO"].ToString());
                                }

                                ItemChildModel child = new ItemChildModel(
                                    itemChild["SPCOMP"].ToString().Trim(),
                                    itemChild["MPDSC"].ToString().Trim(),
                                    itemChild["AGGNTUSR"].ToString(),
                                    int.Parse(itemChild["SPQTY_250"].ToString().Replace(".", ",").Split(',')[0]),
                                    int.Parse(itemChild["SPQTY_500"].ToString().Replace(".", ",").Split(',')[0]),
                                    int.Parse(itemChild["SPQTY_750"].ToString().Replace(".", ",").Split(',')[0]),
                                    int.Parse(itemChild["SPQTY_1000"].ToString().Replace(".", ",").Split(',')[0]),
                                    int.Parse(itemChild["SPQTY_2000"].ToString().Replace(".", ",").Split(',')[0]),
                                    0,
                                    0,
                                    "",
                                    (float)prezzo
                                );

                                item.Children.Add(child);
                            }

                            if (item.Children.Count > 0)
                            {
                                returnList.Add(item);
                            }
                        }

                        string queryDescCZ = "SELECT MPDSC, COALESCE(PPCOMM, '') AS NOTE FROM DBSAITE b " +
                            " LEFT JOIN DBSAITX c ON c.PPUSER = b.MITEM AND c.MCOSC = b.MCOSC AND C.PPTXTC = 'IC' AND C.PPSEQT = 1" +
                            $" WHERE b.MITEM = '{articolo}' AND b.MCOSC = '{societa}'";

                        var articoloTrovato = DbHelper.ExecuteSafeQuery(_connectionStringP, queryDescCZ);

                        ItemModel codiceZero = new ItemModel(
                            articolo,
                            articoloTrovato[0]["MPDSC"].ToString().Trim(),
                            articolo,
                            articoloTrovato[0]["NOTE"].ToString().Trim(),
                            1,
                            1
                        );

                        var ricambiCZ = allRicambiSuggeriti.Where(element => element["MITEM"].ToString().Trim() == codiceZero.Component.Trim() && (int.Parse(element["LEVEL"].ToString().Trim())) == codiceZero.Level).ToList();

                        foreach (var itemChild in ricambiCZ)
                        {
                            versione = versione == "" ? "0" : versione;

                            query = $"SELECT OLQNEPR/10000 AS PREZZO FROM OCSAQUO WHERE OLQTYPE='{tipolistino}' AND OLQKEYL='CRI' AND OLQITEM= '{itemChild["SPCOMP"].ToString().Trim()}' AND OLQVERL={versione} AND OLQCOSC='{societa}'";
                            var prezziList = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

                            double prezzo = 0;

                            if (prezziList.Count > 0)
                            {
                                prezzo = double.Parse(prezziList[0]["PREZZO"].ToString());
                            }

                            ItemChildModel child = new ItemChildModel(
                                itemChild["SPCOMP"].ToString().Trim(),
                                itemChild["MPDSC"].ToString().Trim(),
                                itemChild["AGGNTUSR"].ToString(),
                                int.Parse(itemChild["SPQTY_250"].ToString().Replace(".", ",").Split(',')[0]),
                                int.Parse(itemChild["SPQTY_500"].ToString().Replace(".", ",").Split(',')[0]),
                                int.Parse(itemChild["SPQTY_750"].ToString().Replace(".", ",").Split(',')[0]),
                                int.Parse(itemChild["SPQTY_1000"].ToString().Replace(".", ",").Split(',')[0]),
                                int.Parse(itemChild["SPQTY_2000"].ToString().Replace(".", ",").Split(',')[0]),
                                0,
                                0,
                                "",
                                (float)prezzo
                            );

                            codiceZero.Children.Add(child);
                        }

                        if (codiceZero.Children.Count > 0)
                        {
                            returnList.Add(codiceZero);
                        }
                    }

                    Console.WriteLine($"Elaborazione terminata in data {DateTime.Now.ToString("dd-MM-yyyy HH:mm:ss")}");
                }
            }

            return returnList;
        }

        // -----------------------------------------------------------------------------------------------------------

        public List<Dictionary<string, object>> GetEsplosioneScalareArticolo(string articolo, string societa = "CSPRO")
        {
            List<Dictionary<string, object>> returnList = new List<Dictionary<string, object>>();
            string query = $"SELECT * FROM TABLE(CS_DISTINTA_SCALARE_FN('{societa}', '{articolo}')) db ORDER BY SPSQNO";
            var listaEsplosione = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            returnList = EsplosioneRicorsiva(listaEsplosione, articolo, 1, 1, articolo);

            return returnList;
        }

        //-----------------------------------------------------------------------------------------------------------

        public List<Dictionary<string, object>> GetArticoloMatricoleRilevate(string articolo, string societa = "CSPRO")
        {
            List<Dictionary<string, object>> returnList = new List<Dictionary<string, object>>();
            string query = $"SELECT * FROM ( " +
                $"    SELECT* FROM(" +
                $"       SELECT db.*, (SELECT MCLPERI FROM DBSAITE WHERE(MITEM = db.SPCOMP AND MCOSC = db.SOC)) AS MCLPERI " +
                $"            FROM TABLE(CS_DISTINTA_SCALARE_FN('{societa}', '{articolo}')) db " +
                $"       )" +
                $"    WHERE(" +
                $"       (MITEM NOT LIKE '27309%' AND MITEM NOT LIKE '27306%' AND MITEM NOT LIKE '27307%' AND MITEM NOT LIKE '27316%') AND " +
                $"      (SPCOMP NOT LIKE '27309%' AND SPCOMP NOT LIKE '27306%' AND SPCOMP NOT LIKE '27307%'  AND SPCOMP NOT LIKE '27316%') " +
                $"	)" +
                $") TEST1 WHERE " +
                $" TEST1.SPPHAN = 'P'" +
                $" OR TEST1.MCLPERI = 'T'" +
                $" OR(TEST1.SPCOMP LIKE '11023%' OR TEST1.SPCOMP LIKE '11029%' OR TEST1.SPCOMP LIKE '10110%' OR TEST1.SPCOMP LIKE '11048%')" +
                $" OR TEST1.SPCOMP IN(" +
                $"     SELECT DISTINCT MITEM FROM (" +
                $"         SELECT* FROM (" +
                $"             SELECT db.*, (SELECT MCLPERI FROM DBSAITE WHERE(MITEM = db.SPCOMP AND MCOSC = db.SOC)) AS MCLPERI" +
                $"                 FROM TABLE(CS_DISTINTA_SCALARE_FN('{societa}', '{articolo}')) db" +
                $" 	        )" +
                $" 	    WHERE(" +
                $"            (MITEM NOT LIKE '27309%' AND MITEM NOT LIKE '27306%' AND MITEM NOT LIKE '27307%' AND MITEM NOT LIKE '27316%') AND" +
                $"           (SPCOMP NOT LIKE '27309%' AND SPCOMP NOT LIKE '27306%' AND SPCOMP NOT LIKE '27307%'  AND SPCOMP NOT LIKE '27316%')" +
                $" 		)" +
                $" 	) TEST WHERE" +
                $"    TEST.SPPHAN = 'P'" +
                $"    OR TEST.MCLPERI = 'T'" +
                $"    OR(TEST.SPCOMP LIKE '11023%' OR TEST.SPCOMP LIKE '11029%' OR TEST.SPCOMP LIKE '10110%' OR TEST.SPCOMP LIKE '11048%')" +
                $"    AND TEST1.SPCOMP = TEST.MITEM" +
                $" )" +
                $" ORDER BY CHIAVE";
            var listaEsplosione = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            returnList = EsplosioneRicorsiva(listaEsplosione, articolo, 1, 1, articolo);

            return returnList;
        }

        // -----------------------------------------------------------------------------------------------------------

        private List<Dictionary<string, object>> EsplosioneRicorsiva(List<Dictionary<string, object>> articoli, string codicePadre, int level, int qtaPadre, string chiavePapaPrima)
        {
            List<Dictionary<string, object>> returnList = new List<Dictionary<string, object>>();
            var listSearch = articoli.Where((element) => element["MITEM"].ToString().Trim() == codicePadre && element["LEVEL"].ToString().Trim() == level.ToString() && element["CHIAVE"].ToString().Trim().StartsWith(chiavePapaPrima.ToString().Trim())).ToList();

            foreach (var articolo in listSearch)
            {
                Dictionary<string, object> item = new()
                {
                    ["ID"] = articolo["SPCOMP"].ToString().Trim(),
                    ["DESCRIZIONE"] = articolo["MPDSC"].ToString().Trim(),
                    ["SPSQNO"] = articolo["SPSQNO"].ToString().Trim(),
                    ["LEVEL"] = articolo["LEVEL"].ToString().Trim(),
                    ["CHILDREN"] = EsplosioneRicorsiva(articoli, articolo["SPCOMP"].ToString().Trim(), int.Parse(articolo["LEVEL"].ToString().Trim()) + 1, qtaPadre * (int)double.Parse(articolo["SPQTY"].ToString().Trim()), articolo["CHIAVE"].ToString().Trim()),
                    ["MCLPERI"] = (articolo.ContainsKey("MCLPERI") ? articolo["MCLPERI"] : "").ToString().Trim(),
                    ["SPQTY"] = ((int)double.Parse(articolo["SPQTY"].ToString().Trim())) * qtaPadre,
                    ["UM"] = articolo["MUTMS"].ToString().Trim()
                };

                returnList.Add(item);
            }

            return returnList;
        }

        // -----------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Recupera le informazioni di un articolo.
        /// </summary>
        /// <param name="articolo">Identificativo dell'articolo (obbligatorio).</param>
        /// <param name="societa">Codice della società (default "CSPRO").</param>
        /// <returns>Un oggetto <see cref="ItemInfoModel"/> contenente le informazioni dell'articolo.</returns>
        /// <exception cref="Exception">Lancia un'eccezione se l'articolo non è stato specificato.</exception>
        public ItemInfoModel GetInfoArticolo(string? articolo = null, string societa = "CSPRO")
        {
            string query = "SELECT MITEM, MPDSC, MSTAIT, MTYPN, MUTMS, MWEIGHT, MFORCD, MBREAD, MHEIGH, MPALLET " +
                           "FROM DBSAITE ";

            ItemInfoModel art = new ItemInfoModel("NOT FOUND", "", "", "", "", 0, "", 0, 0, 0);

            if (articolo != null)
            {
                query += $"WHERE MCOSC = '{societa}' AND MITEM = '{articolo}' ";
            }
            else
            {
                throw (new Exception("L'articolo non è stato specificato"));
            }

            using (OdbcDataReader reader = DbHelper.ExecuteQuery(_connectionStringP, query))
            {
                if (reader.Read())
                {
                    art = new ItemInfoModel(
                        reader.GetString(0).Trim(),
                        reader.GetString(1).Trim(),
                        reader.GetString(2).Trim(),
                        reader.GetString(3).Trim(),
                        reader.GetString(4).Trim(),
                        reader.GetInt32(5) / 100,
                        reader.GetString(6).Trim(),
                        reader.GetInt32(7) / 100,
                        reader.GetInt32(8) / 100,
                        reader.GetInt32(9) / 100
                    );
                }
            }

            return art;
        }

        public Dictionary<string, dynamic>? GetPrezzoArticolo(string articolo, string societa)
        {
            string query = $"SELECT OLQNEPR/10000 AS PREZZO FROM OCSAQUO WHERE OLQTYPE = 'RC' AND OLQCOSC = '{societa}' AND OLQKEYL = 'CRI' AND OLQITEM = '{articolo}' " +
                $" AND CONCAT(LPAD(OLQVERL, 10, '0'), LPAD(OLQSEQQ, 5, '0')) = " +
                $" (SELECT CONCAT(LPAD(OLQVERL, 10, '0'), LPAD(OLQSEQQ, 5, '0')) FROM OCSAQUO OCSAQUO1 " +
                $" WHERE OCSAQUO1.OLQTYPE = 'RC' AND OCSAQUO1.OLQCOSC = '{societa}' " +
                $" AND OCSAQUO1.OLQKEYL = 'CRI' AND OCSAQUO1.OLQITEM = OCSAQUO.OLQITEM " +
                $" ORDER BY CONCAT(LPAD(OLQVERL, 10, '0'), LPAD(OLQSEQQ, 5, '0')) DESC " +
                $" FETCH FIRST 1 ROWS ONLY)";

            var result = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            if (result.Count > 0)
            {
                return result[0];
            }
            else
            {
                return null;
            }
        }

        /// <summary>
        /// Recupera una lista di articoli in base alla descrizione.
        /// </summary>
        /// <param name="description">Descrizione (o parte di essa) da cercare (obbligatoria).</param>
        /// <param name="societa">Codice della società (default "CSPRO").</param>
        /// <returns>Una lista di <see cref="ItemModel"/> contenente gli articoli trovati.</returns>
        /// <exception cref="Exception">Lancia un'eccezione se la descrizione non è stata specificata.</exception>
        public List<ItemModel> GetDescArticolo(string? description = null, string societa = "CSPRO")
        {
            List<ItemModel> descList = new();

            string query = "SELECT MITEM, MPDSC " +
                           "FROM DBSAITE ";

            if (description != null)
            {
                query += $"WHERE MPDSC LIKE '{description}%' AND MCOSC = '{societa}' ";
            }
            else
            {
                throw (new Exception("La descrizione non è stato specificato"));
            }

            using (OdbcDataReader reader = DbHelper.ExecuteQuery(_connectionStringP, query))
            {
                while (reader.Read())
                {
                    // Aggiunge l'articolo alla lista
                    descList.Add(new ItemModel(reader.GetString(0).Trim(), reader.GetString(1).Trim(), "", "", 0, 0));
                }
            }
            return descList;
        }

        public List<Dictionary<string, dynamic>> GetArticoliSocieta(string societa, bool all = false)
        {
            string query = "SELECT DBSAITE.MITEM, DBSAITE.MPDSC " +
                           $"FROM DBSAITE " +
                           $"INNER JOIN DBSAFCA ON DBSAITE.MITEM = DBSAFCA.MITEM AND DBSAITE.MCOSC = DBSAFCA.MCOSC " +
                           $"WHERE DBSAITE.MCOSC = '{societa}' AND DBSAITE.MITEM NOT LIKE 'SE%'";

            if (!all)
            {
                query += " AND DBSAFCA.MLTCD = 'P'";
            }

            var itemList = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            return itemList;
        }

        public List<Dictionary<string, object>> GetItemsFM(string societa)
        {
            string query = $"SELECT MITEM, MPDSC FROM DBSAITE WHERE MCOSC = '{societa}' AND MITEM LIKE 'FM%'";
            var articoliFM = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            return articoliFM;
        }

        public List<Dictionary<string, object>> GetFmPrior(string societa)
        {
            string query = $"SELECT CSPRIFM.*, MPDSC FROM CSPRIFM LEFT JOIN DBSAITE ON MITEM = CSFMPRD AND MCOSC = '{societa}' ORDER BY CSPRIOR";
            var priorFM = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            return priorFM;
        }

        public List<Dictionary<string, dynamic>> SavePriorFM(string societa, List<Dictionary<string, object>> listaPrior)
        {
            string query = "DELETE FROM CSPRIFM";
            DbHelper.ExecuteNonQuery(_connectionStringP, query);

            foreach (var fm in listaPrior)
            {
                query = $"INSERT INTO CSPRIFM(CSFMPRD, CSPRIOR) VALUES ('{fm["CSFMPRD"].ToString().Trim()}', {fm["CSPRIOR"].ToString().Trim()})";
                DbHelper.ExecuteSafeQuery(_connectionStringP, query);
            }

            return GetFmPrior(societa);
        }


        public List<Dictionary<string, dynamic>> GetMatricole(string societa)
        {
            string query = $"SELECT MITEM AS MEITEM, COALESCE(MEMATR,'N/D') AS MEMATR, COALESCE(MEDESC, MPDSC) AS MEDESC  FROM DBSAITE " +
                $" LEFT JOIN MTSAITE ON MEITEM = MITEM AND MCOSC = MECOSC" +
                $" WHERE MTYPN = '6' AND MCOSC = '{societa}'";

            var matricoleList = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            return matricoleList;
        }

        public List<Dictionary<string, dynamic>> GetArticoliTraduzioni(List<Dictionary<string, object>> righe, string lingua)
        {
            string inWhereClause = "(";

            foreach (var riga in righe)
            {
                inWhereClause += $"'{riga["CSITEM"].ToString().Trim()}'";

                if (righe.IndexOf(riga) != righe.Count - 1)
                {
                    inWhereClause += ", ";
                }
            }

            inWhereClause += ")";

            string query = $"SELECT PPUSER, PPCOMM FROM DBSAITX WHERE PPTXTC = '{lingua}C' AND MCOSC = 'CSPRO' AND PPSEQT = 1 AND PPUSER IN {inWhereClause}";
            var righeTradotte = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            for (int i = 0; i < righe.Count; i++)
            {
                var trovato = false;
                Dictionary<string, dynamic> element = new Dictionary<string, dynamic>();

                foreach (var traduzione in righeTradotte)
                {
                    if (traduzione["PPUSER"].ToString().Trim() == righe[i]["CSITEM"].ToString().Trim())
                    {
                        trovato = true;
                        element = traduzione;
                    }
                }

                if (trovato)
                {
                    righe[i]["DESCR_ARTICOLO"] = element["PPCOMM"].ToString();
                }
                else
                {
                    righe[i]["DESCR_ARTICOLO"] = "TRADUZIONE NON TROVATA";
                    //query = $"SELECT PPUSER, PPCOMM FROM DBSAITX WHERE PPTXTC = 'IC' AND MCOSC = 'CSPRO' AND PPSEQT = 1 AND PPUSER = '{righe[i]["CSITEM"].ToString().Trim()}'";
                    //var traduzioneAlternativa = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

                    //if(traduzioneAlternativa.Count > 0)
                    //{
                    //    righe[i]["DESCR_ARTICOLO"] = traduzioneAlternativa[0]["PPCOMM"].ToString();
                    //}
                    //else
                    //{
                    //    righe[i]["DESCR_ARTICOLO"] = "TRADUZIONE NON TROVATA";
                    //}
                }

                query = $"SELECT a.MITEM, a.MCODFUN AS COD_FUN, COALESCE((SELECT a2.MPDSC FROM DBSAITE a2 WHERE a2.MITEM = a.MCODFUN AND a2.MCOSC = a.MCOSC), '') AS DESC_COD_FUN FROM DBSAITE a WHERE a.MITEM = '{righe[i]["CSITEM"].ToString().Trim()}' AND a.MCOSC = 'CSPRO'";

                var codFunzionale = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

                if (codFunzionale.Count > 0)
                {
                    righe[i]["COD_FUNZIONALE"] = codFunzionale[0]["COD_FUN"].ToString().Trim();
                }
                else
                {
                    righe[i]["COD_FUNZIONALE"] = "";
                }
            }

            return righe;
        }

        public List<Dictionary<string, dynamic>> GetTabellaSconti(string societa)
        {
            string query = $"SELECT TBKEY, LEFT(TBDATI,30) AS DESCR FROM TBITEM WHERE TBPROC = 'AV' AND TBTABE = 'SC' AND TBDITTA = '{societa}' ORDER BY TBKEY ASC";
            var tabellaSconti = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            foreach (var sconto in tabellaSconti)
            {
                query = $"SELECT O1.OSSTXVA/100 AS SCONTO FROM OCSASCV O1 WHERE OSSCOSC = '{societa}' AND OSSTYPE = '{sconto["TBKEY"].ToString().Trim()}' AND OSSITEM = 'ALL' AND EXISTS (SELECT 'MAX/LAST OSSVERS' FROM OCSASCV o2 WHERE o2.OSSTYPE = O1.OSSTYPE AND o2.OSSITEM = O1.OSSITEM AND o2.OSSCOSC = O1.OSSCOSC GROUP BY o2.OSSTYPE, o2.OSSITEM, o2.OSSCOSC HAVING MAX(O2.OSSVERS) = O1.OSSVERS)";
                sconto["SCONTI"] = DbHelper.ExecuteSafeQuery(_connectionStringP, query);
            }

            return tabellaSconti;
        }

        public List<Dictionary<string, dynamic>> GetArticoliMacchina(string societa)
        {
            string query = "SELECT DBSAITE.MITEM, DBSAITE.MPDSC " +
                           $"FROM DBSAITE " +
                           $"WHERE DBSAITE.MCOSC = '{societa}' AND (DBSAITE.MITEM LIKE '0%' OR DBSAITE.MITEM LIKE 'U%') ";

            var itemList = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            return itemList;
        }

        public List<Dictionary<string, dynamic>> GetNationCode()
        {
            string query = $"SELECT DISTINCT(COD_NAZIONE) AS COD_NAZIONE, DESCR_BREVE FROM TBITEM_ACNA";
            var nationList = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            return nationList;
        }

        public List<Dictionary<string, dynamic>> GetArticoloComponentiUsura(string codiceArticolo, string usura, string societa)
        {
            if (societa == "CSCSPRO")
            {
                societa = "CSPRO";
            }
            else if (societa == "CSCSUSA")
            {
                societa = "CSUSA";
            }
            else
            {
                societa = "HUT00";
            }

            string query = $"SELECT * FROM CS_DISTINTA_SCALARE_USURA5_V V" +
                                $" WHERE V.RADICE = '{codiceArticolo}'" +
                                $" AND V.SOC = '{societa}' ORDER BY V.CHIAVE";
            var allRicambiUsura = DbHelper.ExecuteSafeQuery(_connectionStringP, query);

            int nVolte = 1;
            var convUsura = int.Parse(usura);
            if (convUsura > 1000)
            {
                nVolte = convUsura / 1000;
            }

            List<Dictionary<string, dynamic>> _returnList = new List<Dictionary<string, dynamic>>();

            foreach (var articolo in allRicambiUsura)
            {
                if ((decimal)articolo["AGGNTUSR"] <= convUsura)
                {
                    var molt = convUsura / (decimal)articolo["AGGNTUSR"];

                    articolo["SPQTY3"] = (decimal)articolo["SPQTY3"] * molt;
                    var prezzo = GetPrezzoArticolo(articolo["SPCOMP"].ToString().Trim(), societa);

                    if (prezzo != null)
                    {
                        articolo["PREZZO_LISTINO"] = prezzo["PREZZO"];
                    }
                    else
                    {
                        articolo["PREZZO_LISTINO"] = 0;
                    }

                    var listCount = _returnList.Where((element) => element["SPCOMP"].ToString() == articolo["SPCOMP"].ToString()).ToList().Count();

                    if (listCount > 0)
                    {
                        _returnList.Where((element) => element["SPCOMP"].ToString() == articolo["SPCOMP"].ToString()).First()["SPQTY3"] += (decimal)articolo["SPQTY3"];
                    }
                    else
                    {
                        _returnList.Add(articolo);
                    }
                }
            }

            return _returnList;
        }
    }
}
