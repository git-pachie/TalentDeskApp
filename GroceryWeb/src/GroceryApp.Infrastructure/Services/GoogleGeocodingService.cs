using System.Text.Json;
using GroceryApp.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace GroceryApp.Infrastructure.Services;

public class GoogleGeocodingService : IGeocodingService
{
    private readonly HttpClient _httpClient;
    private readonly string? _apiKey;
    private readonly ILogger<GoogleGeocodingService> _logger;

    public GoogleGeocodingService(HttpClient httpClient, IConfiguration configuration, ILogger<GoogleGeocodingService> logger)
    {
        _httpClient = httpClient;
        _apiKey = configuration["Google:MapsApiKey"];
        _logger = logger;
    }

    public async Task<(double Latitude, double Longitude)?> GeocodeAddressAsync(string address)
    {
        if (string.IsNullOrEmpty(_apiKey))
        {
            _logger.LogWarning("Google Maps API key not configured. Skipping geocoding.");
            return null;
        }

        try
        {
            var encodedAddress = Uri.EscapeDataString(address);
            var url = $"https://maps.googleapis.com/maps/api/geocode/json?address={encodedAddress}&key={_apiKey}";

            var response = await _httpClient.GetAsync(url);
            if (!response.IsSuccessStatusCode) return null;

            var json = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(json);

            var results = doc.RootElement.GetProperty("results");
            if (results.GetArrayLength() == 0) return null;

            var location = results[0]
                .GetProperty("geometry")
                .GetProperty("location");

            var lat = location.GetProperty("lat").GetDouble();
            var lng = location.GetProperty("lng").GetDouble();

            return (lat, lng);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Geocoding failed for address: {Address}", address);
            return null;
        }
    }
}
