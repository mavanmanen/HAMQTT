using System.Globalization;
using HomeAssistantDiscoveryNet;
using HAMQTT.Integration.Oxxio.Models;
using ToMqttNet;

namespace HAMQTT.Integration.Oxxio;

internal sealed class OxxioIntegration(OxxioApi api, IMqttConnectionService mqtt) : Integration(mqtt)
{
    private const string StateTopic = "oxxio/state";

    public override string CronExpression => "0 * * * *";
    protected override bool RunOnStartup => true;

    protected override MqttDeviceDiscoveryConfig GetDeviceDiscoveryConfig()
    {
        var config = new MqttDeviceDiscoveryConfig
        {
            Device = new MqttDiscoveryDevice
            {
                Name = "Oxxio v2",
                Identifiers = ["mavanmanen_oxxio"],
                Manufacturer = "mavanmanen"
            },
            Origin = new MqttDiscoveryConfigOrigin
            {
                Name = "HAMQTT.Integration.Template"
            },
            StateTopic = StateTopic
        };

        config.AddComponent($"oxxio_current-tariff", new MqttSensorDiscoveryConfig
        {
            Name = "Current Tariff",
            DeviceClass = HomeAssistantDeviceClass.MONETARY.Value,
            UnitOfMeasurement = $"{HomeAssistantUnits.CURRENCY_EURO}/{HomeAssistantUnits.ENERGY_KILO_WATT_HOUR}",
            ValueTemplate = "{{ value_json.tariff }}"
        });

        config.AddComponent($"oxxio_rating", new MqttSensorDiscoveryConfig
        {
            Name = "Rating",
            DeviceClass = HomeAssistantDeviceClass.ENUM.Value,
            ValueTemplate = "{{ value_json.rating }}"
        });

        config.AddComponent("oxxio_last-update", new MqttSensorDiscoveryConfig
        {
            Name = "Last Update",
            ValueTemplate = "{{ now().strftime('%H:%M:%S %d-%m-%Y') }}"
        });

        config.AddComponent("oxxio_average-price", new MqttSensorDiscoveryConfig
        {
            Name = "Average Price",
            DeviceClass = HomeAssistantDeviceClass.MONETARY.Value,
            UnitOfMeasurement = HomeAssistantUnits.CURRENCY_EURO.Value,
            ValueTemplate = "{{ value_json.average_price }}"
        });

        return config;
    }

    public override async Task Invoke()
    {
        var currentTariffs = await api.GetTariffsAsync();
        if (currentTariffs == null)
        {
            return;
        }

        var electricity = currentTariffs.Products.Single(p => p.ProductType == ProductType.Electricity);
        var currentSlice = electricity.Slices.OrderBy(s => s.Start).Last(s => s.Start <= DateTime.UtcNow);

        var tariff = currentSlice.Price.Total.ToString(CultureInfo.InvariantCulture);
        var rating = currentSlice.Price.Rating.ToString("G");
        var averagePrice = electricity.AveragePrice.ToString(CultureInfo.InvariantCulture);

        await PublishAsync(StateTopic, new { tariff, rating, averagePrice });
    }
}