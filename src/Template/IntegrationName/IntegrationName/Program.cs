using HAMQTT.Integration;
using IntegrationName;

var host = Environment.GetEnvironmentVariable("MQTT_HOST");
var username = Environment.GetEnvironmentVariable("MQTT_USERNAME");
var password = Environment.GetEnvironmentVariable("MQTT_PASSWORD");

var builder = new IntegrationAppBuilder()
    .WithHost(host)
    .WithNodeId("MQTT_INTEGRATION_INTEGRATION_NAME")
    .WithCredentials(username, password)
    .WithStartup<Startup>();

var app = builder.Build();
app.Run();