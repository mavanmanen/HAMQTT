using System.Text.Json.Serialization;

namespace HAMQTT.Integration.Oxxio.Models;

public class Products
{
    [JsonPropertyName("productType")]
    [JsonConverter(typeof(JsonStringEnumConverter<ProductType>))]
    public required ProductType ProductType { get; set; }
    
    [JsonPropertyName("slices")]
    public required Slices[] Slices { get; set; }
    
    [JsonPropertyName("averagePrice")]
    public required double AveragePrice { get; set; }
}