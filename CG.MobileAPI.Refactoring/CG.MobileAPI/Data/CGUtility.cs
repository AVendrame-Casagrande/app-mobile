namespace CG.MobileAPI.Data
{
    public static class CGUtility
    {
        public static DateTime? ParseDateString(string dateStr, string format = "yyyyMMdd")
        {
            if (DateTime.TryParseExact(dateStr, format,
                                       System.Globalization.CultureInfo.InvariantCulture,
                                       System.Globalization.DateTimeStyles.None,
                                       out DateTime parsedDate))
            {
                return parsedDate;
            }
            else
            {
                // Se il formato non è valido, restituisci null (o lancia un'eccezione se preferisci)
                return null;
            }
        }

        public static string GetFormattedString(string date, string format, string parseFormat = "yyyyMMdd")
        {
            DateTime? dateO = ParseDateString(date, parseFormat);

            if(dateO != null)
            {
                DateTime dataConversione = (DateTime)dateO;
                return dataConversione.ToString(format);
            }

            return "";
        }

        public static int GetDecimalDate()
        {
            return DateTime.Now.Year * 10000 + DateTime.Now.Month * 100 + DateTime.Now.Day;
        }
    }
}
