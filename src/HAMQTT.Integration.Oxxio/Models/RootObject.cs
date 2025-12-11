using System.Text.Json.Serialization;

namespace HAMQTT.Integration.Oxxio.Models;

public class RootObject
{
    [JsonPropertyName("data")]
    public required Data Data { get; set; }
}