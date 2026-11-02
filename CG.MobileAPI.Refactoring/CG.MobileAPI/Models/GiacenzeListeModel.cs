using System.Data.Odbc;
using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;
using CG.MobileAPI.Data;
using CG.MobileAPI.Tools;

namespace CG.MobileAPI.Models
{
    // =================================================================================================================
    // ----- RICHIESTE -------------------------------------------------------------------------------------------------
    // =================================================================================================================

    /// <summary>Richiesta di addInfoOdlStampaVern (ex addInfoOdlStampaVern.php).</summary>
    public class AddInfoOdlStampaVernRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
    }

    /// <summary>Richiesta di addInfoOdlStampaVernLibera (ex addInfoOdlStampaVernLibera.php).</summary>
    public class AddInfoOdlStampaVernLiberaRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
    }

    /// <summary>Richiesta di addInfoPadreStampaVernLibera (ex addInfoPadreStampaVernLibera.php).</summary>
    public class AddInfoPadreStampaVernLiberaRequest
    {
        /// <summary>Codice articolo padre.</summary>
        public string? padre { get; set; }
    }

    /// <summary>Richiesta di addPadreDescrizioneFixToMovimento (ex addPadreDescrizioneFixToMovimento.php).</summary>
    public class AddPadreDescrizioneFixToMovimentoRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
    }

    /// <summary>Richiesta di cambiaStatoLista (ex cambiaStatoLista.php). L'utente di chiusura è quello del token.</summary>
    public class CambiaStatoListaRequest
    {
        /// <summary>Id della lista (liste_testate.id).</summary>
        public string? id { get; set; }
        /// <summary>Nuovo stato: 0 = riaperta, 1 = archiviata, 9 = eliminata.</summary>
        public string? stato { get; set; }
    }

    /// <summary>Richiesta di checkOdlListaPrelievoMgautAndGetFasi (ex checkOdlListaPrelievoMgautAndGetFasi.php).</summary>
    public class CheckOdlListaPrelievoMgautAndGetFasiRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
    }

    /// <summary>Richiesta di checkOdvListaPrelievoMgaut (ex checkOdvListaPrelievoMgaut.php).</summary>
    public class CheckOdvListaPrelievoMgautRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Numero ODV.</summary>
        public string? odv { get; set; }
    }

    /// <summary>Richiesta di deleteListaPrelievo (ex deleteListaPrelievo.php).</summary>
    public class DeleteListaPrelievoRequest
    {
        /// <summary>Tipo prelievo.</summary>
        public string? tipoprel { get; set; }
        /// <summary>Riferimento prelievo.</summary>
        public string? rifprel { get; set; }
        /// <summary>Sotto-riferimento prelievo.</summary>
        public string? subrifprel { get; set; }
        /// <summary>Sequenza prelievo.</summary>
        public string? seqprel { get; set; }
    }

    /// <summary>Richiesta di eliminaRiga (ex eliminaRiga.php).</summary>
    public class EliminaRigaRequest
    {
        /// <summary>Id della riga (liste_righe.id).</summary>
        public string? id { get; set; }
    }

    /// <summary>Richiesta di getListaPrelievi0027FromAttivitaCheckScript (ex getListaPrelievi0027FromAttivitaCheckScript.php).</summary>
    public class GetListaPrelievi0027FromAttivitaCheckScriptRequest
    {
        /// <summary>Articolo dell'avviso.</summary>
        public string? articolo_avviso { get; set; }
        /// <summary>ODL dell'avviso.</summary>
        public string? odl_avviso { get; set; }
        /// <summary>Timestamp numerico dell'avviso (confrontato con MASATRN.TRDATE).</summary>
        public string? timest_avviso { get; set; }
    }

    /// <summary>Richiesta di getOdlListFromMagDest (ex getOdlListFromMagDest.php).</summary>
    public class GetOdlListFromMagDestRequest
    {
        /// <summary>Magazzino di destinazione.</summary>
        public string? magazzinoDestinazione { get; set; }
        /// <summary>True se la richiesta arriva dalla sezione Prelievi (lista ODL + ODV).</summary>
        public bool? inviatoDaPrelievi { get; set; }
    }

    /// <summary>Richiesta di getStoriaMovimento (ex getStoriaMovimento.php).</summary>
    public class GetStoriaMovimentoRequest
    {
        /// <summary>Codice utente del movimento ('' = qualsiasi utente).</summary>
        public string? utente { get; set; }
        /// <summary>Data dell'aggiornamento mancanti (0 = storico utente).</summary>
        public string? dtrun { get; set; }
        /// <summary>Ora dell'aggiornamento mancanti (0 = storico utente).</summary>
        public string? hrrun { get; set; }
        /// <summary>Magazzino di impegno ('' = qualsiasi).</summary>
        public string? magazzino_impegno { get; set; }
        /// <summary>Sezione dell'app.</summary>
        public string? sezione { get; set; }
    }

    /// <summary>Richiesta di getStoriaMovimentoOggi (ex getStoriaMovimentoOggi.php).</summary>
    public class GetStoriaMovimentoOggiRequest
    {
        /// <summary>Codice utente del movimento.</summary>
        public string? utente { get; set; }
        /// <summary>Magazzino di impegno.</summary>
        public string? magazzino_impegno { get; set; }
        /// <summary>Sezione dell'app.</summary>
        public string? sezione { get; set; }
    }

    /// <summary>Richiesta di getStoriaPrelieviMgis001 (ex getStoriaPrelieviMgis001.php).</summary>
    public class GetStoriaPrelieviMgis001Request
    {
        /// <summary>Codice utente.</summary>
        public string? utente { get; set; }
    }

    /// <summary>Richiesta di mgaut_prel_immediato_get_odv_from_prebolla (ex mgaut_prel_immediato_get_odv_from_prebolla.php).</summary>
    public class MgautPrelImmediatoGetOdvFromPrebollaRequest
    {
        /// <summary>Numero prebolla (con o senza prefisso "PRB/").</summary>
        public string? prebolla { get; set; }
    }

    /// <summary>Richiesta di mgaut_prel_immediato_get_righe_from_odv (ex mgaut_prel_immediato_get_righe_from_odv.php).</summary>
    public class MgautPrelImmediatoGetRigheFromOdvRequest
    {
        /// <summary>Numero ODV (OR / OM).</summary>
        public string? odv { get; set; }
    }

    /// <summary>Richiesta di mgaut_prel_odl_get_articoli (ex mgaut_prel_odl_get_articoli.php).</summary>
    public class MgautPrelOdlGetArticoliRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
        /// <summary>Magazzino automatico di origine.</summary>
        public string? magazzino_origine { get; set; }
        /// <summary>Magazzino di destinazione.</summary>
        public string? magazzino_destinazione { get; set; }
    }

    /// <summary>Richiesta di mgaut_prel_odl_get_magazzini (ex mgaut_prel_odl_get_magazzini.php).</summary>
    public class MgautPrelOdlGetMagazziniRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Magazzino automatico di origine.</summary>
        public string? magazzino_origine { get; set; }
    }

    /// <summary>Richiesta di mgaut_prel_odl_get_odl (ex mgaut_prel_odl_get_odl.php).</summary>
    public class MgautPrelOdlGetOdlRequest
    {
        /// <summary>Codice articolo ('' = tutti).</summary>
        public string? articolo { get; set; }
        /// <summary>Magazzino automatico di origine.</summary>
        public string? magazzino_origine { get; set; }
        /// <summary>Magazzino di destinazione.</summary>
        public string? magazzino_destinazione { get; set; }
    }

    /// <summary>Richiesta di mgaut_prel_odv_get_articoli (ex mgaut_prel_odv_get_articoli.php).</summary>
    public class MgautPrelOdvGetArticoliRequest
    {
        /// <summary>Numero ODV.</summary>
        public string? odv { get; set; }
        /// <summary>Magazzino automatico di origine.</summary>
        public string? magazzino_origine { get; set; }
        /// <summary>Magazzino di destinazione.</summary>
        public string? magazzino_destinazione { get; set; }
    }

    /// <summary>Richiesta di mgaut_prel_odv_get_magazzini (ex mgaut_prel_odv_get_magazzini.php).</summary>
    public class MgautPrelOdvGetMagazziniRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Magazzino automatico di origine.</summary>
        public string? magazzino_origine { get; set; }
    }

    /// <summary>Richiesta di mgaut_prel_odv_get_odv (ex mgaut_prel_odv_get_odv.php).</summary>
    public class MgautPrelOdvGetOdvRequest
    {
        /// <summary>Codice articolo ('' = tutti).</summary>
        public string? articolo { get; set; }
        /// <summary>Magazzino automatico di origine.</summary>
        public string? magazzino_origine { get; set; }
        /// <summary>Magazzino di destinazione.</summary>
        public string? magazzino_destinazione { get; set; }
    }

    /// <summary>Richiesta di selectAccettazioni (ex selectAccettazioni.php).</summary>
    public class SelectAccettazioniRequest
    {
        /// <summary>Magazzino.</summary>
        public string? magazzino { get; set; }
    }

    /// <summary>Richiesta di selectCambioOdl (ex selectCambioOdl.php).</summary>
    public class SelectCambioOdlRequest
    {
        /// <summary>Codice ODL, articolo padre o magazzino di destinazione.</summary>
        public string? codiceOdl_Padre_Mag { get; set; }
    }

    /// <summary>Richiesta di selectMancantiDaMag (ex selectMancantiDaMag.php).</summary>
    public class SelectMancantiDaMagRequest
    {
        /// <summary>Magazzino di impegno.</summary>
        public string? magazzinoImpegno { get; set; }
        /// <summary>True per i Mancanti (statopick = 'Y'), false per i Prelievi.</summary>
        public bool? statoPickYSelected { get; set; }
        /// <summary>ODL / ODV da filtrare ('' = tutti).</summary>
        public string? codiceOdl { get; set; }
    }

    /// <summary>Richiesta di selectRientri (ex selectRientri.php).</summary>
    public class SelectRientriRequest
    {
        /// <summary>Magazzino.</summary>
        public string? magazzino { get; set; }
    }

    /// <summary>Richiesta di updateAutomhaTrasferito (ex updateAutomhaTrasferito.php).</summary>
    public class UpdateAutomhaTrasferitoRequest
    {
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Riferimento prelievo.</summary>
        public string? rifprel { get; set; }
        /// <summary>Sotto-riferimento prelievo.</summary>
        public string? subrifprel { get; set; }
        /// <summary>Sequenza prelievo.</summary>
        public string? seqprel { get; set; }
        /// <summary>Sequenza riga.</summary>
        public string? seq { get; set; }
    }

    /// <summary>Richiesta di updateStatoStoriaMovimento (ex updateStatoStoriaMovimento.php).</summary>
    public class UpdateStatoStoriaMovimentoRequest
    {
        /// <summary>Data dell'aggiornamento mancanti.</summary>
        public string? dtrun { get; set; }
        /// <summary>Ora dell'aggiornamento mancanti.</summary>
        public string? hrrun { get; set; }
        /// <summary>Codice articolo.</summary>
        public string? articolo { get; set; }
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
        /// <summary>Fase.</summary>
        public string? fase { get; set; }
        /// <summary>Nuovo stato del movimento.</summary>
        public string? stato_mov { get; set; }
    }

    /// <summary>Richiesta di validateOdlSelectFasi (ex validateOdlSelectFasi.php).</summary>
    public class ValidateOdlSelectFasiRequest
    {
        /// <summary>Numero ODL.</summary>
        public string? odl { get; set; }
    }

    /// <summary>Richiesta di writeLista (ex writeLista.php). L'utente di creazione è quello del token.</summary>
    public class WriteListaRequest
    {
        /// <summary>Nome della lista (magazzino o vano).</summary>
        public string? nome_lista { get; set; }
        /// <summary>Tipo lista: magazzino, vano_preciso, vano_radice.</summary>
        public string? tipo_lista { get; set; }
    }

    /// <summary>
    /// Riga di inventario inviata a writeRigaLista (ex campo JSON <c>rigaLista</c>). I campi sono letti come nel PHP
    /// (json_decode + cast), quindi accettano sia numeri sia stringhe.
    /// </summary>
    public class WriteRigaListaRiga
    {
        /// <summary>Id della lista (liste_testate.id).</summary>
        public JsonElement? id_lista_testata { get; set; }
        /// <summary>Codice articolo.</summary>
        public JsonElement? articolo { get; set; }
        /// <summary>Descrizione articolo.</summary>
        public JsonElement? descrizione { get; set; }
        /// <summary>Magazzino.</summary>
        public JsonElement? magazzino { get; set; }
        /// <summary>Vano originale.</summary>
        public JsonElement? vano_originale { get; set; }
        /// <summary>Vano modificato.</summary>
        public JsonElement? vano_modificato { get; set; }
        /// <summary>Quantità originale.</summary>
        public JsonElement? qta_originale { get; set; }
        /// <summary>Quantità modificata.</summary>
        public JsonElement? qta_modificata { get; set; }
        /// <summary>Url della foto.</summary>
        public JsonElement? url_foto { get; set; }
        /// <summary>Stato della riga.</summary>
        public JsonElement? stato { get; set; }
        /// <summary>Nota.</summary>
        public JsonElement? nota { get; set; }
        /// <summary>1 se la riga è stata aggiunta a mano.</summary>
        public JsonElement? riga_aggiunta_manualmente { get; set; }
    }

    /// <summary>Richiesta di writeRigaLista (ex writeRigaLista.php). L'utente di inserimento è quello del token.</summary>
    public class WriteRigaListaRequest
    {
        /// <summary>Riga da scrivere.</summary>
        public WriteRigaListaRiga? rigaLista { get; set; }
    }

    /// <summary>Richiesta di writeStoriaMovMgis001 (ex writeStoriaMovMgis001.php). L'utente è quello del token.</summary>
    public class WriteStoriaMovMgis001Request
    {
        /// <summary>Nome della lista.</summary>
        public string? nome_lista { get; set; }
        /// <summary>Numero di errori (default 0).</summary>
        public string? errori { get; set; }
        /// <summary>Riepilogo testuale del movimento.</summary>
        public string? riepilogo_movimento { get; set; }
    }

    // =================================================================================================================
    // ----- DATA CLASS ------------------------------------------------------------------------------------------------
    // =================================================================================================================

    /// <summary>
    /// Accesso ai dati per liste, prelievi, MGAUT e storico movimenti.
    /// </summary>
    public class DBGIACENZE_LISTE
    {
        private readonly MobileConnections _conn;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="DBGIACENZE_LISTE"/>.
        /// </summary>
        /// <param name="conn">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public DBGIACENZE_LISTE(MobileConnections conn)
        {
            _conn = conn;
        }

        // -------------------------------------------------------------------------------------------------------------
        // ----- ACCETTAZIONI / PRECARICO ------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Testate di precarico non completate, ognuna con le sue righe in <c>righe</c> (ex accettazione_get_precarico.php).
        /// </summary>
        public List<Dictionary<string, object?>> AccettazioneGetPrecarico()
        {
            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();

            var lista = DbHelper.Query(conn, null, @"select * from precarico_testate
where not completato
order by data_creazione desc, ora_creazione desc");

            foreach (var testata in lista)
            {
                testata["righe"] = DbHelper.Query(conn, null, @"select * from precarico_righe
    where odl=? and fase=? and sequenza=?
    order by id", Testo(testata, "odl"), Testo(testata, "fase"), PhpInt(Testo(testata, "sequenza")));
            }

            return lista;
        }

        /// <summary>
        /// Accettazioni (entrate dell'ultimo anno) di un magazzino con i mancanti MIRC collegati (ex selectAccettazioni.php).
        /// Restituisce <c>null</c> se non ci sono movimenti (il PHP rispondeva HTTP 404).
        /// </summary>
        public Dictionary<string, object?>? SelectAccettazioni(SelectAccettazioniRequest request, string societa)
        {
            var magazzino = Obbligatorio(request.magazzino, "magazzino");

            // Articoli R già confermati dalla qualità
            var listaConfermati = DbHelper.Query(_conn.PgDb1, "select * from public.conferme_qualita_codici_r");

            var dataCorrente = Oggi() - 20000; // -1 anno

            var righe = DbHelper.Query(_conn.Db2, @"SELECT MASATRN.TDTVER, MASATRN.TTRAN, MASATRN.TRDATE, CSDBITA.CSCOLOR, MASATRN.TCHNU AS FORN, MASATRN.TNBOL AS BOLLA, MASAMSL.MALITEM AS ARTICOLO, DBSAITE.MPDSC AS DESCRIZIONE, MASAMSL.MLLOC AS MAGAZZINO, MASAMSL.MALOHQT*0.01 AS QTA_GIAC, MASAMSL.MALDTVE AS DATA_MOV, MASATRN.TMACO AS TIPO_MOV, MASATRN.TUSCO AS MOV, MASATRN.TQUAN/100 AS QTA_MOV, MASATRN.TORNUOR AS ORDINE, ANSADID.ANINCO, DBSAITE.MPALLET/100 AS PESO_LORDO, DBSAITE.MWEIGHT/100 AS PESO_NETTO, DBSAITE.DIPRO, DBSAITE.MUTMS, CSDBITA.CSTRASU
FROM MASATRN
INNER JOIN DBSAITE ON DBSAITE.MITEM = MASATRN.TRNITM AND DBSAITE.MCOSC = MASATRN.TRNSOC
INNER JOIN MASAMSL ON MASATRN.TMAG = MASAMSL.MLLOC AND MASATRN.TRNSOC = MASAMSL.MAHCOSC AND MASATRN.TRNITM = MASAMSL.MALITEM
LEFT JOIN ANSADID ON MASATRN.TRNSOC = ANSADID.ANCOSO AND MASATRN.TCHNU = ANSADID.ANCOCO
LEFT JOIN CSDBITA ON DBSAITE.MITEM = CSDBITA.CSITEMA
WHERE MASAMSL.MLLOC=?
AND MASATRN.TDTVER > ? AND MASATRN.TTRAN != 'S' AND MASATRN.TMACO LIKE 'E%'
AND MASAMSL.MAHCOSC=? AND MASATRN.TRNSOC=? AND DBSAITE.MCOSC=?
ORDER BY MASAMSL.MALITEM ASC, MASAMSL.MLLOC, MASATRN.TRDATE DESC", magazzino, dataCorrente, societa, societa, societa);

            if (righe.Count == 0) return null;

            var listaAccettazioni = new List<Dictionary<string, object?>>();
            var id = 0;
            var articoloCorrente = "";
            var magazzinoCorrente = "";
            double qtaMovimentoCorrente = 0;
            double qtaGiacenteCorrente = 0;

            foreach (var riga in righe)
            {
                var articolo = Trim(Testo(riga, "ARTICOLO"));
                var qtaMovimento = PhpFloat(Trim(Testo(riga, "QTA_MOV")));
                var qtaGiacente = PhpFloat(Trim(Testo(riga, "QTA_GIAC")));
                var bolla = Trim(Testo(riga, "BOLLA"));
                magazzino = Trim(Testo(riga, "MAGAZZINO"));

                // Per ogni articolo/magazzino tengo i movimenti finché coprono la giacenza
                if (articolo == articoloCorrente && magazzino == magazzinoCorrente)
                {
                    if (qtaMovimentoCorrente >= qtaGiacenteCorrente) continue;
                    qtaMovimentoCorrente += qtaMovimento;
                }
                else
                {
                    magazzinoCorrente = magazzino;
                    articoloCorrente = articolo;
                    qtaMovimentoCorrente = qtaMovimento;
                    qtaGiacenteCorrente = qtaGiacente;
                }

                id++;

                // Incrocio con i confermati (solo articoli R; se non è un EA è considerato confermato)
                var isRConfirmed = false;
                var tipoMovimento = Trim(Testo(riga, "TIPO_MOV"));

                if (articolo.StartsWith('R'))
                {
                    if (listaConfermati.Any(c => articolo == Testo(c, "articolo") && bolla == Testo(c, "bolla")))
                    {
                        isRConfirmed = true;
                    }

                    if (tipoMovimento != "EA") isRConfirmed = true;
                }

                listaAccettazioni.Add(new Dictionary<string, object?>
                {
                    ["id"] = id,
                    ["articolo"] = articolo,
                    ["codiceDisegno"] = Trim(Testo(riga, "DIPRO")),
                    ["pesoLordo"] = PhpFloat(Trim(Testo(riga, "PESO_LORDO"))),
                    ["pesoNetto"] = PhpFloat(Trim(Testo(riga, "PESO_NETTO"))),
                    ["descrizione"] = Trim(Testo(riga, "DESCRIZIONE")),
                    ["magazzino"] = magazzino,
                    ["qtaGiacenza"] = qtaGiacente,
                    ["dataMovimento"] = PhpInt(Trim(Testo(riga, "DATA_MOV"))),
                    ["tipoMovimento"] = tipoMovimento,
                    ["movimento"] = Trim(Testo(riga, "MOV")),
                    ["qtaMovimento"] = qtaMovimento,
                    ["ordine"] = Trim(Testo(riga, "ORDINE")),
                    ["bolla"] = bolla,
                    ["codiceFornitore"] = Trim(Testo(riga, "FORN")),
                    ["fornitore"] = SpaziMultipli(Testo(riga, "ANINCO")),
                    ["colore"] = Trim(Testo(riga, "CSCOLOR")),
                    ["um"] = Trim(Testo(riga, "MUTMS")),
                    ["trattamento"] = Trim(Testo(riga, "CSTRASU")),
                    ["isRConfirmed"] = isRConfirmed
                });
            }

            // Mancanti MIRC (il PHP usa il magazzino dell'ultima riga letta)
            var mancanti = DbHelper.Query(_conn.PgCasagrande, @"SELECT cs_fabbmanc_odl.articolo AS padre, cs_fabbmanc_odl.descarticolo as des_padre, cs_fabbmanc_odl_dispo.magdispo, cs_fabbmanc_odl_dispo.articolo, cs_fabbmanc_odl_dispo.magazzino, cs_fabbmanc_odl_comp.numero, cs_fabbmanc_odl_dispo.fase, cs_fabbmanc_odl_comp.iscritico, cs_fabbmanc_odl_dispo.giacdispo as qta
FROM cs_fabbmanc_odl_dispo
INNER JOIN cs_fabbmanc_odl_comp ON cs_fabbmanc_odl_dispo.fase = cs_fabbmanc_odl_comp.fase
AND cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_odl_dispo.articolo
AND cs_fabbmanc_odl_dispo.magazzino = cs_fabbmanc_odl_comp.magazzino
AND cs_fabbmanc_odl_dispo.numero = cs_fabbmanc_odl_comp.numero
AND cs_fabbmanc_odl_dispo.societa = cs_fabbmanc_odl_comp.societa
INNER JOIN cs_fabbmanc_odl ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero)
AND (cs_fabbmanc_odl_comp.societa = cs_fabbmanc_odl.societa)
where cs_fabbmanc_odl_comp.iscritico='1' and cs_fabbmanc_odl_comp.statopick = 'Y' and cs_fabbmanc_odl_comp.tipoarticolo != 'N' and cs_fabbmanc_odl_dispo.societa=?
and cs_fabbmanc_odl_dispo.magdispo=?
ORDER BY cs_fabbmanc_odl_dispo.articolo, cs_fabbmanc_odl_dispo.magazzino, cs_fabbmanc_odl_dispo.numero, cs_fabbmanc_odl_dispo.fase", societa, magazzino);

            return new Dictionary<string, object?>
            {
                ["listaAccettazioni"] = listaAccettazioni,
                ["listaMancantiAccettazioni"] = mancanti
            };
        }

        // -------------------------------------------------------------------------------------------------------------
        // ----- STAMPA VERNICIATURA / INFO ODL ------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        private const string QUERY_PADRE_DA_ODL = @"SELECT distinct cs_fabbmanc_odl.articolo as codicepadre, cs_fabbmanc_odl.descarticolo as descpadre, cs_fabbmanc_odl.desccolore
FROM cs_fabbmanc_odl
FULL JOIN cs_fabbmanc_odl_comp ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero) AND (cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa)
WHERE cs_fabbmanc_odl_comp.numero=? AND cs_fabbmanc_odl_comp.societa=?";

        /// <summary>
        /// Fasi (da stransfer), padre, descrizione padre e colore di un ODL per la stampa verniciatura (ex addInfoOdlStampaVern.php).
        /// </summary>
        public Dictionary<string, object?> AddInfoOdlStampaVern(AddInfoOdlStampaVernRequest request, string societa)
        {
            var odl = Obbligatorio(request.odl, "odl");
            var stampa = new Dictionary<string, object?>();

            using var conn = new OdbcConnection(_conn.PgCasagrande);
            conn.Open();

            stampa["listaFasi"] = DbHelper.Query(conn, null, @"SELECT distinct cs_fabbmanc_odl_stransfer.fasecodl as fase, cs_fabbmanc_odl_fasi.descrizione as descrizionefase
FROM cs_fabbmanc_odl_stransfer
JOIN cs_fabbmanc_odl_fasi ON (cs_fabbmanc_odl_stransfer.fasecodl = cs_fabbmanc_odl_fasi.fase) and (cs_fabbmanc_odl_stransfer.numero = cs_fabbmanc_odl_fasi.numero)
WHERE cs_fabbmanc_odl_stransfer.societa=?
AND cs_fabbmanc_odl_stransfer.statocodl > '0010'
AND cs_fabbmanc_odl_stransfer.numero=?
ORDER BY cs_fabbmanc_odl_stransfer.fasecodl", societa, odl);

            AggiungiInfoPadre(stampa, DbHelper.Query(conn, null, QUERY_PADRE_DA_ODL, odl, societa));
            if (!stampa.ContainsKey("colore") || stampa["colore"] == null) stampa["colore"] = "";

            return stampa;
        }

        /// <summary>
        /// Fasi (da cs_fabbmanc_odl_fasi), padre, descrizione padre e colore di un ODL per la stampa verniciatura libera
        /// (ex addInfoOdlStampaVernLibera.php). Se mancano le fasi o il padre restituisce solo quanto trovato fino a lì.
        /// </summary>
        public Dictionary<string, object?> AddInfoOdlStampaVernLibera(AddInfoOdlStampaVernLiberaRequest request, string societa)
        {
            var odl = Obbligatorio(request.odl, "odl");
            var stampa = new Dictionary<string, object?> { ["listaFasi"] = new List<Dictionary<string, object?>>() };

            using var conn = new OdbcConnection(_conn.PgCasagrande);
            conn.Open();

            var fasi = DbHelper.Query(conn, null, @"SELECT distinct cs_fabbmanc_odl_fasi.fase as fase, cs_fabbmanc_odl_fasi.descrizione as descrizionefase
FROM cs_fabbmanc_odl
JOIN cs_fabbmanc_odl_fasi ON cs_fabbmanc_odl.numero = cs_fabbmanc_odl_fasi.numero
WHERE cs_fabbmanc_odl.societa=?
AND cs_fabbmanc_odl.stato > '0010'
AND cs_fabbmanc_odl.numero=?
ORDER BY cs_fabbmanc_odl_fasi.fase", societa, odl);

            if (fasi.Count == 0) return stampa;
            stampa["listaFasi"] = fasi;

            var padri = DbHelper.Query(conn, null, QUERY_PADRE_DA_ODL, odl, societa);
            if (padri.Count == 0) return stampa;

            AggiungiInfoPadre(stampa, padri);
            if (stampa["colore"] == null) stampa["colore"] = "";

            return stampa;
        }

        /// <summary>
        /// Padre, descrizione padre e colore dato il codice del padre (ex addInfoPadreStampaVernLibera.php).
        /// Oggetto vuoto se non trovato.
        /// </summary>
        public Dictionary<string, object?> AddInfoPadreStampaVernLibera(AddInfoPadreStampaVernLiberaRequest request, string societa)
        {
            var padre = Obbligatorio(request.padre, "padre");
            var stampa = new Dictionary<string, object?>();

            var padri = DbHelper.Query(_conn.PgCasagrande, @"SELECT distinct cs_fabbmanc_odl.articolo as codicepadre, cs_fabbmanc_odl.descarticolo as descpadre, cs_fabbmanc_odl.desccolore
FROM cs_fabbmanc_odl
FULL JOIN cs_fabbmanc_odl_comp ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero) AND (cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa)
WHERE cs_fabbmanc_odl.articolo=? AND cs_fabbmanc_odl_comp.societa=?", padre, societa);

            if (padri.Count == 0) return stampa;

            AggiungiInfoPadre(stampa, padri);
            if (stampa["colore"] == null) stampa["colore"] = "";

            return stampa;
        }

        /// <summary>
        /// Codice e descrizione del padre di un ODL (ex addPadreDescrizioneFixToMovimento.php).
        /// </summary>
        public Dictionary<string, object?> AddPadreDescrizioneFixToMovimento(AddPadreDescrizioneFixToMovimentoRequest request, string societa)
        {
            var odl = Obbligatorio(request.odl, "odl");
            var oggettoPadre = new Dictionary<string, object?> { ["codicePadre"] = "", ["descrizionePadre"] = "" };

            var righe = DbHelper.Query(_conn.PgCasagrande, @"SELECT cs_fabbmanc_odl.articolo as padre, cs_fabbmanc_odl.descarticolo as descpadre
FROM cs_fabbmanc_odl
WHERE cs_fabbmanc_odl.numero=? and cs_fabbmanc_odl.societa=?", odl, societa);

            foreach (var riga in righe)
            {
                oggettoPadre = new Dictionary<string, object?>
                {
                    ["codicePadre"] = Testo(riga, "padre"),
                    ["descrizionePadre"] = Testo(riga, "descpadre")
                };
            }

            return oggettoPadre;
        }

        /// <summary>
        /// Fasi di un ODL con magazzino/vano di destinazione, esclusi i magazzini automatici (ex validateOdlSelectFasi.php).
        /// </summary>
        public List<Dictionary<string, object?>> ValidateOdlSelectFasi(ValidateOdlSelectFasiRequest request, string societa)
        {
            var odl = Obbligatorio(request.odl, "odl");

            return DbHelper.Query(_conn.PgCasagrande, @"SELECT distinct cs_fabbmanc_odl_stransfer.fasecodl as fase, cs_fabbmanc_odl_stransfer.magto as mag_des, cs_fabbmanc_odl_stransfer.vanoto as vano_des
FROM cs_fabbmanc_odl_stransfer
WHERE cs_fabbmanc_odl_stransfer.societa=?
AND cs_fabbmanc_odl_stransfer.statocodl > '0010'
AND cs_fabbmanc_odl_stransfer.numero=?
AND cs_fabbmanc_odl_stransfer.magto != 'MGAUT00'
AND cs_fabbmanc_odl_stransfer.magto != 'MGAUT10'
AND cs_fabbmanc_odl_stransfer.magto != 'MGAUT02'
AND cs_fabbmanc_odl_stransfer.magto != 'MGAUT03'
ORDER BY cs_fabbmanc_odl_stransfer.fasecodl, cs_fabbmanc_odl_stransfer.magto desc", societa, odl);
        }

        /// <summary>
        /// Righe di trasferimento di un ODL, oppure (se il codice è un padre o un magazzino) la lista degli ODL possibili;
        /// per la ricerca per ODL aggiunge gli altri ODL dello stesso magazzino di destinazione (ex selectCambioOdl.php).
        /// </summary>
        public Dictionary<string, object?> SelectCambioOdl(SelectCambioOdlRequest request, string societa)
        {
            var codice = Obbligatorio(request.codiceOdl_Padre_Mag, "codiceOdl_Padre_Mag");
            var cambioOdl = new Dictionary<string, object?>();

            using var conn = new OdbcConnection(_conn.PgCasagrande);
            conn.Open();

            // Prima per ODL, poi per padre, poi per magazzino
            var lista = GetListaCambioOdl(conn, codice, "odl", societa);
            if (lista.Count == 0) lista = GetListaCambioOdl(conn, codice, "Padre", societa);
            if (lista.Count == 0) lista = GetListaCambioOdl(conn, codice, "Magazzino", societa);

            cambioOdl["listaCambioOdl"] = lista;

            if (lista.Count > 0 && (string?)lista[0]["tipoRicerca"] == "odl")
            {
                cambioOdl["listaPossibiliOdl"] = DbHelper.Query(conn, null, @"SELECT DISTINCT cs_fabbmanc_odl_stransfer.numero AS ODL
    FROM cs_fabbmanc_odl
    FULL JOIN cs_fabbmanc_odl_stransfer ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_stransfer.numero) AND (cs_fabbmanc_odl.societa = cs_fabbmanc_odl_stransfer.societa)
    WHERE cs_fabbmanc_odl_stransfer.societa=? AND cs_fabbmanc_odl_stransfer.statocodl > '0010'
    AND cs_fabbmanc_odl_stransfer.magto=?
    ORDER BY cs_fabbmanc_odl_stransfer.numero", societa, (string?)lista[0]["mag_des"] ?? "");
            }

            return cambioOdl;
        }

        private static List<Dictionary<string, object?>> GetListaCambioOdl(OdbcConnection conn, string codice, string tipoCodice, string societa)
        {
            string select, where, extraJoin = "", orderBy = "";

            switch (tipoCodice)
            {
                case "odl":
                    select = @"SELECT cs_fabbmanc_odl_stransfer.numero AS ODL, cs_fabbmanc_odl_stransfer.fasecodl AS FASE, cs_fabbmanc_odl_stransfer.qtatrasfaperes as rientro, cs_fabbmanc_odl_stransfer.articolo, cs_fabbmanc_odl_stransfer.descarticolo, cs_fabbmanc_odl_stransfer.dthrtrasf AS DT_TRASF, cs_fabbmanc_odl_stransfer.qtatrasftot, cs_fabbmanc_odl_stransfer.qtatrasfape AS QTA, cs_fabbmanc_odl_stransfer.magfrom AS MAG_ORI, cs_fabbmanc_odl_stransfer.vanofrom AS VANO_ORI, cs_fabbmanc_odl_stransfer.magto AS MAG_DES, cs_fabbmanc_odl_stransfer.vanoto AS VANO_DES,
                        cs_fabbmanc_odl.articolo AS PADRE, cs_fabbmanc_odl.descarticolo AS DES_PADRE, cs_fabbmanc_odl.desccolore, cs_articoli.mpallet";
                    where = "AND cs_fabbmanc_odl_stransfer.numero=?";
                    extraJoin = "FULL JOIN cs_articoli ON cs_fabbmanc_odl_stransfer.articolo = cs_articoli.mitem";
                    orderBy = "ORDER BY cs_fabbmanc_odl_stransfer.qtatrasfaperes, cs_fabbmanc_odl_stransfer.fasecodl, cs_fabbmanc_odl_stransfer.articolo";
                    break;

                case "Padre":
                    select = "SELECT distinct cs_fabbmanc_odl_stransfer.numero AS ODL, cs_fabbmanc_odl.articolo AS PADRE, cs_fabbmanc_odl.descarticolo AS DES_PADRE";
                    where = "AND cs_fabbmanc_odl.articolo=?";
                    break;

                default: // Magazzino
                    select = "SELECT distinct cs_fabbmanc_odl_stransfer.numero AS ODL, cs_fabbmanc_odl.articolo AS PADRE, cs_fabbmanc_odl.descarticolo AS DES_PADRE";
                    where = "AND cs_fabbmanc_odl_stransfer.magto=?";
                    break;
            }

            var righe = DbHelper.Query(conn, null, $@"{select}
    FROM cs_fabbmanc_odl
    FULL JOIN cs_fabbmanc_odl_stransfer ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_stransfer.numero) AND (cs_fabbmanc_odl.societa = cs_fabbmanc_odl_stransfer.societa)
    {extraJoin}
    WHERE cs_fabbmanc_odl_stransfer.societa=? AND cs_fabbmanc_odl_stransfer.statocodl > '0010' {where}
    {orderBy}", societa, codice);

            var lista = new List<Dictionary<string, object?>>();

            foreach (var r in righe)
            {
                if (tipoCodice != "odl")
                {
                    lista.Add(new Dictionary<string, object?>
                    {
                        ["odl"] = Testo(r, "odl"),
                        ["padre"] = Testo(r, "padre"),
                        ["des_padre"] = Testo(r, "des_padre"),
                        ["tipoRicerca"] = tipoCodice
                    });
                    continue;
                }

                lista.Add(new Dictionary<string, object?>
                {
                    ["odl"] = Testo(r, "odl"),
                    ["fase"] = Testo(r, "fase"),
                    ["articolo"] = Testo(r, "articolo"),
                    ["descarticolo"] = Testo(r, "descarticolo"),
                    ["dt_trasf"] = PhpFloat(Testo(r, "dt_trasf")),
                    ["qtatrasftot"] = PhpFloat(Testo(r, "qtatrasftot")),
                    ["qta"] = PhpFloat(Testo(r, "qta")),
                    ["mag_ori"] = Testo(r, "mag_ori"),
                    ["vano_ori"] = Testo(r, "vano_ori"),
                    ["mag_des"] = Testo(r, "mag_des"),
                    ["vano_des"] = Testo(r, "vano_des"),
                    ["padre"] = Testo(r, "padre"),
                    ["des_padre"] = Testo(r, "des_padre"),
                    ["colore"] = Testo(r, "desccolore"),
                    ["pesoLordo"] = PhpFloat(Testo(r, "mpallet")),
                    ["rientro"] = PhpFloat(Testo(r, "rientro")),
                    ["tipoRicerca"] = tipoCodice
                });
            }

            return lista;
        }

        /// <summary>
        /// Elenco degli ODL (o, dalla sezione Prelievi, di ODL + ODV) che hanno come destinazione il magazzino indicato
        /// (ex getOdlListFromMagDest.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetOdlListFromMagDest(GetOdlListFromMagDestRequest request, string societa)
        {
            var magazzino = Obbligatorio(request.magazzinoDestinazione, "magazzinoDestinazione");

            if (request.inviatoDaPrelievi != true)
            {
                // Verniciatura
                return DbHelper.Query(_conn.PgCasagrande, @"SELECT distinct cs_fabbmanc_odl.numero AS ODL, cs_fabbmanc_odl.articolo AS PADRE, cs_fabbmanc_odl.descarticolo AS DES_PADRE
FROM cs_fabbmanc_odl
FULL JOIN cs_fabbmanc_odl_stransfer ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_stransfer.numero) AND (cs_fabbmanc_odl.societa = cs_fabbmanc_odl_stransfer.societa)
WHERE cs_fabbmanc_odl_stransfer.societa=? AND cs_fabbmanc_odl_stransfer.magto = ? AND cs_fabbmanc_odl_stransfer.statocodl > '0010'
ORDER BY cs_fabbmanc_odl.numero", societa, magazzino);
            }

            using var conn = new OdbcConnection(_conn.PgCasagrande);
            conn.Open();

            // Lista ODL
            var lista = DbHelper.Query(conn, null, @"select distinct cs_fabbmanc_odl.numero as odl, cs_fabbmanc_odl.articolo AS padre, cs_fabbmanc_odl.descarticolo as des_padre, cs_fabbmanc_odl.fabbdate
    from cs_fabbmanc_odl
    inner join cs_fabbmanc_odl_comp on cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero AND cs_fabbmanc_odl_comp.societa = cs_fabbmanc_odl.societa
    inner join cs_fabbmanc_odl_dispo on cs_fabbmanc_odl_dispo.fase = cs_fabbmanc_odl_comp.fase AND cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_odl_dispo.articolo AND cs_fabbmanc_odl_dispo.magazzino = cs_fabbmanc_odl_comp.magazzino AND cs_fabbmanc_odl_dispo.numero = cs_fabbmanc_odl_comp.numero AND cs_fabbmanc_odl_dispo.societa = cs_fabbmanc_odl_comp.societa
    WHERE cs_fabbmanc_odl_comp.statopick != 'Y' and cs_fabbmanc_odl_comp.statopick != '' and cs_fabbmanc_odl.societa=?
    AND cs_fabbmanc_odl_dispo.magazzino = ? and cs_fabbmanc_odl_comp.tipoarticolo != 'N'
    ORDER BY cs_fabbmanc_odl.fabbdate", societa, magazzino);

            // Lista ODV (una delle due è per forza vuota)
            lista.AddRange(DbHelper.Query(conn, null, @"select distinct cs_fabbmanc_rodv.numero as odl, cs_fabbmanc_odv.cliente as padre, cs_fabbmanc_odv.nomecliente as des_padre
                from cs_fabbmanc_rodv
                inner join cs_fabbmanc_odv on cs_fabbmanc_odv.societa = cs_fabbmanc_rodv.societa and cs_fabbmanc_odv.numero = cs_fabbmanc_rodv.numero
                inner join cs_fabbmanc_rodv_dispo ON (cs_fabbmanc_rodv_dispo.numero = cs_fabbmanc_rodv.numero and cs_fabbmanc_rodv_dispo.pos = cs_fabbmanc_rodv.pos and cs_fabbmanc_rodv_dispo.seq = cs_fabbmanc_rodv.seq and cs_fabbmanc_rodv_dispo.societa = cs_fabbmanc_rodv.societa)
                where magazzino=? and cs_fabbmanc_rodv.societa=? order by cs_fabbmanc_rodv.numero", magazzino, societa));

            return lista;
        }

        // -------------------------------------------------------------------------------------------------------------
        // ----- MANCANTI / RIENTRI ------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Numero di mancanti critici per magazzino di impegno e ultimo data-log (ex countMancantiSearchPage.php).
        /// </summary>
        public Dictionary<string, object?> CountMancantiSearchPage(string societa)
        {
            using var conn = new OdbcConnection(_conn.PgCasagrande);
            conn.Open();

            var righe = DbHelper.Query(conn, null, @"select cs_fabbmanc_odl_dispo.magazzino
from cs_fabbmanc_odl_dispo
inner join cs_fabbmanc_odl_comp ON cs_fabbmanc_odl_dispo.fase = cs_fabbmanc_odl_comp.fase
and cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_odl_dispo.articolo
and cs_fabbmanc_odl_dispo.magazzino = cs_fabbmanc_odl_comp.magazzino
and cs_fabbmanc_odl_dispo.numero = cs_fabbmanc_odl_comp.numero
and cs_fabbmanc_odl_dispo.societa = cs_fabbmanc_odl_comp.societa
where cs_fabbmanc_odl_comp.statopick = 'Y'
  and cs_fabbmanc_odl_dispo.societa=?
and cs_fabbmanc_odl_dispo.isauto='0'
and cs_fabbmanc_odl_comp.iscritico = '1'
and cs_fabbmanc_odl_comp.tipoarticolo != 'N'
and cs_fabbmanc_odl_dispo.magdispo not like 'MEF%'
and cs_fabbmanc_odl_dispo.magdispo not like 'MC%'
and cs_fabbmanc_odl_dispo.magdispo not like 'MN%'
and cs_fabbmanc_odl_dispo.magdispo not like 'MGFURG%'
order by cs_fabbmanc_odl_dispo.magazzino", societa);

            // Raggruppo le righe (già ordinate) per magazzino
            var mancanti = new List<Dictionary<string, object?>>();
            string? magazzinoCorrente = "";

            foreach (var riga in righe)
            {
                var magazzino = Testo(riga, "magazzino");

                if (magazzinoCorrente != magazzino)
                {
                    magazzinoCorrente = magazzino;
                    mancanti.Add(new Dictionary<string, object?> { ["magazzino"] = magazzino, ["count"] = 1 });
                }
                else
                {
                    mancanti[^1]["count"] = (int)mancanti[^1]["count"]! + 1;
                }
            }

            var oggetto = new Dictionary<string, object?> { ["mancanti"] = mancanti };

            var dataLog = DbHelper.Query(conn, null, "select * from cs_fabbmanc_testata");
            if (dataLog.Count > 0) oggetto["dataLog"] = dataLog[0];

            return oggetto;
        }

        /// <summary>
        /// Ultimo data-log dei mancanti (prima riga di cs_fabbmanc_testata), oppure la stringa
        /// <c>"error: no Data Log"</c> (ex getLatestDtrunHrrun.php).
        /// </summary>
        public object GetLatestDtrunHrrun()
        {
            var dataLog = DbHelper.QueryFirst(_conn.PgCasagrande, "select * from cs_fabbmanc_testata");
            return dataLog != null ? dataLog : "error: no Data Log";
        }

        /// <summary>
        /// Mancanti (o prelievi) di un magazzino di impegno, divisi tra magazzini normali e automatici, con l'ultimo
        /// data-log; per gli ODV (OM / OR) nei prelievi legge le righe ODV (ex selectMancantiDaMag.php).
        /// </summary>
        public Dictionary<string, object?> SelectMancantiDaMag(SelectMancantiDaMagRequest request, string societa)
        {
            var magazzinoImpegno = Obbligatorio(request.magazzinoImpegno, "magazzinoImpegno");
            var statoPickY = request.statoPickYSelected == true;
            var codiceOdl = request.codiceOdl ?? "";

            var statoPickYQuery = statoPickY
                ? "cs_fabbmanc_odl_comp.statopick = 'Y'"
                : "cs_fabbmanc_odl_comp.statopick != 'Y' and cs_fabbmanc_odl_comp.statopick != ''";
            var codiceOdlQuery = "";
            var additionalOrderBy = "";
            var parametriOdl = new List<object?>();

            if (codiceOdl != "")
            {
                codiceOdlQuery = "and cs_fabbmanc_odl_dispo.numero = ?";
                additionalOrderBy = "cs_fabbmanc_odl_dispo.fabbdate asc, cs_fabbmanc_odl_dispo.fase,";
                parametriOdl.Add(codiceOdl);
            }

            var isOdv = !statoPickY && (codiceOdl.StartsWith("OM") || codiceOdl.StartsWith("OR"));

            const string selectMancanti = @"SELECT cs_fabbmanc_odl_comp.iscritico, cs_fabbmanc_odl_dispo.numero as odl, cs_fabbmanc_odl_dispo.magazzino as magazzinoImpegno, cs_fabbmanc_odl_dispo.articolo, cs_fabbmanc_odl_comp.descarticolo, cs_fabbmanc_odl_dispo.fase, cs_fabbmanc_odl_fasi.descrizione as descrizionefase, cs_fabbmanc_odl_dispo.stato, cs_fabbmanc_odl_dispo.fabbdate, cs_fabbmanc_odl_dispo.prioprel, cs_fabbmanc_odl_dispo.seq, cs_fabbmanc_odl_dispo.magdispo, cs_fabbmanc_odl_dispo.vanodispo, cs_fabbmanc_odl_comp.umis, cs_fabbmanc_odl_dispo.giacdispo, cs_fabbmanc_odl_dispo.nomefornlastdispo, cs_fabbmanc_odl_comp.statopick, cs_fabbmanc_odl_comp.pesol, cs_fabbmanc_odl.articolo AS padre, cs_fabbmanc_odl.descarticolo as des_padre, cs_fabbmanc_odl.desccolore,cs_fabbmanc_odl_dispo.fornlastdispo,cs_fabbmanc_odl_dispo.bollanolastdispo,cs_fabbmanc_odl_dispo.bolladtlastdispo
FROM cs_fabbmanc_odl_dispo
INNER JOIN cs_fabbmanc_odl_comp ON (cs_fabbmanc_odl_dispo.fase = cs_fabbmanc_odl_comp.fase)
AND (cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_odl_dispo.articolo)
AND (cs_fabbmanc_odl_dispo.magazzino = cs_fabbmanc_odl_comp.magazzino)
AND (cs_fabbmanc_odl_dispo.numero = cs_fabbmanc_odl_comp.numero)
AND (cs_fabbmanc_odl_dispo.societa = cs_fabbmanc_odl_comp.societa)
INNER JOIN cs_fabbmanc_odl ON (cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero)
AND (cs_fabbmanc_odl_comp.societa = cs_fabbmanc_odl.societa)
INNER JOIN cs_fabbmanc_odl_fasi ON (cs_fabbmanc_odl_dispo.fase = cs_fabbmanc_odl_fasi.fase) and (cs_fabbmanc_odl_dispo.numero = cs_fabbmanc_odl_fasi.numero)";

            const string selectOdv = @"select *
    from cs_fabbmanc_rodv
    inner join cs_fabbmanc_rodv_dispo ON (cs_fabbmanc_rodv_dispo.numero = cs_fabbmanc_rodv.numero and cs_fabbmanc_rodv_dispo.pos = cs_fabbmanc_rodv.pos and cs_fabbmanc_rodv_dispo.seq = cs_fabbmanc_rodv.seq and cs_fabbmanc_rodv_dispo.societa = cs_fabbmanc_rodv.societa)
    inner join cs_fabbmanc_odv ON (cs_fabbmanc_rodv_dispo.numero = cs_fabbmanc_odv.numero and cs_fabbmanc_rodv_dispo.societa = cs_fabbmanc_odv.societa)
    where magazzino=?
    and cs_fabbmanc_rodv_dispo.isauto=?
    and cs_fabbmanc_rodv.numero = ?
    and cs_fabbmanc_rodv.societa=?
    order by cs_fabbmanc_rodv.numero, cs_fabbmanc_rodv.articolo";

            var parametri = parametriOdl.Append(societa).Append(magazzinoImpegno).ToArray();

            using var conn = new OdbcConnection(_conn.PgCasagrande);
            conn.Open();

            // QUERY 1: mancanti dei magazzini non automatici
            var listaMancanti = isOdv
                ? DbHelper.Query(conn, null, selectOdv, magazzinoImpegno, "0", codiceOdl, societa)
                : DbHelper.Query(conn, null, $@"{selectMancanti}
WHERE {statoPickYQuery} {codiceOdlQuery} AND cs_fabbmanc_odl_dispo.societa=?
AND cs_fabbmanc_odl_dispo.isauto='0'
AND cs_fabbmanc_odl_dispo.magazzino = ? and cs_fabbmanc_odl_comp.tipoarticolo != 'N'
and cs_fabbmanc_odl_dispo.magdispo not like 'MEF%'
and cs_fabbmanc_odl_dispo.magdispo not like 'MC%'
and cs_fabbmanc_odl_dispo.magdispo not like 'MN%'
and cs_fabbmanc_odl_dispo.magdispo not like 'MGFURG%'
ORDER BY {additionalOrderBy} cs_fabbmanc_odl_dispo.magdispo, cs_fabbmanc_odl_dispo.vanodispo, cs_fabbmanc_odl_dispo.numero, cs_fabbmanc_odl_comp.articolo", parametri);

            // QUERY 2: mancanti dei magazzini automatici
            var listaMancantiAut = isOdv
                ? DbHelper.Query(conn, null, selectOdv, magazzinoImpegno, "1", codiceOdl, societa)
                : DbHelper.Query(conn, null, $@"{selectMancanti}
WHERE {statoPickYQuery} {codiceOdlQuery} AND cs_fabbmanc_odl_dispo.societa=?
AND cs_fabbmanc_odl_dispo.isauto='1'
AND cs_fabbmanc_odl_dispo.magazzino = ? and cs_fabbmanc_odl_comp.tipoarticolo != 'N'
ORDER BY {additionalOrderBy} cs_fabbmanc_odl_dispo.magdispo, cs_fabbmanc_odl_dispo.numero, cs_fabbmanc_odl_dispo.fase", parametri);

            // QUERY 3: ultimo data-log
            var dataLog = DbHelper.Query(conn, null, "select * from cs_fabbmanc_testata");

            return new Dictionary<string, object?>
            {
                ["listaArticoliMancanti"] = listaMancanti,
                ["listaArticoliMancantiAUT"] = listaMancantiAut,
                ["dataLog"] = dataLog.Count > 0
                    ? dataLog[0]
                    : new Dictionary<string, object?> { ["dtrun"] = 0, ["hrrun"] = 0 }
            };
        }

        /// <summary>
        /// Rientri di un magazzino: giacenze con quantità resa (totale - impegnata) maggiore di zero (ex selectRientri.php).
        /// </summary>
        public List<Dictionary<string, object?>> SelectRientri(SelectRientriRequest request)
        {
            var magazzino = Obbligatorio(request.magazzino, "magazzino");

            var righe = DbHelper.Query(_conn.PgCasagrande, @"select cs_fabbmanc_giac.articolo, cs_fabbmanc_giac.magazzino, cs_fabbmanc_giac.vano, cs_fabbmanc_giac.qtatot as qta_totale, cs_fabbmanc_giac.qtaimpegnata as qta_impegnata, cs_articoli.mpdsc as descrizione
from cs_fabbmanc_giac
inner join cs_articoli on cs_fabbmanc_giac.articolo = cs_articoli.mitem
where cs_fabbmanc_giac.magazzino=? and cs_articoli.mtypn != 'N' and cs_articoli.mcommcd !='FA-204' and cs_articoli.mcommcd != 'FA-215' and cs_articoli.mcommcd != 'FA-406' and cs_articoli.mcommcd != 'FA-2111' and  cs_articoli.mcommcd != 'FA-2112'
order by cs_fabbmanc_giac.articolo", magazzino);

            var listaRientri = new List<Dictionary<string, object?>>();

            foreach (var r in righe)
            {
                var qtaTotale = Testo(r, "qta_totale");
                var qtaImpegnata = Testo(r, "qta_impegnata");

                // qta_resa = totale - impegnata (l'impegnata negativa vale 0)
                var qtaResa = PhpFloat(qtaTotale) - Math.Max(PhpFloat(qtaImpegnata), 0);

                if (qtaResa > 0)
                {
                    listaRientri.Add(new Dictionary<string, object?>
                    {
                        ["articolo"] = Testo(r, "articolo"),
                        ["magazzino"] = Testo(r, "magazzino"),
                        ["vano"] = Testo(r, "vano"),
                        ["qta_totale"] = qtaTotale,
                        ["qta_impegnata"] = qtaImpegnata,
                        ["qta_resa"] = qtaResa,
                        ["descrizione"] = Testo(r, "descrizione")
                    });
                }
            }

            return listaRientri;
        }

        // -------------------------------------------------------------------------------------------------------------
        // ----- STORICO MOVIMENTI -------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Storico movimenti mancanti (ex getStoriaMovimento.php):
        /// con utente e magazzino e dtrun/hrrun a 0 lo storico dell'utente dell'ultimo mese; con utente vuoto e
        /// dtrun/hrrun valorizzati i movimenti di quell'aggiornamento (eventualmente filtrati per magazzino).
        /// </summary>
        public List<Dictionary<string, object?>> GetStoriaMovimento(GetStoriaMovimentoRequest request)
        {
            var codiceUtente = request.utente ?? "";
            var dtrun = PhpInt(request.dtrun);
            var hrrun = PhpInt(request.hrrun);
            var magazzinoImpegno = request.magazzino_impegno ?? "";
            var sezione = request.sezione ?? "";
            var dataCorrente = Oggi() - 100; // -1 mese

            if (codiceUtente != "" && dtrun == 0 && hrrun == 0 && magazzinoImpegno != "")
            {
                // Tab storici
                return DbHelper.Query(_conn.PgDb1, "select * from storia_mov_mancanti where utente_mov=? and mag_des=? and data_salvataggio > ? and sezione=? order by data_salvataggio desc, ora_salvataggio desc",
                    codiceUtente, magazzinoImpegno, dataCorrente, sezione);
            }

            if (codiceUtente == "" && dtrun > 0 && hrrun > 0 && magazzinoImpegno == "")
            {
                // Movimenti già fatti per l'aggiornamento (solo dtrun: un articolo di un ODL si muove una volta al giorno)
                return DbHelper.Query(_conn.PgDb1, "select * from storia_mov_mancanti where dtrun=? and sezione=?", dtrun, sezione);
            }

            if (codiceUtente == "" && dtrun > 0 && hrrun > 0 && magazzinoImpegno != "")
            {
                // Movimenti dell'aggiornamento per il magazzino (serve il numero per capire se un altro utente ne ha fatti)
                return DbHelper.Query(_conn.PgDb1, "select * from storia_mov_mancanti where dtrun=? and mag_des=? and sezione=?", dtrun, magazzinoImpegno, sezione);
            }

            // Nessuna combinazione valida: il PHP eseguiva una query vuota e restituiva []
            return new List<Dictionary<string, object?>>();
        }

        /// <summary>
        /// Movimenti mancanti salvati oggi da un utente per magazzino e sezione (ex getStoriaMovimentoOggi.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetStoriaMovimentoOggi(GetStoriaMovimentoOggiRequest request)
        {
            return DbHelper.Query(_conn.PgDb1, "select * from storia_mov_mancanti where utente_mov=? and  mag_des=? and data_salvataggio=? and sezione=?",
                request.utente ?? "", request.magazzino_impegno ?? "", Oggi(), request.sezione ?? "");
        }

        /// <summary>
        /// Aggiorna lo stato di un movimento mancanti; <c>"updated"</c> oppure <c>"error"</c> se mancano dtrun, hrrun o
        /// stato (ex updateStatoStoriaMovimento.php).
        /// </summary>
        public string UpdateStatoStoriaMovimento(UpdateStatoStoriaMovimentoRequest request)
        {
            // Nel PHP i valori numerici mancanti o a zero rendevano la query non valida → 'error'
            if (!int.TryParse(request.dtrun?.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var dtrun) || dtrun == 0 ||
                !int.TryParse(request.hrrun?.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var hrrun) || hrrun == 0 ||
                !int.TryParse(request.stato_mov?.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var statoMov) || statoMov == 0)
            {
                return "error";
            }

            DbHelper.NonQuery(_conn.PgDb1, "update storia_mov_mancanti set stato_mov=? where articolo=? and odl=? and fase=? and dtrun=? and hrrun=?",
                statoMov, PhpVero(request.articolo), PhpVero(request.odl), PhpVero(request.fase), dtrun, hrrun);

            return "updated";
        }

        /// <summary>
        /// Storico dell'ultimo mese dei movimenti MGIS001 di un utente (ex getStoriaPrelieviMgis001.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetStoriaPrelieviMgis001(GetStoriaPrelieviMgis001Request request)
        {
            return DbHelper.Query(_conn.PgDb1, @"select data,ora,nome_lista,riepilogo_movimento,errori, magazzino_destinazione from storico_mov_mgis001
where utente=? and data > ?
order by data desc, ora desc", request.utente ?? "", Oggi() - 100);
        }

        /// <summary>
        /// Registra un movimento MGIS001 nello storico e restituisce l'id inserito (ex writeStoriaMovMgis001.php).
        /// </summary>
        /// <param name="request">Lista, riepilogo ed errori.</param>
        /// <param name="utente">Codice dell'utente autenticato.</param>
        public string WriteStoriaMovMgis001(WriteStoriaMovMgis001Request request, string utente)
        {
            var errori = string.IsNullOrWhiteSpace(request.errori) ? 0 : IntValido(request.errori, "errori");

            // Il PHP sostituiva gli apici per non rompere la query: mantengo lo stesso testo salvato
            var riepilogo = (request.riepilogo_movimento ?? "").Replace("'", "` ");

            return DbHelper.Scalar(_conn.PgDb1, @"insert into public.storico_mov_mgis001 (utente, data, ora, nome_lista, riepilogo_movimento, errori) values
    (?, ?, ?, ?, ?, ?) returning id", utente, Oggi(), OraAdesso(), request.nome_lista ?? "", riepilogo, errori) ?? "";
        }

        // -------------------------------------------------------------------------------------------------------------
        // ----- LISTE INVENTARIO --------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Liste di inventario non chiuse (stato &lt; 3) (ex getElencoListe.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetElencoListe()
        {
            var righe = DbHelper.Query(_conn.PgDb1, "select * from liste_testate where stato<3 order by stato,data_creazione desc, ora_creazione desc");

            return righe.Select(r => new Dictionary<string, object?>
            {
                ["id"] = PhpInt(Testo(r, "id")),
                ["nome_lista"] = Testo(r, "nome_lista"),
                ["tipo_lista"] = Testo(r, "tipo_lista"),
                ["data_creazione"] = PhpFloat(Testo(r, "data_creazione")),
                ["ora_creazione"] = PhpFloat(Testo(r, "ora_creazione")),
                ["stato"] = PhpInt(Testo(r, "stato")),
                ["utente_creazione"] = Testo(r, "utente_creazione"),
                ["utente_chiusura"] = Testo(r, "utente_chiusura")
            }).ToList();
        }

        /// <summary>
        /// Crea una lista di inventario dopo aver verificato che non ne esista già una aperta con lo stesso nome e che
        /// magazzino/vano esistano su Diapason. Restituisce l'id inserito oppure <c>lista_already_exists</c>,
        /// <c>magazzino_not_found</c>, <c>vano_preciso_not_found</c>, <c>vano_radice_not_found</c> (ex writeLista.php).
        /// </summary>
        /// <param name="request">Nome e tipo della lista.</param>
        /// <param name="utente">Codice dell'utente autenticato (utente di creazione).</param>
        /// <param name="societa">Società del token (controllo magazzino / vano su Diapason).</param>
        public string WriteLista(WriteListaRequest request, string utente, string societa)
        {
            var nomeLista = Obbligatorio(request.nome_lista, "nome_lista");
            var tipoLista = request.tipo_lista ?? "";

            using var connPg = new OdbcConnection(_conn.PgDb1);
            connPg.Open();

            // Non deve esserci già una lista aperta con lo stesso nome
            if (DbHelper.Query(connPg, null, "select nome_lista from public.liste_testate where nome_lista=? and stato=0", nomeLista).Count > 0)
            {
                return "lista_already_exists";
            }

            // Controllo che magazzino / vano esistano (a seconda del tipo lista)
            string? queryControllo = tipoLista switch
            {
                "magazzino" => "SELECT MASAHED.MAHMAG FROM MASAHED WHERE MASAHED.MAHCOSC=? AND MASAHED.MAHMAG=?",
                "vano_preciso" => "SELECT DISTINCT MASAHLO.MLHLOC FROM MASAHLO WHERE MASAHLO.MAHCOSC=? AND MASAHLO.MLHLOC=?",
                "vano_radice" => "SELECT DISTINCT MASAHLO.MLHLOC FROM MASAHLO WHERE MASAHLO.MAHCOSC=? AND MASAHLO.MLHLOC LIKE ?",
                _ => null
            };

            // Tipo lista sconosciuto: il PHP non scriveva nulla
            if (queryControllo == null) return "";

            var valoreControllo = tipoLista == "vano_radice" ? nomeLista + "%" : nomeLista;

            if (DbHelper.Query(_conn.Db2, queryControllo, societa, valoreControllo).Count == 0)
            {
                return tipoLista + "_not_found";
            }

            return DbHelper.Query(connPg, null, "insert into public.liste_testate (nome_lista, data_creazione, ora_creazione,utente_creazione, tipo_lista) values (?,?,?,?,?) returning id",
                nomeLista, Oggi(), OraAdesso(), utente, tipoLista).FirstOrDefault()?.Values.FirstOrDefault()?.ToString() ?? "";
        }

        /// <summary>
        /// Cambia lo stato di una lista (archiviazione / riapertura / eliminazione) registrando l'utente di chiusura
        /// (ex cambiaStatoLista.php). Restituisce <c>"updated"</c>.
        /// </summary>
        /// <param name="request">Id lista e nuovo stato.</param>
        /// <param name="utente">Codice dell'utente autenticato.</param>
        public string CambiaStatoLista(CambiaStatoListaRequest request, string utente)
        {
            var id = IntValido(request.id, "id");
            var stato = IntValido(request.stato, "stato");

            DbHelper.NonQuery(_conn.PgDb1, "update public.liste_testate set stato=?, utente_chiusura=?, data_archiviazione=?, ora_archiviazione=?  WHERE id=?",
                stato, utente, Oggi(), OraAdesso(), id);

            return "updated";
        }

        /// <summary>
        /// Elimina una riga di lista (ex eliminaRiga.php). Restituisce <c>"deleted"</c>.
        /// </summary>
        public string EliminaRiga(EliminaRigaRequest request)
        {
            var id = IntValido(request.id, "id");

            DbHelper.NonQuery(_conn.PgDb1, "delete from public.liste_righe where id=?", id);

            return "deleted";
        }

        /// <summary>
        /// Scrive una riga di inventario e restituisce l'id inserito. Se la lista non è più aperta restituisce
        /// <c>lista_archiviata</c> / <c>lista_eliminata</c> / <c>error</c>; se la stessa riga è già stata inserita
        /// restituisce il codice dell'utente che l'ha inserita (ex writeRigaLista.php).
        /// </summary>
        /// <param name="request">Riga da scrivere.</param>
        /// <param name="utente">Codice dell'utente autenticato (utente di inserimento).</param>
        public string WriteRigaLista(WriteRigaListaRequest request, string utente)
        {
            var riga = request.rigaLista ?? throw new MobileException("Parametro rigaLista obbligatorio");

            var articolo = JsonTesto(riga.articolo);
            var descrizione = JsonTesto(riga.descrizione);
            var idListaTestata = PhpInt(JsonTesto(riga.id_lista_testata));
            var stato = PhpInt(JsonTesto(riga.stato));
            var magazzino = JsonTesto(riga.magazzino);
            var qtaOriginale = Math.Round(PhpFloat(JsonTesto(riga.qta_originale)), 3, MidpointRounding.AwayFromZero);
            var qtaModificata = Math.Round(PhpFloat(JsonTesto(riga.qta_modificata)), 3, MidpointRounding.AwayFromZero);
            var vanoOriginale = JsonTesto(riga.vano_originale);
            var vanoModificato = JsonTesto(riga.vano_modificato);
            var urlFoto = JsonTesto(riga.url_foto);
            var nota = JsonTesto(riga.nota);
            var rigaAggiuntaManualmente = PhpInt(JsonTesto(riga.riga_aggiunta_manualmente));

            using var conn = new OdbcConnection(_conn.PgDb1);
            conn.Open();

            // La lista deve essere ancora aperta
            var statoLista = CheckListaStillExists(conn, idListaTestata);
            if (statoLista != "ok") return statoLista;

            // Se la stessa riga è già stata inserita restituisco l'utente che l'ha inserita
            var utenteInserimento = "";
            foreach (var esistente in DbHelper.Query(conn, null, @"select utente_inserimento from public.liste_righe
where id_lista_testata=?
and articolo=?
and magazzino=?
and vano_originale=?
and stato=?", idListaTestata, articolo, magazzino, vanoOriginale, stato))
            {
                utenteInserimento = Testo(esistente, "utente_inserimento") ?? "";
            }

            if (utenteInserimento != "") return utenteInserimento;

            return DbHelper.Query(conn, null, @"insert into public.liste_righe (id_lista_testata, articolo, descrizione, magazzino, vano_originale, vano_modificato,
          qta_originale, qta_modificata, url_foto, stato, utente_inserimento, data_inserimento, ora_inserimento, riga_aggiunta_manualmente, nota) values
          (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) returning id",
                idListaTestata, articolo, descrizione, magazzino, vanoOriginale, vanoModificato, qtaOriginale, qtaModificata, urlFoto, stato,
                utente, Oggi(), OraAdesso(), rigaAggiuntaManualmente, nota).FirstOrDefault()?.Values.FirstOrDefault()?.ToString() ?? "";
        }

        /// <summary>
        /// Stato di una lista: ok (aperta), lista_archiviata, lista_eliminata, error (ex shared_functions/checkListaStillExists.php).
        /// </summary>
        private static string CheckListaStillExists(OdbcConnection conn, int id)
        {
            foreach (var r in DbHelper.Query(conn, null, "select stato from public.liste_testate where id=?", id))
            {
                switch (PhpInt(Testo(r, "stato")))
                {
                    case 0:
                        return "ok";
                    case 1:
                    case 2:
                    case 3:
                        return "lista_archiviata";
                    case 9:
                        return "lista_eliminata";
                }
            }

            return "error";
        }

        // -------------------------------------------------------------------------------------------------------------
        // ----- PRELIEVI MGAUT / AUTOMHA ------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Padre, descrizione padre e fasi di un ODL per la lista di prelievo MGAUT; <c>null</c> se l'ODL non esiste
        /// (ex checkOdlListaPrelievoMgautAndGetFasi.php).
        /// </summary>
        public Dictionary<string, object?>? CheckOdlListaPrelievoMgautAndGetFasi(CheckOdlListaPrelievoMgautAndGetFasiRequest request)
        {
            var odl = Obbligatorio(request.odl, "odl");

            using var conn = new OdbcConnection(_conn.PgCasagrande);
            conn.Open();

            var odlInfo = DbHelper.Query(conn, null, @"SELECT distinct cs_fabbmanc_odl.articolo as padre, cs_fabbmanc_odl.descarticolo as desc_padre
FROM cs_fabbmanc_odl
INNER JOIN cs_fabbmanc_odl_comp ON cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero AND cs_fabbmanc_odl.societa = cs_fabbmanc_odl_comp.societa
WHERE cs_fabbmanc_odl_comp.numero=?", odl).LastOrDefault();

            if (odlInfo == null) return null;

            odlInfo["listaFasi"] = DbHelper.Query(conn, null, @"select distinct cs_fabbmanc_odl_comp.fase, cs_fabbmanc_odl_fasi.descrizione as descrizionefase
    from cs_fabbmanc_odl_comp
    inner join cs_fabbmanc_odl_fasi on cs_fabbmanc_odl_comp.fase = cs_fabbmanc_odl_fasi.fase and cs_fabbmanc_odl_comp.numero = cs_fabbmanc_odl_fasi.numero
    where cs_fabbmanc_odl_comp.numero=? order by cs_fabbmanc_odl_comp.fase", odl)
                .Select(f => new Dictionary<string, object?>
                {
                    ["fase"] = Testo(f, "fase"),
                    ["descrizionefase"] = Testo(f, "descrizionefase"),
                    ["qta"] = null
                }).ToList();

            return odlInfo;
        }

        /// <summary>
        /// Numero, cliente, nome cliente e posizione di un ODV con l'articolo su magazzino automatico; <c>null</c> se non
        /// trovato (ex checkOdvListaPrelievoMgaut.php).
        /// </summary>
        public Dictionary<string, object?>? CheckOdvListaPrelievoMgaut(CheckOdvListaPrelievoMgautRequest request, string societa)
        {
            var articolo = Obbligatorio(request.articolo, "articolo");
            var odv = Obbligatorio(request.odv, "odv");

            return DbHelper.Query(_conn.PgCasagrande, @"select cs_fabbmanc_odv.numero, cs_fabbmanc_odv.cliente, cs_fabbmanc_odv.nomecliente, cs_fabbmanc_rodv.pos
from cs_fabbmanc_rodv
inner join cs_fabbmanc_rodv_dispo ON (cs_fabbmanc_rodv_dispo.numero = cs_fabbmanc_rodv.numero and cs_fabbmanc_rodv_dispo.pos = cs_fabbmanc_rodv.pos and cs_fabbmanc_rodv_dispo.seq = cs_fabbmanc_rodv.seq and cs_fabbmanc_rodv_dispo.societa = cs_fabbmanc_rodv.societa)
inner join cs_fabbmanc_odv ON (cs_fabbmanc_rodv_dispo.numero = cs_fabbmanc_odv.numero and cs_fabbmanc_rodv_dispo.societa = cs_fabbmanc_odv.societa)
where cs_fabbmanc_rodv.numero=?
and cs_fabbmanc_rodv_dispo.isauto='1'
and cs_fabbmanc_rodv.societa=?
and cs_fabbmanc_rodv.articolo=?", odv, societa, articolo).LastOrDefault();
        }

        /// <summary>
        /// Segna come cancellata (cancellato = '1') una testata di prelievo Automha (ex deleteListaPrelievo.php).
        /// Restituisce <c>"deleted"</c>.
        /// </summary>
        public string DeleteListaPrelievo(DeleteListaPrelievoRequest request)
        {
            var tipoprel = Obbligatorio(request.tipoprel, "tipoprel");
            var rifprel = Obbligatorio(request.rifprel, "rifprel");
            var seqprel = IntValido(request.seqprel, "seqprel");

            DbHelper.NonQuery(_conn.PgCasagrande, "update prelautoh set cancellato='1' where tipoprel=? and rifprel=? and subrifprel=? and seqprel=?",
                tipoprel, rifprel, request.subrifprel ?? "", seqprel);

            return "deleted";
        }

        /// <summary>
        /// Segna come trasferita una riga di prelievo Automha; per il sotto-riferimento 0027 completa anche l'inserimento
        /// fase 0027 (ex updateAutomhaTrasferito.php). Restituisce <c>"updated"</c>.
        /// </summary>
        public string UpdateAutomhaTrasferito(UpdateAutomhaTrasferitoRequest request)
        {
            var articolo = Obbligatorio(request.articolo, "articolo");
            var rifprel = Obbligatorio(request.rifprel, "rifprel");
            var subrifprel = request.subrifprel ?? "";
            var seqprel = IntValido(request.seqprel, "seqprel");
            var seq = IntValido(request.seq, "seq");

            DbHelper.NonQuery(_conn.PgCasagrande, "update public.prelautop set trasferito='1' where articolo=? and rifprel=? and subrifprel=? and seqprel=? and seq=?",
                articolo, rifprel, subrifprel, seqprel, seq);

            if (subrifprel == "0027")
            {
                DbHelper.NonQuery(_conn.PgDb1, "update inserimenti_fase_0027 set data_completamento=?, ora_completamento=? where articolo=? and odl=? and data_completamento = 0",
                    Oggi(), OraAdesso(), articolo, rifprel);
            }

            return "updated";
        }

        /// <summary>
        /// Righe di prelievo MGAUT00 / MGAUT10 non ancora uscite (ex getListaMgaut02.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetListaMgaut02()
        {
            return DbHelper.Query(_conn.PgCasagrande, @"
select prelautop.societa,
prelautop.tipoprel,
prelautop.rifprel,
prelautop.subrifprel,
prelautop.seqprel,
prelautop.seq,
prelautop.articolo,
prelautop.descarticolo,
prelautop.qta,
prelautop.umis,
prelautop.vanoto,
prelautop.posodv,
prelautop.seqodv,
prelautop.qtaconf,
prelautop.uscito,
prelautop.trasferito, prelautoh.scaffale, magfrom, magto, inviato
from prelautop
inner join prelautoh on prelautoh.rifprel = prelautop.rifprel
and prelautoh.subrifprel = prelautop.subrifprel
and prelautoh.seqprel = prelautop.seqprel
and prelautoh.tipoprel = prelautop.tipoprel
where uscito='0' and cancellato='0' and (magfrom='MGAUT00' or magfrom='MGAUT10')
order by prelautoh.rifprel, prelautoh.subrifprel, prelautoh.seqprel, articolo");
        }

        /// <summary>
        /// True se l'articolo dell'attività 0027 è ancora da visualizzare, cioè non è ancora entrato su MGAUT02 / MGAUT03
        /// per quell'ODL dopo l'avviso (ex getListaPrelievi0027FromAttivitaCheckScript.php).
        /// </summary>
        public bool GetListaPrelievi0027FromAttivitaCheckScript(GetListaPrelievi0027FromAttivitaCheckScriptRequest request, string societa)
        {
            var articolo = Obbligatorio(request.articolo_avviso, "articolo_avviso");
            var odl = Obbligatorio(request.odl_avviso, "odl_avviso");
            if (!long.TryParse(request.timest_avviso?.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var timest))
            {
                throw new MobileException("Parametro timest_avviso non valido");
            }

            var righe = DbHelper.Query(_conn.Db2, @"SELECT TRNITM
    FROM MASATRN
    WHERE MASATRN.TRNITM = ?
    AND MASATRN.TORNUOR = ?
    AND MASATRN.TRDATE > ? AND
    MASATRN.TMACO='ET' AND MASATRN.TUSCO ='A'
    AND (MASATRN.TMAG = 'MGAUT02' OR MASATRN.TMAG = 'MGAUT03')
    AND MASATRN.TRNSOC = ?", articolo, odl, timest, societa);

            return righe.Count == 0;
        }

        /// <summary>
        /// Righe di prelievo uscite e confermate ma non ancora trasferite (esclusi ODV OR / OM), con i dati della testata
        /// e, per i kanban, la commessa ricavata dalla famiglia dell'articolo (ex getListaTrasferimentiMgis001.php).
        /// </summary>
        public List<Dictionary<string, object?>> GetListaTrasferimentiMgis001(string societa)
        {
            using var connPg = new OdbcConnection(_conn.PgCasagrande);
            connPg.Open();
            using var connDb2 = new OdbcConnection(_conn.Db2);
            connDb2.Open();

            var righe = DbHelper.Query(connPg, null, @"select prelautop.societa, prelautop.tipoprel, prelautop.rifprel, prelautop.subrifprel, prelautop.seqprel, prelautop.seq,
prelautop.articolo, prelautop.descarticolo, prelautop.qta, prelautop.umis, prelautop.vanoto, prelautop.posodv, prelautop.seqodv,
prelautop.qtaconf, prelautop.uscito, prelautop.trasferito, prelautoh.scaffale, prelautoh.inviato, prelautoh.nota, prelautoh.cancellato,
prelautoh.dtmm, prelautoh.hrmm, prelautoh.magfrom, prelautoh.magto from public.prelautop
inner join prelautoh on prelautoh.rifprel = prelautop.rifprel
and prelautoh.subrifprel = prelautop.subrifprel
and prelautoh.seqprel = prelautop.seqprel
and prelautoh.tipoprel = prelautop.tipoprel
where cancellato='0' and uscito='1' and prelautop.qtaconf > 0 and prelautop.trasferito='0' and prelautop.rifprel not like 'OR%' and prelautop.rifprel not like 'OM%'
order by case when prelautop.tipoprel  = 'KAN' then '999' else '000' end || prelautop.rifprel, prelautop.subrifprel, prelautop.seqprel, prelautop.seq");

            var lista = new List<Dictionary<string, object?>>();

            foreach (var p in righe)
            {
                var tipoprel = Testo(p, "tipoprel");
                var rifprel = Testo(p, "rifprel");
                var subrifprel = Testo(p, "subrifprel");
                var seqprel = PhpInt(Testo(p, "seqprel"));
                var articolo = Testo(p, "articolo");

                // Kanban: la commessa si ricava dalla famiglia dell'articolo
                var commessa = "";
                if (tipoprel == "KAN")
                {
                    foreach (var f in DbHelper.Query(connDb2, null, @"SELECT DBSAFCA.MCOMMCD
            FROM DBSAFCA
            WHERE DBSAFCA.MITEM = ? AND DBSAFCA.MCOSC = ?", articolo ?? "", societa))
                    {
                        switch (Trim(Testo(f, "MCOMMCD")))
                        {
                            case "FA-2150": commessa = "1036020"; break;
                            case "FA-208012": commessa = "1036025"; break;
                            case "FA-2113": commessa = "1036030"; break;
                        }
                    }
                }

                // Dati della testata
                object? dtcrea = 0, hrcrea = 0;
                string? usrcrea = "", magfrom = "", magto = "", fase = "", descfase = "", artpadre = "", descartpadre = "",
                    cliente = "", nomecliente = "", nota = "", scaffale = "";

                var testate = DbHelper.Query(connPg, null, "select * from public.prelautoh where cancellato = '0' AND rifprel = ? AND subrifprel = ? AND seqprel = ?",
                    rifprel ?? "", subrifprel ?? "", seqprel);

                var h = testate.FirstOrDefault(t => Testo(t, "rifprel") == rifprel && Testo(t, "subrifprel") == subrifprel && PhpInt(Testo(t, "seqprel")) == seqprel);
                if (h != null)
                {
                    dtcrea = PhpInt(Testo(h, "dtcrea"));
                    hrcrea = PhpInt(Testo(h, "hrcrea"));
                    usrcrea = Testo(h, "usrcrea");
                    magfrom = Testo(h, "magfrom");
                    magto = Testo(h, "magto");
                    fase = Testo(h, "fase");
                    descfase = Testo(h, "descfase");
                    artpadre = Testo(h, "artpadre");
                    descartpadre = Testo(h, "descartpadre");
                    cliente = Testo(h, "cliente");
                    nomecliente = Testo(h, "nomecliente");
                    nota = Testo(h, "nota");
                    scaffale = Testo(h, "scaffale");
                }

                lista.Add(new Dictionary<string, object?>
                {
                    ["societa"] = Testo(p, "societa"),
                    ["tipoprel"] = tipoprel,
                    ["rifprel"] = rifprel,
                    ["subrifprel"] = subrifprel,
                    ["seqprel"] = seqprel,
                    ["seq"] = PhpInt(Testo(p, "seq")),
                    ["articolo"] = articolo,
                    ["descarticolo"] = Testo(p, "descarticolo"),
                    ["qta"] = PhpFloat(Testo(p, "qtaconf")),
                    ["umis"] = Testo(p, "umis"),
                    ["vanoto"] = Testo(p, "vanoto"),
                    ["dtcrea"] = dtcrea,
                    ["hrcrea"] = hrcrea,
                    ["usrcrea"] = usrcrea,
                    ["magfrom"] = magfrom,
                    ["magto"] = magto,
                    ["fase"] = fase,
                    ["descfase"] = descfase,
                    ["artpadre"] = artpadre,
                    ["descartpadre"] = descartpadre,
                    ["cliente"] = cliente,
                    ["nomecliente"] = nomecliente,
                    ["nota"] = nota,
                    ["scaffale"] = scaffale,
                    ["commessa"] = commessa,
                    ["selezionato"] = false
                });
            }

            return lista;
        }

        /// <summary>
        /// ODV (OR / OM) contenuti in una prebolla in stato 05 (ex mgaut_prel_immediato_get_odv_from_prebolla.php).
        /// </summary>
        public List<string> MgautPrelImmediatoGetOdvFromPrebolla(MgautPrelImmediatoGetOdvFromPrebollaRequest request, string societa)
        {
            var prebolla = Obbligatorio(request.prebolla, "prebolla");
            if (!prebolla.StartsWith("PRB/")) prebolla = "PRB/" + prebolla;

            return DbHelper.Query(_conn.Db2, @"
SELECT DISTINCT SHSAPIK.SHLRIORN
FROM SHSAPIK
INNER JOIN SHSADAT ON SHSAPIK.SHTNUM = SHSADAT.SHTNUM AND SHSAPIK.SHTCOSOC = SHSADAT.SHTCOSOC
WHERE SHSAPIK.SHTCOSOC=?
AND SHSADAT.SHTSTAT='05'
AND SHSAPIK.SHTNUM=?
ORDER BY SHSAPIK.SHLRIORN", societa, prebolla)
                .Select(r => Trim(Testo(r, "SHLRIORN")))
                .Where(odv => odv != "")
                .ToList();
        }

        /// <summary>
        /// Righe di prebolla (stato 05) di un ODV con giacenza su MGAUT10 / MGAUT00 e magazzino automatico da cui
        /// prelevare (prima MGAUT10, poi MGAUT00) se la giacenza copre la quantità cumulata dell'articolo
        /// (ex mgaut_prel_immediato_get_righe_from_odv.php).
        /// </summary>
        public List<Dictionary<string, object?>> MgautPrelImmediatoGetRigheFromOdv(MgautPrelImmediatoGetRigheFromOdvRequest request, string societa)
        {
            var odv = Obbligatorio(request.odv, "odv");

            using var conn = new OdbcConnection(_conn.Db2);
            conn.Open();

            var listaRighe = DbHelper.Query(conn, null, @"
SELECT SHSAPIK.SHTNUM AS prebolla, SHSAPIK.SHLCDART AS articolo, SHSAPIK.SHLQTY*0.01 AS qta, SHSAPIK.SHLRIORR AS pos,
SHSAPIK.SHLRIORS AS seq, SHSADAT.SHTCDINT AS cliente, SHSADAT.SHTMGFR AS magazzino,
DBSAITE.MPDSC AS descarticolo, DBSAITE.MUTMS AS umis, ANSADID.ANINCO as nomecliente
FROM SHSAPIK
INNER JOIN SHSADAT ON SHSAPIK.SHTNUM = SHSADAT.SHTNUM AND SHSAPIK.SHTCOSOC = SHSADAT.SHTCOSOC
INNER JOIN DBSAITE ON SHSAPIK.SHLCDART = DBSAITE.MITEM AND SHSAPIK.SHTCOSOC = DBSAITE.MCOSC
INNER JOIN ANSADID ON SHSADAT.SHTCDINT = ANSADID.ANCOCO AND SHSADAT.SHTCOSOC = ANSADID.ANCOSO
WHERE SHSAPIK.SHTCOSOC=?
AND SHSADAT.SHTSTAT='05'
AND SHSAPIK.SHLRIORN=?
order by SHSAPIK.SHLCDART,SHSAPIK.SHLQTY desc", societa, odv)
                .Select(r => new Dictionary<string, object?>
                {
                    ["articolo"] = Trim(Testo(r, "ARTICOLO")),
                    ["descarticolo"] = SpaziMultipli(Testo(r, "DESCARTICOLO")),
                    ["umis"] = Trim(Testo(r, "UMIS")),
                    ["pos"] = PhpInt(Trim(Testo(r, "POS"))),
                    ["seq"] = PhpInt(Trim(Testo(r, "SEQ"))),
                    ["qta"] = PhpFloat(Trim(Testo(r, "QTA"))),
                    ["magto"] = Trim(Testo(r, "MAGAZZINO")),
                    ["cliente"] = Trim(Testo(r, "CLIENTE")),
                    ["nomecliente"] = SpaziMultipli(Testo(r, "NOMECLIENTE")),
                    ["magfrom"] = null,
                    ["giacenza_10"] = 0,
                    ["giacenza_00"] = 0
                }).ToList();

            // Lo stesso articolo può comparire su più posizioni: la giacenza deve coprire la quantità cumulata
            var articoloCorrente = "";
            double qtaArticoloCorrente = 0;

            foreach (var riga in listaRighe)
            {
                var articolo = (string)riga["articolo"]!;

                if (articolo != articoloCorrente)
                {
                    articoloCorrente = articolo;
                    qtaArticoloCorrente = 0;
                }

                qtaArticoloCorrente += (double)riga["qta"]!;

                // Prima MGAUT10 poi MGAUT00
                var giacenze = DbHelper.Query(conn, null, @"
    SELECT
    MASAMSL.MLLOC, MASAMSL.MALOHQT/100 AS GIACENTE
    FROM MASAMSL
    FULL JOIN DBSAITE ON DBSAITE.MITEM = MASAMSL.MALITEM AND DBSAITE.MCOSC = MASAMSL.MAHCOSC
    WHERE DBSAITE.MITEM=? AND MASAMSL.MAHCOSC=? AND (MASAMSL.MLLOC='MGAUT00' OR MASAMSL.MLLOC='MGAUT10')
    GROUP BY MASAMSL.MLLOC, MASAMSL.MALOHQT
    ORDER BY MASAMSL.MLLOC DESC", articolo, societa);

                foreach (var g in giacenze)
                {
                    var magAuto = Trim(Testo(g, "MLLOC"));
                    var giacenza = PhpFloat(Trim(Testo(g, "GIACENTE")));

                    if (magAuto == "MGAUT10")
                    {
                        riga["giacenza_10"] = giacenza;
                        if (giacenza >= qtaArticoloCorrente) riga["magfrom"] = "MGAUT10";
                    }

                    if (magAuto == "MGAUT00")
                    {
                        riga["giacenza_00"] = giacenza;
                        // Solo se non c'è già giacenza sufficiente su MGAUT10
                        if (giacenza >= qtaArticoloCorrente && riga["magfrom"] == null) riga["magfrom"] = "MGAUT00";
                    }
                }
            }

            return listaRighe;
        }

        private const string FROM_ODL_DISPO_MGAUT = @"FROM cs_fabbmanc_odl_dispo
inner join cs_fabbmanc_odl_comp on
cs_fabbmanc_odl_dispo.fase = cs_fabbmanc_odl_comp.fase
and cs_fabbmanc_odl_comp.articolo = cs_fabbmanc_odl_dispo.articolo
and cs_fabbmanc_odl_dispo.magazzino = cs_fabbmanc_odl_comp.magazzino
and cs_fabbmanc_odl_dispo.numero = cs_fabbmanc_odl_comp.numero
and cs_fabbmanc_odl_dispo.societa = cs_fabbmanc_odl_comp.societa
inner join cs_fabbmanc_odl
on cs_fabbmanc_odl.numero = cs_fabbmanc_odl_comp.numero
and cs_fabbmanc_odl_comp.societa = cs_fabbmanc_odl.societa
inner join  cs_fabbmanc_odl_fasi on cs_fabbmanc_odl_dispo.fase = cs_fabbmanc_odl_fasi.fase and cs_fabbmanc_odl_dispo.numero = cs_fabbmanc_odl_fasi.numero";

        private const string FROM_RODV_DISPO = @"from cs_fabbmanc_rodv
    inner join cs_fabbmanc_rodv_dispo ON (cs_fabbmanc_rodv_dispo.numero = cs_fabbmanc_rodv.numero and cs_fabbmanc_rodv_dispo.pos = cs_fabbmanc_rodv.pos and cs_fabbmanc_rodv_dispo.seq = cs_fabbmanc_rodv.seq and cs_fabbmanc_rodv_dispo.societa = cs_fabbmanc_rodv.societa)
    inner join cs_fabbmanc_odv ON (cs_fabbmanc_rodv_dispo.numero = cs_fabbmanc_odv.numero and cs_fabbmanc_rodv_dispo.societa = cs_fabbmanc_odv.societa)";

        /// <summary>
        /// Articoli di un ODL/fase disponibili sul magazzino automatico di origine per il magazzino di destinazione
        /// (ex mgaut_prel_odl_get_articoli.php).
        /// </summary>
        public List<Dictionary<string, object?>> MgautPrelOdlGetArticoli(MgautPrelOdlGetArticoliRequest request, string societa)
        {
            var odl = Obbligatorio(request.odl, "odl");
            var fase = Obbligatorio(request.fase, "fase");
            var origine = Obbligatorio(request.magazzino_origine, "magazzino_origine");
            var destinazione = Obbligatorio(request.magazzino_destinazione, "magazzino_destinazione");

            return DbHelper.Query(_conn.PgCasagrande, $@"select cs_fabbmanc_odl_dispo.articolo, cs_fabbmanc_odl_dispo.giacdispo as qta
{FROM_ODL_DISPO_MGAUT}
where cs_fabbmanc_odl_comp.numero=?
and cs_fabbmanc_odl_comp.fase=?
and cs_fabbmanc_odl_dispo.magdispo=?
and cs_fabbmanc_odl_comp.magazzino=?
and cs_fabbmanc_odl_dispo.isauto='1'
and cs_fabbmanc_odl_dispo.societa = ?
and cs_fabbmanc_odl_comp.magazzino != ':'
order by cs_fabbmanc_odl_dispo.articolo", odl, fase, origine, destinazione, societa);
        }

        /// <summary>
        /// Magazzini di destinazione (ODL) per cui l'articolo è disponibile sul magazzino automatico di origine
        /// (ex mgaut_prel_odl_get_magazzini.php).
        /// </summary>
        public List<string?> MgautPrelOdlGetMagazzini(MgautPrelOdlGetMagazziniRequest request, string societa)
        {
            var articolo = Obbligatorio(request.articolo, "articolo");
            var origine = Obbligatorio(request.magazzino_origine, "magazzino_origine");

            return DbHelper.Query(_conn.PgCasagrande, $@"select distinct cs_fabbmanc_odl_comp.magazzino
{FROM_ODL_DISPO_MGAUT}
where cs_fabbmanc_odl_dispo.articolo=?
and cs_fabbmanc_odl_dispo.magdispo = ?
and cs_fabbmanc_odl_dispo.isauto='1'
and cs_fabbmanc_odl_dispo.societa = ?
and cs_fabbmanc_odl_comp.magazzino != ':'
order by cs_fabbmanc_odl_comp.magazzino", articolo, origine, societa)
                .Select(r => Testo(r, "magazzino")).ToList();
        }

        /// <summary>
        /// ODL/fasi con articoli (tutti o quello indicato) disponibili sul magazzino automatico di origine per il
        /// magazzino di destinazione (ex mgaut_prel_odl_get_odl.php).
        /// </summary>
        public List<Dictionary<string, object?>> MgautPrelOdlGetOdl(MgautPrelOdlGetOdlRequest request, string societa)
        {
            var articolo = request.articolo ?? "";
            var origine = Obbligatorio(request.magazzino_origine, "magazzino_origine");
            var destinazione = Obbligatorio(request.magazzino_destinazione, "magazzino_destinazione");

            var parametri = new List<object?> { destinazione };
            var whereArticolo = "";
            if (articolo != "")
            {
                whereArticolo = "and cs_fabbmanc_odl_dispo.articolo=?";
                parametri.Add(articolo);
            }
            parametri.Add(origine);
            parametri.Add(societa);

            return DbHelper.Query(_conn.PgCasagrande, $@"select cs_fabbmanc_odl_comp.numero as odl, cs_fabbmanc_odl_comp.fase, cs_fabbmanc_odl.articolo AS padre, cs_fabbmanc_odl.descarticolo as des_padre, cs_fabbmanc_odl_fasi.descrizione as descrizionefase, cs_fabbmanc_odl_dispo.giacdispo as qta
{FROM_ODL_DISPO_MGAUT}
where cs_fabbmanc_odl_comp.magazzino=?
{whereArticolo}
and cs_fabbmanc_odl_dispo.magdispo = ?
and cs_fabbmanc_odl_dispo.isauto='1'
and cs_fabbmanc_odl_dispo.societa = ?
order by cs_fabbmanc_odl_dispo.numero", parametri.ToArray());
        }

        /// <summary>
        /// Articoli di un ODV disponibili sul magazzino automatico di origine per il magazzino di destinazione
        /// (ex mgaut_prel_odv_get_articoli.php).
        /// </summary>
        public List<Dictionary<string, object?>> MgautPrelOdvGetArticoli(MgautPrelOdvGetArticoliRequest request, string societa)
        {
            var odv = Obbligatorio(request.odv, "odv");
            var origine = Obbligatorio(request.magazzino_origine, "magazzino_origine");
            var destinazione = Obbligatorio(request.magazzino_destinazione, "magazzino_destinazione");

            return DbHelper.Query(_conn.PgCasagrande, $@"select cs_fabbmanc_rodv.articolo, cs_fabbmanc_rodv.pos, cs_fabbmanc_rodv.seq, cs_fabbmanc_rodv.giacdispo as qta
    {FROM_RODV_DISPO}
    and cs_fabbmanc_odv.numero=?
    and magazzino=?
    and magdispo=?
    and cs_fabbmanc_rodv_dispo.isauto='1'
    and cs_fabbmanc_rodv.societa=?
    order by cs_fabbmanc_rodv.articolo", odv, destinazione, origine, societa);
        }

        /// <summary>
        /// Magazzini di destinazione (ODV) per cui l'articolo è disponibile sul magazzino automatico di origine
        /// (ex mgaut_prel_odv_get_magazzini.php).
        /// </summary>
        public List<string?> MgautPrelOdvGetMagazzini(MgautPrelOdvGetMagazziniRequest request, string societa)
        {
            var articolo = Obbligatorio(request.articolo, "articolo");
            var origine = Obbligatorio(request.magazzino_origine, "magazzino_origine");

            return DbHelper.Query(_conn.PgCasagrande, $@"select distinct magazzino
    {FROM_RODV_DISPO}
    where cs_fabbmanc_rodv.articolo=?
    and magdispo=?
    and cs_fabbmanc_rodv_dispo.isauto='1'
    and cs_fabbmanc_rodv.societa=?
    order by magazzino", articolo, origine, societa)
                .Select(r => Testo(r, "magazzino")).ToList();
        }

        /// <summary>
        /// ODV con articoli (tutti o quello indicato) disponibili sul magazzino automatico di origine per il magazzino
        /// di destinazione (ex mgaut_prel_odv_get_odv.php).
        /// </summary>
        public List<Dictionary<string, object?>> MgautPrelOdvGetOdv(MgautPrelOdvGetOdvRequest request, string societa)
        {
            var articolo = request.articolo ?? "";
            var origine = Obbligatorio(request.magazzino_origine, "magazzino_origine");
            var destinazione = Obbligatorio(request.magazzino_destinazione, "magazzino_destinazione");

            var parametri = new List<object?> { destinazione, origine };
            var whereArticolo = "";
            if (articolo != "")
            {
                whereArticolo = "and cs_fabbmanc_rodv.articolo=?";
                parametri.Add(articolo);
            }
            parametri.Add(societa);

            return DbHelper.Query(_conn.PgCasagrande, $@"select cs_fabbmanc_odv.numero as odv, cs_fabbmanc_odv.cliente, cs_fabbmanc_odv.nomecliente, cs_fabbmanc_rodv.pos, cs_fabbmanc_rodv.seq, cs_fabbmanc_rodv.giacdispo as qta
    {FROM_RODV_DISPO}
    where magazzino=?
    and magdispo=?
    {whereArticolo}
    and cs_fabbmanc_rodv_dispo.isauto='1'
    and cs_fabbmanc_rodv.societa=?
    order by cs_fabbmanc_odv.numero, cs_fabbmanc_rodv.pos", parametri.ToArray());
        }

        // -------------------------------------------------------------------------------------------------------------
        // ----- UTILITÀ -----------------------------------------------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>Copia padre / descrizione / colore dall'ultima riga (come il ciclo del PHP).</summary>
        private static void AggiungiInfoPadre(Dictionary<string, object?> destinazione, List<Dictionary<string, object?>> padri)
        {
            foreach (var p in padri)
            {
                destinazione["padre"] = Testo(p, "codicepadre");
                destinazione["descrizionePadre"] = Testo(p, "descpadre");
                destinazione["colore"] = Testo(p, "desccolore");
            }
        }

        /// <summary>Valore di una colonna come stringa (nome cercato anche senza distinzione maiuscole/minuscole).</summary>
        private static string? Testo(Dictionary<string, object?> riga, string colonna)
        {
            if (riga.TryGetValue(colonna, out var valore)) return valore?.ToString();

            foreach (var kv in riga)
            {
                if (string.Equals(kv.Key, colonna, StringComparison.OrdinalIgnoreCase)) return kv.Value?.ToString();
            }

            return null;
        }

        /// <summary>trim() PHP (null → "").</summary>
        private static string Trim(string? valore) => (valore ?? "").Trim();

        /// <summary>preg_replace('/\s\s+/', ' ', trim(x)) del PHP.</summary>
        private static string SpaziMultipli(string? valore) => Regex.Replace(Trim(valore), @"\s\s+", " ");

        /// <summary>Cast (int) del PHP: cifre iniziali, altrimenti 0.</summary>
        private static int PhpInt(string? valore)
        {
            var m = Regex.Match(valore ?? "", @"^\s*[+-]?\d+");
            if (!m.Success) return 0;
            return long.TryParse(m.Value.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var n)
                ? (int)Math.Clamp(n, int.MinValue, int.MaxValue)
                : 0;
        }

        /// <summary>Cast (float) del PHP: numero iniziale, altrimenti 0.</summary>
        private static double PhpFloat(string? valore)
        {
            var m = Regex.Match(valore ?? "", @"^\s*[+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?");
            return m.Success && double.TryParse(m.Value.Trim(), NumberStyles.Float, CultureInfo.InvariantCulture, out var d) ? d : 0;
        }

        /// <summary>Espressione PHP <c>$x ? $x : null</c> interpolata in una stringa: i valori "falsi" diventano "".</summary>
        private static string PhpVero(string? valore) => string.IsNullOrEmpty(valore) || valore == "0" ? "" : valore;

        /// <summary>Valore di un campo JSON come lo interpolava PHP in una stringa.</summary>
        private static string JsonTesto(JsonElement? elemento)
        {
            if (elemento == null) return "";

            return elemento.Value.ValueKind switch
            {
                JsonValueKind.String => elemento.Value.GetString() ?? "",
                JsonValueKind.Number => elemento.Value.GetRawText(),
                JsonValueKind.True => "1",
                JsonValueKind.False or JsonValueKind.Null or JsonValueKind.Undefined => "",
                _ => elemento.Value.GetRawText()
            };
        }

        /// <summary>Parametro obbligatorio non vuoto.</summary>
        private static string Obbligatorio(string? valore, string nome)
        {
            if (string.IsNullOrWhiteSpace(valore)) throw new MobileException($"Parametro {nome} obbligatorio");
            return valore;
        }

        /// <summary>Parametro intero obbligatorio.</summary>
        private static int IntValido(string? valore, string nome)
        {
            if (!int.TryParse(valore?.Trim(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var n))
            {
                throw new MobileException($"Parametro {nome} non valido");
            }
            return n;
        }

        /// <summary>date("Ymd") come intero.</summary>
        private static int Oggi() => int.Parse(DateTime.Now.ToString("yyyyMMdd", CultureInfo.InvariantCulture), CultureInfo.InvariantCulture);

        /// <summary>date("His") come intero.</summary>
        private static int OraAdesso() => int.Parse(DateTime.Now.ToString("HHmmss", CultureInfo.InvariantCulture), CultureInfo.InvariantCulture);
    }
}
