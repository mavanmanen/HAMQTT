using Coravel;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using MQTTnet.Packets;
using ToMqttNet;

namespace HAMQTT.Integration;

public static class Extensions
{
    public static void AddIntegration<T>(this IServiceCollection services) where T : Integration
    {
        services.AddSingleton<Integration, T>();
        services.AddTransient<T>();
    }

    public static void UseIntegrations(this WebApplication app)
    {
        var mqtt = app.Services.GetRequiredService<IMqttConnectionService>();
        var subscriptionManager = app.Services.GetRequiredService<SubscriptionManager>();
        var integrations = app.Services.GetServices<Integration>().ToList();

        mqtt.OnConnectAsync += async _ =>
        {
            foreach (var integration in integrations)
            {
                await integration.PublishDiscoveryDocumentAsync();
            }

            app.Services.UseScheduler(scheduler =>
            {
                foreach (var cronIntegration in integrations.Where(i => i is CronIntegration).Cast<CronIntegration>())
                {
                    scheduler.ScheduleInvocableType(cronIntegration.GetType()).Cron(cronIntegration.CronExpression);
                }
            }).LogScheduledTaskProgress();

            foreach (var mqttIntegration in integrations.Where(i => i is MqttIntegration).Cast<MqttIntegration>())
            {
                await subscriptionManager.SubscribeAsync(mqttIntegration.Topic, mqttIntegration.GetType());
            }
        };
    }
}