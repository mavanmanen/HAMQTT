using Microsoft.Extensions.DependencyInjection;
using MQTTnet;
using ToMqttNet;

namespace HAMQTT.Integration;

internal class SubscriptionManager
{
    private readonly Dictionary<string, List<Type>> _subscriptions = [];
    private readonly IMqttConnectionService _mqtt;

    public SubscriptionManager(IServiceProvider services, IMqttConnectionService mqtt)
    {
        _mqtt = mqtt;

        _mqtt.OnApplicationMessageReceivedAsync += async message =>
        {
            await message.AcknowledgeAsync(CancellationToken.None);
            if (!_subscriptions.TryGetValue(message.ApplicationMessage.Topic, out var subscriptions))
            {
                return;
            }

            var invocations = subscriptions
                .Select(services.GetRequiredService)
                .Cast<MqttIntegration>()
                .Select(s => s.Invoke(message.ApplicationMessage));

            await Task.WhenAll(invocations);
        };
    }

    internal async Task SubscribeAsync(string topic, Type integrationType)
    {
        if (_subscriptions.TryGetValue(topic, out var value))
        {
            value.Add(integrationType);
            return;
        }

        _subscriptions.Add(topic, [integrationType]);
        await _mqtt.SubscribeAsync(new MqttTopicFilterBuilder().WithTopic(topic).Build());
    }
}