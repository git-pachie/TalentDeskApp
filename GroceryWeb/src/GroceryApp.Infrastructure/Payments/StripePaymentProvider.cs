using GroceryApp.Application.DTOs.Payments;
using GroceryApp.Application.Interfaces;
using GroceryApp.Domain.Entities;
using Microsoft.Extensions.Configuration;
using Stripe;
using DomainPaymentMethod = GroceryApp.Domain.Entities.PaymentMethod;

namespace GroceryApp.Infrastructure.Payments;

/// <summary>
/// Handles Card and Apple Pay payments via Stripe.
/// Apple Pay is processed as a Stripe charge with a token from the client.
/// </summary>
public class StripePaymentProvider : IPaymentProvider
{
    private readonly IConfiguration _configuration;

    public StripePaymentProvider(IConfiguration configuration)
    {
        _configuration = configuration;
        StripeConfiguration.ApiKey = _configuration["Stripe:SecretKey"];
    }

    public DomainPaymentMethod SupportedMethod => DomainPaymentMethod.Card;

    public async Task<PaymentProviderResult> ProcessPaymentAsync(Payment payment, CheckoutRequest request)
    {
        try
        {
            var options = new PaymentIntentCreateOptions
            {
                Amount = (long)(payment.Amount * 100), // Convert to cents
                Currency = "php",
                PaymentMethod = request.StripeToken,
                Confirm = true,
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true,
                    AllowRedirects = "never"
                }
            };

            var service = new PaymentIntentService();
            var intent = await service.CreateAsync(options);

            return intent.Status == "succeeded"
                ? new PaymentProviderResult
                {
                    Success = true,
                    ExternalTransactionId = intent.Id
                }
                : new PaymentProviderResult
                {
                    Success = false,
                    FailureReason = $"Payment intent status: {intent.Status}"
                };
        }
        catch (StripeException ex)
        {
            return new PaymentProviderResult
            {
                Success = false,
                FailureReason = ex.Message
            };
        }
    }

    public Task<bool> ValidateWebhookAsync(string payload, string? signature)
    {
        try
        {
            var webhookSecret = _configuration["Stripe:WebhookSecret"]!;
            EventUtility.ConstructEvent(payload, signature, webhookSecret);
            return Task.FromResult(true);
        }
        catch
        {
            return Task.FromResult(false);
        }
    }

    public Task<WebhookResult> HandleWebhookAsync(string payload)
    {
        var stripeEvent = EventUtility.ParseEvent(payload);

        if (stripeEvent.Type == EventTypes.PaymentIntentSucceeded)
        {
            var intent = stripeEvent.Data.Object as PaymentIntent;
            return Task.FromResult(new WebhookResult
            {
                Success = true,
                ExternalTransactionId = intent?.Id,
                NewStatus = PaymentStatus.Paid
            });
        }

        if (stripeEvent.Type == EventTypes.PaymentIntentPaymentFailed)
        {
            var intent = stripeEvent.Data.Object as PaymentIntent;
            return Task.FromResult(new WebhookResult
            {
                Success = true,
                ExternalTransactionId = intent?.Id,
                NewStatus = PaymentStatus.Failed
            });
        }

        return Task.FromResult(new WebhookResult { Success = false });
    }
}
