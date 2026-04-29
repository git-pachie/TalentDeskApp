using GroceryApp.Application.DTOs.Payments;
using GroceryApp.Domain.Entities;

namespace GroceryApp.Application.Interfaces;

public interface IPaymentProvider
{
    PaymentMethod SupportedMethod { get; }
    Task<PaymentProviderResult> ProcessPaymentAsync(Payment payment, CheckoutRequest request);
    Task<bool> ValidateWebhookAsync(string payload, string? signature);
    Task<WebhookResult> HandleWebhookAsync(string payload);
}

public class PaymentProviderResult
{
    public bool Success { get; set; }
    public string? ExternalTransactionId { get; set; }
    public string? RedirectUrl { get; set; }
    public string? FailureReason { get; set; }
}

public class WebhookResult
{
    public bool Success { get; set; }
    public string? ExternalTransactionId { get; set; }
    public PaymentStatus NewStatus { get; set; }
}
