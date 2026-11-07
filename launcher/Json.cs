using System.Collections.Generic;
using System.Linq;
using System.Text.Json;

namespace HordesOfAzeroth.Launcher
{
    static class Json
    {
        public static object Parse(string json)
        {
            using (JsonDocument document = JsonDocument.Parse(json))
                return Plain(document.RootElement);
        }

        static object Plain(JsonElement element)
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.Object:
                    return element.EnumerateObject().ToDictionary(p => p.Name, p => Plain(p.Value));
                case JsonValueKind.Array:
                    return element.EnumerateArray().Select(Plain).ToArray();
                case JsonValueKind.String:
                    return element.GetString();
                case JsonValueKind.Number:
                    return element.TryGetInt64(out long whole) ? whole : element.GetDouble();
                case JsonValueKind.True:
                    return true;
                case JsonValueKind.False:
                    return false;
                default:
                    return null;
            }
        }
    }
}
