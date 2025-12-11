using System.Text.Json.Serialization;

namespace HAMQTT.Integration.Oxxio.Models;

public class Slices
{
    [JsonPropertyName("start")]
    public required DateTime Start { get; set; }
    
    [JsonPropertyName("price")]
    public required Price Price { get; set; }
}