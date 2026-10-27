using CG.MobileAPI.Models;
using Microsoft.Extensions.Options;
using System.Data.Common;
using System.Data.Odbc;

namespace CG.MobileAPI.Data
{
    /// <summary>
    /// Rappresenta il contesto di database personalizzato che fornisce l'accesso ai vari servizi di dati (DBSAITE, DIAPOPER, CSDBGRR, ANSADID e DBMAGAZZINO).
    /// </summary>
    public class MyDbContext
    {
        private readonly ConfigurationLoader _configLoader;
        private readonly string _connectionStringTest;
        private readonly string _connectionStringProd;
        private readonly string _connectionStringBCK;
        private readonly string _connectionStringCGU;
        private readonly string _connectionStringCGUTest;
        private readonly string _connectionStringPostgre;

        /// <summary>
        /// Inizializza una nuova istanza della classe <see cref="MyDbContext"/>.
        /// </summary>
        /// <param name="connectionStringTest">La stringa di connessione per il database di test.</param>
        /// <param name="connectionStringProd">La stringa di connessione per il database di produzione.</param>
        /// <param name="connectionStringBCK">La stringa di connessione per il database di backup.</param>
        /// <param name="config">Le opzioni di configurazione che contengono il loader delle configurazioni.</param>
        /// <param name="mobile">Le stringhe di connessione dei servizi dell'app mobile.</param>
        public MyDbContext(string connectionStringTest, string connectionStringProd, string connectionStringBCK, string connectionStringCGU, string connectionStringCGUTest, string connectionStringPostgre, IOptions<ConfigurationLoader> config, MobileConnections mobile)
        {
            _configLoader = config.Value;
            _connectionStringTest = connectionStringTest;
            _connectionStringProd = _configLoader.IsTest ? connectionStringTest : connectionStringProd;
            _connectionStringBCK = _configLoader.IsTest ? connectionStringTest : connectionStringBCK;
            _connectionStringCGU = _configLoader.IsTest ? connectionStringCGUTest : connectionStringCGU;
            _connectionStringPostgre = connectionStringPostgre;

            mobile.Db2 = _configLoader.IsTest ? connectionStringTest : connectionStringProd;
            mobile.Db2Replica = _configLoader.IsTest ? connectionStringTest : connectionStringBCK;

            DBSAITE = new DBSAITE(_connectionStringTest, _connectionStringProd, _connectionStringBCK);
            DBAUTH = new DBAUTH(mobile);
            DBGENERALE = new DBGENERALE(mobile);
            DBGIACENZE_LISTE = new DBGIACENZE_LISTE(mobile);
            DBGIACENZE_ARTICOLI = new DBGIACENZE_ARTICOLI(mobile);
            DBPRODUZIONE = new DBPRODUZIONE(mobile);
            DBAVVISI = new DBAVVISI(mobile);
            DBCHAT = new DBCHAT(mobile);
            DBKANBAN = new DBKANBAN(mobile);
            DBMOVIMENTI = new DBMOVIMENTI(mobile);
        }

        /// <summary>
        /// Ottiene l'istanza del servizio DBSAITE (ARTICOLI).
        /// </summary>
        public DBSAITE DBSAITE;

        /// <summary>
        /// Ottiene l'istanza del servizio DBAUTH (login e profilo utente).
        /// </summary>
        public DBAUTH DBAUTH;

        /// <summary>
        /// Ottiene l'istanza del servizio DBGENERALE (versione, foto, ODV e servizi generali).
        /// </summary>
        public DBGENERALE DBGENERALE;

        /// <summary>
        /// Ottiene l'istanza del servizio DBGIACENZE_LISTE (liste, prelievi, MGAUT e storico movimenti).
        /// </summary>
        public DBGIACENZE_LISTE DBGIACENZE_LISTE;

        /// <summary>
        /// Ottiene l'istanza del servizio DBGIACENZE_ARTICOLI (articoli, magazzini, vani e inventario).
        /// </summary>
        public DBGIACENZE_ARTICOLI DBGIACENZE_ARTICOLI;

        /// <summary>
        /// Ottiene l'istanza del servizio DBPRODUZIONE (produzione, impegno ODL, pre-carico e qualità).
        /// </summary>
        public DBPRODUZIONE DBPRODUZIONE;

        /// <summary>
        /// Ottiene l'istanza del servizio DBAVVISI (attività / avvisi).
        /// </summary>
        public DBAVVISI DBAVVISI;

        /// <summary>
        /// Ottiene l'istanza del servizio DBCHAT (chat).
        /// </summary>
        public DBCHAT DBCHAT;

        /// <summary>
        /// Ottiene l'istanza del servizio DBKANBAN (kanban e scaffali).
        /// </summary>
        public DBKANBAN DBKANBAN;

        /// <summary>
        /// Ottiene l'istanza del servizio DBMOVIMENTI (movimenti di magazzino verso Diapason).
        /// </summary>
        public DBMOVIMENTI DBMOVIMENTI;
    }
}
