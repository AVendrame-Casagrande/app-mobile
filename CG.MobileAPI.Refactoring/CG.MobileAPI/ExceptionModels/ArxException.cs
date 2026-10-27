namespace CG.MobileAPI.ExceptionModels
{
    public class ArxException : Exception
    {
        public ArxException() { }

        public ArxException(string message)
            : base(message) { }

        public ArxException(string message, Exception inner)
            : base(message, inner) { }
    }
}
