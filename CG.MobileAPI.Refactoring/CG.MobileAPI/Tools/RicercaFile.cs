using System.ComponentModel;
using System.Runtime.InteropServices;

namespace CG.MobileAPI.Tools
{
    /// <summary>
    /// Ricerca di file per pattern (es. <c>0010001*.pdf</c>) fatta dal file system / file server.
    /// <para>
    /// <see cref="Directory.GetFiles(string, string)"/> in .NET legge l'elenco COMPLETO della cartella e filtra in
    /// memoria: su una cartella di rete con centinaia di migliaia di file (Archivio3d) impiega più di un minuto.
    /// FindFirstFileEx invece passa il pattern al server, che restituisce solo i file corrispondenti (decine di ms).
    /// </para>
    /// </summary>
    public static class RicercaFile
    {
        private const int FIND_EX_INFO_BASIC = 1;
        private const int FIND_EX_SEARCH_NAME_MATCH = 0;
        private const int FIND_FIRST_EX_LARGE_FETCH = 2;
        private const int ERROR_FILE_NOT_FOUND = 2;
        private const int ERROR_NO_MORE_FILES = 18;
        private const uint FILE_ATTRIBUTE_DIRECTORY = 0x10;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        private struct WIN32_FIND_DATA
        {
            public uint dwFileAttributes;
            public uint ftCreationTimeLow, ftCreationTimeHigh;
            public uint ftLastAccessTimeLow, ftLastAccessTimeHigh;
            public uint ftLastWriteTimeLow, ftLastWriteTimeHigh;
            public uint nFileSizeHigh, nFileSizeLow;
            public uint dwReserved0, dwReserved1;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string cFileName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 14)] public string cAlternateFileName;
        }

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr FindFirstFileExW(string lpFileName, int fInfoLevelId, out WIN32_FIND_DATA lpFindFileData,
            int fSearchOp, IntPtr lpSearchFilter, int dwAdditionalFlags);

        [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern bool FindNextFileW(IntPtr hFindFile, out WIN32_FIND_DATA lpFindFileData);

        [DllImport("kernel32.dll")]
        private static extern bool FindClose(IntPtr hFindFile);

        /// <summary>
        /// Nomi dei file (non delle cartelle) di <paramref name="cartella"/> che corrispondono a <paramref name="pattern"/>,
        /// in ordine di nome. Il pattern non deve contenere separatori di percorso.
        /// </summary>
        /// <exception cref="DirectoryNotFoundException">La cartella non esiste o non è raggiungibile.</exception>
        /// <exception cref="UnauthorizedAccessException">Accesso negato alla cartella.</exception>
        public static List<string> Elenca(string cartella, string pattern)
        {
            if (!OperatingSystem.IsWindows())
            {
                return Directory.GetFiles(cartella, pattern).Select(Path.GetFileName).OfType<string>()
                    .OrderBy(f => f, StringComparer.Ordinal).ToList();
            }

            var risultato = new List<string>();
            var handle = FindFirstFileExW(Path.Combine(cartella, pattern), FIND_EX_INFO_BASIC, out var dati,
                FIND_EX_SEARCH_NAME_MATCH, IntPtr.Zero, FIND_FIRST_EX_LARGE_FETCH);
            if (handle == new IntPtr(-1))
            {
                var errore = Marshal.GetLastWin32Error();
                if (errore == ERROR_FILE_NOT_FOUND || errore == ERROR_NO_MORE_FILES)
                {
                    return risultato;
                }
                if (errore == 5)
                {
                    throw new UnauthorizedAccessException($"Accesso negato a {cartella}");
                }
                throw new DirectoryNotFoundException($"{cartella}: {new Win32Exception(errore).Message}");
            }

            try
            {
                do
                {
                    if ((dati.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0)
                    {
                        risultato.Add(dati.cFileName);
                    }
                }
                while (FindNextFileW(handle, out dati));
            }
            finally
            {
                FindClose(handle);
            }
            return risultato.OrderBy(f => f, StringComparer.Ordinal).ToList();
        }
    }
}
