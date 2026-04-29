using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using GroceryApp.Application.DTOs.Payments;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.Extensions.Configuration;

namespace GroceryApp.Infrastructure.Payments;

/// <summary>
/// GCash payment provider integration.
/// In production, this would call the GCash/PayMongo API.
/// </summary>
public class GCashPaymentProvider : IPaymentProvider
{
    private readonly IConfiguration _configuration;
    private readonly HttpClient _httpClient;

    public GCashPaymentProvider(IConfiguration configuration, HttpClient httpClient)
    {
        _configuration = configuration;
        _httpClient = httpClient;
    }

    public PaymentMethod SupportedMethod => PaymentMethod.GCash;

    public async Task<PaymentProviderResult> ProcessPaymentAsync(Payment payment, CheckoutRequest request)
    {
        // Create a GCash source via PayMongo (or direct GCash API)
        var apiKey = _configuration["GCash:ApiKey"];
        var baseUrl = _configuration["GCash:BaseUrl"] ?? "https://api.paymongo.com/v1";

        var payload = new
        {
            data = new
            {
                attributes = new
                {
                    amount = (int)(payment.Amount * 100),
                    currency = "PHP",
                    type = "gcash",
                    redirect = new
                    {
                        success = request.ReturnUrl ?? $"{_configuration["App:BaseUrl"]}/payment/success",
                        failed = request.ReturnUrl ?? $"{_configuration["App:BaseUrl"]}/payment/failed"
                    }
                }
            }
        };

        var json = JsonSerializer.Serialize(payload);
        var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/sources")
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };

        var authBytes = Encoding.UTF8.GetBytes($"{apiKey}:");
        httpRequest.Headers.Authorization = new("Basic", Convert.ToBase64String(authBytes));

        var response = await _httpClient.SendAsync(httpRequest);
        var responseBody = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            return new PaymentProviderResult
            {
                Success = false,
                FailureReason = $"GCash API error: {response.StatusCode}"
            };
        }

        using var doc = JsonDocument.Parse(responseBody);
        var sourceId = doc.RootElement.GetProperty("data").GetProperty("id").GetString();
        var redirectUrl = doc.RootElement
            .GetProperty("data")
            .GetProperty("attributes")
            .GetProperty("redirect")
            .GetProperty("checkout_url")
            .GetString();

        return new PaymentProviderResult
        {
            Success = false, // Not yet paid — waiting for webhook
            ExternalTransactionId = sourceId,
            RedirectUrl = redirectUrl
        };
    }

    public Task<bool> ValidateWebhookAsync(string payload, string? signature)
    {
        var webhookSecret = _configuration["GCash:WebhookSecret"];
        if (string.IsNullOrEmpty(webhookSecret) || string.IsNullOrEmpty(signature))
            return Task.FromResult(false);

        var computed = ComputeHmac(payload, webhookSecret);
        return Task.FromResult(computed == signature);
    }

    public Task<WebhookResult> HandleWebhookAsync(string payload)
    {
        using var doc = JsonDocument.Parse(payload);
        var data = doc.RootElement.GetProperty("data");
        var attributes = data.GetProperty("attributes");
        var status = attributes.GetProperty("status").GetString();
        var sourceId = attributes.TryGetProperty("source_id", out var sid) ? sid.GetString() : data.GetProperty("id").GetString();

        var newStatus = status switch
        {
            "paid" or "chargeable" => PaymentStatus.Paid,
            "failed" or "expired" => PaymentStatus.Failed,
            _ => PaymentStatus.Pending
        };

        return Task.FromResult(new WebhookResult
        {
            Success = true,
            ExternalTransactionId = sourceId,
            NewStatus = newStatus
        });
    }

    private static string ComputeHmac(string payload, string secret)
    {
        var keyBytes = Encoding.UTF8.GetBytes(secret);
        var payloadBytes = Encoding.UTF8.GetBytes(payload);
        var hash = HMACSHA256.HashData(keyBytes, payloadBytes);
        return Convert.ToHexStringLower(hash);
    }
}
