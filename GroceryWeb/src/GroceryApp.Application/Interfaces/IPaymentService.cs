using GroceryApp.Application.DTOs.Payments;

namespace GroceryApp.Application.Interfaces;

public interface IPaymentService
{
    Task<PaymentResultDto> ProcessCheckoutAsync(Guid userId, CheckoutRequest request);
    Task HandleWebhookAsync(string provider, string payload, string? signature);
}
