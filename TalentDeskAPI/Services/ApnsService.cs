using System.Net;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using TalentDeskAPI.Configuration;
using TalentDeskAPI.Models;

namespace TalentDeskAPI.Services;

/// <summary>
/// Sends push notifications to APNs over HTTP/2.
/// </summary>
public class ApnsService
{
    private readonly HttpClient _httpClient;
    private readonly ApnsSettings _settings;
    private readonly ApnsTokenService _tokenService;
    private readonly ILogger<ApnsService> _logger;

    public ApnsService(
        HttpClient httpClient,
        IOptions<ApnsSettings> settings,
        ApnsTokenService tokenService,
        ILogger<ApnsService> logger)
    {
        _httpClient = httpClient;
        _settings = settings.Value;
        _tokenService = tokenService;
        _logger = logger;
    }

    public async Task<PushNotificationResponse> SendAsync(PushNotificationRequest request)
    {
        var url = $"{_settings.ServerUrl}/3/device/{request.DeviceToken}";

        var payload = BuildPayload(request);
        var jsonPayload = JsonSerializer.Serialize(payload, new JsonSerializerOptions
        {
            DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
        });

        var httpRequest = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent(jsonPayload, Encoding.UTF8, "application/json"),
            Version = HttpVersion.Version20,
            VersionPolicy = HttpVersionPolicy.RequestVersionExact
        };

        httpRequest.Headers.Authorization = new("bearer", _tokenService.GetToken());
        httpRequest.Headers.TryAddWithoutValidation("apns-topic", _settings.BundleId);
        httpRequest.Headers.TryAddWithoutValidation("apns-push-type", "alert");
        httpRequest.Headers.TryAddWithoutValidation("apns-priority", "10");

        try
        {
            var response = await _httpClient.SendAsync(httpRequest);
            var body = await response.Content.ReadAsStringAsync();
            var apnsId = response.Headers.Contains("apns-id")
                ? response.Headers.GetValues("apns-id").FirstOrDefault()
                : null;

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Push sent to {Token}, apns-id: {ApnsId}", request.DeviceToken, apnsId);
                return new PushNotificationResponse
                {
                    Success = true,
                    StatusCode = (int)response.StatusCode,
                    ApnsId = apnsId
                };
            }

            var reason = TryParseReason(body);
            _logger.LogWarning("APNs rejected push: {Status} {Reason}", (int)response.StatusCode, reason);
            return new PushNotificationResponse
            {
                Success = false,
                StatusCode = (int)response.StatusCode,
                Reason = reason
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send push notification to {Token}", request.DeviceToken);
            return new PushNotificationResponse
            {
                Success = false,
                StatusCode = 0,
                Reason = ex.Message
            };
        }
    }

    private static Dictionary<string, object?> BuildPayload(PushNotificationRequest request)
    {
        var alert = new Dictionary<string, string>
        {
            ["title"] = request.Title,
            ["body"] = request.Body
        };

        var aps = new Dictionary<string, object?> { ["alert"] = alert };

        if (request.Badge.HasValue)
            aps["badge"] = request.Badge.Value;

        if (!string.IsNullOrEmpty(request.Sound))
            aps["sound"] = request.Sound;

        var payload = new Dictionary<string, object?> { ["aps"] = aps };

        if (request.CustomData is not null)
        {
            foreach (var kvp in request.CustomData)
                payload[kvp.Key] = kvp.Value;
        }

        return payload;
    }

    private static string? TryParseReason(string body)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            return doc.RootElement.TryGetProperty("reason", out var reason)
                ? reason.GetString()
                : body;
        }
        catch
        {
            return body;
        }
    }
}
