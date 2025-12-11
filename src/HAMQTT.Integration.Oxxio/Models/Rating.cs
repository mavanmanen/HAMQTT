using System.Text.Json.Serialization;

namespace HAMQTT.Integration.Oxxio.Models;

public enum Rating
{
    [JsonStringEnumMemberName("cheap")]
    Cheap,

    [JsonStringEnumMemberName("average")]
    Average,

    [JsonStringEnumMemberName("expensive")]
    Expensive
}