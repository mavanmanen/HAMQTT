namespace HAMQTT.Integration.Oxxio;

public class Startup : IntegrationStartup
{
    public override void RegisterServices(IServiceCollection services)
    {
        services.AddSingleton<OxxioApi>();
        services.AddIntegration<OxxioIntegration>();
    }
}