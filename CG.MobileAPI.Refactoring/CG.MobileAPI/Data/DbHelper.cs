using System.Data.Odbc;
using System.Reflection.PortableExecutable;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory;
using static Microsoft.EntityFrameworkCore.DbLoggerCategory.Database;

namespace CG.MobileAPI.Data
{
    /// <summary>
    /// Fornisce metodi helper per l'esecuzione di query e operazioni ODBC in modo centralizzato.
    /// </summary>
    public static class DbHelper
    {
        /// <summary>
        /// Esegue la query utilizzando un comando ODBC già configurato e una connessione aperta.
        /// </summary>
        /// <param name="command">Il comando ODBC da eseguire.</param>
        /// <returns>Un oggetto <see cref="OdbcDataReader"/> contenente i risultati della query.</returns>
        public static OdbcDataReader ExecuteQuerySharedConn(OdbcCommand command)
        {
            command.CommandType = System.Data.CommandType.Text;
            command.CommandTimeout = 0;
            OdbcDataReader reader = command.ExecuteReader();
            return reader;
        }

        /// <summary>
        /// Esegue una query SQL utilizzando una nuova connessione ODBC e restituisce un <see cref="OdbcDataReader"/>.
        /// </summary>
        /// <param name="connectionString">La stringa di connessione da utilizzare.</param>
        /// <param name="query">La query SQL da eseguire.</param>
        /// <returns>Un oggetto <see cref="OdbcDataReader"/> con i risultati della query.</returns>
        public static OdbcDataReader ExecuteQuery(string connectionString, string query)
        {
            using (OdbcConnection conn = new OdbcConnection(connectionString))
            {
                using (OdbcCommand command = new OdbcCommand(query, conn))
                {
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandTimeout = 0;
                    command.Connection.Open();
                    OdbcDataReader reader = command.ExecuteReader();
                    return reader;
                }
            }
        }

        /// <summary>
        /// Esegue una query non di selezione (INSERT, UPDATE, DELETE) e restituisce un valore booleano che indica se l'operazione è andata a buon fine.
        /// </summary>
        /// <param name="connectionString">La stringa di connessione da utilizzare.</param>
        /// <param name="query">La query SQL da eseguire.</param>
        /// <returns><c>true</c> se la query è stata eseguita correttamente; altrimenti, <c>false</c>.</returns>
        public static bool ExecuteNonQuery(string connectionString, string query)
        {
            using (OdbcConnection conn = new OdbcConnection(connectionString))
            {
                using (OdbcCommand command = new OdbcCommand(query, conn))
                {
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandTimeout = 0;
                    command.Connection.Open();
                    try
                    {
                        command.ExecuteNonQuery();
                        command.Dispose();
                        conn.Close(); 

                        return true;
                    }
                    catch (Exception e)
                    {
                        command.Dispose();
                        conn.Close();
                        return false;
                    }
                }
            }
        }


        /// <summary>
        /// Esegue una query e restituisce <c>true</c> se la query restituisce almeno una riga.
        /// </summary>
        /// <param name="connectionString">La stringa di connessione da utilizzare.</param>
        /// <param name="query">La query SQL da eseguire.</param>
        /// <returns><c>true</c> se la query ha restituito delle righe; altrimenti, <c>false</c>.</returns>
        public static bool ExecuteCount(string connectionString, string query)
        {
            using (OdbcConnection conn = new OdbcConnection(connectionString))
            {
                using (OdbcCommand command = new OdbcCommand(query, conn))
                {
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandTimeout = 0;
                    command.Connection.Open();
                    try
                    {
                        OdbcDataReader reader = command.ExecuteReader();
                        return reader.HasRows;
                    }
                    catch (Exception e)
                    {
                        return false;
                    }
                }
            }
        }

        /// <summary>
        /// Esegue una query SQL in modo sicuro e restituisce i risultati come una lista di dizionari.
        /// Ogni dizionario rappresenta una riga, con coppie chiave/valore corrispondenti ai nomi delle colonne e ai loro valori.
        /// </summary>
        /// <param name="connectionString">La stringa di connessione da utilizzare.</param>
        /// <param name="query">La query SQL da eseguire.</param>
        /// <returns>Una lista di dizionari contenenti i risultati della query.</returns>
        public static List<Dictionary<string, object>> ExecuteSafeQuery(string connectionString, string query)
        {
            var results = new List<Dictionary<string, object>>();

            try
            {
                using (OdbcConnection conn = new OdbcConnection(connectionString))
                using (OdbcCommand command = new OdbcCommand(query, conn))
                {
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandTimeout = 0;
                    conn.Open();
                    using (OdbcDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var row = new Dictionary<string, object?>();

                            for (int i = 0; i < reader.FieldCount; i++)
                            {
                                string columnName = reader.GetName(i);

                                row[columnName] = reader.IsDBNull(i)
                                    ? null
                                    : reader.GetValue(i);
                            }

                            results.Add(row);
                        }
                    }
                    conn.Close();
                }
            }catch(Exception e)
            {
                throw;
            }

            return results;
        }


        /// <summary>
        /// Esegue una query e restituisce <c>true</c> se la query restituisce almeno una riga.
        /// </summary>
        /// <param name="connectionString">La stringa di connessione da utilizzare.</param>
        /// <param name="query">La query SQL da eseguire.</param>
        /// <returns><c>true</c> se la query ha restituito delle righe; altrimenti, <c>false</c>.</returns>
        public static int ExecuteSafeCount(string connectionString, string query)
        {
            try
            {
                var response = ExecuteSafeQuery(connectionString, query);

                return response.Count();
            }catch(Exception e)
            {
                throw;
            }
        }

        /// <summary>
        /// Esegue una query SQL in modo sicuro utilizzando una connessione ODBC già aperta e restituisce i risultati come una lista di dizionari.
        /// </summary>
        /// <param name="conn">La connessione ODBC già aperta.</param>
        /// <param name="query">La query SQL da eseguire.</param>
        /// <returns>Una lista di dizionari contenenti i risultati della query.</returns>
        /// <remarks>
        /// <b>NB:</b> Ricordarsi di aprire e chiudere la connessione prima e dopo questo metodo
        /// </remarks>
        public static List<Dictionary<string, object>> ExecuteSafeQuerySharedConnection(OdbcConnection conn, string query)
        {
            var results = new List<Dictionary<string, object>>();
            using (OdbcCommand command = new OdbcCommand(query, conn))
            {
                command.CommandType = System.Data.CommandType.Text;
                command.CommandTimeout = 0;
                using (OdbcDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var row = new Dictionary<string, object>();
                        for (int i = 0; i < reader.FieldCount; i++)
                        {
                            row[reader.GetName(i)] = reader.GetValue(i);
                        }
                        results.Add(row);
                    }
                    reader.Close();
                }
            }
            return results;
        }

        public static bool ExecuteNonQuerySharedConnection(OdbcConnection conn, string query, OdbcTransaction? transaction)
        {
            using (OdbcCommand command = new OdbcCommand(query, conn, transaction))
            {
                command.CommandType = System.Data.CommandType.Text;
                command.CommandTimeout = 0;
                try
                {
                    command.ExecuteNonQuery();

                    return true;
                }
                catch (Exception e)
                {
                    return false;
                }
            }
        }

        /// <summary>
        /// Esegue una query SQL in modo sicuro utilizzando una connessione ODBC già aperta e restituisce i risultati come una lista di dizionari.
        /// </summary>
        /// <param name="connectionString">La stringa di connessione al DB.</param>
        /// <param name="query">La query SQL da eseguire.</param>
        /// <param name="parameters">ODBC bind parameters definito come lista di tuple <code>(string, int, int, object)</code>.</param>
        /// <returns>Una lista di dizionari contenenti i risultati della query.</returns>
        /// <remarks>
        /// <b>NB:</b> Ricordarsi di aprire e chiudere la connessione prima e dopo questo metodo
        /// </remarks>
        /// <remarks>
        /// Il quarto parametro <paramref name="parameters"/> prevede una lista di <i>binding parameters</i> per cui si definisce in ordine il Nome
        /// parametro nel formato <code>@...</code>, il Tipo parametro secondo definizione Enumerazione <code>System.Data.Odbc</code>, la lunghezza del campo (VarChar)
        /// e il valore che si vuole assegnare al parametro definito nella tupla, osservando una logica di tipo posizionale.
        /// </remarks>
        public static List<Dictionary<string, object>> ExecuteSafeQuery(string connectionString, string query, List<(string, int, int, object)> parameters)
        {
            var results = new List<Dictionary<string, object>>();

            using (OdbcConnection conn = new OdbcConnection(connectionString))
            {
                using (OdbcCommand command = new OdbcCommand(query, conn))
                {
                    command.CommandType = System.Data.CommandType.Text;
                    command.CommandTimeout = 0;

                    foreach (var p in parameters)
                    {
                        if (!Enum.IsDefined(typeof(OdbcType), p.Item2))
                        {
                            continue;
                        }

                        if (p.Item2 == (int)OdbcType.VarChar)
                        {
                            command.Parameters.Add(p.Item1, (OdbcType)p.Item2, p.Item3).Value = p.Item4;
                        }
                        else
                        {
                            command.Parameters.Add(p.Item1, (OdbcType)p.Item2).Value = p.Item4;
                        }
                    }

                    using (OdbcDataReader reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var row = new Dictionary<string, object>();
                            for (int i = 0; i < reader.FieldCount; i++)
                            {
                                row[reader.GetName(i)] = reader.GetValue(i);
                            }
                            results.Add(row);
                        }
                        reader.Close();
                    }
                }
            }

            return results;
        }

        // -------------------------------------------------------------------------------------------------------------
        // --- Query parametrizzate (marker posizionali "?") -----------------------------------------------------------
        // -------------------------------------------------------------------------------------------------------------

        /// <summary>
        /// Esegue una SELECT parametrizzata e restituisce le righe come dizionari colonna/valore.
        /// I valori sono convertiti in stringa come faceva PHP (odbc_fetch / pg_fetch): numeri in formato invariante,
        /// date in <c>yyyy-MM-dd</c>, timestamp in <c>yyyy-MM-dd HH:mm:ss</c>, booleani in <c>t</c>/<c>f</c>, NULL come <c>null</c>.
        /// </summary>
        /// <param name="connectionString">La stringa di connessione da utilizzare.</param>
        /// <param name="query">La query SQL con i marker <c>?</c>.</param>
        /// <param name="values">I valori dei parametri, nell'ordine dei marker.</param>
        /// <returns>Una lista di dizionari contenenti i risultati della query.</returns>
        public static List<Dictionary<string, object?>> Query(string connectionString, string query, params object?[] values)
        {
            using var conn = new OdbcConnection(connectionString);
            conn.Open();
            return Query(conn, null, query, values);
        }

        /// <summary>
        /// Come <see cref="Query(string, string, object?[])"/> ma su una connessione già aperta (ed eventuale transazione).
        /// </summary>
        public static List<Dictionary<string, object?>> Query(OdbcConnection conn, OdbcTransaction? transaction, string query, params object?[] values)
        {
            var results = new List<Dictionary<string, object?>>();
            using var command = CreateCommand(conn, transaction, query, values);
            using var reader = command.ExecuteReader();
            while (reader.Read())
            {
                var row = new Dictionary<string, object?>();
                for (int i = 0; i < reader.FieldCount; i++)
                {
                    row[reader.GetName(i)] = reader.IsDBNull(i) ? null : ToPhpString(reader.GetValue(i), reader.GetDataTypeName(i));
                }
                results.Add(row);
            }
            return results;
        }

        /// <summary>
        /// Esegue una SELECT parametrizzata e restituisce la prima riga, o <c>null</c> se non ci sono risultati.
        /// </summary>
        public static Dictionary<string, object?>? QueryFirst(string connectionString, string query, params object?[] values)
        {
            return Query(connectionString, query, values).FirstOrDefault();
        }

        /// <summary>
        /// Esegue una query parametrizzata e restituisce il valore della prima colonna della prima riga (come stringa), o <c>null</c>.
        /// </summary>
        public static string? Scalar(string connectionString, string query, params object?[] values)
        {
            var row = QueryFirst(connectionString, query, values);
            return row == null || row.Count == 0 ? null : row.Values.First()?.ToString();
        }

        /// <summary>
        /// Esegue un INSERT / UPDATE / DELETE parametrizzato e restituisce il numero di righe coinvolte.
        /// A differenza di <see cref="ExecuteNonQuery(string, string)"/> l'eventuale errore viene propagato.
        /// </summary>
        public static int NonQuery(string connectionString, string query, params object?[] values)
        {
            using var conn = new OdbcConnection(connectionString);
            conn.Open();
            return NonQuery(conn, null, query, values);
        }

        /// <summary>
        /// Come <see cref="NonQuery(string, string, object?[])"/> ma su una connessione già aperta (ed eventuale transazione).
        /// </summary>
        public static int NonQuery(OdbcConnection conn, OdbcTransaction? transaction, string query, params object?[] values)
        {
            using var command = CreateCommand(conn, transaction, query, values);
            return command.ExecuteNonQuery();
        }

        /// <summary>
        /// Genera la lista di marker per una clausola IN parametrizzata: <c>InMarkers(3)</c> = <c>"?,?,?"</c>.
        /// </summary>
        public static string InMarkers(int count)
        {
            if (count <= 0) throw new ArgumentException("La lista IN deve contenere almeno un valore.", nameof(count));
            return string.Join(",", Enumerable.Repeat("?", count));
        }

        private static OdbcCommand CreateCommand(OdbcConnection conn, OdbcTransaction? transaction, string query, object?[] values)
        {
            var command = new OdbcCommand(query, conn, transaction)
            {
                CommandType = System.Data.CommandType.Text,
                CommandTimeout = 0
            };
            foreach (var value in values)
            {
                command.Parameters.Add(CreateParameter(value));
            }
            return command;
        }

        private static OdbcParameter CreateParameter(object? value)
        {
            switch (value)
            {
                case null:
                    return new OdbcParameter { OdbcType = OdbcType.VarChar, Value = DBNull.Value };
                case string s:
                    return new OdbcParameter { OdbcType = OdbcType.VarChar, Size = Math.Max(s.Length, 1), Value = s };
                case int i:
                    return new OdbcParameter { OdbcType = OdbcType.Int, Value = i };
                case long l:
                    return new OdbcParameter { OdbcType = OdbcType.BigInt, Value = l };
                case decimal d:
                    return new OdbcParameter { OdbcType = OdbcType.Decimal, Value = d, Precision = 31, Scale = (byte)d.Scale };
                case double db:
                    return new OdbcParameter { OdbcType = OdbcType.Double, Value = db };
                case bool b:
                    return new OdbcParameter { OdbcType = OdbcType.Bit, Value = b };
                case DateTime dt:
                    return new OdbcParameter { OdbcType = OdbcType.Timestamp, Value = dt };
                default:
                    var str = value.ToString() ?? "";
                    return new OdbcParameter { OdbcType = OdbcType.VarChar, Size = Math.Max(str.Length, 1), Value = str };
            }
        }

        private static string ToPhpString(object value, string dataTypeName)
        {
            var inv = System.Globalization.CultureInfo.InvariantCulture;
            switch (value)
            {
                case DateTime dt:
                    var tipo = (dataTypeName ?? "").ToLowerInvariant();
                    return tipo.Contains("date") && !tipo.Contains("time")
                        ? dt.ToString("yyyy-MM-dd", inv)
                        : dt.ToString("yyyy-MM-dd HH:mm:ss", inv);
                case TimeSpan ts:
                    return ts.ToString(@"hh\:mm\:ss", inv);
                case bool b:
                    return b ? "t" : "f";
                case byte[] bytes:
                    return System.Text.Encoding.UTF8.GetString(bytes);
                case IFormattable f:
                    return f.ToString(null, inv);
                default:
                    return value.ToString() ?? "";
            }
        }
    }
}
