using System.Text.Json.Serialization;

namespace HAMQTT.Integration.Oxxio.Models;

public enum ProductType
{
    [JsonStringEnumMemberName("electricity")]
    Electricity,
    [JsonStringEnumMemberName("gas")]
    Gas
}