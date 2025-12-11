using RestSharp;
using RestSharp.Authenticators;

namespace HAMQTT.Integration.Oxxio;

public class HeaderAuthenticator(string apiKey) : IAuthenticator
{
    public ValueTask Authenticate(IRestClient client, RestRequest request)
    {
        request.AddHeader("Apikey", apiKey);
        return ValueTask.CompletedTask;
    }
}