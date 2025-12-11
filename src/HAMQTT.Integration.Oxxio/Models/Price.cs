using System.Text.Json.Serialization;

namespace HAMQTT.Integration.Oxxio.Models;

public class Price
{
    [JsonPropertyName("total")]
    public double Total { get; set; }
    
    [JsonPropertyName("rating")]
    [JsonConverter(typeof(JsonStringEnumConverter<Rating>))]
    public Rating Rating { get; set; }
}