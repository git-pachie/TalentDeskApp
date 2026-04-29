using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using GroceryApp.Application.DTOs.Payments;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.Extensions.Configuration;

namespace GroceryApp.Infrastructure.Payments;

/// <summary>
/// PayMaya (Maya) payment provider integration.
/// </summary>
public class PayMayaPaymentProvider : IPaymentProvider
{
    private readonly IConfiguration _configuration;
    private readonly HttpClient _httpClient;

    public PayMayaPaymentProvider(IConfiguration configuration, HttpClient httpClient)
    {
        _configuration = configuration;
        _httpClient = httpClient;
    }

    public PaymentMethod SupportedMethod => PaymentMethod.PayMaya;

    public async Task<PaymentProviderResult> ProcessPaymentAsync(Payment payment, CheckoutRequest request)
    {
        var apiKey = _configuration["PayMaya:ApiKey"];
        var baseUrl = _configuration["PayMaya:BaseUrl"] ?? "https://pg-sandbox.paymaya.com/checkout/v1";

        var payload = new
        {
            totalAmount = new
            {
                value = payment.Amount,
                currency = "PHP"
            },
            requestReferenceNumber = payment.Id.ToString(),
            redirectUrl = new
            {
                success = request.ReturnUrl ?? $"{_configuration["App:BaseUrl"]}/payment/success",
                failure = request.ReturnUrl ?? $"{_configuration["App:BaseUrl"]}/payment/failed",
                cancel = request.ReturnUrl ?? $"{_configuration["App:BaseUrl"]}/payment/cancelled"
            }
        };

        var json = JsonSerializer.Serialize(payload);
        var httpRequest = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}/checkouts")
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
                FailureReason = $"PayMaya API error: {response.StatusCode}"
            };
        }

        using var doc = JsonDocument.Parse(responseBody);
        var checkoutId = doc.RootElement.GetProperty("checkoutId").GetString();
        var redirectUrl = doc.RootElement.GetProperty("redirectUrl").GetString();

        return new PaymentProviderResult
        {
            Success = false,
            ExternalTransactionId = checkoutId,
            RedirectUrl = redirectUrl
        };
    }

    public Task<bool> ValidateWebhookAsync(string payload, string? signature)
    {
        var webhookSecret = _configuration["PayMaya:WebhookSecret"];
        if (string.IsNullOrEmpty(webhookSecret) || string.IsNullOrEmpty(signature))
            return Task.FromResult(false);

        var computed = ComputeHmac(payload, webhookSecret);
        return Task.FromResult(computed == signature);
    }

    public Task<WebhookResult> HandleWebhookAsync(string payload)
    {
        using var doc = JsonDocument.Parse(payload);
        var status = doc.RootElement.TryGetProperty("status", out var s) ? s.GetString() : null;
        var checkoutId = doc.RootElement.TryGetProperty("id", out var id) ? id.GetString() : null;

        var newStatus = status?.ToLower() switch
        {
            "payment_success" or "completed" => PaymentStatus.Paid,
            "payment_failed" or "expired" => PaymentStatus.Failed,
            _ => PaymentStatus.Pending
        };

        return Task.FromResult(new WebhookResult
        {
            Success = true,
            ExternalTransactionId = checkoutId,
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
