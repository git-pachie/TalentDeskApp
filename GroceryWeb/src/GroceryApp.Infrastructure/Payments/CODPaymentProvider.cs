using GroceryApp.Application.DTOs.Payments;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;

namespace GroceryApp.Infrastructure.Payments;

/// <summary>
/// Cash on Delivery — no external API call needed.
/// Payment is marked as pending until delivery confirmation.
/// </summary>
public class CODPaymentProvider : IPaymentProvider
{
    public PaymentMethod SupportedMethod => PaymentMethod.CashOnDelivery;

    public Task<PaymentProviderResult> ProcessPaymentAsync(Payment payment, CheckoutRequest request)
    {
        // COD is always "successful" in the sense that the order proceeds.
        // Actual payment happens on delivery.
        return Task.FromResult(new PaymentProviderResult
        {
            Success = true,
            ExternalTransactionId = $"COD-{payment.Id}"
        });
    }

    public Task<bool> ValidateWebhookAsync(string payload, string? signature)
    {
        // COD has no webhooks
        return Task.FromResult(false);
    }

    public Task<WebhookResult> HandleWebhookAsync(string payload)
    {
        return Task.FromResult(new WebhookResult { Success = false });
    }
}
