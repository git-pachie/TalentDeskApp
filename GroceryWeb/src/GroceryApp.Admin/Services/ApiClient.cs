using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;

namespace GroceryApp.Admin.Services;

/// <summary>
/// Typed HTTP client for calling the GroceryApp API from the Admin MVC panel.
/// </summary>
public class ApiClient
{
    private readonly HttpClient _httpClient;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    public ApiClient(IHttpClientFactory httpClientFactory, IHttpContextAccessor httpContextAccessor)
    {
        _httpClient = httpClientFactory.CreateClient("GroceryApi");
        _httpContextAccessor = httpContextAccessor;
    }

    private HttpRequestMessage CreateRequest(HttpMethod method, string endpoint, HttpContent? content = null)
    {
        var request = new HttpRequestMessage(method, endpoint)
        {
            Content = content
        };

        var token = _httpContextAccessor.HttpContext?.Session.GetString("JwtToken");
        if (!string.IsNullOrEmpty(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }

        return request;
    }

    public async Task<T?> GetAsync<T>(string endpoint)
    {
        using var request = CreateRequest(HttpMethod.Get, endpoint);
        using var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadAsStringAsync();
        if (string.IsNullOrWhiteSpace(json)) return default;
        return JsonSerializer.Deserialize<T>(json, JsonOptions);
    }

    public async Task<TResponse?> PostAsync<TRequest, TResponse>(string endpoint, TRequest data)
    {
        var json = JsonSerializer.Serialize(data, JsonOptions);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        using var request = CreateRequest(HttpMethod.Post, endpoint, content);
        using var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
        var responseJson = await response.Content.ReadAsStringAsync();
        if (string.IsNullOrWhiteSpace(responseJson)) return default;
        return JsonSerializer.Deserialize<TResponse>(responseJson, JsonOptions);
    }

    public async Task PostVoidAsync<TRequest>(string endpoint, TRequest data)
    {
        var json = JsonSerializer.Serialize(data, JsonOptions);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        using var request = CreateRequest(HttpMethod.Post, endpoint, content);
        using var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
    }

    public async Task<TResponse?> PutAsync<TRequest, TResponse>(string endpoint, TRequest data)
    {
        var json = JsonSerializer.Serialize(data, JsonOptions);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        using var request = CreateRequest(HttpMethod.Put, endpoint, content);
        using var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
        var responseJson = await response.Content.ReadAsStringAsync();
        if (string.IsNullOrWhiteSpace(responseJson)) return default;
        return JsonSerializer.Deserialize<TResponse>(responseJson, JsonOptions);
    }

    public async Task<bool> DeleteAsync(string endpoint)
    {
        using var request = CreateRequest(HttpMethod.Delete, endpoint);
        using var response = await _httpClient.SendAsync(request);
        return response.IsSuccessStatusCode;
    }

    public async Task<TResponse?> PostMultipartAsync<TResponse>(string endpoint, MultipartFormDataContent content)
    {
        using var request = CreateRequest(HttpMethod.Post, endpoint, content);
        using var response = await _httpClient.SendAsync(request);
        response.EnsureSuccessStatusCode();
        var responseJson = await response.Content.ReadAsStringAsync();
        if (string.IsNullOrWhiteSpace(responseJson)) return default;
        return JsonSerializer.Deserialize<TResponse>(responseJson, JsonOptions);
    }
}
