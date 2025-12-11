using System.Text.Json;
using Coravel.Invocable;
using HomeAssistantDiscoveryNet;
using MQTTnet;
using ToMqttNet;

namespace HAMQTT.Integration;

public abstract class Integration(IMqttConnectionService mqtt) : IInvocable
{
    public abstract string CronExpression { get; }
    protected abstract bool RunOnStartup { get; }
    protected abstract MqttDeviceDiscoveryConfig GetDeviceDiscoveryConfig();
    public abstract Task Invoke();

    private static readonly JsonSerializerOptions JsonSerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.SnakeCaseLower,
        WriteIndented = false
    };

    protected async Task PublishAsync<T>(string topic, T payload) =>
        await mqtt.PublishAsync(new MqttApplicationMessageBuilder()
            .WithTopic(topic)
            .WithPayload(JsonSerializer.Serialize(payload, JsonSerializerOptions))
            .Build());

    internal async Task PublishDiscoveryDocumentAsync()
    {
        var deviceConfig = GetDeviceDiscoveryConfig();

        var uniqueIdProperty = typeof(MqttDiscoveryConfig).GetProperty("UniqueId")!;

        foreach (var (key, obj) in deviceConfig.Components)
        {
            uniqueIdProperty.SetValue(obj, key);
        }

        await mqtt.PublishDiscoveryDocument(deviceConfig);

        if (RunOnStartup)
        {
            await Invoke();
        }
    }
}