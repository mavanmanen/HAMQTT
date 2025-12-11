using System.Text.Json.Serialization;

namespace HAMQTT.Integration.Oxxio.Models;

public class Data
{
    [JsonPropertyName("start")]
    public DateTime Start { get; set; }
    
    [JsonPropertyName("end")]
    public DateTime End { get; set; }
    
    [JsonPropertyName("products")]
    public required Products[] Products { get; set; }
}