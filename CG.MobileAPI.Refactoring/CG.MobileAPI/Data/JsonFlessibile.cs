using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace CG.MobileAPI.Data
{
    /// <summary>
    /// Legge in una proprietà <c>string</c> anche numeri e booleani JSON (il client li manda nel loro tipo naturale,
    /// mentre i modelli di richiesta tengono i campi come stringhe, come li riceveva PHP).
    /// </summary>
    public class StringaFlessibileConverter : JsonConverter<string>
    {
        /// <inheritdoc />
        public override string? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            switch (reader.TokenType)
            {
                case JsonTokenType.String:
                    return reader.GetString();
                case JsonTokenType.Number:
                    return reader.TryGetInt64(out var l)
                        ? l.ToString(CultureInfo.InvariantCulture)
                        : reader.GetDecimal().ToString(CultureInfo.InvariantCulture);
                case JsonTokenType.True:
                    return "true";
                case JsonTokenType.False:
                    return "false";
                case JsonTokenType.Null:
                    return null;
                default:
                    throw new JsonException($"Valore non convertibile in stringa: {reader.TokenType}");
            }
        }

        /// <inheritdoc />
        public override void Write(Utf8JsonWriter writer, string value, JsonSerializerOptions options)
        {
            writer.WriteStringValue(value);
        }
    }

    /// <summary>
    /// Legge in una proprietà <c>bool</c> anche le stringhe "true"/"false"/"1"/"0".
    /// </summary>
    public class BoolFlessibileConverter : JsonConverter<bool>
    {
        /// <inheritdoc />
        public override bool Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            switch (reader.TokenType)
            {
                case JsonTokenType.True:
                    return true;
                case JsonTokenType.False:
                    return false;
                case JsonTokenType.Number:
                    return reader.GetDecimal() != 0;
                case JsonTokenType.String:
                    var s = (reader.GetString() ?? "").Trim().ToLowerInvariant();
                    return s == "true" || s == "1";
                default:
                    throw new JsonException($"Valore non convertibile in booleano: {reader.TokenType}");
            }
        }

        /// <inheritdoc />
        public override void Write(Utf8JsonWriter writer, bool value, JsonSerializerOptions options)
        {
            writer.WriteBooleanValue(value);
        }
    }
}
