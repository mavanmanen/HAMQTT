using HAMQTT.Integration.Oxxio.Models;
using RestSharp;

namespace HAMQTT.Integration.Oxxio;

internal class OxxioApi(IConfiguration configuration)
{
    private readonly IRestClient _client = new RestClient(new RestClientOptions
    {
        BaseUrl = new Uri("https://api-digital.enecogroup.com/dxpweb/public/nl/oxxio"),
        Authenticator = new HeaderAuthenticator(configuration["OXXIO_API_KEY"]!)
    });

    public async Task<Data?> GetTariffsAsync()
    {
        var request = new RestRequest("/dynamic/prices")
            .AddQueryParameter("start", $"{DateTime.Now:yyyy-MM-dd}")
            .AddQueryParameter("interval", "Hour")
            .AddQueryParameter("aggregation", "Day");
        
        var result = await _client.GetAsync<RootObject>(request);

        return result?.Data;
    }
}